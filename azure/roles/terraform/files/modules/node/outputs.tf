output "ips" {
  description = "Public IP address of the virtual machine"
  value       = ["${var.node_count * length(azurerm_public_ip.node.*.ip_address) > 0 ? join(",\n", slice( azurerm_public_ip.node.*.ip_address, 0, (var.node_count > length(azurerm_public_ip.node.*.ip_address) ? length(azurerm_public_ip.node.*.ip_address) : var.node_count ))) : ""}"]
}

output "lb_ips" {
  description = "Public IP address of the balanced virtual machine"
  value       = ["${var.lb_node_count * length(azurerm_public_ip.node.*.ip_address) > 0 ? join(",\n", slice(azurerm_public_ip.node.*.ip_address, (var.node_count > length(azurerm_public_ip.node.*.ip_address) ? length(azurerm_public_ip.node.*.ip_address) : var.node_count ), ((var.node_count+var.lb_node_count) > length(azurerm_public_ip.node.*.ip_address) ? length(azurerm_public_ip.node.*.ip_address) : var.node_count+var.lb_node_count ) )) : ""}"]
}