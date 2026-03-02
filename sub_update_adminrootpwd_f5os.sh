#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

read -p "Saisir le login (sauf admin/root) : " LOGIN
read -sp "Saisir le mot de passe du compte $LOGIN : " LOGINPWD
echo ""
read -sp "Saisir le nouveau mot de passe du compte root : " NEWROOTPWD
echo ""
read -sp "Saisir le nouveau mot de passe du compte admin : " NEWADMINPWD
echo ""

run_temp_expect() {
    local HOST="$1"
    local LOGIN="$2"
    local LOGINPWD="$3"
    local NEWROOTPWD="$4"
    local NEWADMINPWD="$5"

    #expect -f - <<'EOF' "$LOGIN" "$LOGINPWD" "$HOST" "$NEWROOTPWD" "$NEWADMINPWD"
    expect -f - <<'EOF' "$LOGIN" "$LOGINPWD" "$HOST" "$NEWROOTPWD" "$NEWADMINPWD" >/dev/null
        set adminuser [lindex $argv 0]
        set adminpass [lindex $argv 1]
        set host [lindex $argv 2]
        set newpassroot [lindex $argv 3]
        set newpassadmin [lindex $argv 4]

        set timeout 20

        log_user 0
        spawn sshpass -p "$adminpass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 $adminuser@$host
        log_user 1

        after 2000
        send "system aaa authentication users user root config set-password password\r"
        expect "Value for 'password' (<string>):"
        #after 500
        send -- "$newpassadmin\r"
        expect "response Password successfully updated."
        #after 10000

        send "system aaa authentication users user admin config set-password password\r"
        expect "Value for 'password' (<string>):"
        #after 500
        send -- "$newpassroot\r"
        expect "response Password successfully updated."
        #after 5000

        send "exit\r"

        expect eof
EOF

    return $?
}

run_expect() {
    local HOST="$1"
    local USERNAME="$2"
    local TMPPASS="$3"
    local NEWPASS="$4"

    #expect -f - <<'EOF' "$HOST" "$USERNAME" "$TMPPASS" "$NEWPASS"
    expect -f - <<'EOF' "$HOST" "$USERNAME" "$TMPPASS" "$NEWPASS" >/dev/null
        set host [lindex $argv 0]
        set username [lindex $argv 1]
        set tmppass [lindex $argv 2]
        set newpass [lindex $argv 3]

        # Désactive l'affichage des commandes expect
        log_user 1
        set timeout 20

        # Connexion SSH F5OS
        spawn ssh -o StrictHostKeyChecking=no $username@$host

        # Authentification
        expect {
            "Password:" {
                send -- "$tmppass\r"
            }
            timeout {
                puts "Timeout pendant le login sur $host"
                exit 2
            }
            eof {
                puts "Connexion refusée par $host"
                exit 3
            }
        }

        # Demande de changement de mot de passe imposé par F5OS
        expect {
            "(current) UNIX password:" {
                send -- "$tmppass\r"
                exp_continue
            }
            "New password:" {
                send -- "$newpass\r"
                exp_continue
            }
            "Retype new password:" {
                send -- "$newpass\r"
                exp_continue
            }
            "#" {
                # On est connecté en shell
                send -- "\r"
                send -- "\r"
                send -- "exit\r"
            }
        }

        expect eof
EOF
}

print_pwd_result() {
    local HOST="$1"
    local ACCOUNT="$2"
    local RET="$3"

    if [[ $RET -eq 0 ]]; then
        echo -e "Modification password $ACCOUNT effectuée $OK"
        echo ""
        ((ho++))
    else
        echo -e "Modification password $ACCOUNT en erreur $ERR"
        echo ""
        ((hk++))
    fi
}

for HOST in $(cat $HOSTS); do
    echo ""
    # Phase 1 - Changement temporaire
    echo "============================================================"
    echo "        Update admin/root sur $HOST        "
    echo "============================================================"
    echo ""
    echo ">>> Mise à jour des mdp admin et root temporaires en cours"

    ((h++))
    ho=0
    hk=0

    run_temp_expect "$HOST" "$LOGIN" "$LOGINPWD" "$NEWROOTPWD" "$NEWADMINPWD"
    RET=$?
    echo ""
    print_pwd_result "$HOST" "root/admin" "$RET"

    sleep 1

    # Phase 2 - Changement définitif
    echo ""
    echo ""
    echo ">>> Mise à jour du mdp root définitif en cours"
    run_expect "$HOST" "root" "$NEWADMINPWD" "$NEWROOTPWD"
    RET=$?
    #echo "Retour expect $RET"
    echo ""
    print_pwd_result "$HOST" "root" "$RET"

    sleep 1

    echo ""
    echo ""
    echo ">>> Mise à jour du mdp admin définitif en cours"
    run_expect "$HOST" "admin" "$NEWROOTPWD" "$NEWADMINPWD"
    RET=$?
    #echo "Retour expect $RET"
    echo ""
    print_pwd_result "$HOST" "admin" "$RET"

    if [ $ho -eq 3 ]; then
        ((o++))
    else
        ((k++))
    fi
done

show_recap "$h" "$o" "$k"
