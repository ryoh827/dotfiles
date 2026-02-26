---
name: chezmoi-ryoh827-conventions
description: Use this skill when editing ryoh827's chezmoi/dotfiles repo to follow repository-specific path conventions, especially home bin script placement.
---

# ryoh827 chezmoi Conventions

Use this skill when working in `/Users/ryoh827/.codex/worktrees/*/chezmoi` or the `ryoh827/dotfiles` repository.

## Home bin scripts

- For commands that should be installed under `~/bin`, use `bin/executable_<name>` in the chezmoi source repository.
- Do not use `dot_bin/` for these scripts in this repository.

## Example

- `~/bin/cmu` -> `bin/executable_cmu`
