#!/usr/bin/env bash

function show_help() {
   # Display Help
   echo "Run this delete resources used to simulate a Purdue Network with its assets, including IoT Edge devices created in IoT Hub"
   echo
   echo "Syntax: ./install_default.sh [-flag=value]"
   echo ""
   echo "List of mandatory flags:"
   echo "-rg        Prefix used for all new Azure Resource Groups created by this script."
   echo "-hubrg            Azure Resource Group with the Azure IoT Hub"
   echo "-hubname          Name of the Azure IoT Hub controlling the IoT Edge devices"
   echo ""
   echo "List of optional flags:"
   echo "-h         Print this help."
   echo "-c         Path to configuration file with IoT Edge VMs information."
   echo "-s         Azure subscription to use to deploy resources."
   echo "-l         Azure region to deploy resources to."
   echo
}

#global variable
scriptFolder=$(dirname "$(readlink -f "$0")")

# Default settings / Initializing all option variables to avoid contamination by variables from the environment.
iotHubResourceGroup=""
iotHubName=""
configFilePath="./config.txt"
location="eastus"
resourceGroupPrefix="iotedge4iiot"
vmSize="Standard_D3_v2" #Standard_B1ms"

while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit;;
        -c=?*)
            configFilePath=${1#*=}
            if [ ! -f "${configFilePath}" ]; then
              echo "Configuration file not found. Exiting."
              exit 1
            fi;;
        -c=)
            echo "Missing configuration file path. Exiting."
            exit;;
        -hubrg=?*)
            iotHubResourceGroup=${1#*=}
            ;;
        -hubrg=)
            echo "Missing IoT Hub resource group. Exiting."
            exit;;
        -hubname=?*)
            iotHubName=${1#*=}
            ;;
        -hubname=)
            echo "Missing IoT Hub name. Exiting."
            exit;;
        -l=?*)
            location=${1#*=}
            ;;
        -l=)
            echo "Missing location. Exiting."
            exit;;
        -s=?*)
            subscription=${1#*=}
            ;;
        -s=)
            echo "Missing subscription. Exiting."
            exit;;
        -rg=?*)
            resourceGroupPrefix=${1#*=}
            ;;
        -rg=)
            echo "Missing resource group prefix. Exiting."
            exit;;
        --)
            shift
            break;;
        *)
            break
    esac
    shift
done

# Derived default settings
networkResourceGroupName="${resourceGroupPrefix}-RG-network"
iotedgeResourceGroupName="${resourceGroupPrefix}-RG-iotedge"

#Verifying that mandatory parameters are there
if [ -z $iotHubResourceGroup ]; then
    echo "Missing IoT Hub resource group. Exiting."
    exit 1
fi
if [ -z $iotHubName ]; then
    echo "Missing IoT Hub name. Exiting."
    exit 1
fi

echo "==========================================================="
echo "==	              Azure Subscription          	 =="
echo "==========================================================="
echo ""
if [ ! -z $subscription ]; then
  az account set --subscription $subscription
fi
subscription=$(az account show --query 'name' -o tsv)
echo "Executing script with Azure Subscription: ${subscription}" 
echo ""

# Parse the configuration file
source ${scriptFolder}/scripts/parseConfigFile.sh $configFilePath

echo "Deleting all IoT Edge devices listed in the configuration file from IoT Hub..."
for (( i=0; i<${#iotEdgeDevices[@]}; i++))
do
    echo "...${iotEdgeDevices[i]}"
    az iot hub device-identity delete --device-id ${iotEdgeDevices[i]} --hub-name $iotHubName
done
echo "done"

echo "Deleting all resource groups..."
az group list --out tsv --tag $resourceGroupPrefix --query 'reverse(sort_by([], &tags.CreationDate)[*].name)' | while read line; do echo "...$line"; az group delete --yes --name $line; done
echo "done"

echo "==========================================================="
echo "==	   All resources have been removed             	 =="
echo "==========================================================="
