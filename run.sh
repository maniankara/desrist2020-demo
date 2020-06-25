#!/bin/bash
set -e



function usage {
    echo "Usage:"
    echo "Setup the application for debian based environments"
    echo "Syntax:"
    echo "./$(basename $0) [fabric|api|website|cc]"
    echo "E.g.:"
    echo "./$(basename $0) fabric-system # Performs the installation of system packages necessary for fabric"
    echo "./$(basename $0) fabric-platform # Performs the installation of hyperledger fabric+fabric-samples and performs network up"
    echo "./$(basename $0) fabric-up # Performs the network up"
    echo "./$(basename $0) fabric-down # Performs the network down"
    echo "./$(basename $0) fabric # Performs fabric-system+fabric-platform in one go"
    echo "./$(basename $0) cc # Performs chaincode installation"
    echo "./$(basename $0) api # Performs the hyperledger fabric api server installation"
    echo "./$(basename $0) website # Performs the frontend installation"
    exit -1
}

function fabric-system {
    # Install docker
    sudo apt update
    sudo apt install -y docker.io
    sudo usermod -a -G docker $USER
    # Install docker-compose
    wget -O- https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m) | sudo tee /usr/local/bin/docker-compose >/dev/null
    sudo chmod a+x /usr/local/bin/docker-compose
    # Install golang
    sudo add-apt-repository ppa:longsleep/golang-backports -y
    sudo apt install golang-go -y
    # Verify system installations
    echo "----------- Installed system packages ---------"
    sg - docker -c '
    docker version;
    docker-compose -v;
    go version;
    '
}

function fabric-platform {
    # Run bootstrap
    echo "----------- Installing hyperledger fabric ----------"
    sg - docker -c '
    curl -sSL https://bit.ly/2ysbOFE | bash -s
    '
    # Setup path
    echo "export PATH=$PATH:$PWD/fabric-samples/bin" >> ~/.bashrc
    source ~/.bashrc
}

function _network-up-down {
    cmd="$1"
    if [ "$1" == "up" ]; then
        cmd="up createChannel -c cvchannel -s couchdb"
    fi
    (cd fabric-samples/test-network;
    sg - docker -c "
    echo 'y' |./network.sh $cmd
    "
    )
    # Verify fabric platform installation
    echo "----------- Listing active containers --------------"
    sg - docker -c '
    docker ps
    '
}

function fabric-up {
    _network-up-down up
}

function fabric-down {
    _network-up-down down
}

function fabric {
    # Install the system-level components
    fabric-system "$*"
    # Install hyperledger fabric
    fabric-platform
}

function cc {
    bash -x ./hyperledger-chaincode/dti/scripts/deployCC.sh
}

function main {
    if [ "$1" = "" -o "$1" = "-h" ]; then
        usage
    fi
    $1 $*
}

main "$*"