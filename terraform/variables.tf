# /terraform/variables.tf (KORRIGERET)

#Autentificering
variable "proxmox_api_user" { 
  type = string 
}

variable "proxmox_token_id" { 
  type = string 
}

variable "proxmox_token" { 
  type = string 
  sensitive = true 
} # SECRET

variable "proxmox_template_name" { 
  type = string 
  default = "9000" 
} # ID Cloud-init skabelon

# K8s Node Definition (Single Source of Truth)
variable "k8s_nodes" {
  type = map(object({
    id            = number
    ip            = number         # Sidste oktet i 192.168.8.x
    pve_host      = string         # "pve2" eller "pve3"
    storage_name  = string         # "VM-Storage" (PVE2) eller "Local-zfs" (PVE3)
    cores         = number
    memory        = number
  }))
  default = {
    # MASTER 1: VMID 30101 -> IP 192.168.8.101
    "b-k8s-master-1" = { id = 30101, ip = 101, pve_host = "pve3", storage_name = "Local-zfs", cores = 2, memory = 4096 }
    
    # MASTER 2: VMID 30102 -> IP 192.168.8.102
    "b-k8s-master-2" = { id = 30102, ip = 102, pve_host = "pve2", storage_name = "VM-Storage", cores = 2, memory = 4096 }
    
    # WORKER 1: VMID 30110 -> IP 192.168.8.110
    "b-k8s-worker-1" = { id = 30110, ip = 110, pve_host = "pve3", storage_name = "Local-zfs", cores = 4, memory = 8192 }
    
    # WORKER 2: VMID 30111 -> IP 192.168.8.111
    "b-k8s-worker-2" = { id = 30111, ip = 111, pve_host = "pve2", storage_name = "VM-Storage", cores = 4, memory = 8192 }
  }
}
