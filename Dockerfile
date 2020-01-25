# Use Jenkins latest
FROM jenkins/jenkins:latest
LABEL maintainer Edi Septriyanto <eslabs.id@gmail.com> architecture="AMD64/x86_64"
LABEL jenkins-version="latest" ubuntu-version="18.04" build="25-Jan-2020"

# Tell the container there is no tty
ENV DEBIAN_FRONTEND noninteractive

USER root

RUN apt-get -y update && \
    apt-get -y install apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
        $(lsb_release -cs) \
        stable" && \
    apt-get -y update && \
    apt-get -y install docker-ce

#RUN apt-get install -y docker-ce

RUN usermod -a -G docker jenkins

USER jenkins
