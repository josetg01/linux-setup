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

modificar_usuario() {
  echo "Usuarios existentes:"
  ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "(objectClass=inetOrgPerson)" uid | \
    awk '/^uid: /{printf "%s\t", $2} /^cn: /{print $2}' | nl

  read -p "Selecciona el número del usuario a modificar: " user_num
  user_dn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "(objectClass=inetOrgPerson)" uid | \
    awk -v num="$user_num" '/^uid: /{count++} count==num {print "uid="$2","$1}' | sed "s/^/uid=/" | sed "s/^uid=//")

  if [ -z "$user_dn" ]; then
    echo "Usuario no encontrado."
    return
  fi

  # Obtener los valores actuales
  current_sn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "$user_dn" sn | grep "^sn: " | awk '{print $2}')
  sn="$current_sn"
  current_givenName=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "$user_dn" givenName | grep "^givenName: " | awk '{print $2}')
  givenName="$current_givenName"

  echo "Introduce los nuevos valores (deja en blanco para no modificar):"
  read -p "Nombre (givenName) [actual: $current_givenName]: " new_givenName
  read -p "Apellidos (sn) [actual: $current_sn]: " new_sn
  read -p "Correo (mail) [actual: $(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "$user_dn" mail | grep "^mail: " | awk '{print $2}')]: " new_mail
  read -p "Código Postal (postalCode) [actual: $(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_USERS" "$user_dn" postalCode | grep "^postalCode: " | awk '{print $2}')]: " new_postalCode

  # Crear el archivo LDIF para la modificación
  echo "dn: $user_dn" > /tmp/modificar_user.ldif
  echo "changetype: modify" >> /tmp/modificar_user.ldif

  # Modificar givenName y sn si se proporcionan nuevos valores
  if [ -n "$new_givenName" ] || [ -n "$new_sn" ]; then
    if [ -n "$new_givenName" ]; then
      echo "replace: givenName" >> /tmp/modificar_user.ldif
      echo "givenName: $new_givenName" >> /tmp/modificar_user.ldif
      givenName="$new_givenName"
    fi

    if [ -n "$new_sn" ]; then
      echo "replace: sn" >> /tmp/modificar_user.ldif
      echo "sn: $new_sn" >> /tmp/modificar_user.ldif
      sn="$new_sn"
    fi

    # Modificar cn y gecos si se cambian givenName o sn
    new_cn="$givenName $sn"
    echo "replace: cn" >> /tmp/modificar_user.ldif
    echo "cn: $new_cn" >> /tmp/modificar_user.ldif
    echo "replace: gecos" >> /tmp/modificar_user.ldif
    echo "gecos: $new_cn" >> /tmp/modificar_user.ldif
  fi

  # Modificar otros campos si se proporcionan nuevos valores
  if [ -n "$new_mail" ]; then
    echo "replace: mail" >> /tmp/modificar_user.ldif
    echo "mail: $new_mail" >> /tmp/modificar_user.ldif
  fi

  if [ -n "$new_postalCode" ]; then
    echo "replace: postalCode" >> /tmp/modificar_user.ldif
    echo "postalCode: $new_postalCode" >> /tmp/modificar_user.ldif
  fi

  # Ejecutar la modificación
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_user.ldif; then
    echo "Error al modificar el usuario."
  else
    echo "Usuario modificado con éxito."
  fi

  rm -f /tmp/modificar_user.ldif
}
modificar_grupo() {
  echo "Grupos existentes:"
  ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(objectClass=posixGroup)" cn gidNumber | \
    awk '/^cn: /{printf "%s\t", $2} /^gidNumber: /{print $2}' | nl

  read -p "Selecciona el número del grupo a modificar: " group_num
  group_dn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(objectClass=posixGroup)" cn | \
    awk -v num="$group_num" '/^cn: /{count++} count==num {print "cn="$2","$1}' | sed "s/^/cn=/" | sed "s/^cn=//")

  if [ -z "$group_dn" ]; then
    echo "Grupo no encontrado."
    return
  fi

  # Obtener el gidNumber y cn actual
  current_gidNumber=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "$group_dn" gidNumber | grep "^gidNumber: " | awk '{print $2}')
  current_cn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "$group_dn" cn | grep "^cn: " | awk '{print $2}')

  echo "Introduce los nuevos valores (deja en blanco para no modificar):"
  read -p "Nombre del grupo (cn) [actual: $current_cn]: " new_cn
  # Deshabilitar la modificación del gidNumber
  echo "No se puede modificar el gidNumber. El actual es: $current_gidNumber"

  # Crear el archivo LDIF para la modificación
  echo "dn: $group_dn" > /tmp/modificar_grupo.ldif
  echo "changetype: modify" >> /tmp/modificar_grupo.ldif

  # Modificar cn si se proporciona un nuevo valor
  if [ -n "$new_cn" ]; then
    # Actualizar el dn si se cambia el cn
    new_group_dn="cn=$new_cn,$DN_GROUPS"
    echo "replace: cn" >> /tmp/modificar_grupo.ldif
    echo "cn: $new_cn" >> /tmp/modificar_grupo.ldif
  fi

  # Ejecutar la modificación del grupo
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_grupo.ldif; then
    echo "Error al modificar el grupo."
  else
    echo "Grupo modificado con éxito."

    # Si se cambió el cn, también actualizamos el dn
    if [ -n "$new_cn" ]; then
      echo "Renombrando el grupo en LDAP..."
      sudo ldapmodrdn -x -D "$BIND_DN" -w "$BIND_PASSWD" "$group_dn" "cn=$new_cn"
    fi
  fi

  rm -f /tmp/modificar_grupo.ldif
}

menu_inicio
