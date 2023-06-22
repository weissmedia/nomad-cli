MAKEFLAGS += --warn-undefined-variables --no-print-directory
.SHELLFLAGS := -eu -o pipefail -c

all: help
.PHONY: all

# Use bash for inline if-statements
SHELL:=bash

# Application settings
APP_NAME=orca-cli
OWNER?=weissmedia
DOCKER_REPOSITORY?=docker.io

# Create TAG_NAME
BRANCH_NAME:=$(shell git branch --show-current)
export TAG_NAME:=$(shell echo $(BRANCH_NAME) | sed 's/\//-/')

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1
export BUILDKIT_INLINE_CACHE:=1
export COMPOSE_DOCKER_CLI_BUILD:=1

# Nomad configuration
export NOMAD_VERSION?=1.5.6
export LEVANT_VERSION?=0.3.1

##@ Helpers
help: ## display this help
	@echo "$(APP_NAME)"
	@echo "====================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9_%\/-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

docker-login: DOCKER_LOGIN_CREDENTIALS?=
docker-login: ## auto login to docker repository
	docker login $(DOCKER_LOGIN_CREDENTIALS) $(DOCKER_REPOSITORY)

##@ Levant
levant-get:
	@rm -rf /tmp/levant \
	&& git clone git@github.com:hashicorp/levant.git /tmp/levant \
	&& cd /tmp/levant \
	&& git checkout tags/$(LEVANT_VERSION) \
	&& make build \
	&& cd - \
	&& cp /tmp/levant/bin/levant levant \
	&& chmod +x levant

##@ Building
show-arch: ## shows all available architectures
	@curl -s https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS \
		-o /tmp/nomad_SHA256SUMS
	@awk -F_ '{print $$3"_"$$4}' /tmp/nomad_SHA256SUMS | cut -d'.' -f1

build: DARGS?=--load
build: ## build the image
	docker buildx build $(DARGS) --rm --force-rm --no-cache \
		-t $(OWNER)/$(APP_NAME):latest \
		-t $(OWNER)/$(APP_NAME):interpol-78fb2a3ad55 \
		-t $(OWNER)/$(APP_NAME):nomad-$(NOMAD_VERSION) \
		-t $(OWNER)/$(APP_NAME):levant-$(LEVANT_VERSION) \
		--build-arg nomad_version=$(NOMAD_VERSION) \
		--build-arg levant_version=$(LEVANT_VERSION) \
		.

push: ## push the image
	$(MAKE) build DARGS=--push

