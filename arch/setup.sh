#!/bin/bash

#
sudo pacman -Sy --noconfirm git base-devel

if command -v trizen &> /dev/null; then
    echo "trizen ya está instalado."
else
    echo "trizen no está instalado. Iniciando la instalación..."

    # Instalar yay desde AUR
    git clone https://aur.archlinux.org/trizen.git
    cd trizen
    makepkg -si

    # Limpiar el directorio temporal
    cd ..
    sudo rm -rf trizen

    echo "trizen ha sido instalado correctamente."
fi
