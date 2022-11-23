#!/bin/bash
set -e
. deployment/environments/functions.sh

LIVE_ENVIRONMENT=$(echo_live_config_environment)
echo "Environment $LIVE_ENVIRONMENT is currently live"

NON_LIVE_ENVIRONMENT=$(bash deployment/get-non-live-environment.sh)

echo "Deploying to Environment $NON_LIVE_ENVIRONMENT"

if [ "$NON_LIVE_ENVIRONMENT" = 'blue' ]; then
  NON_LIVE_HTTP_PORT='3000'
else
  NON_LIVE_HTTP_PORT='3001'
fi

NAME=$NON_LIVE_ENVIRONMENT HTTP_PORT=$NON_LIVE_HTTP_PORT bash deployment/environments/start-environment.sh
