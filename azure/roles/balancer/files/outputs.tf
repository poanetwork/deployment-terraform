output "ips" {
  description = "Public IP address of the Azure app gateway"
  value       = "${azurerm_public_ip.node.ip_address}"
}
