FROM docker.io/bitnami/minideb:buster
LABEL maintainer "Bitnami <containers@bitnami.com>"

ENV HOME="/" \
    OS_ARCH="amd64" \
    OS_FLAVOUR="debian-10" \
    OS_NAME="linux"

COPY prebuildfs /
# Install required system packages and dependencies
RUN install_packages acl ca-certificates curl gzip libaio1 libc6 libcom-err2 libgcc1 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libncurses6 libsasl2-2 libssl1.1 libstdc++6 libtinfo6 lsof procps tar
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "ini-file" "1.3.0-2" --checksum d89528e5d733f34ae030984584659ff10a36370d40332bd8d41c047764d39cda
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "mysql" "8.0.25-0" --checksum ac2aa9081eb14b51a897da6250a534e680c59bf472a3b46d59fa09a6e1f5baca
RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "gosu" "1.13.0-0" --checksum fd7257c2736164d02832dbf72e2c1ed9d875bf3e32f0988520796bc503330129
RUN chmod g+rwX /opt/bitnami
RUN mkdir /docker-entrypoint-initdb.d /docker-info.d

COPY rootfs /
RUN /opt/bitnami/scripts/mysql/postunpack.sh
ENV BITNAMI_APP_NAME="mysql" \
    BITNAMI_IMAGE_VERSION="8.0.25-debian-10-r35" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/mysql/bin:/opt/bitnami/mysql/sbin:$PATH"
ARG CONSUL_VERSION
COPY files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
COPY files/initbash_profile.sh /usr/sbin/initbash_profile
COPY files/consul_agent.sh /docker-info.d/consul_agent.sh
RUN apt-get update && apt install -y \
        libnet-ifconfig-wrapper-perl/stable \
        wget unzip nano \
    && chmod +x   /usr/sbin/bashrc_alias.sh /usr/sbin/initbash_profile /docker-info.d/consul_agent.sh \
    &&  /bin/bash -C "/usr/sbin/initbash_profile" \
    && VERSION_MYSQL=$(mysqld --version | grep version | awk '{print $3}') \
    && echo "VERSION_MYSQL=${VERSION_MYSQL}" >> /docker-info.d/build.info \
    && wget https://releases.hashicorp.com/consul/${CONSUL_VERSION:-1.9.6}/consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip  \
    && unzip -d /bin consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && rm consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && apt remove -y unzip wget \
    && ln -sf /opt/bitnami/mariadb/bin/mysqldump /usr/bin/mysqldump \
    && sed -i '/mysql-env.sh.*/a \\bash /docker-info.d/consul_agent.sh' /opt/bitnami/scripts/mysql/entrypoint.sh \
    && cat /opt/bitnami/scripts/mysql/entrypoint.sh

EXPOSE 3306

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/mysql/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mysql/run.sh" ]
