$ErrorActionPreference = "Stop"

$ip = $null
try {
    $ip = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -and
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254*' -and
            $_.PrefixOrigin -ne 'WellKnown'
        } |
        Select-Object -First 1 -ExpandProperty IPAddress
} catch {
    $ip = $null
}

if (-not $ip) {
    $ip = "127.0.0.1"
}

$env:HOST_IP = $ip
Write-Host "Using HOST_IP=$ip"
docker compose up -d --build backend worker
