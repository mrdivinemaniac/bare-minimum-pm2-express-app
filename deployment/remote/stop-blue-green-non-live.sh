#!/bin/bash
set -e
. deployment/environments/functions.sh

LIVE_ENVIRONMENT=$(echo_live_config_environment)
echo "Environment $LIVE_ENVIRONMENT is currently live"

NON_LIVE_ENVIRONMENT=$(bash deployment/get-non-live-environment.sh)

NAME=$NON_LIVE_ENVIRONMENT bash deployment/environments/stop-environment.sh
