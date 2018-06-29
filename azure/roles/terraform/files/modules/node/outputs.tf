output "ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${azurerm_public_ip.node.*.ip_address}"
}
