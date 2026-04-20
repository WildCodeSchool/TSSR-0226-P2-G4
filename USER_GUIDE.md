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
|DNS actuels |cat /etc/resolv.conf - ipconfig /all | grep 'DNS' | Get-DnsClientServerAddress -AddressFamily IPv4 / Select-Object -ExpandProperty ServerAddresses|
|Liste des interfaces |ip link show |Get-NetAdapter |
|Table ARP | ip n|Get-NetNeighbor |
|Table de routage | ip r | Get-NetRoute|
|BIOS/UEFI version |sudo dmidecode -t bios | Get-CimInstance Win32_BIOS \ Select SMBIOSBIOSVersion, Manufacturer |
|Adresse IP, masque, passerelle | ip a|ipconfig /all |
|Version de l'OS |uname -a | [System.Environment]::OSVersion.VersionString|
|Carte graphique |lspci \ grep -i 'vga |Get-CimInstance Win32_VideoController / Select-Object -ExpandProperty Name |
|uptime |uptime -p |(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime |
|10 derniers événements critiques | journalctl -p crit -n 10| Get-EventLog -LogName System -EntryType Error -Newest 10| 
|Recherche des evenements dans le fichier log_evt.log pour un utilisateur |grep '$userRech' /var/log/log_evt.log |Select-String -Path 'C:\logs\log_evt.log' -Pattern '$userRech' |
|Recherche des evenements dans le fichier log_evt.log pour un ordinateur |grep '$ordiRech' /var/log/log_evt.log |Select-String -Path 'C:\log_evt.log' -Pattern '$ordiRech' |
|Date de dernière connexion d’un utilisateur | last -n 1 '$lastCo'| Get-LocalUser $lastCo \ Select-Object Name, LastLogon|
|Date de dernière modification du mot de passe |chage -l '$modifMdp' |Get-LocalUser '$modifMdp' \ Select-Object Name, PasswordLastSet |
|Liste des sessions ouvertes par l'utilisateur | w|query user |




 
- Utilisation : comment exécuter le script
- FAQ

