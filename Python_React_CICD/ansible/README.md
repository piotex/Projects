# ansible

```bash
ansible-project/
├── inventories/
│   ├── dev/
│   │   ├── hosts.yaml
│   │   └── group_vars/
│   │       ├── all.yaml
│   │       └── frontend.yaml
│   └── prod/
│       ├── hosts.yaml
│       └── group_vars/
│           ├── all.yaml
│           └── backend.yaml
├── roles/
│   ├── common/        
│   ├── frontend/      
│   ├── backend/       
│   └── jenkins/       
├── playbooks/
│   ├── site.yaml      
│   ├── frontend.yaml  
│   ├── backend.yaml   
│   └── jenkins.yaml   
└── files/             
```



# Run ansible
```bash
cd 
source ansible-venv/bin/activate
cd /home/peter/github/Projects/Python_React_CICD/ansible
ansible-playbook -i inventories/dev/hosts playbooks/site.yaml
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




# 5 ????
### 5.1 Create ansible user 
** On host **
```bash
sudo useradd -m -s /bin/bash ansible
echo "ansible:xxxxx" | sudo chpasswd

sudo groupadd ansible || true
sudo usermod -aG ansible ansible

echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible
sudo chmod 440 /etc/sudoers.d/ansible
```

### 5.2 Add ssh public key on host
** On local **
```bash
ssh-keygen -t ed25519 -b 4096 -f /home/peter/.ssh/id_rsa_ansible -N ""

ssh-copy-id -i /home/peter/.ssh/id_rsa_ansible.pub ansible@192.168.56.110
ssh ansible@192.168.56.110 -i /home/peter/.ssh/id_rsa_ansible
```