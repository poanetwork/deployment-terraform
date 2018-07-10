# Overview

This playbooks is designed for purposes of POA Network deployment automation. It uses both Ansible and Terraform to drastically decrease time to deploy new POA Network. To deploy a new network follow the described procedure.

## Step 1: Prerequisites

All you need for this playbooks to work is to install Ansible itself, Terraform and an Azure CLI.
Here is the list of docs that will lead you through the process of prerequisites installation:
1. [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. [Terraform](https://www.terraform.io/intro/getting-started/install.html)

## Step 2: Authenticating with Azure

You can authenthicate using your own account or via service principal.

### Authenthicating using Azure CLI

To authenthicate using your own account use `az login` shell command. 

### Authenthicating using Service Principal

First, you will need to create a Service Principal with sufficient permissions. [This instruction](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) will provide you with the most modern way of creating a principal. Do not forget to save the output into secure place.
Then set the necessary env variables:

```
export ARM_CLIENT_ID = <appId>
export ARM_CLIENT_SECRET = <password>
export ARM_TENANT_ID = <tenant>
```

## Step 3: Configure

Adjust all settings before running the deployment. First of all - copy example config file to the same folder and name it like `all.yml`: 

```
cd playbooks-terraform/azure
cp group_vars/all.yml.example group_vars/all.yml
```

Edit the `all.yml` file to set up all the actual parameters.

## Step 4: Generate SSH keys

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.
To generate a new key run

```
ssh-keygen -t rsa -b 4096 -C "full-node"
```

## Optional step (configure backend)

Regardless of the auth method chosen you will need to provide scripts with the storage account access key if you want terraform to save its state to Azure blob storage by setting appropriate env variable:

```
export ARM_ACCESS_KEY = <access_key>
```
You can get storage account key by creating a new resource at Azure called "Storage account" and visiting "Access keys" page inside of created resource.
Also, you need to add the following line to your `all.yml` file to configure Terraform remote state backend properly:
```
storage_account: "<account_name>"
container: "<container_name>"
```
Make sure to fill <> variables with the correct values.

## Step 5: Deploy

To deploy your POA network run

```
ansible-playbook site.yml --key-file <key_name>
```
After deployment script will create a file called `host` with the list of created resources.

# Clean up

When the infrastructure is no longer needed run

```
cd playbooks-terraform/azure/roles/balancer/files
yes | terraform destroy
cd playbooks-terraform/azure/roles/terraform/files
yes | terraform destroy
```

This will delete created resources from your account. While creating infrastructure script uses two separate terraform state files, so it should be destroyed in the correct order described abode.

# Managing multiple deployments

In case you want to deploy several environments use separate configuration files (all.yml).

# Deploying infrastructure separately

If you want to deploy an infrastructure for network without creating network itself you can refer to those READMEs: [building nodes](roles/terraform/files/README.md) and [bringing up a balancer](roles/balancer/files/README.md).