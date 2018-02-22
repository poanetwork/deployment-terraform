[all:vars]
ansible_ssh_private_key_file=${private_key}
ansible_user=poa

[bootnode]
bootnode/0 ansible_host=${node_address}

[moc]
moc/0 ansible_host=${moc_address}
