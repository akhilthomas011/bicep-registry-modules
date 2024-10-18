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
      timeZone: 'UTC'
    }
    visibility: 'Custom'
    resourceFilter: {
      resourceGroups: []
      osTypes: [
        'Windows'
        'Linux'
      ]
      locations: []
    }
  }
  {
    maintenanceConfigName: 'maintenance_ring-02'
    location: location
    installPatches: {
      linuxParameters: {
        classificationsToInclude: [
          'Other'
        ]
        packageNameMasksToExclude: []
        packageNameMasksToInclude: []
      }
      rebootSetting: 'IfRequired'
      windowsParameters: {
        classificationsToInclude: [
          'FeaturePack'
          'ServicePack'
        ]
        kbNumbersToExclude: []
        kbNumbersToInclude: []
      }
    }
    lock: {}
    maintenanceWindow: {
      duration: '03:00'
      expirationDateTime: null
      recurEvery: 'Week Saturday,Sunday'
      startDateTime: '2024-09-19 00:00'
      timeZone: 'UTC'
    }
    visibility: 'Custom'
    resourceFilter: {
      resourceGroups: []
      osTypes: [
        'Windows'
        'Linux'
      ]
      locations: []
    }
  }
]

@description('The tag name that will be used to filter the VMs/ARC enabled servers for the maintenance ring.')
param maintenanceConfigEnrollmentTagName string = 'aum_maintenance_config'

@description('The name of the managed identity that will be used to deploy the policies.')
@maxLength(63)
param policyDeploymentManagedIdentityName string = 'id-aumpolicy-contributor-001'

//VARIABLES

var maintenanceConfigNames = [
  for (maintenanceConfiguration, i) in maintenanceConfigurations: maintenanceConfiguration.maintenanceConfigName
]

var maintenanceConfigTagsArray = [
  for (maintenanceConfigName, i) in maintenanceConfigNames: {
    maintenanceConfigEnrollmentTagName: maintenanceConfigEnrollmentTagName
    maintenanceConfigName: '${maintenanceConfigName}'
  }
]

var maintenanceConfigTagsObjects = toObject(
  maintenanceConfigTagsArray,
  entry => entry.maintenanceConfigName,
  entry => entry.maintenanceConfigEnrollmentTagName
)

var testobject = toObject(maintenanceConfigNames, entry => entry,)
// MODULES

// OUTPUTS
output maintenanceConfigNames array = maintenanceConfigNames
output maintenanceConfigTagsArray array = maintenanceConfigTagsArray
output maintenanceConfigTagsObjects object = maintenanceConfigTagsObjects
output testobject object = testobject
//User Defined Types
@description('Defines the structure of a maintenance configuration.')
type maintenanceConfigurationType = {
  @description('The name of the maintenance configuration.')
  maintenanceConfigName: string
  @description('The location where the maintenance configuration will be created.')
  location: string
  @description('The patch installation settings for the maintenance configuration.')
  installPatches: {
    @description('The patch installation settings for Linux.')
    linuxParameters: {
      @description('The classifications of patches to include for Linux.')
      classificationsToInclude: array?
      @description('The package name masks to exclude for Linux.')
      packageNameMasksToExclude: array?
      @description('The package name masks to include for Linux.')
      packageNameMasksToInclude: array?
    }
    @description('The reboot setting for the maintenance configuration.')
    rebootSetting: string
    @description('The patch installation settings for Windows.')
    windowsParameters: {
      @description('The classifications of patches to include for Windows.')
      classificationsToInclude: array?
      @description('The KB numbers to exclude for Windows.')
      kbNumbersToExclude: array?
      @description('The KB numbers to include for Windows.')
      kbNumbersToInclude: array?
    }
  }
  @description('The lock settings for the maintenance configuration.')
  lock: object
  @description('The maintenance window settings for the maintenance configuration.')
  maintenanceWindow: {
    @description('The duration of the maintenance window.')
    duration: string
    @description('The expiration date and time of the maintenance window.')
    expirationDateTime: string?
    @description('The recurrence interval of the maintenance window.')
    recurEvery: string
    @description('The start date and time of the maintenance window.')
    startDateTime: string
    @description('''Name of the timezone.
    List of timezones can be obtained by executing `[System.TimeZoneInfo]::GetSystemTimeZones()` in PowerShell.
    Example: `Pacific Standard Time`, `UTC`, `W. Europe Standard Time`, `Korea Standard Time`, `Cen. Australia Standard Time`.
    ''')
    timeZone: string
  }
  @description('The visibility of the maintenance configuration.')
  visibility: visibilityType
  @description('The resource filter settings for the maintenance configuration.')
  resourceFilter: {
    @description('The resource groups to include in the maintenance configuration.')
    resourceGroups: array?
    @description('The OS types to include in the maintenance configuration.')
    osTypes: array?
    @description('The locations to include in the maintenance configuration.')
    locations: array?
  }
  @description('The tags to apply to the maintenance configuration.')
  tags: object?
  @description('The role assignments for the maintenance configuration.')
  roleAssignments: array?
}[]
@description('Defines the structure of visibility.')
type visibilityType = '' | 'Custom' | 'Public' | null
