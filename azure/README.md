## Authenticating with Azure

Terraform does not authenticate with Azure directly. Instead, it uses Azure CLI
authentication when you run it locally.

```
az login
```

Verify you have access to the account

```
az account list
```

## Configure

Adjust all settings before running the deployment.

```
cd playbooks-terraform/azure
cp group_vars/all.yml.example group_vars/all.yml
```

Edit the `all.yml` file to set up node parameters.

## Generate SSH keys

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.

To generate a new key

```
ssh-keygen -t rsa -b 4096 -C "full-node"
```

Provide path to the key like `~/.ssh/id_poa-test` and no password.

In this case `~/.ssh/id_poa-test` will be your private key (`ssh_private_key_ansible`) and `~/.ssh/id_poa-test.pub` will be the public one (`ssh_public_key_ansible`).

## Deploy

To deploy your POA network run
```
ansible-playbook site.yml --key-file <key_name>.pub
```

## Clean up

When the infrastructure is no longer needed run

```
cd poanetwork
yes | terraform destroy
```

This will delete created resources from your account.

## Managing multiple deployments

In case you want to deploy several environments use separate configuration files (all.yml).