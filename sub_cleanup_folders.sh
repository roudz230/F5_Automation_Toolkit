#!/bin/bash

# Répertoire racine du projet (emplacement du script)
BASE_DIR="$(dirname "$0")"

# Dossiers à nettoyer
DIRS=(
    "$BASE_DIR/backups"
    "$BASE_DIR/logs"
    "$BASE_DIR/logs/before"
    "$BASE_DIR/logs/after"
)

read -p "Confirmer le nettoyage des répertoires ? (y/N) : " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 0

echo "=== Nettoyage des répertoires ==="

for DIR in "${DIRS[@]}"; do
    if [[ -d "$DIR" ]]; then
        echo "Nettoyage : $DIR"
        rm -f "$DIR"/*
    else
        echo "Dossier absent (ignoré) : $DIR"
    fi
done

echo "Nettoyage terminé."