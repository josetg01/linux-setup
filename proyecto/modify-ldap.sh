#!/bin/bash

# Configuración de variables
LDAP_SERVER="localhost"
BASE_DN="dc=josemaria1,dc=local"
BIND_DN="cn=admin,$BASE_DN"
BIND_PASSWD="alumno"
DOMAIN="josemaria1.local"

#
añadir_objeto(){
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
calc_gid(){
  # Obtener el GID máximo actual
  max_gid=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$BASE_DN" "(objectClass=posixGroup)" gidNumber | grep gidNumber | awk '{print $2}' | sort -n | tail -n 1)

  # Si no hay GIDs, empezar desde 1000 (puedes ajustar esto según tus necesidades)
  if [ -z "$max_gid" ]; then
    new_gid=1000
  else
    new_gid=$((max_gid + 1))
  fi
}
añadir_grupo(){
  read -p "Nombre de grupo: " nomgroup
  new_gid=$(calc_gid)
  echo "El nombre del grupo es: $nomgroup"
  echo "El numero de gid es: $new_gid"
  exit
}
añadir_uo(){
  read -p "Nombre de la unidad Organizativa: " nomuo
  echo "dn: ou=$nomuo,$BASE_DN" > /tmp/uo.ldiff
  echo "objectClass: organizationalUnit" >> /tmp/uo.ldiff
  echo "ou: $nomuo" >> /tmp/uo.ldiff
  sudo ldapadd -x -D cn=admin,$BASE_DN -w $BIND_PASSWD -f /tmp/uo.ldiff
  exit
}
añadir_objeto
