FROM tomcat:8.0-jre8-slim as build-base
RUN mkdir /opt/lexml && \
    apt-get update && \
    apt-get -y install git
WORKDIR /opt/lexml

FROM build-base as build-linker
COPY build-linker .
RUN apt-get update && \
    apt-get -y install curl && \
    (curl -sSL https://get.haskellstack.org/ | sh) && \
    git clone https://github.com/lexml/lexml-linker.git && \
    cd lexml-linker && \
    stack install --local-bin-path /usr/bin alex happy && \
    stack install --local-bin-path /usr/bin

FROM build-base as maven-base
RUN apt-get update && \
    apt-get -y install maven

FROM maven-base as build-parser
ARG http_port
ARG http_host
COPY build-parser .
ARG version=latest
RUN git clone https://github.com/lexml/lexml-parser-projeto-lei-ws.git && \
    cd lexml-parser-projeto-lei-ws && \
    if [ "latest" != "$version" ]; then git checkout $version; fi && \
    if [ -z "$http_port" ];then : ; else mkdir /root/.m2; echo "<settings><proxies><proxy><host>$http_host</host><port>$http_port</port></proxy></proxies></settings>" > /root/.m2/settings.xml; fi && \
    mvn clean package

FROM tomcat:8.0-jre8-slim
ARG uid
ARG gid
RUN apt-get update && \
    apt-get -y install abiword && \
    groupadd -g $gid -r tomcat && \
    useradd -u $uid -r -g tomcat -d /usr/local/tomcat tomcat && \
    mkdir -p /areastorage/parser/mensagemUsuario && \
    mkdir -p /areastorage/parser/results && \
    mkdir -p /areastorage/lexml-static && \
    chown -R tomcat. /usr/local/tomcat && \
    chown -R tomcat. /areastorage
VOLUME /areastorage/parser
COPY --from=build-linker /usr/bin/simplelinker /usr/local/bin
COPY --from=build-linker /usr/lib/x86_64-linux-gnu/libgmp.so.10 /usr/lib/x86_64-linux-gnu
USER tomcat:tomcat
WORKDIR /usr/local/tomcat
COPY --from=build-parser /opt/lexml/lexml-parser-projeto-lei-ws/target/lexml-parser.war ./webapps
COPY --from=build-parser /opt/lexml/lexml-parser-projeto-lei-ws/src/main/resources/lexml-static/ /areastorage/lexml-static
