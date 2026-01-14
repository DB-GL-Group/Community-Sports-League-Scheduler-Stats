#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" = "Darwin" ]; then
  echo "macOS: opening port 80 requires enabling firewall and allowing caddy."
  echo "Run: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
  echo "Then allow caddy if prompted, or run:"
  echo "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/bin/caddy"
  echo "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/bin/caddy"
  exit 0
fi

if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 80/tcp
  sudo ufw status
  exit 0
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --reload
  sudo firewall-cmd --list-all
  exit 0
fi

echo "No supported firewall tool found (ufw/firewalld). Open port 80 manually."
