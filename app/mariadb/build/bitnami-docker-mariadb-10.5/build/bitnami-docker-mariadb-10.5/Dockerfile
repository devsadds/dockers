ARG IMAGE_TAG
FROM $IMAGE_TAG
LABEL maintainer "Bitnami <containers@bitnami.com>"

ENV HOME="/" \
    OS_ARCH="amd64" \
    OS_FLAVOUR="debian-10" \
    OS_NAME="linux"

COPY prebuildfs /
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gzip libaio1 libaudit1 libc6 libcap-ng0 libgcc1 libicu63 liblzma5 libncurses6 libpam0g libssl1.1 libstdc++6 libtinfo6 libxml2 lsof procps tar zlib1g
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "ini-file" "1.3.0-2" --checksum d89528e5d733f34ae030984584659ff10a36370d40332bd8d41c047764d39cda
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "mariadb" "10.5.10-0" --checksum c923d9f13ca0d26c5d8fa192924037177b14b486ea8552c194de1b38b6a651c1
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "gosu" "1.13.0-0" --checksum fd7257c2736164d02832dbf72e2c1ed9d875bf3e32f0988520796bc503330129
RUN chmod g+rwX /opt/bitnami
RUN mkdir /docker-entrypoint-initdb.d

COPY rootfs /
COPY files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
COPY files/initbash_profile.sh /usr/sbin/initbash_profile
RUN /opt/bitnami/scripts/mariadb/postunpack.sh
ARG CONSUL_VERSION
ENV BITNAMI_APP_NAME="mariadb" \
    BITNAMI_IMAGE_VERSION="10.5.10-debian-10-r34" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/mariadb/bin:/opt/bitnami/mariadb/sbin:$PATH"
RUN apt-get update && apt install -y \
        libnet-ifconfig-wrapper-perl/stable \
        wget unzip nano \
    &&  mkdir -p /docker-info.d/ \
    && chmod +x   /usr/sbin/bashrc_alias.sh /usr/sbin/initbash_profile \
    &&  /bin/bash -C "/usr/sbin/initbash_profile" \
    && VERSION_MYSQL=$(mysqld --version | grep version | awk '{print $3}') \
    && echo "VERSION_MYSQL=${VERSION_MYSQL}" >> /docker-info.d/build.info \
    && wget https://releases.hashicorp.com/consul/${CONSUL_VERSION:-1.9.6}/consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip  \
    && unzip -d /bin consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && rm consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && apt remove -y unzip wget \
    && ln -sf /opt/bitnami/mariadb/bin/mysqldump /usr/bin/mysqldump 
EXPOSE 3306

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/mariadb/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mariadb/run.sh" ]
