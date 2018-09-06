# Overview

This playbooks is designed for purposes of POA Network deployment automation. It uses both Ansible and Terraform to drastically decrease time to deploy new POA Network. To deploy a new network follow the described procedure.

## Step 1: Prerequisites

All you need for this playbooks to work is to install Ansible itself, Terraform and an Azure CLI.
Here is the list of docs that will lead you through the process of prerequisites installation:
1. [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. [Terraform](https://www.terraform.io/intro/getting-started/install.html)
4. `PIP msrestazure and ansible[azure] modules`(optional). You can install it using `pip install msrestazure && pip install ansible[azure]`. Required only if you need scripts to create a resource group or a storage account.

Also, you can get our latest docker image with preinstalled software [here](https://hub.docker.com/r/poanetwork/terraform-prep/).

## Step 2: Authenticating with Azure

You can authenthicate terraform in Azure using your own account or via service principal. For your local deployments it will be better to authenthicate using your account since it relies on short-term tokens. For CI deployments Service Principals are the only way to authenthicate.

### Authenthicating using your account

To authenthicate using your own account use `az login` shell command. Follow the instructions on screen. It is better to use this option only with [local backend storage](#backends).

### Authenthicating using Service Principal

First, you will need to create a Service Principal with sufficient permissions. [This instruction](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) will provide you with the most modern way of creating a principal. Do not forget to save the output into secure place.
Then set the necessary environment variables:

```
export ARM_CLIENT_ID = <appId>
export ARM_CLIENT_SECRET = <password>
export ARM_TENANT_ID = <tenant>
export ARM_SUBSCRIPTION_ID = <subscription>
export ANSIBLE_AZURE_AUTH_SOURCE = env
``` 
#### Example

After creating Service Principal you will get an output in the following format:
```
{
    "appId": "x123xx45-x6x7-8x9x-0x1x-123x456xx78x",
    "displayName": "service_account",
    "name": "http://service_account",
    "password": "1x2345xx-678x-9x0x-1234-x5xx6xxxx789",
    "tenant": "01234xx5-6789-0x12-34xx-5x6789x0x1x2"
}
```
Also you will need to get your subscription id. To do this - open portal.azure.com and search for `subscriptions` panel. For this example our subscription id will be `1xx2x3x4-x5xx-6x7x-xx89-0x1xx23xx456`. To get the appropriate access we will need to set the variables as following:
```
export ARM_CLIENT_ID = x123xx45-x6x7-8x9x-0x1x-123x456xx78x
export ARM_CLIENT_SECRET = 1x2345xx-678x-9x0x-1234-x5xx6xxxx789
export ARM_TENANT_ID = 01234xx5-6789-0x12-34xx-5x6789x0x1x2
export ARM_SUBSCRIPTION_ID = 1xx2x3x4-x5xx-6x7x-xx89-0x1xx23xx456
export ANSIBLE_AZURE_AUTH_SOURCE = env
```

## Step 3: Configure

Adjust all settings before running the deployment. First of all - copy example config file to the same folder and name it like `all.yml`: : 

```..
cd playbooks-terraform/azure
cp group_vars/all.yml.example group_vars/all.yml
```

Edit `all.yml` file to set up all the actual parameters.

### Backends

This scripts support both local and remote state storage. To switch between them change the `backend` variable at `all.yml`. While `backend: false` will keep the state locally, `backend: true` will automatically create a storage account at Azure and safe terraform state to the blob inside it. It is a best practice to keep backend remotely, since it is much more safer.

### Resource groups

Optionally, you may want to create a resource group yourself, or deploy to an existent group. To do this set `prepare_resource_group: false` and `resource_group_name: <your_RG_name>` at `all.yml`. Otherwise set `resource_group_name` only. Scripts will automatically create a resource group. 

## Step 4: SSH keys

We recommend using a separate key for ansible deployment. To generate a new key run `ssh-keygen -t rsa -b 4096 -C "full-node"`
You should explicitly specify path to your public SSH key. Ansible script will put it on all the virtual machines in a deployment. Also, do not forget to specify private ssh key while calling Ansible scripts via `--key-file`, otherwise the default SSH key of your system will be used.

## Step 5: Deploy

To deploy your POA network run `ansible-playbook site.yml --key-file <key_name>`
After deployment, script will create a file called `hosts` with the list of created resources.

# Clean up

When the infrastructure is no longer needed run `ansible-playbook destroy.yml`

# Managing multiple deployments

In case you want to deploy several environments use separate configuration files (`all.yml`).

# Deploying infrastructure separately

If you want to deploy an infrastructure for network without creating network itself you can refer to those READMEs: [building nodes](roles/terraform/files/README.md), [bringing up a balancer](roles/balancer/files/README.md), [using remote state](roles/storage-account/README.md) and [creating resource group](roles/resource-group/README.md) 

# Continous Integration

You may want to setup a continous integration. This repository contains [.circleci/config.yml](../.circleci/config.yml) file with a designed workflow for a [CircleCI](https://circleci.com). To make everything work properly you will need to setup environment variables. Some of them is required and the others are optional.

## Azure authenthication 
There is the only way of proper authenthicating for CI - using service principal. All the variables and examples for its usage are described at the [corresponding part of this README](#authenthicating-using-service-principal).

## Configs

Besides the azure authenthication variables CI requires config and a public SSH key to be set:
`config_file` - base64 encoded version of `group_vars/all.yml` file
`pub_key` - plain text SSH public key
`

## VMs authenthication

`pub_key`	- your public key in the plain text format
Also you will need to specify private part of your SSH key at SSH permissions page of CircleCI project configuration

## Optional variables

`build_attr`
`tests_attr`
`destroy_attr`

Those variables appends to the script execution line (corresponding to the job of the workflow). These variables are optional, however in some cases they may be useful. For example, you may want to specify extra variables or a tag:
`-e "backend=true" -e "NETWORK_NAME=PoANet" -t deploy` 
