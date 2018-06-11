output "bootnode-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.bootnode-ips}"
}

output "explorer-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.explorer-ips}"
}

output "moc-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.moc-ips}"
}

output "netstat-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.netstat-ips}"
}

output "validator-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.poa.validator-ips}"
}
