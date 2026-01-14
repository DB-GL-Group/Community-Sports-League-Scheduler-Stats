$ErrorActionPreference = "Stop"

New-NetFirewallRule -DisplayName "Allow HTTP 80" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
Write-Host "Opened port 80 (Allow HTTP 80)."
