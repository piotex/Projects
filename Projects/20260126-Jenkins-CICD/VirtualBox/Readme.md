# VirtualBox

## 1. Create CICD VM
1.1. New 
Name: cicd-vm
ISO:  Rocky v10.1 DVD x86_64
RAM:  4096 Mb
CPU:  4 
Virtual Disk: 50 Gb

1.2. Network
Nat
Host-only - Static IP
    Address: 192.168.56.56
    Netmask: 255.255.255.0
    Gateway: 192.168.56.1
    DNS: 8.8.8.8
    `nmtui`


1.3. Start and Config
Install Rocky
English
