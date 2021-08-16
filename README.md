# jenkins-docker

Build a Docker image using Jenkins pipeline and push it into Docker registry. This ```jenkins-docker``` image is built from Jenkins official image, install Docker, and give access to user ```jenkins``` build images.

Get the image from Docker Hub: [https://hub.docker.com/r/joglomedia/jenkins-docker](https://hub.docker.com/r/joglomedia/jenkins-docker)

## Running Jenkins with Docker from Host

Start your jenkins-docker container by running this command:

```bash
docker container run --name jenkins-docker -p 8080:8080 joglomedia/jenkins-docker:lts
```

To run Jenkins build from host, you need to mount the Docker socket to the container. Add the volume parameter to your ```docker run``` command:

```bash
-v /var/run/docker.sock:/var/run/docker.sock:rw
```

In order to make the Docker inside your container able to communicate with the host Docker daemon, you should set the Docker group ID similar to the group ID of your host Docker daemon.

```bash
-e DOCKER_HOST_GID=YOUR_DOCKER_HOST_GID
```

You can try the following command to get the host Docker group ID:

```bash
getent group docker | cut -d: -f3
```

Assign the group ID to the ```DOCKER_HOST_GID``` environment variable, so you can pass it to the ```docker container run``` command.

```bash
DOCKER_HOST_GID=$(getent group docker | cut -d: -f3)
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

Finally, initialize jenkins-docker container as below:

```bash
docker container run -d --name jenkins-docker -p 8080:8080 \
-e DOCKER_HOST_GID=${DOCKER_HOST_GID} \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
-v ${JENKINS_HOME}:/var/jenkins_home \
joglomedia/jenkins-docker:lts
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

All additional plugins listed in [jenkins-home/plugins.txt](https://github.com/joglomedia/jenkins-docker/blob/lts/jenkins-home/plugins.txt) file.

## DONATION

**[Buy Me a Bottle of Milk or a Cup of Coffee!](https://paypal.me/masedi)**

## SPONSORSHIP

Be the first one!

## Copyright

(c) 2020-2021 | [MasEDI.Net](https://masedi.net/)
