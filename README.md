# 🎓 Bachelorprojekt: Modernisering af kritisk it-infrastruktur: Automatiseret GitOps Platform

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![ArgoCD](https://img.shields.io/badge/argo-%23E56428.svg?style=for-the-badge&logo=argo&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)

Dette repository indeholder kildekoden til mit bachelorprojekt. Projektet demonstrerer en fuldautomatiseret løsning, der etablerer et **K3s Kubernetes cluster** på Proxmox via Infrastructure as Code (IaC) og anvender **GitOps** principper til applikationsstyring vha **ArgoCD** 

---

## 📂 Projektstruktur

Herunder ses overblikket over mappestrukturen og formålet med de enkelte komponenter:

```text
/opt/bachelor-gitops/
├── 📁 adminpc/          # Opsætningsscripts til Admin/Controller noden
│                        # Sikrer at nødvendige tools (kubectl, tofu, ansible) er installeret.
│
├── 📁 ansible/          # Configuration Management
│   ├── inventory.yaml   # Oversigt over noder (genereret af OpenTofu eller statisk)
│   └── playbooks/       # Installerer K3s, joiner noder og bootstrapper ArgoCD.
│
├── 📁 kubernetes/       # GitOps "Single Source of Truth"
│   ├── apps/            # Applikations-manifests (Microservices)
│   └── system-apps/     # Infrastruktur-apps (Dashboard, ArgoCD config, Ingress).
│
├── 📁 terraform/        # Infrastructure as Code (On-Premises)
│   └── main.tf          # Provisionering af VM'er på Proxmox (Masters/Workers).
│
└── 📁 terraform-azure/  # Infrastructure as Code (Public Cloud)
                         # POC for Hybrid Cloud setup mod Azure AKS.
                         # (Bemærkning: Begrænset funktionalitet pga. licensvilkår).
```

---

## 🚀 Quick Start Guide

Følg denne rækkefølge for at bringe miljøet i luften fra bunden.

### 1. Klargøring af Admin PC
Først klargøres styringsmaskinen med de nødvendige værktøjer.
```bash
cd adminpc
# Kør setup script (hvis tilgængeligt) eller installer dependencies manuelt
```

### 2. Infrastruktur (Terraform)
Opretter de virtuelle maskiner på Proxmox serveren.
```bash
cd terraform
tofu init
tofu apply
```
*Dette opretter 2x Master noder og 2x Worker noder.*

### 3. Konfiguration & Cluster (Ansible)
Installerer K3s på noderne og installerer ArgoCD.
```bash
cd ../ansible
# 1. Test forbindelsen
ansible -i inventory.yaml all -m ping

# 2. Kør playbooks
ansible-playbook -i inventory.yaml playbooks/01-os-prep.yaml
ansible-playbook -i inventory.yaml playbooks/02-k3s-install.yaml
ansible-playbook -i inventory.yaml playbooks/03-argocd-bootstrap.yaml
```

### 4. Adgang til systemet
Når Ansible er færdig, er systemet klar.

* **ArgoCD UI:** `https://<NODE-IP>:30080` (NodePort)
* **Kubernetes Dashboard:** `https://<NODE-IP>:3xxxx` (Se specifik port med `kubectl get svc -n kubernetes-dashboard`)

---

## ☁️ Note vedrørende Hybrid Cloud (Azure)

Mappen `terraform-azure/` indeholder IaC-kode til oprettelse af et Azure Kubernetes Service (AKS) cluster for at demonstrere Hybrid Cloud kapabiliteter.

> **⚠️ Begrænsning:** Da projektet anvender en **"Azure for Students"** licens, er der begrænsninger på antallet af vCPU-kerner og specifikke rettigheder i Active Directory. Derfor er den fulde automatisering af Azure-delen ikke eksekverbar i dette miljø, men koden tjener som dokumentation for den tiltænkte arkitektur beskrevet i rapporten.

> **⚠️ Begrænsning:** Da projektet anvender en **"Azure for Students"** licens, er **Terraform driveren** deaktiveret for denne abonnementstype. Derfor er den fulde automatisering af Azure-delen ikke eksekverbar i dette miljø, men koden tjener som dokumentation for den tiltænkte arkitektur beskrevet i rapporten.

---

## 🛠 Teknologistak

| Komponent | Teknologi | Beskrivelse |
| :--- | :--- | :--- |
| **Virtualisering** | Proxmox VE | Underliggende hypervisor. |
| **Provisionering** | OpenTofu | Open-source alternativ til Terraform. |
| **Config Mgmt** | Ansible | Opsætning af OS og K3s cluster. |
| **Container Platform** | K3s | Letvægts Kubernetes distribution. |
| **GitOps Controller** | ArgoCD | Synkroniserer Git state med Cluster state. |
| **Dashboard** | K8s Dashboard | Grafisk overblik over ressourcer. |

---

© 2025/2026 - Bachelorprojekt
