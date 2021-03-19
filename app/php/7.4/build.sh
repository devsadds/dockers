#!/bin/bash
BUILD_DATE=$(date +%Y_%m_%d__%H:%M)
echo "BUILD_DATE=${BUILD_DATE}" > .env
docker-compose build && docker-compose push
