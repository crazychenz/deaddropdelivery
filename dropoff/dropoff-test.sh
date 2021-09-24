#!/bin/sh

PUSH_EVENT=$1
SCHEME=$(jq -r .scheme config.json)
HOSTNAME=$(jq -r .hostname config.json)
PICKUPKEY=$(jq -r .pickupkey config.json)

curl -v -X POST \
  -H 'Content-Type: application/json' -d @$PUSH_EVENT \
  $SCHEME://$HOSTNAME/github-dropoff/$DROPOFFKEY

