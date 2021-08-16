NAME=jenkins-docker
VERSION=0.0.2
REPO=joglomedia/jenkins-docker
TAG := $(shell git rev-parse --abbrev-ref HEAD)
JENKINS_HOME := $(shell echo "$$(pwd)/jenkins_home")
DOCKER_HOST_GID := $(shell cat /etc/group |grep docker | awk '{split($$0,a,":"); print a[3]}')

build:
	docker build --rm --pull --build-arg DOCKER_HOST_GID=$(DOCKER_HOST_GID) -t $(REPO):$(TAG) .

push:
	if [ $$(docker images | grep $(REPO) | grep -c $(TAG)) ]; then \
		docker push "$(REPO):$(TAG)"; \
	else \
		echo "No image to push"; \
	fi

test:
	if [ $$(docker images | grep $(REPO) | grep -c $(TAG)) ]; then \
		mkdir -p $(JENKINS_HOME) && \
		chown 1000:1000 $(JENKINS_HOME) && \
		docker run --rm --name jenkins-docker-test -p 8080:8080 \
			-v $(JENKINS_HOME):/var/jenkins_home \
			-v /var/run/docker.sock:/var/run/docker.sock:ro "$(REPO):$(TAG)"; \
	fi

all:
	build push

.PHONY: build push all