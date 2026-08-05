---
name: gh-stack
description: Use this skill when a change splits into multiple dependent PRs, to build and review-manage stacked PRs with the github/gh-stack extension.
---

# gh-stack

1つの作業が依存関係を持つ複数PRに分割できるとき、`gh stack`（`github/gh-stack` 拡張）でスタックPRとして運用するスキル。

単一PRで完結する変更にはこのスキルを使わず `pr-create` を使う。

## 前提チェック

- `gh extension list` に `github/gh-stack` があること。無ければ `gh extension install github/gh-stack` を実行する
- ワーキングツリーがクリーンであること
- ローカルのスタック情報は `.git/gh-stack` に保存され、コミットされない

## スタックにする判断

以下のいずれかに当てはまるときスタックにする:

- 下位の変更が入らないと上位の変更をレビューできない（基盤の追加 → 利用側の実装）
- diffが大きく、独立してレビュー・マージできる単位に切り分けられる

当てはまらないなら単一PRにする。スタックにすると判断したら、各層のブランチ名とそこに含める変更の分割案をユーザーに提示し、合意を得てから作成に入る。

## ワークフロー

### 1. スタックを作る

```bash
gh stack init <bottom-branch>
```

トランクを既定ブランチ以外にする場合は `--base <branch>` を付ける。既存ブランチ群を下から順に取り込む場合は `gh stack init <b1> <b2> <b3>`。

### 2. 層を積む

最下層にコミットしたら、次の層を追加する:

```bash
gh stack add <branch>
```

`gh stack add -Am "<message>" <branch>` でステージとコミットを同時に行える。各層は単独でテストが通る状態にする。

### 3. PRを作る

```bash
gh stack submit --auto --open
```

- 非対話端末では対話エディタは開かないが、明示的に `--auto` を付ける
- `--auto` のPRは既定でdraftになるため、レビュー可能にするなら `--open` を付ける
- `--auto` のタイトルは自動生成なので、作成後に各PRのタイトル・本文を整える

### 4. タイトルと本文を整える

```bash
gh stack view --json
```

で層とPR番号の対応を取り、PRごとに次を適用する:

```bash
gh pr edit <pr-number> --title "<title>" --body "<body>"
```

- タイトルは70文字以内
- 本文は `pr-create` と同じ `## Summary` / `## Test plan` の形式
- スタック内の位置関係はGitHub側のスタック表示に任せ、本文に自前のナビゲーションを書かない

### 5. レビュー対応と追随

- 指摘対応は該当層のブランチに直接コミットする
- トランクや下位層の更新を全層に流す: `gh stack rebase`
- コンフリクトは解消後に `gh stack rebase --continue`、やり直すなら `gh stack rebase --abort`
- fetch・rebase・push・PR状態同期をまとめて行う: `gh stack sync`
- マージ済み層のローカルブランチを掃除する: `gh stack sync --prune`

### 6. マージ

```bash
gh stack merge --yes
```

指定PRまでで止める場合は `gh stack merge <pr-number> --yes`。マージ方式はリポジトリの方針に合わせて `--squash` / `--merge` / `--rebase` を指定する。

## 制約

- 対話UI（`gh stack modify`、引数なしの `gh stack submit`・`merge`）に依存しない。非対話フラグを使う
- スタック管理下のブランチに `gh pr create` を使わない。PR作成は `gh stack submit` に統一する
- 層の追加・削除・並べ替えが必要になったら、独断で `gh stack modify` を使わずユーザーに確認する
- `gh stack merge` はスタック全体を一括マージする破壊的操作なので、実行前にユーザーの承認を得る
- PRタイトル・本文の言語はコミットメッセージの言語に合わせる
