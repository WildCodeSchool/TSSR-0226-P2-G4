| BACKLOG | BASH | POWERSHELL 7 |
| :---: | :---: | :---: |
|Création de compte utilisateur local | sudo -S adduser --allow-bad-names "$user_name" | |
|Changement de mot de passe |sudo -S passwd "$user_name" | |
|Suppression de compte utilisateur local |sudo -S deluser "$user_name" | |
|Ajout à un groupe d'administration |sudo -S usermod -aG sudo "$user_name" | |
|Ajout à un groupe |sudo -S usermod -aG $group_name '$user_name | Add-LocalGroupmember -Group '$group_name' -Member '$user_name'|
|Redémarrage | sudo -S reboot|Restart-Computer -ComputerName '$ip_cible' -Force |
|Création de répertoire | | |
|Modification de répertoire | | |
|Suppression de répertoire | | |
|Activation du pare-feu | | |
|Prise de main à distance (CLI) | | |
|Exécution de script sur la machine distante | | |
|DNS actuels | | |
|Liste des interfaces | | |
|Table ARP | | |
|Table de routage | | |
|BIOS/UEFI version | | |
|Adresse IP, masque, passerelle | | |
|Version de l'OS | | |
|Carte graphique | | |
|uptime | | |
|10 derniers événements critiques | | | 
|Recherche des evenements dans le fichier log_evt.log pour un utilisateur | | |
|Recherche des evenements dans le fichier log_evt.log pour un ordinateur | | |
|Date de dernière connexion d’un utilisateur | | |
|Date de dernière modification du mot de passe | | |
|Liste des sessions ouvertes par l'utilisateur | | |




 
- Utilisation : comment exécuter le script
- FAQ

