#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

LOGFILE="$LOGS_DIR/${TIMESTAMP}_sync_cluster.log"
AUTH="-u $LOGIN:$LOGINPWD"

poll_sync() {
    local HOST=$1
    #local AUTH="-u $LOGIN:$LOGINPWD"

    for i in {1..20}; do
        STATUS=$(curl -sk $AUTH \
            "https://$HOST/mgmt/tm/cm/sync-status" \
            | jq -r '.entries[].nestedStats.entries.status.description')

        if [[ "$STATUS" == "In Sync" ]]; then
            return 0
        fi

        sleep 5
    done
    return 1
}

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Synchro cluster sur $HOST"
    echo "=============================================================="

    ((h++))

    #AUTH="-u $LOGIN:$LOGINPWD"

    echo "" >> "$LOGFILE"
    echo "================ $HOST ================" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    #ROLE=$(curl -sk $AUTH \
    #    "https://$HOST/mgmt/tm/cm/failover-status" \
    #    | jq -r '.entries[].nestedStats.entries.status.description')

    ROLE=$(curl -sk $AUTH \
        "https://$HOST/mgmt/tm/cm/failover-status" \
        | jq -r '.entries[].nestedStats.entries.status.description | select(. == "ACTIVE" or . == "STANDBY")')

    #grepper -E du ROLE sur ACTIVE|STANDBY car plusieurs retours possible
    #ROLE2=$(echo $ROLE | grep -E "ACTIVE|STANDBY|Unknown|UNKNOWN")

    echo "Role : $ROLE"

    if [[ "$ROLE" != "ACTIVE" ]]; then
        echo "Pas MASTER du cluster - au suivant"
        echo "Role : $ROLE - Pas MASTER du cluster - au suivant" >> "$LOGFILE"
        continue
    fi

    echo "Role : $ROLE" >> "$LOGFILE"

    #CHANGE=$(curl -sk $AUTH \
    #    "https://$HOST/mgmt/tm/cm/sync-status" \
    #    | jq -r '.entries[].nestedStats.entries.status.description | select(. == "Changes Pending")')

    CHANGE=$(curl -sk $AUTH \
        "https://$HOST/mgmt/tm/cm/sync-status" \
        | jq -r '.entries[].nestedStats.entries.status.description')

    echo "Sync Status : $CHANGE"

    # Passer à == In Sync ? Au cas ou il y a un autre statut que Changes Pending, comme Initial sync..
    if [[ "$CHANGE" != "Changes Pending" ]]; then
        echo "Pas de synchro nécessaire"
        echo "Sync Status : $CHANGE - Pas de synchro nécessaire - au suivant" >> "$LOGFILE"
        continue
    fi

    echo "Sync Status : $CHANGE" >> "$LOGFILE"

    COLOR=$(curl -sk $AUTH \
        "https://$HOST/mgmt/tm/cm/sync-status" \
        | jq -r '.entries[].nestedStats.entries.color.description')

    echo "Sync color : $COLOR"
    echo "Sync color : $COLOR" >> "$LOGFILE"

    echo "Device Groups disponibles : "
    mapfile -t DGROUPS < <(
        curl -sk $AUTH "https://$HOST/mgmt/tm/cm/device-group" \
        | jq -r '.items[] | select(.type == "sync-failover") | .name'
    )

    #printf 'DGROUPS[%d]=%q\n' "${!DGROUPS[@]}" "${DGROUPS[@]}"

    #DG2=$(curl -sk $AUTH "https://$HOST/mgmt/tm/cm/device-group" | jq -r '.items[] | select(.type == "sync-failover") | .name')
    #echo "$DG2"

    select DG in "${DGROUPS[@]}"; do
        [[ -n "$DG" ]] && break
    done

    if [[ "$COLOR" == "red" ]]; then
        echo "Sync Overwrite vers $DG en cours"
        echo "Sync Overwrite vers $DG en cours" >> "$LOGFILE"

        curl -sk $AUTH -X POST \
            "https://$HOST/mgmt/tm/cm/config-sync" \
            -H "Content-Type: application/json" \
            -d "{
                \"command\":\"run\",
                \"options\":[{\"force-full-load-push-to-group\":\"$DG\"}]
            }" >/dev/null
    else
        echo "Sync vers $DG en cours"
        echo "Sync vers $DG en cours" >> "$LOGFILE"

        curl -sk $AUTH -X POST \
            "https://$HOST/mgmt/tm/cm/config-sync" \
            -H "Content-Type: application/json" \
            -d "{
                \"command\":\"run\",
                \"options\":[{\"to-group\":\"$DG\"}]
            }" >/dev/null
    fi

    if poll_sync "$HOST"; then
        echo -e "Sync Status ($DG) : In Sync $OK"
        echo "Sync Status ($DG) : In Sync" >> "$LOGFILE"
        ((o++))
    else
        echo -e "Sync Status ($DG) : Failed $ERR"
        echo "Sync Status ($DG) : Failed" >> "$LOGFILE"
        ((k++))
    fi

done

show_recap "$h" "$o" "$k"