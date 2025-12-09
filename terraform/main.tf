# /terraform/main.tf

#Provider Definition flyttet til providers.tf

# --- Oprettelse af K8s VM'er (Masters & Workers) ---
resource "proxmox_vm_qemu" "k8s_node" {
  for_each    = var.k8s_nodes

  target_node = each.value.pve_host
  name        = each.key        
  vmid        = each.value.id   
  
  # Kloning og Boot Hang Fix
  clone       = var.proxmox_template_name 
  agent       = 1
  start_at_node_boot = true 
  
  # LØSNING PÅ BOOT HANG: Tvinger VM til at vente længere og bruge bedre I/O
  additional_wait = 15 
  scsihw          = "virtio-scsi-single" 
  
  # Ressourcer 
  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }
  memory      = each.value.memory

  # 1. DISK DEFINITION (OS Disk)
  disk {
    type    = "disk"
    slot    = "scsi0"
    storage = each.value.storage_name 
    size    = "32G" 
  }

  # 2. CLOUD-INIT DREV - fjernet #size    = "4M"
  disk {
    type    = "cloudinit" 
    slot    = "ide2"      
    storage = each.value.storage_name 
  }

  # NETVÆRK 1 (net0): Offentligt/Management (192.168.8.x)
  network {
    bridge  = "vmbr0" 
    model   = "virtio"
    id      = 0
  }
  
  # NETVÆRK 2 (net1): Privat/Cluster Replikering (10.0.0.x) - Holdt i koden for fremtidig brug
  network {
    bridge  = "vmbr1" 
    model   = "virtio"
    id      = 1
  }
  
  # Cloud-Init Metadata
  ipconfig0 = "ip=192.168.8.${each.value.ip}/24,gw=192.168.8.1" 
  ipconfig1 = "ip=10.0.0.${each.value.ip}/24"
  
  sshkeys   = file("~/.ssh/id_bachelor_project.pub")
  ciuser    = "gitops" 
}