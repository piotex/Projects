### Technologies
- Spring Boot (app)
- AWS (cloud - infra)

### Code
1.1 Copy basic app code
Open: https://start.spring.io/
    Project: Maven
    Language: Java
    Spring Boot: 4.0.3
    Group: com.example
    Artifact: app-code
    Package: com.example.app-code
    Packaging: Jar
    Configuration: Properties
    Java: 21
    (Generate)

unzip app-code.zip
cp app-code repo/app-code

1.2. Add Controller and pom.xml dependency
```
vi src/main/java/com/example/app-code/HelloController.java
vi pom.xml
```

1.3 Compile and run
```
sudo apt update -y
sudo apt install -y maven openjdk-21-jdk 
```
```
cd app-code/
mvn clean package
java -jar target/app-code-0.0.1-SNAPSHOT.jar
```

### Infrastructure
1.1. Create manually EC2
EC2 > Instances > (Launch Instance)
    OS: Amazon Linux 2023
    Instance type: t3.micro
    Key pair: Generate or select
    VPC & subnets: should be created
    Security group: Create and allow SSH & HTTP
    Storage (EBS): 8 GiB

1.2. Connect to EC2
EC2 > Instances > (EC2 Instance Connect)
or
```
cp /mnt/c/Users/pkubo/Downloads/PRIV_KEY ~/
cd ~
chmod 400 PRIV_KEY
ssh -i PRIV_KEY ec2-user@PUBLIC_IP
```

1.3 Install packages
```
sudo dnf update -y
sudo dnf install git maven java-21-amazon-corretto java-21-amazon-corretto-devel -y
java -version
```

### Deploy manually 
```
ARTEFACT_PATH="github/Projects/Projects/20260311-Basic-AWS-Jenkins-Springboot/app-code/target/app-code-0.0.1-SNAPSHOT.jar"
scp -i 2026-03-11.pem $ARTEFACT_PATH ec2-user@X.X.X.X:/home/ec2-user/
ssh -i PRIV_KEY ec2-user@PUBLIC_IP
sudo java -jar app-code-0.0.1-SNAPSHOT.jar --server.port=80
```








