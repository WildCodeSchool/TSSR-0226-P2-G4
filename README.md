# Projet 2 : Automatisation de tâches par script

# **_Sommaire_** : 

1.  [Description du Projet](#Description-du-Projet)
2.  [Membre du groupe et Rôle des Membres](#Membre-du-groupe-et-Rôle-des-Membres)
3.  [Architecture technique](#Architecture-technique)
4.  [Technologies Utilisées](#Technologies-Utilisées)
5.  [Logiciel](#Logiciel)
6.  [Difficultés et solutions rencontrées](#Difficultés-et-solutions-rencontrées)
7.  [Améliorations possibles](#Améliorations-possibles)

# _Description du Projet_ 

1. Mettre en place une architecture client/serveur sur Proxmox.
2. Automatisation par script des tâches suivantes:

Gestion des utilisateurs | Gestion admin | Collecte d'infos | Recherche d'infos | Traitement d'infos |
| --- | --- | --- | --- | --- |

* Création de compte utilisateur local
* Changement de mot de passe
* Suppression de compte utilisateur local
* Ajout à un groupe d'administration
* Ajout à un groupe
* Redémarrage
* Création de répertoire
* Suppression de répertoire
* Prise de main à distance (CLI)
* Activation du pare-feu
* Exécution de script sur la machine distante
* Modification de répertoire
* DNS actuels
* Liste des interfaces
* Table ARP
* Table de routage
* BIOS/UEFI version
* Adresse IP, masque, passerelle
* Version de l'OS
* Carte graphique
* Uptime
* 10 derniers événements critiques
* Recherche des evenements dans le fichier log_evt.log pour un utilisateur
* Recherche des evenements dans le fichier log_evt.log pour un ordinateur
* Date de dernière connexion d’un utilisateur
* Date de dernière modification du mot de passe
* Liste des sessions ouvertes par l'utilisateur

# _Membre du groupe et Rôle des Membres_

Noms | Rôles | Sprint S-01 |
| :---: | :---: | :---: |
Zishan | Product Owner | Backlog - Gestion utilisateurs/admin
Xavier |Scrum Master | Pseudo code - Collecte, Recherche, Traitement infos 
Aymeric | Tech experts | GitHub - Gestion utilisateurs/admin
Minjha | Tech experts | GitHub - Gestion utilisateurs/admin - Configuration IP
Commun |     | Architecture client/server |

# _Architecture technique_

Configuration des 4 VMs dont 2 clients et 2 servers :

50Go de RAM pour les clients et 40Go pour les serveurs



Windows 11 pro | Ubuntu | Windows Server 2025 | Server Debian | 
| :---: | :---: | :---: | :---: |
CLIWIN01 | CLILIN01 | SRVWIN01 | SRVLX01 | @IP DG |
172.16.40.20 | 172.16.40.30 | 172.16.40.5 | 172.16.40.10 | 172.16.40.254 |

Masque de sous-réseaux : 255.255.255.0

DNS                    : 8.8.8.8

# _Technologies Utilisées_

VsCode 
Bash
PowerShell









