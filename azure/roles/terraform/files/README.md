# Overview

You can use this instruction to deploy virtual machines without creating POA network itself.

## Step 1: Prerequisites

All you need for this playbooks to work is to install Terraform and an Azure CLI.
Here is the list of docs that will lead you through the process of prerequisites installation:
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

## Step 3: Generate SSH keys

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.

To generate a new key run

```
ssh-keygen -t rsa -b 4096 -C "full-node"
```

Provide path to the key like `~/.ssh/id_poa-test` and no password.

In this case `~/.ssh/id_poa-test` will be your private key (`ssh_private_key_ansible`) and `~/.ssh/id_poa-test.pub` will be the public one (`ssh_public_key_ansible`).

## Step 4: Configure

Create file called `tf.tfvars` with the next content: 

```
network_name           = "<network name>"
environment_name       = "<env name>"
bootnode_count         = "<bootnode_count>"
bootnode_lb_count      = "<balanced_bootnode_count>"
validator_count        = "<validator_count>"
ssh_public_key         = "<path_to_ssh_public_key>"
region                 = "<region>"
resource_group_name    = "<if a resource group already exists, enter its name here. If you do not have a resource group ready, leave this variable empty - a resource group with the default name will be automatically created.>
admin_username         = "<ubuntu/centos/admin/poa or any other that will be used to connect to VMs that will be deployed by terraform>"
prefix                 = "<prefix_to_all_terraform_resources>"
```
Make sure to fill the file above with the actual parameters.

## Optional step (configure backend)

Regardless of the auth method chosen you will need to provide scripts with the storage account access key and a subscription ID if you want terraform to save its state to Azure blob storage by setting appropriate env variable:

```
export ARM_ACCESS_KEY = <access_key>
export ARM_SUBSCRIPTION_ID = <subscription ID>
```
You can get storage account key by creating a new resource at Azure called "Storage account" and visiting "Access keys" page inside of created resource.
Also create a file called `backend.tfvars` with the following content:

```
storage_account_name = "<storage_account_name>"
container_name       = "<container_name >"
key                  = "<filename_to_save_or_search>"
```

## Step 5: Deploy

To deploy your infra run

```
terraform init <backend_arg>
terraform plan
terraform apply
```
Replace <backend_arg> either with `-backend=false` if you want Terraform to store state file locally or `-backend-config=backend.tfvars` to provide terraform with configuration file filled at the previous step. 

## Clean up

When the infrastructure is no longer needed run

```
cd playbooks-terraform/azure/roles/terraform/files
yes | terraform destroy
```
