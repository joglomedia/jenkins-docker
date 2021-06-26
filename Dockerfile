# Use Jenkins LTS
FROM jenkins/jenkins:lts

LABEL maintainer Edi Septriyanto <eslabs.id@gmail.com> architecture="AMD64/x86_64"
LABEL jenkins-version="lts" build="21-Jun-2021"

USER root

ENV JENKINS_REF /usr/share/jenkins/ref

# Skip the setup wizard.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true \
    -Dpermissive-script-security.enabled=true"

# Set default admin user.
ENV JENKINS_OPTS="--argumentsRealm.roles.user=admin \
    --argumentsRealm.passwd.admin=admin \
    --argumentsRealm.roles.admin=admin"

# Install the plugins
COPY jenkins-home/plugins.txt ${JENKINS_REF}/
#RUN /usr/local/bin/install-plugins.sh < ${JENKINS_REF}/plugins.txt
RUN jenkins-plugin-cli -f ${JENKINS_REF}/plugins.txt

COPY jenkins-home/email-templates /var/jenkins_home/

# Install Docker
RUN apt-get -y update && \
    apt-get -y install apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "${ID}")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
    apt-get -y update && \
    apt-get -y install docker-ce && \
    usermod -aG docker jenkins

USER jenkins