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
    ssh -o ConnectTimeout=5 "${userCible}@${ipCible}" "$args"
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
        $tableauNew = ("$ARGS")   
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

# Création de répertoire Windows
function w_creerDoss {
    $absolPath = Read-Host "Où voulez-vous créer votre dossier : " 
    if ((sshCible "Test-Path -Path '$absolPath'") -eq $false) {
        $rep1 = Read-Host " Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] "                  
        if ("$rep1" -eq "o") {
            $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
            sshCible "New-Item -ItemType Directory -Path '$absolPath/$nomDoss'" 
            Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"                                 
        }
        else {
            <# Action when all if and elseif conditions are false #>
            Write-Host "D'accord, retour au menu principal"
        }
    }
    else {
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? "                 
        sshCible "New-Item -ItemType Directory -Path '$absolPath/$nomDoss'" 
        Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"  
    }
}
function l_creerDoss {
    $absolPath = Read-Host "Où voulez-vous créer votre dossier : " 
    if ((sshCible "test -d '$absol_path'") -eq $false) {
        $rep1 = Read-Host "Le chemin vers le dossier n'existe pas, voulez-vous le créer ? [o/n] " 
        if ($rep1 -eq "o") {
            $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
            sshCible "sudo -S mkdir -p '$absolPath/$nomDoss'" 
            Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"
        }
        else {
            Write-Host "D'accord, retour au menu principal"
        }
    }
    else {
        $nomDoss = Read-Host "D'accord, quel est le nom du dossier à créer dans $absolPath ? " 
        sshCible "sudo -S mkdir -p '$absolPath/$nomDoss'" 
        Write-Host "Le dossier $nomDoss a bien été créé dans $absolPath"
    }
}
# Modification de répertoire (changement de nom ou de droits d'accès) Windows
function w_modifDoss {
    $absolPath = Read-Host "Où se situe le dossier à modifier : " 
    if ((sshCible "Test-Path -Path '$absolPath'") -eq $true) {
        $ancienDoss = Read-Host " Quel est le nom du dossier à modifier dans $absolPath ? " 
        if ((sshCible "Test-Path -Path '$absolPath\$ancienDoss'") -eq $true) {                
            $rep4 = Read-Host " Faut-il Renommer le dossier ou en Modifier les droits ? [R/M] "                
            if ($rep4 -eq "R") {
                $newDoss = Read-Host "D'accord, quel est le nouveau nom du dossier ? "
                sshCible "Rename-Item -Path '$absolPath\$ancienDoss' -NewName '$newDoss'" 
                Write-Host "Le dossier $ancienDoss a bien été renommé en $newDoss dans $absolPath"
            }
            elseif ($rep4 -eq "M") { 
                # La réponse attendue est toute attachée Sous la forme rwx ou xw ou r 
                $chxdroit = Read-Host "Quels droits voulez vous accorder sur le dossier $ancienDoss ? [r/w/x] " 
                                                        
                if ("$chxdroit" -match "^[rwx]+$") {
                    sshCible "icacls '$absolPath\$ancienDoss' /grant '${userName}:($chxdroit)'"
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
    if ((sshCible "test -d '$absolPath'") -eq $true) {
        $ancienDoss = Read-Host " Quel est le nom du dossier à modifier dans $absolPath ? " 
        if ((sshCible "test -d '$absolPath/$ancienDoss'") -eq $true) {
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
    if ((sshCible "Test-Path -Path '$absolPath'") -eq $false) {
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
        if ((sshCible "Test-Path -Path '$fullPath'") -eq $true) {                                        
            $count = sshCible "(Get-ChildItem '$fullPath' | Measure-Object).Count"
            if ($count -eq 0) {
                sshCible "Remove-Item -Recurse -Force '$fullPath'" 
                Write-Host "Le dossier $nomDoss a bien été supprimé dans $absolPath"
            }                                                
            else {
                $rep2 = Read-Host "Le dossier choisi n'est pas vide, voulez vous continuer et supprimer son contenu ? [o/n] "                                                      
                if ($rep2 -eq "o") {
                    sshCible "Remove-Item '$fullPath'" 
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
    if ((sshCible "test -d '$absolPath'") -eq $false) {
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
        if ((sshCible "test -d '$absolPath/$nomDoss'") -eq $true) {
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
        sshCible "Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True"
        Write-Host "Le pare-feu cible a été activé"
    }    
    elseif ($rep3 -eq "D") {        
        sshCible "Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled False" 
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

#####################################################
#####################################################
function getTime {
[string]$date = Get-Date -Format yyyyMMdd
[string]$heure = Get-Date -Format HHmmss
}

function dnsActuel {
    if ($(boul_os) -eq 0)
    {
        $dns=$(sshCible "cat /etc/resolv.conf")
    }
    else {
        $dns=$(sshCible "ipconfig /all | Select-String 'DNS'")
    }
Write-Host "$($dns)"
Add-Content -Path "DNS_${cibleordi}_${date}.txt" -Value $dns
AddLog -Arg "DNS"
SsMenu-Recueil
}
# ip et passerelle
function Ips {
    if ($(boul_os) -eq 0)
    {
        $reseau=$(sshCible "ip a")
    }
    else {
        $reseau=$(sshCible "ipconfig /all")
    }
Write-Host "$($Ips)"
Add-Content -Path "Reseau_${cibleordi}_${date}.txt" -Value $Ips
AddLog -Arg "reseau"
SsMenu-Recueil
}
#La version de l'OS de l'ordi cible
function VersionOs {
    if ($(boul_os) -eq 0)
    {
        $os=$(sshCible "uname -a")
    }
    else {
        $os=$(sshCible "[System.Environment]::OSVersion.VersionString")
    }
Write-Host "$($os)"
Add-Content -Path "VersionOS_${cibleordi}_${date}.txt" -Value $os
AddLog -Arg "Os"
SsMenu-Recueil
}

#trouve le nom de la carte graphique
function CarteGraph {
    if ($(boul_os) -eq 0)
    {
        $carte=$(sshCible "lspci | grep -i 'vga'")
    }
    else {
        $carte=$(sshCible "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name")
    }
Write-Host "$($carte)"
Add-Content -Path "VersionOS_${cibleordi}_${date}.txt" -Value $carte
AddLog -Arg "Carte"
SsMenu-Recueil
}
#fonction uptime
function DonneUptime {
    if ($(boul_os) -eq 0)
    {
        $uptime=$(sshCible "uptime")
    }
    else {
        $uptime=$(sshCible "(Get-CimInstance Win32_OperatingSystem).LastBootUpTime")
    }
Write-Host "$($uptime)"
Add-Content -Path "Uptime_${cibleordi}_${date}.txt" -Value $uptime
AddLog -Arg "Uptime"
SsMenu-Recueil
#version BIOS
function VersBios {
    if ($(boul_os) -eq 0)
    {
        $bios=$(sshCible "sudo dmidecode -t bios system")
    }
    else {
        $bios=$(sshCible "Get-CimInstance Win32_BIOS | Select-Object SMBIOSBIOSVersion, Manufacturer, ReleaseDate")
    }
Write-Host "$($bios)"
Add-Content -Path "Bios_${cibleordi}_${date}.txt" -Value $bios
AddLog -Arg "Bios"
SsMenu-Recueil
}

#Table Arp
function Arp {
    if ($(boul_os) -eq 0)
    {
        $arp=$(sshCible "ip n")
    }
    else {
        $arp=$(sshCible "Get-NetNeighbor")
    }
Write-Host "$($arp)"
Add-Content -Path "Arp_${cibleordi}_${date}.txt" -Value $arp
AddLog -Arg "Arp"
SsMenu-Recueil
}

# evenements critiques
function EventCrit {
    if ($(boul_os) -eq 0)
    {
        $event=$(sshCible "journalctl -p crit -n 10")
    }
    else {
        $event=$(sshCible "Get-EventLog -LogName System -EntryType Error -Newest 10")
    }
Write-Host "$($event)"
Add-Content -Path "Event_${cibleordi}_${date}.txt" -Value $event
AddLog -Arg "Event"
SsMenu-Recueil
}
#table de routage
function TableRoutage {
    if ($(boul_os) -eq 0)
    {
        $routage=$(sshCible "ip r")
    }
    else {
        $routage=$(sshCible "Get-NetRoute")
    }
Write-Host "$($routage)"
Add-Content -Path "Routage_${cibleordi}_${date}.txt" -Value $routage
AddLog -Arg "Routage"
SsMenu-Recueil
}
#liste des interfaces reseaux
function Interface {
    if ($(boul_os) -eq 0)
    {
        $interface=$(sshCible "ip link show")
    }
    else {
        $interface=$(sshCible "Get-NetAdapter")
    }
Write-Host "$($interface)"
Add-Content -Path "Interfaces_${cibleordi}_${date}.txt" -Value $interface
AddLog -Arg "Interfaces"
SsMenu-Recueil
}
# ajout d'une action passée en argument au fichier log
function AddLog {
    param([string]$param1)
    GetTime
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "${date}_${heure}_${utilisateur}_${param1}"
}
# Ferme le fichier quand l'utilisateur quitte
function Quitter {
    Add-Content -Path "C:\Windows\System32\LogFiles\log_evt.log" -Value "EndScript"
    exit 0
}
# Retour menu
function Retour-Menu {
    param($DernierMenu)
    Clear-Host
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
########################################################
########################################################
# Menu principal
function Menu-Principal {
    Clear-Host
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
    Clear-Host
    Write-Host "Quelle action voulez-vous effectuer?"
    Write-Host " 1) Création de compte"
    Write-Host " 2) Changement de mdp"
    Write-Host " 3) Suppression de compte"
    Write-Host " 4) Ajout à un groupe admin"
    Write-Host " 5) Ajout à un groupe"
    Write-Host " 6) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { New-User }
        "2" { Change-Passwd }
        "3" { Del-User }
        "4" { Add-Admin }
        "5" { Add-Group }
        "6" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Gestion }
    }
}

# Sous-menu administration
function SsMenu-Admin {
    Clear-Host
    Write-Host "Que voulez-vous faire?"
    Write-Host " 1) Redémarrer le poste"
    Write-Host " 2) Créer un répertoire"
    Write-Host " 3) Modifier un répertoire"
    Write-Host " 4) Supprimer un répertoire"
    Write-Host " 5) Activer/Désactiver le pare-feu"
    Write-Host " 6) Prise en main à distance (CLI)"
    Write-Host " 7) Exécution de script sur la machine"
    Write-Host " 8) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { Redemarrage }
        "2" { Creer-Doss }
        "3" { Modif-Doss }
        "4" { Suppr-Doss }
        "5" { Fire-Wall }
        "6" { Ssh-Cible }
        "7" { Write-Host "test" }
        "8" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Admin }
    }
}

# Sous-menu recueil d'informations
function SsMenu-Recueil {
    Clear-Host
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
    Write-Host " 11) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1"  { dnsActuel }
        "2"  { Interface }
        "3"  { Arp }
        "4"  { TableRoutage }
        "5"  { VersBios }
        "6"  { Ips }
        "7"  { VersionOs }
        "8"  { CarteGraph }
        "9"  { DonneUptime }
        "10" { EventCrit}
        "11" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Recueil }
    }
}

# Sous-menu logs utilisateur
function SsMenu-LogUser {
    Clear-Host
    Write-Host "Quelles informations voulez-vous?"
    Write-Host " 1) Date de dernière connexion d'un utilisateur"
    Write-Host " 2) Dernière modification de mdp"
    Write-Host " 3) Liste des sessions ouvertes par l'utilisateur"
    Write-Host " 4) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { Last-Connexion }
        "2" { Last-ModifMdp }
        "3" { List-OpenUser }
        "4" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-LogUser }
    }
}

# Sous-menu recherche logs
function SsMenu-Recherche {
    Clear-Host
    Write-Host "Quelles informations de journalisation recherchez-vous?"
    Write-Host " 1) Informations sur un utilisateur précis"
    Write-Host " 2) Informations sur un ordinateur précis"
    Write-Host " 3) Quitter"
    $choix = Read-Host "Votre choix"
    switch ($choix) {
        "1" { Recherche-Utilisateur }
        "2" { Recherche-Ordinateur }
        "3" { Quitter }
        default { Write-Host "ERREUR"; SsMenu-Recherche }
    }
}
# Lancement du script
Ask-Cible
Connexion-SSH
Debut-Journalisation
Menu-Principal
