#!/bin/bash

source "$(dirname "$0")/fonctions.sh"
source "$(dirname "$0")/config.sh"

check_hosts_file "$HOSTS"

# Menu
while true; do
    #clear
    echo "=============================================================="
    echo ""
    echo "                        F5 Admin Toolkit                      "
    echo ""
    echo "=============================================================="
    echo "1  - Modifier les mdp admin/root BigIP"
    echo "2  - Modifier les mdp admin/root F5OS"
    echo "3  - Upload ISO BigIP"
    echo "4  - Upload ISO F5OS"
    echo "5  - Créer backups BigIP"
    echo "6  - Download backups BigIP"
    echo "7  - Download backups F5OS"
    echo "8  - Verify"
    echo "9  - Verify GTM"
    echo "10 - Check AFM / ASM / GTM / LTM"
    echo "11 - Diff Check AFM / ASM / GTM / LTM"
    echo "12 - Check AS3"
    echo "13 - Install AS3"
    echo "14 - Cluster Failover"
    echo "15 - Synchroniser les clusters via API"
    echo "0  - Quitter"
    echo "=============================================================="

    read -p "Votre choix : " CHOIX

    case $CHOIX in

    1)
        echo ">>> Lancement de sub_update_adminrootpwd_bigip.sh"
        ./sub_update_adminrootpwd_bigip.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;
    
    2)
        echo ">>> Lancement de sub_update_adminrootpwd_f5os.sh"
        ./sub_update_adminrootpwd_f5os.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    3)
        echo ">>> Lancement de sub_upload_isobigip.sh"
        ./sub_upload_isobigip.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    4)
        echo ">>> Lancement de sub_upload_isof5os.sh"
        ./sub_upload_isof5os.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    5)
        echo ">>> Lancement de sub_create_ucs.sh"
        ./sub_create_ucs.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    6)
        echo ">>> Lancement de sub_download_backup_bigip.sh"
        ./sub_download_backup_bigip.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    7)
        echo ">>> Lancement de sub_download_backup_f5os.sh"
        ./sub_download_backup_f5os.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    8)
        echo ">>> Lancement de sub_verify_conf.sh"
        ./sub_verify_conf.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    9)
        echo ">>> Lancement de sub_verifygtm_conf.sh"
        ./sub_verifygtm_conf.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    10)
        echo ">>> Lancement de sub_check_state_ssh.sh"
        ./sub_check_state_ssh.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    11)
        echo ">>> Lancement de sub_diff_check_state.sh"
        ./sub_diff_check_state.sh
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    12)
        echo ">>> Lancement de sub_check_as3.sh"
        ./sub_check_as3.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    13)
        echo ">>> Lancement de sub_install_as3.sh"
        ./sub_install_as3.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    14)
        echo ">>> Lancement de sub_failover_bigip.sh"
        ./sub_failover_bigip.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    15)
        echo ">>> Lancement de sub_sync_cluster_api.sh"
        ./sub_sync_cluster_api.sh "$HOSTS"
        read -p "Appuyez sur Entrée pour continuer..."
        ;;

    0)
        echo "Au revoir."
        exit 0
        ;;

    *)
        echo "Choix invalide. Essayez encore."
        sleep 1
        ;;
    esac

done