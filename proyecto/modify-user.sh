#!/bin/bash

# Configuración
LDAP_SERVER="ldap://localhost"
BIND_DN="cn=admin,dc=example,dc=com"
BIND_PW="tu_contraseña"
TARGET_DN="uid=jdoe,ou=users,dc=example,dc=com"

# Crear archivo LDIF
LDIF_FILE="modificaciones.ldif"

# Solicitar nuevos valores
read -p "Introduce el nuevo apellido (sn) [dejar vacío para no modificar]: " NEW_SN
read -p "Introduce el nuevo correo (mail) [dejar vacío para no modificar]: " NEW_MAIL
read -p "Introduce el nuevo teléfono (telephoneNumber) [dejar vacío para no modificar]: " NEW_PHONE

# Preparar contenido LDIF
{
    echo "dn: $TARGET_DN"
    echo "changetype: modify"

    if [[ -n "$NEW_SN" ]]; then
        echo "replace: sn"
        echo "sn: $NEW_SN"
    fi

    if [[ -n "$NEW_MAIL" ]]; then
        echo "replace: mail"
        echo "mail: $NEW_MAIL"
    fi

    if [[ -n "$NEW_PHONE" ]]; then
        echo "add: telephoneNumber"
        echo "telephoneNumber: $NEW_PHONE"
    fi
} > $LDIF_FILE

# Verificar si el archivo LDIF no está vacío
if [[ -s $LDIF_FILE ]]; then
    # Aplicar modificaciones
    ldapmodify -x -H $LDAP_SERVER -D "$BIND_DN" -w "$BIND_PW" -f $LDIF_FILE

    # Comprobar el resultado
    if [ $? -eq 0 ]; then
        echo "Modificaciones aplicadas correctamente."
    else
        echo "Error al aplicar las modificaciones."
    fi
else
    echo "No se realizaron modificaciones. El archivo LDIF está vacío."
fi

# Limpiar
rm -f $LDIF_FILE
