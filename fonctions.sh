# Couleurs & Symboles
RESET="\e[Om"
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m" 
CYAN="\e[36m"
OK="${BOLD}${GREEN}\u2705${RESET}"
ERR="${BOLD}${RED}\u274C${RESET}"
WARN="${BOLD}${YELLOW}\u26A1${RESET}"
INF="${BOLD}${CYAN}\u2755${RESET}"


# Couleurs & Symboles
RESET="\e[0m"
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
OK="${BOLD}${GREEN}\u2705${RESET}"
ERR="${BOLD}${RED}\u274C${RESET}"
WARN="${BOLD}${YELLOW}\u26A1${RESET}"
INF="${BOLD}${CYAN}\u2755${RESET}"

# Vérification fichier hosts
check_hosts_file() {
    local HOSTS=$1

    if [[ -z "$HOSTS" ]]; then
        echo -e "ERREUR : aucun fichier hosts fourni $ERR"
        exit 1
    fi

    if [[ ! -f "$HOSTS" ]]; then
        echo -e "ERREUR : fichier $HOSTS introuvable $ERR"
        exit 1
    fi

    if [[ ! -s "$HOSTS" ]]; then
        echo -e "ERREUR : fichier $HOSTS vide $ERR"
        exit 1
    fi
}

# Détection du rôle du device via SSH (analyse prompt)
get_role_ssh() {
    local HOST=$1
    local USER=$2
    local PASS=$3
    local SSH_TIMEOUT=10

    if [[ "$USER" == "root" ]]; then
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "tmsh show sys failover 2>/dev/null"
        )
    else
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "show sys failover 2>/dev/null"
        )
    fi

    if echo "$PROMPT" | grep -q "active"; then
        echo "ACTIVE"
    elif echo "$PROMPT" | grep -q "standby"; then
        echo "STANDBY"
    #elif echo "$PROMPT" | grep -q "(Standalone)"; then
    #    echo "STANDALONE"
    else
        echo "$PROMPT UNKNOWN"
    fi
}

# Détermine s'il s'agit d'un device en cluster ou standalone
get_cluster_mode() {
    local HOST=$1
    local USER=$2
    local PASS=$3
    local PROMPT
    local COUNT

    if [[ "$USER" == "root" ]]; then
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "tmsh list cm device one-line 2>/dev/null"
        )
    else
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "list cm device one-line 2>/dev/null"
        )
    fi

    if [[ -z "$PROMPT" ]]; then
        echo "UNKNOWN"
        return
    fi

    COUNT=$(echo "$PROMPT" | grep -c "cm device")

    if [[ "$COUNT" -gt 1 ]]; then
        echo "CLUSTER"
    else
        echo "STANDALONE"
    fi
}

# Helper : affiche un résumé propre
show_role_status() {
    local HOST=$1
    local ROLE=$2
    local MODE=$3

    if [[ "$MODE" == "STANDALONE" && "$ROLE" == "ACTIVE" ]]; then
        echo " -> [$HOST] Standalone = modification AUTORISEE"
    elif [[ "$MODE" == "CLUSTER" && "$ROLE" == "ACTIVE" ]]; then
        echo " -> [$HOST] Membre ACTIF d'un cluster = modification AUTORISEE"
    elif [[ "$MODE" == "CLUSTER" && "$ROLE" == "STANDBY" ]]; then
        echo " -> [$HOST] Membre PASSIF d'un Cluster = modification INTERDITE"
    else
        echo " -> [$HOST] Impossible de déterminer l'état ($MODE / $ROLE) = ABANDON"
        continue
    fi
    echo ""
}

# Récupère l'état du failover
get_failover_state() {
    local HOST=$1
    local USER=$2
    local PASS=$3
    local PROMPT

    if [[ "$USER" == "root" ]]; then
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "tmsh show sys failover 2>/dev/null"
        )
    else
        PROMPT=$(sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=$SSH_TIMEOUT \
            "$USER@$HOST" \
            "show sys failover 2>/dev/null"
        )
    fi

    if echo "$PROMPT" | grep -q "active"; then
        echo "ACTIVE"
    elif echo "$PROMPT" | grep -q "standby"; then
        echo "STANDBY"
    else
        echo "UNKNOWN"
    fi
}

# Affichage résumé du script
show_recap () {
    local TOTAL_HOSTS=$1
    local SUCCESS=$2
    local FAILED=$3

    echo ""
    echo "------------------------------------"
    echo "Récap :"
    echo "Nb Hosts   : $TOTAL_HOSTS"
    echo -e "Success $OK : $SUCCESS"
    echo -e "Failed  $ERR : $FAILED"
    echo "------------------------------------"
    echo ""
}