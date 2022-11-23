#!/bin/bash
set -e
if [ -z "$KEY_FILE_PATH" ]; then
  echo "KEY_FILE_PATH is required"
  exit 1
fi

if [ -z "$SSH_TARGET" ]; then
  echo "SSH_TARGET is required"
  exit 1
fi

CURRENT_NON_LIVE_ENVIRONMENT=$(ssh -o StrictHostKeyChecking=no -i $KEY_FILE_PATH $SSH_TARGET "cd ~ && bash ./deployment/get-non-live-environment.sh")

echo "Curent non live environment is ${CURRENT_NON_LIVE_ENVIRONMENT}"

ENV_NAME=$CURRENT_NON_LIVE_ENVIRONMENT bash deployment/push-code.sh
