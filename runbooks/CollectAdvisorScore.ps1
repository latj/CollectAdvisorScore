###############
# DESCRIPTION #
###############

# this script collect Advisor Score recommendation. And Insert them to a Azure database, that need to be pre configured.


#################
# CONFIGURATION #
#################

$Recommendations = 'Cost', 'Security', 'Performance', 'HighAvailability', 'OperationalExcellence', 'Advisor'
$tableName = "dbo.AdvisorScore"
$Type = "Monthly"
$AzSqlLogin = Get-AutomationVariable -Name AzSqlLogin
$AzSqlPassword = Get-AutomationVariable -Name AzSqlPassword


##########
# SCRIPT #
##########

# Connect to Azure with Automation Account system-assigned managed identity
Disable-AzContextAutosave -Scope Process
$AzureContext = (Connect-AzAccount -Identity -WarningAction Ignore).context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


# Generate Access token
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}


# grab all subscription 
$SubscriptionId = Get-AzSubscription

# loop all Subscriptions 
foreach($SubId in $SubscriptionId.Id){
	# Collect data per recommendation
  	foreach($Recommendation in $Recommendations){
   
		# Invoke the Advicor Score REST api
		$restUri = 'https://management.azure.com/subscriptions/' + $SubId + '/providers/Microsoft.Advisor/advisorScore/'+ $Recommendation +'?api-version=2020-07-01-preview'
		$response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader 

		# Filter out only Monthly recommendations
		$Monthly = $response.Properties.timeSeries | Where-Object {$_.aggregationLevel -eq "Monthly"}

		# insert data only if data exists 
      	If ($Monthly) {

        # Collect info from response
        $Date = $Monthly.scoreHistory[0].date
        [decimal]$Score = $Monthly.scoreHistory[0].score
        [decimal]$ConsumptionUnits = $Monthly.scoreHistory[0].consumptionUnits
        [int]$ImpactedResourceCount = $Monthly.scoreHistory[0].impactedResourceCount
        [decimal]$PotentialScoreIncrease = $Monthly.scoreHistory[0].potentialScoreIncrease

        # insert data to Azure SQL
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        # $Connection.ConnectionString = "server='$serverName';database='$databaseName';"
        $Connection.ConnectionString = "Server=tcp:servername.database.windows.net,1433;Initial Catalog=DB01;Persist Security Info=False;User ID='$AzSqlLogin';Password='$AzSqlPassword';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

        $Connection.Open()
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection
        foreach($Name in $Recommendation){
          $insertquery="
          INSERT INTO $tableName
              ([Type],[Recommendations],[Date],[Score],[ConsumptionUnits],[ImpactedResourceCount],[PotentialScoreIncrease],[SubscriptionId])
            VALUES
              ('$Type','$Recommendation','$Date','$Score','$ConsumptionUnits','$ImpactedResourceCount','$PotentialScoreIncrease','$SubId')"
          $Command.CommandText = $insertquery
          $Command.ExecuteNonQuery()
          $Connection.Close();
        }
    }
  }

}



