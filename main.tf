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
  tags = {
    environment = "QuantumSmart"
  }
}

resource "azurerm_subnet" "qs_private_subnet" {
  name                 = "qs_private_subnet"
  resource_group_name  = azurerm_resource_group.QSRG.name
  virtual_network_name = azurerm_virtual_network.QS_VNET.name
  address_prefixes     = ["10.1.1.0/25"]
}

resource "azurerm_subnet" "qs_public_subnet" {
  name                 = "qs_public_subnet"
  resource_group_name  = azurerm_resource_group.QSRG.name
  virtual_network_name = azurerm_virtual_network.QS_VNET.name
  address_prefixes     = ["10.1.1.128/25"]
}



resource "azurerm_network_interface" "QS_NIC1" {
  name                = "qs_nic1"
  location            = azurerm_resource_group.QSRG.location
  resource_group_name = azurerm_resource_group.QSRG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.qs_public_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "QS_VMSS" {
  name                = "qsvmss"
  resource_group_name = azurerm_resource_group.QSRG.name
  location            = azurerm_resource_group.QSRG.location
  sku                 = "Standard_DS_v2"
  instances           = 1
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDU+K1hcgzdT/M78lljaijBK6QK7fs+wtMoEiDknHs1U10nLbj+ubQ3dFuMhV+GkfvurCmRmqF/qztF+75G6thudREbRoiXtn9VY4lVzBy7GA5/thrIDrqtabfTZw9Rc0sxUjG6dc3QHBfj0IlgmRQF5qzz0lTQcMM8CHtkc4RZN4byBZUVyXXoto1x3GOpMDNCQ81cKGAtWk5MZvoaJ7aQ6htHtS9cXjQEgbuBDCmvfIixDIOy+FO3AWkqg5+2bibGnXkOEfdFLaljmLKAS5GKOtS2gRTtGKILzXUMtics96MiW0hNGjvnLeDTTwM02+GeI9qFWQmhEXOMoJD68j9VmBJml0VH1I9DdIzWECDGSaEw5zBQ6bQvObPCeTUuCWhtWtXDWmqpQMPpUN7cTPSu+0iJJmqwIQAxVWQsq7Y+LXSnqNniv1sNCF5GBvEPj93cNWlbZasZi3+wlAVN4bPpXG4MsFRr5tLk6x20J7La/GUdaEGq1CVtwmwJuKrg6Hs="
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = azurerm_network_interface.QS_NIC1.name
    primary = true

    ip_configuration {
      name      = "public_ip"
      primary   = true
      subnet_id = azurerm_subnet.qs_public_subnet.id
    }
  }
}

