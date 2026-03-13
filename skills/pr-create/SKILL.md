---
name: pr-create
description: Use this skill when you want to push the current branch and create a GitHub PR in one run without per-step confirmations.
---

# PR Create

現在のブランチをリモートにpushし、全コミットを分析してGitHub PRを作成するスキル。
各ステップ間で承認を求めず一括実行する。

## 前提チェック

以下を満たさない場合はエラーで停止する:

- 現在のブランチが `main` または `master` でないこと
- ワーキングツリーがクリーンであること（未コミットの変更がないこと）

## ワークフロー

### 1. ベースブランチの特定

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

取得できない場合は `main` をフォールバックとする。

### 2. コミット分析

以下を実行して全コミットの内容を把握する:

```bash
git log <base>..HEAD --oneline
git diff <base>...HEAD --stat
```

### 3. Push

```bash
git push -u origin HEAD
```

### 4. PR作成

全コミットの内容を元に以下を作成する:

- **タイトル**: 70文字以内、変更の要約
- **本文**: 以下のフォーマット

```markdown
## Summary
<1-3行の箇条書き>

## Test plan
<テスト手順の箇条書き>
```

PRを作成する:

```bash
gh pr create --base "<base>" --title "<title>" --body "<body>"
```

### 5. 結果

作成されたPRのURLを返却する。

## 制約

- ステップ間で承認を求めない
- PRタイトルは70文字以内に収める
- コミットメッセージの言語に合わせてPRタイトル・本文の言語を決定する
