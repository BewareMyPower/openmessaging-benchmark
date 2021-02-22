terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.45.1"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {}
variable "location" {}
variable "broker_instances" {}
variable "broker_vm_size" {}
variable "tags" {}

variable "prefix" {
  type = string
  default = "kop"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}NetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "ip" {
  count               = 3
  name                = "${var.prefix}IP-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

# NIC connects your VM to a given virtual network, public ip, and network security group
resource "azurerm_network_interface" "nic" {
  count               = length(azurerm_public_ip.ip)
  name                = "${var.prefix}NIC-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
 
  ip_configuration {
    name                          = "${var.prefix}NicConfiguration-${count.index}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip[count.index].id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "association" {
  count                     = length(azurerm_network_interface.nic)
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create a storage account to store boot diagnostics for a VM.
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "${var.prefix}diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                      = var.tags
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key" { value = tls_private_key.ssh_key.private_key_pem }

resource "azurerm_linux_virtual_machine" "broker" {
  count                 = length(var.broker_instances)
  name                  = element(var.broker_instances, count.index)
  resource_group_name   = azurerm_resource_group.rg.name 
  location              = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.broker_vm_size
  tags                  = var.tags

  os_disk {
    name                 = "${var.prefix}OsDisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "${var.prefix}-broker-${count.index}"
  admin_username = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
