#/bin/bash

#Desinstalar juegos
sudo apt purge -y 

#Nslookup DNS reales equipo
sudo rm /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
