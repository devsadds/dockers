ARG DOCKER_BASE_IMAGE
FROM ${DOCKER_BASE_IMAGE}
ARG CONSUL_VERSION
ENV DEBIAN_FRONTEND noninteractive
ENV DATADIR /var/lib/mysql
LABEL maintainer "unnforgiven <a.v.galushko86@gmail.com>"
RUN groupadd -g 1001 mysql \
	&& useradd -u 1001 -r -g 1001 -s /sbin/nologin -c "Default Application User" mysql \
	&& apt-get update -qq \
	&& apt-get install -qqy --no-install-recommends \
		       apt-transport-https \
		       ca-certificates \
		       pwgen \
		       wget \
		       dnsutils \
		       unzip \
		       net-tools  \
		       curl \
		       gnupg2 \
		       lsb-release \
		       tzdata \
		       supervisor \
		       inetutils-ping \
    && cd /tmp \
	&& wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb && dpkg -i percona-release_latest.generic_all.deb ||  apt-get install --fix-broken -y \
	&& apt-get update && apt-get install -y percona-xtradb-cluster-57 \
	&& apt-get install -y pmm2-client \
	&& echo "PXc Mysqld version" \
	&& echo "-----------------------" \
	&& mysqld --version \
	&& echo "-----------------------" \
	&& sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf \
	&& rm -rf /var/lib/mysql \
	&& mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 777 /var/run/mysqld \
	&& sed -ri 's/^bind-address/#&/' /etc/mysql/my.cnf \
	&& wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip  \
    && unzip -d /bin consul_${CONSUL_VERSION}_linux_amd64.zip \
	&& sed -ri 's/^log_error/#&/' /etc/mysql/my.cnf \
	&& rm -rfv /var/lib/apt/lists/* /tmp/*

COPY files/wsrep_notify.sh /docker-scripts.d/
COPY files/node.cnf /etc/mysql/conf.d/node.cnf
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
COPY files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
COPY files/initbash_profile.sh /usr/sbin/initbash_profile


RUN mkdir /docker-info.d/ /tmp/logs \
	&& chmod 777 -R -v /docker-scripts.d/ \
	&& chmod +x /docker-entrypoint.sh  /usr/sbin/bashrc_alias.sh /usr/sbin/initbash_profile \
	&& chown -R -v mysql:mysql  /docker-info.d/  /docker-scripts.d/ /etc/mysql /docker-entrypoint.sh /tmp/logs \
	&&  /bin/bash -C "/usr/sbin/initbash_profile" \
	&& VERSION_XTRABACKUP=$(xtrabackup --version 2>&1 | grep version | awk '{print $3}') \
	&& VERSION_MYSQL=$(mysqld --version | grep version | awk '{print $3}') \
	&& VERSION_CONSUL=${CONSUL_VERSION} \
	&& DOCKER_BUILD_DATA=$(date +%Y_%m_%d_%R_%Z) \
	&& echo "DOCKER_BUILD_DATA=${DOCKER_BUILD_DATA}" > /docker-info.d/build.info \
	&& echo "DOCKER_BASE_IMAGE=ubuntu:bionic" >> /docker-info.d/build.info \
	&& echo "VERSION_XTRABACKUP=${VERSION_XTRABACKUP}" >> /docker-info.d/build.info \
	&& echo "VERSION_MYSQL=${VERSION_MYSQL}" >> /docker-info.d/build.info \
	&& echo "VERSION_CONSUL=${VERSION_CONSUL}" >> /docker-info.d/build.info \
	&& echo "--------Build info--------------" \
	&& cat /docker-info.d/build.info \
	&& echo "--------Build info----------------" \
    && usermod -a -G tty mysql
VOLUME ["/var/lib/mysql", "/var/log/mysql"]
EXPOSE 3306 4567 4568
USER root
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [""]
