// This script is given for testing purpose
//
// For a given RG, it will
//  - Deploy an Automation account using a System-assigned Managed Identity
//  - Give Contributor role to System-assigned Managed Identity to the RG 
//  - Deploy Runbooks to Automation Account
//
// Example of execution:
// az deployment group create --resource-group MyRg --template-file main.bicep

// Location
param Location string = 'West Europe'
param LocationShort string = 'weu'

param AutomationAccountName string = 'automationaccount03'

resource AutomationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: AutomationAccountName
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    sku: {
      name: 'Basic'
    }
  }
}

resource Runbook_ScheduleUpdatesWithVmsTags 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/UM-ScheduleUpdatesWithVmsTags'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/dawlysd/azure-update-management-with-tags/main/runbooks/UM-ScheduleUpdatesWithVmsTags.ps1'      
    }
  }
}

resource Runbook_PreTasks 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/UM-PreTasks'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/dawlysd/azure-update-management-with-tags/main/runbooks/UM-PreTasks.ps1'
    }
  }
}

resource Runbook_PostTasks 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/UM-PostTasks'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/dawlysd/azure-update-management-with-tags/main/runbooks/UM-PostTasks.ps1'      
    }
  }
}

resource Runbook_CleanUpSchedules 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/UM-CleanUp-Schedules'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/dawlysd/azure-update-management-with-tags/main/runbooks/UM-CleanUp-Schedules.ps1'        
    }
  }
}

resource Runbook_CleanUpSnapshots 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/UM-CleanUp-Snapshots'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/dawlysd/azure-update-management-with-tags/main/runbooks/UM-CleanUp-Snapshots.ps1'           
    }
  }
}

resource DailySchedule 'Microsoft.Automation/automationAccounts/schedules@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/Schedules-ScheduleVmsWithTags'
  properties:{
    description: 'Schedule daily'
    startTime: ''
    frequency: 'Day'
    interval: 1
  }
}

param Sched1Guid string = newGuid()
resource ScheduleRunbook_ScheduleUpdatesWithVmsTags 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/${Sched1Guid}'
  properties:{
    schedule:{
      name: split(DailySchedule.name, '/')[1]
    }
    runbook:{
      name: split(Runbook_ScheduleUpdatesWithVmsTags.name, '/')[1]
    }
  }
}

param Sched2Guid string = newGuid()
resource ScheduleRunbook_CleanUpSnapshots 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/${Sched2Guid}'
  properties:{
    schedule:{
      name: split(DailySchedule.name, '/')[1]
    }
    runbook:{
      name: split(Runbook_CleanUpSnapshots.name, '/')[1]
    }
  }
}

param Sched3Guid string = newGuid()
resource ScheduleRunbook_CleanUpSchedules 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/${Sched3Guid}'
  properties:{
    schedule:{
      name: split(DailySchedule.name, '/')[1]
    }
    runbook:{
      name: split(Runbook_CleanUpSchedules.name, '/')[1]
    }
  }
}

resource Variable_SendGridAPIKey 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/SendGridAPIKey'
  properties: {
    isEncrypted: true
    value: '"${SendGridAPIKey}"'
  }
}

resource Variable_SendGridSender 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/SendGridSender'
  properties: {
    isEncrypted: false
    value: '"${SendGridSender}"'
  }
}

param assignmentName string = guid(resourceGroup().id)
resource SystemAssignedManagedIdentityRgContributor 'Microsoft.Authorization/roleAssignments@2020-03-01-preview' = {
  name: assignmentName
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: AutomationAccount.identity.principalId
  }
  dependsOn:[
    AutomationAccount
    // Workaround because AutomationAccount.identity.principalId takes time to be available ...
    // This workaround avoid the PrincipalNotFound error message
    Win01
  ]
}
