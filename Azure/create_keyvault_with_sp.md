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

# Using a Service Principal
Now let's create a principal that we'll use to pull secrets from the vault. If you want to set your own password, you can use `--password "mysecretpass"` in the below command:
```
ROLENAME="keyvaultreader"
EXPIREYEAR=$(expr 9999 - $(date +%Y))
az ad sp create-for-rbac --name $ROLENAME  --years $EXPIREYEAR
```
This will create a service principal the the name in the `ROLENAME` variable. If you're generating the password, note the password, or you'll have to change it later.

# Using a Managed Service Identity
You can use an Azure Managed Service Identity (MSI) to access Keyvault as well. A Managed Identity in this case is a sort of credential/user that gets assigned to an Azure resource (in this case, an Azure VM).

If you didn't create your VM with an MSI, [you can assign it one](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm):
```bash
az vm identity assign -g myResourceGroup -n myVm
```

# Assign Permissions to the Vault to the Principal
Notice the `get list` part. You can set many more permissions for secrets, keys and certs. See the references at the end of this doc.
```bash
az keyvault set-policy \
  --name MyKeyVault \
  --resource-group MyVaultGroup \
  --secret-permissions get list \
  --spn 22f4ef14-d742-442c-bb1c-a41a82c3cf0e
```

# Assign Permissions to the Vault on a VM with an MSI
And here's how you do it with the MSI. You'll need to get the SPN (aka AppID or PrincipalId). In this case there's an embedded command to get the latter. This only works if your VM is on the same subscription as your AKV, otherwise you'll need to change subscription contexts before your `az vm identity` command.
```bash
az keyvault set-policy \
  --name MyKeyVault \
  --resource-group MyVaultGroup \
  --secret-permissions get list \
  --spn $(az vm identity show -g KZ-RG -n kz-ubuntutest|jq -r '.principalId')
```
# Testing that your Service Principal can access the Vault
You can test if this is working by creating a secret in your keyvault (I used `test`). Then log in. Be sure to fill in the app id, password, and tenant values below:
 ```bash
 az login --service-principal \
  -u 'd5da05cd-5855-40b7-b981-02360ad19564' \
  -p '16858f8f-4b84-45ee-aecb-66091f136748' \
  --tenant 'f11fe2ef-0b41-456a-a6bc-d1bf4c6de3f8'
az keyvault secret show --name test --vault-name MyKeyVault
```
# Put it all together
Here's a script that puts it all together if you're using a Service Principal
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
[Managed Identities on Azure VMs](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm)