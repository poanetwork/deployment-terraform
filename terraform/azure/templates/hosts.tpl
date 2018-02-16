[bootnode:vars]
ansible_ssh_private_key_file=~/.ssh/id_poa-test
ansible_user=poa

[bootnode]
bootnode/0 ansible_host=${node_address}
