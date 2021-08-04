ARG BASE_IMAGE
FROM $BASE_IMAGE
USER root
ENV RUNTIME_DEPS \
       libpq5 \
    	rsync \
    	openssh-client \
    	bash \
    	openssl \
    	git \
    	curl \
    	gettext \
    	python3-pip \
    	postgresql-client \
    	fping \
    	sshpass \
    	ca-certificates \
        supervisor
ENV BUILD_DEPS \
        gcc \
        make \
        g++ \
        zlib-dev \
    	musl-dev \
    	postgresql-dev \
    	libffi-dev \
        build-essential \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        wget \
        libbz2-dev
#RUN apt update \
#	&& apt install -y  ${RUNTIME_DEPS}
#USER human
ENV PYHTON_DEPS \
        ipaddr \
        ipaddress \
        pika \
        sentry-sdk \
        pip \
        cffi \
        python-dateutil>=2.8.0 \
        arrow>=0.14.3 \
        jmespath \
        pyyaml \
        pycrypto \
        pywinrm \
        jmespath \
        pyapi-gitlab \
        psycopg2-binary \
        netaddr \
        demjson \
        tornado>=6.0.3 \
        requests>=2.18.4 \
        jsontree>=0.5.1 \
        threaded \
        flask \
        Flask-APScheduler \
        Flask-HTTPAuth \
        gunicorn \
        blinker \
        memorize \
        gunicorn \
        mysql-connector-python==8.0.11 \
        PyMySQL
RUN pip3 install  ${PYHTON_DEPS}
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
COPY files/app /app
#USER root
RUN chmod +x /docker-entrypoint.sh
#USER human
RUN python3.9 --version
ENTRYPOINT ["/docker-entrypoint.sh"]