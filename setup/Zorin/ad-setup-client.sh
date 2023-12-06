#/bin/bash
read -p "Nombre de equipo: " nombrepc
read -p "Dominio Windows: " dominio
read -p "Usuario para unir al dominio: " userdomain
read -s -p "Contraseña del usuario para unir al dominio" passwduserdomain
#Instalacion paquetes necesarios
sudo apt update && sudo apt upgrade -y
apt install -y realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

#
sudo hostnamectl set-hostname $nombrepc.$dominio
sudo realm join -v -U $userdomain $dominio --one-time-password=passwduserdomain
sudo pam-auth-update --enable mkhomedir
