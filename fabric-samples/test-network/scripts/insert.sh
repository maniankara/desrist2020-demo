
CHANNEL_NAME="$1"
CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

FABRIC_CFG_PATH=$PWD/../config/

# import utils
. scripts/envVar.sh

CC_SRC_PATH=../../hyperledger-chaincode/dvbtci/

insert1() {
  set -x
  ID=$(echo '111092-221P'|sha256sum|awk {'print $1'})
  DOC=$(sha256sum ../../hyperledger-chaincode/dvbtci/testdata/test_doc.txt |awk {'print $1'})
  set +x
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C mychannel -n dvbtci $PEER_CONN_PARMS -c '{"function":"createCv","Args":["59cc0a6d26db6e14f182282c701ca051870080e3959c530d6b4f52b1f210dd5a", "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4"]}' >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

insert2() {
  set -x
  ID=$(echo '111092-221P'|sha256sum|awk {'print $1'})
  DOC=$(sha256sum ../../hyperledger-chaincode/dvbtci/testdata/test_doc2.txt |awk {'print $1'})
  set +x
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C mychannel -n dvbtci $PEER_CONN_PARMS -c '{"function":"createCv","Args":["59cc0a6d26db6e14f182282c701ca051870080e3959c530d6b4f52b1f210dd5a", "9af1c23321338830741fe7931d4c9a5c0b047a477e502c7aebb67a9329bc5e6e"]}' >&log.txt
  res=$?
  cat log.txt
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
    peer chaincode query -C mychannel -n dvbtci -c '{"Args":["queryAllCvs"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

## Invoke the chaincode
#chaincodeInvokeInit 1 2

#sleep 10

function main {
  if  [ "$1" == "0" ]; then
    echo "Querying chaincode on peer0.org1..."
    chaincodeQuery 1
  elif [ "$1" == "1" ]; then
    insert1 1 2
    echo "Querying chaincode..."
    chaincodeQuery 1
  else
    insert2 1 2
    echo "Querying chaincode..."
    chaincodeQuery 1
  fi
}

main "$@"
