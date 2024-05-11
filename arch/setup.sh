#!/bin/bash

aurhelper="yay"

# Función para verificar si un paquete está instalado
package_installed() {
    pacman -Q "$1" &> /dev/null
}

    sudo pacman -Sy

# Verificar si ya se ha solicitado la contraseña de sudo en esta sesión
if ! sudo -n true 2>/dev/null; then
    # Si no se ha solicitado, solicitarla y mantenerla válida
    echo "Por favor, ingresa tu contraseña de sudo:"
    sudo -v
    # Comprobar si la contraseña es correcta
    if [ $? -ne 0 ]; then
        echo "La contraseña de sudo es incorrecta. Inténtalo de nuevo."
        exit 1
    fi
fi

# Verificar si tk está instalado
if ! package_installed tk; then
    echo "El paquete tk no está instalado. Instalando..."
    sudo pacman -S --noconfirm tk
fi

# Verificar si python-pexpect está instalado
if ! package_installed python-pexpect; then
    echo "El paquete python-pexpect no está instalado. Instalando..."
    sudo pacman -S --noconfirm python-pexpect
fi

# Verificar si python-pillow está instalado
if ! package_installed python-pillow; then
    echo "El paquete python-pillow no está instalado. Instalando..."
    sudo pacman -S --noconfirm python-pillow
fi

# Verificar si está instalado el aur helper
if ! package_installed $aurhelper; then
    echo "El paquete $aurhelper no está instalado. Instalando..."
    # Instalar dependencias necesarias para construir Trizen
    sudo pacman -S --needed --noconfirm base-devel git

    # Clonar el repositorio de Trizen desde GitHub
    git clone https://aur.archlinux.org/$aurhelper.git

    # Cambiar al directorio de Trizen
    cd trizen

    # Compilar e instalar Trizen
    makepkg -si --noconfirm

    # Regresar al directorio anterior
    cd ..

    # Eliminar el directorio clonado de Trizen
    rm -rf trizen

    echo "Trizen se ha instalado correctamente y el directorio de Git ha sido eliminado."
fi
python3 setup.py $aurhelper
