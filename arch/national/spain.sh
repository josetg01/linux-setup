#!/bin/bash

yay -Sy --noconfirm opensc pcsc-tools ccid ca-certificates-dnie configuradorfnmt autofirma-git
sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service
