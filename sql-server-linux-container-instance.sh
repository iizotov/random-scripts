#!/bin/bash

#Creating an azure container instance with SQL Server 2017

#Parameters
LOCATION=eastus
RG=sqlRG
NAME=sqlserver
CPU=2
RAM=4

#Create a Resource Group and pull the SQL Server docker image
az group create --name $RG --location $LOCATION
az container create --name $NAME --image microsoft/mssql-server-linux --resource-group $RG --ip-address public --environment-variables 'ACCEPT_EULA=Y' 'SA_PASSWORD=yourStrong(!)Password' --cpu $CPU --memory $RAM --port 1433

#List Containers
az container list
