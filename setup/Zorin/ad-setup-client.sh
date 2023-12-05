#/bin/bash

#Instalacion paquetes necesarios
sudo apt update && sudo apt upgrade -y
apt install -y realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

