#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

MAX_JOBS=4
TMP_DIR="tmp/ucs_parallel"
#mkdir -p "$TMP_DIR"

: > "$TMP_DIR/hosts"
: > "$TMP_DIR/ok"
: > "$TMP_DIR/ko"

# Lancement génération backup en parallele sur 4 hosts

# Fonction backup (1 host)
backups_ucs() {
    local HOST="$1"
    local UCS_NAME="$HOST-$TIMESTAMP-before.ucs"

    echo ""
    #echo "=============================================================="
    echo "Création UCS sur $HOST - $(date)"
    #echo "=============================================================="

    echo 1 >> "$TMP_DIR/hosts"

    if [[ "$LOGIN" == "root" ]]; then
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "tmsh save sys ucs $UCS_NAME" </dev/null
        )
        RET=$?
    else
        PROMPT=$(sshpass -p "$LOGINPWD" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT_MEDIUM \
            -o LogLevel=ERROR \
            "$LOGIN@$HOST" \
            "save sys ucs $UCS_NAME" </dev/null
        )
        RET=$?
    fi

    if [[ $RET -eq 0 ]]; then
        echo ""
        echo -e "UCS créé sur $HOST $OK"
        echo 1 >> "$TMP_DIR/ok"
    else
        echo ""
        echo -e "UCS en erreur sur $HOST $ERR"
        echo 1 >> "$TMP_DIR/ko"
    fi
}

read -p "Saisir le login : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

while read -r HOST; do
    [[ -z "$HOST" ]] && continue

    # Limitation du nombre de jobs
    while [[ $(jobs -rp | wc -l) -ge $MAX_JOBS ]]; do
        sleep 1
    done

    sleep 1
    backups_ucs "$HOST" &
done < "$HOSTS"

# Attendre la fin de tous les jobs
wait

h=$(wc -l < "$TMP_DIR/hosts")
o=$(wc -l < "$TMP_DIR/ok")
k=$(wc -l < "$TMP_DIR/ko")

show_recap "$h" "$o" "$k"