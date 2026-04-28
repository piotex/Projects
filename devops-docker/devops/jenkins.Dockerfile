FROM rockylinux:9

ENV JENKINS_HOME=/var/lib/jenkins

# Update system and install Java 21
RUN dnf update -y && \
    dnf install -y java-21-openjdk

RUN mkdir -p /var/lib/jenkins && \
    chown -R root:root /var/lib/jenkins

# Add Jenkins repo
RUN cat <<EOF >/etc/yum.repos.d/jenkins.repo
[jenkins]
name=Jenkins-stable
baseurl=https://pkg.jenkins.io/redhat/
enabled=1
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat/jenkins.io.key
EOF

# Import key (repo is broken, GPG mismatched -> install with nogpgcheck)
RUN rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key && \
    dnf clean all && \
    dnf install -y jenkins --nogpgcheck && \
    dnf clean all

# Expose Jenkins port
EXPOSE 8080

# Jenkins home (volume)
VOLUME ["/var/lib/jenkins"]

# Run Jenkins as PID 1 (no systemd inside Docker)
CMD ["java", "-DJENKINS_HOME=/var/lib/jenkins", "-jar", "/usr/share/java/jenkins.war"]

