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
module updateManagerConfig 'br/public:avm/ptn/maintenance/azure-update-manager:<version>' = {
  name: 'updateManagerConfigDeployment'
  params: {
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
  }
}
```

</details>
<p>

<details>

<summary>via Bicep parameters file</summary>

```bicep-params
using 'br/public:avm/ptn/maintenance/azure-update-manager:<version>'


```

</details>
<p>

### Example 2: _Using large parameter set_

This instance deploys the module with most of its features enabled.


<details>

<summary>via Bicep module</summary>

```bicep
module updateManagerConfig 'br/public:avm/ptn/maintenance/azure-update-manager:<version>' = {
  name: 'updateManagerConfigDeployment'
  params: {
    location: '<location>'
    maintenanceConfigurationsResourceGroupNeworExisting: 'new'
    maintenanceConfigurationsResourceGroupName: '<maintenanceConfigurationsResourceGroupName>'
    maintenanceConfigurations:[
      {
        maintenanceConfigName: 'maintenance_ring-01'
        location: location
        installPatches: {
          linuxParameters: {
            classificationsToInclude:'<classificationsToInclude>'
            packageNameMasksToExclude: '<packageNameMasksToExclude>'
            packageNameMasksToInclude: '<packageNameMasksToInclude>'
          }
          rebootSetting: 'IfRequired'
          windowsParameters: {
            classificationsToInclude: '<classificationsToInclude>'
            kbNumbersToExclude: '<kbNumbersToExclude>'
            kbNumbersToInclude: '<kbNumbersToInclude>'
          }
        }
        lock: {
          kind: 'CanNotDelete'
          name: 'myCustomLockName'
        }
        maintenanceWindow: {
          duration: '03:00'
          expirationDateTime: '9999-12-31 23:59:59'
          recurEvery: '1Day'
          startDateTime: '2022-12-31 13:00'
          timeZone: 'UTC'
        }
        visibility: 'Custom'
        resourceFilter: {
          resourceGroups: '<resourceGroups>'
          osTypes: '<osTypes>'
          locations: '<locations>'
        }
      }
    ]
    enableAUMTagName:'<enableAUMTagName>'
    enableAUMTagValue: '<enableAUMTagValue>'
    maintenanceConfigEnrollmentTagName: '<maintenanceConfigEnrollmentTagName>'
    policyDeploymentManagedIdentityName: '<policyDeploymentManagedIdentityName>'
    enableTelemetry: '<enableTelemetry>'
  }
}
```

</details>
<p>

<details>

<summary>via JSON parameters file</summary>

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "<location>"
    },
    "maintenanceConfigurationsResourceGroupNeworExisting": "new",
    "maintenanceConfigurationsResourceGroupName": {
      "value": ""
    },
    "maintenanceConfigurations": {
      "value": []
    },
    "enableAUMTagName": {
      "value": ""
    },
    "enableAUMTagValue": {
      "value": ""
    },
    "maintenanceConfigEnrollmentTagName": {
      "value": ""
    },
    "policyDeploymentManagedIdentityName": {
      "value": ""
    },
    "enableTelemetry": {
      "value": false
    }
  }
}
```

</details>
<p>

<details>

<summary>via Bicep parameters file</summary>

```bicep-params
using 'br/public:avm/ptn/network/private-link-private-dns-zones:<version>'

param location = '<location>'
param privateLinkPrivateDnsZones = [
  'testpdnszone1.int'
  'testpdnszone2.local'
]
param virtualNetworkResourceIdsToLinkTo = [
  '<vnetResourceId>'
]
```

</details>
<p>
