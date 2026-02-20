#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

BEFORE_DIR="$LOGS_DIR/before"
AFTER_DIR="$LOGS_DIR/after"

extract_summary() {
    sed -n '/^===== SUMMARY =====/,/^===== END SUMMARY =====/p' "$1"
}

echo
echo "===== SUMMARY DIFF REPORT ====="
echo

for BEFORE_FILE in "$BEFORE_DIR"/*_state_before.log; do
    HOST=$(basename "$BEFORE_FILE" | sed -E 's/^[^_]+_[^_]+_([^_]+)_.*/\1/')
    AFTER_FILE=$(ls "$AFTER_DIR"/*_"$HOST"_state_after.log 2>/dev/null | sort | tail -n 1)

    #echo "$HOST"
    #echo "$AFTER_FILE"

    if [[ ! -f "$AFTER_FILE" ]]; then
        echo -e "$HOST : Fichier AFTER manquant $WARN"
        continue
    fi

    BEFORE_SUMMARY=$(mktemp)
    AFTER_SUMMARY=$(mktemp)

    extract_summary "$BEFORE_FILE" > "$BEFORE_SUMMARY"
    extract_summary "$AFTER_FILE" > "$AFTER_SUMMARY"

    if diff -u "$BEFORE_SUMMARY" "$AFTER_SUMMARY" > /dev/null; then
        echo -e "$HOST : Pas de différence $OK"
        echo
    else
        echo -e "$HOST : Différences détectées $WARN"
        echo
        diff -u "$BEFORE_SUMMARY" "$AFTER_SUMMARY"
        echo
        echo
    fi

    rm -f "$BEFORE_SUMMARY" "$AFTER_SUMMARY"
done
