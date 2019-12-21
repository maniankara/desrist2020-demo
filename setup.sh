#!/bin/bash
set -e

function usage {
    echo "Usage:"
    echo "Setup the application for debian based environments"
    echo "Syntax:"
    echo "./$(basename $0) [fabric|api|website]"
    echo "E.g.:"
    echo "./$(basename $0) fabric # Performs the hyperledger fabric installation"
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
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.0.0-beta 1.4.4 0.4.18
    '
    # Setup path
    echo "export PATH=$PATH:~/hyperledger/fabric-samples/bin" >> ~/.bashrc
    source ~/.bashrc
    # Start the cluster
    (cd fabric-samples/first-network;
    sg - docker -c '
    echo "y" |./byfn.sh generate
    echo "y" |./byfn.sh up
    '
    )
    # Verify fabric platform installation
    echo "----------- Listing active containers --------------"
    sg - docker -c '
    docker ps
    '
}

function fabric {
    # Install the system-level components
    fabric-system "$*"
    # Install hyperledger fabric
    fabric-platform



}

function main {
    if [ "$1" = "" ]; then
        usage
    fi
    $1 $*
}

main "$*"