

3.2. Sieć dockera
```
docker network create \
  --driver bridge \
  devops-net

docker network ls
```

3.3. Uruchomienie kontenerów
```
docker run -itd -v nexus:/data   --name nexus   --network devops-net rockylinux/rockylinux:9
docker run -itd -v test:/data    --name test    --network devops-net rockylinux/rockylinux:9
docker run -itd -v prod:/data    --name prod    --network devops-net rockylinux/rockylinux:9
```

3.4. Nexus 
```
docker build -f nexus.Dockerfile -t devops-nexus .
docker run -itd \
  --name nexus \
  -p 8001:8081 \
  -v nexus_home:/nexus-data \
  --network devops-net \
  devops-nexus
docker exec -it nexus cat /opt/sonatype-work/nexus3/admin.password
```

3.5. Test
```
docker build -f test.Dockerfile -t devops-test .
docker run -itd \
  --name test \
  -p 8002:8080 \
  -v test:/opt/tomcat/webapps \
  --network devops-net \
  devops-test

mvn clean package
docker cp target/myapp-1.0.0.war test:/opt/tomcat/webapps/
curl http://localhost:8002/myapp-1.0.0/hello
```


3.7. Jenkins
```
docker build -f jenkins.Dockerfile -t devops-jenkins .
docker run -itd \
  --name jenkins \
  -p 8000:8080 \
  -v jenkins_home:/var/lib/jenkins \
  --network devops-net \
  devops-jenkins
docker exec -it jenkins cat /var/lib/jenkins/secrets/initialAdminPassword
```