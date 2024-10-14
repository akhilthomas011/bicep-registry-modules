metadata name = 'update-manager-configuration'
metadata description = 'This module creates multiple maintenance windows for Azure update manager and assigns them to existing VMs dynamically using tags .'
metadata owner = 'Azure/module-maintainers'
metadata version = '0.1.0'
metadata category = 'Compute'

targetScope = 'subscription'

//PARAMETERS
@description('The location where the resources will be deployed.')
param location string = deployment().location

@description('The name of the resource group where the maintenance configurations will be created.')
param maintenanceConfigurationsResourceGroupName string = 'myMaintenanceConfiguration-RG'

@description('The array of maintenance configurations to be created.')
param maintenanceConfigurations maintenanceConfigurationType = [
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

@description('The tag values that will be used to filter the VMs/ARC enabled servers for the maintenance ring.')
param maintenanceRingTagValues array = [
  'Ring-01'
  'Ring-02'
  'Ring-03'
]

@description('The name of the managed identity that will be used to deploy the policies.')
@maxLength(63)
param policyDeploymentManagedIdentityName string = 'id-aumpolicy-contributor-001'

var aumEnablingTag = {
  '${enableAUMTagName}': enableAUMTagValue
}

var aumEnablingTagObject = {
  key: items(aumEnablingTag)[0].key
  value: items(aumEnablingTag)[0].value
}

var osTypes = [
  'Windows'
  'Linux'
]

// MODULES

@description('Creates a user-assigned managed identity for policy deployment.')
module id_aumpolicy_contributor 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedManagedIdentity'
  scope: resourceGroup(maintenanceConfigurationsResourceGroupName)
  params: {
    name: policyDeploymentManagedIdentityName
    location: location
  }
}

@description('Creates maintenance configurations based on the provided parameters.')
module maintenance_configurations 'br/public:avm/res/maintenance/maintenance-configuration:0.3.0' = [
  for (maintenanceConfiguration, i) in maintenanceConfigurations: {
    name: take('maintenanceConfiguration-${maintenanceConfiguration.maintenanceConfigName}', 63)
    scope: resourceGroup(maintenanceConfigurationsResourceGroupName)
    params: {
      name: maintenanceConfiguration.maintenanceConfigName
      location: location
      installPatches: maintenanceConfiguration.?installPatches
      maintenanceWindow: maintenanceConfiguration.?maintenanceWindow
      visibility: maintenanceConfiguration.?visibility
      lock: maintenanceConfiguration.?lock
      tags: maintenanceConfiguration.?tags
      roleAssignments: maintenanceConfiguration.?roleAssignments
      extensionProperties: {
        InGuestPatchMode: 'User'
      }
      maintenanceScope: 'InGuestPatch'
    }
  }
]

@description('Assigns maintenance configurations to resources based on the provided filters.')
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

@description('Assigns the prerequisite policy for Azure Update Manager.')
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
    identity: 'UserAssigned'
    userAssignedIdentityId: id_aumpolicy_contributor.outputs.resourceId
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

@description('Enables periodic assessment on Azure VMs based on tags for each OS type.')
@batchSize(1)
module configurePeriodicCheckingAzureVMsWin 'modules/policyAssignments.bicep' = [
  for osType in osTypes: {
    name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignment${osType}'
    params: {
      name: 'AUMConfigurePeriodicCheckingAzVMPolicyAssignment${osType}'
      displayName: 'Azure Update Manager enabling periodic assessment on Azure VMs based on Tags for ${osType}'
      description: 'This policy enables periodic checking for updates on Azure based on Tags of the Azure VMs for ${osType}'
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15'
      parameters: {
        tagOperator: {
          value: 'All'
        }
        tagValues: {
          value: aumEnablingTag
        }
        osType: {
          value: osType
        }
      }
      identity: 'UserAssigned'
      userAssignedIdentityId: id_aumpolicy_contributor.outputs.resourceId
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
]

@description('Enables periodic assessment on ARC Servers based on tags for each OS type.')
@batchSize(1)
module configurePeriodicCheckingARCServersWindows 'modules/policyAssignments.bicep' = [
  for osType in osTypes: {
    name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignment${osType}'
    params: {
      name: 'AUMConfigurePeriodicCheckingARCVMPolicyAssignment${osType}'
      displayName: 'Azure Update Manager enabling periodic assessment on ARC Servers based on Tags for ${osType}'
      description: 'This policy enables periodic checking for updates on Azure based on Tags of the ARC Servers for ${osType}'
      policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/bfea026e-043f-4ff4-9d1b-bf301ca7ff46'
      parameters: {
        tagOperator: {
          value: 'All'
        }
        tagValues: {
          value: aumEnablingTag
        }
        osType: {
          value: osType
        }
      }
      identity: 'UserAssigned'
      userAssignedIdentityId: id_aumpolicy_contributor.outputs.resourceId
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
]

@description('Defines a policy to enforce tags on Azure VMs/ARC enabled servers for Azure Update Manager maintenance.')
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
                  exists: true
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

@description('Assigns the policy to enforce tags on Azure VMs/ARC enabled servers for Azure Update Manager maintenance.')
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
    }
    identity: 'UserAssigned'
    userAssignedIdentityId: id_aumpolicy_contributor.outputs.resourceId
    roleDefinitionIds: []
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

//User Defined Types
@description('Defines the structure of a maintenance configuration.')
type maintenanceConfigurationType = [
  {
    maintenanceConfigName: string
    location: string
    installPatches: {
      linuxParameters: {
        classificationsToInclude: array
        packageNameMasksToExclude: array
        packageNameMasksToInclude: array
      }
      rebootSetting: string
      windowsParameters: {
        classificationsToInclude: array
        kbNumbersToExclude: array
        kbNumbersToInclude: array
      }
    }
    lock: object
    maintenanceWindow: {
      duration: string
      expirationDateTime: string?
      recurEvery: string
      startDateTime: string
      timeZone: string
    }
    visibility: visibilityType
    maintenanceRing: string
    resourceFilter: {
      resourceTypes: array
      resourceGroups: array
      osTypes: array
      locations: array
    }
    tags: object?
    roleAssignments: array?
  }
]
@description('Defines the structure of visibility.')
type visibilityType = '' | 'Custom' | 'Public' | null
