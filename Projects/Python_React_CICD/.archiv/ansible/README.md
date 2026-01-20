# ansible



# Run ansible
```bash
cd 
source ansible-venv/bin/activate
cd /home/peter/github/Projects/Python_React_CICD/ansible
ansible-playbook -i inventory/server.yml setup.yml
```







# Install ansible on local machine
```bash
cd
python3 -m venv ansible-venv
source ansible-venv/bin/activate
python3 -m pip install --upgrade pip
pip install ansible
ansible --version
deactivate
```

# Create ansible user and ssh communication
### On host
```bash
sudo useradd -m -s /bin/bash ansible
echo "ansible:ansible123" | sudo chpasswd

sudo groupadd ansible
sudo usermod -aG ansible ansible

echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible
sudo chmod 440 /etc/sudoers.d/ansible
```

### On local
```bash
ssh-keygen -t rsa -b 4096 
	/home/peter/.ssh/id_rsa_ansible

ssh-copy-id -i /home/peter/.ssh/id_rsa_ansible.pub ansible@192.168.223.223
ssh ansible@192.168.223.223 -i /home/peter/.ssh/id_rsa_ansible

cd /home/peter/github/Projects
code .
```