#!/bin/bash

MY_NETWORK=../network

export FABRIC_CFG_PATH=~/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${MY_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${MY_NETWORK}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${MY_NETWORK}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# 0 환경설정 함수
setOrg() {
    ORG=$1

    echo "Using Organization ${ORG}"
    if [ $ORG -eq 1 ]; then
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
        export CORE_PEER_MSPCONFIGPATH=${MY_NETWORK}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        export CORE_PEER_ADDRESS=localhost:7051
    else
        export CORE_PEER_LOCALMSPID="Org2MSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
        export CORE_PEER_MSPCONFIGPATH=${MY_NETWORK}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        export CORE_PEER_ADDRESS=localhost:9051
    fi
}

# 1 package
echo "package"
set -xe
peer lifecycle chaincode package asset.tar.gz --path /home/bstudent/dev/chaincode/shadow/v1.0 --lang golang --label asset_1.0
set +x

# 2.1 install to org1
echo "install to org1"
setOrg 1
set -x
peer lifecycle chaincode install asset.tar.gz
set +x

# 2.2 install to org2
echo "install to org2"
setOrg 2
set -x
peer lifecycle chaincode install asset.tar.gz
set +x

# 2.3 install 조회
echo "install query"
set -x
peer lifecycle chaincode queryinstalled > log.txt
set +x
cat log.txt
PACKAGE_ID=$(sed -n "/asset_1.0/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

# 3.1 paprove from org1
echo "aprove from org1"
setOrg 1
set -x
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --channelID mychannel --name asset --version 1.0 --package-id ${PACKAGE_ID} --sequence 1
set +x

sleep 3

# 3.2 approve from org2
echo "approve from org2"
setOrg 2
set -x
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --channelID mychannel --name asset --version 1.0 --package-id ${PACKAGE_ID} --sequence 1
set +x

sleep 3

# 4 commit
PEER_PARAMS="--peerAddresses localhost:7051 --tlsRootCertFiles ${PEER0_ORG1_CA} --peerAddresses localhost:9051 --tlsRootCertFiles ${PEER0_ORG2_CA}"
echo "commit from org2"
set -x
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --channelID mychannel --name asset ${PEER_PARAMS} --version 1.0 --sequence 1
set +x

sleep 3

# 4.1 commit 조회
echo "commit query"
set -x
peer lifecycle chaincode querycommitted --channelID mychannel --name asset
set +x

# 5.1 test invoke (CreateAsset)
echo "test  invoke (CreateAsset)"
set -x
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${ORDERER_CA} --channelID mychannel --name asset ${PEER_PARAMS} -c '{"Args":["CreateAsset","asset10","white","13","bstudent","30000"]}'
set +x

sleep 3

# 5.2 test query (ReadAsset)
echo "test query (ReadAsset)"
set -x
peer chaincode query --channelID mychannel --name asset -c '{"Args":["ReadAsset","asset10"]}'
set +x 