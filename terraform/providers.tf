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
  }

  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstateebxte"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
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
