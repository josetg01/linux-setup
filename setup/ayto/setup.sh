#/bin/bash
sudo rm /etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo apt update && sudo apt upgrade -y
curl https://raw.githubusercontent.com/josetg01/linux-setup/main/setup/$(lsb_release -si)/delete-games-$(lsb_release -sr).sh | bash
sudo apt autoremove -y

#Repositorio Google Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

#Repositorio de Firefox
sudo add-apt-repository ppa:mozillateam/ppa -y

#Establecer nombre de equipo con dominio.
read -p "Escribe el numero del equipo: " numpc
read -p "Escriba el dominio a utilizar: " dominio

cat > /etc/hostname <<EOL
PC$numpc.$dominio
EOL

cat > /etc/hosts <<EOL
127.0.0.1 localhost
127.0.1.1 PC$numpc

#The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOL

#Instalacion y configurador de VNC
sudo apt install -y x11vnc
read -p "Escribe la contraseñar a usar para VNC: " vncpass
cat > /lib/systemd/system/x11vnc.service <<EOL
[Unit]
Description=x11vnc service
After=display-manager.service network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess -passwd $vncpass
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

#Instalacion de software
sudo apt install -y firefox-esr firefox-esr-locale-{en,es} vlc openjdk-8-jre
