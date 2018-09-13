# Configure the Azure Provider
provider "azurerm" {
  version = "1.6.0"
}

# Create virtual network
resource "azurerm_virtual_network" "poa" {
  name                = "${var.prefix}${var.network_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    environment = "${var.environment_name}"
  }
}

# Create subnet
resource "azurerm_subnet" "poa" {
  name                 = "${var.prefix}${var.network_name}-subnet"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${azurerm_virtual_network.poa.name}"
  address_prefix       = "10.0.1.0/24"
}

module "bootnode" {
  source = "./modules/node"

  resource_group_name = "${var.resource_group_name}"
  
  network_name   = "${var.network_name}"
  subnet_id      = "${azurerm_subnet.poa.id}"
  node_count     = "${var.bootnode_count}"
  lb_node_count  = "${var.bootnode_lb_count}"
  region         = "${var.region}"
  
  platform       = "ubuntu"
  role           = "bootnode"
  ssh_public_key = "${var.ssh_public_key}"  
  prefix         = "${var.prefix}"  
  
  admin_username = "${var.admin_username}"
}

module "explorer" {
  source = "./modules/node"

  resource_group_name = "${var.resource_group_name}"

  network_name = "${var.network_name}"
  subnet_id    = "${azurerm_subnet.poa.id}"
  node_count   = 1
  region       = "${var.region}"  

  platform       = "ubuntu"
  role           = "explorer"
  ssh_public_key = "${var.ssh_public_key}"
  prefix         = "${var.prefix}"
    
  admin_username = "${var.admin_username}"
}

module "moc" {
  source = "./modules/node"

  resource_group_name = "${var.resource_group_name}"

  network_name = "${var.network_name}"
  subnet_id    = "${azurerm_subnet.poa.id}"
  node_count   = 1
  region       = "${var.region}" 
  
  platform       = "ubuntu"
  role           = "moc"  
  ssh_public_key = "${var.ssh_public_key}"
  prefix         = "${var.prefix}"
    
  admin_username = "${var.admin_username}"
}

module "netstat" {
  source = "./modules/node"

  resource_group_name = "${var.resource_group_name}"

  network_name = "${var.network_name}"
  subnet_id    = "${azurerm_subnet.poa.id}"
  node_count   = 1
  region       = "${var.region}" 

  platform       = "ubuntu"
  role           = "netstat"  
  ssh_public_key = "${var.ssh_public_key}"
  prefix         = "${var.prefix}"
    
  admin_username = "${var.admin_username}"
}

module "validator" {
  source = "./modules/node"

  resource_group_name = "${var.resource_group_name}"

  network_name = "${var.network_name}"
  subnet_id    = "${azurerm_subnet.poa.id}"
  node_count   = "${var.validator_count}"
  region       = "${var.region}" 
  
  platform       = "ubuntu"
  role           = "validator"  
  ssh_public_key = "${var.ssh_public_key}"
  prefix         = "${var.prefix}"
    
  admin_username = "${var.admin_username}"
}
