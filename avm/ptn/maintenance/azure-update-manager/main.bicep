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
        }
      }
    }
  }
]
param tagAssignmentPolicy object = {
  displayName: 'tagAssignmentPolicy'
  description: 'tagAssignmentPolicy'
  policyDefinitionId: 'policyDefinitionId'
  parameters: {}
  identity: 'SystemAssigned'
  userAssignedIdentityId: ''
  roleDefinitionIds: []
  metadata: {}
  nonComplianceMessages: []
  enforcementMode: 'Default'
  subscriptionId: ''
  notScopes: []
  location: location
  overrides: []
  resourceSelectors: []
}

// VARIABLES

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

module policyAssignment 'modules/policyAssignments.bicep' = {
  name: 'policyAssignment'
  params: {
    name: tagAssignmentPolicy.name
    displayName: tagAssignmentPolicy.displayName
    description: tagAssignmentPolicy.description
    policyDefinitionId: tagAssignmentPolicy.policyDefinitionId
    parameters: tagAssignmentPolicy.parameters
    identity: tagAssignmentPolicy.identity
    userAssignedIdentityId: tagAssignmentPolicy.userAssignedIdentityId
    roleDefinitionIds: tagAssignmentPolicy.roleDefinitionIds
    metadata: tagAssignmentPolicy.metadata
    nonComplianceMessages: tagAssignmentPolicy.nonComplianceMessages
    enforcementMode: tagAssignmentPolicy.enforcementMode
    subscriptionId: tagAssignmentPolicy.subscriptionId
    notScopes: tagAssignmentPolicy.notScopes
    location: location
    overrides: tagAssignmentPolicy.overrides
    resourceSelectors: tagAssignmentPolicy.resourceSelectors
  }
}

// OUTPUTS
output maintenanceConfigurationIds array = [
  for i in range(0, length(maintenanceConfigurations)): {
    id: maintenance_configurations[i].outputs.resourceId
  }
]
