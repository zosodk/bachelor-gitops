# /terraform/main.tf

# --- Tofu & Provider Konfiguration (Bruger den opdaterede v3.0 syntaks) ---
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06" # Vi bruger den version, du initialiserede
    }
  }
}

provider "proxmox" {
  pm_api_url             = var.proxmox_api_url
  
  # Autentifikation via API Token
  pm_api_token_id        = var.proxmox_token_id
  pm_api_token_secret    = var.proxmox_token_secret

  pm_tls_insecure        = true
  pm_minimum_permission_check = false 
}

resource "proxmox_vm_qemu" "test_node" {
  target_node = "pve2"
  name        = "b-test-node-30199"
  vmid        = var.test_vmid
  
  # Basiskonfiguration (Mindst muligt)
  clone       = var.proxmox_template_name 
  agent       = 1
  start_at_node_boot = true # Erstatter deprecated 'onboot'
  cores       = 1
  memory      = 1024

  # Disk opsætning
  disk {
    storage = "VM-Storage"
    size    = "10G"
    type    = "scsi"
    slot    = 0
  }

  # Netværk
  network {
    bridge  = "vmbr0" 
    model   = "virtio"
    id      = 0
  }
  
  # Cloud-Init
  ipconfig0 = "ip=192.168.8.${var.test_ip}/24,gw=192.168.8.1"
  sshkeys   = file("~/.ssh/id_bachelor_project.pub")
  ciuser    = "gitops" 
}