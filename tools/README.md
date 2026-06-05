# Tools

Project automation, validation scripts, editor helpers, and build utilities will
live here once they are needed.

Keep tools small, documented, and safe to run locally.

Current helpers:

- `new_asset_bundle.ps1`
- `run-godot.ps1`
- `validate_asset_manifests.ps1`

## Godot Helper

Use `run-godot.ps1` for both manual editor launches and safe automated checks.

Manual editor launch:

```powershell
.\tools\run-godot.ps1 -Editor
```

Quick trusted checks that should return promptly:

```powershell
.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--version"
.\tools\run-godot.ps1 -Headless -TimeoutSeconds 15 -GodotArgs "--help"
```

Project smoke test:

```powershell
.\tools\run-godot.ps1 -SmokeTest -TimeoutSeconds 30
```

What the smoke test proves:

- Godot can open the project path.
- Core region scenes and controllers load.
- The main scene and formal region scenes instantiate without immediate parser or missing-resource failures.

What it does not prove:

- Full gameplay acceptance.
- Input, travel, save/load, or interaction behavior.
- Anything that still requires walking around in the editor.

If a managed check times out, the helper now terminates only the Godot process tree it launched and prints a clear timeout error instead of hanging silently.
