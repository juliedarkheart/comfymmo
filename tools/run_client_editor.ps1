# Opens the Hearthvale project in the Godot editor.
param(
    [string]$GodotPath = "E:\Apps\Godot\Godot_v4.6.3-stable_win64.exe",
    [string]$ProjectPath = (Split-Path $PSScriptRoot -Parent)
)

if (-not (Test-Path -LiteralPath $GodotPath)) {
    # Fall back to the console build if the windowed exe name differs.
    $fallback = "E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe"
    if (Test-Path -LiteralPath $fallback) {
        $GodotPath = $fallback
    } else {
        Write-Host "Godot not found at: $GodotPath" -ForegroundColor Red
        Write-Host "Fix: pass -GodotPath with your Godot 4.x executable."
        exit 1
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    Write-Host "No project.godot found in: $ProjectPath" -ForegroundColor Red
    Write-Host "Fix: pass -ProjectPath pointing at the Hearthvale checkout."
    exit 1
}

Write-Host "Opening Godot editor on $ProjectPath" -ForegroundColor Cyan
Write-Host "Running: `"$GodotPath`" --editor --path `"$ProjectPath`"" -ForegroundColor DarkGray
Start-Process -FilePath $GodotPath -ArgumentList @("--editor", "--path", $ProjectPath)
