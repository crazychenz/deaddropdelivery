#!/bin/sh

REPOHASH=$1
PREV_PICKUP=$2
SCHEME=$(jq -r .scheme config.json)
HOSTNAME=$(jq -r .hostname config.json)
PICKUPKEY=$(jq -r .pickupkey config.json)

curl -v -X GET $SCHEME://$HOSTNAME/github-pickup/$PICKUPKEY/$REPOHASH/$PREV_PICKUP
