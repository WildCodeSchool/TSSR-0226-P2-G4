| BACKLOG | BASH | POWERSHELL 7 |
| :---: | :---: | :---: |
|Création de compte utilisateur local | sudo -S adduser --allow-bad-names "$user_name" |New-LocalUser -Name $userName -NoPassword |
|Changement de mot de passe |sudo -S passwd "$user_name" | `$pw = Read-Host -AsSecureString; Set-LocalUser -Name $userName -Password `$pw |
|Suppression de compte utilisateur local |sudo -S deluser "$user_name" | Remove-LocalUser -Name '$user_name'|
|Ajout à un groupe d'administration |sudo -S usermod -aG sudo "$user_name" |Add-LocalGroupmember -Group 'Administrators' -Member '$user_name' |
|Ajout à un groupe |sudo -S usermod -aG $group_name '$user_name | Add-LocalGroupmember -Group '$group_name' -Member '$user_name'|
|Redémarrage | sudo -S reboot|Restart-Computer -ComputerName '$ip_cible' -Force |
|Création de répertoire |sudo -S mkdir -p "$nom_doss" | New-Item -ItemType Directory -Path '$nomDoss'|
|Modification de répertoire |sudo -S mv '$ancien_doss' '$new_doss' - sudo -S chmod u+$chxdroit "$ancien_doss" |Rename-Item -Path '$ancien_doss' -NewName '$new_doss' - powershell.exe -Command \ 'icacls '$ancien_doss' /grant '${user_name}:({$chxdroit})' |
|Suppression de répertoire |sudo -S rm -r '$nom_doss' | Remove-Item -Recurse -Force '$nom_doss'|
|Activation du pare-feu |sudo -S ufw enable | Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True|
|Prise de main à distance (CLI) | | |
|Exécution de script sur la machine distante |ssh -t -o ConnectTimeout=5 "${user_cible}@${ip_cible}" "$*" 2>/dev/null |ssh -o ConnectTimeout=5 "${script:userCible}@${script:ipCible}" "$args" |
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

