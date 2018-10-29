<# 
  Needs to be run locally (assuming that .\SkuRecommendationDataCollectionScript.ps1 has been 
  copied to all machines involved in your analysis) to $ScriptDir below
  
  Modify the $ConnString accordingly
  
  get .\SkuRecommendationDataCollectionScript.ps1 from C:\Program Files\Microsoft Data Migration Assistant
  
  get Microsoft Data Migration Assistant from https://www.microsoft.com/en-us/download/details.aspx?id=53595 
#>

# Execution timestamp
$Timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}

# Script Location
$ScriptDir = "c:\tmp"

# Output location
$OutputDir = "c:\tmp\" + $env:computername + $Timestamp

# Connection string (SQL admin user)
$ConnString = "Server=localhost;Initial Catalog=master;User Id=***;Password=***"

# perf counter collection duration (min 40 mins)
$Duration = 2400

# Main body
cd $ScriptDir
mkdir $OutputDir -ErrorAction Ignore

.\SkuRecommendationDataCollectionScript.ps1 `
    -ComputerName localhost `
    -OutputFilePath ($OutputDir + "\perf.csv") `
    -CollectionTimeInSeconds $Duration `
    -DbConnectionString $ConnString 
