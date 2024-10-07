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
    maintenanceRing: '01'
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
        'Linux'
      ]
      locations: [
        'uaenorth'
      ]
    }
  }
]

@description('The tag name that will be used to filter the VMs/ARC enabled servers for enabling Azure Update Manager.')
param enableAUMTagName string = 'aum_maintenance'

@description('The tag value that will be used to filter the VMs/ARC enabled servers for enabling Azure Update Manager.')
param enableAUMTagValue string = 'Enabled'

@description('The tag name that will be used to filter the VMs/ARC enabled servers for the maintenance ring.')
param maintenanceRingTagName string = 'aum_maintenance_ring'

@description('The tag value that will be used to filter the VMs/ARC enabled servers for the maintenance ring.')
param maintenanceRingTagValues array = [
  'Pilot'
  'Ring-01'
  'Ring-02'
]

// VARIABLES
var aum_maintenance_rings = [
  for (maintenanceConfiguration, index) in maintenanceConfigurations: maintenanceConfiguration.resourceFilter.tagSettings.tags.aum_maintenance_ring[0]
]

var aumEnablingTag = {
  '${enableAUMTagName}': enableAUMTagValue
}

var aumEnablingTagObject = {
  key: items(aumEnablingTag)[0].key
  value: items(aumEnablingTag)[0].value
}

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
      filter: {
        resourceTypes: maintenanceConfiguration.resourceFilter.resourceTypes
        resourceGroups: maintenanceConfiguration.resourceFilter.resourceGroups
        osTypes: maintenanceConfiguration.resourceFilter.osTypes
        locations: maintenanceConfiguration.resourceFilter.locations
        tagsettings: {
          filterOperator: 'All'
          tags: {
            '${maintenanceRingTagName}': [maintenanceConfiguration.maintenanceRing]
            '${enableAUMTagName}': [enableAUMTagValue]
          }
        }
      }
    }
  }
]

module setPrereqPolicyAssignment 'modules/policyAssignments.bicep' = {
  name: 'AzureUpdateManagerPrerequisitePolicyAssignment'
  params: {
    name: 'AzureUpdateManagerPrerequisitePolicyAssignment'
    displayName: 'Azure Update Manager prerequisites settings update based on Tags'
    description: 'Azure Update Manager prerequisites settings update based on Tags of the Azure VMs/ARC enabled Servers'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/9905ca54-1471-49c6-8291-7582c04cd4d4'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: [aumEnablingTagObject]
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

module configurePeriodicCheckingAzureVMsWin 'modules/policyAssignments.bicep' = {
  name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignmentWindows'
  params: {
    name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignmentWindows'
    displayName: 'Azure Update Manager enabling periodic assessment on Azure VMs based on Tags for Windows'
    description: 'This policy enables periodic checking for updates on Azure based on Tags of the Azure VMs for Windows'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: aumEnablingTag
      }
      osType: {
        value: 'Windows'
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

module configurePeriodicCheckingAzureVMs 'modules/policyAssignments.bicep' = {
  name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignmentLinux'
  params: {
    name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignmentLinux'
    displayName: 'Azure Update Manager enabling periodic assessment on Azure VMs based on Tags for Linux'
    description: 'This policy enables periodic checking for updates on Azure based on Tags of the Azure VMs for Linux'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: aumEnablingTag
      }
      osType: {
        value: 'Linux'
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

resource configurePeriodicCheckingAzureVMsremediateTask 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: guid('Remediate', configurePeriodicCheckingAzureVMs.name, subscription().id)
  properties: {
    failureThreshold: {
      percentage: 1
    }
    resourceCount: 500
    policyAssignmentId: configurePeriodicCheckingAzureVMs.outputs.resourceId
    policyDefinitionReferenceId: '/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15'
    parallelDeployments: 10
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}

module configurePeriodicCheckingARCServersWindows 'modules/policyAssignments.bicep' = {
  name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignmentWindows'
  params: {
    name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignmentWindows'
    displayName: 'Azure Update Manager enabling periodic assessment on ARC Servers based on Tags for Windows'
    description: 'This policy enables periodic checking for updates on Azure based on Tags of the ARC Servers for Windows'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/bfea026e-043f-4ff4-9d1b-bf301ca7ff46'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: aumEnablingTag
      }
      osType: {
        value: 'Windows'
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

module configurePeriodicCheckingARCServersLinux 'modules/policyAssignments.bicep' = {
  name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignmentLinux'
  params: {
    name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignmentWindows'
    displayName: 'Azure Update Manager enabling periodic assessment on ARC Servers based on Tags for Linux'
    description: 'This policy enables periodic checking for updates on Azure based on Tags of the ARC Servers for Linuxs'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/bfea026e-043f-4ff4-9d1b-bf301ca7ff46'
    parameters: {
      tagOperator: {
        value: 'All'
      }
      tagValues: {
        value: aumEnablingTag
      }
      osType: {
        value: 'Linux'
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

module requireAUMTagPolicyDefinition 'modules/policyDefinition.bicep' = {
  name: 'requireAUMTagPolicyDefinition'
  params: {
    name: 'requireAUMTagPolicyDefinition'
    displayName: 'Require tags on Azure VMs/ARC enabled servers for Azure Update Manager maintenance'
    description: 'Enforces existence of tags on Azure VMs/ARC enabled servers for Azure Update Manager maintenance. Does not apply to other resources/resource groups.'
    mode: 'Indexed'
    metadata: {
      version: '1.0.0'
      category: 'Tags'
    }
    parameters: {
      maintenanceRingTagName: {
        type: 'String'
        metadata: {
          displayName: 'AUM maintenance ring tag name'
          description: 'Name of the AUM maintenance ring tag. For example \'aum_maintenance_ring\''
        }
        defaultValue: maintenanceRingTagName
      }
      maintenanceRingTagValues: {
        type: 'Array'
        metadata: {
          displayName: 'AUM maintenance ring tag allowed values'
          description: 'Values of the tag. For example [01,02,03]'
        }
        defaultValue: maintenanceRingTagValues
      }
      maintenanceEnablingTagName: {
        type: 'String'
        metadata: {
          displayName: 'AUM maintenance enabling tag name'
          description: 'Name of the AUM maintenance enabling tag. For example \'aum_maintenance\''
        }
        defaultValue: enableAUMTagName
      }
      maintenanceEnablingTagValue: {
        type: 'String'
        metadata: {
          displayName: 'AUM maintenance enabling tag value'
          description: 'Value of the tag. For example, \'Enabled\''
        }
        defaultValue: enableAUMTagValue
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            anyOf: [
              {
                field: 'type'
                equals: 'Microsoft.Compute/virtualMachines'
              }
              {
                field: 'type'
                equals: 'Microsoft.HybridCompute/machines'
              }
            ]
          }
          {
            anyOf: [
              {
                not: {
                  field: '[concat(\'tags[\', parameters(\'maintenanceRingTagName\'), \']\')]'
                  in: '[parameters(\'maintenanceRingTagValues\')]'
                }
              }
              {
                not: {
                  field: '[concat(\'tags[\', parameters(\'maintenanceEnablingTagName\'), \']\')]'
                  equals: '[parameters(\'maintenanceEnablingTagValue\')]'
                }
              }
            ]
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

module requireAUMTagPolicyAssignment 'modules/policyAssignments.bicep' = {
  name: 'requireAUMTagPolicyAssignment'
  params: {
    name: 'requireAUMTagPolicyAssignment'
    displayName: 'Require AUM maintenance ring tag on Azure VMs/ARC enabled servers'
    description: 'Enforces existence of a tag on Azure VMs/ARC enabled servers.'
    policyDefinitionId: requireAUMTagPolicyDefinition.outputs.resourceId
    parameters: {
      maintenanceRingTagName: {
        value: maintenanceRingTagName
      }
      maintenanceRingTagValues: {
        value: maintenanceRingTagValues
      }
      maintenanceEnablingTagName: {
        value: enableAUMTagName
      }
      maintenanceEnablingTagValue: {
        value: enableAUMTagValue
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

// OUTPUTS
output maintenanceConfigurationIds array = [
  for i in range(0, length(maintenanceConfigurations)): {
    id: maintenance_configurations[i].outputs.resourceId
  }
]
