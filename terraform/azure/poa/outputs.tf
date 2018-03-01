output "boot_node_ip" {
  value = "${module.bootnode.ip}"
}

output "netstat_node_ip" {
  value = "${module.netstat.ip}"
}
