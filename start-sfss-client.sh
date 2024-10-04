#!/usr/bin/env bash

docker network ls | grep sfss-network || docker network create -d bridge sfss-network
docker run --rm -it --network=sfss-network --name sfss-client sfss-client
