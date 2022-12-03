#/bin/bash

#Creating a User and a Group
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm

#Adjusting the Current User
sudo usermod -aG gvm $USER

su $USER

#Setting the PATH
export PATH=$PATH:/usr/local/sbin

#Choosing an Install Prefix
export INSTALL_PREFIX=/usr/local

#Creating a Source, Build and Install Directory
export SOURCE_DIR=$HOME/source
mkdir -p $SOURCE_DIR
export BUILD_DIR=$HOME/build
mkdir -p $BUILD_DIR
export INSTALL_DIR=$HOME/install
mkdir -p $INSTALL_DIR

#Installing Common Build Dependencies
sudo apt update
sudo apt install --no-install-recommends --assume-yes \
  build-essential \
  curl \
  cmake \
  pkg-config \
  python3 \
  python3-pip \
  gnupg

#Importing the Greenbone Signing Key
curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc
gpg --import /tmp/GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" > /tmp/ownertrust.txt
gpg --import-ownertrust < /tmp/ownertrust.txt

#Setting the Version
export GVM_VERSION=22.4.0
