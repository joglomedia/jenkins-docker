# Use Jenkins LTS
FROM jenkins/jenkins:lts-alpine

LABEL maintainer Edi Septriyanto <me@masedi.net> architecture="AMD64/x86_64"
LABEL jenkins-version="2.462.2-lts-alpine" build="04-Sep-2024"

USER root

ARG DOCKER_HOST_GID=${DOCKER_HOST_GID:-9999}
ENV DOCKER_HOST_GID=${DOCKER_HOST_GID}

# Modified entrypoint to allow for the use of a custom docker host.
COPY src/jenkins-docker.sh /usr/local/bin/jenkins-docker.sh

# Install docker and dependencies.
RUN set -ex && \
    apk update && apk upgrade && \
    apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    ca-certificates openssl sudo bash && \
#    update-ca-certificates && \
    apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community/ \
    docker docker-compose shadow && \
    rm -rf /var/lib/apk/* && \
    chmod +x /usr/local/bin/jenkins-docker.sh && \
# Add jenkins as docker group and sudoers
    groupmod -g ${DOCKER_HOST_GID} docker && \
    usermod -aG docker jenkins && \
    echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins

# Install Jenkins plugins.
COPY --chown=jenkins:jenkins src/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose -f /usr/share/jenkins/ref/plugins.txt

# Copy email notification template.
COPY --chown=jenkins:jenkins src/email-templates /var/jenkins_home/

# Run the setup wizard.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true \
    -Dpermissive-script-security.enabled=true"

# Set default admin user.
ENV JENKINS_OPTS="--argumentsRealm.roles.user=admin \
    --argumentsRealm.passwd.admin=admin \
    --argumentsRealm.roles.admin=admin"

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins-docker.sh"]