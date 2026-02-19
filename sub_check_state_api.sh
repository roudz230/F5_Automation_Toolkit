#!/bin/bash

source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

curl_api() {
    local HOST="$1"
    local URI="$2"

    curl -sk -u "$LOGIN:$LOGINPWD" \
        "https://${HOST}${URI}"
}

get_availability() {
    local STATS="$1"

    echo "$STATS" | jq -r '
        .entries[]
        .nestedStats.entries["status.availabilityState"].description
        // "unknown"
    '
}

check_afm() {
    local HOST="$1"

    echo
    echo "### AFM policies"

    AFM_JSON=$(curl_api "$HOST" "/mgmt/tm/security/firewall/policy")
    echo "$AFM_JSON" | jq -r '.items[].name' 2>/dev/null || echo "N/A"

    AFM_COUNT=$(echo "$AFM_JSON" | jq '.items | length' 2>/dev/null || echo 0)
    echo "AFM policy count: $AFM_COUNT"
}

check_asm() {
    local HOST="$1"

    echo
    echo "### ASM policies"

    ASM_JSON=$(curl_api "$HOST" "/mgmt/tm/asm/policies")
    echo "$ASM_JSON" | jq -r '.items[].name' 2>/dev/null || echo "N/A"

    ASM_COUNT=$(echo "$ASM_JSON" | jq '.items | length' 2>/dev/null || echo 0)
    echo "ASM policy count: $ASM_COUNT"
}

check_gtm() {
    local HOST="$1"

    echo
    echo "### GTM WideIP status"

    WIDEIP_JSON=$(curl_api "$HOST" "/mgmt/tm/gtm/wideip/a")

    echo "$WIDEIP_JSON" | jq -r '.items[] | "\(.name) - \(.status.availabilityState)"' 2>/dev/null || echo "N/A"

    WIDEIP_AVAILABLE=$(echo "$WIDEIP_JSON" | jq '[.items[] | select(.status.availabilityState=="available")] | length' 2>/dev/null || echo 0)
    WIDEIP_OFFLINE=$(echo "$WIDEIP_JSON" | jq '[.items[] | select(.status.availabilityState!="available")] | length' 2>/dev/null || echo 0)

    echo "WideIP available: $WIDEIP_AVAILABLE"
    echo "WideIP offline : $WIDEIP_OFFLINE"
}

check_ltm() {
    local HOST="$1"
    local TYPE="$2"
    local TITLE="$3"

    echo
    echo "### $TITLE STATUS"

    local LIST_JSON
    local LIST=()

    case "$TYPE" in
        virtual)
            LIST_JSON=$(curl_api "$HOST" "/mgmt/tm/ltm/virtual?\$select=name,partition,subPath")
            mapfile -t LIST < <(
                echo "$LIST_JSON" | jq -r '
                    .items[] | "\(.partition)|\(.subPath // "")|\(.name)"
                '
            )
            ;;
        pool)
            LIST_JSON=$(curl_api "$HOST" "/mgmt/tm/ltm/pool?\$select=name,partition,subPath")
            mapfile -t LIST < <(
                echo "$LIST_JSON" | jq -r '
                    .items[] | "\(.partition)|\(.subPath // "")|\(.name)"
                '
            )
            ;;
        pool_member)
            POOLS_JSON=$(curl_api "$HOST" "/mgmt/tm/ltm/pool?\$select=name,partition,subPath")
            mapfile -t LIST < <(
                echo "$POOLS_JSON" | jq -r '
                    .items[] | "\(.partition)|\(.subPath // "")|\(.name)"
                '
            )
            ;;
        *)
            echo "Unknown type: $TYPE"
            return 1
            ;;
    esac

    local TOTAL=0 OK=0 OFFLINE=0 UNKNOWN=0

    for ITEM in "${LIST[@]}"; do
        IFS='|' read -r PARTITION SUBPATH NAME <<< "$ITEM"

        if [[ "$TYPE" == "pool_member" ]]; then

            if [[ -n "$SUBPATH" ]]; then
                MEMBER_JSON=$(curl_api "$HOST" \
                    "/mgmt/tm/ltm/pool/~${PARTITION}~${SUBPATH}~${NAME}/members")
            else
                MEMBER_JSON=$(curl_api "$HOST" \
                    "/mgmt/tm/ltm/pool/~${PARTITION}~${NAME}/members")
            fi

            mapfile -t MEMBERS < <(
                echo "$MEMBER_JSON" | jq -r '.items[].name'
            )

            for MEMBER in "${MEMBERS[@]}"; do
                STATS=$(curl_api "$HOST" \
                    "/mgmt/tm/ltm/pool/~${PARTITION}~${SUBPATH}~${NAME}/members/~Common~${MEMBER}/stats")

                STATE=$(get_availability "$STATS")

                echo "${PARTITION}/${NAME}/Common/${MEMBER} - $STATE"

                ((TOTAL++))
                case "$STATE" in
                    available) ((OK++)) ;;
                    offline) ((OFFLINE++)) ;;
                    unknown*) ((UNKNOWN++)) ;;
                esac
            done

        else
            if [[ -n "$SUBPATH" ]]; then
                URI="/mgmt/tm/ltm/${TYPE}/~${PARTITION}~${SUBPATH}~${NAME}/stats"
                FULLNAME="${PARTITION}/${SUBPATH}/${NAME}"
            else
                URI="/mgmt/tm/ltm/${TYPE}/~${PARTITION}~${NAME}/stats"
                FULLNAME="${PARTITION}/${NAME}"
            fi

            STATS=$(curl_api "$HOST" "$URI")
            STATE=$(get_availability "$STATS")

            echo "$FULLNAME - $STATE"

            ((TOTAL++))
            case "$STATE" in
                available) ((OK++)) ;;
                offline) ((OFFLINE++)) ;;
                unknown*) ((UNKNOWN++)) ;;
            esac
        fi
    done

    echo
    echo "### $TITLE SUMMARY"
    echo "TOTAL     : $TOTAL"
    echo "AVAILABLE : $OK"
    echo "OFFLINE   : $OFFLINE"
    echo "UNKNOWN   : $UNKNOWN"
}

read -p "Saisir le login : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""
read -p "Saisir l'étape (before ou after) : " PHASE
echo ""

AUTH="-u $LOGIN:$LOGINPWD"

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "===================================================="
    echo "Checks sur $HOST"
    echo "===================================================="

    LOGFILE="logs/${TIMESTAMP}_${HOST}_state_${PHASE}.log"
    ((h++))

    {
        echo "=============================="
        echo "HOST  : $HOST"
        echo "PHASE : $PHASE"
        echo "DATE  : $TIMESTAMP"
        echo "=============================="
        echo

        check_afm "$HOST"
        check_asm "$HOST"
        check_gtm "$HOST"

        check_ltm "$HOST" "virtual"     "VIRTUAL SERVERS"
        check_ltm "$HOST" "pool"        "POOLS"
        check_ltm "$HOST" "pool_member" "POOL MEMBERS"

    } > "$LOGFILE" 2>&1

done

show_recap "$h" "$o" "$k"