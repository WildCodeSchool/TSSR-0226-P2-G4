#!/bin/bash

# Vérification de l'utilisation du script en mode Administrateur

if [[ $EUID -ne 0 ]]; then
        echo "Mode sudo obligatoire pour run le script !" && exit 1
fi

# Mise en variable du nom d'utilisateur

function test_add {
    if [ $# -ne 0 ]
    then
        tableau_new=("$@")
    else
        read -p "Veuillez rentrer les noms des utilisateurs (séparés par des espaces) : " -a tableau_new
    fi
}

# Creation de compte

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
#add_log "creer_user"
#retour_menu
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
#add_log "new_passwd"
#retour_menu
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
#add_log "suppr_user"
#retour_menu
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
#add_log "ajout_admin"
#retour_menu
}



# Ajout à un groupe

function add_group {
    for user_name in "${tableau_new[@]}"
    do
        if grep -q "^$user_name:" /etc/passwd
        then
            read -p "Dans quel groupe voulez-vous ajouter $user_name ? " group_name
                if ! grep -q "^$group_name" /etc/group
                then
                    read -p "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] " rep
                        if [ $rep = o ]
                        then
                            groupadd "$group_name" && echo "Groupe $group_name créé"
                        else
                            echo "D'accord, retour au menu principal" #&& $retour_menu
                        fi
                fi
            usermod -aG $group_name "$user_name" && echo "L'utilisateur $user_name a été ajouté avec succès au groupe $group_name"
        else
            echo "L'utilisateur $user_name n'existe pas"
        fi
    done
#add_log "ajout_group"
#retour_menu
}

# Choix de redémarrage
function redemarrage {
    read -p "Entrez le nom d'utilisateur de la machine à redémarrer : " cible_user
    read -p "Entrez l'identifiant de la machine à redémarrer : " cible_ip
    ssh $cible_user@$cible_ip "sudo reboot" # /!\ à configurer avec clef SSH pour retirer le sudo

#add_log "redemarrer"
#retour_menu
}

# Création de répertoire
function creer_dossier {
    read -p "Où voulez-vous créer votre dossier : " absol_path
        if ! [[ -e "$absol_path" ]]
            then
                read -p " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " rep1
                    if [[ "$rep1" = "o" ]]
                    then
                        read -p "D'accord, quel est le nom du dossier à créer dans $absol_path ? " nom_doss
                        mkdir -p "$absol_path/$nom_doss" && echo "Le dossier $nom_doss a bien été créé dans $absol_path"
                    else
                        echo "D'accord, retour au menu principal" #&& $retour_menu
                    fi
        fi
#add_log "creation_doss"
#retour_menu
}

# Suppression de répertoire
function suppr_doss {
    read -p "Où se trouve le dossier à supprimer ? " absol_path
        if ! [[ -e "$absol_path" ]]
            then
                read -p " Le chemin vers le dossier n'existe pas, entrez un chemin existant : " rep1
                    if [[ -de "$rep1" ]]
                    then
                        read -p "D'accord, quel est le nom du dossier à supprimer dans $absol_path ? " nom_doss
                            if [[ -z "$nom_doss" ]]
                                then
                                    read -p "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] " rep2
                                    rmdir -rf "$absol_path/$nom_doss" && echo "Le dossier $nom_doss et son contenu ont bien été supprimé dans $absol_path"
                    else
                        echo "Deuxième erreur, retour au menu principal" #&& $retour_menu
                    fi
        fi
#add_log "suppr_doss"
#retour_menu
}



# Modification de répertoire
# Ajout d'une action passée en argument au fichier log
#function add_log {
#time
#echo ""$date"_"$heure"_"$utilisateur"_"$1"" >> $chemin_log log_evt.log
#}

#test_add "$@"
#new_user
#change_password
#del_user
#add_admin
#add_group