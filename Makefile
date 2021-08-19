NAME=jenkins-docker
VERSION=0.0.3
REPO=joglomedia/jenkins-docker
TAG := $(shell git rev-parse --abbrev-ref HEAD)
JENKINS_HOME := $(shell echo "$$(pwd)/jenkins_home")
DOCKER_HOST_GID := $(shell getent group docker | cut -d: -f3)

build:
	docker build --rm --pull --build-arg DOCKER_HOST_GID=$(DOCKER_HOST_GID) -t $(REPO):$(TAG) .

test:
	if [ $$(docker images | grep $(REPO) | grep -c $(TAG)) ]; then \
		mkdir -p $(JENKINS_HOME) && \
		chown 1000:1000 $(JENKINS_HOME) && \
		docker run --rm --name jenkins-docker-test \
			-e "DOCKER_HOST_GID=$(DOCKER_HOST_GID)" \
			-p 8080:8080 -p 50000:50000 \
			-v $(JENKINS_HOME):/var/jenkins_home \
			-v /var/run/docker.sock:/var/run/docker.sock:ro "$(REPO):$(TAG)"; \
	fi

push:
	if [ $$(docker images | grep $(REPO) | grep -c $(TAG)) ]; then \
		docker push "$(REPO):$(TAG)"; \
	else \
		echo "No image to push"; \
	fi

all:
	build test push

.PHONY: build test push all
