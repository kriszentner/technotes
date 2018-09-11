# Introduction
Azure Key Vault (AKV) is a store that can house secrets or certificates. It's a fairly useful Azure item, though doing things with it programatically do involve wrapping a number of concepts and tutorials together.

Honestly I spend enough time looking this up myself, that I decided to just make a step-by-step on how to do it programatically. I prefer the Azure cli, so we'll be going through it that way.

Let's create a keyvault, a service principal, and then give the service principal access to read secrets from the vault.

# Prerequisites
Install `jq` for this to work.

# Creating a Key Vault
Let's set the subscription you'll make your vault in
```bash
az account set --subscription "MyAzureSubscription"
```
If you don't have a Resource Group in mind for your vault, make one:
```bash
az group create -n 'MyVaultGroup' -l 'uswest2'
```
If your sub doesn't have AKV enabled, lets do it:
```bash
az provider register -n Microsoft.KeyVault
```
Create your vault:
```bash
az keyvault create --name 'MyKeyVault' \
  --resource-group 'MyVaultGroup' \
  --location 'westus2'
```

# Create your Principal
Now let's create a principal that we'll use to pull secrets from the vault. If you want to set your own password, you can use `--password "mysecretpass"` in the below command:
```
ROLENAME="keyvaultreader"
EXPIREYEAR=$(expr 9999 - $(date +%Y))
az ad sp create-for-rbac --name $ROLENAME  --years $EXPIREYEAR
```
This will create a service principal, if you're generating the password, note the password, or you'll have to change it later.

# Assign Permissions to the Principal
Notice the `get list` part. You can set many more permissions for secrets, keys and certs. See the references at the end of this doc.
```bash
az keyvault set-policy --name gcrchefvault --resource-group MSREngInfraExt --secret-permissions get list --spn 2347e503-3b37-42b3-902b-a503f2d4c488
```

# Put it all together

```bash
#!/usr/bin/env bash
SUBSCRIPTION="MyAzureSubscription"
RGNAME="MyVaultGroup"
VAULTNAME="MyKeyVault"
LOCATION="uswest2"
ROLENAME="keyvaultreader"
EXPIREYEAR=$(expr 9999 - $(date +%Y))
# Leave blank to have it set a password for you
PASSWORD=""
# Setup
az account set --subscription $SUBSCRIPTION
az group create -n $RGNAME -l $LOCATION
az provider register -n Microsoft.KeyVault
# Create Keyvault
az keyvault create --name $VAULTNAME \
  --resource-group $RGNAME \
  --location $LOCATION
# Principal Creation
az ad sp create-for-rbac --name $ROLENAME --password "$mypass" --years $expireyear
SPN=$(az ad app list --display-name $ROLENAME|jq -r '.[].appId')
# Set Policy
az keyvault set-policy --name $VAULTNAME --resource-group $RGNAME --secret-permissions get list --spn $SPN
```
# References
[Manage Keyvault with CLI](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-manage-with-cli2)  
[Keyvault Documentation](https://docs.microsoft.com/en-us/cli/azure/keyvault) 