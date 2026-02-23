# 1. Groupe de Ressources
resource "azurerm_resource_group" "tp_rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
}

# 2. Réseau Virtuel (VNET)
resource "azurerm_virtual_network" "tp_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name

  tags = {
    environment = "tp"
  }
}

# 3. Sous-réseau (Subnet)
resource "azurerm_subnet" "tp_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.tp_rg.name
  virtual_network_name = azurerm_virtual_network.tp_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3.1 — Sécurité : Network Security Group (NSG) pour ouvrir le port 80
resource "azurerm_network_security_group" "tp_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Liaison du NSG au Subnet
resource "azurerm_subnet_network_security_group_association" "tp_nsg_assoc" {
  subnet_id                 = azurerm_subnet.tp_subnet.id
  network_security_group_id = azurerm_network_security_group.tp_nsg.id
}

# 4.1 — Interfaces réseau (NIC)
resource "azurerm_network_interface" "vm_nic" {
  count               = 2
  name                = "${var.prefix}-nic-${count.index + 1}"
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tp_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 4.2 — Machines Virtuelles Linux
resource "azurerm_linux_virtual_machine" "tp_vm" {
  count               = 2
  name                = "${var.prefix}-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.tp_rg.name
  location            = azurerm_resource_group.tp_rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(<<-EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "<h1>Hello from ${var.prefix}-vm-${count.index + 1}</h1>" > /var/www/html/index.html
systemctl start nginx
systemctl enable nginx
EOF
  )

  os_disk {
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
}

# 5.1 — IP Publique pour le Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.prefix}-lb-pip"
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5.2 — Le Load Balancer
resource "azurerm_lb" "tp_lb" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# 5.3 — Backend Address Pool
resource "azurerm_lb_backend_address_pool" "tp_backend_pool" {
  loadbalancer_id = azurerm_lb.tp_lb.id
  name            = "${var.prefix}-backend-pool"
}

# 5.4 — Association des NICs au Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "nic_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tp_backend_pool.id
}

# 5.5 — Health Probe
resource "azurerm_lb_probe" "tp_probe" {
  loadbalancer_id = azurerm_lb.tp_lb.id
  name            = "${var.prefix}-http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# 5.6 — Load Balancing Rule
resource "azurerm_lb_rule" "tp_lb_rule" {
  loadbalancer_id                = azurerm_lb.tp_lb.id
  name                           = "${var.prefix}-http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.tp_backend_pool.id]
  probe_id                       = azurerm_lb_probe.tp_probe.id
}