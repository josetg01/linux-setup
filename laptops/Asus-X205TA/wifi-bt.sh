#!/bin/bash
# Download firmware file and install it
wget https://raw.githubusercontent.com/josetg01/ASUS-X205TA/master/Drivers/Inalambrico/brcmfmac43340-sdio.txt -O /lib/firmware/brcm/brcmfmac43340-sdio.txt
wget https://raw.githubusercontent.com/josetg01/ASUS-X205TA/master/Drivers/Inalambrico/BCM43341B0.hcd -O /lib/firmware/brcm/BCM43341B0.hcd

# Create systemd service file
cat >/etc/systemd/system/btattach.service <<EOL
[Unit]
Description=Btattach

[Service]
Type=simple
ExecStart=/usr/bin/btattach --bredr /dev/ttyS1 -P bcm
ExecStop=/usr/bin/killall btattach

[Install]
WantedBy=multi-user.target
EOL

# Enable service
systemctl enable btattach
