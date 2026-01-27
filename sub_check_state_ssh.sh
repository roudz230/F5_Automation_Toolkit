#!/bin/bash

HOST="$1"
OUTFILE="outputs/${HOST}_BEFORE_$(date +%F_%H%M).txt"

ssh -o LogLevel=ERROR root@"$HOST" <<'EOF' > "$OUTFILE" 2>&1

echo "### SYSTEM"
tmsh show sys version

echo
echo "### AFM POLICIES"
tmsh list security firewall policy

echo
echo "### ASM POLICIES"
tmsh list asm policy

echo
echo "### VIRTUAL SERVERS"
tmsh show ltm virtual

echo
echo "### POOLS"
tmsh show ltm pool

echo
echo "### POOL MEMBERS"
tmsh show ltm pool members

EOF