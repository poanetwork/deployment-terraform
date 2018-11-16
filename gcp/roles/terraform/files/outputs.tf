output "bootnode-ips" {
  description = "Public IP address of the bootnode"
  value       = "${module.bootnode.ips}"
}

output "bootnode-lb-ips" {
  description = "Public IP address of the balanced bootnode"
  value       = "${module.bootnode.lb_ips}"
}

output "explorer-ips" {
  description = "Public IP address of the explorer node"
  value       = "${module.explorer.ips}"
}

output "moc-ips" {
  description = "Public IP address of the master of ceremony"
  value       = "${module.moc.ips}"
}

output "netstat-ips" {
  description = "Public IP address of the netstat"
  value       = "${module.netstat.ips}"
}

output "validator-ips" {
  description = "Public IP address of the validator node"
  value       = "${module.validator.ips}"
}