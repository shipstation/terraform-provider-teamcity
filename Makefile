# Project name.
PROJECT_NAME = terraform-provider-teamcity

# Makefile parameters.
TAG ?= $(shell git describe || git describe --tags)

# General.
SHELL = /bin/bash
TOPDIR = $(shell git rev-parse --show-toplevel)

# Project specifics.
BUILD_DIR = dist
INSTALL_DIR = $(HOME)/.terraform.d/plugins
PLATFORMS = linux darwin
OS = $(word 1, $@)
GOOS = $(shell uname -s | tr A-Z a-z)
GOARCH = amd64
CONTAINER_NAME = teamcity_server
INTEGRATION_TEST_DIR = integration_tests
TEAMCITY_DATA_DIR = $(INTEGRATION_TEST_DIR)/data_dir
TEAMCITY_HOST = http://localhost:8112

default: build

.PHONY: help
help: # Display help
	@awk -F ':|##' \
		'/^[^\t].+?:.*?##/ {\
			printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
		}' $(MAKEFILE_LIST) | sort

.PHONY: build
build: ## Build the project for the current platform
	mkdir -p $(BUILD_DIR)
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(BUILD_DIR)/$(PROJECT_NAME)-$(TAG)-$(GOOS)-$(GOARCH)

.PHONY: ci
ci: lint test ## Run all the CI targets

.PHONY: clean
clean: clean-code clean-docker ## Clean everything (!DESTRUCTIVE!)

.PHONY: clean-code
clean-code: ## Remove unwanted files in this project (!DESTRUCTIVE!)
	@cd $(TOPDIR) && git clean -ffdx && git reset --hard

.PHONY: clean-docker
clean-docker: ## Remove the docker container if it is running
	@docker rm -f $(CONTAINER_NAME) || true

.PHONY: dist
dist: $(PLATFORMS) ## Package the project for all available platforms
	mkdir -p $(BUILD_DIR)
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(BUILD_DIR)/$(PROJECT_NAME)-$(TAG)-$(GOOS)-$(GOARCH)

.PHONY: install
install: ## Install the plugin the in terraform.d directory
	mkdir -p $(INSTALL_DIR)
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(INSTALL_DIR)/$(PROJECT_NAME)

.PHONY: lint
lint: ## Run the static analyzers
	gometalinter --skip=vendor ./... || true

.PHONY: setup
setup: ## Setup the full environment (default)
	dep ensure
	gometalinter --install || true

.PHONY: test
test: ## Run the unit/integration tests
	@test -d  $(TEAMCITY_DATA_DIR) || tar xfz $(INTEGRATION_TEST_DIR)/teamcity_data.tar.gz -C $(INTEGRATION_TEST_DIR)
	@curl -sL https://download.octopusdeploy.com/octopus-teamcity/4.42.1/Octopus.TeamCity.zip -o $(TEAMCITY_DATA_DIR)/plugins/Octopus.TeamCity.zip
	@echo "rest.listSecureProperties=true" > $(TEAMCITY_DATA_DIR)/config/internal.properties
	@test -n "$$(docker ps -q -f name=$(CONTAINER_NAME))" || docker run --rm -d \
		--name $(CONTAINER_NAME) \
		-v $(PWD)/$(TEAMCITY_DATA_DIR):/data/teamcity_server/datadir \
		-v $(PWD)/$(INTEGRATION_TEST_DIR)/log_dir:/opt/teamcity/logs \
		-p 8112:8111 \
		jetbrains/teamcity-server:2018.1.3
	@echo -n "Teamcity server is booting (this may take a while)..."
	@until $$(curl -o /dev/null -sfI $(TEAMCITY_HOST)/login.html);do echo -n ".";sleep 5;done
	@export TEAMCITY_ADDR=$(TEAMCITY_HOST) TEAMCITY_USER=admin TEAMCITY_PASSWORD=admin TF_ACC=1\
		&& go test -v -failfast -timeout 90s ./...

.PHONY: $(PLATFORMS)
$(PLATFORMS): # Build the project for all available platforms
	mkdir -p $(BUILD_DIR)
	GOOS=$(OS) GOARCH=$(GOARCH) go build -o $(BUILD_DIR)/$(PROJECT_NAME)-$(TAG)-$(OS)-$(GOARCH)

