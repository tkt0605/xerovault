### Xero VAult

## Gitでの以下のトラブルシューティング
# トラブルシュートと解決手順

このドキュメントは、開発中に遭遇したGit関連の問題とその解決手順をまとめたものです。

---

## ✅ 1. `fatal: couldn't find remote ref master`

### 原因:
リモートに `master` ブランチが存在しない。`main` が使われている場合が多い。

### 解決方法:
```bash
git pull origin main

.gitignore に追加
echo -e "\n__pycache__/\n*.pyc" >> .gitignore
git add .gitignore

# キャッシュから削除
find . -name "*.pyc" -exec git rm --cached {} \;

# リベース続行
git rebase --continue

