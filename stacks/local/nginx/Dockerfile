FROM nginx
RUN mkdir /etc/nginx/logs && \
    chmod 777 /etc/nginx/logs
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.crt /etc/nginx/nginx.crt
COPY nginx.key /etc/nginx/nginx.key
