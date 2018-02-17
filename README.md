# Deployment Automation

This repository contains Terraform scripts to automate `full node` deployment to
Azure and AWS cloud providers.

## Installing Terraform

Assuming you are on macOS and have Homebrew installed.

```
brew install terraform
terraform version
> Terraform v0.11.3
```

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

Start from configuration example:

```
cd terraform/azure
mv terraform.tfvars.example terraform.tfvars
```

Edit the `terraform.tfvars` file to set up node parameters.

## Generate SSH keys

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.

To generate a new key

```
ssh-keygen -t rsa -b 4096 -C "full-node"
```

Provide path to the key like `~/.ssh/id_poa-test` and no password.

In this case `~/.ssh/id_poa-test` will be your private key (`ssh_private_key_ansible`) and `~/.ssh/id_poa-test.pub` will be the public one (`ssh_public_key_ansible`).

## Deploy

Download Azure Terraform plugin

```
terraform init
```

Show the resources scheduled for creation

```
terraform plan
```

Create the resources

```
terraform apply
```

## Clean up

When the infrastructure is no longer needed run

```
terraform destroy
```

This will delete created resources from your account.

## Managing multiple deployments

In case you want to deploy several environments use separate state files. By default Terraform saves state to the file `terraform.tfstate`. You can change this behaviour with option `-state=path`. To manage multiple deployments use different pathes for the state files.

Example:

```
terraform apply -state=prod.tfstate
terraform apply -state=dev.tfstate
```
