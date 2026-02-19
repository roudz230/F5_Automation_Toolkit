#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login (sauf root) : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""
read -p "Saisir l'étape (before ou after) : " PHASE
PHASE="${PHASE,,}"
echo ""

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Checks sur $HOST"
    echo "=============================================================="

    LOGFILE="$LOGS_DIR/$PHASE/${TIMESTAMP}_${HOST}_masterkeydecrypt_${PHASE}.log"
    ((h++))

    sshpass -p "$LOGINPWD" ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT_LONG \
        -o LogLevel=ERROR \
        "$LOGIN@$HOST" <<'EOF' > "$LOGFILE" 2>&1

bash
# Master Key decrypt failure - decrypt failure - final
more /var/log/ltm | grep "Master Key decrypt failure"

EOF

    if [[ -s "$LOGFILE" ]]; then
        echo -e "Master Key decrypt failure $ERR"
        ((k++))
    else
        echo -e "Aucun problème détecté $OK"
        ((o++))
    fi

done

show_recap "$h" "$o" "$k"