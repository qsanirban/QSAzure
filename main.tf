# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

variable "subscription_id" {
  type    = string
}

variable "client_id" {
  type    = string
}

variable "tenant_id" {
  type    = string
}

variable "client_secret" {
  type    = string
}

provider "azurerm" {
  version = "~> 3.0.2"
  subscription_id = var.subscription_id
  client_id = var.client_id
  tenant_id = var.tenant_id
  client_secret = var.client_secret
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "TestRG"
  location = "westus2"
}
