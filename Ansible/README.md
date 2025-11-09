# Ansible

## 1. Install Ansible (WSL)
### 1.1. Update Packages
```
sudo apt update && sudo apt upgrade -y
```
### 1.1. Install Python 
```
sudo apt install -y python3 python3-venv python3-pip
python3 --version
pip3 --version
```
### 1.2. Create venv and activate
```
python3 -m venv venv
source venv/bin/activate
```
### 1.3. Install Ansible
```
pip install --upgrade pip
pip install ansible
ansible --version
```
