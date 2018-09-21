# Overview

This playbooks is designed for deployment automation of a clone of "POA Network".

Namely, the following operations are performed:

- random account is generated for Master of Ceremony (MoC)
  
- bytecode of the Network Consensus Contract is prepared

- based on these data, genesis json file is prepared

- Netstat node is started

- Several (configurable number) bootnodes are started, `bootnodes.txt` is exchanged between them

- Additionally, some more bootnodes can be started behind a Gateway, forming a publicly accessible RPC endpoint for the network. This endpoint is availble over `http`, but the user may later assign it a DNS name, generate valid ssl certificates and upload them to the Gateway config, turning this endpoint to `https`.

- Explorer node is started

- MoC's node is started

- Ceremony is performed on the MoC's node, i.e. other consensus contracts are deployed to the network

- Several (configurable number) initial keys are generated

- Subset (or all) of initial keys are converted into (mining + voting + payout) keys

- For a subset (or for all) of converted keys, validator nodes are started

- Simple tests can be run against the network: (1) check that txs are getting mined (2) check that all validators mine blocks (only makes sense if validator nodes were started for all mining keys)

- Artifacts (`spec.json`, `bootnodes.txt`, `contracts.json`, ...) are stored on the MoC's node

- `hosts` file is generated on the user's machine containing ip addresses of all nodes and their respective roles

Most of the work is done by `ansible`, but to bring up the infrastructure, ansible calls `terraform`.

# Usage

## Step 1: Install prerequisites

To run these scripts you need to install:
1. [Ansible >=2.6.3](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. [Terraform >=0.11.8](https://www.terraform.io/intro/getting-started/install.html)
4. `PIP msrestazure and ansible[azure] modules`(optional). You can install it using `pip install msrestazure && pip install ansible[azure]`. Required only if you need scripts to create a resource group or a storage account.

Alternatively, there's a [docker image](https://hub.docker.com/r/poanetwork/terraform-prep/) with pre-installed dependencies.

## Step 2: Authenticating with Azure

You can authenthicate terraform in Azure using your own account or via service principal. For your local deployments it will be better to authenthicate using your account since it relies on short-term tokens. For CI deployments Service Principals are the only way to authenthicate.

### Authenticating using azure cli + web browser

To authenthicate using CLI run
```bash
az login
```
and follow the instructions. You will have to open browser, login to your azure account and enter confirmation code. This authentication is valid for some limited time, so you may have to re-authenticate later.
Please, use this option only with [local backend storage](#backends).

### Authenticating using Service Principal

This method can be used to automate deployment process without the need to manually enter confirmation code every time.

You need to create Service Principal (SP) in Azure with sufficient permissions. [This instruction](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest) will provide you with the details. Do not forget to save the output into secure place.
After you've created a SP, it is best to create a separate Resource Group and add the SP as a contributor to that group. To do this
    * create new Resource Group
    * select Access Control (IAM) tab in the left sidebar
    * click "Add"
    * choose "Role" = Contributor", this should grant the SP sufficient rights to create all necessary resources
    * don't be surprised that SP won't be visible in the list of available users - Azure doesn't display SPs there, you should start typing SP's name in the "select" field above and it's name will appear in the list
    * save

Set the necessary env variables using SP's authenticating data
```bash
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
To get your subscription id open [Azure portal](https://portal.azure.com) and search for `subscriptions` panel. For this example our subscription id will be `1xx2x3x4-x5xx-6x7x-xx89-0x1xx23xx456`. To get the appropriate access we will need to set the variables as following:
```bash
export ARM_CLIENT_ID = x123xx45-x6x7-8x9x-0x1x-123x456xx78x
export ARM_CLIENT_SECRET = 1x2345xx-678x-9x0x-1234-x5xx6xxxx789
export ARM_TENANT_ID = 01234xx5-6789-0x12-34xx-5x6789x0x1x2
export ARM_SUBSCRIPTION_ID = 1xx2x3x4-x5xx-6x7x-xx89-0x1xx23xx456
export ANSIBLE_AZURE_AUTH_SOURCE = env
```


## Step 3: Playbook configuration

Configuration options are stored in `group_vars/all.yml`. An example is given in `group_vars/all.yml.example` so you need to copy it and use a template
```bash
cd azure
cp group_vars/all.yml.example group_vars/all.yml
```

Notes about some configuration parameters:

* `SPEC_ADDRESS` - by default, ansible generates genesis json file based on the following template: `roles/moc-preconf/templates/spec.json.j2`. If you want to adjust parameters of the genesis, you should create your own copy of that template and update it `cp roles/moc-preconf/templates/spec.json.j2 my-spec.json.j2`. For example, to change block time, you can update value in `engine.authorityRound.params.stepDuration`. Then you should set `SPEC_ADDRESS: my-spec.json.j2`. You should NOT change values enclosed in double curly brackets `"{{ ... }}"`, since they are automatically filled by ansible.

* `bootnode_balanced_count` - this is number of ADDITIONAL bootnodes that will be put into rpc endpoint. So the total number of bootnodes is `bootnode_count+bootnode_balanced_count`.

* `initial_key_count` - number of initial keys generated by MoC during ceremony. Max = 12
* `initial_key_convert_count` - number of (mining + voting + payout) keys generated from the initial keys. Should be `<= initial_key_count`

* `validator_count` - number of validator nodes to run. Should be `<= initial_key_convert_count`.

* `terraform_location` - path to the `terraform` binary. Default value is for typical linux installation. To find correct path on your system, run `which terraform`.

* `PUB_KEY_STORE` - path to your public key. This key will be copied to all created nodes of the network

* `resource_group_name` - the value of this variable represents the name of the Azure resource group where deployment should be located. If group with this name already exists - scripts will not recreate it, nor delete any resources inside. If variable is empty or not set, resource group will be created with the default name following the next template: `{{ NETWORK_NAME }}rg`, where `{{ NETWORK_NAME }}` is the `NETWORK_NAME` variable set at the config file.

* `ansible_user` - this is the user to connect to the nodes with.
  
* `ansible_python_interpreter`, `ansible_pip` - same as for `terraform_location`, default values are for Linux, use `which` to find correct paths on your system.

* `backend` - deployment-terraform scripts support both local and remote state storage. While `backend: false` will keep the state locally, `backend: true` will automatically create a storage account at Azure and safe terraform state to the blob inside it. It is a best practice to keep backend remotely, since it is much more safer.

It is also possible to use `group_vars/all.yml` to overwrite options used by ansible playbooks during nodes deployment. For example, if you want to use custom parity binary, you should add the following two configuration parameters to `group_vars/all.yml`:
```yaml
PARITY_BIN_LOC: "https://..."
PARITY_BIN_SHA256: "..."
```

Another example - change gas limit - you need to use custom spec json file (see above) and set hex value `genesis.gasLimit = "0x..."`, after that additionally set option for ansible playbooks in `group_vars/all.yml`
```yaml
BLK_GAS_LIMIT: "9000000" # decimal here !
```

## Step 4: Generate SSH keys

We recommend using a separate key for ansible deployment. To generate a new key run `ssh-keygen -t rsa -b 4096 -C "full-node"`
You should explicitly specify path to your public SSH key. Ansible script will put it on all the virtual machines in a deployment. Also, do not forget to specify private ssh key while calling Ansible scripts via `--key-file`, otherwise the default SSH key of your system will be used.

## Step 5: Deploy

To deploy your POA network run `ansible-playbook site.yml --key-file <key_name>`
After deployment, script will create a file called `hosts` with the list of created resources.

```
ansible-playbook site.yml --key-file <key_name>
```
Deployment process may take more than 1 hour, depending on the number of nodes and Azure performance. After deployment, the script will create a file called `hosts` inside the `outputs/<network_name>` folder with the list of created resources.

# Clean up

When the infrastructure is no longer needed run `ansible-playbook destroy.yml -i <hosts_file>`

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
`pub_key` - plain text SSH public key. Make sure to set this option properly or you might not be able to reach your deployment via SSH.
Also you will need to specify private part of your SSH key at SSH permissions page of CircleCI project configuration

## Optional variables

`build_attr`
`tests_attr`
`destroy_attr`

Those variables appends to the script execution line (corresponding to the job of the workflow). These variables are optional, however in some cases they may be useful. For example, you may want to specify extra variables or a tag:
`-e "backend=true" -e "NETWORK_NAME=PoANet" -t deploy` 
