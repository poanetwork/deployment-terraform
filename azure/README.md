# Overview

This playbooks is designed for deployment automation of a clone of "POA Network".

Namely, the following operations are performed:
    - random account is generated for Master of Ceremony (MoC)
    - bytecode of the Network Consensus Contract is prepared
    - based on these data, genesis json file is prepared
    - Netstat node is started
    - Several (configurable number) bootnodes are started, `bootnodes.txt` is exchanged between them
    - Additionally, some more bootnodes can be started behind a Gateway, forming a publicly accessible RPC endpoint for the network. This endpoint is availble over `http:`, but the user may later assign it a DNS name, generate valid ssl certificates and upload them to the Gateway config, turning this endpoint to `https:`.
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

Alternatively, there's a [docker image](https://hub.docker.com/r/poanetwork/terraform-prep/) with pre-installed dependencies.

## Step 2: Authenticating with Azure

There are two ways to authenticate these scripts with azure: using (azure cli + web browser) or using service principal.

### Authenticating using (azure cli + web browser)

Run
```bash
az login
```
and follow the instructions. You will have to open browser, login to your azure account and enter confirmation code. This authentication is valid for some limited time, so you may have to re-authenticate later.

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
export ARM_CLIENT_ID="appId"
export ARM_CLIENT_SECRET="password"
export ARM_TENANT_ID="tenant"
```

## Step 3: Playbook configuration

Configuration options are stored in `group_vars/all.yml`. An example is given in `group_vars/all.yml.example` so you need to copy it and use a template
```
cd azure
cp group_vars/all.yml.example group_vars/all.yml
```

Notes about some configuration parameters:
    * `SPEC_ADDRESS` - by default, ansible generates genesis json file based on the following template: `roles/moc-preconf/templates/spec.json.j2`. If you want to adjust parameters of the genesis, you should create your own copy of that template and update it `cp roles/moc-preconf/templates/spec.json.j2 my-spec.json.j2`. For example, to change block time, you can update value in `engine.authorityRound.params.stepDuration`. Then you should set `SPEC_ADDRESS: my-spec.json.j2`. You should NOT change values enclosed in double curly brackets `"{{ ... }}"`, since they are automatically filled by ansible
    * `bootnode_balanced_count` - this is number of ADDITIONAL bootnodes that will be put into rpc endpoint. So the total number of bootnodes is `bootnode_count+bootnode_balanced_count`
    * `initial_key_count` - number of initial keys generated by MoC during ceremony. Max = 12
    * `initial_key_convert_count` - number of (mining + voting + payout) keys generated from the initial keys. Should be `<= initial_key_count`
    * `validator_count` - number of validator nodes to run. Should be `<= initial_key_convert_count`
    * `terraform_location` - path to the `terraform` binary. Default value is for typical linux installation. To find correct path on your system, run `which terraform`
    * `PUB_KEY_STORE` - path to your public key. This key will be copied to all created nodes of the network
    * `prepare_resource_group`, `resource_group_name` - if you generated resource group manually as described above, you should set `prepare_resource_group: false` and uncomment `resource_group_name: "RESOURCE GROUP NAME"`
    * `ansible_user` - this is the user to connect to the nodes with
    * `ansible_python_interpreter`, `ansible_pip` - same as for `terraform_location`, default values are for Linux, use `which` to find correct paths on your system

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

We recommend using a separate key for ansible deployment. Terraform also puts your personal key `ssh_public_key` on the machine.
To generate a new key run

```
ssh-keygen -t rsa -b 4096 -C "full-node"
```

## Optional step (configure backend)

Regardless of the auth method chosen you will need to provide scripts with the storage account access key and a subscription ID if you want terraform to save its state to Azure blob storage by setting appropriate env variable:

```
export ARM_ACCESS_KEY = <access_key>
export ARM_SUBSCRIPTION_ID = <subscription ID>
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
Deployment process may take more than 1 hour, depending on the number of nodes and Azure performance. After deployment, the script will create a file called `host` with the list of created resources.

To make remote backend switch properly `-e backend=true` ansible-playbook CLI option is necessary.

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
