NAME=jenkins-docker
VERSION=0.0.1
REPO=joglomedia/jenkins-docker
TAG=lts

build:
	docker build --rm --pull -t $(REPO):$(TAG) .

push:
	if [ $$(docker images | grep $(REPO) | grep -c $(TAG)) ]; then \
		docker push "$(REPO):$(TAG)"; \
	else \
		echo "No image to push"; \
	fi

all:
	build push

.PHONY: build push all
