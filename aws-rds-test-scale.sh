#!/bin/bash

# The idea for the script is to measure how much outage can happen when scaling (modifing vCPU/RAM and/or size) 
# of AWS Mysql RDS or Mysql Aurora instances.
# It continuoursly puts the database(s) under load using dbbench and reattempts to connect when it's down
# whilst logging everything

# parameters
PORT=3306
HOSTS=(
    iizotovaurora-cluster.cluster-cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com\
    iizotovmysqlnoaz.cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com\
    iizotovmysqlaz.cdr1dtourrqx.ap-southeast-2.rds.amazonaws.com
)
ROLES=(
    "AuroraMysql"\
    "RDSMysqlSingle-AZ"\
    "RDSMysqlMulti-AZ"
)

echo -n "Enter Username: "
read USER

read -s -p "Enter Password: " PWD
echo

# define test script
temp_file=$(mktemp)
cat > ${temp_file} <<- EOM
[setup]
query=create database if not exists test
query=create table if not exists test.test_table(a int)
query=truncate table test.test_table

[burst insert]
query=insert into test.test_table values (FLOOR(RAND() * 400) + 100)
batch-size=10
rate=10

[burst select]
query=select sum(a) from test.test_table
batch-size=10
rate=10
EOM
echo "the test script is located in ${temp_file}"
echo

# do some work - launch all tests as background threads
I=0
for HOST in "${HOSTS[@]}"
do
    ROLE=${ROLES[$I]}
    LOG=/tmp/${ROLE}.log
    rm -f ${LOG}
    echo "testing ${ROLE}, log: ${LOG}"
    let I=I+1
    PREPCOMMAND="mkdir -p \$HOME/go; export GOPATH=\$HOME/go; export PATH=\$PATH:\$GOPATH/bin"
    COMMAND="dbbench -password ${PWD} -username ${USER} -host ${HOST} -port ${PORT} -intermediate-stats-interval .1s -max-active-conns 20 -max-idle-conns 50 ${temp_file}"
    nohup bash -c "echo ${PREPCOMMAND}; while true; do ${COMMAND}; sleep .1; done" > ${LOG} &
    sleep .5
done

# cleanup and wrap
cat << EOM

Tests are still running in the backround... Now modify the RDS instances as required (resize, etc)
To stop, run
pkill -f dbbench
...and analyse the logs...
echo /tmp/*.log | grep -i error
EOM

# end of script