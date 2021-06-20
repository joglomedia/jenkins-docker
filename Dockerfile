# Use Jenkins latest
FROM jenkins/jenkins:lts-alpine

LABEL maintainer Edi Septriyanto <eslabs.id@gmail.com> architecture="AMD64/x86_64"
LABEL jenkins-version="lts-latest" build="25-Jan-2020"

USER root

ENV JENKINS_REF /usr/share/jenkins/ref

# Install Docker
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
    apk add --update docker openrc shadow && \
    rc-update add docker boot

# Skip the setup wizard
# ENV JAVA_ARGS -Djenkins.install.runSetupWizard=false -Dpermissive-script-security.enabled=true
# ENV JAVA_ARGS -Djenkins.install.runSetupWizard=false
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dpermissive-script-security.enabled=true"

# Install the plugins
COPY jenkins-home/plugins.txt ${JENKINS_REF}/
RUN /usr/local/bin/install-plugins.sh < ${JENKINS_REF}/plugins.txt

COPY jenkins-home/email-templates /var/jenkins_home/

RUN usermod -a -G docker jenkins
USER jenkins
