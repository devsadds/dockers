ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG PIP_REQUIREMENTS
ARG APP_VERSION
ENV APP_VERSION $APP_VERSION
ENV PIP_REQUIREMENTS $PIP_REQUIREMENTS
RUN echo $$PIP_REQUIREMENTS
ENV DEBIAN_FRONTEND noninteractive
ENV runtimeDeps \
            rsync \
            openssh-client \
            bash \
            openssl \
            git \
            curl \
            python3 \
            python3-pip \
            gettext \
            postgresql-client \
            fping \
            sshpass \
            sudo \
            ca-certificates \
            supervisor
ENV buildDeps \
            gcc \
            make \
            g++ \
            cargo \
            python3-dev \
            libffi-dev

RUN apt update --fix-missing && apt install -y  $runtimeDeps \
    && apt install -y $buildDeps \
    && pip3 install -U wheel --user \
    && pip3 install --upgrade  --no-cache-dir ${PIP_REQUIREMENTS} \
 	&& apt-get purge -y --auto-remove $buildDeps \
 	&& rm -rf /var/lib/apt/lists/*
ARG RUN_USER
RUN groupadd -g 1001 ${RUN_USER} \
    #&& useradd -u 1000 -D -s /usr/bin/bash -G ${RUN_USER} ${RUN_USER}
    && useradd -u 1001 -r -g 1001 -s /usr/bin/bash -c "Default Application User" ${RUN_USER}
RUN mkdir -p /etc/telegram_bot \
    && chown -R -v ${RUN_USER}:${RUN_USER} /etc/telegram_bot \
    && mkdir -p /etc/telegram_bot

COPY docker-entrypoint.sh /usr/local/bin/
WORKDIR /etc/telegram_bot/
LABEL maintainer "unnforgiven <a.v.galushko86@gmail.com>"
ENTRYPOINT ["docker-entrypoint.sh"]