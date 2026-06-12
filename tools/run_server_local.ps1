# Runs the Hearthvale dedicated server for local / private-LAN playtests.
# Usage examples:
#   .\tools\run_server_local.ps1
#   .\tools\run_server_local.ps1 -Port 9000 -World my_town
#   .\tools\run_server_local.ps1 -Bind 127.0.0.1     # strictly this PC only
param(
    [int]$Port = 8910,
    [string]$World = "default_world",
    [string]$Bind = "*",
    [string]$GodotPath = "E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [string]$ProjectPath = (Split-Path $PSScriptRoot -Parent)
)

if (-not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "Godot not found at: $GodotPath" -ForegroundColor Red
    Write-Host "Fix: pass -GodotPath with your Godot 4.x console executable, e.g.:"
    Write-Host "  .\tools\run_server_local.ps1 -GodotPath 'D:\Godot\Godot_v4.x_console.exe'"
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    Write-Host "No project.godot found in: $ProjectPath" -ForegroundColor Red
    Write-Host "Fix: pass -ProjectPath pointing at the Hearthvale checkout."
    exit 1
}

Write-Host "=== Hearthvale local server ===" -ForegroundColor Cyan
Write-Host "Bind $Bind  Port $Port (UDP)  World '$World'"
Write-Host "Clients on this PC connect via F8 to 127.0.0.1:$Port"
Write-Host "Clients on your LAN connect to this PC's LAN IP (run 'ipconfig', allow UDP $Port in the firewall)."
Write-Host ""

$args = @("--headless", "--path", $ProjectPath, "res://server/server_main.tscn", "--", "--port=$Port", "--world=$World", "--bind=$Bind")
Write-Host "Running: `"$GodotPath`" $($args -join ' ')" -ForegroundColor DarkGray
& $GodotPath @args
exit $LASTEXITCODE
