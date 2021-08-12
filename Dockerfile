# Use Jenkins LTS
FROM jenkins/jenkins:lts-alpine

LABEL maintainer Edi Septriyanto <me@masedi.net> architecture="AMD64/x86_64"
LABEL jenkins-version="lts-alpine" build="12-Aug-2021"

USER root

# Install docker and dependencies.
RUN set -ex && \
    apk update && apk upgrade && \
    apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    ca-certificates openssl sudo bash && \
#    update-ca-certificates && \
    apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community/ \
    docker docker-compose shadow && \
    rm -rf /var/lib/apk/*

# Add jenkins as docker group and sudoers
RUN usermod -a -G docker jenkins && \
    echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins

# Install Jenkins plugins.
COPY --chown=jenkins:jenkins jenkins-home/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose -f /usr/share/jenkins/ref/plugins.txt

# Copy email notification template.
COPY --chown=jenkins:jenkins jenkins-home/email-templates /var/jenkins_home/

# Skip the setup wizard.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true \
    -Dpermissive-script-security.enabled=true"

# Set default admin user.
ENV JENKINS_OPTS="--argumentsRealm.roles.user=admin \
    --argumentsRealm.passwd.admin=admin \
    --argumentsRealm.roles.admin=admin"
