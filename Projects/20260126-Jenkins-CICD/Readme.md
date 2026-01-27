# 20260126 Jenkins CICD

## Technologies:
1. VirtualBox - Infrastructure:
2. Jenkins    - CICD
3. nexus      - Artefact repo



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

# 2. Insall Software
```
ssh peter@192.168.56.56

sudo dnf update -y
sudo dnf install -y java-21-openjdk-devel maven git unzip wget curl zip
java -version
mvn -v
```

# 3. Insall Jenkins
```
sudo curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf makecache -y
sudo dnf install -y jenkins

sudo systemctl enable --now jenkins
sudo systemctl status jenkins --no-pager

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

sudo journalctl -u jenkins -f
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

# 4. Install nexus
```
sudo useradd -r -s /sbin/nologin nexus

cd /opt
sudo wget -O nexus.tar.gz "https://download.sonatype.com/nexus/3/nexus-3.88.0-08-linux-x86_64.tar.gz"
sudo tar -xzf nexus.tar.gz
sudo mv $(ls -d nexus-3* | head -n1) nexus

sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work || true

sudo sed -i 's/#run_as_user=""/run_as_user="nexus"/' /opt/nexus/bin/nexus

sudo vi /etc/systemd/system/nexus.service 

sudo systemctl daemon-reload
sudo systemctl enable --now nexus
sudo systemctl status nexus --no-pager

sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload

cat /opt/sonatype-work/nexus3/admin.password
```


# 5. Download and run basic Springboot project
```
cd /tmp
curl -s "https://start.spring.io/starter.zip?type=maven-project&language=java&groupId=com.example&artifactId=demo&name=demo&packageName=com.example.demo&javaVersion=21&dependencies=web" -o demo.zip
unzip demo.zip -d demo
cd demo

vi src/main/java/com/example/demo/HomeController.java
vi pom.xml
vi settings.xml

mvn -B -DskipTests package
mvn -Dspring-boot.run.arguments="--server.port=8082" spring-boot:run

sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

# 6. Deploy artefact to nexus
```
mvn -s settings.xml -DskipTests clean deploy
mvn versions:set -DnewVersion=1.0.0 -DgenerateBackupPoms=false -DprocessAllModules=true
mvn versions:set -DnewVersion=1.0.1-SNAPSHOT -DgenerateBackupPoms=false -DprocessAllModules=true


# mvn release:prepare -DreleaseVersion=0.0.1 -DdevelopmentVersion=0.0.2-SNAPSHOT -DscmCommentPrefix="[release] "
# mvn release:perform
```

