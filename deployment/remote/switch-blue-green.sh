#!/bin/bash
set -e
. deployment/environments/functions.sh

LIVE_ENVIRONMENT=$(echo_live_config_environment)
echo "Environment $LIVE_ENVIRONMENT is currently live"

NEXT_ENVIRONMENT=$(bash deployment/get-non-live-environment.sh)

ENV_NAME=$NEXT_ENVIRONMENT . deployment/environments/set-live-environment.sh
