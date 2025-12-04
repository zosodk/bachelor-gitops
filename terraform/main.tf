# /terraform/main.tf

#Tofu & Provider Konfiguration
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url  = "https://192.168.8.20:8006/api2/json" # API endpoint (f.eks. PVE2)
  pm_user     = var.proxmox_api_user
  pm_token_id = var.proxmox_token_id
  pm_token    = var.proxmox_token
  pm_tls_insecure = true
}

# --- Oprettelse af K8s VM'er ---
resource "proxmox_vm_qemu" "k8s_node" {
  # Bruger 'for_each' til at iterere gennem de noder, der er defineret i variables.tf
  for_each    = var.k8s_nodes

  target_node = each.value.pve_host # Fordeler noder mellem pve2 og pve3
  name        = each.key
  vmid        = each.value.id
  
  # Basiskonfiguration
  clone       = var.proxmox_template_name 
  agent       = 1
  onboot      = true
  cores       = each.value.cores
  memory      = each.value.memory

  # Disk opsætning
  disk {
    storage = each.value.storage_name # Vælger den hurtige, lokale storage
    size    = "40G"
    type    = "scsi"
    # Sørg for at boote fra denne disk (rettes automatisk af Tofu/Provider)
  }

  # NETVÆRK 1 (net0): Offentligt/Management (192.168.8.x)
  network {
    bridge  = "vmbr0" 
  }
  
  # NETVÆRK 2 (net1): Privat/Cluster Replikering (10.0.0.x)
  # Denne VM vil have en ekstra interface, der skal konfigureres af Ansible senere
  network {
    bridge  = "vmbr1" # Skal matche netværksbridge
  }
  
  # Cloud-Init (Sætter kun 192-nettet, da 10-nettet opsættes i Ansible)
  ipconfig0 = "ip=192.168.8.${each.value.ip}/24,gw=192.168.8.1"
  sshkeys   = file("~/.ssh/id_bachelor_project.pub")
  # public ssh-key skal kopieres fra alternativ sted - husk!
  ciuser    = "gitops" 
}
