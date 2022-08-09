MAKEFLAGS += --warn-undefined-variables --no-print-directory
.SHELLFLAGS := -eu -o pipefail -c

all: help
.PHONY: all

# Use bash for inline if-statements
SHELL:=bash
APP_NAME=nomad-cli
OWNER?=weissmedia
DOCKER_REPOSITORY?=registry.hub.docker.com

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1
export BUILDKIT_INLINE_CACHE:=1
export COMPOSE_DOCKER_CLI_BUILD:=1

# Nomad configuration
export NOMAD_VERSION?=1.3.3

##@ Helpers
help: ## display this help
	@echo "$(APP_NAME)"
	@echo "====================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9_%\/-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

docker-login: DOCKER_LOGIN_CREDENTIALS?=
docker-login: ## auto login to docker repository
	docker login $(DOCKER_LOGIN_CREDENTIALS) $(DOCKER_REPOSITORY)

##@ Building
arch-conv = $(word $2,$(subst _, ,$1))
build/%: IMAGE_TAG?=latest
build/%: DARGS?=
build/%: ## build the latest image
	$(eval ARCH := $(call arch-conv,$(notdir $@),1)/$(call arch-conv,$(notdir $@),2))
	@echo "::group::Build $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME) (system's architecture)"
	docker buildx build $(DARGS) --rm --force-rm -t $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME):$(IMAGE_TAG) --build-arg nomad_version=$(NOMAD_VERSION) --build-arg architecture=$(notdir $@) . --load
	@echo -n "Built image size: "
	@docker images $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME):$(IMAGE_TAG) --format "{{.Size}}"
	@echo "::endgroup::"

	@echo "::group::Build $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME) $(ARCH)"
	docker buildx build $(DARGS) --rm --force-rm -t build-multi-tmp-cache/$(APP_NAME):$(IMAGE_TAG) --build-arg nomad_version=$(NOMAD_VERSION) --build-arg architecture=$(notdir $@) . --platform "$(ARCH),linux/arm64"
	@echo "::endgroup::"

##@ Pushing and pulling images
pull: IMAGE_TAG?=latest
pull: ## pull image
	docker pull $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME):$(IMAGE_TAG)

push: docker-login ## push all tags
	@echo "::group::Push $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME) (system's architecture)"
	docker push --all-tags $(DOCKER_REPOSITORY)/$(OWNER)/$(APP_NAME)
	@echo "::endgroup::"
