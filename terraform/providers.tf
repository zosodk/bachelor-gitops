# /terraform/providers.tf

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