# /terraform/main.tf

#Tofu & Provider Konfiguration
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

provider "proxmox" {
  pm_api_url  = "https://192.168.8.20:8006/api2/json" # API endpoint (f.eks. PVE2)
#  pm_user     = var.proxmox_token_id
#  pm_password = var.proxmox_token
  pm_tls_insecure        = true
  pm_minimum_permission_check = false
}

# --- Oprettelse af K8s VM'er ---
resource "proxmox_vm_qemu" "k8s_node" {
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
    slot    = "0"
  }

  # NETVÆRK 1 (net0): Offentligt/Management (192.168.8.x)
  network {
    bridge  = "vmbr0" 
    model = "virtio"
    id   = "0"
  }
  
  # NETVÆRK 2 (net1): Privat/Cluster Replikering (10.0.0.x)
  # Denne VM vil have en ekstra interface, der skal konfigureres af Ansible senere
  network {
    bridge  = "vmbr1" # Skal matche netværksbridge
    model   = "virtio"
    id      = "0"
}
  
  # Cloud-Init (Sætter kun 192-nettet, da 10-nettet opsættes i Ansible)
  ipconfig0 = "ip=192.168.8.${each.value.ip}/24,gw=192.168.8.1"
  sshkeys   = file("~/.ssh/id_bachelor_project.pub")
  # public ssh-key skal kopieres fra alternativ sted - husk!
  ciuser    = "gitops" 
}
