#!/bin/bash

# Configuración de variables
LDAP_SERVER="localhost"
BASE_DN="dc=josemaria1,dc=local"
BIND_DN="cn=admin,$BASE_DN"
BIND_PASSWD="alumno"
DOMAIN="josemaria1.local"

#
añadir_objecto(){
  echo "1) Añadir Usuario"
  echo "2) Añadir grupo"
  echo "3) Añadir unidad organizativa"
  read -p "Selecione una opcion [1-3]: " n

  case $n in
    1) añadir_usuario;;
    2) añadir_grupo;;
    3) añadir_uo;;
    *) echo "Opción incorrecta";;
  esac
}
añadir_usuario(){
  read -p "\nNombre de usuario: " user
  read -p "Nombre: " nombre
  read -p "Apellidos: " apellidos
  read -sp "Contraseña: " password
  echo "El nombre de usuario elegido es: $user"
  echo "El nombre es: $nombre"
  echo "El apellido es: $apellidos"
  echo "El nombre completo es: $nombre $apellidos"
  echo "La contraseña del usuario es: $password"
  exit 0
}
añadir_grupo(){
  read -p "Nombre de grupo: " nomgroup
  echo "El nombre del grupo es: $nomgroup"
  
}
añadir_uo(){}
añadir_objecto
