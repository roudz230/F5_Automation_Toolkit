#!/bin/bash

get_availability() {
    local STATS="$1"

    echo "$STATS" | jq -r '
        .entries[]
        .nestedStats.entries["status.availabilityState"].description
        // "unknown"
    '
}

check_ltm_object() {
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
            # On récupère d'abord les pools
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
            # Récupération des membres du pool
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
                    "/mgmt/tm/ltm/pool/~${PARTITION}~${NAME}/members/~${PARTITION}~${MEMBER}/stats")

                AVAIL=$(get_availability "$STATS")

                echo "${PARTITION}/${NAME}/${MEMBER} - $AVAIL"

                ((TOTAL++))
                case "$AVAIL" in
                    available) ((OK++)) ;;
                    offline)   ((OFFLINE++)) ;;
                    unknown|*) ((UNKNOWN++)) ;;
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
            AVAIL=$(get_availability "$STATS")

            echo "$FULLNAME - $AVAIL"

            ((TOTAL++))
            case "$AVAIL" in
                available) ((OK++)) ;;
                offline)   ((OFFLINE++)) ;;
                unknown|*) ((UNKNOWN++)) ;;
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

#!/bin/bash
set -euo pipefail

source ./config.sh
source ./functions.sh
source ./checks_afm.sh
source ./checks_asm.sh
source ./checks_gtm.sh
source ./checks_ltm.sh

mkdir -p "$OUTDIR"

while read -r HOST; do
    [[ -z "$HOST" || "$HOST" =~ ^# ]] && continue

    OUTFILE="$OUTDIR/${HOST}_${PHASE}_${DATE}.txt"
    echo "Processing $HOST → $OUTFILE"

    {
        echo "HOST  : $HOST"
        echo "PHASE : $PHASE"
        echo "DATE  : $(date)"
        echo "=============================="

        check_afm "$HOST"
        check_asm "$HOST"
        check_gtm "$HOST"

        check_ltm_object "$HOST" "virtual"     "VIRTUAL SERVERS"
        check_ltm_object "$HOST" "pool"        "POOLS"
        check_ltm_object "$HOST" "pool_member" "POOL MEMBERS"

    } > "$OUTFILE" 2>&1

done < "$HOSTS_FILE"