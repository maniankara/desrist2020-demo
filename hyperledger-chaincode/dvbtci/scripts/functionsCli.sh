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
TIMEOUT=10

export FABRIC_CFG_PATH=$PWD/fabric-samples/config/
export PATH=$PATH:$PWD/fabric-samples/bin

CC_SRC_PATH="/opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/dvbtci"
LOCAL_CC_SRC_PATH="hyperledger-chaincode/dvbtci"
# import utils
. $LOCAL_CC_SRC_PATH/scripts/envVar.sh

# Vendor it locally before mounting to cli - permission problems
vendorDependencies() {
  CC_RUNTIME_LANGUAGE=golang
  echo Vendoring Go dependencies ...
  pushd $LOCAL_CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  echo Finished vendoring Go dependencies
  cp -r hyperledger-chaincode/dvbtci fabric-samples/chaincode
}

packageChaincode() {
  ORG=$1
  PEER=0
  set -x
  docker exec cli bash -c "
    source ./scripts/utils.sh &&
    CC_SRC_PATH=$CC_SRC_PATH 
    CC_RUNTIME_LANGUAGE=$CC_SRC_LANGUAGE
    packageChaincode $VERSION $PEER $ORG
  "
  set +x
}

# installChaincode PEER ORG
installChaincode() {
  ORG=$1
  PEER=0
  set -x
  docker exec cli bash -c "
    source ./scripts/utils.sh &&
    installChaincode $PEER $ORG
  "
  set +x
}

# queryInstalled and Approve PEER ORG
queryInstalledAndApprove() {
  ORG=$1
  PEER=0
  VERSION=1
  set -x
  docker exec cli bash -c "
    source ./scripts/utils.sh &&
    CHANNEL_NAME=$CHANNEL_NAME
    queryInstalled $PEER $ORG
    approveForMyOrg $VERSION $PEER $ORG
  "
  set +x
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  ORG=$1
  PEER=0
  VERSION=1
  ORG1MSP=$2
  ORG2MSP=$3
  set -x
  docker exec cli bash -c "
    source ./scripts/utils.sh &&
    CHANNEL_NAME=$CHANNEL_NAME
    TIMEOUT=$TIMEOUT
    DELAY=$DELAY
    checkCommitReadiness $VERSION $PEER $ORG Org1MSP.*$ORG1MSP Org2MSP.*$ORG2MSP
  "
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  docker exec -it cli peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $PKG_NAME $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required --channel-config-policy "OR('Org1.peer', 'Org2.peer')"
  res=$?
  set +x
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    docker exec -it cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $PKG_NAME >log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  docker exec -it cli peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $PKG_NAME $PEER_CONN_PARMS --isInit -c '{"Args":["Init"]}' --waitForEvent
  res=$?
  #set +x
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

chaincodeQuery() {
  ORG=$1
  setGlobals $ORG
  echo "===================== Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    docker exec -it cli peer chaincode query -C $CHANNEL_NAME -n $PKG_NAME -c '{"Args":["queryAllCars"]}' 
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}
