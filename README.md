# A Collection of Random Scripts

## [hdi-stop-services.sh](../blob/master/hdi-stop-services.sh)
This Azure HDInsight [script action](https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-hadoop-customize-cluster-linux#use-a-script-action-during-cluster-creation) can be run at run-time or during HDInsight cluster creation to stop the services that you do not require to free up resources

### Usage
```bash
sudo -E bash hdi-stop-services.sh <service0-to-stop> [<service1-to-stop>] [<service2-to-stop>] ... [<serviceN-to-stop>]
```   

## [aws-rds-test-scale.sh](../blob/master/aws-rds-test-scale.sh)
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

2. Install [dbbench](https://github.com/memsql/dbbench):
```bash
sudo apt-get -y install golang
sudo apt-get -y install git

mkdir $HOME/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

go get github.com/memsql/dbbench
```

3. cd into the script directory and run ```bash ./aws-rds-test-scale.sh```

## [sql-server-linux-container-instance.sh](../blob/master/sql-server-linux-container-instance.sh)
A bit of fun really. When [Azure Container Instances](https://azure.microsoft.com/en-gb/services/container-instances/) became available, I thought - wouldn't it be good to try using it for something heavy, like SQL Server 2017 (which was not the idea behind the ACS service, but that's beside the point). This script does just that - pulls a [SQL Server 2017 docker image](https://hub.docker.com/r/microsoft/mssql-server-linux/) and spins up an ACI instance in Azure

### Usage
1. Fire up bash in Azure Cloud Shell on [https://shell.azure.com/](https://shell.azure.com/) - I'm assuming you have an Azure Subscription handy
2. Run the script:
```bash
cd /tmp/
wget https://raw.githubusercontent.com/iizotov/random-scripts/master/sql-server-linux-container-instance.sh
bash /tmp/sql-server-linux-container-instance.sh
```
3. Connect to your SQL using the IP address from the script output, username: ```sa``` and password: ```yourStrong(!)Password```

4. After you're finished playing, tear down by running
```bash
az group delete --name sqlRG -y
```
