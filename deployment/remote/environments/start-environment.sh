#!/bin/bash
. deployment/environments/functions.sh

# Ensure name of environment is set
if [ -z "$NAME" ]; then
  echo "NAME is required"
  exit 1
fi

# Ensure HTTP_PORT is set
if [ -z "$HTTP_PORT" ]; then
  echo "HTTP_PORT is required"
  exit 1
fi

# Default subdomain to the environment name if unspecified
if [ -z "$SUBDOMAIN"]; then
  SUBDOMAIN=$NAME
fi

# Fallback to the main branch if unspecified
if [ -z "$GIT_IDENTIFIER" ]; then
  GIT_IDENTIFIER="main"
fi

echo "Starting environment $NAME on HTTP port $HTTP_PORT"

# Check if port is available
PORT_ENTRY="$(lsof -i -P -n | grep "$HTTP_PORT (LISTEN)")"
if [ ! -z "$PORT_ENTRY" ]; then
  echo "Port $HTTP_PORT already has a listener. Ensuring $NAME is running on this port..."
  assert_env_port $NAME $HTTP_PORT
fi

# lsof might throw error even if it might not be of any concern
set -e

APP_NAME=$(echo_pm2_app_name $NAME)

TARGET_CODE_DIRECTORY="$ENV_DIRECTORY/$APP_NAME"
# Step 1: Start the application
echo "Starting application"
cd $TARGET_CODE_DIRECTORY
CURRENT_PROCESS_ID=$(eval "pm2 pid $APP_NAME")
if [ -z $CURRENT_PROCESS_ID ]; then
  HTTP_PORT=$HTTP_PORT pm2 start index.js --name "$APP_NAME" -i --wait-ready --listen-timeout 10000 --kill-timeout 10000
else
  echo "Application already running. Restarting..."
  HTTP_PORT=$HTTP_PORT pm2 restart $APP_NAME --update-env
fi

# Step 2: Ensure that the app is online
echo "Checking application status"
assert_pm2_app_online $APP_NAME

# Step 3: Create nginx configuration
echo "Creating nginx configuration"
create_env_nginx_config $NAME $SUBDOMAIN $HTTP_PORT

# Step 4: Restart nginx
echo "Restarting nginx"
restart_nginx
