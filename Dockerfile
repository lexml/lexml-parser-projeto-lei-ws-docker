FROM tomcat:8.0-jre8-slim as build-base
RUN mkdir /opt/lexml && \
    apt-get update && \
    apt-get -y install git 

FROM tomcat:8.0-jre8-slim as runtime-base    
RUN apt-get update && \
    apt-get install -y abiword && \
    rm -fRv \
      /usr/local/tomcat/webapps/docs \
      /usr/local/tomcat/webapps/examples \
      /usr/local/tomcat/webapps/manager \
      /usr/local/tomcat/webapps/host-manager \
      /usr/local/tomcat/webapps/ROOT \
      /usr/local/tomcat/webapps/ROOT \
      /usr/lib/x86_64-linux-gnu/libLLVM* \
      /usr/lib/x86_64-linux-gnu/dri \
      /usr/share/icons

FROM lexmlbr/lexml-linker:1.0 as linker-base

FROM build-base as maven-base
RUN apt-get update && \
    apt-get -y install maven

FROM maven-base as build-parser-deps
WORKDIR /opt/lexml
RUN mkdir -p /root/.m2
COPY m2-settings.xml /root/.m2/settings.xml
ARG version=latest
RUN git clone https://github.com/lexml/lexml-parser-projeto-lei-ws.git && \
    cd lexml-parser-projeto-lei-ws && \
    if [ "latest" != "$version" ]; then git checkout $version; fi && \
    ls | grep -v 'pom\.xml' | xargs rm -fRv && \
    mvn dependency:go-offline && \
    cd .. && \
    rm -fR lexml-parser-projeto-lei-ws

FROM build-parser-deps as build-parser
WORKDIR /opt/lexml
RUN git clone https://github.com/lexml/lexml-parser-projeto-lei-ws.git && \
    cd lexml-parser-projeto-lei-ws && \
    if [ "latest" != "$version" ]; then git checkout $version; fi && \
    mvn clean package

FROM runtime-base
ARG uid
ARG gid
RUN mkdir -p /areastorage/parser/mensagemUsuario && \
    mkdir -p /areastorage/parser/results && \
    mkdir -p /areastorage/lexml-static && \
    groupadd -g $gid -r tomcat && \
    useradd -u $uid -r -g tomcat -d /usr/local/tomcat tomcat && \
    chown -R tomcat. /usr/local/tomcat && \
    chown -R tomcat. /areastorage
VOLUME /areastorage/parser
COPY --from=linker-base /usr/bin/simplelinker /usr/local/bin
USER tomcat:tomcat
WORKDIR /usr/local/tomcat
COPY --from=build-parser /opt/lexml/lexml-parser-projeto-lei-ws/target/lexml-parser.war ./webapps
COPY --from=build-parser /opt/lexml/lexml-parser-projeto-lei-ws/src/main/resources/lexml-static/ /areastorage/lexml-static
