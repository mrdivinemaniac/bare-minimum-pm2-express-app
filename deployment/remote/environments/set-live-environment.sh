#!/bin/bash
set -e
. deployment/environments/functions.sh

# Ensure ENV_PORT is set
if [ -z "$ENV_NAME" ]
then
  echo "ENV_NAME is required"
  exit 1
fi

echo "Setting $ENV_NAME as the live environment"

APP_NAME=$(echo_pm2_app_name $ENV_NAME)
# Step 1: Ensure target environment is online
assert_pm2_app_online $APP_NAME

# Step 2: Create nginx configuration
echo "Creating nginx configuration"
create_live_nginx_config $ENV_NAME

# Step 3: Restart nginx
echo "Restarting nginx"
restart_nginx
