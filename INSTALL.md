- Prérequis techniques à l’exécution des scripts
- Installation/Mise en place des scripts (explication étape par étape, ligne de code, copie d’écran, etc.) sur le client et/ou le serveur
- FAQ

# Connexion SSH par clé : Debian → Windows 11 

## Étape 1 — Activer le serveur SSH sur Windows
Depuis PowerShell administrateur :
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

## Étape 2 — Générer les clés sur Debian
Depuis Debian :
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519

## Étape 3 — Copier la clé publique sur Windows
Depuis Debian :
scp ~/.ssh/id_ed25519.pub user@ip-windows:C:/Users/user/.ssh/ma_cle.pub

## Étape 4 — Ajouter la clé dans le bon fichier sur Windows
Depuis PowerShell administrateur :

#### Créer le fichier
New-Item -ItemType File -Path "C:\ProgramData\ssh\administrators_authorized_keys"

#### Coller le contenu de la clé
Get-Content "$env:USERPROFILE\.ssh\ma_cle.pub" | Add-Content "C:\ProgramData\ssh\administrators_authorized_keys"

## Étape 5 — Corriger les permissions sur Windows
Depuis PowerShell administrateur :
powershell
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r

icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:F"

icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "*S-1-5-32-544:F"

## Étape 6 — Vérifier le sshd_config sur Windows
Ouvre C:\ProgramData\ssh\sshd_config et vérifie :
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

Ces deux lignes doivent être commentées :
#Match Group administrators
#AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
Redémarre SSH :
powershell
Restart-Service sshd

## Étape 7 — Tester depuis Debian
ssh user@ip-windows
