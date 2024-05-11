#!/bin/bash
aurhelper=$1
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

# Instalar vmware-workstation
$aurhelper -S --noconfirm vmware-workstation

# Instalar vmware-tools
sudo pacman -S --noconfirm open-vm-tools

sudo modprobe -a vmw_vmci vmmon
sudo systemctl enable vmware-networks vmware-usbarbitrator
sudo systemctl start vmware-networks vmware-usbarbitrator
