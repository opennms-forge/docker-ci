FROM opennms/build-env:latest

LABEL maintainer "Markus von Rüden <mvr@opennms.com>"

ARG BAMBOO_VERSION=6.6.1
ARG BAMBOO_AGENT=bamboo-agent-${BAMBOO_VERSION}.jar
ARG BAMBOO_DOWNLOAD_ADDRESS=http://localhost:8085

ENV BAMBOO_HOME=/opt/bamboo-home
ENV BAMBOO_SERVER_ADDRESS=http://localhost:8085/agentServer
ENV BAMBOO_SECURITY_TOKEN=
ENV MAVEN_PROXY=

# Install wget
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install wget && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install git
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install git && \
    yum clean all && \
    rm -rf /var/cache/yum

# Download and install bamboo-agent.jar
RUN mkdir -p ${BAMBOO_HOME} && \
    wget --tries 3 -O ${BAMBOO_HOME}/${BAMBOO_AGENT} ${BAMBOO_DOWNLOAD_ADDRESS}/admin/agent/${BAMBOO_AGENT}

# Copy files
COPY conf/bamboo-capabilities.properties ${BAMBOO_HOME}
COPY conf/settings.xml ${BAMBOO_HOME}/settings.xml.template
COPY entrypoint.sh /

VOLUME [ "${BAMBOO_HOME}" ]

LABEL license="AGPLv3" \
      org.opennms.horizon.version="${BAMBOO_VERSION}" \
      vendor="OpenNMS Community" \
      name="Bamboo Agent"

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "-h" ]
