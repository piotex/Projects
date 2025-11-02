# Kubernetes Cluster on VirtualBox (Ubuntu)

> Inspiration: [YouTube Video](https://www.youtube.com/watch?v=j3a2Sr2n8eQ)

> Full tutorial: [YouTube Video](https://www.youtube.com/live/Iwbhtscr4eg)

This guide walks through creating a **Kubernetes cluster** using **VirtualBox**, **Ubuntu**, and **kubeadm**.

---

## 🧩 1. Download

1. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. [Ubuntu ISO image](https://ubuntu.com/download)
3. [WSL (for SSH access)](https://www.youtube.com/results?search_query=install+wsl)

---

## ⚙️ 2. Create Virtual Machines

1. Create VM: `ubuntu-k8s`
2. Resources: **4 GB RAM**, **4 CPUs**, **60 GB disk**
3. **Add a second network adapter**
4. Start machine and install base packages:
    ```
    sudo apt update && sudo apt upgrade -y
    sudo apt install net-tools -y
    sudo apt install openssh-server -y
    sudo systemctl enable ssh
    sudo systemctl start ssh
    ifconfig
    ```
5. Power off the machine and clone x2 (full clone + new MAC address)
6. Use ifconfig to note IPs
7. Start all machines and connect via SSH

## 🔧 3. Configure All Machines
3.1 Update & install tools
```
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gpg
```

3.2 Disable swap
```
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

3.3 Set hostnames
```
sudo hostnamectl set-hostname k8s-main
sudo hostnamectl set-hostname k8s-node1
sudo hostnamectl set-hostname k8s-node2
exit
```

3.4 Edit /etc/hosts on all machines
```
192.168.56.104 main
192.168.56.105 node1
192.168.56.106 node2
```

3.5 Install containerd
```
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

3.6 Install kubeadm, kubelet, kubectl
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

3.7 Initialize cluster (on main node)
```
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
sudo sysctl --system

sudo kubeadm init --apiserver-advertise-address=192.168.56.104 --pod-network-cidr=10.244.0.0/16
```

##### Save the kubeadm join ... command for worker nodes.

3.8 Configure kubectl (main node)
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

3.9 Install Pod Network (Flannel)

Edit /etc/containerd/config.toml:
```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
```

Then:
```
sudo systemctl restart containerd
sudo systemctl restart kubelet
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get nodes
kubectl get pods -A
```

3.10 Join Worker Nodes

On each worker:
```
sudo swapoff -a
sudo sysctl -w net.ipv4.ip_forward=1
sudo kubeadm join 192.168.56.104:6443 --token <token> \
  --discovery-token-ca-cert-hash <hash>
```

##### Or generate a new token on main:
```
kubeadm token create --print-join-command
```

3.11 Fix Internal Network

Edit /etc/default/kubelet:
```
KUBELET_EXTRA_ARGS="--node-ip=192.168.56.104"
```
Adjust per node (.105, .106, etc.)

Then restart:
```
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl get nodes -o wide
```

3.12 Fix Flannel Error
```
sudo modprobe br_netfilter
sudo modprobe overlay

sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

On main:
```
kubectl delete pod -n kube-flannel --all
kubectl get pods -n kube-flannel -o wide
```

## 💻 4. Install kubectl on Local Machine
4.1 Install dependencies
```
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg
```

4.2 Install kubectl
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubectl
```

4.3 Install Helm
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

4.4 Copy kubeconfig from main node
```
mkdir -p ~/.kube
scp peter@192.168.56.104:/home/peter/.kube/config ~/.kube/config
```

Edit config file:
```
server: https://192.168.56.104:6443
```

4.5 Verify connection
```
curl -k https://192.168.56.104:6443/version
kubectl get nodes
```

## 🌐 5. Deploy NGINX
5.1 Create deployment file: 

`nginx-deployment.yaml`

5.2 Apply deployment
```
kubectl apply -f nginx-deployment.yaml
```

5.3 Check status
```
kubectl get pods -o wide
kubectl get svc nginx-service
```

5.4 Access the NGINX page
```
kubectl port-forward service/nginx-service 8080:80
```

Then open:

👉 http://localhost:8080
