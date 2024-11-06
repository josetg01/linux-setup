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
modificar_usuario() {
  # Listar usuarios y pedir la selección
  listar_usuarios

  read -p "Selecciona el usuario a modificar: " username_modify
  if [ -z "$username_modify" ]; then
    echo "El nombre de usuario no puede estar vacío."
    return 1
  fi

  # Obtener DN del usuario
  user_dn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "(uid=$username_modify)" dn | awk '/^dn: /{print $2}')
  if [ -z "$user_dn" ]; then
    echo "Usuario no encontrado en LDAP."
    return 1
  fi

  # Obtener los valores actuales del usuario de una sola consulta
  user_info=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "(uid=$username_modify)" sn givenName mail postalCode)
  
  # Extraer los valores actuales
  current_sn=$(echo "$user_info" | grep "^sn: " | awk '{print $2}')
  sn="$current_sn"
  current_givenName=$(echo "$user_info" | grep "^givenName: " | awk '{print $2}')
  givenName="$current_givenName"
  current_mail=$(echo "$user_info" | grep "^mail: " | awk '{print $2}')
  current_postalCode=$(echo "$user_info" | grep "^postalCode: " | awk '{print $2}')

  echo "Introduce los nuevos valores (deja en blanco para no modificar):"
  
  # Pedir los nuevos valores al usuario
  read -p "Nombre (givenName) [actual: $current_givenName]: " new_givenName
  read -p "Apellidos (sn) [actual: $current_sn]: " new_sn
  read -p "Correo (mail) [actual: $current_mail]: " new_mail
  read -p "Código Postal (postalCode) [actual: $current_postalCode]: " new_postalCode

  # Si los valores son vacíos, mantener los actuales
  if [ -z "$new_givenName" ]; then
    new_givenName="$givenName"
  fi
  if [ -z "$new_sn" ]; then
    new_sn="$sn"
  fi
  if [ -z "$new_mail" ]; then
    new_mail="$current_mail"
  fi
  if [ -z "$new_postalCode" ]; then
    new_postalCode="$current_postalCode"
  fi

  # Construir el valor de 'cn' y 'gecos'
  new_cn="$new_givenName $new_sn"
  new_gecos="$new_givenName $new_sn"

  # Escapar los espacios en los valores
  new_givenName=$(echo "$new_givenName" | sed 's/ /\\ /g')
  new_sn=$(echo "$new_sn" | sed 's/ /\\ /g')
  new_cn=$(echo "$new_cn" | sed 's/ /\\ /g')
  new_gecos=$(echo "$new_gecos" | sed 's/ /\\ /g')

  # Crear el archivo LDIF para la modificación
  echo "dn: $user_dn" > /tmp/modificar_user.ldif
  echo "changetype: modify" >> /tmp/modificar_user.ldif

  # Realizar las modificaciones de los atributos en una sola línea de replace
  echo "replace: givenName" >> /tmp/modificar_user.ldif
  echo "givenName: $new_givenName" >> /tmp/modificar_user.ldif
  echo "replace: sn" >> /tmp/modificar_user.ldif
  echo "sn: $new_sn" >> /tmp/modificar_user.ldif
  echo "replace: cn" >> /tmp/modificar_user.ldif
  echo "cn: $new_cn" >> /tmp/modificar_user.ldif
  echo "replace: gecos" >> /tmp/modificar_user.ldif
  echo "gecos: $new_gecos" >> /tmp/modificar_user.ldif

  # Modificar otros campos si se proporcionan nuevos valores
  if [ -n "$new_mail" ]; then
    echo "replace: mail" >> /tmp/modificar_user.ldif
    echo "mail: $new_mail" >> /tmp/modificar_user.ldif
  fi

  if [ -n "$new_postalCode" ]; then
    echo "replace: postalCode" >> /tmp/modificar_user.ldif
    echo "postalCode: $new_postalCode" >> /tmp/modificar_user.ldif
  fi

  # Verificar el contenido del archivo LDIF antes de modificar
  echo "Contenido del archivo LDIF:"
  cat /tmp/modificar_user.ldif

  # Ejecutar la modificación en LDAP
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_user.ldif; then
    echo "Error al modificar el usuario."
  else
    echo "Usuario modificado con éxito."
  fi

  # Limpiar el archivo LDIF
  rm -f /tmp/modificar_user.ldif
}


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
