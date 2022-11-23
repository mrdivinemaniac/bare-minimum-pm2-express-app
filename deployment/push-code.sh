#!/bin/bash
set -e
. deployment/remote/environments/functions.sh

if [ -z "$KEY_FILE_PATH" ]; then
  echo "KEY_FILE_PATH is required"
  exit 1
fi

if [ -z "$SSH_TARGET" ]; then
  echo "SSH_TARGET is required"
  exit 1
fi

# Ensure name of environment is set
if [ -z "$ENV_NAME" ]; then
  echo "ENV_NAME is required"
  exit 1
fi

# Fallback to the main branch if unspecified
if [ -z "$GIT_IDENTIFIER" ]; then
  GIT_IDENTIFIER="main"
fi

if [ -z $REPOSITORY_DIRECTORY ]; then
  echo "Setting up tmp directory"
  TMP_DIRECTORY="/tmp/deploy-checkout"
  rm -rf $TMP_DIRECTORY
  mkdir -p $TMP_DIRECTORY

  echo "Cloning repository"
  git clone $GIT_REPO $TMP_DIRECTORY
  cd $TMP_DIRECTORY

  echo "Pulling target code from repository"
  git fetch
  git checkout $GIT_IDENTIFIER
else
  echo "Git directory supplied. Using that directory"
  cd $REPOSITORY_DIRECTORY
fi

echo "Installing dependencies"
npm install

echo "Pushing code to remote"
APP_NAME=$(echo_pm2_app_name $ENV_NAME)
TARGET_CODE_DIRECTORY="$ENV_DIRECTORY/$APP_NAME"
ssh -o StrictHostKeyChecking=no -i $KEY_FILE_PATH $SSH_TARGET "rm -rf $TARGET_CODE_DIRECTORY"
rsync -Pav -e "ssh -i $KEY_FILE_PATH" ./* $SSH_TARGET:$TARGET_CODE_DIRECTORY

echo "Cleaning Up"
if [ ! -z $TMP_DIRECTORY ]; then
  rm -rf $TMP_DIRECTORY
fi
