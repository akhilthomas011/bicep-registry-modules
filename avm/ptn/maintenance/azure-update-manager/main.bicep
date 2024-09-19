metadata name = 'update-manager-configuration'
metadata description = 'This module creates multiple maintenance windows for Azure update manager and assigns them to existing VMs dynamically using tags .'
metadata owner = 'Azure/module-maintainers'
metadata version = '0.1.0'
metadata category = 'Compute'

targetScope = 'subscription'

// PARAMETERS
param location string = 'westeurope'
param maintenanceConfigurationsResourceGroupName string = 'myMaintenanceConfiguration-RG'
param maintenanceConfigurations array = [
  {
    maintenanceConfigName: 'maintenanceConfigurationRing-1'
    location: location
    installPatches: {
      linuxParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
        packageNameMasksToExclude: []
        packageNameMasksToInclude: []
      }
      rebootSetting: 'IfRequired'
      windowsParameters: {
        classificationsToInclude: [
          'Critical'
          'Security'
        ]
        kbNumbersToExclude: []
        kbNumbersToInclude: []
      }
    }
    lock: {}
    maintenanceWindow: {
      duration: '03:00'
      expirationDateTime: null
      recurEvery: '1Day'
      startDateTime: '2024-09-19 00:00'
      timeZone: 'India Standard Time'
    }
    visibility: 'Custom'
  }
]
// VARIABLES

module maintenance_configuration 'br/public:avm/res/maintenance/maintenance-configuration:0.3.0' = [
  for maintenanceConfiguration in maintenanceConfigurations: {
    scope: resourceGroup(maintenanceConfigurationsResourceGroupName)
    name: take('maintenanceConfiguration-${maintenanceConfiguration.maintenanceConfigurationName}', 63)
    params: {
      name: maintenanceConfiguration.maintenanceConfigName
      extensionProperties: {
        InGuestPatchMode: 'User'
      }
      installPatches: maintenanceConfiguration.?installPatches
      location: location
      lock: maintenanceConfiguration.lock
      maintenanceScope: 'InGuestPatch'
      maintenanceWindow: maintenanceConfiguration.maintenanceWindow
      roleAssignments: maintenanceConfiguration.roleAssignments
      tags: maintenanceConfiguration.tags
      visibility: maintenanceConfiguration.visibility
    }
  }
]

resource resourceRoleAssignment 'Microsoft.Resources/deployments@2023-07-01' = {
  name: '${guid(resourceId, principalId, roleDefinitionId)}-ResourceRoleAssignment'
  properties: {
    mode: 'Incremental'
    expressionEvaluationOptions: {
      scope: 'Outer'
    }
    template: loadJsonContent('modules/generic-role-assignment.json')
    parameters: {
      scope: {
        value: resourceId
      }
      name: {
        value: name
      }
      roleDefinitionId: {
        value: contains(roleDefinitionId, '/providers/Microsoft.Authorization/roleDefinitions/')
          ? roleDefinitionId
          : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
      }
      principalId: {
        value: principalId
      }
      principalType: {
        value: principalType
      }
      description: {
        value: description
      }
    }
  }
}

// OUTPUTS
output maintenanceConfigurationIds array = [
  for i in range(0, length(maintenanceConfigurations)): {
    id: maintenanceConfigurations[i].outputs.resourceId
  }
]
