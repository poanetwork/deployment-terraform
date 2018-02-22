[all:vars]
ansible_ssh_private_key_file=${private_key}
ansible_user=poa

[bootnode]
bootnode/0 ansible_host=${node_address}

[explorer]
explorer/0 ansible_host=${explorer_address}
