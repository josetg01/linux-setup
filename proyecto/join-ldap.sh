#/bin/bash

#Editamos el fichero /etc/ldap.conf
sed -i 's/BASE.*/BASE\t '
sed -i 's/URI.*/URI\t ldap://'
