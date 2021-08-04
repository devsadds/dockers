ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

RUN apt-get update \
	&& apt install -y bash curl iproute2 net-tools iputils-ping  \
	&& localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
	&& rm -rfv /var/lib/apt/lists/*
ENV LANG ru_RU.utf8
COPY files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
COPY files/initbash_profile.sh /usr/sbin/initbash_profile
COPY files/docker-entrypoint.d /docker-entrypoint.d/
COPY files/pgscripts /pgscripts/
RUN apt-get update && apt install -y \
        libnet-ifconfig-wrapper-perl/stable \
        wget unzip nano  \
    &&  mkdir -p /docker-info.d/ \
    && chmod +x   /usr/sbin/bashrc_alias.sh /usr/sbin/initbash_profile \
    &&  /bin/bash -C "/usr/sbin/initbash_profile" \
    && wget https://releases.hashicorp.com/consul/${CONSUL_VERSION:-1.9.6}/consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip  \
    && unzip -d /bin consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && rm consul_${CONSUL_VERSION:-1.9.6}_linux_amd64.zip \
    && apt remove -y unzip wget \
    #&& sed -i '/#set -o xtrace/a bash /docker-entrypoint.d/consul_agent.sh' /opt/bitnami/scripts/postgresql/entrypoint.sh \
    && chmod 777 -R -v /pgscripts/