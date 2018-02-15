<#
 .SYNOPSIS
    Exports Metrics from Azure SQL DB Databases for detailed analysis

 .DESCRIPTION
    Exports Metrics from Azure SQL DB Databases for detailed analysis from either a supplied list of Azure subscription ids, alternatively a full scan will be performed
 
 .PARAMETER scanAllSubscriptions
    Defines whether to scan all available Azure subscriptions

 .PARAMETER subscriptionIds
    Comma-separated list of Azure subscription IDs to extract SQL SB Metrics from

 .PARAMETER startDateTimeUTC
    Metrics history horizon - DateTime in UTC, default = two weeks ago

 .PARAMETER timeGrain
    Metrics grain, example: 00:01:00, 00:05:00, 00:15:00, 01:00:00, etc.

 .PARAMETER metrics
    SQL DB Metrics to extract

 .PARAMETER outputFolder
    Folder to output to (will be created if doesn't exist),
#>
[CmdletBinding(DefaultParameterSetName="ScanSelectedSubscriptions")]            

param(
 [Parameter(ParameterSetName='scanAll', Mandatory=$True)]
 [switch]$scanAllSubscriptions,

 [Parameter(ParameterSetName='ScanSelectedSubscriptions', Mandatory=$True)]
 [string[]]$subscriptionIds,

 [Parameter(Mandatory=$False)]
 [System.DateTime]$startDateTimeUTC = (Get-Date).ToUniversalTime().AddDays(-14),
 
 [Parameter(Mandatory=$False)]
 [System.TimeSpan]$timeGrain = "00:05:00",

 [Parameter(Mandatory=$False)]
 [string[]]$metrics = @("storage","dtu_used"),

 [Parameter(Mandatory=$False)]
 [string]$outputFolder = ".\output"
)


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
New-Item $outputFolder -ItemType directory -ErrorAction SilentlyContinue | Out-Null;

$outputFolder = (Resolve-Path $outputFolder).Path;

# sign in
Write-Host "Logging in...";
try
{
    $availableSubscriptionIds = (Get-AzureRmSubscription | Where-Object {$_.State -ieq 'Enabled' } ).Id;
}
catch {
    Login-AzureRmAccount
    $availableSubscriptionIds = (Get-AzureRmSubscription | Where-Object {$_.State -ieq 'Enabled' } ).Id;
}


#get available subs
if($scanAllSubscriptions) {
    $subscriptionIds = $availableSubscriptionIds;  
}
else {

}

foreach($subscriptionId in $subscriptionIds) {
    #cleaning up files
    $outputPath = "$($outputFolder)/output-$($subscriptionId).csv";
    Remove-Item -Path $outputPath -ErrorAction SilentlyContinue;
    
    Write-Host "Selecting subscription $subscriptionId";
    Select-AzureRmSubscription -Subscription $subscriptionId -ErrorAction Continue | Out-Null
    foreach($sqlServer in Get-AzureRmSqlServer) {
		foreach($sqlDatabase in Get-AzureRmSqlDatabase -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName) {
			if($sqlDatabase.DatabaseName -ine "master") {
				#"SQL databases," + $sqlDatabase.Name + ",Online"  | out-file $OutFilePath -encoding ascii -append
                Write-Host "Found $($sqlDatabase.DatabaseName) on $($sqlDatabase.ServerName)";
			    foreach($metric in Get-AzureRmMetric -ResourceId $sqlDatabase.ResourceId -TimeGrain $timeGrain -StartTime $startDateTimeUTC -AggregationType Average -MetricNames $metrics -WarningAction SilentlyContinue -ErrorAction Continue){
                    $metric.data | select TimeStamp,Average, @{l="Metric";e={$metric.Name.Value}}, @{l="Server";e={$sqlDatabase.ServerName}},@{l="Database";e={$sqlDatabase.DatabaseName}},@{l="DbSize";e={$sqlDatabase.CurrentServiceObjectiveName}} | ConvertTo-Csv -Delimiter "," | select -skip 2 >> $outputPath;
                    Write-Host "finished exporting $($metric.Name.Value) for $($sqlDatabase.DatabaseName) on $($sqlDatabase.ServerName) to $outputPath";
                }
            }
		}
	} 
}

Write-Host "csv outputs are located in $outputFolder";
$outputArchive = $outputFolder + "\output.zip";
Write-Host "compressing outputs to $outputArchive";
Get-ChildItem -Path $outputFolder -Filter *.csv -File | Compress-Archive -Force -DestinationPath $outputArchive;
Write-Host "Done, script exiting";
