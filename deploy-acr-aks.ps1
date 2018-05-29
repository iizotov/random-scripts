<#
 .SYNOPSIS
    This script deploys an ACR and an AKS Cluster
    Feel free to run it locally or in Azure Cloud Shell https://shell.azure.com/powershell 

 .DESCRIPTION
    This script deploys an ACR and an AKS Cluster following the instructions here: https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr
 
 .PARAMETER Silent
    Defines whether values will be prompted interactively or default values will be used
#>
[CmdletBinding(DefaultParameterSetName="Interactive")]   
param(
    [Parameter(ParameterSetName='Interactive', Mandatory=$false)]
    [switch]$Silent
)
<#
.SYNOPSIS
    Propmts for a user input or accepts default
#>
function Read-Default($Prompt, $DefaultValue = '', $SilentlyAcceptDefault = $false) 
{ 
    if ($SilentlyAcceptDefault)
    {
        Write-Host "$($Prompt) = $($defaultValue)"
        return $DefaultValue
    }
    else 
    {
        $pr = Read-Host "$($Prompt) [$($defaultValue)]"
        return ($DefaultValue,$pr)[[bool]$pr]
    }
}
<#
.SYNOPSIS
    Appends a random suffix to a string
#>
function Randomize($String, $Delimiter = '-', $Cnt = 6)
{
    return ("$($String)" + "$($Delimiter)" + -join ((65..90) + (97..122) | Get-Random -Count $Cnt | ForEach-Object {[char]$_})).ToLower()
}

# Check if Azure CLI 2.0 is installed and az aks is available
Write-Host "Checking if Azure CLI 2.0 is installed and az aks is available..."
az aks -h 2>&1 | Out-Null
if (!$?) {
    Write-Error "Azure CLI 2.0 not found, please install from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
    Exit -1 
}

# Check if we're already logged in and skip az login
Write-Host "Checking if we're already logged in..."
az account list --all 2>&1 | Out-Null
if (!$?) {
    az login
}

# Register necessary resource providers
Write-Host "Registering Azure Resource Providers..."
az provider register --name Microsoft.Network
az provider register --name Microsoft.Storage
az provider register --name Microsoft.Compute
az provider register --name Microsoft.ContainerService

# Populate default values
$subscriptionId = az account show --query 'id' -o tsv
$resourceGroup = Randomize "rg-aks"
$aksCluster = Randomize "svc-aks"
$acr = Randomize "svcacr" -Delimiter ""
$aksRegions = az provider show --namespace Microsoft.ContainerService --query "resourceTypes[?resourceType=='managedClusters'].locations | [0]" --output tsv
$region = $aksRegions | Select-Object -First 1
$nodeCount = 1

# Select subscription
az account list --all --output table
$subscriptionId = Read-Default 'Enter Subscription ID' $subscriptionId -SilentlyAcceptDefault $Silent
az account set --subscription $subscriptionId 
Write-Host "Selected subscription $subscriptionId"

# Check if kubectl is installed and install using az aks install-cli
kubectl version 2>&1 | Out-Null

if (!$?) {
    Write-Host 'kubectl not installed, installing...'
    az aks install-cli
}

if (!$?) {
    Write-Host 'kubectl not installed, installing as Administrator...'
    Start-Process -Verb runAs 'az' 'aks install-cli'
}

# Get regions for AKS
Write-Host 'AKS is available in the following regions:'
$aksRegions

# Get user values of skip if non-interactive mode is used
$region = Read-Default -Prompt 'Enter a region to deploy AKS to' $region -SilentlyAcceptDefault $Silent
$resourceGroup = Read-Default 'Enter a gesource group name to deploy AKS to' $resourceGroup -SilentlyAcceptDefault $Silent
$aksCluster = Read-Default 'Enter an AKS cluster name' $aksCluster -SilentlyAcceptDefault $Silent
$nodeCount = Read-Default 'Enter how many worker nodes to deploy' $nodeCount -SilentlyAcceptDefault $Silent
$acr = Read-Default 'Enter an ACR name' $acr -SilentlyAcceptDefault $Silent

# Create an RG
Write-Host "Creating resource group $resourceGroup in $region"
az group create --name $resourceGroup --location $region | Out-Null

# Create an ACR
Write-Host "Please wait... Creating ACR $acr in resource group $resourceGroup"
az acr create --resource-group $resourceGroup --name $acr --sku Basic| Out-Null

# Create an AKS cluster
Write-Host "Please wait... Creating AKS cluster $aksCluster in resource group $resourceGroup"
az aks create --resource-group $resourceGroup --name $aksCluster --node-count $nodeCount --generate-ssh-keys | Out-Null

Write-Host "private key ~/.ssh/id_rsa"
Write-Host
Get-Content ~/.ssh/id_rsa
Write-Host


Write-Host "public key ~/.ssh/id_rsa.pub"
Write-Host
Get-Content ~/.ssh/id_rsa.pub
Write-Host


# Get credentials for AKS
az aks get-credentials --resource-group $resourceGroup --name $aksCluster | Out-Null
Write-Host "~/.kube/config contents:"
Write-Host
Get-Content ~/.kube/config
Write-Host
