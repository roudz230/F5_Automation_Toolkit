#!/bin/bash

OUT=$(sshpass -e ssh "$HOST" "tmsh load sys config verify" 2>&1 | tee "$LOGFILE")

ERR_COUNT=$(echo "$OUT" | grep -c '^Error:')
WARN_COUNT=$(echo "$OUT" | grep -c '^there were warnings:')

if [[ $ERR_COUNT -gt 0 ]]; then
    echo "❌ Verification FAILED"
elif [[ $WARN_COUNT -gt 0 ]]; then
    echo "⚠ Verification OK with warnings"
else
    echo "✔ Verification OK"
fi

echo "$OUT" | awk '
    /^Error:/ { print }
    /^there were warnings:/ { inwarn=1; next }
    inwarn { print }
'