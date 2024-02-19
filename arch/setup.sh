#!/bin/bash

#
sudo pacman -Sy --noconfirm git base-devel

if command -v yay &> /dev/null; then
    echo "yay ya está instalado."
else
    echo "yay no está instalado. Iniciando la instalación..."

    # Instalar yay desde AUR
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si

    # Limpiar el directorio temporal
    cd ..
    rm -rf yay

    echo "yay ha sido instalado correctamente."
fi
