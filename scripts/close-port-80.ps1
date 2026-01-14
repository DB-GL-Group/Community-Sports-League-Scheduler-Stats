#!/usr/bin/env pwsh

try {
    $rule = Get-NetFirewallRule -DisplayName "Allow HTTP 80" -ErrorAction SilentlyContinue
    if ($null -eq $rule) {
        Write-Host "Firewall rule 'Allow HTTP 80' not found."
        exit 0
    }
    Remove-NetFirewallRule -DisplayName "Allow HTTP 80"
    Write-Host "Firewall rule 'Allow HTTP 80' removed."
} catch {
    Write-Error $_
    exit 1
}
