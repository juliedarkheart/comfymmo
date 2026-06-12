# Runs the Hearthvale dedicated server bound to ALL interfaces (0.0.0.0) for
# friend playtests over the internet. READ THIS FIRST:
#   - This is PROTOTYPE networking: no auth, no encryption. Private friends only.
#   - Reaching it from the internet additionally requires:
#       1. Windows firewall inbound rule for UDP <port>
#          (run tools\open_firewall_server_port.ps1 as Administrator)
#       2. Router port forwarding of UDP <port> to this PC
#       3. Friends connect to your PUBLIC IP (some ISPs use CGNAT, which blocks
#          port forwarding entirely — see docs/external_server_access.md)
param(
    [int]$Port = 8910,
    [string]$World = "default_world",
    [string]$GodotPath = "E:\Apps\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [string]$ProjectPath = (Split-Path $PSScriptRoot -Parent)
)

if (-not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "Godot not found at: $GodotPath" -ForegroundColor Red
    Write-Host "Fix: pass -GodotPath with your Godot 4.x console executable."
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    Write-Host "No project.godot found in: $ProjectPath" -ForegroundColor Red
    Write-Host "Fix: pass -ProjectPath pointing at the Hearthvale checkout."
    exit 1
}

Write-Host "=== Hearthvale PUBLIC-BIND server ===" -ForegroundColor Yellow
Write-Host "Bind 0.0.0.0  Port $Port (UDP)  World '$World'"
Write-Host ""
Write-Host "WARNING: prototype networking, no authentication. Share the address" -ForegroundColor Yellow
Write-Host "with trusted friends only, and stop the server when you're done." -ForegroundColor Yellow
Write-Host "Internet access needs firewall (UDP $Port) + router port forwarding." -ForegroundColor Yellow
Write-Host "Details: docs/external_server_access.md"
Write-Host ""

$args = @("--headless", "--path", $ProjectPath, "res://server/server_main.tscn", "--", "--port=$Port", "--world=$World", "--bind=0.0.0.0")
Write-Host "Running: `"$GodotPath`" $($args -join ' ')" -ForegroundColor DarkGray
& $GodotPath @args
exit $LASTEXITCODE
