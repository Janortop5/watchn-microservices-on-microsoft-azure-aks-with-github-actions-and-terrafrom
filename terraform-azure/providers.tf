terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
    namedotcom = {
      source  = "lexfrei/namedotcom"
      version = "1.2.5"
    }        
  }

    backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatei8hze"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "namedotcom" {
  username = var.NAMEDOTCOM_USERNAME
  token    = var.NAMEDOTCOM_TOKEN
}

provider "azurerm" {
    features {}

    #    subscription_id = "${environment.ARM_SUBSCRIPTION_ID}"
    #	  tenant_id       = "${environment.ARM_TENANT_ID}"
    #	  client_id       = "${environment.ARM_CLIENT_ID}"
    #	  client_secret   = "${environment.ARM_CLIENT_SECRET}"
    subscription_id = var.ARM_SUBSCRIPTION_ID
    tenant_id       = var.ARM_TENANT_ID
    client_id       = var.ARM_CLIENT_ID
    client_secret   = var.ARM_CLIENT_SECRET
}

# Data source for AKS cluster
data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = azurerm_kubernetes_cluster.k8s.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_kubernetes_cluster.k8s
  ]
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
  }
  alias           = "aks"
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
  alias           = "aks"
}
