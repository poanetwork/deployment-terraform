# Overview

You can use this instruction to deploy azure application gateway that will be acting like an load balancer over specified nodes.

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

## Step 3: Generate certificates

To deal with Azure GW you will need two certificates - .pfx to present to the end user and .crt, that will be used by GW to access nodes.
We can generate CRT file using 

```
openssl genrsa -aes128 -passout pass:<password> -out gw.key 2048
openssl req -new -passin pass:<password> -key gw.key -out gw.csr
openssl x509 -req -days 36500 -in gw.csr -signkey gw.key -out gw.crt
```
CRT can be converted to PFX by:
```
openssl pkcs12 -export -inkey gw.key -in gw.crt -out gw.pfx -passin pass:<password> -passout pass:<password>
```
However, we recommend to use certificates that are signed by well-known certification authority.

## Step 4: Configure

Create file called `tf.tfvars` with the next content: 

```
ssl_cert               = "<path to the .pfx certificate that will be used by balancer itself>"
nodes_cert             = "<path to the .crt certificate that will be used by balancer to access nodes"
region                 = "<deployment region>"
resource_group_name    = "<resource_group_name>"
virtual_network        = "<name of virtual network that will be used by balancer>"
prefix                 = "<prefix that will be used in the name of the balancer>"
password               = "<password for the .pfx certificate (required)>"
```
Make sure to fill the file above with the actual parameters.

## Optional step (configure backend)

Regardless of the auth method chosen you will need to provide scripts with the storage account access key if you want terraform to save its state to Azure blob storage by setting appropriate env variable:

```
export ARM_ACCESS_KEY = <access_key>
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
cd playbooks-terraform/azure/roles/balancer/files
yes | terraform destroy
```