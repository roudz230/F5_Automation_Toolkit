#!/bin/bash
set -euo pipefail

HOSTS_FILE="$1"
PHASE="$2"              # before | after
OUTDIR="./results"
DATE="$(date +%Y%m%d_%H%M%S)"

API_USER="admin"
API_PASS="password"
API_PORT=443

mkdir -p "$OUTDIR"

curl_api() {
    local HOST="$1"
    local URI="$2"

    curl -sk -u "$API_USER:$API_PASS" \
        "https://${HOST}:${API_PORT}${URI}"
}

check_host() {
    local HOST="$1"

    OUTFILE="$OUTDIR/${HOST}_${PHASE}_${DATE}.txt"

    {
        echo "=============================="
        echo "HOST      : $HOST"
        echo "PHASE     : $PHASE"
        echo "DATE      : $DATE"
        echo "=============================="
        echo

        ### AFM POLICIES
        echo "### AFM policies"
        AFM_JSON=$(curl_api "$HOST" "/mgmt/tm/security/firewall/policy")
        echo "$AFM_JSON" | jq -r '.items[].name' 2>/dev/null || echo "N/A"

        AFM_COUNT=$(echo "$AFM_JSON" | jq '.items | length' 2>/dev/null || echo 0)
        echo "AFM policy count: $AFM_COUNT"
        echo

        ### ASM POLICIES
        echo "### ASM policies"
        ASM_JSON=$(curl_api "$HOST" "/mgmt/tm/asm/policies")
        echo "$ASM_JSON" | jq -r '.items[].name' 2>/dev/null || echo "N/A"

        ASM_COUNT=$(echo "$ASM_JSON" | jq '.items | length' 2>/dev/null || echo 0)
        echo "ASM policy count: $ASM_COUNT"
        echo

        ### WIDEIP
        echo "### WideIP status"
        WIDEIP_JSON=$(curl_api "$HOST" "/mgmt/tm/gtm/wideip/a")

        echo "$WIDEIP_JSON" | jq -r '.items[] | "\(.name) - \(.status.availabilityState)"' 2>/dev/null || echo "N/A"

        WIDEIP_AVAILABLE=$(echo "$WIDEIP_JSON" | jq '[.items[] | select(.status.availabilityState=="available")] | length' 2>/dev/null || echo 0)
        WIDEIP_OFFLINE=$(echo "$WIDEIP_JSON" | jq '[.items[] | select(.status.availabilityState!="available")] | length' 2>/dev/null || echo 0)

        echo "WideIP available: $WIDEIP_AVAILABLE"
        echo "WideIP offline  : $WIDEIP_OFFLINE"
        echo

        ### VIRTUAL SERVERS
        echo "### Virtual Servers status"
        VS_JSON=$(curl_api "$HOST" "/mgmt/tm/ltm/virtual")

        echo "$VS_JSON" | jq -r '.items[] | "\(.name) - \(.status.availabilityState)"' 2>/dev/null || echo "N/A"

        VS_AVAILABLE=$(echo "$VS_JSON" | jq '[.items[] | select(.status.availabilityState=="available")] | length' 2>/dev/null || echo 0)
        VS_OFFLINE=$(echo "$VS_JSON" | jq '[.items[] | select(.status.availabilityState!="available")] | length' 2>/dev/null || echo 0)

        echo "VS available: $VS_AVAILABLE"
        echo "VS offline  : $VS_OFFLINE"

    } > "$OUTFILE" 2>&1
}

### MAIN LOOP
while IFS= read -r HOST; do
    [[ -z "$HOST" ]] && continue
    echo ">>> Checking $HOST"
    check_host "$HOST"
done < "$HOSTS_FILE"

echo
echo "✔ Checks completed"
echo "Results in: $OUTDIR"