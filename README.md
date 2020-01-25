# jenkins-docker

Build a Docker image using Jenkins pipeline and push it into Docker registry. The Jenkins pulled from Jenkins official image latest version.

## Running Jenkins with Docker from host

Start your jenkins-docker container by running this command:

```
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock eslabsid/jenkins-docker
```

You also can configuring a volume for Jenkins home. Use a directory for which you have permission.

```
JENKINS_HOME="${HOME}/jenkins_home"
mkdir -p ${JENKINS_HOME}
```

Change ownership required for Linux, ignore this line for Mac or Windows.

```
chown 1000:1000 ${JENKINS_HOME}
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v ${JENKINS_HOME}:/var/jenkins_home eslabsid/jenkins-docker
```

For running container in the background add a ```-d``` or ```--detach``` parameter to the Docker's ```container run``` command above.

## Complete Jenkins startup wizard

After initializing the Jenkins container, complete the Jenkins startup wizard and install additional plugins (Locale & Blueocean). Your Jenkins web administration should be accessible from here:

```
http://YOUR-IP-ADDRESS:8080
```

If you're asked for administrator password, you can get the password from inside container by executing the following command:

```
docker exec -it jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword
```

## Install additional plugins



## Inspirations
[Jenkins and Docker](https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry)

