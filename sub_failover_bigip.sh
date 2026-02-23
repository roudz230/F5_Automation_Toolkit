#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login (sauf admin/root) : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

for HOST in $(cat $HOSTS); do
    echo ""
    echo "=============================================================="
    echo "Failover cluster - Vérification sur $HOST"
    echo "=============================================================="

    ROLE=$(get_failover_state "$HOST" "$LOGIN" "$LOGINPWD")
    MODE=$(get_cluster_mode "$HOST" "$LOGIN" "$LOGINPWD")
    show_role_status "$HOST" "$ROLE" "$MODE"

    #if [[ ("$MODE" == "STANDALONE" || "$MODE" == "CLUSTER") && "$ROLE" == "ACTIVE" ]]; then
    if [[ "$MODE" == "CLUSTER" && "$ROLE" == "ACTIVE" ]]; then
        ((h++))

        sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "run sys failover standby"

        if [[ $? -eq 0 ]]; then
            echo -e "Bascule cluster $OK"
            ((o++))
        else
            echo -e "Bascule cluster en erreur $ERR"
            ((k++))
        fi
    fi
done

show_recap "$h" "$o" "$k"
