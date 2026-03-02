#!/bin/bash

source "$(dirname "$0")/functions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login (sauf admin/root) : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""
read -sp "Saisir le nouveau mot de passe du compte root : " NEWROOTPWD
echo ""
read -sp "Saisir le nouveau mot de passe du compte admin : " NEWADMINPWD
echo ""

for HOST in $(cat $HOSTS); do
    echo ""
    echo "=============================================================="
    echo "   Update admin/root sur $HOST"
    echo "=============================================================="

    ROLE=$(get_failover_state "$HOST" "$LOGIN" "$LOGINPWD")
    MODE=$(get_cluster_mode "$HOST" "$LOGIN" "$LOGINPWD")
    show_role_status "$HOST" "$ROLE" "$MODE"

    if [[ ("$MODE" == "STANDALONE" || "$MODE" == "CLUSTER") && "$ROLE" == "ACTIVE" ]]; then
        ((h++))

        #expect -f - << 'EOF' "$LOGIN" "$LOGINPWD" "$HOST" "$NEWROOTPWD" "$NEWADMINPWD"
        expect -f - << 'EOF' "$LOGIN" "$LOGINPWD" "$HOST" "$NEWROOTPWD" "$NEWADMINPWD" >/dev/null

set adminuser [lindex $argv 0]
set adminpass [lindex $argv 1]
set host [lindex $argv 2]
set newpassroot [lindex $argv 3]
set newpassadmin [lindex $argv 4]

set timeout 20

log_user 0
spawn sshpass -p "$adminpass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o LogLevel=ERROR $adminuser@$host
log_user 1

expect {
    -re {\(tmos\)#} {
        send "bash\r"
        exp_continue
    }
    -re {(\$|#)} { }
}

send "tmsh modify auth password root\r"
expect -re "changing password for root"
expect -re "new password:"
after 500
send -- "$newpassroot\r"
expect -re "confirm password:"
after 500
send -- "$newpassroot\r"

send "tmsh modify auth user admin prompt-for-password\r"
expect -re "changing password for admin"
expect -re "new password:"
after 500
send -- "$newpassadmin\r"
expect -re "confirm password:"
after 500
send -- "$newpassadmin\r"

send "exit\r"
send "quit\r"

expect eof
EOF

        if [[ $? -eq 0 ]]; then
            echo ""
            echo -e "   -> Modification password root et admin effectuée $OK"
            ((o++))
        else
            echo ""
            echo -e "   -> Modification password root et admin en erreur $ERR"
            ((k++))
        fi
    fi
done

show_recap "$h" "$o" "$k"