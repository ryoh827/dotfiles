---
name: chezmoi-readd-after-external-change
description: Use this skill after running any command that writes to a file under $HOME that is managed by chezmoi (e.g. mise use -g, brew bundle, defaults write, direct edits), to detect drift and re-add it into the chezmoi source with chezmoi re-add.
---

# Chezmoi re-add after external change

`mise use -g` や `brew bundle`、GUIアプリの設定変更など、chezmoiを経由せず`$HOME`配下のファイルを直接書き換えるコマンドを実行した後に使うスキル。chezmoiのソース（このリポジトリ）とターゲットファイルの間にドリフトが生まれていないか確認し、必要なら取り込む。

## いつ使うか

- `mise use -g` / `mise install -g` などmise系コマンドの実行後
- `brew bundle dump` やパッケージマネージャによる設定ファイル書き換えの後
- `defaults write`、エディタ設定、シェル設定など、`$HOME`配下でchezmoi管理下にあるファイルを直接編集・生成するコマンドの後
- ユーザーから「これchezmoiに反映しといて」のように依頼されたとき

## 手順

1. `chezmoi status` でドリフトの有無を確認する。
2. 表示されたパスのうち、**今回の操作で変更したファイルだけ**を対象にする。無関係な既存ドリフトが混ざっていても触らない。
3. 対象ファイルが実行前後で差分を持つか `chezmoi diff <target-path>` で確認する。
4. 差分が今回の変更と一致していれば `chezmoi re-add <target-path>` でソースに取り込む（引数なしの `chezmoi re-add` は全ドリフトを取り込んでしまうため使わない）。
5. `git diff --stat` で取り込まれた内容を確認し、ユーザーに提示する。
6. コミットするかどうかはユーザーの指示を待つ（無断でコミットしない）。

## 対象外のケース

- そもそもそのファイルがchezmoi管理下にない場合は何もしない（`chezmoi managed` で確認できる）。
- ドリフトが今回の操作と無関係な場合は、その旨を伝えるだけにして re-add しない。
