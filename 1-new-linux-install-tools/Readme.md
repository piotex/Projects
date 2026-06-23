## Tool Installation

## VS Code
- Auto Save -> File + Auto Save
- plugins:
    - HashiCorp Terraform
    - Python
    - ...

## PyCharm 


## Python VENV
```bash
sudo apt update
sudo apt install python3.14-venv

python3 -m venv venv
source venv/bin/activate

pip freeze > requirements.txt
pip install -r requirements.txt

deactivate
```


### AWS CLI
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

aws --version
```

### Terraform
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y

terraform --version
```

### Ansible
```bash
sudo apt update && sudo apt install -y software-properties-common

sudo add-apt-repository --yes --update ppa:ansible/ansible

sudo apt install -y ansible

ansible --version
```

