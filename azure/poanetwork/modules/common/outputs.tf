output "resource_group_name" {
  description = "Name of the created resource group"
  value       = "${azurerm_resource_group.poa.name}"
}

output "subnet_id" {
  description = "Subnet ID"
  value       = "${azurerm_subnet.poa.id}"
}
