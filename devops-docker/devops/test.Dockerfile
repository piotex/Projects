FROM rockylinux:9

# Install Java, wget, tar, unzip
RUN set -euxo pipefail && \
    dnf -y update && \
    dnf -y install java-21-openjdk wget tar unzip shadow-utils && \
    dnf clean all

ENV TOMCAT_VERSION=10.1.53
ENV CATALINA_HOME=/opt/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

# Create tomcat user
RUN useradd -r -M -d /opt/tomcat tomcat

# Download and install Tomcat ONLY from dlcdn.apache.org
RUN set -eux && \
    cd /tmp && \
    wget "https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" && \
    mkdir -p "$CATALINA_HOME" && \
    tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz" -C "$CATALINA_HOME" --strip-components=1 && \
    rm -f "apache-tomcat-${TOMCAT_VERSION}.tar.gz" && \
    chown -R tomcat:tomcat "$CATALINA_HOME"

EXPOSE 8080

USER tomcat

CMD ["catalina.sh", "run"]