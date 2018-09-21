FROM tomcat:8.0-jre8-slim
ARG http_port
ARG http_host
RUN apt-get update && \
    apt-get -y install abiword maven curl git && \
    curl -sSL https://get.haskellstack.org/ | sh && \
    mkdir -p /areastorage/parser/mensagemUsuario && \
    mkdir -p /areastorage/parser/results && \
    mkdir -p /areastorage/parser/lexml-static && \
    mkdir -p /opt/lexml && \
    cd /opt/lexml && \
    git clone https://github.com/lexml/lexml-parser-projeto-lei-ws.git && \
    cd lexml-parser-projeto-lei-ws && \
    if [ -z "$http_port" ];then : ; else mkdir /root/.m2; echo "<settings><proxies><proxy><host>$http_host</host><port>$http_port</port></proxy></proxies></settings>" > /root/.m2/settings.xml; fi && \
    mvn clean package && \
    cp target/lexml-parser.war /usr/local/tomcat/webapps && \
    cp -a src/main/resources/lexml-static/* /areastorage/parser/lexml-static && \
    rm -fr /root/.m2 && \
    cd .. && \
    git clone https://github.com/lexml/lexml-linker.git && \
    cd lexml-linker && \
    stack install --local-bin-path /usr/bin alex happy && \
    stack install --local-bin-path /usr/bin && \
    rm -fr /opt/lexml && \
    rm -fr /root/.stack
