function Test-AdminContext {
    $UserIsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not ($UserIsAdmin)) {
        Write-Warning "Le script '$($MyInvocation.MyCommand)' ne peut pas être exécuté car la session PowerShell n'est pas exécutée dans le contexte Administrateur"
        exit
    }

}

function testIp {
    if ($script:ipCible -match "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$") { 
        Write-Host "IP valide : $script:ipCible"
    }
    else {
        Write-Host "Erreur : '$script:ipCible' n'est pas une adresse IP valide"
        askCible
    }       
}

# Demande l'ip et le compte distant (camel case- echo = write host $script contraire du local, backtic au lieu de backslash)
function askCible {
    Write-Host "Bonjour et bienvenue sur ce script d'administration`n"
    $script:ipCible = Read-Host "Quelle est l'ip de la machine cliente? Veuillez rentrer une ip correcte sous la forme **.**.**.** " 
    testIp
    $script:userCible = Read-Host "Veuillez rentrer le nom exacte de l'utilisateur cible"
}

# Prépare un alias pour la connexion ssh
function sshCible {
    ssh -o ConnectTimeout=5 "${script:userCible}@${script:ipCible}" "$args"
}

# Teste la connexion ssh et demande l'OS de la cible pour identifier windows ou linux
function connexionSsh {
    $test1 = ssh -o ConnectTimeout=5 "${script:userCible}@${script:ipCible}" "echo test" 2>$null
    if ($test1 -eq "test") {
        $versionDeLOS = sshCible "uname -s" 2>$null
        if ($versionDeLOS -like "*Linux*") { 
            $script:versionDeLOS = 0  # Linux
        }    
        else {
            $script:versionDeLOS = 1  # Windows
        }
    }
    else {
        Write-Host "erreur"
    }
}

# Crée le fichier log et l'initialise
function debutJournalisation {
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "StartScript`n"
}

# Ferme le fichier quand l'utilisateur quitte
function Quitter {
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "EndScript"
    exit 0
}
# Mise en variable du nom d'utilisateur

function testAdd {
    if ($args.Count -gt 0) {
        $script:tableauNew = $args   
    }
    else {
        $inputUsers = Read-Host "Veuillez rentrer les noms des utilisateurs (séparés par des espaces) : "
        $script:tableauNew = $inputUsers -split " "
    }
}

# Création de compte Windows

function W_NewLocalUsers {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "powershell Get-LocalUser -Name "$userName"" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Utilisateur $userName déjà existant"
        } 
        else {
            sshCible "powershell New-LocalUser -Name $userName -NoPassword"
            Write-Host "Utilisateur $userName créé avec succès"
        }
    }
}

# Création de compte Linux

function L_NewLocalUsers {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "grep -q '^{$userName}:' /etc/passwd" 
        if ($LASTEXITCODE -eq 0) {    
            Write-Host "Utilisateur $userName déjà existant"
        } 
        else {
            sshCible "sudo -S adduser --allow-bad-names --disabled-password --gecos '' $userName"
            Write-Host "Utilisateur $userName créé avec succès"
        }
    }
}


# Changement de mot de passe Linux

function L_ChangePassword {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "grep -q '^{$userName}:' /etc/passwd" 
        if ($LASTEXITCODE -eq 0) {    
            sshCible "sudo -S passwd $userName" 
            Write-Host "Mot de passe de $userName changé avec succès" 
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Changement de mot de passe Windows

function W_ChangePassword {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "powershell Get-LocalUser -Name $userName" 2>$null
        if ($LASTEXITCODE -eq 0) {   
            $mdp = Read-Host "Entrez le nouveau Mot de passe: " -AsSecureString
            sshCible "powershell net user '$userName' '$mdp'"
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Suppression de compte Linux

function L_DelUser {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "grep -q '^{$userName}:' /etc/passwd" 
        if ($LASTEXITCODE -eq 0) {    
            sshCible "sudo -S deluser $userName" 
            Write-Host "L'utilisateur $userName à bien été supprimé"
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Supression de compte Windows

function W_DelUser {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "powershell Get-LocalUser -Name $userName" 2>$null
        if ($LASTEXITCODE -eq 0) {    
            sshCible "powershell Remove-LocalUser -Name $userName" 
            Write-Host "L'utilisateur $userName à bien été supprimé"
        }    
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Ajout à un groupe d'administration Linux

function L_AddAdmin {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "grep -q '^{$userName}:' /etc/passwd"
        if ($LASTEXITCODE -eq 0) {    
            sshCible "sudo -S usermod -aG sudo $userName" 
            Write-Host "L'utilisateur $userName a été ajouté au groupe Admin"
        }    
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Ajout à un groupe d'administration Windows

function W_AddAdmin {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "powershell Get-LocalUser -Name $userName"
        sshCible "powershell Add-LocalGroupmember -Group 'Administrators' -Member $userName"
        Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe Administrateur"
    }
    else {
        Write-Host "L'utilisateur $userName n'existe pas"
    }
}


# Ajout à un groupe Linux

function L_AddGroup {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "grep -q '^{$userName}:' /etc/passwd"
        if ($LASTEXITCODE -eq 0) {    
            $groupName = Read-Host "Dans quel groupe voulez-vous ajouter $userName ? "
            sshCible "grep -q '^{$groupName}:' /etc/group"
            if ($LASTEXITCODE -eq 0) {    
                $Rep = Read-Host "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] "
                If ($Rep -eq "o") {
                    sshCible "sudo -S groupadd $groupName" 
                    Write-Host "Groupe $groupName créé"
                    sshCible "sudo -S usermod -aG $groupName $userName"
                    Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe $groupName"
                }
                else {
                    Write-Host "D'accord, retour au menu principal"
                }
            }
            else {
                Write-Host "L'utilisateur $userName n'existe pas"
            }
        }
    }
}

#Ajout à un groupe Windows

function W_AddGroup {
    testAdd
    foreach ($userName in $script:tableauNew) {
        sshCible "powershell Get-LocalUser -Name $userName"
        if ($LASTEXITCODE -eq 0) {    
            $groupName = Read-Host "Dans quel groupe voulez-vous ajouter $userName ? "
            sshCible "powershell Get-LocalGroup -Name $groupName"
            if ($LASTEXITCODE -eq 1) {    
                $Rep = Read-Host "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] "
                if ($Rep -ceq "o") {
                    sshCible "powershell New-LocalGroup -Name $groupName"
                    Write-Host "Groupe $groupName créé"
                    sshCible "powershell Add-LocalGroupmember -Group $groupName -Member $userName" 
                    Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe $groupName"
                }            
                else {
                    Write-Host "D'accord, retour au menu principal"
                    Menu-Principal
                }
            }
            else {
                sshCible "powershell Add-LocalGroupmember -Group $groupName -Member $userName" 
                    Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe $groupName"
                }
            }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}


# Choix de redémarrage Linux
function L_Redemarrage {
    $Rep5 = Read-Host "$script:userCible@$script:ipCible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] "
    If ($Rep5 -eq "o") {
        sshCible "sudo -S reboot" 
        Write-Host " La machine cible est en cours de redémarrage "
    }    
    else {
        Write-Host "D'accord, retour au menu principal"
    }
}

# Choix de redémarrage Windows
function W_Redemarrage {
    $Rep5 = Read-Host "$script:userCible@$script:ipCible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] "
    If ($Rep5 -eq "o") {
        sshCible "powershell Restart-Computer -Force" 
        Write-Host " La machine cible est en cours de redémarrage "
    }    
    else {
        Write-Host "D'accord, retour au menu principal"
    }
}

# Création de répertoire Windows
function w_creerDoss {
    $absolPath = Read-Host "Où voulez-vous créer votre dossier : " 
    sshCible "powershell Test-Path -Path '$absolPath'" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $rep1 = Read-Host " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] "                  
        if ("$rep1" -eq "o") {
            $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
            sshCible "powershell New-Item -ItemType Directory -Path '$absolPath/$nomDoss'" 
            Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"                                 
        }
        else {
            <# Action when all if and elseif conditions are 0 #>
            Write-Host "D'accord, retour au menu principal"
        }
    }
    else {
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? "                 
        sshCible "powershell New-Item -ItemType Directory -Path '$absolPath/$nomDoss'" 
        Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"  
    }
}
function l_creerDoss {
    $absolPath = Read-Host "Où voulez-vous créer votre dossier : " 
    sshCible "test -d '$absolPath'"
    if ($LASTEXITCODE -ne 0) {
        $rep1 = Read-Host "Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " 
        if ($rep1 -eq "o") {
            $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
            $fullPath = "$absolPath/$nomDoss"
            sshCible "sudo -S mkdir -p '$fullPath'" 
            Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"
        }
        else {
            Write-Host "D'accord, retour au menu principal"
        }
    }
    else {
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
        $fullPath = "$absolPath/$nomDoss"
        sshCible "sudo -S mkdir -p '$fullPath'" 
        Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"
    }
}
# Modification de répertoire (changement de nom ou de droits d'accès) Windows
function w_modifDoss {
    $absolPath = Read-Host "Où se situe le dossier à modifier : " 
    sshCible "powershell Test-Path -Path '$absolPath'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $ancienDoss = Read-Host " Quel est le nom du dossier à modifier dans $absolPath ? " 
        sshCible "powershell Test-Path -Path '$absolPath\$ancienDoss'"
        if ($LASTEXITCODE -eq 0) {                
            $rep4 = Read-Host " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] "                
            if ($rep4 -ceq "R") {
                $newDoss = Read-Host "D'accord, quel est le nouveau nom du dossier ? "
                sshCible "powershell Rename-Item -Path '$absolPath\$ancienDoss' -NewName '$newDoss'" 
                Write-Host "Le dossier $ancienDoss a bien été renommé en $newDoss dans $absolPath"
            }
            elseif ($rep4 -ceq "M") { 
                # La réponse attendue est toute attachée Sous la forme rwx ou xw ou r 
                $chxdroit = Read-Host "Quels droits voulez vous accorder sur le dossier $ancienDoss ? [r/w/x] "                                   
                if ($chxdroit -match "^[rwx]+$") {
                    # Droit par défaut Read
                    $winDroit = "R" 
                    if ($chxdroit -eq "rwx") { $winDroit = "F" }
                    elseif ($chxdroit -eq "rw") { $winDroit = "M" } # Modify: lire, écrire, supprimer
                    elseif ($chxdroit -eq "w") { $winDroit = "W" }
                    elseif ($chxdroit -eq "x") { $winDroit = "RX" }
                    sshCible "powershell icacls $absolPath\$ancienDoss /grant:r ${script:userCible}:$winDroit"
                    Write-Host "Droits mis à jour pour $ancienDoss"
                }                                        
                else {                                            
                    Write-Host "Ce type de droit n'existe pas"
                }
            }
        }                
        else {                    
            Write-Host " Le dossier $ancienDoss n'existe pas "
        } 
    }   
    else {        
        Write-Host " Le chemin vers le dossier n'existe pas "
    }
}


function l_modifDoss {
    $absolPath = Read-Host "Où se situe le dossier à modifier : " 
    sshCible "test -d '$absolPath'"
    if ($LASTEXITCODE -eq 0) { 
        $ancienDoss = Read-Host " Quel est le nom du dossier à modifier dans $absolPath ? " 
        sshCible "test -d '$absolPath/$ancienDoss'"
        if ($LASTEXITCODE -eq 0) { 
            $rep4 = Read-Host " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] " 
            if ($rep4 -eq "R") {
                $newDoss = Read-Host "D'accord, quel est le nouveau nom du dossier ? " 
                sshCible "sudo -S mv '$absolPath/$ancienDoss' '$absolPath/$newDoss'" 
                Write-Host "Le dossier $ancienDoss a bien été renommé en $newDoss dans $absolPath"
            }
            elseif ($rep4 -eq "M") {
                # La réponse attendue est toute attachée Sous la forme rwx ou xw ou r 
                $chxdroit = Read-Host "Quels droits voulez vous accorder sur le dossier $ancienDoss ? [r/w/x] " 
                if ($chxdroit -match "^[rwx]+$") {
                    sshCible "sudo -S chmod u+$chxdroit '$absolPath/$ancienDoss'"
                    Write-Host "Droits u+$chxdroit appliqués sur $ancienDoss"
                }
                else {
                    Write-Host "Ce type de droit n'existe pas" 
                }
            }
        }   
        else {   
            Write-Host" Le dossier $ancienDoss n'existe pas "
        }
    }
    else { 
        Write-Host " Le chemin vers le dossier n'existe pas "
    }
}

# Suppression de répertoire Windows
function w_supprDoss {
    $absolPath = Read-Host "Où se trouve le dossier à supprimer ? " 
    sshCible "powershell Test-Path -Path '$absolPath'"
    if ($LASTEXITCODE -ne 0) {
        $rep1 = Read-Host "Le chemin vers le dossier n'existe pas, voulez-vous rentrer un autre chemin ? [o/n] "                         
        if ($rep1 -eq "o") {                                
            w_supprDoss                            
        }
        else {                                        
            Write-Host "D'accord, retour au menu"
        }
    }        
    else {                
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à supprimer dans $absolPath ? "  
        $fullPath = "$absolPath/$nomDoss"                       
        sshCible "powershell Test-Path -Path '$fullPath'"
        if ($LASTEXITCODE -eq 0) {                                      
            $result = sshCible "powershell (Get-ChildItem '$fullPath' | Measure-Object).Count"
            $count = [int]$result    
            if ($count -eq 0) {
                sshCible "powershell Remove-Item -Recurse -Force '$fullPath'" 
                Write-Host "Le dossier $nomDoss a bien été supprimé dans $absolPath"
            }                                                
            else {
                $rep2 = Read-Host "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] "                                                      
                if ($rep2 -eq "o") {
                    sshCible "powershell Remove-Item '$fullPath'" 
                    Write-Host "Le dossier $nomDoss et son contenu ont bien été supprimés dans $absolPath"    
                }                                                                
                else {                        
                    Write-Host "D'accord, retour au menu"
                }
            }                                   
        }
        else { 
            Write-Host "La valeur saisie n'existe pas ou n'est pas un dossier"
        }        
    } 
}


function l_supprDoss {
    $absolPath = Read-Host "Où se trouve le dossier à supprimer ? " 
    sshCible "test -d '$absolPath'"
    if ($LASTEXITCODE -ne 0) {    
        $rep1 = Read-Host " Le chemin vers le dossier n'existe pas, voulez-vous rentrer un autre chemin ? [o/n] " 
        if ($rep1 -eq "o") {
            l_supprDoss
        }
        else {
            Write-Host "D'accord, retour au menu"
        }
    }
    else {
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à supprimer dans $absolPath ? " 
        $fullPath = "$absolPath/$nomDoss"   
        sshCible "test -d '$absolPath/$nomDoss'"
        if ($LASTEXITCODE -eq 0) {
            $isEmpty = sshCible "[ -z ""\$(ls -A '$fullPath')"" ] && echo 'vrai' || echo 'faux'" 
            if ($isEmpty -eq "vrai") { 
                sshCible "sudo -S rmdir '$fullPath'" 
                Write-Host "Le dossier $nomDoss a bien été supprimé dans $absolPath"
            }
            else {
                $rep2 = Read-Host "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] " 
                if ($rep2 -eq "o") {
                    sshCible "sudo -S rm -rf '$fullPath'" 
                    Write-Host "Le dossier $nomDoss et son contenu ont bien été supprimé dans $absolPath"
                }
                else {
                    Write-Host "D'accord, retour au menu"
                }
            }
        }
        else {
            Write-Host "La valeur saisie n'existe pas ou n'est pas un dossier"
        }
    }
}

# Activation du Pare-feu
function w_fireWall {
    $rep3 = Read-Host "Voulez-vous Activer ou Désactiver le pare-feu du poste distant $ipCible ? [A/D] " 
    if ($rep3 -eq "A") {         
        sshCible "powershell Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled 0"
        Write-Host "Le pare-feu cible a été activé"
    }    
    elseif ($rep3 -eq "D") {        
        sshCible "powershell Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled 0" 
        Write-Host "Le pare-feu cible a été désactivé"
    }
    else {        
        Write-Host "Demande invalide"
    }
}

function l_fireWall {
    $rep3 = Read-Host "Voulez-vous Activer ou Désactiver le pare-feu du poste distant $ipCible ? [A/D] " 
    if ($rep3 -eq "A") {
        sshCible "sudo -S ufw --force enable" 
        Write-Host "Le pare-feu cible a été activé"
    }   
    elseif ($rep3 -eq "D") {        
        sshCible "sudo -S ufw disable" 
        Write-Host "Le pare-feu cible a été désactivé"
    }
    else {    
        Write-Host "Demande invalide"
    }
}

# Date de dernière connexion d'un utilisateur
function lastConnexion {
    $lastCo = Read-Host "Entrez le nom de l'utilisateur ? "  
    if ($script:versionDeLOS -eq 0) {
        sshCible "last -n 1 '$lastCo'" # linux
    }
    else {
        sshCible "Get-LocalUser $lastCo | Select-Object Name, LastLogon" # windows
    }
    Retour-Menu SsMenu-LogUser
}
# Date dernière modification password
function lastModifMdp {
$modifMdp = Read-Host "Entrez le nom de l'utilisateur du mdp ? "  
    if ($script:versionDeLOS -eq 0) {
        sshCible "chage -l '$modifMdp'" # linux
    }
    else {
        sshCible "Get-LocalUser '$modifMdp' | Select-Object Name, PasswordLastSet" # windows
    }
    Retour-Menu SsMenu-LogUser
}

# Liste des sessions ouvertes par l'utilisateur
function listOpenUser { 
    if ($script:versionDeLOS -eq 0) {
    sshCible "w" # linux
    }
    else {
        sshCible "query user" # windows
    }
    Retour-Menu SsMenu-LogUser
}
#####################################################
#####################################################
function getTime {
    $script:date = Get-Date -Format yyyyMMdd
    $script:heure = Get-Date -Format HHmmss
}
# Création utilisateur
function newUser {
    if ($script:versionDeLOS -eq 0) {
        L_NewLocalUsers
    }
    else {
        W_NewLocalUsers
    }
    addLog "newUser"
    Retour-Menu SsMenu-Gestion
}
# Changement de Mot de Passe
function changePasswd {
    if ($script:versionDeLOS -eq 0) {
        L_ChangePassword
    }
    else {
        W_ChangePassword
    }
    addLog "changePasswd"
    Retour-Menu SsMenu-Gestion
}
# Suppression utilisateur
function delUser {
    if ($script:versionDeLOS -eq 0) {
        L_DelUser
    }
    else {
        W_DelUser
    }
    addLog "delUser"
    Retour-Menu SsMenu-Gestion
}
# Ajout au groupe Admin
function addAdmin {
    if ($script:versionDeLOS -eq 0) {
        L_AddAdmin
    }
    else {
        W_AddAdmin
    }
    addLog "addAdmin"
    Retour-Menu SsMenu-Gestion
}
# Ajout à un groupe utilisateur
function addGroup {
    if ($script:versionDeLOS -eq 0) {
        L_AddGroup
    }
    else {
        W_AddGroup
    }
    addLog "addGroup"
    Retour-Menu SsMenu-Gestion
}
# Redemarrage du pc distant
function redemarrage {
    if ($script:versionDeLOS -eq 0) {
        L_Redemarrage
    }
    else {
        W_Redemarrage
    }
    addLog "redemarrage"
    Retour-Menu SsMenu-Gestion
}
# Création de répertoire
function creerDoss {
    if ($script:versionDeLOS -eq 0) {
            l_creerDoss
    }
    else {
        w_creerDoss
    }
    addLog "creerDoss"
    Retour-Menu SsMenu-Admin
}
# Suppression de répertoire
function supprDoss {
    if ($script:versionDeLOS -eq 0) {
        l_supprDoss
    }
    else {
        w_supprDoss
    }
    addLog "supprDoss"
    Retour-Menu SsMenu-Admin
}
# Modification de répertoire (changement de nom et droits d'accès)
function modifDoss {
    if ($script:versionDeLOS -eq 0) {
        l_modifDoss
    }
    else {
        w_modifDoss
    }
    addLog "modifDoss"
    Retour-Menu SsMenu-Admin
}
# Contrôle du pare-feu
function fireWall {
    if ($script:versionDeLOS -eq 0) {
        l_fireWall
    }
    else {
        w_fireWall
    }
    addLog "fireWall"
    Retour-Menu SsMenu-Admin
}

function dnsActuel {
    if ($script:versionDeLOS -eq 0) {
        $dns = sshCible "cat /etc/resolv.conf"
    }
    else {
        # Correction : Get-DnsClientServerAddress (sans le 's' à Client)
        $dns = sshCible "powershell -Command ""Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses""" 
    }
    Write-Host "DNS trouvé : $dns"
    getTime
    Add-Content -Path "DNS_${cibleordi}_${script:date}.txt" -Value $dns
    AddLog -Arg "DNS"
    SsMenu-Recueil
}

# ip et passerelle
function Ips {
    if ($script:versionDeLOS -eq 0) {
        $reseau = sshCible "ip a"
    }
    else {
        $reseau = sshCible "ipconfig /all"
    }
    Write-Host $reseau
    getTime
    Add-Content -Path "Reseau_${cibleordi}_${script:date}.txt" -Value $reseau
    AddLog -Arg "reseau"
    SsMenu-Recueil
}

#La version de l'OS de l'ordi cible
function VersionOs {
    if ($script:versionDeLOS -eq 0) {
        $os = sshCible "uname -a"
    }
    else {
        $os = sshCible "powershell -Command ""[System.Environment]::OSVersion.VersionString"""
    }
    Write-Host "$($os)"
    getTime # Ajout de l'appel pour peupler $script:date
    Add-Content -Path "VersionOS_${cibleordi}_${script:date}.txt" -Value $os
    AddLog -Arg "Os"
    SsMenu-Recueil
}

#trouve le nom de la carte graphique
function CarteGraph {
    if ($script:versionDeLOS -eq 0) {
        $carte = sshCible "lspci | grep -i 'vga'"
    }
    else {
        $carte = sshCible "powershell ""Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name"""
    }
    Write-Host $carte
    getTime
    Add-Content -Path "GPU_${cibleordi}_${script:date}.txt" -Value $carte
    AddLog -Arg "Carte"
    SsMenu-Recueil
}

#fonction uptime
function DonneUptime {
    if ($script:versionDeLOS -eq 0) {
        $uptime = sshCible "uptime -p"
    }
    else {
        $uptime = sshCible "powershell -Command ""(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime"""
    }
    Write-Host "$($uptime)"
    getTime # Ajout de l'appel pour peupler $script:date
    Add-Content -Path "Uptime_${cibleordi}_${script:date}.txt" -Value $uptime
    AddLog -Arg "Uptime"
    SsMenu-Recueil
}   

#version BIOS
function VersBios {
    if ($script:versionDeLOS -eq 0) {
        $bios = sshCible "sudo dmidecode -t bios"
    }
    else {
        $bios = sshCible "powershell -Command ""Get-CimInstance Win32_BIOS | Select SMBIOSBIOSVersion, Manufacturer"""
    }
    Write-Host "$($bios)"
    getTime
    Add-Content -Path "Bios_${cibleordi}_${script:date}.txt" -Value $bios
    AddLog -Arg "Bios"
    SsMenu-Recueil
}

#Table Arp
function Arp {
    if ($script:versionDeLOS -eq 0) {
        $arp = sshCible "ip n"
    }
    else {
        $arp = sshCible "Get-NetNeighbor"
    }
    Write-Host "$($arp)"
    getTime
    Add-Content -Path "Arp_${cibleordi}_${script:date}.txt" -Value $arp
    AddLog -Arg "Arp"
    SsMenu-Recueil
}

# evenements critiques
function EventCrit {
    if ($script:versionDeLOS -eq 0) {
        $event = sshCible "journalctl -p crit -n 10"
    }
    else {
        $event = sshCible "Get-EventLog -LogName System -EntryType Error -Newest 10"
    }
    Write-Host "$($event)"
    getTime
    Add-Content -Path "Event_${cibleordi}_${script:date}.txt" -Value $event
    AddLog -Arg "Event"
    SsMenu-Recueil
}
    
#table de routage
function TableRoutage {
    if ($script:versionDeLOS -eq 0) {
        $routage = sshCible "ip r"
    }
    else {
        $routage = sshCible "Get-NetRoute"
    }
    Write-Host "$($routage)"
    getTime
    Add-Content -Path "Routage_${cibleordi}_${script:date}.txt" -Value $routage
    AddLog -Arg "Routage"
    SsMenu-Recueil
}

#liste des interfaces reseaux
function Interface {
    if ($script:versionDeLOS -eq 0) {
        $interface = sshCible "ip link show"
    }
    else {
        $interface = sshCible "Get-NetAdapter"
    }
    Write-Host "$($interface)"
    getTime
    Add-Content -Path "Interfaces_${cibleordi}_${script:date}.txt" -Value $interface
    AddLog -Arg "Interfaces"
    SsMenu-Recueil
}
# Recherche evenement par utilisateur
function rechercheUtilisateur {
    $userRech = Read-Host "Entrez le nom de l'utilisateur pour la recherche des evenements:" 
        if ($script:versionDeLOS -eq 0) {    
            sshCible "grep '$userRech' /var/log/log_evt.log"  
        }
        else {
        sshCible "powershell Select-String -Path 'C:\logs\log_evt.log' -Pattern '$userRech'"
        }
        Retour-Menu SsMenu-Recueil
}
# Recherche evenement par ordinateur
function rechercheOrdinateur {
    $ordiRech = Read-Host "Entrez l'adresse IP pour la recherche des evenements:" ordi_rech
        if ($script:versionDeLOS -eq 0) {
            sshCible "grep '$ordiRech' /var/log/log_evt.log"  
        }
        else {
            sshCible "powershell Select-String -Path 'C:\log_evt.log' -Pattern '$ordiRech'"
        }
        Retour-Menu SsMenu-Recueil
}
# ajout d'une action passée en argument au fichier log
function AddLog {
    param([string]$Arg)
    getTime
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "${script:date}_${script:heure}_$Arg"
}
########################################################
########################################################

# Menu principal
function Menu-Principal {
    Write-Host "================================"
    Write-Host "         MENU PRINCIPAL"
    Write-Host "================================"
    Write-Host "Que voulez-vous faire?"
    Write-Host " 1) Gestion utilisateur"
    Write-Host " 2) Administration"
    Write-Host " 3) Recueil d'information"
    Write-Host " 4) Consultation des logs"
    Write-Host " 5) Consultation des logs d'utilisation du script"
    Write-Host " 6) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { SsMenu-Gestion }
        "2" { SsMenu-Admin }
        "3" { SsMenu-Recueil }
        "4" { SsMenu-Recherche }
        "5" { SsMenu-LogUser }
        "6" { Quitter }
        default { Write-Host "ERREUR"; Menu-Principal }
    }
}

# Sous-menu gestion utilisateurs
function SsMenu-Gestion {
    Write-Host "Quelle action voulez-vous effectuer?"
    Write-Host " 1) Création de compte"
    Write-Host " 2) Changement de mdp"
    Write-Host " 3) Suppression de compte"
    Write-Host " 4) Ajout à un groupe admin"
    Write-Host " 5) Ajout à un groupe"
    Write-Host " 6) Retour au menu Principal"
    Write-Host " 7) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { newUser }
        "2" { changePasswd }
        "3" { delUser }
        "4" { addAdmin }
        "5" { addGroup }
        "6" { Menu-Principal }
        "7" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Gestion }
    }
}

# Sous-menu administration
function SsMenu-Admin {
    Write-Host "Que voulez-vous faire?"
    Write-Host " 1) Redémarrer le poste"
    Write-Host " 2) Créer un répertoire"
    Write-Host " 3) Modifier un répertoire"
    Write-Host " 4) Supprimer un répertoire"
    Write-Host " 5) Activer/Désactiver le pare-feu"
    Write-Host " 6) Prise en main à distance (CLI)"
    Write-Host " 7) Exécution de script sur la machine"
    Write-Host " 8) Retour au menu Principal"
    Write-Host " 9) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { redemarrage }
        "2" { creerDoss }
        "3" { modifDoss }
        "4" { supprDoss }
        "5" { fireWall }
        "6" { sshCible }
        "7" { Write-Host "test" }
        "8" { Menu-Principal }
        "9" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Admin }
    }
}

# Sous-menu recueil d'informations
function SsMenu-Recueil {
    Write-Host "Quelles informations voulez-vous récupérer?"
    Write-Host " 1)  DNS actuels"
    Write-Host " 2)  Liste des interfaces"
    Write-Host " 3)  Tables ARP"
    Write-Host " 4)  Table de routage"
    Write-Host " 5)  Version BIOS"
    Write-Host " 6)  IP, masque et passerelle"
    Write-Host " 7)  Version OS"
    Write-Host " 8)  Carte graphique"
    Write-Host " 9)  Uptime"
    Write-Host " 10) Derniers évènements critiques"
    Write-Host " 11) Retour au menu Principal"
    Write-Host " 12) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { dnsActuel }
        "2" { Interface }
        "3" { Arp }
        "4" { TableRoutage }
        "5" { VersBios }
        "6" { Ips }
        "7" { VersionOs }
        "8" { CarteGraph }
        "9" { DonneUptime }
        "10" { EventCrit }
        "11" { Menu-Principal }
        "12" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Recueil }
    }
}

# Sous-menu logs utilisateur
function SsMenu-LogUser {
    Write-Host "Quelles informations voulez-vous?"
    Write-Host " 1) Date de dernière connexion d'un utilisateur"
    Write-Host " 2) Dernière modification de mdp"
    Write-Host " 3) Liste des sessions ouvertes par l'utilisateur"
    Write-Host " 4) Retour au menu Principal"
    Write-Host " 5) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { lastConnexion }
        "2" { lastModifMdp }
        "3" { listOpenUser }
        "4" { Menu-Principal }
        "5" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-LogUser }
    }
}

# Sous-menu recherche logs
function SsMenu-Recherche {
    Write-Host "Quelles informations de journalisation recherchez-vous?"
    Write-Host " 1) Informations sur un utilisateur précis"
    Write-Host " 2) Informations sur un ordinateur précis"
    Write-Host " 3) Retour au menu Principal"
    Write-Host " 4) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { rechercheUtilisateur }
        "2" { rechercheOrdinateur }
        "3" { Menu-Principal }
        "4" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Recherche }
    }
}

# Retour menu
function Retour-Menu {
    param($DernierMenu)
    Write-Host "Que voulez-vous faire?"
    Write-Host " 1) Retourner au menu principal"
    Write-Host " 2) Retourner au dernier menu"
    Write-Host " 3) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { Menu-Principal }
        "2" { & $DernierMenu }
        "3" { Quitter }
        default { Write-Host "ERREUR"; Retour-Menu -DernierMenu $DernierMenu }
    }
}
# Lancement du script
Test-AdminContext
AskCible
connexionSsh
debutJournalisation
Menu-Principal
