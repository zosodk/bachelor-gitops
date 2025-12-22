#!/bin/bash
# Kør dette script fra DIN Mac/PC for at bootstrappe b-admin noden.
# Brug: ./bootstrap-admin-from-mac.sh
# KAn også køres fra en Linux maskine med ssh/scp installeret.
# --- KONFIGURATION ---
# -- Rediger disse variabler efter behov --
ADMIN_IP="192.168.8.100"
USER="gitops"
SSH_KEY_PATH="$HOME/.ssh/id_bachelor_project"
# Hvis du bruger en anden nøgle, opdater stien ovenfor.
# Husk at nøglen skal have adgang til både din Mac/PC og GitHub.
# Nøglen sklal også være konfigureret i cloud-init for b-admin noden.
# Nøglen skal være sat op i GitHub som deploy key eller i din brugerprofil.
# DVs gitops bruger i cloud-init template, skal matche denne nøgle. id_bachelor_project nøgle er standard i dette projekt.
# Cloud-init template skal bygges om, hvis du ønsker at bruge en anden nøgle.
REPO_URL="git@github.com:zosodk/bachelor-gitops.git"

echo "--- Bootstrapping b-admin på $ADMIN_IP ---"

# 1. Tjek om vi kan nå serveren
if ! ping -c 1 -W 1 $ADMIN_IP &> /dev/null; then
    echo "FEJL: Kan ikke pinge $ADMIN_IP. Tjek VPN eller netværk."
    exit 1
fi

# 2. Kopier SSH Nøgler (Løser 'Hønen og Ægget' for GitHub adgang)
echo ">>> [1/4] Kopierer SSH nøgler til serveren..."
# Vi kopierer både privat (til GitHub) og offentlig (til Terraform) nøgle
scp -i $SSH_KEY_PATH $SSH_KEY_PATH $SSH_KEY_PATH.pub $USER@$ADMIN_IP:~/.ssh/

# 3. Sæt rettigheder og Initialiser Git (Remote Kommandoer)
echo ">>> [2/4] Konfigurerer SSH og installerer Git på serveren..."
ssh -i $SSH_KEY_PATH $USER@$ADMIN_IP <<EOF
    # Fix rettigheder på nøgler (Kritisk for at SSH virker)
    chmod 600 ~/.ssh/id_bachelor_project
    chmod 644 ~/.ssh/id_bachelor_project.pub
    
    # Start Agent og tilføj nøgle
    eval "\$(ssh-agent -s)"
    ssh-add ~/.ssh/id_bachelor_project
    
    # Accepter GitHubs fingerprint automatisk (så scriptet ikke hænger)
    ssh-keyscan github.com >> ~/.ssh/known_hosts

    # Installer Git (så vi kan klone)
    sudo apt-get update -qq
    sudo apt-get install -y git -qq
EOF

# 4. Klon Repository (Nu hvor nøglerne er på plads)
echo ">>> [3/4] Kloner Repository på serveren..."
ssh -i $SSH_KEY_PATH $USER@$ADMIN_IP <<EOF
    # Start Agent igen (ny session)
    eval "\$(ssh-agent -s)"
    ssh-add ~/.ssh/id_bachelor_project

    sudo mkdir -p /opt/bachelor-gitops
    sudo chown $USER:$USER /opt/bachelor-gitops
    
    if [ ! -d "/opt/bachelor-gitops/.git" ]; then
        git clone $REPO_URL /opt/bachelor-gitops
    else
        cd /opt/bachelor-gitops
        git pull origin main
    fi
EOF

# 5. Kør Installationsscriptet (Det der ligger i repoet)
echo ">>> [4/4] Kører install_tools.sh fra repository..."
ssh -i $SSH_KEY_PATH $USER@$ADMIN_IP <<EOF
    # Gør scriptet eksekverbart og kør det
    # Antager scriptet ligger i roden eller adminpc mappen, juster sti efter behov
    chmod +x /opt/bachelor-gitops/install_tools_final.sh 
    /opt/bachelor-gitops/install_tools_final.sh
EOF

echo "--- Bootstrap Færdig! Log ind med: ssh $USER@$ADMIN_IP ---"