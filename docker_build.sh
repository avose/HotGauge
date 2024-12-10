#!/bin/sh
#docker build --no-cache --tag hotgauge .
#docker build --tag hotgauge .
#docker build --progress=plain --build-arg --tag hotgauge CACHEBUST=$(date +%s) . 2>&1 | tee docker_build.log
#docker build --build-arg --tag hotgauge CACHEBUST=$(date +%s) .
docker build --build-arg CACHEBUST=1 --tag hotgauge .
