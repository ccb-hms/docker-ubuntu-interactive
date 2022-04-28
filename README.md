# docker-ubuntu-interactive
A repository for Ubuntu containers tooled for interactive login with s6 supervisor, with the goal of providing multi-architecture (ARM64 and AMD64) images.

This README needs work.  Barebones notes to myself for the time being.

## Setting up multi-arch distributed build
```
# from an ARM64 host with AMD64 remote
# (reverse arm64 and amd64 platforms in the next two buildx commands if
# executing from AMD64 host with ARM64 remote)

docker buildx create --name distributed_builder --node distributed_builder_arm64 --platform linux/arm64  --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000

# this assumes password-less ssh authentication has been set up for 
# REMOTE_USER@REMOTE_HOST

docker buildx create --name distributed_builder --append --node distributed_builder_amd64 --platform linux/amd64 ssh://REMOTE_USER@REMOTE_HOST --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=10000000 --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=10000000

docker buildx use distributed_builder

docker buildx inspect --bootstrap
```

## Building
```
docker buildx build --platform linux/arm64,linux/amd64 --progress=plain --push --tag "hmsccb/ubuntu-interactive:20.04" -f 20.04.Dockerfile .
```

## Running
```
docker \
    run \
    --rm \
    --name ubuntu-interactive \
    -d \
    -v /tmp:/HostData \
    -p 2200:22 \
    -e CONTAINER_USER_USERNAME=test \
    -e CONTAINER_USER_PASSWORD=test \
    hmsccb/ubuntu-interactive:20.04
```