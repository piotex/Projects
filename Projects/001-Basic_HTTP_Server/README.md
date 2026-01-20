# Very Basic Http Server Setup

## 1. Make sure you have python installed on server

## 2. Frontend
### 2.1 Install yarn
#### 2.1.1 Server - CentOS Stream 10
```bash
sudo dnf install -y nodejs
sudo npm install -g yarn
sudo ln -s /usr/local/bin/yarn /usr/bin/yarn
yarn --version
```

#### 2.1.2 Server - Ubuntu / WSL
```bash
sudo apt update
sudo apt install -y curl
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt remove -y cmdtest
sudo apt install -y yarn
yarn --version
```

### 2.2 Create Frontend
```bash
yarn create react-app my-app --template typescript
cd my-app
```
```bash
vi my-app/src/SimplePageWithBackendData.tsx
vi my-app/src/index.tsx
```

### 2.3 Build Frontend
```bash
yarn build
```

### 2.4 Deploy Frontend
Server
```bash
sudo mkdir -p /var/www/your-app
sudo chmod 777 -R /var/www/your-app 
```
Local
```bash
scp -rv my-app/build peter@192.168.56.110:/var/www/your-app
```
Server
```bash
sudo chown -R nginx:nginx /var/www/your-app
sudo find /var/www/your-app -type d -exec chmod 755 {} \;
sudo find /var/www/your-app -type f -exec chmod 644 {} \;
getenforce
sudo chcon -R -t httpd_sys_content_t /var/www/your-app/build
```

### 2.5 Install nginx
Server - CentOS Stream 10 
```bash
sudo yum update  -y
sudo yum install epel-release -y
sudo yum install nginx  -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```
Local
```bash
scp -rv  nginx.conf  peter@192.168.56.110:/etc/nginx/nginx.conf 
```
Server
```bash
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart nginx
sudo systemctl status nginx
```
**Open ports**
```bash
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all --permanent
sudo semanage port -a -t http_port_t -p tcp 8080
```

## 3. Backend
```bash
mkdir -p /opt/backend
chmod 777 -R /opt/backend
```

### 3.1 Create Backend
```bash
vi app.py
requirements.txt
scp -rv  app.py requirements.txt  peter@192.168.56.110:/opt/backend
```
```bash
sudo chown -R peter:peter /opt/backend
sudo chmod -R 755 /opt/backend
```

### 3.2 Setup Server
### 3.2.1 venv setup
```bash
cd /opt/backend
sudo dnf install python3-virtualenv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
```

### 3.2.2 Backend Service
```bash
scp -rv flaskbackend.service  peter@192.168.56.110:/etc/systemd/system/flaskbackend.service
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable flaskbackend.service
sudo systemctl start flaskbackend.service
sudo systemctl status flaskbackend.service
```

**Open port**
```bash
sudo firewall-cmd --zone=public --add-port=8090/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all --permanent
```