output "bootnode-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.bootnode.ips}"
}

output "bootnode-lb-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.bootnode.lb_ips}"
}

output "explorer-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.explorer.ips}"
}

output "moc-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.moc.ips}"
}

output "netstat-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.netstat.ips}"
}

output "validator-ips" {
  description = "Public IP address of the validator virtual machine"
  value       = "${module.validator.ips}"
}