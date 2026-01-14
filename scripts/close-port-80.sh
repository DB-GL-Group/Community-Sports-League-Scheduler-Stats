#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" = "Darwin" ]; then
  echo "macOS: closing port 80 via firewall blocks caddy."
  echo "Run: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --blockapp /usr/bin/caddy"
  exit 0
fi

if command -v ufw >/dev/null 2>&1; then
  sudo ufw delete allow 80/tcp
  sudo ufw status
  exit 0
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  sudo firewall-cmd --permanent --remove-service=http
  sudo firewall-cmd --reload
  sudo firewall-cmd --list-all
  exit 0
fi

echo "No supported firewall tool found (ufw/firewalld). Close port 80 manually."
