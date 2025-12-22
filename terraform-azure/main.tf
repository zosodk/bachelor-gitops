terraform {
  required_providers {
    azurerm = {
  # Lås til version 3.x for at undgå v4 breaking changes
      version = "= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Bruger automatisk din 'az login' session - tilføjet nedenfor for at undgå automatisk registrering af ressourcer som Students ikke kan
  skip_provider_registration = true
}

# 1. Ressource Gruppe (Container til alt i Azure)
# opsætning af adgang til Azure er gemt som screenshot i dokumentationen

resource "azurerm_resource_group" "bachelor_rg" {
  name     = "bachelor-cloud-rg"
  location = "West Europe" # (Tæt på DK for lav latency)
}

# 2. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks_prd" {
  name                = "bachelor-prd-cluster"
  location            = azurerm_resource_group.bachelor_rg.location
  resource_group_name = azurerm_resource_group.bachelor_rg.name
  dns_prefix          = "bachelor-prd"
  
  # VIGTIGT for Students: Brug "Free" tier. 
  # Det betyder, at jeg ikke betaler for "Management Plane" (API serveren).
  sku_tier            = "Free"

  # Konfiguration af worker noder (VM'erne der kører pods)
  default_node_pool {
    name       = "agentpool"
    node_count = 1             # Jeg starter med 1 node for at spare credits
    vm_size    = "Standard_B2s" # Billig "Burstable" instans (2 vCPU, 4GB RAM)
  }

  # Bruger en automatisk identitet til at styre ressourcer
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    Project     = "Bachelor"
    ManagedBy   = "Terraform"
  }
}

# 3. Output: Kommando til at hente adgang (vises når den er færdig)
output "get_credentials_cmd" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.bachelor_rg.name} --name ${azurerm_kubernetes_cluster.aks_prd.name}"
}