modificar_grupo() {
  echo "Grupos existentes:"
  ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(objectClass=posixGroup)" cn gidNumber | \
    awk '/^cn: /{printf "%s\t", $2} /^gidNumber: /{print $2}' | nl

  read -p "Selecciona el número del grupo a modificar: " group_num
  group_dn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$DN_GROUPS" "(objectClass=posixGroup)" cn | \
    awk -v num="$group_num" '/^cn: /{count++} count==num {print "dn: cn="$2","$1}' | sed "s/^/cn=/" | sed "s/^cn=//")

  if [ -z "$group_dn" ]; then
    echo "Grupo no encontrado."
    return
  fi

  # Obtener los valores actuales
  current_cn=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$group_dn" cn | grep "^cn: " | awk '{print $2}')
  current_gidNumber=$(ldapsearch -x -LLL -D "$BIND_DN" -w "$BIND_PASSWD" -b "$group_dn" gidNumber | grep "^gidNumber: " | awk '{print $2}')

  echo "Introduce los nuevos valores (deja en blanco para no modificar):"
  read -p "Nombre del grupo (cn) [actual: $current_cn]: " new_cn
  read -p "GID Number (gidNumber) [actual: $current_gidNumber]: " new_gidNumber

  # Crear el archivo LDIF para la modificación
  echo "dn: $group_dn" > /tmp/modificar_group.ldif
  echo "changetype: modify" >> /tmp/modificar_group.ldif

  # Modificar cn si se proporciona un nuevo valor
  if [ -n "$new_cn" ]; then
    echo "replace: cn" >> /tmp/modificar_group.ldif
    echo "cn: $new_cn" >> /tmp/modificar_group.ldif

    # Cambiar el DN del grupo
    new_group_dn="cn=$new_cn,$DN_GROUPS"
    echo "dn: $group_dn" > /tmp/modificar_dn.ldif
    echo "changetype: modrdn" >> /tmp/modificar_dn.ldif
    echo "newrdn: cn=$new_cn" >> /tmp/modificar_dn.ldif
    echo "deleteoldrdn: 1" >> /tmp/modificar_dn.ldif

    if ! sudo ldapmodrdn -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_dn.ldif; then
      echo "Error al cambiar el DN del grupo."
      rm -f /tmp/modificar_dn.ldif
      return
    else
      echo "DN del grupo cambiado con éxito."
    fi

    rm -f /tmp/modificar_dn.ldif

    group_dn="$new_group_dn"
  fi

  # Modificar gidNumber si se proporciona un nuevo valor
  if [ -n "$new_gidNumber" ]; then
    echo "replace: gidNumber" >> /tmp/modificar_group.ldif
    echo "gidNumber: $new_gidNumber" >> /tmp/modificar_group.ldif
  fi

  # Ejecutar la modificación
  if ! sudo ldapmodify -x -D "$BIND_DN" -w "$BIND_PASSWD" -f /tmp/modificar_group.ldif; then
    echo "Error al modificar el grupo."
  else
    echo "Grupo modificado con éxito."
  fi

  rm -f /tmp/modificar_group.ldif
}

menu_inicio
