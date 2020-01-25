# docker-jenkins

Jenkins inside Docker container. The Jenkins pulled from Jenkins official image latest version.

## Running jenkins with docker from host

```
docker run --name jenkins-docker -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock eslabsid/docker-jenkins
```

