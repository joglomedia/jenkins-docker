# jenkins-docker

Build a Docker image using Jenkins pipeline and push it into Docker registry. This `jenkins-docker` image is built from jenkins official image, install Docker and give access to user ```jenkins``` build dockers.

Get the image from Docker Hub: [https://hub.docker.com/r/joglomedia/jenkins-docker](https://hub.docker.com/r/joglomedia/jenkins-docker)

## Running Jenkins with Docker from Host

Start your jenkins-docker container by running this command:

```bash
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock:rw joglomedia/jenkins-docker:lts-alpine
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
docker container run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock:rw -v ${JENKINS_HOME}:/var/jenkins_home joglomedia/jenkins-docker:lts-alpine
```

For running container in the background add a ```-d``` or ```--detach``` parameter to the Docker's ```container run``` command above.

## Complete Jenkins Startup Wizard

After initializing the Jenkins container, complete the Jenkins startup wizard and install additional plugins (Locale & Blueocean). Your Jenkins web administration should be accessible from here:

```bash
http://YOUR-IP-ADDRESS:8080/
```

If you're asked for administrator password, you can get the password from inside container by executing the following command:

```bash
docker exec -it jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword
```

## Install Additional Jenkins Plugins

All additional plugins listed in [jenkins-home/plugins.txt](https://github.com/joglomedia/jenkins-docker/blob/lts-alpine/jenkins-home/plugins.txt) file.

## DONATION

**[Buy Me a Bottle of Milk or a Cup of Coffee!](https://paypal.me/masedi)**

## SPONSORSHIP

Be the first one!

## Copyright

(c) 2020-2021 | [MasEDI.Net](https://masedi.net/)
