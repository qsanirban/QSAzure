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

resource "azurerm_resource_group" "QSRG" {
  name     = "QSRG"
  location = "westus2"
}

resource "azurerm_network_security_group" "QS_SG" {
  name                = "QS_SG"
  location            = azurerm_resource_group.QSRG.location
  resource_group_name = azurerm_resource_group.QSRG.name
}

resource "azurerm_virtual_network" "QS_VNET" {
  name                = "qs_vnet"
  location            = azurerm_resource_group.QSRG.location
  resource_group_name = azurerm_resource_group.QSRG.name
  address_space       = ["10.1.1.0/24"]
  dns_servers         = ["10.1.1.4", "10.1.1.5"]

  subnet {
    name           = "qs_public_subnet"
    address_prefix = "10.1.1.0/25"
  }

  subnet {
    name           = "qs_private_subnet"
    address_prefix = "10.1.1.128/25"
    security_group = azurerm_network_security_group.QS_SG.id
  }

  tags = {
    environment = "QuantumSmart"
  }
}
