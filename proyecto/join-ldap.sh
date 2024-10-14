#!/bin/bash

#Configuracion de variables
LDAP_CONF="/etc/ldap/ldap.conf"
NSS_CONF="/etc/nsswitch.conf"

#Instalacion paquetes cliente ldap
sudo DEBIAN_FRONTEND=noninteractive  apt install libnss-ldap libpam-ldap ldap-utils -y

# Verifica que se ha pasado un argumento
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 dominio"
    exit 1
fi

# Lee el dominio
dominio="$1"

# Divide el dominio en partes utilizando el punto como delimitador
IFS='.' read -r -a partes <<< "$dominio"

# Inicializa la variable LDAP
ldap_format=""

# Recorre las partes y las transforma al formato LDAP
for parte in "${partes[@]}"; do
    ldap_format+="dc=${parte},"
done

# Elimina la última coma
ldap_format="${ldap_format%,}"

#Editamos el fichero /etc/ldap.conf
sed -i "s/BASE.*/BASE\t$ldap_format/" $LDAP_CONF
sed -i "s/URI.*/URI\tldap:\/\/ldap.$dominio/" $LDAP_CONF

#Modificamos el fichero "/etc/nsswitch.conf"
sed -i '/^passwd:/s/$/ ldap/' $NSS_CONF
sed -i '/^group:/s/$/ ldap/' $NSS_CONF
sed -i '/^shadow:/s/$/ ldap/' $NSS_CONF

#Añadimos la linea necesaria al fichero common-session
echo "session    optional    pam_mkhomedir.so    skel=/etc/skel   umask=077" >> /etc/pam.d/common-session
