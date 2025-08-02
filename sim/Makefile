APP_NAME ?= neuroflight
TAG ?= latest
DOCKERFILE ?= Dockerfile
BASE_DIR ?= $(shell pwd)

# Build the Docker image
.PHONY: build
build:
	@echo "Building Docker image: $(APP_NAME):$(TAG)"
	docker buildx build --platform linux/amd64 --tag $(APP_NAME):$(TAG) --file $(DOCKERFILE) --load .

run: build
	# enable access to xhost from the container
	xhost +
	# Run docker and open bash shell
	docker run -it --privileged \
  	--env=LOCAL_USER_ID="$(id -u)" \
  	-v $(BASE_DIR)/PX4-Autopilot:/src/PX4-Autopilot:rw \
  	-v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  	-e DISPLAY=:0 \
  	--network host \
  	--name=$(APP_NAME) \
  	$(APP_NAME) \
  	bash


.PHONY: clean
clean:
	@echo "Cleaning up Docker images: $(APP_NAME)"
	-docker rmi -f $(APP_NAME):$(TAG)
	@echo "Cleaning up dangling images"
	-docker image prune -f
	docker rm $(APP_NAME)
