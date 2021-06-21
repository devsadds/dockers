ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG APP_VERSION
ENV APP_VERSION ${APP_VERSION}
RUN apk update && apk add bash curl gettext
COPY files/configs/nginx /etc/nginx
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
COPY files/docker-healtcheck.sh /docker-healtcheck.sh
RUN chmod +x /docker-entrypoint.sh /docker-healtcheck.sh

EXPOSE 9096 9104 9100 
ENTRYPOINT ["/docker-entrypoint.sh"]