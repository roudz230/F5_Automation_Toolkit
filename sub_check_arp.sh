#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

LOGFILE="$LOGS_DIR/${TIMESTAMP}_check_arp.log"

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Check ARP sur $HOST"
    echo "=============================================================="

    ((h++))

    if [[ "$LOGIN" == "root" ]]; then
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "tmsh show net arp" 2>&1
        )
        RET=$?
    else
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "show net arp" 2>&1
        )
        RET=$?
    fi

    echo "" >> "$LOGFILE"
    echo "=============$HOST=============" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    if [[ $RET -eq 0 ]]; then
        echo -e "Vérification effectuée $OK"
        echo "$PROMPT" >> "$LOGFILE"
        ((o++))
    else
        echo -e "Vérification en erreur $ERR"
        echo "Erreur SSH $RET" >> "$LOGFILE"
        ((k++))
    fi

    echo "" >> "$LOGFILE"
done

show_recap "$h" "$o" "$k"