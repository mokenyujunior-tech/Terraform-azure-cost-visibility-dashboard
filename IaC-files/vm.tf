resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---- Networking --------------------------------------------
resource "azurerm_virtual_network" "vm" {
  name                = "vnet-cvd-${random_string.suffix.result}"
  address_space       = ["10.50.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(var.tags, {
    costcategory = "Networking"
  })
}

resource "azurerm_subnet" "vm" {
  name                 = "snet-cvd-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-cvd-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, {
    costcategory = "Networking"
  })
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-cvd-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # SSH locked to a single source IP. If your ISP rotates your
  # public IP, update var.ssh_allowed_source_ip and re-apply.
  security_rule {
    name                       = "AllowSSHFromOwner"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.ssh_allowed_source_ip}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenySSHFromInternet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, {
    costcategory = "Networking"
  })
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-cvd-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = merge(var.tags, {
    costcategory = "Networking"
  })
}

# ---- The VM itself -----------------------------------------
resource "azurerm_linux_virtual_machine" "lab" {
  name                            = "vm-cvd-lab-${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh.public_key_openssh
  }

  os_disk {
    name                 = "osdisk-cvd-vm-${random_string.suffix.result}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Disable boot diagnostics to avoid creating an extra storage
  # account just for boot logs. We don't need them for a lab VM.
  boot_diagnostics {
    storage_account_uri = null
  }

  tags = merge(var.tags, {
    costcategory = "Servers"
  })
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "lab" {
  virtual_machine_id    = azurerm_linux_virtual_machine.lab.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = "2000"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled = false
  }

  tags = merge(var.tags, {
    costcategory = "Automation"
  })
}