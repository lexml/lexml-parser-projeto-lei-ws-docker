FROM tomcat:8.0-jre8-slim
ARG http_port
ARG http_host
ARG uid
ARG gid
ARG version=latest
RUN groupadd -g $gid -r tomcat && \
    useradd -u $uid -r -g tomcat -d /usr/local/tomcat tomcat && \
    mkdir -p /areastorage/parser/mensagemUsuario && \
    mkdir -p /areastorage/parser/results && \
    mkdir -p /areastorage/lexml-static && \
    mkdir -p /opt/lexml
VOLUME /areastorage/parser
RUN apt-get update && \
    apt-get -y install abiword maven curl git && \
    curl -sSL https://get.haskellstack.org/ | sh
WORKDIR /opt/lexml
COPY build-linker .
RUN git clone https://github.com/lexml/lexml-linker.git && \
    cd lexml-linker && \
    stack install --local-bin-path /usr/bin alex happy && \
    stack install --local-bin-path /usr/bin && \
    cp /usr/bin/simplelinker /usr/local/bin && \
    rm -fr /root/.stack
COPY build-parser .
RUN git clone https://github.com/lexml/lexml-parser-projeto-lei-ws.git && \
    cd lexml-parser-projeto-lei-ws && \
    if [ "latest" != "$version" ]; then git checkout $version; fi && \
    if [ -z "$http_port" ];then : ; else mkdir /root/.m2; echo "<settings><proxies><proxy><host>$http_host</host><port>$http_port</port></proxy></proxies></settings>" > /root/.m2/settings.xml; fi && \
    mvn clean package && \
    cp target/lexml-parser.war /usr/local/tomcat/webapps && \
    cp -a src/main/resources/lexml-static/* /areastorage/lexml-static && \
    rm -fr /root/.m2
WORKDIR /usr/local/tomcat
RUN chown -R tomcat. /usr/local/tomcat && \
    chown -R tomcat. /areastorage && \
    rm -fr /opt/lexml
USER tomcat:tomcat
