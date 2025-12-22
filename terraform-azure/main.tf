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
  location = "North Europe" # (Tæt på DK for lav latency)
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
# Manuel kørsel af denne kommando er nødvendig for at konfigurere kubectl til at forbinde til AKS klyngen.
#az provider register --namespace Microsoft.ContainerService
# Registrer Compute (VM'er til noderne)
#az provider register --namespace Microsoft.Compute
# Registrer Network (VNet, Load Balancer)
#az provider register --namespace Microsoft.Network
# Registrer Storage (Diske til databaser/PVC)
#az provider register --namespace Microsoft.Storage
# Registrer OperationsManagement (Nødvendig for AKS logs/metrics)
#az provider register --namespace Microsoft.OperationsManagement
#az provider register --namespace Microsoft.OperationalInsights
# Registrer ContainerService (AKS)
#az provider register --namespace Microsoft.ContainerService
#az provider show -n Microsoft.ContainerService --query "registrationState"
# Tjek registreringsstatus: skal sige "Registered"