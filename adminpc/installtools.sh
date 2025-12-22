#!/bin/bash
set -e # Stop scriptet hvis en kommando fejler

# Sikkerhedstjek: Scriptet må IKKE køres som root
if [ "$(id -u)" -eq 0 ]; then
  echo "FEJL: Dette script skal køres som din standardbruger (f.eks. 'gitops'), IKKE som root."
  echo "Scriptet bruger selv 'sudo' hvor det er nødvendigt."
  exit 1
fi

# Hent brugernavnet på den nuværende bruger
CURRENT_USER=$(whoami)
SSH_KEY_PATH="$HOME/.ssh/id_bachelor_project"

echo ">>> Velkommen $CURRENT_USER. Starter opsætning af Admin Node..."

echo ">>> [1/9] Opdaterer Systemet..."
sudo apt-get update && sudo apt-get upgrade -y
# Installerer grundlæggende afhængigheder
sudo apt-get install -y curl git unzip software-properties-common python3-pip apt-transport-https ca-certificates gnupg lsb-release

# Tjek for reboot (fra din bash_history erfaring)
if [ -f /var/run/reboot-required ]; then
    echo "!!! ADVARSEL: Kernel opdateringer kræver genstart. Anbefales at køre 'sudo reboot' efter dette script !!!"
fi