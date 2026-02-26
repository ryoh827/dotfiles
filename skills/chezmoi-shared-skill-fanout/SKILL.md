---
name: chezmoi-shared-skill-fanout
description: Use this skill when adding or updating a skill in ryoh827's dotfiles so the same source is deployed to both Codex and Claude via chezmoi includes.
---

# Chezmoi Shared Skill Fanout

Use this skill when you need one skill definition to be available in both Codex and Claude in the `ryoh827/dotfiles` repository.

## Source of truth

- Put the canonical skill files under `skills/<skill-name>/`.
- Edit only the files in `skills/<skill-name>/` when updating content.

## Codex deployment

- Add `dot_codex/skills/<skill-name>/SKILL.md.tmpl` with `{{ include "skills/<skill-name>/SKILL.md" }}`.
- If the skill has Codex UI metadata, store the canonical file at `skills/<skill-name>/agents/openai.yaml`.
- Add `dot_codex/skills/<skill-name>/agents/openai.yaml.tmpl` with `{{ include "skills/<skill-name>/agents/openai.yaml" }}`.

## Claude deployment

- Add `dot_claude/skills/<skill-name>/SKILL.md.tmpl` with `{{ include "skills/<skill-name>/SKILL.md" }}`.

## Checks

- Verify both wrapper files point to the same `skills/<skill-name>/SKILL.md`.
- Keep wrappers as include-only files, like `dot_codex/AGENTS.md.tmpl` and `dot_config/claude/CLAUDE.md.tmpl`.
