#!/bin/bash
export GIT_REPO="git@github.com:mrdivinemaniac/bare-minimum-pm2-express-app.git"
export ENV_DIRECTORY="$HOME/app/environments"
export NGINX_CONFIGS_DIRECTORY="/etc/nginx"
export SERVICE_DOMAIN="myapp.local"
export ENV_NGINX_CONFIG_TEMPLATE="$HOME/deployment/environments/env-nginx-config-template"
export LIVE_NGINX_CONFIG_TEMPLATE="$HOME/deployment/environments/env-nginx-config-template"

create_nginx_config () {
  local TEMPLATE_PATH=$1 #The file to use to use a template
  local ENV_NAME=$2 #The name of the environment - eg: blue, green
  local CONFIG_NAME=$3 #The name of the nginx config file
  local DOMAIN=$4 #The domain this environment is served at - eg: blue.myapp.com, myapp.com
  local HTTP_PORT=$5 #The http port this environment is listening to

  local SITES_AVAILABLE_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-available/$CONFIG_NAME"
  local SITES_ENABLED_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-enabled/$CONFIG_NAME"

  #Copy template configuration to sites-available
  cp $TEMPLATE_PATH $SITES_AVAILABLE_NGINX_CONFIG
  sed -i "s/{{ENV_NAME}}/$ENV_NAME/" $SITES_AVAILABLE_NGINX_CONFIG
  sed -i "s/{{HTTP_PORT}}/$HTTP_PORT/" $SITES_AVAILABLE_NGINX_CONFIG
  sed -i "s/{{DOMAIN}}/$DOMAIN/" $SITES_AVAILABLE_NGINX_CONFIG

  #Create symlink for sites-available/config_name in sites-enabled/config_name
  if [ ! -f $SITES_ENABLED_NGINX_CONFIG ]; then
    ln -s $SITES_AVAILABLE_NGINX_CONFIG $SITES_ENABLED_NGINX_CONFIG
  fi
}

remove_nginx_config () {
  local CONFIG_NAME=$1 #The name of the config file

  #Remove configs from both sites-available and sites-enabled
  local SITES_AVAILABLE_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-available/$CONFIG_NAME"
  local SITES_ENABLED_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-enabled/$CONFIG_NAME"
  rm $SITES_AVAILABLE_NGINX_CONFIG
  rm $SITES_ENABLED_NGINX_CONFIG
}

restart_nginx () {
  sudo systemctl restart nginx
}

create_env_nginx_config () {
  local ENV_NAME=$1 #The name of the environment - eg: blue, green
  local SUBDOMAIN=$2 #The subdomain this environment is served at - eg: blue, green, next
  local HTTP_PORT=$3 #The http port this environment is listening to

  local DOMAIN="$SUBDOMAIN.$SERVICE_DOMAIN"
  local CONFIG_NAME="$ENV_NAME.$SERVICE_DOMAIN"
  create_nginx_config $ENV_NGINX_CONFIG_TEMPLATE $ENV_NAME $CONFIG_NAME $DOMAIN $HTTP_PORT
}

remove_env_nginx_config () {
  local ENV_NAME=$1 #The name of the environment - eg: blue, green
  remove_nginx_config "$ENV_NAME.$SERVICE_DOMAIN"
}

create_live_nginx_config () {
  local ENV_NAME=$1 #The name of the environment - eg: blue, green
  local CONFIG_NAME="$ENV_NAME.$SERVICE_DOMAIN"
  local SITES_AVAILABLE_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-available/$CONFIG_NAME"
  if [ ! -f $SITES_AVAILABLE_NGINX_CONFIG ]; then
    echo "Nginx configuration for environment not found"
    exit 1
  fi
  local HTTP_PORT=$(echo_nginx_config_port $SITES_AVAILABLE_NGINX_CONFIG)
  create_nginx_config $LIVE_NGINX_CONFIG_TEMPLATE $ENV_NAME $SERVICE_DOMAIN $SERVICE_DOMAIN $HTTP_PORT
}

echo_nginx_config_environment () {
  local CONFIG_PATH=$1 #The path to the nginx configuration
  local ENVIRONMENT_STRING=$(eval "cat $CONFIG_PATH | grep '#environment:'")
  [[ $ENVIRONMENT_STRING =~ ^\#environment\:([a-zA-Z]+)\;[0-9]+$ ]] && echo ${BASH_REMATCH[1]}
}

echo_nginx_config_port () {
  local CONFIG_PATH=$1 #The path to the nginx configuration
  local ENVIRONMENT_STRING=$(eval "cat $CONFIG_PATH | grep '#environment:'")
  [[ $ENVIRONMENT_STRING =~ ^\#environment\:[a-zA-Z]+\;([0-9]+)$ ]] && echo ${BASH_REMATCH[1]}
}

echo_live_config_environment () {
  local SITES_AVAILABLE_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-available/$SERVICE_DOMAIN"
  if [ ! -f $SITES_AVAILABLE_NGINX_CONFIG ]; then
    echo ""
    return
  fi
  local LIVE_ENVIRONMENT=$(echo_nginx_config_environment $SITES_AVAILABLE_NGINX_CONFIG)
  echo $LIVE_ENVIRONMENT
}

echo_pm2_app_name () {
  local ENV_NAME=$1 #The name of the environment - eg: blue, green
  echo "$ENV_NAME.$SERVICE_DOMAIN"
}

assert_pm2_app_online () {
  local APP_NAME=$1 #The name of the PM2 app
  local APP_STATUS=$(eval "pm2 show $APP_NAME | grep status")
  if [[ "$APP_STATUS" == *"online"* ]]; then
    echo "Application $APP_NAME is online"
  else
    echo "Application $APP_NAME is not online."
    pm2 logs --lines 20 --nostream
    exit 1
  fi
}

assert_env_port () {
  local ENV_NAME=$1 #The name of the environment - eg: blue, green
  local PORT=$2 #The port to assert
  local CONFIG_NAME="$ENV_NAME.$SERVICE_DOMAIN"
  local SITES_AVAILABLE_NGINX_CONFIG="$NGINX_CONFIGS_DIRECTORY/sites-available/$CONFIG_NAME"
  if [ ! -f $SITES_AVAILABLE_NGINX_CONFIG ]; then
    echo "Nginx configuration for environment not found"
    exit 1
  fi
  local CURRENT_PORT=$(echo_nginx_config_port $SITES_AVAILABLE_NGINX_CONFIG)
  if [ ! $CURRENT_PORT = $PORT ]; then
    echo "Environment $ENV_NAME is not running on port $PORT"
    exit 1
  fi
}
