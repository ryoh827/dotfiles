# Neovim キーマップ チートシート

leader = `Space`。`Space` を押して待つと which-key が候補一覧を出す（グループ名: Find / Buffer / Code / Diagnostics / Trouble / Session / Search-Replace / Yank / Memo-Toggle / AI-Claude）。ここには which-key に出ない/覚えにくいものを中心に記載する。

## Treesitter textobjects（operator / visual で使う）

構文単位を選択・操作できる。`d`（削除）`c`（変更）`v`（選択）`y`（コピー）などと組み合わせる。

| キー | 対象 | 例 |
|---|---|---|
| `af` / `if` | 関数（外側 / 内側） | `daf` 関数ごと削除、`vif` 関数の中身を選択 |
| `ac` / `ic` | クラス（外側 / 内側） | `dac`、`cic` |
| `aa` / `ia` | 引数（外側 / 内側） | `cia` 引数を書き換え、`daa` 引数削除 |

移動（normal でカーソルジャンプ）:

| キー | 移動先 |
|---|---|
| `]f` / `[f` | 次 / 前の関数の先頭 |
| `]]` / `[[` | 次 / 前のクラスの先頭 |

## 検索・置換・パネル

| キー | 動作 |
|---|---|
| `<leader>sr` | grug-far: プロジェクト横断の検索置換UI（visualで選択語をプリセット） |
| `<leader>xx` | Trouble: 診断一覧 |
| `<leader>xX` | Trouble: 現在バッファの診断 |
| `<leader>xs` | Trouble: シンボル一覧 |
| `<leader>xq` / `<leader>xl` | Trouble: quickfix / loclist |
| `<leader>xt` | Trouble: TODOコメント一覧 |

## Git hunk（gitsigns、バッファ内で有効）

| キー | 動作 |
|---|---|
| `]c` / `[c` | 次 / 前の hunk へ移動 |
| `<leader>hs` / `<leader>hr` | hunk を stage / reset（visual で範囲指定可） |
| `<leader>hS` / `<leader>hR` | バッファ全体を stage / reset |
| `<leader>hp` | hunk のプレビュー |
| `<leader>hb` | 行の blame 表示 |
| `<leader>hd` | このファイルの diff |

## セッション（persistence）

| キー | 動作 |
|---|---|
| `<leader>qs` | 現在ディレクトリのセッション復元 |
| `<leader>ql` | 直近のセッション復元 |
| `<leader>qd` | このセッションの保存を止める |

## バッファ

| キー | 動作 |
|---|---|
| `<leader>bd` | バッファ削除（Snacks: 分割レイアウトを壊さない） |
| `<S-l>` / `<S-h>` | 次 / 前のバッファ（bufferline順） |

## 既存の主要キー（抜粋）

| キー | 動作 |
|---|---|
| `<leader>ff` / `fg` / `fb` / `fr` | Telescope: ファイル / grep / バッファ / 最近開いた |
| `<leader>fR` | Telescope: 直前の検索結果を再開（resume） |
| `s` / `S` | flash: ジャンプ / treesitterジャンプ |
| `gd` / `K` / `gr` / `<leader>rn` / `<leader>ca` | LSP: 定義 / hover / 参照 / rename / code action |
| `gl` / `[d` / `]d` | 診断: 行表示 / 前 / 次 |
| `<leader>gf` | conform: フォーマット |
| `<leader>w` | ウィンドウリサイズモード（h/l/j/k、= 均等、q 終了） |
</content>
