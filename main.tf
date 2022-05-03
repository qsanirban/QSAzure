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
  location = "westeurope"
}

resource "random_string" "qsfqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
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

resource "azurerm_public_ip" "qs_public_ip" {
 name                         = "qs-public-ip"
 location                     = azurerm_resource_group.QSRG.location
 resource_group_name          = azurerm_resource_group.QSRG.name
 allocation_method            = "Static"
 domain_name_label            = random_string.qsfqdn.result
 tags = {
    environment = "QuantumSmart"
  }
}

resource "azurerm_lb" "qs_lb" {
 name                = "qs-lb"
 location            = azurerm_resource_group.QSRG.location
 resource_group_name = azurerm_resource_group.QSRG.name

 frontend_ip_configuration {
   name                 = "PublicIPAddress"
   public_ip_address_id = azurerm_public_ip.qs_public_ip.id
 }

 tags = {
    environment = "QuantumSmart"
  }
}

resource "azurerm_lb_backend_address_pool" "qs_bpepool" {
 loadbalancer_id     = azurerm_lb.qs_lb.id
 name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "qs_probe" {
 ## resource_group_name = azurerm_resource_group.QSRG.name
 loadbalancer_id     = azurerm_lb.qs_lb.id
 name                = "ssh-running-probe"
 port                = 80
}

resource "azurerm_lb_rule" "qs_lbnatrule" {
   ##resource_group_name            = azurerm_resource_group.QSRG.name
   loadbalancer_id                = azurerm_lb.qs_lb.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = 80
   backend_port                   = 80
   ##backend_address_pool_id        = azurerm_lb_backend_address_pool.qs_bpepool.id
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.qs_probe.id
}

resource "azurerm_linux_virtual_machine_scale_set" "qs_vmss" {
 name                = "qsvmscaleset"
 location            = azurerm_resource_group.QSRG.location
 resource_group_name = azurerm_resource_group.QSRG.name
 sku                 = "Standard_B1ls"
 instances           = 2  
 admin_username       = "adminuser"
 admin_password       = "qs@1234$$$!!!"
 
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
    name    = "example"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.qs_public_subnet.id
    }
  }

}
