#!/bin/bash

yay -S --noconfirm opensc pcsc-tools ccid ca-certificates-dnie configuradorfnmt
sudo systemctl enable pcscd.service
sudo systemctl start pcscd.service
