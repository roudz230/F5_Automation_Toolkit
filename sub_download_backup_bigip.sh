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
    echo "Download du backup de $HOST"
    echo "=============================================================="

    ((h++))

    if [[ "$LOGIN" == "root" ]]; then
        LAST_UCS=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "ls -lt /var/local/ucs/*.ucs 2>/dev/null | head -1"
        )
    else
        LAST_UCS=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "run /util bash -c 'ls -lt /var/local/ucs/*.ucs 2>/dev/null | head -1'"
        )
    fi

    if [ -z "$LAST_UCS" ]; then
        echo -e "Aucun UCS trouvé sur $HOST $INF"
        continue
    fi

    UCS_FILE=$(basename "$LAST_UCS")

    #echo "Dernier backup : $UCS_FILE"

    sshpass -p "$LOGINPWD" scp \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT \
        -o LogLevel=ERROR \
        "$LOGIN@$HOST:$LAST_UCS" \
        "$BACKUP_DIR/"

    if [ $? -eq 0 ]; then
        echo -e "Backup téléchargé : $BACKUP_DIR/$UCS_FILE $OK"
        ((o++))
    else
        echo -e "Echec du téléchargement du backup depuis $HOST $ERR"
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"