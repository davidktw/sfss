#!/usr/bin/env bash

docker network ls | grep sfss-network || docker network create -d bridge sfss-network
docker run --rm -d --network=sfss-network --name sfss-server sfss-server
