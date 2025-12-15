#!/bin/bash

sudo systemctl stop logs_archiver_prod
sudo systemctl disable logs_archiver_prod
sudo rm /etc/systemd/system/logs_archiver_prod.service
sudo rm /etc/systemd/system/logs_archiver_prod.service
sudo rm -rf /usr/local/lib/logs_archiver_prod
