function Test-AdminContext {
    $UserIsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not ($UserIsAdmin)) {
        Write-Warning "Le script '$($MyInvocation.MyCommand)' ne peut pas être exécuté car la session PowerShell n'est pas exécutée dans le contexte Administrateur"
        exit
    }

}

Test-AdminContext 

function testIp {
    if ($($ipCible) -match "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$") { 
        Write-Host "IP valide : $($ipCible)"
    }
    else {
        Write-Host "Erreur : '$($ipCible)' n'est pas une adresse IP valide"
        askCible
    }    
}

# Prépare un alias pour la connexion ssh
function sshCible {
    ssh -t -o ConnectTimeout=5 "${$userCible}@${$ipCible}" "$*" 2>$null
}

# Demande l'ip et le compte distant (camel case- echo = write host $script contraire du local, backtic au lieu de backslash)
function askCible {
    Write-Host "Bonjour et bienvenue sur ce script d'administration`n"
    $script:ipCIble = Read-Host "Quelle est l'ip de la machine cliente? Veuillez rentrer une ip correcte sous la forme **.**.**.** " 
    testIp
    $script:userCible = Read-Host "Veuillez rentrer le nom exacte de l'utilisateur cible"
}

askCible

# Crée le fichier log et l'initialise
function debutJournalisation {
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "StartScript`n"
}

debutJournalisation

# Mise en variable du nom d'utilisateur

function testAdd {
    if ($Args -ne 0) {
        tableauNew=("$ARGS")   
    }
    else {
        $tableauNew = Read-Host "Veuillez rentrer les noms des utilisateurs (séparés par des espaces) : "
    } 
}

# Création de compte Windows

function W_NewLocalUsers {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue)) {
            Write-Host "Utilisateur $userName déjà existant"
        } 
        else {
            sshCible New-LocalUser -Name $userName -NoPassword
            Write-Host "Utilisateur $userName créé avec succès"
        }
    }
}

# Création de compte Linux

function L_NewLocalUsers {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (grep -q "^$userName:" /etc/passwd)) {
            Write-Host "Utilisateur $userName déjà existant"
        } 
        else {
            sshCible (sudo -S adduser --allow-bad-names "$userName")
            Write-Host "Utilisateur $userName créé avec succès"
        }
    }
}


# Changement de mot de passe Linux

function L_ChangePassword {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (sudo -S grep -q "^$userName:" /etc/passwd)) {
            sshCible (sudo -S passwd "$userName") && Write-Host "Mot de passe de $userName changé avec succès" 
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Changement de mot de passe Windows

function W_ChangePassword {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (Get-LocalUser -Name "$userName")) {
            sshCible ($NewPwd = Read-Host -AsSecureString; Get-LocalUser -Name "$userName" | Set-LocalUser -Password $NewPwd)
        }
        else
        {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Suppression de compte Linux

function L_DelUser {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (grep -q "^$userName:" /etc/passwd)) {
            sshCible (sudo -S deluser "$userName") && Write-Host "L'utilisateur $userName à bien été supprimé"
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Supression de compte Windows

function W_DelUser {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (Get-LocalUser -Name "$userName")) {
            sshCible (Remove-LocalUser -Name "$userName") && Write-Host "L'utilisateur $userName à bien été supprimé"
        }    
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Ajout à un groupe d'administration Linux

function L_AddAdmin {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (grep -q "^$userName:" /etc/passwd)) {
            sshCible (sudo -S usermod -aG sudo "$userName") && Write-Host "L'utilisateur $userName a été ajouté au groupe Admin"
        }    
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Ajout à un groupe d'administration Windows

function W_AddAdmin {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (Get-LocalUser -Name "$userName")) {
            sshCible (Add-LocalGroupmember -Group 'Administrators' -Member "$userName") && Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe Administrateur"
        }
        else {
            Write-Host "L'utilisateur $userName n'existe pas"
        }
    }
}

# Ajout à un groupe Linux

function L_AddGroup {
    testAdd
    foreach ($userName in $tableauNew) {
        If (sshCible (grep -q "^$userName:" /etc/passwd)) {
            $GroupName = Read-Host "Dans quel groupe voulez-vous ajouter $userName ? "
            If (! (sshCible (grep -q "^$groupName:" /etc/group))) {
                $Rep = Read-Host "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] "
                If ($Rep -eq "o") {
                    sshCible (sudo -S groupadd "$groupName") && Write-Host "Groupe $groupName créé"
                    sshCible (sudo -S usermod -aG $groupName "$userName") && Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe $groupName"
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
    foreach ($userName in $tableauNew) {
        If (sshCible (Get-LocalUser -Name "$userName")) {
            $GroupName = Read-Host "Dans quel groupe voulez-vous ajouter $userName ? "
            If (! (sshCible (grep -q "^$groupName:" /etc/group))) {
                $Rep = Read-Host "Le groupe choisi n'existe pas, voulez-vous le créer ? [o/n] "
                If ($Rep -eq "o") {
                    sshCible (New-LocalGroup "$groupName") && Write-Host "Groupe $groupName créé"
                    sshCible "Add-LocalGroupmember -Group "$groupName" -Member "$userName"" && Write-Host "L'utilisateur $userName a été ajouté avec succès au groupe $groupName"
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

# Choix de redémarrage Linux
function L_Redemarrage {
    $Rep5 = Read-Host "$userCible@$ipCible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] "
    If ($Rep5 -eq "o") {
        sshCible (sudo -S reboot) && Write-Host " La machine cible est en cours de redémarrage "
    }    
    else {
        Write-Host "D'accord, retour au menu principal"
    }
}

# Choix de redémarrage Windows
function W_Redemarrage {
    $Rep5 = Read-Host "$userCible@$ipCible est-ce bien la machine que vous souhaitez redémarrer ? [o/n] "
    If ($Rep5 -eq "o") {
        sshCible "Restart-Computer -ComputerName "$ipCible" -Force" && Write-Host " La machine cible est en cours de redémarrage "
    }    
    else {
        Write-Host "D'accord, retour au menu principal"
    }
}
