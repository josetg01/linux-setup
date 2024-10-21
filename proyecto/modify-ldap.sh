#!/bin/bash

# Configuración de variables
LDAP_SERVER="localhost"
BASE_DN="dc=josemaria1,dc=local"
BIND_DN="cn=admin,$BASE_DN"
BIND_PASSWD="alumno"
DOMAIN="josemaria1.local"

#
añadir_objecto(){
  
}
añadir_usuario(){
  read -p "Nombre de usuario: " user
  read -p "Nombre: " nombre
  read -p "Apellidos: " apellidos
  read -sp "Contraseña: " password
  echo "El nombre de usuario elegido es: $user"
  echo "El nombre es: $nombre"
  echo "El apellido es: $apellidos"
  echo "El nombre completo es: $nombre apellidos"
  echo "La contraseña del usuario es: $password"
  
}
añadir_grupo(){}
añadir_uo(){}
