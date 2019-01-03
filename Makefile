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
clean: clean-code ## Clean everything (!DESTRUCTIVE!)

.PHONY: clean-code
clean-code: ## Remove unwanted files in this project (!DESTRUCTIVE!)
	@cd $(TOPDIR) && git clean -ffdx && git reset --hard

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
test: ## Run the unit tests
	go test pkg/*

.PHONY: $(PLATFORMS)
$(PLATFORMS): # Build the project for all available platforms
	mkdir -p $(BUILD_DIR)
	GOOS=$(OS) GOARCH=$(GOARCH) go build -o $(BUILD_DIR)/$(PROJECT_NAME)-$(TAG)-$(OS)-$(GOARCH)

