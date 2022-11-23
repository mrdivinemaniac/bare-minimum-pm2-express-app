#!/bin/bash
. deployment/environments/functions.sh

# Ensure name of environment is set
if [ -z "$NAME" ]
then
  echo "NAME is required"
  exit 1
fi

echo "Stopping environment $NAME"

LIVE_ENVIRONMENT=$(echo_live_config_environment)
echo "Current Live Environment is $LIVE_ENVIRONMENT"

if [ "$LIVE_ENVIRONMENT" = $NAME ]; then
  echo "Cannot stop live environment"
  exit 1
fi
APP_NAME=$(echo_pm2_app_name $NAME)

# Step 1: Stop the application
echo "Stopping application"
pm2 stop "$APP_NAME"
pm2 delete "$APP_NAME"

# Step 2: Remove nginx config
echo "Removing nginx config"
remove_env_nginx_config $NAME

# Step 3: Restart nginx
echo "Restarting nginx"
restart_nginx
