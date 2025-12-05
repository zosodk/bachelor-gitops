# /terraform/variables.tf

# --- Autentificering (Matcher credentials.auto.tfvars) ---
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_user" {
  type = string
}

variable "proxmox_token_id" {
  type = string
}

variable "proxmox_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "proxmox_template_name" {
  type = string
}

# --- K8s Node Definition (Single Source of Truth) ---
variable "k8s_nodes" {
  type = map(object({
    id            = number
    ip            = number         # Sidste oktet i 192.168.8.x & 10.0.0.x
    pve_host      = string         # "pve2" eller "pve3"
    storage_name  = string         # "vm-storage" (PVE2) eller "local-zfs" (PVE3)
    cores         = number
    memory        = number
  }))
  default = {
    # MASTER 1: VMID 30101 -> IP 101 (PVE3/NVMe)
    "b-k8s-master-1" = {
      id           = 30101
      ip           = 101
      pve_host     = "pve3"
      storage_name = "vm-storage" 
      cores        = 2
      memory       = 4096
    }
    
    # MASTER 2: VMID 30102 -> IP 102 (PVE2/SSD)
    "b-k8s-master-2" = {
      id           = 30102
      ip           = 102
      pve_host     = "pve2"
      storage_name = "vm-storage"
      cores        = 2
      memory       = 4096
    }
    
    # WORKER 1: VMID 30110 -> IP 110 (PVE3/NVMe)
    "b-k8s-worker-1" = {
      id           = 30110
      ip           = 110
      pve_host     = "pve3"
      storage_name = "vm-storage" 
      cores        = 4
      memory       = 8192
    }
    
    # WORKER 2: VMID 30111 -> IP 111 (PVE2/SSD)
    "b-k8s-worker-2" = {
      id           = 30111
      ip           = 111
      pve_host     = "pve2"
      storage_name = "vm-storage"
      cores        = 4
      memory       = 8192
    }
  }
}