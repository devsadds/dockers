ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG APP_VERSION
ENV ANSIBLE_VERSION=$APP_VERSION
ARG ANSIBLE_LINT_VERSION
ARG PIP_REQUIREMENTS
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
    && apk add --no-cache --virtual .build-deps \
            cargo \
    		gcc make g++ zlib-dev \
    		python3-dev \
    		musl-dev \
    		postgresql-dev \
    		libffi-dev \
    		openssl-dev \
    && pip3 install "pip>=20" \
    && pip3 install --no-cache-dir ${PIP_REQUIREMENTS} ansible==${ANSIBLE_VERSION} ansible-lint==${ANSIBLE_LINT_VERSION}  \
 	&& apk del .build-deps \
 	&& rm -rf /var/cache/apk/* /root/.cargo
ARG RUN_USER
RUN addgroup -g 1000 -S ${RUN_USER} \
    && adduser -u 1000 -D -s /bin/bash -G ${RUN_USER} ${RUN_USER}
RUN echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts \
 		&& echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config \
 && chown -R -v ${RUN_USER}:${RUN_USER} /etc/ansible \
 && chmod 4755 /bin/busybox \
 && chown -R -v root:root /root

WORKDIR /etc/ansible