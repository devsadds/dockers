ARG BASE_IMAGE

FROM $BASE_IMAGE

FROM $BASE_IMAGE AS build_stage
ARG APP_VERSION
ENV PGBOUNCER_VERSION ${APP_VERSION}

LABEL maintainer "robert@aztek.io"

RUN apk --update --no-cache add \
        autoconf \
        autoconf-doc \
        automake \
        c-ares \
        c-ares-dev \
        curl \
        gcc \
        libc-dev \
        libevent \
        libevent-dev \
        libtool \
        make \
        libressl-dev \
        file \
        pkgconf

ARG PGBOUNCER_VERSION

RUN curl -Lso  "/tmp/pgbouncer.tar.gz" "https://pgbouncer.github.io/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz" && \
        file "/tmp/pgbouncer.tar.gz"

WORKDIR /tmp

RUN mkdir /tmp/pgbouncer && \
        tar -zxvf pgbouncer.tar.gz -C /tmp/pgbouncer --strip-components 1

WORKDIR /tmp/pgbouncer

RUN ./configure --prefix=/usr && \
        make

FROM $BASE_IMAGE
ARG CONSUL_VERSION
ARG CONSUL_TEMPLATE_VERSION
ARG VERSION_EXPORTER_PG_BOUNCER
# hadolint ignore=DL3018
RUN apk --update --no-cache add \
        libevent \
        libressl \
        ca-certificates \
        c-ares \
        supervisor \
        py3-pip \
        curl \
        && apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev  \
        && pip3 install prometheus-pgbouncer-exporter \
        && mkdir /opt/consul-template \
        && curl  https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip  -o consul_${CONSUL_VERSION}_linux_amd64.zip \
        && curl  https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip  -o consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
        && unzip  consul_${CONSUL_VERSION}_linux_amd64.zip -d /bin \
        && unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -d /opt/consul-template \
        && ln -s /opt/consul-template/consul-template /usr/local/bin/consul-template \
        && mkdir -p /var/log/consul-template \
        && apk --purge del .build-deps

WORKDIR /etc/pgbouncer
WORKDIR /var/log/pgbouncer

RUN chown -R postgres:root \
        /etc/pgbouncer \
        /var/log/pgbouncer

USER postgres

COPY --from=build_stage --chown=postgres ["/tmp/pgbouncer", "/opt/pgbouncer"]
COPY --chown=postgres ["docker-entrypoint.sh", "/opt/pgbouncer"]

WORKDIR /opt/pgbouncer
ENTRYPOINT ["/opt/pgbouncer/docker-entrypoint.sh"]

