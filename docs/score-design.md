# スコア/ストリーク仕様 v2

> Confirmed。Express+Prisma時代は`backend/src/services/scoreService.ts`に実装(コミット `b7c8483`)。Supabase移行後は`supabase/migrations/0001_init.sql`の`recalc_group_score`関数に移植済み。

## 現行仕様の何が問題か

1. **期限切れ・未達成にペナルティがない** — `Goal.deadline` を過ぎても `isCompleted` は `false` のまま放置されるだけで、スコアにも何にも影響しない。「期限を決めたのに達成しなくても損しない」ため、期限を曖昧にする動機がない。
2. **ストリークが壊れない** — `incrementStreak` は達成のたびに `+1` するだけで、リセットする経路がどこにも存在しない。「連続達成」ではなく「累計達成回数」になっている。
3. **曖昧な目標(期限・担当者なし)にリスクがない** — 具体的な目標(`isConcrete`)は高得点(25pt)、曖昧な目標は低得点(5pt)という差はあるが、曖昧な目標側には何のデメリットもない。「リスクを取らない」ことが常に安全という状態。

## 提案: ミス(未達成)を一級の状態として扱う

新しいDBフィールドは追加しない。既存の `deadline` と `isCompleted` だけから状態を導出する。

```
concrete goal (deadline && assigneeId が両方ある) は次の3状態のいずれか:
  - pending   : deadline が未来、isCompleted = false
  - completed : isCompleted = true
  - missed    : deadline が過去、isCompleted = false

vague goal (deadline か assigneeId が欠けている) は次の2状態:
  - pending   : isCompleted = false
  - completed : isCompleted = true
  (期限がない/担当者がいない = そもそも「ミス」を判定できないため missed にはならない)
```

**曖昧な目標を許さない、の意味を「低得点」から「ノーリスク・ノーリターン」に変える**: 具体的な目標だけが得点にもペナルティにもなり、曖昧な目標は常に小さな得点(現状の5pt)のみでリスクもない。

## 計算式

既存定数は維持し、以下を追加する。

| 定数 | 値 | 意味 |
| --- | --- | --- |
| `BASE_SCORE` | 100 | 既存 |
| `MAX_SCORE` | 9999 | 既存 |
| `MIN_SCORE` | 0 (新規) | ペナルティ導入に伴い下限を追加 |
| `CONCRETE_GOAL_PTS` | 25 | 既存 |
| `VAGUE_GOAL_PTS` | 5 | 既存 |
| `FULL_PARTICIPATION_BONUS` | 1.5 | 既存(vagueにも適用、変更なし) |
| `MISSED_GOAL_PENALTY` | **25 (新規)** | concrete goal を1件missするごとに減点。`CONCRETE_GOAL_PTS` と対称にすることで「達成すれば+25、外せば-25」というシンプルな説明にする |
| `STREAK_BONUS` | 50 | 既存(条件は below) |

```
group.score
  = BASE_SCORE
  + Σ(completed goals の獲得点)         // 既存ロジックのまま(concrete×参加率ボーナス or vague)
  − Σ(missed concrete goals の件数) × MISSED_GOAL_PENALTY
  + (streak >= 3 ? STREAK_BONUS : 0)
  を [MIN_SCORE, MAX_SCORE] にクランプ
```

## ストリークを「毎回フル再計算」する導出値に変える

現状の `incrementStreak`(DBに保存した値を+1するだけ)をやめ、`updateGroupScore` と同じ「毎回フル再計算」方式に統一する。

```
1. そのグループの concrete goal のうち、「resolved」(completed または missed) なものを集める
2. deadline の昇順に並べる(concrete goalは必ずdeadlineを持つため自然に時系列になる)
3. 最新(配列の末尾)から遡って、isCompleted=true が連続する件数を数える
4. missed に当たった時点、または列挙し終えた時点で打ち切り → それが現在のstreak
```

- 未解決(pending)の concrete goal はstreak計算に含めない(まだ結果が出ていないため)
- vague goal の達成・未達成はstreakに一切影響しない(曖昧な目標を積み重ねてもストリークは伸びない)
- この方式なら「リセット条件」を別途実装する必要がなく、`Group.streak` というDBカラム自体が不要になる可能性がある(下記「実装への影響」参照)

## 具体例

グループにconcrete goalが時系列で `達成, 達成, ミス, 達成, 達成, 達成` の順で並んでいる場合:
- スコア: 5件の達成(重複省略)分の加点 − 1件のミス分の減点(-25)
- ストリーク: 末尾から3件連続達成 → `streak = 3` → `STREAK_BONUS` 適用

直近が `達成, 達成, ミス` の場合は `streak = 0`(ミスで途切れているため)。

## 実装への影響

- `cast_vote` RPC(`supabase/migrations/0001_init.sql`)に、**deadlineを過ぎたconcrete goalへの投票を拒否するガード**を追加する(missedが「確定」した後に投票で覆せないようにするため)
- `updateGroupScore` は「達成済みgoal」に加えて「missed(deadline超過かつ未達成)なconcrete goal」も取得し、ペナルティ計算に使う
- ストリークをDB保存の増分値からフル再計算方式に変えるため、`Group.streak` カラムは実質的に「毎回上書きされるキャッシュ値」になる(スキーマは変えず、常にupdateGroupScore内で再計算して書き込む形にする — Vote/GoalVoteの統合を見送ったのと同じ理由で、今回はカラム自体の削除は行わない)
- frontendのGoal表示に「missed」状態を出せるよう、Goal APIレスポンスに `status: 'pending' | 'completed' | 'missed'` を追加する(`packages/shared`のGoal型を拡張)

## 既知の制約(今回のスコープ外)

- **Vote/GoalVoteの統合**: レベル2で見送り済みの方針を維持する。

## 未解決の課題(実装後も残っているもの)

1. **`MISSED_GOAL_PENALTY = 25`の妥当性が未検証** — 「要確認」のまま値を確定させて実装した。実グループ運用で+25/-25の対称性が体験として適切か、フィードバックを集めていない。検証には本番デプロイ・実ユーザー・analytics基盤(イベント履歴やフィードバックUI)のいずれかが要るが、現状はどれも存在しない(ローカル/dev環境のみで、デプロイパイプラインも未整備)。したがって**今は着手せず、本番デプロイが実現してから検証に取り組む**。
2. **遅延評価問題** — missed判定は「誰かが投票操作した時(`cast_vote`/`cancel_vote`実行時)にしか再計算されない」。Express時代は`runScoreSweep`によるアプリプロセス内の定期実行で軽減していたが、Supabase移行(SQL関数のみで完結させる方針)に伴いこの定期スイープは**移植していない**。`pg_cron`拡張でSQL Editorから`recalc_group_score`を定期実行するジョブを別途設定すれば同等のことができるが、今回のスコープ外。
3. **GoalVote/Voteの分離** — 投票取り消しの意味論のために2テーブルに分かれているが、統合すべきか未検討のまま(レベル2で見送り済み)。
