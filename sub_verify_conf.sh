#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login radius : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

LOGFILE="$LOGS_DIR/${TIMESTAMP}_verify.log"

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=================================================================="
    echo "load sys config verify sur $HOST"
    echo "=================================================================="

    ((h++))

    echo "" >> "$LOGFILE"
    echo "========== $HOST ==========" >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    OUT=$(sshpass -p "$LOGINPWD" ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
        -o LogLevel=ERROR \
        "$LOGIN@$HOST" \
        "load sys config verify" 2>&1 \
        | tee -a "$LOGFILE")

    ERR_COUNT=$(echo "$OUT" | grep -c "^Error:")
    WARN_COUNT=$(echo "$OUT" | grep -c "^There were warnings:")

    if [[ $ERR_COUNT -gt 0 ]]; then
        echo "echo -e Vérification en erreur $ERR"
        ((k++))
    elif [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "Vérification avec warnings $WARN"
        ((o++))
    else
        echo -e "Vérification OK $OK"
        ((o++))
    fi

    echo "$OUT" | awk '
        /^Error:/ { print }
        /^There were warnings:/ { inwarn=1; next }
        inwarn { print }
    '

    echo "" >> "$LOGFILE"
done

show_recap "$h" "$o" "$k"