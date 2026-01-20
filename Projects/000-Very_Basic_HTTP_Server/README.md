# Very Basic Http Server Setup

## 1. Make sure you have python installed

### CentOS
```bash
sudo dnf update -y
sudo dnf groupinstall "Development Tools" -y
sudo dnf install -y wget openssl-devel libffi-devel bzip2-devel

wget https://www.python.org/ftp/python/3.13.3/Python-3.13.3.tgz
tar xvf Python-3.13.3.tgz
cd Python-3.13.3

./configure --enable-optimizations --prefix=/usr/local --enable-shared

make clean
sudo make altinstall

sudo /usr/local/bin/python3.13 -m ensurepip --upgrade

sudo rm /usr/bin/python3.13
sudo rm /usr/bin/pip3.13

sudo ln -s /usr/local/bin/python3.13 /usr/bin/python3.13
sudo ln -s /usr/local/bin/pip3.13 /usr/bin/pip3.13

sudo echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/python3.13.conf
sudo ldconfig

python3.13 --version
pip3.13 --version
```

### Ubuntu
```bash
```

## 2. Basic Frontend
Server
```bash
mkdir -p /opt/basic-frontend
cd /opt/basic-frontend
```
Local
```bash
scp -i ~/.ssh/id_rsa  index.html  peter@192.168.56.110:/opt/basic-frontend/
```
Server
```bash
python3 -m http.server 8060
```

**Open port**
```bash
sudo firewall-cmd --zone=public --add-port=8060/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all --permanent
```

## 2. Basic Backend

Server
```bash
mkdir -p /opt/basic-backend
cd /opt/basic-backend
```
Local
```bash
scp -i ~/.ssh/id_rsa  main.py  peter@192.168.56.110:/opt/basic-backend/
```
Server
```bash
python3 backend.py
```

**Open port**
```bash
sudo firewall-cmd --zone=public --add-port=8070/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all --permanent
```
