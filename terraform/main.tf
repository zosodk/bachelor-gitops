# /terraform/main.tf

# --- Tofu & Provider Konfiguration ---
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06" 
    }
  }
}

provider "proxmox" {
  pm_api_url             = var.proxmox_api_url
  
  # Autentifikation via API Token (Læses fra credentials.auto.tfvars)
  pm_api_token_id        = var.proxmox_token_id
  pm_api_token_secret    = var.proxmox_token_secret

  pm_tls_insecure        = true
  pm_minimum_permission_check = false 
}

# --- Oprettelse af Simpel Test VM ---
resource "proxmox_vm_qemu" "test_node" {
  target_node = "pve2"
  name        = "b-test-node-30199" 
  vmid        = 30199         
  
  # HENTES FRA VARIABEL
  clone       = var.proxmox_template_name 
  
  agent       = 1
  start_at_node_boot = true 
  
  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }

  memory      = 1024

  # --- DISK DEFINITION (OS Disk) ---
  disk {
    type    = "disk"
    slot    = "scsi0"
    storage = "vm-storage"
    size    = "32"
  }

  # --- CLOUD-INIT DREV ---
  disk {
    type    = "cloudinit" 
    slot    = "ide2"      
    storage = "vm-storage"
  }


  # NETVÆRK
  network {
    bridge  = "vmbr0" 
    model   = "virtio"
    id      = 0
  }
  
  # Cloud-Init Metadata
  ipconfig0 = "ip=192.168.8.${var.test_ip}/24,gw=192.168.8.1"
  sshkeys   = file("~/.ssh/id_bachelor_project.pub")
  ciuser    = "gitops" 
}
