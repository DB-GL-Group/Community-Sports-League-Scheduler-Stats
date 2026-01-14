#!/usr/bin/env bash
set -euo pipefail

detect_ip() {
  if command -v ip >/dev/null 2>&1; then
    ip -4 addr show | awk '/inet / {print $2}' | cut -d/ -f1 \
      | grep -vE '^(127\.|169\.254\.)' | head -n 1
    return
  fi
  if command -v ifconfig >/dev/null 2>&1; then
    ifconfig | awk '/inet / {print $2}' \
      | grep -vE '^(127\.|169\.254\.)' | head -n 1
    return
  fi
}

HOST_IP="$(detect_ip || true)"
if [ -z "${HOST_IP}" ]; then
  HOST_IP="127.0.0.1"
fi

export HOST_IP
echo "Using HOST_IP=${HOST_IP}"
docker compose up -d --build backend worker
