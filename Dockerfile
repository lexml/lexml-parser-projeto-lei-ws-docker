FROM tomcat:8.0-jre8
USER root
RUN  apt-get update && \
     apt-get -y install abiword alex && \
     curl -sSL https://get.haskellstack.org/ | sh && \
     mkdir -p /areastorage/parser/mensagemUsuario && \
     mkdir -p /areastorage/parser/results && \
     chown -R 2000:2000 /areastorage && \
     mkdir -p /opt/stack
WORKDIR /opt/stack
COPY lexml-linker .
RUN  stack install --local-bin-path /usr/bin

WORKDIR /usr/local/tomcat
COPY lexml-parser-projeto-lei-ws/target/lexml-parser.war ./webapps
RUN  mkdir /areastorage/parser/lexml-static
COPY lexml-parser-projeto-lei-ws/src/main/resources/lexml-static /areastorage/parser/lexml-static
