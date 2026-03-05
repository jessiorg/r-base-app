#!/bin/bash
set -e

# Pull ARM64 version of R base image
docker pull --platform linux/arm64/v8 rocker/r-base:4.4.0

# Change to docker directory
cd /data/docker

# Build the r-api service with ARM64 platform
docker-compose build --no-cache --build-arg BUILDPLATFORM=linux/arm64/v8 --build-arg TARGETPLATFORM=linux/arm64/v8 r-api

# Start the service
docker-compose up -d r-api
