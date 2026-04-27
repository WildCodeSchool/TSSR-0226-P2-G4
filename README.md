# Projet 2 : Automatisation de tâches par script

# **_Sommaire_** : 

1.  [Description du Projet](#Description-du-Projet)
2.  [Membre du groupe et Rôle des Membres](#Membre-du-groupe-et-Rôle-des-Membres)
3.  [Architecture technique](#Architecture-technique)
4.  [Technologies Utilisées](#Technologies-Utilisées)
5.  [Logiciels](#Logiciels)
6.  [Difficultés et solutions rencontrées](#Difficultés-et-solutions-rencontrées)
7.  [Améliorations possibles](#Améliorations-possibles)

# _Description du Projet_ 

1. Mettre en place une architecture client/serveur sur Proxmox.
2. Automatisation par script des tâches suivantes:

<img width="461" height="461" alt="P2G4 drawio" src="https://github.com/user-attachments/assets/3dad82ad-09ee-4bde-9c0a-5d265825fb20" />

-----------------------------------------------------------------------------------------------------------------------------------------

| Gestion des utilisateurs                | Gestion admin                               | Recueil d'infos                  | Consultation des Logs                                                    | Surveillance utilisateurs                     |
| --------------------------------------- | ------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------ | --------------------------------------------- |
| Création de compte utilisateur local    | Redémarrage                                 | DNS actuels                      | Recherche des evenements dans le fichier log_evt.log pour un utilisateur | Date de dernière connexion d’un utilisateur   |
| Changement de mot de passe              | Création de répertoire                      | Liste des interfaces             | Recherche des evenements dans le fichier log_evt.log pour un ordinateur  | Date de dernière modification du mot de passe |
| Suppression de compte utilisateur local | Modification de répertoire                  | Table ARP                        |                                                                          | Liste des sessions ouvertes par l'utilisateur |
| Ajout à un groupe d'administration      | Suppression de répertoire                   | Table de routage                 |                                                                          |                                               |
| Ajout à un groupe                       | Prise de main à distance (CLI)              | BIOS/UEFI version                |                                                                          |                                               |
|                                         | Activation du pare-feu                      | Adresse IP, masque, passerelle   |                                                                          |                                               |
|                                         | Exécution de script sur la machine distante | Version de l'OS                  |                                                                          |                                               |
|                                         |                                             | Carte graphique                  |                                                                          |                                               |
|                                         |                                             | Uptime                           |                                                                          |                                               |
|                                         |                                             | 10 derniers événements critiques |                                                                          |                                               |

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

Pour ce projet, l'infrastructure repose sur Proxmox VE, une plateforme de gestion de virtualisation "Bare Metal".

Pourquoi un Hyperviseur de Type 1 ?
Contrairement à des solutions comme VirtualBox (Type 2) qui s'installent comme de simples logiciels sur Windows, Proxmox est le "Gouverneur" direct du matériel :

Performance brute : Installé directement sur le serveur physique, il n'y a pas de système d'exploitation intermédiaire (comme Windows 10/11) pour ralentir les échanges.

Stabilité accrue : Moins de couches logicielles signifie moins de risques de plantage du convoi de données.

## Les avantages :

La configuration de mon PC personnel (peu de: CPU, RAM, SSD) n'est plus un frein . Il est juste utilisé comme un "terminal" pour accéder à l'interface web Proxmox. 

Disponibilité H24 : Contrairement à une solution de virtualisation classique sur PC, les services (Web, BDD, VPN) restent en ligne 24h/24.

Efficience énergétique : Le serveur est optimisé pour la basse consommation. Laisser tourner ces VMs sur Proxmox est bien plus économique et silencieux que de laisser mon PC de bureau allumé toute la nuit, ce qui préserve ma facture d'électricité et la durée de vie de mon matériel personnel.

# _Logiciels_

VsCode    |     Shell Bash     |    PowerShell

# _Difficultés et solutions rencontrées_

1. Passerelle par defaut non routée sur Proxmox pour l'accès à internet permettant de récupérer le script sur le drive
2. Conexion SSH par clé sans mdp (envoi de la clé ssh publique dans le mauvais fichier "authorized_keys" du mauvais utilisateur "administrator au lieu de wilder") 
3. Trouver la cmd à ajouter devant les fonctions pour l'execution des cmd depuis le server vers les hôtes en ssh 
4. Déboublement des cmd Bash en PowerShell
5. Debug script sur server : VsCode ajoute un retour à la ligne causant des erreurs de synthaxe sur Debian

# Améliorations possibles

1. Configurer les VM pour copier/coller les cmd PowerShell 7.6
2. Plus de temps !
3. Entrer l'ip en argument du script au lieu de le demander 
4. Ajouter un clear dans le menu



