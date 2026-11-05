#!/bin/bash
# What I ran on the base EC2 instance (Amazon Linux 2023) before making the AMI.

sudo dnf install -y git python3-pip

# grab the app
sudo git clone --branch 2.1 https://github.com/czabriskie/follicle-force-3000.git /opt/follicle-force-3000

# the service runs as root, so the packages have to be installed with sudo
# (this is what fixed the ModuleNotFoundError)
sudo pip3 install -r /opt/follicle-force-3000/app/requirements.txt
sudo pip3 install flask gunicorn

# set it up as a service on port 80 so it starts on boot
sudo cp follicle.service /etc/systemd/system/follicle.service
sudo systemctl daemon-reload
sudo systemctl enable follicle
sudo systemctl start follicle

# should say active (running)
sudo systemctl status follicle
