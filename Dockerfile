FROM opennms/build-env:latest

LABEL maintainer "Markus von Rüden <mvr@opennms.com>"

ARG BAMBOO_VERSION=6.6.1
ARG BAMBOO_AGENT=bamboo-agent-${BAMBOO_VERSION}.jar
ARG BAMBOO_DOWNLOAD_ADDRESS=http://localhost:8085

ENV BAMBOO_HOME=/opt/bamboo-home
ENV BAMBOO_SERVER_ADDRESS=http://localhost:8085/agentServer
ENV BAMBOO_SECURITY_TOKEN=
ENV MAVEN_PROXY=

# Install ssh-server (required for SshMonitorIT)
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install openssh-server && \
    yum clean all && \
    rm -rf /var/cache/yum
RUN ssh-keygen -b 521 -t ecdsa -C"$(id -un)@$(hostname)-$(date --rfc-3339=date)" -f  /etc/ssh/ssh_host_ecdsa_key

# Install Postgres, which is a required dependencies for test-environment
RUN yum -y --setopt=tsflags=nodocs update && \
    rpm -ivh https://yum.postgresql.org/9.6/redhat/rhel-7.3-x86_64/pgdg-centos96-9.6-3.noarch.rpm && \
    yum -y install postgresql96 postgresql96-server postgresql96-libs postgresql96-contrib postgresql96-devel && \
    yum clean all && \
    rm -rf /var/cache/yum
# Modified setup script to bypass systemctl variable read stuff
ADD ./conf/postgres/postgresql-setup.sh /usr/bin/postgresql-setup
RUN chmod +x /usr/bin/postgresql-setup
RUN /usr/bin/postgresql-setup initdb

#Access from all over --- NEVER DO THIS SHIT IN POST DEV ENVs !!!!!!!!!!!!!!!!!!!
RUN echo "local   all             postgres                                peer" > /var/lib/pgsql/data/pg_hba.conf && \
    echo "local   all             all                                     peer" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "host    all             all             127.0.0.1/32            trust" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "host    all             all             ::1/128                 trust" >> /var/lib/pgsql/data/pg_hba.conf

# Docker in Docker
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install yum-utils device-mapper-persistent-data lvm2 && \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum -y install docker-ce && \
    yum clean all && \
    rm -rf /var/cache/yum

# Download and install bamboo-agent.jar
RUN mkdir -p ${BAMBOO_HOME} && \
    wget --tries 3 -O ${BAMBOO_HOME}/${BAMBOO_AGENT} ${BAMBOO_DOWNLOAD_ADDRESS}/admin/agent/${BAMBOO_AGENT}

# Copy files
COPY conf/bamboo-capabilities.properties ${BAMBOO_HOME}
COPY conf/settings.xml ${BAMBOO_HOME}/settings.xml.template
COPY entrypoint.sh /

# 5432 Postgres
EXPOSE 5432

VOLUME [ "${BAMBOO_HOME}", "/var/lib/pgsql" ]

LABEL license="AGPLv3" \
      org.opennms.horizon.version="${BAMBOO_VERSION}" \
      vendor="OpenNMS Community" \
      name="Bamboo Agent"

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "-h" ]

WORKDIR ${BAMBOO_HOME}