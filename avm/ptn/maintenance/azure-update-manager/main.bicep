metadata name = 'update-manager-configuration'
metadata description = 'This module creates multiple maintenance windows for Azure update manager and assigns them to existing VMs dynamically using tags .'
metadata owner = 'Azure/module-maintainers'
metadata version = '0.1.0'
metadata category = 'Compute'

targetScope = 'subscription'

// PARAMETERS
param location string = deployment().location
param maintenanceConfigurationsResourceGroupName string = 'myMaintenanceConfiguration-RG'
param maintenanceConfigurations array = [
  {
    maintenanceConfigName: 'maintenance_ring-01'
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
    resourceFilter: {
      resourceTypes: [
        'Microsoft.Compute/virtualMachines'
        'Microsoft.hybridcompute/machines'
      ]
      resourceGroups: [
        'rg-dge-access-prod-uaen-01'
        'maintenanceConfigTest-RG'
      ]
      osTypes: [
        'Windows'
      ]
      locations: [
        'uaenorth'
      ]
      tagSettings: {
        filterOperator: 'All'
        tags: {
          aum_maintenance_ring: ['01']
          aum_maintenance: ['enabled']
        }
      }
    }
  }
]

// VARIABLES

// MODULES
module maintenance_configurations 'br/public:avm/res/maintenance/maintenance-configuration:0.3.0' = [
  for (maintenanceConfiguration, i) in maintenanceConfigurations: {
    scope: resourceGroup(maintenanceConfigurationsResourceGroupName)
    name: take('maintenanceConfiguration-${maintenanceConfiguration.maintenanceConfigName}', 63)
    params: {
      name: maintenanceConfiguration.maintenanceConfigName
      extensionProperties: {
        InGuestPatchMode: 'User'
      }
      installPatches: maintenanceConfiguration.?installPatches
      location: location
      lock: maintenanceConfiguration.?lock
      maintenanceScope: 'InGuestPatch'
      maintenanceWindow: maintenanceConfiguration.?maintenanceWindow
      roleAssignments: maintenanceConfiguration.?roleAssignments
      tags: maintenanceConfiguration.?tags
      visibility: maintenanceConfiguration.?visibility
    }
  }
]

module maintenance_configuration_assignments 'modules/configAssignments.bicep' = [
  for (maintenanceConfiguration, i) in maintenanceConfigurations: {
    name: take('maintenanceConfigAssignment-${maintenanceConfiguration.maintenanceConfigName}', 63)
    params: {
      maintenanceConfigResourceGroupName: maintenanceConfigurationsResourceGroupName
      maintenanceConfigName: maintenance_configurations[i].outputs.name
      maintenanceConfigAssignmentName: 'maintenanceConfigAssignment-${maintenanceConfiguration.maintenanceConfigName}'
      filter: maintenanceConfiguration.?resourceFilter
    }
  }
]

var aumEnablingTag = [{ key: 'aum_maintenance', value: 'enabled' }]

module setPrereqPolicyAssignment 'modules/policyAssignments.bicep' = {
  name: 'AzureUpdateManagerPrerequisitePolicyAssignment'
  params: {
    name: 'AzureUpdateManagerPrerequisitePolicyAssignment'
    displayName: 'Azure Update Manager Prerequisite deployment based on Tags'
    description: 'This policy deploys prerequisites for Azure Update Manager based on Tags of the Azure VMs/ARC enabled Servers'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/9905ca54-1471-49c6-8291-7582c04cd4d4'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: aumEnablingTag
      }
      effect: {
        value: 'DeployIfNotExists'
      }
    }
    identity: 'SystemAssigned'
    userAssignedIdentityId: ''
    roleDefinitionIds: ['/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c']
    metadata: {}
    nonComplianceMessages: []
    enforcementMode: 'Default'
    subscriptionId: subscription().subscriptionId
    notScopes: []
    location: location
    overrides: []
    resourceSelectors: []
  }
}

// module setPrereqPolicyAssignment 'modules/policyAssignments.bicep' = [
//   for (maintenanceConfiguration, i) in maintenanceConfigurations: {
//     name: '${maintenanceConfiguration.maintenanceConfigName}-prereqPolicyAssignment'
//     params: {
//       name: '${maintenanceConfiguration.maintenanceConfigName}-prereqPolicyAssignment'
//       displayName: 'Azure Update Manager Prerequisite Policy${maintenanceConfiguration.maintenanceConfigName}-prereqPolicyAssignment'
//       description: '${maintenanceConfiguration.maintenanceConfigName}-prereqPolicyAssignment'
//       policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/9905ca54-1471-49c6-8291-7582c04cd4d4'
//       parameters: {
//         tagOperator: {
//           value: maintenanceConfiguration.resourceFilter.tagSettings.filterOperator ?? 'All'
//         }
//         tagValues: {
//           value: aumEnablingTag
//         }
//         locations: {
//           value: [location]
//         }
//         effect: {
//           value: 'DeployIfNotExists'
//         }
//         operatingSystemTypes: {
//           value: maintenanceConfiguration.resourceFilter.osTypes ?? []
//         }
//         resourceGroups: {
//           value: maintenanceConfiguration.resourceFilter.resourceGroups ?? []
//         }
//       }
//       identity: 'SystemAssigned'
//       userAssignedIdentityId: ''
//       roleDefinitionIds: ['/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c']
//       metadata: {}
//       nonComplianceMessages: []
//       enforcementMode: 'Default'
//       subscriptionId: subscription().subscriptionId
//       notScopes: []
//       location: location
//       overrides: []
//       resourceSelectors: []
//     }
//   }
// ]

// OUTPUTS
output maintenanceConfigurationIds array = [
  for i in range(0, length(maintenanceConfigurations)): {
    id: maintenance_configurations[i].outputs.resourceId
  }
]

output JsonObject string = '[${string(aumEnablingTag)}]'
