#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Create UCS sur $HOST"
    echo "=============================================================="

    ((h++))

    if [[ "$LOGIN" == "root" ]]; then
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "tmsh save sys ucs $HOST-${TIMESTAMP}-before.ucs" 2>&1
        )
        RET=$?
    else
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "save sys ucs $HOST-${TIMESTAMP}-before.ucs" 2>&1
        )
        RET=$?
    fi

    if [[ $RET -eq 0 ]]; then
        echo -e "UCS créé $OK"
        ((o++))
    else
        echo -e "UCS en erreur $ERR"
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"