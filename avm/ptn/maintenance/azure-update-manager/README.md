# Azure Update Manager

This module deploys multiple maintenance windows for Azure update manager and assigns them to existing VMs dynamically using tags.

## Navigation

- [Resource Types](#Resource-Types)
- [Usage examples](#Usage-examples)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)
- [Data Collection](#Data-Collection)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/locks` | [2020-05-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2020-05-01/locks) |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.ManagedIdentity/userAssignedIdentities` | [2023-01-31](https://learn.microsoft.com/en-us/azure/templates/Microsoft.ManagedIdentity/2023-01-31/userAssignedIdentities) |
| `Microsoft.Maintenance/maintenanceConfigurations` | [2023-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Maintenance/2023-04-01/maintenanceConfigurations) |
| `Microsoft.Maintenance/configurationAssignments` | [2023-04-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.maintenance/2023-04-01/configurationassignments)|
| `Microsoft.Authorization/policyDefinitions` | [2021-06-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2021-06-01/policydefinitions) |
| `Microsoft.Authorization/policyAssignments` | [2022-06-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/2022-06-01/policyassignments) |

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

>**Note**: Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

>**Note**: To reference the module, please use the following syntax `br/public:avm/ptn/maintenance/azure-update-manager:<version>`.

- [Using only defaults.](#example-1-using-only-defaults)
- [Using large parameter set.](#example-2-using-large-parameter-set)

### Example 1: _Using only defaults._

This instance deploys the module with the minimum set of required parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module subVending 'br/public:avm/ptn/lz/sub-vending:<version>' = {
  name: 'subVendingDeployment'
  params: {
    resourceProviders: {}
    subscriptionAliasEnabled: true
    subscriptionAliasName: '<subscriptionAliasName>'
    subscriptionBillingScope: '<subscriptionBillingScope>'
    subscriptionDisplayName: '<subscriptionDisplayName>'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: 'bicep-lz-vending-automation-child'
    subscriptionTags: {
      namePrefix: '<namePrefix>'
      serviceShort: '<serviceShort>'
    }
    subscriptionWorkload: 'Production'
  }
}
```

</details>
<p>

<details>

<summary>via JSON Parameter file</summary>

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "resourceProviders": {
      "value": {}
    },
    "subscriptionAliasEnabled": {
      "value": true
    },
    "subscriptionAliasName": {
      "value": "<subscriptionAliasName>"
    },
    "subscriptionBillingScope": {
      "value": "<subscriptionBillingScope>"
    },
    "subscriptionDisplayName": {
      "value": "<subscriptionDisplayName>"
    },
    "subscriptionManagementGroupAssociationEnabled": {
      "value": true
    },
    "subscriptionManagementGroupId": {
      "value": "bicep-lz-vending-automation-child"
    },
    "subscriptionTags": {
      "value": {
        "namePrefix": "<namePrefix>",
        "serviceShort": "<serviceShort>"
      }
    },
    "subscriptionWorkload": {
      "value": "Production"
    }
  }
}
```

</details>
<p>



