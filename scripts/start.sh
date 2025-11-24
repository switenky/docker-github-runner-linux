#!/bin/bash

GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"

REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --unattended --url https://github.com/${GH_OWNER}/${GH_REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME} --disableupdate

cleanup() {
    echo "Removing runner..."
    # Get a fresh token in case the old one expired
    REMOVE_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/remove-token | jq .token --raw-output)
    if [ "$REMOVE_TOKEN" != "null" ] && [ -n "$REMOVE_TOKEN" ]; then
        ./config.sh remove --unattended --token ${REMOVE_TOKEN}
        echo "Runner ${RUNNER_NAME} removed successfully"
    else
        echo "Failed to get removal token, runner may need manual cleanup"
    fi
}

# Trap multiple signals to ensure cleanup
trap 'cleanup; exit 130' INT    # Ctrl+C
trap 'cleanup; exit 143' TERM   # Docker stop  
trap 'cleanup; exit 129' HUP    # Terminal hangup

./run.sh & wait $!