# Coding Standards

## Godot

- Use Godot 4.x.
- Prefer GDScript for gameplay until a concrete performance need appears.
- Keep scenes focused and composable.
- Use resources for data definitions.
- Avoid global singletons unless they represent a true application service.

## Naming

- Files and folders use `snake_case`.
- GDScript classes use `PascalCase`.
- Signals use past-tense or request-style names where practical.
- IDs are stable lowercase strings.

## Architecture

- Keep domain code inside its domain folder.
- Use `systems/` for orchestration, not as a dumping ground.
- Keep networking assumptions visible in method names and docs.
- Separate gameplay state from presentation state.

## Code Style

- Prefer small functions with clear ownership.
- Avoid clever abstractions before duplication proves they are useful.
- Keep comments focused on intent, constraints, or non-obvious behavior.
- Do not commit generated local editor metadata.

## Reviews

Before merging future changes, check:

- Does the project still open in Godot?
- Is the folder ownership clear?
- Are multiplayer authority assumptions explicit?
- Did the change add only the systems it actually needed?

