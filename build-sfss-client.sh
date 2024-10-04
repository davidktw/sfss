#!/usr/bin/env bash

docker image rm sfss-client
docker image build -t sfss-client --target sfss-client --secret id=mysecrets,src=./secrets.txt .
