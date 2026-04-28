FROM rockylinux:9

# Install dependencies (Java 21 required by Nexus 3.68+)
RUN set -euxo pipefail && \
    dnf -y update && \
    dnf -y install java-21-openjdk wget tar shadow-utils && \
    dnf clean all

ENV NEXUS_VERSION=3.90.2-06
ENV NEXUS_HOME=/opt/nexus
ENV NEXUS_DATA=/nexus-data

# Create Nexus user and directories
RUN set -euxo pipefail && \
    mkdir -p "$NEXUS_HOME" "$NEXUS_DATA" && \
    useradd -r -M -d "$NEXUS_HOME" nexus

# Download & extract Nexus using YOUR EXACT URL + FILENAME
RUN set -eux && \
    cd /tmp && \
    wget "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz" && \
    tar -xzf "nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz" -C /opt && \
    mv /opt/nexus-${NEXUS_VERSION}/* "$NEXUS_HOME" && \
    rm -rf "nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz" "/opt/nexus-${NEXUS_VERSION}"

# IMPORTANT:
# This version of Nexus expects /opt/sonatype-work to exist and be writable.
RUN set -eux && \
    mkdir -p /opt/sonatype-work/nexus3 && \
    chown -R nexus:nexus /opt/sonatype-work /opt/nexus /nexus-data

EXPOSE 8081
VOLUME ["/nexus-data"]

USER nexus

CMD ["/opt/nexus/bin/nexus", "run"]