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
    $script:userCible = Read-Host "Veuillez rentrer le nom exacte de la macheine cible"
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

function NewLocalUsers {
    testAdd
    foreach ($userName in $tableauNew) {
        if (sshCible (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue)) {
            Write-Host "Utilisateur $userName déjà existant"
        }
        else {
            New-LocalUser -Name $userName -NoPassword
            Write-Host "Utilisateur $userName créé avec succès"
        }
    }
}

NewLocalUsers
