FROM docker.io/bitnami/minideb:buster
LABEL maintainer "Bitnami <containers@bitnami.com>"

ENV HOME="/" \
    OS_ARCH="amd64" \
    OS_FLAVOUR="debian-10" \
    OS_NAME="linux"

COPY prebuildfs /
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gzip libbsd0 libbz2-1.0 libc6 libedit2 libffi6 libgcc1 libgmp10 libgnutls30 libhogweed4 libicu63 libidn2-0 libldap-2.4-2 liblz4-1 liblzma5 libnettle6 libp11-kit0 libpcre3 libreadline7 libsasl2-2 libsqlite3-0 libssl1.1 libstdc++6 libtasn1-6 libtinfo6 libunistring2 libuuid1 libxml2 libxslt1.1 libzstd1 locales procps tar zlib1g
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "postgresql" "13.3.0-6" --checksum 025ce5b183508f9e01fab3a56f1649d9dd84403fe85a48d55e31e1dfc99f61cf
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "gosu" "1.13.0-0" --checksum fd7257c2736164d02832dbf72e2c1ed9d875bf3e32f0988520796bc503330129
RUN chmod g+rwX /opt/bitnami
RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
RUN echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen

COPY rootfs /
RUN /opt/bitnami/scripts/postgresql/postunpack.sh
RUN /opt/bitnami/scripts/locales/add-extra-locales.sh
ENV BITNAMI_APP_NAME="postgresql" \
    BITNAMI_IMAGE_VERSION="13.3.0-debian-10-r31" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
    PATH="/opt/bitnami/postgresql/bin:/opt/bitnami/common/bin:$PATH"
COPY files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
COPY files/initbash_profile.sh /usr/sbin/initbash_profile
COPY files/docker-entrypoint.d /docker-entrypoint.d/
COPY files/pgscripts /pgscripts/
RUN apt-get update && apt install -y \
        libnet-ifconfig-wrapper-perl/stable \
        wget unzip nano  curl iproute2 net-tools iputils-ping \
    &&  mkdir -p /docker-info.d/ \
    && chmod +x   /usr/sbin/bashrc_alias.sh /usr/sbin/initbash_profile \
    &&  /bin/bash -C "/usr/sbin/initbash_profile" \
    && wget https://releases.hashicorp.com/consul/${CONSUL_VERSION:-1.9.6}/consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip  \
    && unzip -d /bin consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && rm consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && apt remove -y unzip wget \
    && ln -sf /opt/bitnami/postgresql/bin/pg_dump /usr/bin/pg_dump \
    && sed -i '/#set -o xtrace/a bash /docker-entrypoint.d/consul_agent.sh' /opt/bitnami/scripts/postgresql/entrypoint.sh \
    && chmod 777 -R -v /pgscripts/

VOLUME [ "/bitnami/postgresql", "/docker-entrypoint-initdb.d", "/docker-entrypoint-preinitdb.d" ]

EXPOSE 5432

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/postgresql/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/postgresql/run.sh" ]
