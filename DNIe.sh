#!/bin/bash
sudo apt install pcsc-tools pcscd pinentry-gtk2 libccid libnss3-tools -y
sudo wget https://www.dnielectronico.es/descargas/distribuciones_linux/libpkcs11-dnie_1.6.6_amd64.deb
sudo wget https://estaticos.redsara.es/comunes/autofirma/1/7/1/AutoFirma_Linux.zip
sudo unzip AutoFirma_Linux.zip
sudo dpkg -i *.deb
