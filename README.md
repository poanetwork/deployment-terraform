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

## Deploy

Download Azure Terraform plugin

```
cd azure
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
