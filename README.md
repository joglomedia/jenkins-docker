# jenkins-docker

Build a Docker image using Jenkins pipeline and push it into Docker registry. The Jenkins pulled from Jenkins official image latest version.

## Running Jenkins with Docker from host

```
docker run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock eslabsid/jenkins-docker
```

## Configuring a volume for Jenkins home

Use a directory for which you have permission.

```
JENKINS_HOME='/data/jenkins'
mkdir -p $JENKINS_HOME
```

Change ownership required for Linux, ignore this line for Mac or Windows.

```
chown 1000:1000 $JENKINS_HOME
docker run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $JENKINS_HOME:/var/jenkins_home eslabsid/jenkins-docker
```

## Complete Jenkins startup wizard

After initializing the Jenkins container, complete the Jenkins startup wizard and install the locale and Blue Ocean plugins. Your Jenkins web administration should be accessible from here:

```
http://YOUR-IP-ADDRESS:8080
```

## Inspirations
[Jenkins and Docker](https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry)

