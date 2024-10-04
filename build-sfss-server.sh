#!/usr/bin/env bash

docker image rm sfss-server
docker image build -t sfss-server --target sfss-server --secret id=mysecrets,src=./secrets.txt .
