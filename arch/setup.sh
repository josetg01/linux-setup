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

function vmware-wstation () {
yay -Sy --noconfirm vmware-workstation

# Detectar el tipo de kernel instalado
if pacman -Q | grep -q linux-zen; then
    echo "Kernel Zen detectado."
    KERNEL_TYPE="zen"
elif pacman -Q | grep -q linux-lts; then
    echo "Kernel LTS detectado."
    KERNEL_TYPE="lts"
else
    echo "Kernel genérico detectado."
    KERNEL_TYPE="generic"
fi

# Instalar los encabezados correspondientes al kernel
if [ "$KERNEL_TYPE" == "zen" ]; then
    sudo pacman -S linux-zen-headers
elif [ "$KERNEL_TYPE" == "lts" ]; then
    sudo pacman -S linux-lts-headers
else
    sudo pacman -S linux-headers
fi

sudo modprobe -a vmw_vmci vmmon
sudo systemctl enable vmware-networks vmware-usbarbitrator
sudo systemctl start vmware-networks vmware-usbarbitrator
}
