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






