#!/bin/bash
# Одновляет файл .env в текущей папке
# Добавляются или обновляются значения переменных:
#   REMOTE_USER, REMOTE_UID, REMOTE_GID, PIPY_USER, PIPY_PASSWORD и COMPOSE_PROJECT_NAME
# Значения других имеющихся в этом файле переменных не изменяются

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

DOCKER_CONTEXT=$(docker context inspect -f "{{.Name}}")
DOCKER_HOST=$(docker context inspect -f "{{.Endpoints.docker.Host}}")
echo DOCKER_CONTEXT="$DOCKER_CONTEXT";
if [ "$DOCKER_CONTEXT" = "default" ]; then
  echo "WARNING! Running container locally"
  REMOTE_USER=$USERNAME
  REMOTE_UID=$(id -u)
  REMOTE_GID=$(id -g)
else
  echo "running container in server"
  REMOTE_USER=$(expr  "$DOCKER_HOST" : '.*/\([^@]*\)@.*')
  REMOTE_UID=$(ssh "$DOCKER_HOST" id -u)
  REMOTE_GID=$(ssh "$DOCKER_HOST" id -g)
fi;

echo DOCKER_CONTEXT="$DOCKER_CONTEXT"
echo DOCKER_HOST="$DOCKER_HOST"
echo REMOTE_USER="$REMOTE_USER"
echo REMOTE_UID="$REMOTE_UID"
echo REMOTE_GID="$REMOTE_GID"

EXTRA_INDEX_URL=$(pip3 config get global.extra-index-url)
PIPY_USER=$(expr "$EXTRA_INDEX_URL" : '.*/\([^:]*\):.*')
PIPY_PASSWORD=$(expr  "$EXTRA_INDEX_URL" : '.*:\([^@]*\)@.*')
echo PIPY_USER="$PIPY_USER"
echo PIPY_PASSWORD=***

SCRIPT_NAME=$(realpath "$0")
PROJECT_PATH=$(dirname "$SCRIPT_NAME")
PROJECT_NAME=$(basename "$PROJECT_PATH")
COMPOSE_PROJECT_NAME="${PROJECT_NAME}-${REMOTE_USER}"
echo COMPOSE_PROJECT_NAME="$COMPOSE_PROJECT_NAME"

if [ "" = "$REMOTE_USER" -o \
    "" = "$REMOTE_UID" -o \
    "" = "$REMOTE_GID" -o \
    "" = "$PIPY_USER" -o \
    "" = "$PIPY_PASSWORD" -o \
    "" = "$COMPOSE_PROJECT_NAME" ]; then
  echo "ERROR! One of the required variables is not set"
  exit 1
fi

if [ -f .env ]; then
    sed '/\(REMOTE_USER\|REMOTE_UID\|REMOTE_GID\|PIPY_USER\|PIPY_PASSWORD\|COMPOSE_PROJECT_NAME\)=/d' .env >.env
fi

cat << EOF >> .env
REMOTE_USER=$REMOTE_USER
REMOTE_UID=$REMOTE_UID
REMOTE_GID=$REMOTE_GID
PIPY_USER=$PIPY_USER
PIPY_PASSWORD=$PIPY_PASSWORD
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
EOF
