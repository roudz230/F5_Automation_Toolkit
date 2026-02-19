#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

# Affichage logs AS3
show_as3_logs () {
    local RESPONSE=$1
    local TARGET=$2
    local MSG=$3

    if [[ "$RESPONSE" == *"$TARGET"* ]]; then
        echo -e "$MSG : $RESPONSE $OK"
        ((ho++))
    else
        echo -e "$MSG : $RESPONSE $ERR"
        ((hk++))
    fi
}

read -p "Saisir le login : " LOGIN
echo ""
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

for HOST in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "           Check AS3 sur $HOST"
    echo "=============================================================="

    ((h++))
    ho=0
    hk=0

    RESPONSE1=$(curl -sku $LOGIN:$LOGINPWD -H "Content-Type: application/json" -X GET https://$HOST/mgmt/shared/appsvcs/info/ | jq -r '.version')
    show_as3_logs "$RESPONSE1" "$AS3_VERSION" "Curl /mgmt/shared/appsvcs/info/"

    RESPONSE2=$(curl -sku $LOGIN:$LOGINPWD -I -X GET https://$HOST/mgmt/shared/appsvcs/declare/ | grep "HTTP")
    RESPONSE2_HTTPCODE=$(echo "$RESPONSE2" | tr -d '\r\n')
    show_as3_logs "$RESPONSE2_HTTPCODE" "200" "Curl /mgmt/shared/appsvcs/declare/"

    RESPONSE3=$(curl -sku $LOGIN:$LOGINPWD -I -X GET https://$HOST/mgmt/shared/service-discovery/task/ | grep "HTTP")
    RESPONSE3_HTTPCODE=$(echo "$RESPONSE3" | tr -d '\r\n')
    show_as3_logs "$RESPONSE3_HTTPCODE" "200" "Curl /mgmt/shared/service-discovery/task/"

    if [ $ho -eq 3 ]; then
        ((o++))
    else
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"