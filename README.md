# jenkins-docker

Build a Docker image using Jenkins pipeline and push it into Docker registry. This Dockerfile is built from jenkins official image, install Docker and give access to user ```jenkins``` build dockers.

## Running Jenkins with Docker from host

Start your jenkins-docker container by running this command:

```bash
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock joglomedia/jenkins-docker:lts-alpine
```

You also can configure a volume for Jenkins home. Use a directory for which you have permission.

```bash
JENKINS_HOME="${HOME}/jenkins_home"
mkdir -p ${JENKINS_HOME}
```

Change ownership required for Linux, ignore this line for Mac or Windows.

```bash
chown 1000:1000 ${JENKINS_HOME}
```

Initialize jenkins-docker container as below:

```bash
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock -v ${JENKINS_HOME}:/var/jenkins_home joglomedia/jenkins-docker:lts-alpine
```

For running container in the background add a ```-d``` or ```--detach``` parameter to the Docker's ```container run``` command above.

## Complete Jenkins startup wizard

After initializing the Jenkins container, complete the Jenkins startup wizard and install additional plugins (Locale & Blueocean). Your Jenkins web administration should be accessible from here:

```bash
http://YOUR-IP-ADDRESS:8080/
```

If you're asked for administrator password, you can get the password from inside container by executing the following command:

```bash
docker exec -it jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword
```

## Install additional plugins

All additional plugins listed in [jenkins-home/plugins.txt](https://github.com/joglomedia/jenkins-docker/blob/lts-alpine/jenkins-home/plugins.txt) file.

## Inspirations

[Jenkins and Docker](https://www.edureka.co/community/55640/jenkins-docker-docker-image-jenkins-pipeline-docker-registry)

## DONATION

**[Buy Me a Bottle of Milk or a Cup of Coffee!](https://paypal.me/masedi)**

## SPONSORSHIP

Be the first one!

## Copyright

(c) 2020-2021 | [MasEDI.Net](https://masedi.net/)
