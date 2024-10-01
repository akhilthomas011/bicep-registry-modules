using './main.bicep'

param location = 'westeurope'
param maintenanceConfigurationsResourceGroupName = 'myMaintenanceConfiguration-RG'
param maintenanceConfigurations = [
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
param tagAssignmentPolicy = {
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

