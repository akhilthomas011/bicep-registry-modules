using './main.bicep'

param location = deployment().location
param maintenanceConfigurationsResourceGroupNeworExisting = 'new'
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
param enableAUMTagName = 'aum_maintenance'
param enableAUMTagValue = 'Enabled'
param maintenanceConfigEnrollmentTagName = 'aum_maintenance_config'
param policyDeploymentManagedIdentityName = 'id-aumpolicy-contributor-001'
param enableTelemetry = true

