#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

SEND_BASE=0
SEND_HF=0
SEND_HF_DMZR=0

check_hosts_file "$HOSTS"

# Vérification si l'ISO existe
for ISO in "$BASE_ISO" "$HF_ISO" "$HF_DMZR_ISO"; do
    if [ ! -f "$ISO" ]; then
        echo -e "ISO $ISO introuvable $ERR"
        exit 1
    fi
done

# Fonction en charge de l'upload de l'iso
upload_iso() {
    local HOST="$1"
    local ISO="$2"

    echo "Upload ISO $(basename "$ISO") en cours"

    sshpass -p "$ROOTPWD" scp \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=$SSH_TIMEOUT_LONG \
        -o LogLevel=ERROR \
        "$ISO" "root@$HOST:/shared/images/"

    if [ $? -eq 0 ]; then
        echo -e "Upload OK $OK"
        ((o++))
        return 0
    else
        echo -e "Upload en erreur $ERR"
        ((k++))
        return 1
    fi
}

# Début du script
read -sp "Saisir le mot de passe du compte root : " ROOTPWD
echo ""

read -p "Envoyer l'ISO de base ($(basename "$BASE_ISO")) ? (O/N) : " CONFIRM_BASE
[[ "$CONFIRM_BASE" =~ ^[Oo]$ ]] && SEND_BASE=1

read -p "Envoyer l'Hotfix ($(basename "$HF_ISO")) ? (O/N) : " CONFIRM_HF
[[ "$CONFIRM_HF" =~ ^[Oo]$ ]] && SEND_HF=1

read -p "Envoyer l'Hotfix DMZR ($(basename "$HF_DMZR_ISO")) ? (O/N) : " CONFIRM_HF_DMZR
[[ "$CONFIRM_HF_DMZR" =~ ^[Oo]$ ]] && SEND_HF_DMZR=1

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "        Upload vers $HOST"
    echo "=============================================================="

    ((h++))

    [[ $SEND_BASE -eq 1 ]] && upload_iso "$HOST" "$BASE_ISO"
    [[ $SEND_HF -eq 1 ]] && upload_iso "$HOST" "$HF_ISO"
    [[ $SEND_HF_DMZR -eq 1 ]] && upload_iso "$HOST" "$HF_DMZR_ISO"
done

show_recap "$h" "$o" "$k"