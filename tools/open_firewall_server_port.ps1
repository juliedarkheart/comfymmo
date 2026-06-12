# Adds a Windows Defender Firewall INBOUND rule allowing UDP traffic to the
# Hearthvale server port, so LAN/internet clients can reach a server on this PC.
#
#   MUST be run from an ADMINISTRATOR PowerShell.
#   Nothing in the game runs this automatically — it only changes your firewall
#   when you run it yourself. Remove the rule again with
#   tools\remove_firewall_server_port.ps1.
param(
    [int]$Port = 8910
)

$ruleName = "Hearthvale Server UDP $Port"

Write-Host "This will add a Windows Firewall inbound rule:" -ForegroundColor Yellow
Write-Host "  Name:     $ruleName"
Write-Host "  Protocol: UDP   Port: $Port   Direction: Inbound   Action: Allow"
Write-Host ""

$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Rule '$ruleName' already exists — nothing to do." -ForegroundColor Green
    exit 0
}

try {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol UDP -LocalPort $Port -ErrorAction Stop | Out-Null
    Write-Host "Added firewall rule '$ruleName'." -ForegroundColor Green
    Write-Host "LAN clients can now reach the server. Internet clients additionally need"
    Write-Host "router port forwarding of UDP $Port — see docs/external_server_access.md."
} catch {
    Write-Host "Failed to add the rule: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Most common cause: this PowerShell is not running as Administrator."
    Write-Host "Right-click PowerShell -> 'Run as administrator' and try again."
    exit 1
}
