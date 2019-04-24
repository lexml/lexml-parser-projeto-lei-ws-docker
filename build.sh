#!/bin/bash

VERSION=$1
if [ -z "$VERSION" ]; then
  VERSION="latest"
fi

function getExtraParameters {
  if [ ! -z "$http_proxy" ]; then
    PROXY_BASE=$(echo $http_proxy | cut -d/ -f3)
    PROXY_HOST=$(ip addr list docker0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
    PROXY_PORT=$(echo $PROXY_BASE | cut -d: -f2) 
    PROXY="http://"$(ip addr list docker0 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)":3128"
    echo "--build-arg http_proxy=$PROXY --build-arg https_proxy=$PROXY --build-arg http_host=$PROXY_HOST --build-arg http_port=$PROXY_PORT"
  else
    echo ""
  fi
}
EXTRA_PARAMS=$(getExtraParameters)
echo "Extra parameters: $EXTRA_PARAMS"

docker build ${EXTRA_PARAMS} --build-arg uid=2000 --build-arg gid=2000 --build-arg version=${VERSION} . -t lexmlbr/parser-projeto-lei-ws:${VERSION}
