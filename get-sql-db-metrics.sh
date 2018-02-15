#!/bin/bash

INTERVAL="PT1M"
START=`date -d "-2 weeks" --utc +%FT%TZ`
METRICS="dtu_used storage"
DATABASES=""

OUTPUT=~/data.tgz
OUTPUTDB=~/databases.tsv
OUTPUTMETRICS=~/metrics.tsv

usage() {
    echo "Usage: $0 --all | {[subscription0] [subscription1] ... [subscriptionN]}" 
    echo ""
    echo "This script grabs a min, max, avg history of $METRICS from all SQL DBs in your"
    echo "Azure subscription from $START until now in $INTERVAL increments (e.g. PT5M = every 5 mins)"
    echo "$OUTPUTDB will capture DB info"
    echo "$OUTPUTMETRICS will store the metrics history"
    echo ""
    echo "!!!Please note that the output files will be re-created at each run"
    echo ""
    echo -n "The script requires az cli v2.0.27+, you have: " && az --version | head -1
    echo ""
    echo "Please supply either --all or a space-separated list of Azure subscription IDs to scan through"
    exit -1
}

#validate user input
if [ -z "$1" ]
    then
        usage
        exit -1
fi

#Check if we need to login
az account show && echo "Logged in" || az login

#Clean up before running
rm -f $OUTPUT
rm -f $OUTPUTDB
rm -f $OUTPUTMETRICS

touch $OUTPUTDB || (echo "Cannot create $OUTPUTDB" && exit -1)
touch $OUTPUTMETRICS || (echo "Cannot create $OUTPUTMETRICS" && exit -1)

if [[ "$@" == "--all" ]]
then
    echo "will scan all Azure Subscriptions"
    SUBSCRIPTIONS=`az account list -o tsv --query "[].id"`
else
    echo "will scan the following Azure Subscriptions: $@"
    SUBSCRIPTIONS=$@
fi

for SUBSCRIPTION in $SUBSCRIPTIONS
do
    az account set --subscription "$SUBSCRIPTION"
    echo "setting subscription to $SUBSCRIPTION"
    SERVERS=`az sql server list --query "[].id" --output tsv`
    for SERVER in $SERVERS
    do
        echo "     db server found: $SERVER"
        az sql db list --ids $SERVER --output tsv | grep -v -i "/databases/master" >> $OUTPUTDB
        #getting just DB resource ids excluding the master database
        DATABASES+=`az sql db list --ids $SERVER --query="[].id" --output tsv | grep -v -i "/databases/master$"`
        DATABASES+=" "
    done
done

TOTAL_DB=`cat $OUTPUTDB | wc -l`
echo ""
echo "finished enumerating databases, $TOTAL_DB databases found"

i=0
for DATABASE in $DATABASES
do
    let i++
    for METRIC in $METRICS
    do
        echo "Processing $i/$TOTAL_DB: grabbing $METRIC for $DATABASE"
        az monitor metrics list \
            --resource $DATABASE \
            --output tsv \
            --interval $INTERVAL \
            --start-time $START \
            --aggregation maximum minimum average \
            --metric $METRIC \
            --query="value[].timeseries[].data[].[timeStamp, average, minimum, maximum, '$DATABASE', '$METRIC']" >> $OUTPUTMETRICS
    done 
done

echo "Done, outputs are stored in:"
echo $OUTPUTDB
echo $OUTPUTMETRICS
echo "compressing outputs"
tar -zcvf $OUTPUT $OUTPUTDB $OUTPUTMETRICS
echo ""
echo "finished compressing to $OUTPUT..."

exit 0

