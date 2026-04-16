#!/bin/bash
# Vérification de l'utilisation du script en mode Administrateur
if [[ $EUID -ne 0 ]]; then
        echo "Mode sudo obligatoire pour run le script !" && exit 1
fi
########## déclaration variables ##########
cibleordi=0
date=0
heure=0
utilisateur=$USER
var_OS=$(uname -s)
var_ss=1
user_cible="wilder"
verif_link="[[ -z \$(find '$absol_path/$nom_doss' -mindepth 1 -print -quit) ]]"
########## declaration fonctions ##########
# Fonction test ip
function test_ip {
    local regex='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$' #merci claude pour le regex, notez que j'ai passé 20 min a comprendre comment il marche

    if [[ "$ip_cible" =~ $regex ]]
        then
            echo "IP valide : $ip_cible"
        else
            echo "Erreur : '$ip_cible' n'est pas une adresse IP valide"
            ask_cible
        fi
}
# Demande l'ip et le compte distant
function ask_cible {
    echo -e "Bonjour et bienvenue sur ce script d'administration \n"
    read -e -p "Quelle est l'ip de la machine cliente? \n  Veuillez rentrer une ip correcte sous la forme **.**.**.**" ip_cible
    test_ip
    read -p "Veuillez rentrer le nom exacte de l'utilisateur cible  " user_cible
}

# Prépare un alias pour la connexion ssh
function ssh_cible {
    ssh -t -o ConnectTimeout=5 "${user_cible}@${ip_cible}" "$*" 2>/dev/null
}

# Teste la connexion ssh et demande l'OS de la cible pour identifier windows ou linux
function connexion_ssh {
    local test1=$(ssh -o ConnectTimeout=5 "$user_cible@$ip_cible" "echo test" 2>/dev/null)
    if [ "$test1" ]
        then
            version_de_lOS=$(ssh_cible "uname -s" 2>/dev/null)
            if [[ "$version_de_lOS" == *"Linux"* ]]
                then
                    detect_os=0  # Linux
                else
                    detect_os=1  # Windows
            fi
        else
            echo "erreur"
            exit 1
    fi
}

# Crée le fichier log et l'initialise
function debut_journalisation {
    echo -e "StartScript \n" >> /var/log/log_evt.log
}

# Ferme le fichier quand l'utilisateur quitte
function quitter {
    echo -e "EndScript\n" >> /var/log/log_evt.log
    exit 0
}
# Mise en variable du nom d'utilisateur

function test_add {
    if [ $# -ne 0 ]
    then
        tableau_new=("$@")
    else
        read -p "Veuillez rentrer les noms des utilisateurs (séparés par des espaces) : " -a tableau_new
    fi
}

# Création de compte Linux

function l_new_user {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "grep -q '^$user_name:' /etc/passwd"
            then
                echo "Utilisateur $user_name déjà existant"
            else
                ssh_cible "sudo -S adduser --allow-bad-names '$user_name'" && echo "Utilisateur $user_name créé avec succès"
            fi
        done
}

# Création de compte Windows

function w_new_user {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "[[ Get-LocalUser -Name '$user_name' ]]"
            then
                echo "Utilisateur $user_name déjà existant"
            else
                ssh_cible "New-LocalUser -Name '$user_name'" && echo "Utilisateur $user_name créé avec succès" 
            fi
        done
}

# Changement de mot de passe Linux

function l_change_password {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "sudo -S grep -q '^$user_name:' /etc/passwd"
            then
                ssh_cible "sudo -S passwd '$user_name'" && echo "Mot de passe de $user_name changé avec succès" 
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Changement de mot de passe Windows

function w_change_password {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "[[ Get-LocalUser -Name '$user_name' ]]"
            then
                ssh_cible "$NewPwd = Read-Host -AsSecureString; Get-LocalUser -Name '$user_name' | Set-LocalUser -Password $NewPwd"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Suppression de compte Linux

function l_del_user {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "grep -q '^$user_name:' /etc/passwd"
            then
                ssh_cible "sudo -S deluser '$user_name'" && echo "L'utilisateur $user_name à bien été supprimé"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Supression de compte Windows

function w_del_user {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "[[ Get-LocalUser -Name '$user_name' ]]"
            then
                ssh_cible "Remove-LocalUser -Name '$user_name'" && echo "L'utilisateur $user_name à bien été supprimé"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Ajout à un groupe d'administration Linux

function l_add_admin {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "grep -q '^$user_name:' /etc/passwd"
            then
                ssh_cible "sudo -S usermod -aG sudo '$user_name'" && echo "L'utilisateur $user_name a été ajouté au groupe Admin"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Ajout à un groupe d'administration Windows

function w_add_admin {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "[[ Get-LocalUser -Name '$user_name' ]]"
            then
                ssh_cible "Add-LocalGroupmember -Group 'Administrators' -Member '$user_name'" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe Administrateur"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Ajout à un groupe Linux

function l_add_group {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "grep -q '^$user_name:' /etc/passwd"
            then
                read -p "Dans quel groupe voulez-vous ajouter $user_name ? " group_name
                    if ! ssh_cible "grep -q '^$group_name:' /etc/group"
                    then
                        read -p "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] " rep
                            if [ "$rep" = "o" ]
                            then
                                ssh_cible "sudo -S groupadd '$group_name'" && echo "Groupe $group_name créé"
                            else
                                echo "D'accord, retour au menu principal" && retour_menu
                            fi
                    fi
                ssh_cible "sudo -S usermod -aG $group_name '$user_name'" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe $group_name"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

#Ajout à un groupe Windows

function w_add_group {
    test_add
        for user_name in "${tableau_new[@]}"
        do
            if ssh_cible "[[ Get-LocalUser -Name '$user_name' ]]"
            then
                read -p "Dans quel groupe voulez-vous ajouter $user_name ? " group_name
                    if ! ssh_cible "[[ Get-LocalGroup -Name '$group_name' ]]"
                    then
                        read -p "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] " rep
                            if [ "$rep" = "o" ]
                            then
                                ssh_cible "New-LocalGroup '$group_name'" && echo "Groupe $group_name créé"
                            else
                                echo "D'accord, retour au menu principal" && retour_menu
                            fi
                    fi
                    ssh_cible "Add-LocalGroupmember -Group '$group_name' -Member '$user_name'" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe $group_name"
            else
                echo "L'utilisateur $user_name n'existe pas"
            fi
        done
}

# Choix de redémarrage Linux
function l_redemarrage {
    read -p "$user_cible@$ip_cible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] " rep5
        if [[ "$rep5" = "o" ]]
            then 
                ssh_cible "sudo -S reboot" && echo " La machine cible est en cours de redémarrage "
            else
                echo "D'accord, retour au menu principal" && retour_menu
        fi
}

# Choix de redémarrage Windows
function w_redemarrage {
    read -p "$user_cible@$ip_cible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] " rep5
        if [[ "$rep5" = "o" ]]
            then 
                ssh_cible "Restart-Computer -ComputerName '$ip_cible' -Force" && echo " La machine cible est en cours de redémarrage "
            else
                echo "D'accord, retour au menu principal" && retour_menu
        fi
}

# Création de répertoire Linux

function l_creer_doss {
    read -p "Où voulez-vous créer votre dossier : " absol_path
        if ! ssh_cible "[[ -e '$absol_path' ]]"
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                                                ssh_cible "sudo -S mkdir -p '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
                                        else
                                                echo "D'accord, retour au menu principal"
                                fi
                else 
                        read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                        ssh_cible "sudo -S mkdir -p '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
        fi
}


# Création de répertoire Windows

function w_creer_doss {
    read -p "Où voulez-vous créer votre dossier : " absol_path
        if [[ $(ssh_cible Test-Path -Path "$absol_path") == "False" ]]
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                                                ssh_cible "New-Item -ItemType Directory -Path '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
                                        else
                                                echo "D'accord, retour au menu principal"
                                fi
                else 
                        read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                        ssh_cible "New-Item -ItemType Directory -Path '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
        fi
}

# Suppression de répertoire Windows
function w_suppr_doss {
    read -p "Où se trouve le dossier à supprimer ? " absol_path
        if [[ $(ssh_cible Test-Path -Path "$absol_path") == "False" ]]
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous rentrer un autre chemin ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                w_suppr_doss
                                        else 
                                                echo "D'accord, retour au menu"
                                fi
                else
                        read -p "D'accord, quel est le nom du dossier à supprimer dans $absol_path ? " nom_doss
                                if [[ $(ssh_cible Test-Path -Path "$absol_path/$nom_doss") == "True" ]]
                                        then
                                                if [[ $(ssh_cible Get-ChildItem "$absol_path/$nom_doss" | Measure-Object).Count -eq 0 ]]
                                                        then
                                                                ssh_cible "Remove-Item -Recurse -Force '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été supprimé dans $absol_path"
                                                        else
                                                                read -p "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] " rep2
                                                                if [[ "$rep2" = "o" ]]
                                                                        then
                                                                                ssh_cible "Remove-Item '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss et son contenu ont bien été supprimé dans $absol_path"
                                                                        else 
                                                                                echo "D'accord, retour au menu"
                                                                fi
                                                fi
                                        else 
                                                echo "La valeur saisie n'existe pas ou n'est pas un dossier"
                                fi
        fi
}


# Suppression de répertoire Linux
function l_suppr_doss {
    read -p "Où se trouve le dossier à supprimer ? " absol_path
        if ! ssh_cible "[[ -e '$absol_path' ]]"
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous rentrer un autre chemin ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                l_suppr_doss
                                        else 
                                                echo "D'accord, retour au menu"
                                fi
                else
                        read -p "D'accord, quel est le nom du dossier à supprimer dans $absol_path ? " nom_doss
                                if ssh_cible "[[ -d '$absol_path/$nom_doss' ]]"
                                        then
                                                if ssh_cible "$verif_link"
                                                        then
                                                                ssh_cible "sudo -S rmdir '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss a bien été supprimé dans $absol_path"
                                                        else
                                                                read -p "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] " rep2
                                                                if [[ "$rep2" = "o" ]]
                                                                        then
                                                                                ssh_cible "sudo -S rm -r '$absol_path/$nom_doss'" && echo "Le dossier $nom_doss et son contenu ont bien été supprimé dans $absol_path"
                                                                        else 
                                                                                echo "D'accord, retour au menu"
                                                                fi
                                                fi
                                        else 
                                                echo "La valeur saisie n'existe pas ou n'est pas un dossier"
                                fi
        fi
}

# Modification de répertoire (changement de nom ou de droits d'accès) Windows
function w_modif_doss {
    read -p "Où se situe le dossier à modifier : " absol_path
        if [[ $(ssh_cible Test-Path -Path "$absol_path") == "True" ]]
            then
                read -p " Quel est le nom du dossier à modifier dans $absol_path ? " ancien_doss
                    if [[ $(ssh_cible "Test-Path -Path '$absol_path\\$ancien_doss'") == "True" ]]
                        then
                            read -p " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] " rep4
                                if [[ "$rep4" = "R" ]]
                                    then
                                        read -p "D'accord, quel est le nouveau nom du dossier ? " new_doss
                                        ssh_cible "Rename-Item -Path '$absol_path/$ancien_doss' -NewName '$absol_path/$new_doss'" && echo "Le dossier $ancien_doss a bien été renommé en $new_doss dans $absol_path"
                                elif [[ "$rep4" = "M" ]]
                                    then # La réponse attendue est toute attachée Sous la forme rwx ou xw ou r 
                                        read -p "Quels droits voulez vous accorder sur le dossier $ancien_doss ? [r/w/x] " chxdroit
                                            if [[ "$chxdroit" =~ ^[rwx]+$ ]]
                                                then 
                                                        ssh_cible "powershell.exe -Command \ 'icacls '$absol_path\\$ancien_doss' /grant '${user_name}:({$chxdroit})''"
                                                else
                                                    echo "Ce type de droit n'existe pas"
                                            fi
                                fi
                        else
                            echo " Le dossier $ancien_doss n'existe pas "
                    fi
            else 
                echo " Le chemin vers le dossier n'existe pas "
        fi
}

# Modification de répertoire (changement de nom ou de droits d'accès) Linux
function l_modif_doss {
    read -p "Où se situe le dossier à modifier : " absol_path
        if ssh_cible "[[ -e '$absol_path' ]]"
            then
                read -p " Quel est le nom du dossier à modifier dans $absol_path ? " ancien_doss
                    if ssh_cible "[[ -d '$absol_path/$ancien_doss' ]]"
                        then
                            read -p " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] " rep4
                                if [[ "$rep4" = "R" ]]
                                    then
                                        read -p "D'accord, quel est le nouveau nom du dossier ? " new_doss
                                        ssh_cible "sudo -S mv '$absol_path/$ancien_doss' '$absol_path/$new_doss'" && echo "Le dossier $ancien_doss a bien été renommé en $new_doss dans $absol_path"
                                elif [[ "$rep4" = "M" ]]
                                    then # La réponse attendue est toute attachée Sous la forme rwx ou xw ou r 
                                        read -p "Quels droits voulez vous accorder sur le dossier $ancien_doss ? [r/w/x] " chxdroit
                                            if [[ "$chxdroit" =~ ^[rwx]+$ ]]
                                                then
                                                    ssh_cible "sudo -S chmod u+$chxdroit '$absol_path/$ancien_doss'"
                                                else
                                                    echo "Ce type de droit n'existe pas"
                                            fi
                                fi
                        else
                            echo " Le dossier $ancien_doss n'existe pas "
                    fi
            else 
                echo " Le chemin vers le dossier n'existe pas "
        fi
}

# Activation du Pare-feu
function l_fire_wall {
    read -p "Voulez-vous Activer ou Désactiver le pare-feu du poste distant $ip_cible ? [A/D] " rep3
        if [[ "$rep3" = "A" ]]
            then 
                ssh_cible "sudo -S ufw enable" && echo "Le pare-feu cible a été activé"
        elif [[ "$rep3" = "D" ]]
            then
                ssh_cible "sudo -S ufw disable" && echo "Le pare-feu cible a été désactivé"
        else
            echo "Demande invalide"
        fi
}


# Activation du Pare-feu
function w_fire_wall {
    read -p "Voulez-vous Activer ou Désactiver le pare-feu du poste distant $ip_cible ? [A/D] " rep3
        if [[ "$rep3" = "A" ]]
            then 
                ssh_cible "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True" && echo "Le pare-feu cible a été activé"
        elif [[ "$rep3" = "D" ]]
            then
                ssh_cible "Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False" && echo "Le pare-feu cible a été désactivé"
        else
            echo "Demande invalide"
        fi
}

# Heure courante
function get_time {
date=$(date +"%Y%m%d")
heure=$(date +"%H%M%S")
}

# Création utilisateur
function new_user {
    if [[ $detect_os -eq 0 ]]
        then
            l_new_user
        else
            w_new_user
    fi
add_log "new_user"
retour_menu ss_menu_gestion
}
# Changement de Mot de Passe
function change_passwd {
    if [[ $detect_os -eq 0 ]]
        then
            l_change_password
        else
            w_change_password
    fi
add_log "change_passwd"
retour_menu ss_menu_gestion
}

# Suppression utilisateur
function del_user {
    if [[ $detect_os -eq 0 ]]
        then
            l_del_user
        else
            w_del_user
    fi
add_log "del_user"
retour_menu ss_menu_gestion
}

# Ajout au groupe Admin
function add_admin {
    if [[ $detect_os -eq 0 ]]
        then
            l_add_admin
        else
            w_add_admin
    fi
add_log "add_admin"
retour_menu ss_menu_gestion
}

# Ajout à un groupe utilisateur
function add_group {
    if [[ $detect_os -eq 0 ]]
        then
            l_add_group
        else
            w_add_group
    fi
add_log "add_group"
retour_menu ss_menu_gestion
}

# Redemarrage du pc distant
function redemarrage {
    if [[ $detect_os -eq 0 ]]
        then
            l_redemarrage
        else
            w_redemarrage
    fi
add_log "redemarrage"
retour_menu ss_menu_Admin
}

# Création de répertoire
function creer_doss {
    if [[ $detect_os -eq 0 ]]
        then
            l_creer_doss
        else
            w_creer_doss
    fi
add_log "creer_doss"
retour_menu ss_menu_Admin
}

# Suppression de répertoire
function suppr_doss {
    if [[ $detect_os -eq 0 ]]
        then
            l_suppr_doss
        else
            w_suppr_doss
    fi
add_log "suppr_doss"
retour_menu ss_menu_Admin
}

# Modification de répertoire (changement de nom et droits d'accès)
function modif_doss {
    if [[ $detect_os -eq 0 ]]
        then
            l_modif_doss
        else
            w_modif_doss
    fi
add_log "modif_doss"
retour_menu ss_menu_Admin
}

# Contrôle du pare-feu
function fire_wall {
    if [[ $detect_os -eq 0 ]]
        then
            l_fire_wall
        else
            w_fire_wall
    fi
add_log "fire_wall"
retour_menu ss_menu_Admin
}

# Dns actuel
function dns_actuel {
        if [[ $detect_os -eq 0 ]]
            then
                local dns=$(ssh_cible "cat /etc/resolv.conf")
            else
                local dns=$(ssh_cible "ipconfig /all | grep 'DNS'")
        fi
    echo "$dns" >> DNS_"$cibleordi"_"$date".txt
    echo "$dns"
add_log "DNS"
retour_menu ss_menu_receuil
}

# IP et passerelle
function passerelle_ip {
    if [[ $detect_os -eq 0 ]]
        then
            local reseau=$(ssh_cible "ip a")
        else
            local reseau=$(ssh_cible "ipconfig /all")

    fi
    echo "$reseau" >> reseau_"$cibleordi"_"$date".txt
    echo "$reseau"
add_log "reseau"
retour_menu ss_menu_receuil
}

# La version de l'OS de l'ordi cible
function version_OS {
    if [[ $detect_os -eq 0 ]]
        then
            local os=$(ssh_cible "uname -a")
        else
            local os=$(ssh_cible "[System.Environment]::OSVersion.VersionString")
    fi
    echo "$os" >> version_OS_"$cibleordi"_"$date".txt
    echo "$os"
add_log "version_OS"
retour_menu ss_menu_receuil
}

# Trouve le nom de la carte graphique
function carte_graph {
    if [[ $detect_os -eq 0 ]]
        then
            local carte=$(ssh_cible "lspci | grep -i 'vga'")
        else
            local carte=$(ssh_cible "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name")

    fi
    echo "$carte" >> carte_"$cibleordi"_"$date".txt
    echo "$carte"
add_log "carte"
retour_menu ss_menu_receuil
}

# Fonction uptime
function  donne_uptime {
    if [[ $detect_os -eq 0 ]]
        then
            local var1=$(ssh_cible "uptime")
        else
            local var1=$(ssh_cible "(Get-CimInstance Win32_OperatingSystem).LastBootUpTime")
    fi
    echo "$var1" >> uptime_"$cibleordi"_"$date".txt
    echo "$var1"
add_log "uptime"
retour_menu ss_menu_receuil
}

# Version BIOS
function vers_bios {
    if [[ $detect_os -eq 0 ]]
        then
            local bios=$(ssh_cible "sudo -S dmidecode -t bios system")
        else
            local bios=$(ssh_cible "Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, Manufacturer, ReleaseDate")
    fi
    echo "$bios" >> bios_"$cibleordi"_"$date".txt
    echo "$bios"
add_log "bios"
retour_menu ss_menu_receuil
}

# Table ARP
function table_arp {
    if [[ $detect_os -eq 0 ]]
        then
            local var_arp=$(ssh_cible "ip n")
        else
            local var_arp=$(ssh_cible "Get-NetNeighbor")
    fi
    echo "$var_arp" >> arp_"$cibleordi"_"$date".txt
    echo "$var_arp"
add_log "arp"
retour_menu ss_menu_receuil
}

# Evènements critiques
function event_crit {
    if [[ $detect_os -eq 0 ]]
        then
            local event=$(ssh_cible "journalctl -p crit -n 10")
        else
            local event=$(ssh_cible "Get-EventLog -LogName System -EntryType Error -Newest 10")
    fi
    echo "$event" >> critiques_"$cibleordi"_"$date".txt
    echo "$event"
add_log "critiques"
retour_menu ss_menu_receuil
}

# Table de routage
function table_routage {
    if [[ $detect_os -eq 0 ]]
        then
            local routage=$(ssh_cible "ip r")
        else
            local routage=$(ssh_cible "Get-NetRoute")
    fi
    echo "$routage"
    echo "$routage" >> routage_"$cibleordi"_"$date".txt
add_log "routage"
retour_menu ss_menu_receuil
}

# Liste des interfaces reseaux
function interfaces {
    if [[ $detect_os -eq 0 ]]
        then
            local interfaces=$(ssh_cible "ip link show")
        else
            local interfaces=$(ssh_cible "Get-NetAdapter")
    fi
    echo "$interfaces" >> interfaces_"$cibleordi"_"$date".txt
    echo "$interfaces"
add_log "interfaces"
retour_menu ss_menu_receuil
}

# Recherche evenement par utilisateur
function recherche_utilisateur {
    read -p "Entrez le nom de l'utilisateur pour la recherche des evenements:" user_rech
        grep "$user_rech" /var/log/log_evt.log  
retour_menu ss_menu_receuil
}


# Recherche evenement par ordinateur
function recherche_ordinateur {
    read -p "Entrez l'adresse IP pour la recherche des evenements:" ordi_rech
        grep "$ordi_rech" /var/log/log_evt.log  
retour_menu ss_menu_receuil
}

# Date de dernière connexion d'un utilisateur
function last_connexion {
read -p "Entrez le nom de l'utilisateur ? " last_co 
    ssh_cible "last -1 '$last_co'"
    retour_menu ss_menu_log_user
}

# Date de dernière modification du mot de passe
function last_modif_mdp {
read -p "Entrez le nom de l'utilisateur du mdp ? " modif_mdp 
    ssh_cible "chage -l '$modif_mdp'"
    retour_menu ss_menu_log_user
}

# Liste des sessions ouvertes par l'utilisateur
function list_open_user { 
    ssh_cible w
    retour_menu ss_menu_log_user
}


# Ajout d'une action passée en argument au fichier log
function add_log {
get_time
    echo ""$date"_"$heure"_"$utilisateur"_"$ip_cible"_"$1"" >> /var/log/log_evt.log
}


# Menu principal

function menu_principal {
    clear
    echo "================================"
    echo "         MENU PRINCIPAL"
    echo "================================"
    echo -e "Que voulez-vous faire?\n 1)Gestion utilisateur \n 2)Administration \n 3)Receuil d'information \n 4)Consultation des logs \n 5)Consultation des logs d'utilisation du script\n 6)Quitter"
    local choix
    read choix
        case $choix in 
            1)  ss_menu_gestion ;;
            2)  ss_menu_Admin  ;;
            3)  ss_menu_receuil ;;
            4)  ss_menu_recherche ;;
            5)  ss_menu_log_user ;;
            6)  quitter     ;;
            *) echo "ERREUR" 
            menu_principal ;;
        esac
}

function ss_menu_gestion {
    clear
    echo -e "Quelle action voulez vous effectuer? \n 1)Création de compte \n 2)Changement de mdp \n 3)Suppression de compte \n 4)Ajout à un groupe admin \n 5)Ajout à un groupe \n 6)Quitter"
    local choix
    read choix
        case $choix in
            1)new_user;;
            2)change_passwd;;
            3)del_user;;
            4)add_admin;;
            5)add_group;;
            6) quitter ;;
            *)echo "ERREUR" 
            ss_menu_gestion ;;
        esac
}
function ss_menu_Admin {
    clear
    echo -e "Que voulez-vous faire? \n 1)Redemarrer le poste \n 2)Créer un repertoire \n 3)Modifier un repertoire \n 4)Supprimer un repertoire \n 5)Activer/Désactiver le parefeu \n 6)Prise en main a distance (CLI) \n 7)Execution de script sur la machine \n 8)Quitter"
    local choix 
    read choix
        case $choix in 
            1)redemarrage;;
            2)creer_doss;;
            3)modif_doss;;
            4)suppr_doss;;
            5)fire_wall;;
            6)ssh_cible;;
            7)echo "test";;
            8) quitter ;;
            *)echo "ERREUR" 
            ss_menu_Admin ;;
        esac
}
function ss_menu_receuil {
    clear
    echo -e "Quelles informations voulez vous recuperer?\n 1)DNS actuels\n 2)Liste des interfaces\n 3)Tables ARP\n 4)Table de routage\n 5)Version BIOS\n 6)IP,masque et passerelle\n 7)Version OS"
    echo -e " 8)Carte graphique\n 9)Uptime\n 10)Derniers evenements critiques\n 11)Quitter"
    local choix
    read choix
        case $choix in 
            1)dns_actuel ;;
            2)interfaces ;;
            3)table_arp ;;
            4)table_routage ;;
            5)vers_bios ;;
            6)passerelle_ip ;;
            7)version_OS ;;
            8)carte_graph ;;
            9)donne_uptime ;;
            10)event_crit ;;
            11) quitter ;;
            *) echo "ERREUR" 
            ss_menu_receuil ;;
        esac
}
function ss_menu_log_user {
    clear
    echo -e "Quelle informations voulez vous?\n 1)Date de dernière connexion d'un utilisateur\n 2)Dernière modification de mdp\n 3)Listes des cessions ouvertes par l'utilisateur\n 4)Quitter"
    local choix
    read choix
        case $choix in 
            1)last_connexion ;;
            2)last_modif_mdp ;;
            3)list_open_user ;;
            4)quitter ;;
            *)echo "ERREUR" 
            ss_menu_log_user ;;
        esac
}
function ss_menu_recherche {
    clear
    echo -e "Quelles informations de journalisation recherchez vous?\n 1)Informations sur un utilisateur precis\n 2)Informations sur un ordinateur précis\n 3)Quitter"
    local choix
    read choix
        case $choix in 
            1)recherche_utilisateur;;
            2)recherche_ordinateur;;
            3)quitter ;;
            *)echo "ERREUR" 
            ss_menu_recherche ;;
        esac
}
function retour_menu {
    echo -e "Que voulez vous faire?\n 1)Retourner au menu principal\n 2)Retourner au dernier menu\n 3)Quitter"
    local choix
    local fonction="$1"
    read choix
        case $choix in
            1) menu_principal ;;
            2) $fonction ;;
            3) quitter ;;
            *)echo "ERREUR" 
            retour_menu ;;
        esac
        clear
}

ask_cible
connexion_ssh
debut_journalisation
menu_principal
