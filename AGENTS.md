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