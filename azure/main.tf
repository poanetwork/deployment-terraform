# Configure the Azure Provider
# To recieve token run `az login` from console
provider "azurerm" {
  version = "1.1.2"
}

module "poa" {
  source = "./poanetwork"
}
