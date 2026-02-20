#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login (sauf admin/root) : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""
read -sp "Saisir le mot de passe du compte root : " ROOTPWD
echo ""

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Download du backup de $HOST"
    echo "=============================================================="

    ((h++))

    BACKUP_NAME="${HOST}-${TIMESTAMP}-before.xml"
    URL="https://$HOST/api/data/openconfig-system:system/f5-database:database/f5-database:config-backup"

    RESP=$(curl -sk -u "$LOGIN:$LOGINPWD" \
        -H "Content-Type: application/yang-data+json" \
        -X POST "$URL" \
        -d "{\"f5-database:name\":\"$BACKUP_NAME\"}" \
        -w "\n%{http_code}"
    )

    HTTP_CODE=$(echo "$RESP" | tail -n1)
    BODY=$(echo "$RESP" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
        #echo -e "Backup généré $BACKUP_NAME $OK"
    else
        echo -e "Echec génération du backup sur $HOST $ERR"
        echo "$BODY" | tee -a "$LOGS_DIR/backup-$HOST-error.log"
        continue
    fi

    sleep 2

    sshpass -p "$ROOTPWD" scp \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT \
        -o LogLevel=ERROR \
        "root@$HOST:/var/F5/system/configs/$BACKUP_NAME" \
        "$BACKUP_DIR/"

    if [ $? -eq 0 ]; then
        echo -e "Backup téléchargé : $BACKUP_DIR/$BACKUP_NAME $OK"
        ((o++))
    else
        echo -e "Echec du téléchargement du backup depuis $HOST $ERR"
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"