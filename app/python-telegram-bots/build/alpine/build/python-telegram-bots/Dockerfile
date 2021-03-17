ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG PIP_REQUIREMENTS
ARG APP_VERSION
ENV APP_VERSION $APP_VERSION
ENV PIP_REQUIREMENTS $PIP_REQUIREMENTS

RUN apk add --no-cache  \
    		libpq \
    		rsync \
    		openssh \
    		bash \
    		openssl \
    		git \
    		curl \
            python3 \
    		gettext \
    		py-pip \
    		postgresql-client \
    		fping \
    		sshpass \
    		sudo \
    		ca-certificates \
            supervisor \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
            openresty \
    && apk add --no-cache --virtual .build-deps \
    		gcc \
            make \
            g++ \
            cargo \
            zlib-dev \
    		python3-dev \
    		musl-dev \
    		postgresql-dev \
    		libffi-dev \
    		openssl-dev \
    && pip3 install -U wheel --user \
    && pip3 install --upgrade  --no-cache-dir ${PIP_REQUIREMENTS} \
 	&& apk del .build-deps \
 	&& rm -rf /var/cache/apk/*
ARG RUN_USER
RUN addgroup -g 1000 -S ${RUN_USER} \
    && adduser -u 1000 -D -s /bin/bash -G ${RUN_USER} ${RUN_USER}
RUN mkdir -p /etc/telegram_bot \
    && chown -R -v ${RUN_USER}:${RUN_USER} /etc/telegram_bot \
    && chmod 4755 /bin/busybox \
    && mkdir -p /etc/telegram_bot

COPY docker-entrypoint.sh /usr/local/bin/
WORKDIR /etc/telegram_bot/
ENTRYPOINT ["docker-entrypoint.sh"]