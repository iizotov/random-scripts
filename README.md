# A Collection of Random Scripts

## [deploy-acr-aks.ps1](../master/deploy-acr-aks.ps1)

This script deploys an Azure Container Registry (ACR) and a managed Kubernetes Cluster (AKS) following the instructions from [here](https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr)

### Usage

> make sure to install [azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) first

* run interactively if no parameters are supplied:
    ```powershell
    .\deploy-acr-aks.ps1
    ```

* run non-interactively using default values (subscriptions, regions, etc) if `-Silent` is supplied. You may still need to authenticate your CLI session. By default the number of nodes = 1:
    ```powershell
    .\deploy-acr-aks.ps1 -Silent
    ```
* You're more than welcome to run it in [Azure Cloud Shell](https://azure.microsoft.com/en-au/features/cloud-shell/)

    [![Launch Cloud Shell](https://shell.azure.com/images/launchcloudshell.png "Launch Cloud Shell")](https://shell.azure.com/powershell)

    ```powershell
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/iizotov/random-scripts/master/deploy-acr-aks.ps1'))
    ```

## [get-sql-db-metrics.ps1](../master/get-sql-db-metrics.ps1)

This powershell script exports metrics for detailed analysis from all Azure SQL DB Databases:

* from either a supplied list of Azure subscription ids (comma-separated) if `-subscriptionIds` is supplied:

    ```powershell
    .\get-sql-db-metrics.ps1 -subscriptionIds cb7539f6-f98d-4092-a53e-149daff8ba5d,eaca98dc-dead-4803-af35-f0edb23e0537
    ```

* alternatively a full scan will be performed if `-scanAllSubscriptions` is supplied:
    ```powershell
    .\get-sql-db-metrics.ps1 -scanAllSubscriptions
    ```
Metrics are exported as csv files to a specified folder

### Usage

> make sure to install [azure powershell tools](https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-5.2.0) first

```powershell
.\get-sql-db-metrics.ps1 -subscriptionIds <String[]> [-startDateTimeUTC <DateTime>] [-timeGrain <TimeSpan>] [-metrics <String[]>] [-outputFolder <String>] [<CommonParameters>]
```

or if you want to scan all available subscriptions, use

```powershell
.\get-sql-db-metrics.ps1 -scanAllSubscriptions  [-startDateTimeUTC <DateTime>] [-timeGrain <TimeSpan>] [-metrics <String[]>] [-outputFolder <String>] [<CommonParameters>]
```

To get detailed help, use

```powershell
Get-Help .\get-sql-db-metrics.ps1 -full
```

## [get-vm-metrics.ps1](../master/get-vm-metrics.ps1)

A variation of the [get-sql-db-metrics.ps1](../master/get-sql-db-metrics.ps1) script for Azure VMs

## [get-sql-db-metrics.sh](../master/get-sql-db-metrics.sh)

A linux Azure CLI version of the [get-sql-db-metrics.ps1](../master/get-sql-db-metrics.ps1) script. Make sure to install [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.0.27 or above 

## [aws-rds-test-scale.sh](../master/aws-rds-test-scale.sh)

The idea for the script is to measure outage when a scale operation (vCPU/RAM/db size change) hits an AWS RDS MySQL or Aurora instances. It continuously generates load on the database(s)  using [dbbench](https://github.com/memsql/dbbench), attempts to reconnect when it's down whilst logging everything. 

It's best to test a bunch of RDS instance types to be able to compare results:

* single-AZ
* multi-AZ

## [hdi-stop-services.sh](../master/hdi-stop-services.sh)

This Azure HDInsight [script action](https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-hadoop-customize-cluster-linux#use-a-script-action-during-cluster-creation) can be run at run-time or during HDInsight cluster creation to stop the services that you do not require to free up resources

### Usage

```bash
sudo -E bash hdi-stop-services.sh <service0-to-stop> [<service1-to-stop>] [<service2-to-stop>] ... [<serviceN-to-stop>]
```

## [aws-rds-test-scale.sh](../master/aws-rds-test-scale.sh)

The idea for the script is to measure outage when a scale operation (vCPU/RAM/db size change) hits an AWS RDS MySQL or Aurora instances. It continuously generates load on the database(s)  using [dbbench](https://github.com/memsql/dbbench), attempts to reconnect when it's down whilst logging everything. 

It's best to test a bunch of RDS instance types to be able to compare results:

* single-AZ
* multi-AZ

### Usage

1. Edit the script to reflect your setup - you can have as many hosts and roles as possible, as long as the number of hosts matches the number of roles:

    ```bash
    HOSTS=(
        "iizotovaurora-cluster.cluster-cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com"\
        "iizotovmysqlnoaz.cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com"\
        "iizotovmysqlaz.cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com"
    )
    ROLES=(
        "AuroraMysql"\
        "RDSMysqlSingle-AZ"\
        "RDSMysqlMulti-AZ"
    )
    ```

1. Install [dbbench](https://github.com/memsql/dbbench):

    ```bash
    sudo apt-get -y install golang
    sudo apt-get -y install git

    mkdir $HOME/go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    go get github.com/memsql/dbbench
    ```

1. cd into the script directory and run ```bash ./aws-rds-test-scale.sh```

## [sql-server-linux-container-instance.sh](../master/sql-server-linux-container-instance.sh)

A bit of fun really. When [Azure Container Instances](https://azure.microsoft.com/en-gb/services/container-instances/) became available, I thought - wouldn't it be good to try using it for something heavy, like SQL Server 2017 (which was not the idea behind the ACS service, but that's beside the point). This script does just that - pulls a [SQL Server 2017 docker image](https://hub.docker.com/r/microsoft/mssql-server-linux/) and spins up an ACI instance in Azure

### Usage

1. Fire up bash in Azure Cloud Shell on [https://shell.azure.com/](https://shell.azure.com/) - I'm assuming you have an Azure Subscription handy
1. Run the script:

    ```bash
    cd /tmp/
    wget https://raw.githubusercontent.com/iizotov/random-scripts/master/sql-server-linux-container-instance.sh
    bash /tmp/sql-server-linux-container-instance.sh
    ```

1. Connect to your SQL using the IP address from the script output, username: ```sa``` and password: ```yourStrong(!)Password```

1. After you're finished playing, tear down by running

    ```bash
    az group delete --name sqlRG -y
    ```
