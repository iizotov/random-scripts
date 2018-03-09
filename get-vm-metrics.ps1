<#
 .SYNOPSIS
    Exports Metrics from Azure VMs for detailed analysis

 .DESCRIPTION
    Exports Metrics from Azure VMs for detailed analysis from either a supplied list of Azure subscription ids, alternatively a full scan will be performed
 
 .PARAMETER scanAllSubscriptions
    Defines whether to scan all available Azure subscriptions

 .PARAMETER subscriptionIds
    Comma-separated list of Azure subscription IDs to extract VM Metrics from

 .PARAMETER startDateTimeUTC
    Metrics history horizon - DateTime in UTC, default = two weeks ago

 .PARAMETER timeGrain
    Metrics grain, example: 00:01:00, 00:05:00, 00:15:00, 01:00:00, etc.

 .PARAMETER metrics
    VM Metrics to extract

 .PARAMETER outputFolder
    Folder to output to (will be created if doesn't exist),
#>
[CmdletBinding(DefaultParameterSetName = "ScanSelectedSubscriptions")]            

param(
    [Parameter(ParameterSetName = 'scanAll', Mandatory = $True)]
    [switch]$scanAllSubscriptions,

    [Parameter(ParameterSetName = 'ScanSelectedSubscriptions', Mandatory = $True)]
    [string[]]$subscriptionIds,

    [Parameter(Mandatory = $False)]
    [System.DateTime]$startDateTimeUTC = (Get-Date).ToUniversalTime().AddDays(-30),
 
    [Parameter(Mandatory = $False)]
    [System.TimeSpan]$timeGrain = "00:05:00",

    [Parameter(Mandatory = $False)]
    [string[]]$metrics = @("Percentage CPU"),
#    [string[]]$metrics = @("Percentage CPU", "Network In", "Network Out", "CPU Credits Remaining", "CPU Credits Consumed"),

    [Parameter(Mandatory = $False)]
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
try {
    $availableSubscriptionIds = (Get-AzureRmSubscription | Where-Object {$_.State -ieq 'Enabled' } ).Id;
}
catch {
    Login-AzureRmAccount
    $availableSubscriptionIds = (Get-AzureRmSubscription | Where-Object {$_.State -ieq 'Enabled' } ).Id;
}


#get available subs
if ($scanAllSubscriptions) {
    $subscriptionIds = $availableSubscriptionIds;  
}

foreach ($subscriptionId in $subscriptionIds) {
    #cleaning up files
    $outputPath = "$($outputFolder)/output-$($subscriptionId).csv";
    Remove-Item -Path $outputPath -ErrorAction SilentlyContinue;
    
    Write-Host "Selecting subscription $subscriptionId";
    Select-AzureRmSubscription -Subscription $subscriptionId -ErrorAction Continue | Out-Null
    foreach ($virtualMachine in Get-AzureRmVM) {
        #Get-AzureRmMetricDefinition -ResourceId $virtualMachine.Id;
        Write-Host "Found $($virtualMachine.Name) in $($subscriptionId)";
        foreach ($metric in Get-AzureRmMetric -ResourceId $virtualMachine.Id -TimeGrain $timeGrain -StartTime $startDateTimeUTC -AggregationType Average -MetricNames $metrics -WarningAction SilentlyContinue -ErrorAction Continue) {
            $metric.data | Select-Object TimeStamp, Average, @{l = "Metric"; e = {$metric.Name.Value}},@{l = "VmSize"; e = {$virtualMachine.HardwareProfile.VmSize}}, @{l = "Id"; e = {$virtualMachine.Id}} | ConvertTo-Csv -Delimiter "," | Select-Object -skip 2 >> $outputPath;
            Write-Host "finished exporting $($metric.Name.Value) for $($virtualMachine.Name) on $($subscriptionId) to $outputPath";
        }
    } 
}

Write-Host "csv outputs are located in $outputFolder";
$outputArchive = $outputFolder + "\output.zip";
Write-Host "compressing outputs to $outputArchive";
Get-ChildItem -Path $outputFolder -Filter *.csv -File | Compress-Archive -Force -DestinationPath $outputArchive;
Write-Host "Done, script exiting";
