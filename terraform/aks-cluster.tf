provider "azurerm" {
  version = "~> 2.0"
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "unconference"
  location = "North Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "unconference-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "aks-subnet" {
  name                 = "unconference-aks-subnet"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "unconference-k8s"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "unconference-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D8s_v3"
    os_disk_size_gb = 30
    vnet_subnet_id  = azurerm_subnet.aks-subnet.id
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }
  
  network_profile {
    network_plugin  = "kubenet"
    load_balancer_sku = "Basic"
  }
}
