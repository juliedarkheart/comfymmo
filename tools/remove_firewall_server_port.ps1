# Removes the Windows Firewall rule added by open_firewall_server_port.ps1.
# MUST be run from an ADMINISTRATOR PowerShell.
param(
    [int]$Port = 8910
)

$ruleName = "Hearthvale Server UDP $Port"

$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Host "Rule '$ruleName' does not exist — nothing to remove." -ForegroundColor Green
    exit 0
}

try {
    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
    Write-Host "Removed firewall rule '$ruleName'." -ForegroundColor Green
} catch {
    Write-Host "Failed to remove the rule: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Most common cause: this PowerShell is not running as Administrator."
    exit 1
}
