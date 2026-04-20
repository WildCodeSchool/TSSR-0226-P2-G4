# __Connexion SSH par clé__

1. [Debian → Windows 11](#Debian--Windows-11)
2. [Debian → Ubuntu](#Debian--Ubuntu)
3. [Commandes BASH & POWERSHELL 7](#Commandes-BASH--POWERSHELL-7)


- Prérequis techniques à l’exécution des scripts
- Installation/Mise en place des scripts (explication étape par étape, ligne de code, copie d’écran, etc.) sur le client et/ou le serveur
- FAQ

# Debian → Windows 11 

## Étape 1 — Activer le serveur SSH sur Windows
Depuis PowerShell administrateur :
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
<img width="1916" height="106" alt="activer_serverssh_windows" src="https://github.com/user-attachments/assets/c1f7fe3f-e015-4c9a-a482-e1a7795fa15b" />
Start-Service sshd
<img width="1920" height="114" alt="Start-Serive sshd" src="https://github.com/user-attachments/assets/55a22a4a-e3e8-429e-ac7b-e9bf97c9739b" />
Set-Service -Name sshd -StartupType Automatic
<img width="1916" height="106" alt="Set-Service" src="https://github.com/user-attachments/assets/9dc0806f-3d31-4473-871b-682280b69e2a" />

## Étape 2 — Générer les clés sur Debian
Depuis Debian :
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519
<img width="1923" height="95" alt="key-gen_debian" src="https://github.com/user-attachments/assets/f59ccbc3-3fbc-417c-ae2c-15524bf96adc" />

Depuis Windows Server 2025 :
<img width="1902" height="606" alt="key-gen_wserver" src="https://github.com/user-attachments/assets/0196b666-1a76-4292-9edd-3861d4935292" />

## Étape 3 — Copier la clé publique sur Windows
Depuis Debian :
scp ~/.ssh/id_ed25519.pub user@ip-windows:C:/Users/user/.ssh/ma_cle.pub
<img width="1919" height="95" alt="envoi_keyssh_debian_windows11" src="https://github.com/user-attachments/assets/f308f971-6b41-4697-8150-77af231c0e8d" />

Depuis Windows Server 2025 : 
<img width="1897" height="552" alt="envoi_keyssh_wserver_windows11" src="https://github.com/user-attachments/assets/cfa04158-6b83-422c-a75b-22fec34a056f" />

## Étape 4 — Ajouter la clé dans le bon fichier sur Windows
Depuis PowerShell administrateur :

#### Créer le fichier
New-Item -ItemType File -Path "C:\ProgramData\ssh\administrators_authorized_keys"
<img width="1922" height="96" alt="creer_admin_authorized_keys" src="https://github.com/user-attachments/assets/9a49a6e0-f3f0-4ece-91bb-2d4fa7bbc36b" />

#### Coller le contenu de la clé
Get-Content "$env:USERPROFILE\.ssh\ma_cle.pub" | Add-Content "C:\ProgramData\ssh\administrators_authorized_keys"
<img width="1914" height="100" alt="Get-Content_id_ed25519 pub" src="https://github.com/user-attachments/assets/635175a9-982d-448c-a5b3-c85a220556e4" />

## Étape 5 — Corriger les permissions sur Windows
Depuis PowerShell administrateur :
PowerShell 7.6
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r
<img width="1910" height="96" alt="icacls_inheritance_r" src="https://github.com/user-attachments/assets/e6691f0c-07ce-402b-85dc-d3841472f3c7" />

icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:F"
<img width="1920" height="99" alt="icacls_grant" src="https://github.com/user-attachments/assets/db869b7e-7c40-4f91-85a3-380a14be7e6e" />

icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "*S-1-5-32-544:F"
<img width="1909" height="99" alt="icacls_grant_S" src="https://github.com/user-attachments/assets/e55820ca-f5af-44a9-9698-7c2f583541de" />

## Étape 6 — Vérifier le sshd_config sur Windows
Ouvre C:\ProgramData\ssh\sshd_config et vérifie :
PubkeyAuthentication yes
<img width="1418" height="159" alt="PubkeyAuthentication yes" src="https://github.com/user-attachments/assets/fb5bd8b7-22be-4d9e-a332-af162e71ed08" />

AuthorizedKeysFile .ssh/authorized_keys
<img width="1417" height="33" alt="AuthorizedKeysFile" src="https://github.com/user-attachments/assets/2539d958-8c34-45eb-8f30-02f916d39f9c" />

Ces deux lignes doivent être commentées :
#Match Group administrators
#AuthorizedKeysFile \_\_PROGRAMDATA\_\_/ssh/administrators_authorized_keys
<img width="1411" height="63" alt="Match Group" src="https://github.com/user-attachments/assets/511677fe-707d-4d8e-9376-af72b4dbe44f" />

Redémarre SSH :
PowerShell 7.6
Restart-Service sshd
<img width="1920" height="103" alt="Restart-Service sshd" src="https://github.com/user-attachments/assets/bdaa4cf1-ded6-4ac3-b2bc-69abf360a272" />

## Étape 7 — Tester depuis Debian
ssh user@ip-windows
<img width="1919" height="177" alt="connexion_debian_windows11_debut" src="https://github.com/user-attachments/assets/4ff80e9b-758e-4ce8-82c7-e7f799d84483" />
<img width="1918" height="305" alt="connexion_debian_windows11_etablie" src="https://github.com/user-attachments/assets/8637e570-8620-4e4a-889a-d0ca4edf75d3" />
<img width="1908" height="276" alt="connexion_debian_windows11_exit" src="https://github.com/user-attachments/assets/e9681945-59ae-4484-8958-406af3d18723" />

# Debian → Ubuntu

## Étape 1 — Activer le serveur SSH sur Ubuntu
Depuis Ubuntu 24 : sudo apt install openssh-server
<img width="1811" height="1086" alt="activation_server_ssh" src="https://github.com/user-attachments/assets/d6f84775-266d-4d37-ac3e-12440c8e3bf7" />

## Étape 2 — Copier la clé publique sur Ubuntu
Depuis Debian : ssh-copy-id -i ~/.ssh/id_ed25519.pub wilder@172.16.40.30
<img width="1504" height="258" alt="envoi_keyssh_debian_ubuntu" src="https://github.com/user-attachments/assets/79e0cbc9-0277-45ed-864c-70a0b57b1d82" />

## Étape 3 — Vérifier le fichier authorized_keys sur Ubuntu
Depuis Ubuntu : cd .ssh 
cat authorized_keys
<img width="1917" height="349" alt="authorized_keys_ubuntu" src="https://github.com/user-attachments/assets/0782cf23-d71b-4354-a3a1-73b9782daec3" />

## Étape 4 — Tester depuis Debian
<img width="1025" height="456" alt="connexion_debian_ubuntu" src="https://github.com/user-attachments/assets/79e1d7e1-2a13-4853-af35-e44ff9a04938" />

# Commandes BASH & POWERSHELL 7

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


