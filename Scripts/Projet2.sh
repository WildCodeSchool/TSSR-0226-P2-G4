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
machine_cible="wilder"
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
    read -p "Veuillez rentrer le nom exacte de la machine cible  " machine_cible
}

# Teste la connexion ssh et demande l'OS de la cible pour identifier windows ou linux
function connexion_ssh {
    local test1=$(ssh -o ConnectTimeout=5 "$machine_cible@$ip_cible" "echo test" 2>/dev/null)
    if [ "$test1" ]
        then
            version_de_lOS=$(ssh_cible "uname -s" 2>/dev/null)
            if [ -z "$version_de_lOS" ]
                then
                    detect_os=1  # Windows
                else
                    detect_os=0  # Linux
            fi
        else
            echo "erreur"
            exit 1
    fi
}

# Prépare un alias pour la connexion ssh
function ssh_cible {
    ssh -o ConnectTimeout=5 "${machine_cible}@${ip_cible}" "$@"
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

# Création de compte

function new_user {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            echo "Utilisateur $user_name déjà existant"
        else
            adduser --allow-bad-names "$user_name"
        fi
    done
add_log "creer_user"
retour_menu
}

# Changement de mot de passe

function change_password {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            passwd "$user_name"
        else
            echo "L'utilisateur $user_name n'existe pas"
        fi
    done
add_log "new_passwd"
retour_menu
}


# Suppression de compte

function del_user {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            deluser "$user_name"
        else
            echo "L'utilisateur $user_name n'existe pas"
        fi
    done
add_log "suppr_user"
retour_menu
}


# Ajout à un groupe d'administration

function add_admin {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            usermod -aG sudo "$user_name" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe Administrateur"
        else
            echo "L'utilisateur $user_name n'existe pas"
        fi
    done
add_log "ajout_admin"
retour_menu
}



# Ajout à un groupe

function add_group {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            read -p "Dans quel groupe voulez-vous ajouter $user_name ? " group_name
                if ! grep -q "^$group_name:" /etc/group
                then
                    read -p "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] " rep
                        if [ "$rep" = "o" ]
                        then
                            groupadd "$group_name" && echo "Groupe $group_name créé"
                        else
                            echo "D'accord, retour au menu principal" && retour_menu
                        fi
                fi
            usermod -aG $group_name "$user_name" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe $group_name"
        else
            echo "L'utilisateur $user_name n'existe pas"
        fi
    done
add_log "ajout_group"
retour_menu
}

# Choix de redémarrage
function redemarrage {
    read -p "Entrez le nom d'utilisateur de la machine à redémarrer : " cible_user
    read -p "Entrez l'identifiant de la machine à redémarrer : " cible_ip
    ssh $cible_user@$cible_ip "reboot" && echo " La machine cible est en cours de redémarrage "

add_log "redemarrer"
retour_menu
}

# Création de répertoire
function creer_doss {
    read -p "Où voulez-vous créer votre dossier : " absol_path
        if ! [[ -e "$absol_path" ]]
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                                                mkdir -p "$absol_path/$nom_doss" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
                                        else
                                                echo "D'accord, retour au menu principal" && retour_menu
                                fi
                else 
                        read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                        mkdir -p "$absol_path/$nom_doss" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
        fi
add_log "creation_doss"
retour_menu
}

# Suppression de répertoire
function suppr_doss {
    read -p "Où se trouve le dossier à supprimer ? " absol_path
        if ! [[ -e "$absol_path" ]]
                then
                        read -p " Le chemin vers le dossier n'existe pas, voulez-vous rentrer un autre chemin ? [o/n] " rep1
                                if [[ "$rep1" = "o" ]]
                                        then
                                                suppr_doss
                                        else 
                                                echo "D'accord, retour au menu" && retour_menu
                                fi
                else
                        read -p "D'accord, quel est le nom du dossier à supprimer dans $absol_path ? " nom_doss
                                if [[ -d "$absol_path/$nom_doss" ]]
                                        then
                                                if [ -z "$(find "$absol_path/$nom_doss" -mindepth 1 -print -quit)" ]
                                                        then
                                                                rmdir "$absol_path/$nom_doss" && echo "Le dossier $nom_doss a bien été supprimé dans $absol_path"
                                                        else
                                                                read -p "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] " rep2
                                                                if [[ "$rep2" = "o" ]]
                                                                        then
                                                                                rm -r "$absol_path/$nom_doss" && echo "Le dossier $nom_doss et son contenu ont bien été supprimé dans $absol_path"
                                                                        else 
                                                                                echo "D'accord, retour au menu" && retour_menu
                                                                fi
                                                fi
                                        else 
                                                echo "La valeur saisie n'existe pas ou n'est pas un dossier" && retour_menu
                                fi
        fi
add_log "suppr_doss"
retour_menu
}


# Modification de répertoire (changement de nom ou de droits d'accès)
function modif_doss {
    read -p "Où se situe le dossier à modifier : " absol_path
        if [[ -e "$absol_path" ]]
            then
                read -p " Quel est le nom du dossier à modifier dans $absol_path ? " ancien_doss
                    if [[ -d "$ancien_doss" ]]
                        then
                            read -p " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] " rep4
                                if [[ "$rep4" = "R" ]]
                                    then
                                        read -p "D'accord, quel est le nouveau nom du dossier ? " new_doss
                                        mv "$absol_path/$ancien_doss" "$absol_path/$new_doss" && echo "Le dossier $ancien_doss a bien été renommé en $new_doss dans $absol_path"
                                elif [[ "$rep4" = "M" ]]
                                    then
                                        read -p "Quels droits voulez vous accorder sur le dossier $ancien_doss ? "
                                        # ajouter un case ou chmod
                                fi
                        else
                            echo " Le dossier $ancien_doss n'existe pas " && retour_menu
                    fi
            else 
                echo " Le chemin vers le dossier n'existe pas " && retour_menu
        fi
add_log "modif_doss"
retour_menu
}

# Activation du Pare-feu
function fire_wall {
    read -p "Entrez l'IP de la machine sur laquelle agir : " cible_ip2
    read -p "Voulez-vous Activer ou Désactiver le pare-feu du poste distant ? [A/D] " rep3
        if [[ "$rep3" = "A" ]]
            then 
                ssh $cible_ip2 "ufw enable" && echo "Le pare-feu cible a été activé"
            else
                echo "Demande invalide"
        elif [[ "$rep3" = "D" ]]
            then
                ssh $cible_ip2 "ufw disable" && echo "Le pare-feu cible a été désactivé"
            else
                echo "Demande invalide"
        fi
add_log "fire_wall"
retour_menu
}

# Heure courante
function get_time {
date=$(date +"%Y%m%d")
heure=$(date +"%H%M%S")
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
add_log "uptime"
retour_menu ss_menu_receuil
}

# Version BIOS
function vers_bios {
    if [[ $detect_os -eq 0 ]]
        then
            local bios=$(ssh_cible "sudo dmidecode -t bios system")
        else
            local bios=$(ssh_cible "Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, Manufacturer, ReleaseDate")
    fi
    echo "$bios" >> bios_"$cibleordi"_"$date".txt
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
add_log "interfaces"
retour_menu ss_menu_receuil
}




# Ajout d'une action passée en argument au fichier log
function add_log {
get_time
    echo ""$date"_"$heure"_"$utilisateur"_"$1"" >> /var/log/log_evt.log
}

# Menu principal

function menu_principal {
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

function ss_menu_Admin {
    echo -e "Quelle action voulez vous effectuer? \n 1)Redemarrer le poste \n 2)Créer un repertoire \n 3)Modifier un repertoire \n 4)Supprimer un repertoire\n 5)Activer le parefeu\n 6)Prise en main a distance (CLI)\n 7)Execution de script sur la machine"
    echo " 8)Quitter"
    local choix
    read choix
        case $choix in
            1)echo "test";;
            2)echo "test";;
            3)echo "test";;
            4)echo "test";;
            5)echo "test";;
            6)echo "test";;
            7)echo "test";;
            8) quitter ;;
            *)echo "ERREUR" 
            ss_menu_Admin ;;
        esac
}
function ss_menu_gestion {
    echo -e "Que voulez-vous faire?\n 1)Création de compte\n 2)Changement de mdp\n 3)Suppression de compte\n 4)Ajout à un groupe admin\n 5)Ajout à un groupe\n 6)Quitter"
    local choix 
    read choix
        case $choix in 
            1)echo "test";;
            2)echo "test";;
            3)echo "test";;
            4)echo "test";;
            5)echo "test";;
            6) quitter ;;
            *)echo "ERREUR" 
            ss_menu_gestion ;;
        esac
}
function ss_menu_receuil {
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
    echo -e "Quelle informations voulez vous?\n 1)Date de dernière connexion d'un utilisateur\n 2)Dernière modification de mdp\n 3)Listes des cessions ouvertes par l'utilisateur\n 4)Quitter"
    local choix
    read choix
        case $choix in 
            1)echo "test";;
            2)echo "test";;
            3)echo "test";;
            4)quitter ;;
            *)echo "ERREUR" 
            ss_menu_log_user ;;
        esac
}
function ss_menu_recherche {
    echo -e "Quelles informations de journalisation recherchez vous?\n 1)Informations sur un utilisateur precis\n 2)Informations sur un ordinateur précis\n 3)Quitter"
    local choix
    read choix
        case $choix in 
            1)echo "test";;
            2)echo "test";;
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
}
ask_cible
connexion_ssh
debut_journalisation
menu_principal
test_add "$@"
new_user
change_password
del_user
add_admin
add_group
creer_doss
suppr_doss
modif_doss
fire_wall
