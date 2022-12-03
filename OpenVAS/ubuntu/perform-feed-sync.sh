#/bin/bash

#Downloading Vulnerability Tests
sudo -u gvm greenbone-nvt-sync

#Downloading SCAP, CERT and GVMD Data
sudo -u gvm greenbone-feed-sync --type SCAP
sudo -u gvm greenbone-feed-sync --type CERT
sudo -u gvm greenbone-feed-sync --type GVMD_DATA

#Starting the Greenbone Community Edition Services
sudo systemctl start notus-scanner
sudo systemctl start ospd-openvas
sudo systemctl start gvmd
sudo systemctl start gsad


