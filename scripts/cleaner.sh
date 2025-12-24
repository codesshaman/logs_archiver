#!/bin/bash

source .env

sudo systemctl stop logs_archiver_$SERVICE_POSTFIX
sudo systemctl disable logs_archiver_$SERVICE_POSTFIX
sudo rm /etc/systemd/system/logs_archiver_$SERVICE_POSTFIX.service
sudo rm /etc/systemd/system/logs_archiver_$SERVICE_POSTFIX.service
sudo rm -rf /usr/local/lib/logs_archiver_$SERVICE_POSTFIX
