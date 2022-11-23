#!/bin/bash
set -e
. deployment/environments/functions.sh

LIVE_ENVIRONMENT=$(echo_live_config_environment)

if [ "$LIVE_ENVIRONMENT" = 'blue' ]; then
  NON_LIVE_ENVIRONMENT='green'
else
  NON_LIVE_ENVIRONMENT='blue'
fi

echo $NON_LIVE_ENVIRONMENT
