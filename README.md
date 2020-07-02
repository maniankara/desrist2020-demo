# desrist2020-demo
Source code for Blockchain certified Documents for trusted information (BC-DTI) for conference [DESRIST2020](http://desrist2020.org/).
TODO: Fill-in more information about his application/demo

## Repository Overview
* hyperledger-chaincode/ - Contains chaincode for this application
* hyperledger-api-server/ - API server implementation for the chaincode
* website/ - Frontend for the application

## Architecture diagram - High level

<!-- ![Architecture diagram](./desrist2020_arch.png) -->
<img src="./desrist2020_arch_web.png"/>

## Architecture diagram - Hyperledger fabric network v2.0

<!-- ![Architecture diagram](./desrist2020_arch.png) -->
<img src="./desrist2020_arch.png"/>

## Web Interfaces
### University view
<!-- ![Web Interfaces diagram](./DocUpload.png)-->
<img src="./DocUpload.png" width="70%" height="70%"/>

### Recruiter/Verifiers view
<!-- ![Web Interfaces diagram](./webapp/Verification.jpg) -->
<img src="./webapp/Verification.jpg" width="80%" height="80%"/>

## Work flow diagram
<img src="./desrist2020_arch_flow.png" width="80%" height="80%"/>

### Work flow - Uploader
1. The acceptor of the university uploads the document which needs to be inserted to the system.
2. The SHA256 of the document is calculated and awaits for approver for endorsement.
3. The approver verifies the correctness of the document and signs it.
4. This is send to the chaincode which submites the transaction proposal to the orderer.
5. Orderer orders a new transaction and mines a fresh block with the data.

### Work flow - Verifier
1. The verifier uploads the document to be verified from the verification page.
2. The SHA256 of the document is calculated and submits to the chaincode.
3. The chaincode fetches the correct SHA256 of the document from the blockchain and verifies it with the one SHA256 provided by the verifier.
4. The chaincode returns true or false based on check.

## Prerequisites
1. golang >= 1.13.5
2. Hyperledger Fabric = 1.4.4

## Deployment
1. Optional: Install system packages necessary for fabric
```
./run.sh fabric-system
```
2. Install the fabric itself
```
./run.sh fabric-platform
```
3. Get the test network up with default `mychannel`
```
(cd fabric-samples/test-network; ./network.sh down && ./network.sh up createChannel -s couchdb && ./network.sh deployCCCV)
```
4. Verify existing documents in the network
```
(cd fabric-samples/test-network; FABRIC_CFG_PATH=$PWD/../config/ ./scripts/insert.sh 0)
```
5. Insert the `sha256sum` of a test ID (`111092-221P`) and first Document [test_doc.txt](./hyperledger-chaincode/dvbtci/testdata/test_doc.txt)
```
(cd fabric-samples/test-network; FABRIC_CFG_PATH=$PWD/../config/ ./scripts/insert.sh 1)
```
6. Insert the `sha256sum` of a test ID (`111092-221P`) and second Document [test_doc2.txt](./hyperledger-chaincode/dvbtci/testdata/test_doc2.txt)
```
(cd fabric-samples/test-network; FABRIC_CFG_PATH=$PWD/../config/ ./scripts/insert.sh 2)
```
7. The verification can also been seen in the console and also from couchdb of `peer0` or `peer1`
http://localhost:5984 or http://localhost:7984