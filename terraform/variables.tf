# /terraform/variables.tf

variable "proxmox_api_url" { type = string }
variable "proxmox_api_user" { type = string }
variable "proxmox_token_id" { type = string }
variable "proxmox_token_secret" { type = string; sensitive = true }
variable "proxmox_password" { type = string; sensitive = true }
variable "proxmox_template_name" { type = string }

# --- SIMPEL TEST NODE ---
variable "test_vmid" { default = 30199 }
variable "test_ip"   { default = 199 }