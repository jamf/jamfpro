# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

DOCKER_IMAGE_BASE := jamfdevops
DOCKER_ORG := 
DOCKER_IMAGE := jamfpro

IS_TAG=$(shell git describe --exact-match; echo $$?)
VERSION=$(shell git --no-pager describe --tags --always)
SHA=$(shell git rev-parse --verify HEAD)
BUILD_URL=$(TRAVIS_JOB_WEB_URL)
BUILD_TIMESTAMP=$(shell date +%s)

# DOCKER TASKS
# Build the image
build: ## Build the image
	docker build -t $(DOCKER_IMAGE) .

build-nc: ## Build the image without caching
	docker build --no-cache \
	--label "GIT_SHA=$(SHA)" \
	--label "BUILD_URL=$(BUILD_URL)" \
	--label "BUILD_TIMESTAMP=$(BUILD_TIMESTAMP)" \
	-t $(DOCKER_IMAGE) .

release: build-nc tag publish ## Make a release by building and publishing the `{version}` tagged image

# Docker publish
publish: repo-login publish-version ## Publish the `{version}` tagged image

publish-latest: tag-latest ## Publish the `latest` taged container
	@echo 'Publish latest to $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)'
	docker push $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)/$(DOCKER_IMAGE):latest

publish-version: tag-version ## Publish the `{version}` tagged container
	@if [ "$(IS_TAG)" = "0" ]; then\
		echo 'Publish $(VERSION) to $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)';\
		docker push $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)/$(DOCKER_IMAGE):$(VERSION);\
	else \
		echo 'Not a git tag, skipping push step';\
	fi

# Docker tagging
tag: tag-latest tag-version ## Generate image tags for the `{version}` and `latest`

tag-latest: ## Generate image `{version}` tag
	@echo 'Create tag latest'
	docker tag $(DOCKER_IMAGE) $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)/$(DOCKER_IMAGE):latest

tag-version: ## Generate image `latest` tag
	@echo 'Create tag $(VERSION)'
	docker tag $(DOCKER_IMAGE) $(DOCKER_IMAGE_BASE)$(DOCKER_ORG)/$(DOCKER_IMAGE):$(VERSION)

repo-login: ## Login to docker repo
	@echo 'Logging into DockerHub'
	docker login -u $(DOCKER_USERNAME) -p $(DOCKER_PASSWORD)

version: ## Output the current version
	@echo $(VERSION)

testit:
	if [ "$(IS_TAG)" = "0" ]; then\
		echo "Hello world";\
	fi
