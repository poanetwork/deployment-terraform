# Overview

You can use this instruction to deploy virtual machines without creating POA network itself.

## Step 1: Prerequisites

All you need for this playbooks to work is to install Terraform and an Azure CLI.
Here is the list of docs that will lead you through the process of prerequisites installation:
1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
2. [Terraform](https://www.terraform.io/intro/getting-started/install.html)

Also, you can get our latest docker image with preinstalled software [here](https://hub.docker.com/r/poanetwork/terraform-prep/).

## Step 2: Authenticating with Azure

You can authenthicate using your own account or via service principal.  

### Authenthicating using Azure CLI

To authenthicate using your own account use `az login` shell command. Follow the instructions on screen.

### Authenthicating using Service Principal

First, you will need to create a Service Principal with sufficient permissions. [This instruction](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) will provide you with the most modern way of creating a principal. Do not forget to save the output into secure place.
Then set the necessary environment variables:

```
export ARM_CLIENT_ID = <appId>
export ARM_CLIENT_SECRET = <password>
export ARM_TENANT_ID = <tenant>
export ARM_SUBSCRIPTION_ID = <subscription>
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
```


## Step 3: Generate SSH keys

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.

To generate a new key run `ssh-keygen -t rsa -b 4096 -C "full-node"`

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
resource_group_name    = <RG_name>
admin_username         = "<ubuntu, centos, admin, poa, etc.>"
prefix                 = "<prefix_to_all_terraform_resources>"
```
Make sure to fill the file above with the actual parameters.

## Optional step (configure backend)

If you want terraform to save its state to Azure blob storage you should also create two files called `backend.tfvars` and `remote-backend-selector.tf`. Specify the content of the files as following.

### backend.tfvars

```
storage_account_name = "<storage_account_name>"
container_name       = "<container_name >"
key                  = "<filename_to_save_or_search>"
```

### remote-backend-selector.tf

```
terraform {
    backend "azurerm" { resource_group_name="<RG_name>" }
}  

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
