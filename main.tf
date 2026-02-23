
# 1. Création du Groupe de Ressources
resource "azurerm_resource_group" "tp_rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
}

# 2. Création du Réseau Virtuel (VNET)
resource "azurerm_virtual_network" "tp_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tp_rg.location
  resource_group_name = azurerm_resource_group.tp_rg.name

  tags = {
    environment = "tp"
  }
}

# 3. Création du Sous-réseau (Subnet)
resource "azurerm_subnet" "tp_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.tp_rg.name
  virtual_network_name = azurerm_virtual_network.tp_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
