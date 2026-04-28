#!/bin/bash
set -e

### =========================
### CONFIG
### =========================
AWS_PROFILE="tech-user"
REGION="eu-central-1"

KEY_NAME="kp-2-$(date +%F)"
PUBLIC_IP=63.176.138.59
ARTEFACT_PATH="demo/target/demo-0.0.1-SNAPSHOT.jar"

export AWS_PROFILE=$AWS_PROFILE

### =========================
### 6. DEPLOY APP
### =========================
echo "===> Copying JAR"

scp -o StrictHostKeyChecking=no -i $KEY_NAME.pem \
    $ARTEFACT_PATH ec2-user@$PUBLIC_IP:/home/ec2-user/demo.jar

echo "===> Remote setup"

ssh -o StrictHostKeyChecking=no -i $KEY_NAME.pem ec2-user@$PUBLIC_IP <<EOF

sudo dnf update -y
sudo dnf install -y java-21-amazon-corretto

sudo mkdir -p /opt/demo
sudo mv /home/ec2-user/demo.jar /opt/demo/demo.jar

cat <<SERVICE | sudo tee /etc/systemd/system/demo.service
[Unit]
Description=Demo Spring Boot App
After=network.target

[Service]
User=ec2-user
ExecStart=/usr/bin/java -jar /opt/demo/demo.jar
SuccessExitStatus=143
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable demo
sudo systemctl restart demo

EOF

### =========================
### DONE
### =========================
echo ""
echo "======================================"
echo "APP RUNNING:"
echo "http://$PUBLIC_IP:8080"
echo "======================================"