

#bone
#declaration des variables
#ATTENTION: pour eviter les erreurs les variables de vos fonctions doivent être declarées en "local"
variable1   
variable2
.....

#declaration des fonctions du menu

function_menu_principal

                function_ssmenu1
                function_ssmenu2
                function_ssmenu3
                function_ssmenu4

fonction retour_menu
            retour menu precedent(arg dernier_ss_menu)
            retour debut
                    {appel fonction_menu_principal}
            fin script
                inscription fichier log
# declaration des fonctions des differents groupes d'option

fonction_menu_admin_action

fonction_menu_amdin_compte

fonction_menu_recup_info 

fonction_menu_recherche_info

#declaration des differentes fonction des menus

.....


# declaration des fonctions de log

#ajout à un log
fonction_log

# consultation des logs et recherche
fonction_affichage_log

# interface graphique

# corps du programme
verification droit sudo
demande ip cible et connexion ssh
verification diverses (connexion et shell utilisé)
debut fichier log
appel fonction menu
fin fichier log
exit 0