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

echo ">>> [2/9] Installerer OpenTofu (Terraform)..."
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method deb
rm install-opentofu.sh

echo ">>> [3/9] Installerer Ansible..."
python3 -m pip install --user ansible
# Sikrer at ~/.local/bin er i PATH
export PATH=$PATH:$HOME/.local/bin
if ! grep -q "export PATH=\$PATH:\$HOME/.local/bin" ~/.bashrc; then
  echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
fi

echo ">>> [4/9] Installerer Kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo ">>> [5/9] Installerer Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo ">>> [6/9] Opsætter GitOps Mappestruktur..."
sudo mkdir -p /opt/bachelor-gitops
sudo chown -R $CURRENT_USER:$CURRENT_USER /opt/bachelor-gitops

echo ">>> [7/9] Konfigurerer SSH og Git..."
# Start SSH Agent og tilføj nøgle
if [ -f "$SSH_KEY_PATH" ]; then
    echo "Starter SSH-agent og tilføjer $SSH_KEY_PATH..."
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH"
    
    # Test forbindelse til GitHub (accepter host key automatisk første gang)
    echo "Tester forbindelse til GitHub..."
    ssh -T -o StrictHostKeyChecking=accept-new git@github.com || true
else
    # DEN OPDATEREDE ADVARSEL OM MANGLENDE NØGLER
    echo "---------------------------------------------------------------------"
    echo "ADVARSEL: SSH nøgler ikke fundet i $HOME/.ssh/"
    echo "Cloud-init har kun konfigureret adgang TIL denne maskine."
    echo "For at denne maskine kan styre GitHub og Terraform, skal du kopiere nøgleparret."
    echo "Kør dette fra din Mac/PC:"
    echo "  scp -i ~/.ssh/id_bachelor_project ~/.ssh/id_bachelor_project* $CURRENT_USER@<IP>:~/.ssh/"
    echo "---------------------------------------------------------------------"
fi

echo ">>> [8/9] Kloner Repository..."
cd /opt/bachelor-gitops
# Tjek om vi allerede har klonet, ellers klon direkte i mappen (uden undermappe)
if [ ! -d ".git" ]; then
    echo "Kloner bachelor-gitops..."
    # Forsøg at klone. Hvis SSH fejler, vil denne fejle.
    git clone git@github.com:zosodk/bachelor-gitops.git . || echo "FEJL: Kunne ikke klone repo. Tjek at du har kopieret din private SSH nøgle (se trin 7)."
else
    echo "Repo eksisterer allerede, henter opdateringer..."
    git pull origin main
fi

echo ">>> [9/9] Klargør Terraform..."
if [ -d "terraform" ]; then
    cd terraform
    echo "Kører tofu init..."
    tofu init || echo "ADVARSEL: tofu init fejlede (mangler måske providers eller netværk)"
    
    if [ ! -f "credentials.auto.tfvars" ]; then
        echo "----------------------------------------------------------------"
        echo "VIGTIGT: 'credentials.auto.tfvars' mangler i terraform mappen!"
        echo "Du skal oprette den manuelt med dine secrets før du kører 'tofu plan'."
        echo "----------------------------------------------------------------"
    fi
    cd ..
fi

echo ">>> SETUP FÆRDIG! <<<"
echo "-----------------------------------------------------"
echo "Installerede versioner:"
echo "Git:      $(git --version)"
echo "OpenTofu: $(tofu --version)"
echo "Ansible:  $(ansible --version | head -n 1)"
echo "Kubectl:  $(kubectl version --client --output=yaml | grep gitVersion | awk '{print $2}')"
echo "Azure CLI: $(az --version | head -n 1)"
echo "-----------------------------------------------------"
echo "Husk at logge ind og ud (eller køre 'source ~/.bashrc') for at opdatere PATH."