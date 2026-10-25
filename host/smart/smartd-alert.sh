#!/usr/bin/env bash
# Disk health alerts via healthchecks.io.
#   daily  -> called by cron: ping OK if `smartctl -H` passes, else fail
#   (none) -> called by smartd (-M exec) when it detects a problem: fail
# The ping URL lives in /etc/smart-healthcheck.env (root-only, not in git).
set -euo pipefail
source /etc/smart-healthcheck.env

ping() { curl -fsS -m 10 --retry 3 -o /dev/null "$@"; }

case "${1:-}" in
  daily)
    if smartctl -H /dev/sda | grep -q PASSED; then
      ping "$HC_URL"
    else
      ping --data-raw "smartctl -H did not report PASSED on /dev/sda" "$HC_URL/fail"
    fi
    ;;
  *)
    ping --data-raw "${SMARTD_MESSAGE:-smartd reported a problem on ${SMARTD_DEVICE:-unknown}}" "$HC_URL/fail"
    ;;
esac
