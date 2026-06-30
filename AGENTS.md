# Hearthvale / ComfyMMO Agent Rules

## Project

This is Julie's Hearthvale / ComfyMMO project.

Project path:

E:\GitHub\comfymmo

The project is a Godot 4.x cozy top-down MMO / life-sim prototype.

Current focus:
- LimeZu-family visual pipeline
- asset safety
- character customization
- animation and facing
- terrain polish
- object collision and interactions
- playable homestead loop
- validation and smoke tests
- careful Git workflow

## Protected Assets

The project has local licensed assets under:

licensed_assets/

These assets are protected.

Agents must never delete, move, clean, flatten, mirror, overwrite, restructure, optimize, convert, rename, repack, or commit anything under licensed_assets/.

## Absolute Safety Rules

Never run:

- git clean
- Remove-Item
- rmdir
- del
- erase
- rm -rf
- find ... -delete
- robocopy /MIR
- git reset --hard
- broad cleanup scripts

Never modify:

- licensed_assets/**
- generated_assets/**
- review_assets/**
- local_exports/**

Never commit:

- licensed_assets/**
- generated PNGs
- generated JPGs
- generated WEBPs
- PSD, KRA, ASEPRITE, BLEND, FBX, GLB, GLTF files unless Julie explicitly approves a specific exception

Only commit:

- code
- docs
- validation tools
- registry logic
- safe metadata
- configuration needed for development

## Safe Inspection Commands

Prefer read-only commands:

```powershell
git status --short
git branch --show-current
git log --oneline -5
git diff --stat
git diff --name-only
git diff --cached --name-only
git ls-files
rg "search term" -g '!licensed_assets/**' -g '!generated_assets/**' -g '!review_assets/**'
rg --files -g '!licensed_assets/**' -g '!generated_assets/**' -g '!review_assets/**'
Git Rules
Use a branch for each focused task.
Do not use git add . unless forbidden files have been checked first.
Prefer explicit file staging.
Before commit, always show Julie:
branch
changed files
staged files
validation results
proposed commit message
Validation Before Commit

At minimum run:

git status --short
git diff --stat
git diff --name-only
git diff --cached --name-only

Reject commit if staged files include:

licensed_assets/
generated_assets/
review_assets/
local_exports/
*.png
*.jpg
*.jpeg
*.webp
Agent Behavior

Hermes is a coordinating workflow layer. It does not replace ChatGPT, Codex, or Claude.

Use Hermes to:

scope work
delegate focused tasks
enforce safety gates
run validation
prepare final reports
keep Julie in control without making her micromanage every file

Prefer small safe changes over large rewrites.

## Internal Agent Roles

Hermes may use these as internal roles for organizing work. These are not automatically separate agents unless Hermes delegation is explicitly enabled. By default, they are role lenses used by one coordinating Hermes session.

### Project Foreman
Owns the work plan. Restates Julie's goal, limits scope, chooses the next small task, assigns role responsibilities, and produces the final report. Does not edit files directly unless explicitly asked.

### Git Safety Officer
Checks branch, working tree status, staged files, and commit safety. Must prevent unsafe staging or commits. Never uses git clean, git reset --hard, broad delete commands, or git add . unless Julie explicitly approves after review.

### Validation/QA Runner
Runs or recommends validation checks. Confirms changed files are safe, no protected assets are staged, and the project still appears healthy. Reports pass/fail clearly.

### Godot Engineer
Works only on approved Godot code or scene tasks. Makes minimal safe edits to GDScript, scenes, systems, and tools. Does not touch licensed assets or generated image assets.

### Art Pipeline Guardian
Protects the LimeZu-family asset workflow. May advise on safe metadata, import rules, naming, and visual pipeline. Must not modify, copy, move, flatten, mirror, overwrite, restructure, or commit licensed assets.

### Asset Librarian
Maintains safe registries, manifests, and metadata that reference assets without modifying the original protected files. Does not copy or commit licensed assets.

### Prompt Builder
Creates focused prompts for Codex, Claude, ChatGPT, or Hermes. Prompts must include scope, forbidden actions, validation steps, and approval gates.

### Playtest Triage Agent
Turns Julie's playtest notes into bugs, reproduction steps, priorities, suspected systems, and recommended next actions. Does not edit files directly.

### Docs Keeper
Updates docs, workflow notes, devlogs, and project instructions when asked. Does not modify code or assets unless explicitly assigned.

## Default Role Usage

For normal low-token work, use only:
- Project Foreman
- Git Safety Officer
- Validation/QA Runner
- Godot Engineer when code changes are needed

Use the other roles only when directly relevant.