# Create the resource group via CLI
az group create --name csb-az-terraform --location southeastasia
-- Output
{                                
  "id": "/subscriptions/30a7f168-100f-4383-8cc5-b9835974bd7f/resourceGroups/csb-az-terraform",
  "location": "southeastasia",
  "managedBy": null,
  "name": "csb-az-terraform",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
}

# Get account info to find subscription id
az account show --query id --output tsv
-- Output
30a7f168-100f-4383-8cc5-b9835974bd7f

# Create service principal
az ad sp create-for-rbac --name "csb-az-terraform-deploy" --role "Contributor" --scopes "/subscriptions/30a7f168-100f-4383-8cc5-b9835974bd7f"
-- Output

# Create Azure DevOps Account