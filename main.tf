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
  type    = list(string)
}

variable "client_id" {
  type    = list(string)
}

variable "tenant_id" {
  type    = list(string)
}

provider "azurerm" {
  version = "~> 3.0.2"
  subscription_id = var.subscription_id
  client_id = var.client_id
  tenant_id = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "TestRG"
  location = "westus2"
}
