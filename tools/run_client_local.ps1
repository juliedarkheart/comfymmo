# Launches the Hearthvale game client (windowed). To join a server once the
# game is up: press F8, enter the address, Connect.
#   Same PC:   127.0.0.1 : 8910
#   LAN:       the host PC's LAN IP (host runs 'ipconfig' -> IPv4 Address)
#   Internet:  the host's public IP (host needs UDP port forwarding)
param(
    [string]$GodotPath = "E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [string]$ProjectPath = (Split-Path $PSScriptRoot -Parent)
)

if (-not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "Godot not found at: $GodotPath" -ForegroundColor Red
    Write-Host "Fix: pass -GodotPath with your Godot 4.x executable."
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    Write-Host "No project.godot found in: $ProjectPath" -ForegroundColor Red
    Write-Host "Fix: pass -ProjectPath pointing at the Hearthvale checkout."
    exit 1
}

Write-Host "=== Hearthvale client ===" -ForegroundColor Cyan
Write-Host "Offline play works immediately. For multiplayer press F8 in-game."
$args = @("--path", $ProjectPath)
Write-Host "Running: `"$GodotPath`" $($args -join ' ')" -ForegroundColor DarkGray
& $GodotPath @args
exit $LASTEXITCODE
