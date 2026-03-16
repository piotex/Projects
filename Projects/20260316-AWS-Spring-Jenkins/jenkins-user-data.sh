#!/bin/bash

sudo dnf update -y
sudo dnf install -y java-21-amazon-corretto maven git wget

sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo dnf install -y jenkins

sudo mkdir -p /var/tmp/jenkins
sudo chown jenkins:jenkins /var/tmp/jenkins
sudo chmod 755 /var/tmp/jenkins

sudo mkdir -p /etc/systemd/system/jenkins.service.d

sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.io.tmpdir=/var/tmp/jenkins"
EOF

sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

sudo systemctl status jenkins --no-pager

# sudo mount -o remount,size=2G /tmp