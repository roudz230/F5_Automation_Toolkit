#!/bin/bash

# Script from https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/installation.html

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login : " LOGIN
echo ""
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""

#set -e

CREDS="$LOGIN:$LOGINPWD"
RPM_NAME=$(basename $TARGET_RPM)
CURL_FLAGS="--silent --write-out \n --insecure -u $CREDS"

poll_task () {
    STATUS="STARTED"
    while [ $STATUS != "FINISHED" ]; do
        sleep 1
        RESULT=$(curl ${CURL_FLAGS} "https://$TARGET/mgmt/shared/iapp/package-management-tasks/$1")
        STATUS=$(echo $RESULT | jq -r .status)
        if [ $STATUS = "FAILED" ]; then
            echo -e "$ERR Failed to $(echo $RESULT | jq -r .operation) \"package:\" \
$(echo $RESULT | jq -r .errorMessage)"
            ((k++))
            exit 1
        fi
    done
}

for TARGET in $(cat "$HOSTS"); do
    echo ""
    echo "=============================================================="
    echo "Install AS3 sur $TARGET"
    echo "=============================================================="

    ((h++))

    #Get list of existing f5-appsvcs packages on target
    TASK=$(curl ${CURL_FLAGS} -H "Content-Type: application/json" \
        -X POST https://$TARGET/mgmt/shared/iapp/package-management-tasks -d '{"operation": "QUERY"}')
    poll_task $(echo $TASK | jq -r .id)

    AS3RPMS=$(echo $RESULT | jq -r '.queryResponse[].packageName | select(. | startswith("f5-appsvcs"))')
    SDRPMS=$(echo $RESULT | jq -r '.queryResponse[].packageName | select(. | startswith("f5-service-discovery"))')

    #Uninstall existing f5-appsvcs packages on target
    for PKG in $AS3RPMS; do
        echo "Uninstalling $PKG on $TARGET"
        DATA="{\"operation\":\"UNINSTALL\",\"packageName\":\"$PKG\"}"
        TASK=$(curl ${CURL_FLAGS} "https://$TARGET/mgmt/shared/iapp/package-management-tasks" \
            --data $DATA -H "Origin: https://$TARGET" -H "Content-Type: application/json;charset=UTF-8")
        poll_task $(echo $TASK | jq -r .id)
    done

    #Uninstall existing service discovery packages on target
    for PKG in $SDRPMS; do
        echo "Uninstalling $PKG on $TARGET"
        DATA="{\"operation\":\"UNINSTALL\",\"packageName\":\"$PKG\"}"
        TASK=$(curl ${CURL_FLAGS} "https://$TARGET/mgmt/shared/iapp/package-management-tasks" \
            --data $DATA -H "Origin: https://$TARGET" -H "Content-Type: application/json;charset=UTF-8")
        poll_task $(echo $TASK | jq -r .id)
    done

    #Upload new f5-appsvcs RPM to target
    echo "Uploading RPM to https://$TARGET/mgmt/shared/file-transfer/uploads/$RPM_NAME"
    LEN=$(wc -c $TARGET_RPM | awk 'NR==1{print $1}')
    RANGE_SIZE=5000000
    CHUNKS=$(($LEN / $RANGE_SIZE))

    for i in $(seq 0 $CHUNKS); do
        START=$(($i * $RANGE_SIZE))
        END=$(($START + $RANGE_SIZE))
        END=$(($LEN < $END ? $LEN : $END))
        OFFSET=$(($START + 1))

        curl ${CURL_FLAGS} -o /dev/null --write-out "" \
            https://$TARGET/mgmt/shared/file-transfer/uploads/$RPM_NAME \
            --data-binary @(tail -c +$OFFSET $TARGET_RPM) \
            -H "Content-Type: application/octet-stream" \
            -H "Content-Range: $START-$(($END - 1))/$LEN" \
            -H "Content-Length: $(($END - $START))" \
            -H "Connection: keep-alive"
    done

    #Install f5-appsvcs on target
    echo "Installing $RPM_NAME on $TARGET"
    DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$RPM_NAME\"}"
    TASK=$(curl ${CURL_FLAGS} "https://$TARGET/mgmt/shared/iapp/package-management-tasks" \
        --data $DATA -H "Origin: https://$TARGET" -H "Content-Type: application/json;charset=UTF-8")
    poll_task $(echo $TASK | jq -r .id)

    echo "Waiting for /info endpoint to be available"
    until curl ${CURL_FLAGS} -o /dev/null --write-out "" --fail --silent \
        "https://$TARGET/mgmt/shared/appsvcs/info"; do
        sleep 1
    done

    echo -e "Installed $RPM_NAME on $TARGET $OK"
    ((o++))
done

show_recap "$h" "$o" "$k"
exit 0