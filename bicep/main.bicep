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

resource Runbook_CollectAdvisorScore 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: '${AutomationAccount.name}/CollectAdvisorScore'
  location: Location
  properties:{
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/latj/CollectAdvisorScore/main/runbooks/CollectAdvisorScore.ps1'      
    }
  }
}


resource DailySchedule 'Microsoft.Automation/automationAccounts/schedules@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/CollectAdvisorScaore'
  properties:{
    description: 'Schedule daily'
    startTime: ''
    frequency: 'Day'
    interval: 1
  }
}

resource Variable_AzSqlPassword 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/AzSqlPassword'
  properties: {
    isEncrypted: true
    value: 'djföljsdhfkljsdh'
  }
}

resource Variable_AzSqlLogin 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  name: '${AutomationAccount.name}/AzSqlLogin'
  properties: {
    isEncrypted: false
    value: 'sqladmin'
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
  ]
}
