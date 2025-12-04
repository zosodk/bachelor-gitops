# /terraform/main.tf

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
  pm_api_token_id        = var.proxmox_token_id
  pm_api_token_secret    = var.proxmox_token_secret
  pm_tls_insecure        = true
  pm_minimum_permission_check = false 
}

# --- Oprettelse af Simpel Test VM ---
resource "proxmox_vm_qemu" "test_node" {
  target_node = "pve2"
  name        = "b-test-node-30199"
  vmid        = var.test_vmid
  
  clone       = var.proxmox_template_name 
  agent       = 1
  
  # NY SYNT: Brug start_at_node_boot i stedet for onboot
  start_at_node_boot = true 

  # NY SYNT: CPU skal være i sin egen blok
  cpu {
    cores = 1
    type  = "x86-64-v2-AES" # Matcher host CPU type bedre
  }

  memory      = 1024

  # NY SYNT: Disk definition for v3.0
  disk {
    # 'type' skal være 'disk' (medietypen)
    type    = "disk"
    
    # 'slot' skal være den fulde streng (controller + id)
    slot    = "scsi0"
    
    storage = "VM-Storage"
    size    = "10G"
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