# 開発ログ: profilesテーブルを巡るRLS/列権限の試行錯誤

> フェーズ2(ビルダー発信)向けの素材。5つの修正コミット(`cc16d2a`, `86e67f8`, `d39db4a`, `0858b2f`, `a16158f`)を時系列で並べ、根本原因と学びを整理する。Zenn記事のドラフトはこの内容をベースにしている。

## 前提: SupabaseのRLSと列権限は別レイヤー

Supabaseは`auth.users`と連携した`profiles`テーブルを作ると、デフォルトで`authenticated`/`anon`ロールに**テーブル単位のGRANT ALL**を付与する。Row Level Security(RLS)は「どの行が見えるか」を制御するが、「どの列が見えるか」は制御しない。列を絞るにはPostgreSQLの列単位権限(`GRANT`/`REVOKE`)を使う必要があり、この2つのレイヤーの関係を誤解すると「絞ったつもりで絞れていない」状態になる。このプロジェクトではまさにこのパターンで2度つまずいた。

## 1. 気づき: 列単位REVOKEだけでは何も守れない(`cc16d2a`, 2026-07-17 08:17)

最初の`0010_in_app_notifications.sql`では、`unsubscribe_token`列(メール配信停止トークン、知られると他人の通知配信を無断で止められる)を隠すために

```sql
revoke select (unsubscribe_token) on public.profiles from authenticated, anon;
```

と書いていた。一見正しそうだが、これは効果がない。**PostgreSQLの列単位権限は「テーブル単位の許可に対する追加の許可」としてしか働かず、追加の制限にはならない**。テーブル単位でSELECTが許可されている限り(Supabaseのデフォルトがまさにこれ)、列単位のREVOKEは無視され、`unsubscribe_token`は素通しのままだった。

修正は「テーブル単位を一旦REVOKEしてから、公開してよい列だけを列単位でGRANTし直す」というホワイトリスト方式への転換:

```sql
revoke select on public.profiles from authenticated, anon;
grant select (id, email, name, avatar, is_active, notifications_enabled, created_at, updated_at)
  on public.profiles to authenticated, anon;
```

## 2. 同じ穴がもう一つ: UPDATEにも同じ考慮が抜けていた(`86e67f8`, 2026-07-17 08:43)

SELECTを直した30分後、同じ観点でUPDATEを見直すと案の定同じ問題があった。RLSは行単位(`id = auth.uid()`)のみで列を制限しないため、`supabase.from('profiles').update({ email: '...', is_active: true })`をクライアントから直接叩けば、本来書き換え不可能であるべき`email`や`is_active`まで検証なしで変更できてしまっていた。フロントが実際に更新するのは`name`と`notifications_enabled`の2列だけだったので、同じホワイトリスト方式で塞いだ。

**学び**: 1つのテーブルで見つかったパターンは、そのテーブルの他の権限(SELECT/UPDATE/INSERT/DELETE)にも横展開して確認する必要がある。

## 3. ホワイトリスト方式自体の副作用: 新規列の追加漏れ(`d39db4a`, 2026-07-20 06:19)

3日後、`bio`(自己紹介, 0018)・`interest_tags`(興味タグ, 0019)をprofilesに追加した際、ホワイトリスト方式の裏返しの問題が発生した。UPDATE側は都度`grant update (column)`パターンを踏襲していたが、**SELECT側のホワイトリストへの追加を忘れた**。結果、`Settings.vue`/`GroupDetail.vue`からの直接selectが権限エラーで失敗し、せっかく保存したbio・興味タグが画面上では読み込めない(保存はできるが表示できない)という不具合になった。

**学び**: ホワイトリスト方式は安全だが、「新しい列を足すたびに権限リストも更新する」という運用コストを常に伴う。これを忘れると壊れ方が地味(エラーにならず「保存したのに表示されない」)なので気づきにくい。

## 4. 内部表現の使い回しによる情報漏洩(`0858b2f`, 2026-07-20 06:30)

これは列権限ではなく、SECURITY DEFINER RPC側の問題。`get_rankings`(公開ランキング、`anon`にもexecute権限がある = 未ログインでも呼べる)が、メンバー限定で見せるつもりの`get_group_detail`のowner表現(`id/email/name/avatar`)をそのまま流用していた。フロントの`Ranking.vue`はowner.emailを表示に使っていなかったため実害の露見はなかったが、未ログインユーザーがRPCを直接叩けばグループオーナーのメールアドレスを取得できる状態だった。

**学び**: 「メンバー限定ページ用に作ったデータ構造」を「公開ページ」に使い回すと、権限レベルの異なる文脈が混ざって過剰露出が起きる。呼び出し元のロール(`authenticated`のみか`anon`も含むか)ごとにレスポンスの形を分けるべき。

## 5. 実害のない穴を先回りで塞ぐ(`a16158f`, 2026-07-20 07:32)

最後は、実害の確認された脆弱性ではなく予防的な修正。`profiles`には元々`anon`向けのRLS SELECTポリシーが存在しないため、`anon`が直接selectしても0件になり実害はない(確認済み)。しかし0010の初回修正時に「列単位GRANTの対象を`authenticated, anon`の両方にしていた」名残がそのまま残っており、**将来誰かが`anon`向けのRLSポリシーを誤って追加してしまえば、直前の(4)と同種の漏洩が即座に成立してしまう**構造になっていた。実害がなくても、多層防御として`anon`のSELECT権限自体を落としておく判断をした。

```sql
revoke select on public.profiles from anon;
```

## まとめ: 5件に共通する根本原因

1つのテーブル(`profiles`)を巡る5件の修正はすべて、**「PostgreSQLの列単位権限はテーブル単位の許可を狭められない」という性質の見落とし**か、**そこから生まれたホワイトリスト運用の一貫性維持の難しさ**のどちらかに起因する。

- (1)(2): 見落としそのもの(列REVOKEだけで守れると思っていた)
- (3): ホワイトリスト運用の一貫性が崩れた(新規列の追加漏れ)
- (4): 権限モデルとは別軸の「公開範囲の異なるデータ表現の使い回し」
- (5): 実害はないが構造的に危ういものを予防的に塞ぐ判断

いずれも派手な脆弱性ではなく、Supabase/PostgreSQLの権限モデルに対する地道な理解不足の積み重ねだった。逆に言えば、一度「テーブル単位REVOKE→列単位ホワイトリストGRANT」というパターンを確立してからは、(3)のような追加漏れも含めて機械的にレビューできるようになった。
