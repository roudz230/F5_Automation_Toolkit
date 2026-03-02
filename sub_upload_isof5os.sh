#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

for ISO in "$ISO_F5OS"; do
    if [ ! -f "$ISO" ]; then
        echo -e "ISO $ISO introuvable $ERR"
        exit 1
    fi
done

read -sp "Saisir le mot de passe du compte root : " ROOTPWD
echo ""

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=================================================================="
    echo "        Upload vers $HOST"
    echo "=================================================================="

    echo "Upload ISO en cours"

    sshpass -p "$ROOTPWD" scp \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT_LONG \
        -o LogLevel=ERROR \
        "$ISO_F5OS" "root@$HOST:/var/import/staging/"

    if [ $? -eq 0 ]; then
        echo -e "Upload OK $OK"
        ((o++))
    else
        echo -e "Upload en erreur $ERR"
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"