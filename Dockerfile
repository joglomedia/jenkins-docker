# Use Jenkins LTS
FROM jenkins/jenkins:lts

LABEL maintainer Edi Septriyanto <me@masedi.net> architecture="AMD64/x86_64"
LABEL jenkins-version="lts" build="17-Aug-2021"

USER root

ARG DOCKER_HOST_GID=${DOCKER_HOST_GID:-9999}
ENV DOCKER_HOST_GID=${DOCKER_HOST_GID}

# Modified entrypoint to allow for the use of a custom docker host.
COPY src/jenkins-docker.sh /usr/local/bin/jenkins-docker.sh

# Install Docker and dependencies.
RUN set -ex && \
    apt-get -y update && \
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
    rm -rf /var/lib/apt/lists/* && \
# Add jenkins as docker group and sudoers
    groupmod -g ${DOCKER_HOST_GID} docker && \
    usermod -aG docker jenkins && \
    echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins

# Install Jenkins plugins.
COPY --chown=jenkins:jenkins jenkins-home/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose -f /usr/share/jenkins/ref/plugins.txt

# Copy sample email notification template.
COPY --chown=jenkins:jenkins jenkins-home/email-templates /var/jenkins_home/

# Run the setup wizard.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=true \
    -Dpermissive-script-security.enabled=true"

# Set default admin user.
ENV JENKINS_OPTS="--argumentsRealm.roles.user=admin \
    --argumentsRealm.passwd.admin=admin \
    --argumentsRealm.roles.admin=admin"

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins-docker.sh"]