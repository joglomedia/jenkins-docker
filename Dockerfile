# Use Jenkins latest.
FROM jenkins/jenkins:lts-alpine

LABEL maintainer Edi Septriyanto <me@masedi.net> architecture="AMD64/x86_64"
LABEL jenkins-version="lts-alpine" build="21-Jun-2021"

USER root

ENV JENKINS_REF /usr/share/jenkins/ref

# Install Docker.
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
    apk add --no-cache docker shadow

# Skip the setup wizard.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true \
    -Dpermissive-script-security.enabled=true"

# Set default admin user.
ENV JENKINS_OPTS="--argumentsRealm.roles.user=admin \
    --argumentsRealm.passwd.admin=admin \
    --argumentsRealm.roles.admin=admin"

# Install the plugins.
COPY --chown=jenkins:jenkins jenkins-home/plugins.txt ${JENKINS_REF}/
#RUN /usr/local/bin/install-plugins.sh < ${JENKINS_REF}/plugins.txt
RUN jenkins-plugin-cli -f ${JENKINS_REF}/plugins.txt

COPY jenkins-home/email-templates /var/jenkins_home/

RUN usermod -a -G docker jenkins
USER jenkins
