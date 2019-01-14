#!/usr/bin/env bash

git config --global user.name ${GIT_USER_NAME:-"stakater-user"}

git config --global user.email ${GIT_USER_EMAIL:-"stakater@gmail.com"}

mkdir -p ${HOME}/.ssh/

ssh-keyscan github.com > ${HOME}/.ssh/known_hosts

exec $@