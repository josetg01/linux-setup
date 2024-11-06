#!/bin/bash

# Configuración de variables
LDAP_SERVER="localhost"
BASE_DN="dc=josemaria1,dc=local"
BIND_DN="cn=admin,$BASE_DN"
BIND_PASSWD="alumno"
DOMAIN="josemaria1.local"
DN_GROUPS="ou=Groups,$BASE_DN"
DN_USERS="ou=Users,$BASE_DN"

menu_inicio(){
  echo "1) Añadir objeto"
  echo "2) Modificar objeto"
  echo "3) Eliminar objeto"
  read -p "Seleccione una opción [1-3]: " n

  case $n in
    1) añadir_objeto;;
    2) modificar_objeto;;
    3) eliminar_objeto;;
    *) echo "Opción incorrecta"; menu_inicio;;
  esac
}

# Funciones de añadir Objetos
añadir_objeto(){
  echo "1) Añadir Usuario"
  echo "2) Añadir grupo"
  echo "3) Añadir unidad organizativa"
  read -p "Seleccione una opción [1-3]: " n

  case $n in
    1) añadir_usuario;;
    2) añadir_grupo;;
    3) añadir_uo;;
    *) echo "Opción incorrecta"; añadir_objeto;;
  esac
}

calc_uid(){
  # Obtener el UID máximo actual
  max_uid=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$BASE_DN" "(objectClass=inetOrgPerson)" uidNumber | grep uidNumber | awk '{print $2}' | sort -n | tail -n 1)
  # Si no hay UIDs, empezar desde 1000 (ajusta esto si es necesario)
  if [ -z "$max_uid" ]; then
    new_uid=1000
  else
    new_uid=$((max_uid + 1))
  fi
  echo $new_uid
}

calc_initials(){
  # Tomar la cadena de entrada
  fullname="$1"
  # Usar 'awk' para extraer la primera letra de cada palabra
  echo "$fullname" | awk '{ for(i=1; i<=NF; i++) printf substr($i,1,1); }'
}

listar_grupos() {
  echo "Grupos existentes:"
  ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(objectClass=posixGroup)" cn gidNumber | awk '/^cn: /{printf "%s\t", $2} /^gidNumber: /{print $2}'
}

añadir_usuario(){
  read -p "Nombre de usuario: " user
  read -p "Nombre: " nombre
  read -p "Apellidos: " apellidos
  read -p "Introduce el código postal: " postal_code
  echo "Selecciona un grupo para obtener el gidNumber:"
  listar_grupos
  read -p "Ingresa el gidNumber del grupo: " gidNumber

  # Validar gidNumber
  if ! ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(gidNumber=$gidNumber)" | grep -q "gidNumber: $gidNumber"; then
    echo "El gidNumber ingresado no existe."
    return
  fi
  
  read -sp "Contraseña: " password
  
  new_uid=$(calc_uid)
  initials=$(calc_initials "$nombre $apellidos")
  
  echo "dn: uid=$user,$DN_USERS" > /tmp/user.ldif
  echo "objectClass: inetOrgPerson" >> /tmp/user.ldif
  echo "objectClass: posixAccount" >> /tmp/user.ldif
  echo "objectClass: shadowAccount" >> /tmp/user.ldif
  echo "uid: $user" >> /tmp/user.ldif
  echo "sn: $apellidos" >> /tmp/user.ldif
  echo "givenName: $nombre" >> /tmp/user.ldif
  echo "cn: $nombre $apellidos" >> /tmp/user.ldif
  echo "uidNumber: $new_uid" >> /tmp/user.ldif
  echo "gidNumber: $gidNumber" >> /tmp/user.ldif
  echo "userPassword: $password" >> /tmp/user.ldif
  echo "gecos: $nombre $apellidos" >> /tmp/user.ldif
  echo "loginShell: /bin/bash" >> /tmp/user.ldif
  echo "homeDirectory: /home/$user" >> /tmp/user.ldif
  echo "shadowMax: 999999" >> /tmp/user.ldif
  echo "shadowLastChange: 10877" >> /tmp/user.ldif
  echo "mail: $user@$DOMAIN" >> /tmp/user.ldif
  echo "postalCode: $postal_code" >> /tmp/user.ldif
  echo "o: servidor" >> /tmp/user.ldif
  echo "initials: $initials" >> /tmp/user.ldif
  if ! sudo ldapadd -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/user.ldif; then
    echo "Error al añadir el usuario."
  else
    echo "Usuario $user añadido con éxito."
  fi
  rm -f /tmp/user.ldif
}

calc_gid() {
  # Obtener el GID máximo actual
  max_gid=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$BASE_DN" "(objectClass=posixGroup)" gidNumber | grep gidNumber | awk '{print $2}' | sort -n | tail -n 1)
  # Si no hay GIDs, empezar desde 1000 (ajusta esto si es necesario)
  if [ -z "$max_gid" ]; then
    new_gid=1000
  else
    new_gid=$((max_gid + 1))
  fi
  echo $new_gid
}

añadir_grupo(){
  read -p "Nombre de grupo: " nomgroup
  new_gid=$(calc_gid)
  
  # Aquí puedes agregar el comando ldapadd para crear el grupo
  echo "dn: cn=$nomgroup,$DN_GROUPS" > /tmp/grupo.ldif
  echo "objectClass: posixGroup" >> /tmp/grupo.ldif
  echo "cn: $nomgroup" >> /tmp/grupo.ldif
  echo "gidNumber: $new_gid" >> /tmp/grupo.ldif
  sudo ldapadd -x -D $BIND_DN -w $BIND_PASSWD -f /tmp/grupo.ldif
  rm -f /tmp/grupo.ldif
}

añadir_uo(){
  read -p "Nombre de la unidad Organizativa: " nomuo
  echo "dn: ou=$nomuo,$BASE_DN" > /tmp/uo.ldif
  echo "objectClass: organizationalUnit" >> /tmp/uo.ldif
  echo "ou: $nomuo" >> /tmp/uo.ldif
  sudo ldapadd -x -D $BIND_DN -w $BIND_PASSWD -f /tmp/uo.ldif
  rm -f /tmp/uo.ldif
  exit
}

# Funciones de modificar usuarios y grupos
modificar_objeto(){
  echo "1) Modificar Usuario"
  echo "2) Modificar grupo"
  read -p "Seleccione una opción [1-2]: " n

  case $n in
    1) modificar_usuario;;
    2) modificar_grupo;;
    *) echo "Opción incorrecta"; modificar_objeto;;
  esac
}

listar_usuarios() {
  echo "Usuarios existentes:"
  ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "(objectClass=posixAccount)" uid uidNumber | \
    awk '/^uid: /{printf "%s\t", $2} /^uidNumber: /{print $2}'
}
jtorregros
modificar_grupo(){
  echo "Grupos existentes:"
  listar_grupos

  read -p "Ingresa el nombre del grupo a modificar: " old_group_name
  old_dn="cn=$old_group_name,$DN_GROUPS"

  # Verifica si el grupo existe
  if ! ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(cn=$old_group_name)" | grep -q "dn: $old_dn"; then
    echo "El grupo $old_group_name no existe."
    return
  fi

  read -p "Nuevo nombre para el grupo: " new_group_name

  # Generar archivo LDIF para modificar el DN del grupo (cn y dn)
  echo "dn: $old_dn" > /tmp/modificar_grupo_dn.ldif
  echo "changetype: modrdn" >> /tmp/modificar_grupo_dn.ldif
  echo "newrdn: cn=$new_group_name" >> /tmp/modificar_grupo_dn.ldif
  echo "deleteoldrdn: 1" >> /tmp/modificar_grupo_dn.ldif

  # Ejecutar la modificación del DN
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_grupo_dn.ldif; then
    echo "Error al modificar el DN del grupo."
    rm -f /tmp/modificar_grupo_dn.ldif
    return
  else
    echo "DN del grupo modificado con éxito."
  fi

  rm -f /tmp/modificar_grupo_dn.ldif

  # Generar archivo LDIF para otras modificaciones (si es necesario)
  echo "dn: cn=$new_group_name,$DN_GROUPS" > /tmp/modificar_grupo.ldif
  echo "changetype: modify" >> /tmp/modificar_grupo.ldif
  # Agrega aquí otras modificaciones necesarias al grupo
  # echo "replace: description" >> /tmp/modificar_grupo.ldif
  # echo "Nueva descripción del grupo" >> /tmp/modificar_grupo.ldif

  # Si no hay modificaciones adicionales, elimina el archivo temporal y retorna
  if [ $(wc -l < /tmp/modificar_grupo.ldif) -le 2 ]; then
    rm -f /tmp/modificar_grupo.ldif
    return
  fi

  # Ejecutar la modificación
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_grupo.ldif; then
    echo "Error al modificar el grupo."
  else
    echo "Grupo modificado con éxito."
  fi

  rm -f /tmp/modificar_grupo.ldif
}

menu_inicio
