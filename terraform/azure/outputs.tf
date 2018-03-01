output "bootnode-ip" {
  value = "${module.poa.boot_node_ip}"
}

output "netstat-ip" {
  value = "${module.poa.netstat_node_ip}"
}
