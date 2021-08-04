ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG PIP_REQUIREMENTS
ARG APP_VERSION
ENV ANSIBLE_VERSION=$APP_VERSION
ARG ANSIBLE_LINT_VERSION
ARG RUN_USER
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
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
    		gcc make g++ zlib-dev \
    		python3-dev \
    		musl-dev \
    		postgresql-dev \
    		libffi-dev \
    		openssl-dev \
    && pip3 install --upgrade  --no-cache-dir ${PIP_REQUIREMENTS} \
    && pip3 install dnspython \
 	&& apk del .build-deps \
 	&& rm -rf /var/cache/apk/*

RUN addgroup -g 1000 -S ${RUN_USER} \
    && adduser -u 1000 -D -s /bin/bash -G ${RUN_USER} ${RUN_USER}
RUN mkdir -p /etc/ansible_task \
    && chown -R -v ${RUN_USER}:${RUN_USER} /etc/ansible_task \
    && chmod 4755 /bin/busybox \
    && echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config
COPY files/docker-entrypoint.sh /usr/local/bin/
ENV VERSION 1.1.1
WORKDIR /etc/
ENTRYPOINT ["docker-entrypoint.sh"]