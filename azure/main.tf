# Configure the Azure Provider
# To recieve token run `az login` from console
provider "azurerm" {
  version = "1.6.0"
}

module "poa" {
  source = "./poanetwork"
}
