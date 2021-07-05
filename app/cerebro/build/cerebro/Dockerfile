ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG APP_VERSION
ENV APP_VERSION $APP_VERSION

RUN apt update && apt install -y bash curl wget
RUN mkdir -p /opt/cerebro/logs \
 && wget -qO- https://github.com/lmenezes/cerebro/releases/download/v${APP_VERSION}/cerebro-${APP_VERSION}.tgz \
  | tar xzv --strip-components 1 -C /opt/cerebro \
 && sed -i '/<appender-ref ref="FILE"\/>/d' /opt/cerebro/conf/logback.xml
RUN \
    useradd --create-home --uid=1000 --system   cerebro \
    #&& groupadd --gid=1001 --system human \
    && usermod -aG cerebro cerebro

COPY files/application.conf /opt/cerebro/conf/application.conf
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh \
    && chown -R cerebro:cerebro /opt/cerebro
WORKDIR /opt/cerebro
EXPOSE 9000
USER cerebro
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/opt/cerebro/bin/cerebro"]