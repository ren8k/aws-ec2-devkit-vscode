# Claude Code セットアップ (on EC2)

- `bash setup_claude_code.sh` を実行する
- `source ~/.profile` を実行する
- `claude` コマンドを実行する
- terminal setup では，`2` を選択する (下図参照)
  - `1` を選択すると，[以下のエラー](https://github.com/anthropics/claude-code/issues/193)が出る．
  - `Error: Failed to install VSCode terminal Shift+Enter key binding`

```
╭──────────────────────────╮
│ ✻ Welcome to Claude Code │
╰──────────────────────────╯

 Use Claude Code's terminal setup?

 For the optimal coding experience, enable the recommended settings
 for your terminal: Shift+Enter for newlines

   1. Yes, use recommended settings
 ❯ 2. No, maybe later with /terminal-setup

 Enter to confirm · Esc to skip

```
