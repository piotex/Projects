FROM jenkins/jenkins:lts

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

COPY jenkins.yaml /usr/share/jenkins/jenkins.yaml
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/jenkins.yaml

USER jenkins

EXPOSE 8080
EXPOSE 50000