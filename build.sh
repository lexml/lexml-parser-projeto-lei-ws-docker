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
if [ -f "m2-settings.xml" ] ; then
  echo "Custom Maven settings found"
else
  echo "Custom Maven settings not found. Generating a generic configuration"
  cat > m2-settings.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
</settings>
EOF
fi

docker build ${EXTRA_PARAMS} --build-arg uid=2000 --build-arg gid=2000 --build-arg version=${VERSION} . -t lexmlbr/parser-projeto-lei-ws:${VERSION}
