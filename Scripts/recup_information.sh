#declaration variables
cibleordi=0
date=0
heure=0
utilisateur=$(whoami)
var_OS= $(uname -s)
var_ss= 1
#declaration fonctions
# fonction qui demande à l'utilisateur quelle est l'ip de l'ordinateur cible, teste la connexion ssh et en même temps extrait l'os cible
#fonction test ip
function test_ip {
    local regex='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$' #merci claude pour le regex, notez que j'ai passé 20 min a comprendre comment il marche

    if [[ "$ip_cible" =~ $regex ]]; then
        echo "IP valide : $ip_cible"
    else
        echo "Erreur : '$ip_cible' n'est pas une adresse IP valide"
        ask_cible
    fi
}

function ask_cible {
    echo -e "Bonjour et bienvenue sur ce script d'administration \n"
    read -p -e "Quelle est l'ip de la machine cliente? \n  Veuillez rentrer une ip correcte sous la forme **.**.**.**" ip_cible
    test_ip

}
function connexion_ssh{
    local test1= $(ssh "$USER@$ip_cible")
    if [ $test1 ]
        then
        version_de_lOS= "$(uname -s)"
        var_ssh= "$("$USER"@"$ip_cible")"
        else
        echo "erreur"
        exit 1
    fi
}
#crée le fichier log et l'initialise
function debut_journalisation {
    echo -e "StartScript \n" >> /var/log log_evt.log
}

#heure courante
function time {
date= $(date +"%Y%m%d")
heure= $(date +"%H%M%S")
}
#version os
function version_OS
var_OS= "$(uname -a)"
echo "$var_OS" >> OS_"$cibleordi"_"$date".txt
add_log "OS"
retour_menu

#Carte graphique
function carte_graph{
local carte= "$(lspci | grep -i "vga")"
echo $carte >> carte_"$cibleordi"_"$date".txt
add_log "carte"
retour_menu
}
#dns actuel
function dns_actuel{
    if [[$boul_os -eq 0]]
        then
            local dns= "$(cat /etc/resolv.conf)"
        else
            local dns= "$(ipconfig /all)" | grep "DNS"
    fi
echo $dns >> DNS_"$cibleordi"_"$date".txt
add_log "DNS"
retour_menu
}
# ip et passerelle
function ips {
    if [[$boul_os -eq 0]]
        then
            local reseau= "$(ip a)"
        else
            local reseau= "$(ipconfig /all)"

    fi
echo $reseau >> reseau_"$cibleordi"_"$date".txt
add_log "reseau"
retour_menu
}

#fonction uptime
function  donne_uptime {
local var1= "$(uptime)" 
echo $var1 >> uptime_"$cibleordi"_"$date".txt
add_log "uptime"
retour_menu
}
#version BIOS
function vers_bios{
    local bios= "$(sudo dmidecode -t bios system)"
    echo $bios >> bios_"$cibleordi"_"$date".txt
add_log "bios"
retour_menu
}
#table ARP
function {
    local arp= "$(ip n)"
echo $arp >> arp_"$cibleordi"_"$date".txt
add_log "arp"
retour_menu
}
# evenements critiques
function event_crit {
    local event= "$(journalctl -p crit -n 10)"
echo $event >> critiques_"$cibleordi"_"$date".txt
add_log "critiques"
retour_menu
}

#table de routage
function table_routage{
    local routage= "$(ip r)"
echo $routage >> routage_"$cibleordi"_"$date".txt
add_log "routage"
retour_menu
}
#liste des interfaces reseaux
function interfaces{
    local interfaces= "$(ip link show)"
echo $interfaces >> routage_"$cibleordi"_"$date".txt
add_log "routage"
retour_menu
}

#ajout d'une action passée en argument au fichier log
function add_log {
time
echo ""$date"_"$heure"_"$utilisateur"_"$1"" >> $chemin_log log_evt.log
}





