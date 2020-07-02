#!/usr/bin/env bash

CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
PKG_NAME="$7"
: ${CHANNEL_NAME:="cvchannel"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="true"}
: ${PKG_NAME:="dvbtci"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`


CC_SRC_PATH="hyperledger-chaincode/dvbtci"
# import utils
. $CC_SRC_PATH/scripts/functionsCli.sh

# Golang related Dependencies
vendorDependencies
## at first we package the chaincode
#packageChaincode 1

## Install chaincode on peer0.org1 and peer0.org2
echo "Installing chaincode on peer0.org1..."
#installChaincode 1
echo "Install chaincode on peer0.org2..."
#installChaincode 2

## query whether the chaincode is installed
#queryInstalledAndApprove 1

## approve the definition for org1
#approveForMyOrg 1

## check whether the chaincode definition is ready to be committed
## expect org1 to have approved and org2 not to
checkCommitReadiness 1 "true" "false"
exit 1
checkCommitReadiness 2 "true" "false"

## now approve also for org2
approveForMyOrg 1 0 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 0 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
checkCommitReadiness 1 0 2 "\"Org1MSP\": true" "\"Org2MSP\": true"
checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

## now approve also for org2
approveForMyOrg 2

## check whether the chaincode definition is ready to be committed
## expect them both to have approved
checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition 1 2

## query on both orgs to see that the definition committed successfully
queryCommitted 1
queryCommitted 2

## Invoke the chaincode
chaincodeInvokeInit 1 2

sleep 10

# Query chaincode on peer0.org1
echo "Querying chaincode on peer0.org1..."
chaincodeQuery 1

exit 0
