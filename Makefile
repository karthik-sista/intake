# Project variables
PROJECT_NAME ?= intake_accelerator
ORG_NAME ?= cwds
REPO_NAME ?= intake

# DOCKER_REGISTRY ?= 429614120872.dkr.ecr.us-west-2.amazonaws.com
# AWS_ACCOUNT_ID ?= 429614120872
# DOCKER_LOGIN_EXPRESSION := eval $$(aws ecr get-login --registry-ids $(AWS_ACCOUNT_ID))

export HTTP_PORT ?= 81
export APP_VERSION ?= 1.$(GIT_HASH)

include Makefile.settings

.PHONY: test build release clean tag buildtag login logout publish

version:
	@ echo $(APP_VERSION)

test:
	${INFO} "Pulling latest images..."
	@ docker-compose $(TEST_ARGS) pull
	${INFO} "Building images..."
	@ docker-compose $(TEST_ARGS) build run_tests &
	@ wait
	${INFO} "Running tests..."
	@ docker-compose $(TEST_ARGS) up run_tests
	@ docker cp $$(docker-compose $(TEST_ARGS) ps -q run_tests):/reports/. reports
	@ $(call check_exit_code,$(TEST_ARGS),run_tests)
	${INFO} "Testing complete"

build:
	${INFO} "Building images..."
	@ docker-compose $(TEST_ARGS) build builder
	${INFO} "Building application artifacts..."
	@ docker-compose $(TEST_ARGS) up builder
	@ $(call check_exit_code,$(TEST_ARGS),builder)
	${INFO} "Copying application artifacts..."
	@ docker cp $$(docker-compose $(TEST_ARGS) ps -q builder):/build_artefacts/. release
	${INFO} "Build complete"

release:
	${INFO} "Pulling latest images..."
	@ docker-compose $(RELEASE_ARGS) pull &
	${INFO} "Building images..."
	@ docker-compose $(RELEASE_ARGS) build --pull nginx &
	@ docker-compose $(RELEASE_ARGS) build $(BUILD_ARGS) app
	@ wait
	${INFO} "Release image build complete..."

clean:
	${INFO} "Stopping test bubble containers..."
	@ docker-compose -f integrated-test-environment/docker-compose.bubble.yml down
	@ wait
	${INFO} "Deleting test bubble artifacts..."
	@ rm -rf integrated-test-environment
	${INFO} "Deleting application release artifacts..."
	@ rm -rf release
	${INFO} "Destroying development environment..."
	@ docker-compose $(TEST_ARGS) down --volumes || true
	${INFO} "Destroying release environment..."
	@ docker-compose $(RELEASE_ARGS) down --volumes || true
	${INFO} "Removing dangling images..."
	@ docker images -q -f label=application=$(PROJECT_NAME) -f dangling=true | xargs -I ARGS docker rmi -f ARGS
	${INFO} "Clean complete"

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS),$(call tag_image,$(RELEASE_ARGS),app,$(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag));)
	${INFO} "Tagging complete"

tag%default:
	@ make tag latest $(APP_VERSION) $(GIT_TAG)

login:
	${INFO} "Logging in to Docker registry $$DOCKER_REGISTRY..."
	@ $(DOCKER_LOGIN_EXPRESSION)
	${INFO} "Logged in to Docker registry $$DOCKER_REGISTRY"

logout:
	${INFO} "Logging out of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"

publish:
	${INFO} "Publishing release image $(call get_image_id,$(RELEASE_ARGS),app) to $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)..."
	@ $(call publish_image,$(RELEASE_ARGS),app,$(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME))
	${INFO} "Publish complete"

# Make will not attempt to evaluate arguments passed tasks as targets
%:
	@:
