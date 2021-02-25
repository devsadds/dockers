# vim:set ft=dockerfile:
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG APP_VER
ARG CONSUL_VERSION
ARG CONSUL_TEMPLATE_VERSION
ENV HAPROXY_VERSION ${APP_VER}
ARG VERSION_EXPORTER_HAPROXY

RUN set -x \
	\
	&& if echo ${APP_VER} | grep -Eq "dev"; then echo "devel" && APP_SUBPATH="src/devel";else echo "prod" && APP_SUBPATH="src";fi \
	&& HAPROXY_URL="https://www.haproxy.org/download/$(echo $APP_VER | cut -c1-3)/${APP_SUBPATH}/haproxy-${APP_VER}.tar.gz" \
	&& echo "$HAPROXY_URL" \
	&& apt-get update && apt-get install -y --no-install-recommends \
		iproute2 \
		inetutils-ping \
		curl \
		liblua5.3-0 \
		ca-certificates \
		dnsutils \
		supervisor \
		net-tools \
	&& savedAptMark="$(apt-mark showmanual)" \
	&& apt-get update && apt-get install -y --no-install-recommends \
		gcc \
		libc6-dev \
		liblua5.3-dev \
		libpcre2-dev \
		libssl-dev \
		make \
		wget \
		liblua5.3-dev \
		zlib1g-dev \
		unzip \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O haproxy.tar.gz "$HAPROXY_URL" \
	&& wget -O haproxy-${APP_VER}.tar.gz.sha256  ${HAPROXY_URL}.sha256 \
	&& HAPROXY_SHA256=$(awk '{ print  $1 }' haproxy-${APP_VER}.tar.gz.sha256 ) \
	&& echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	\
	&& makeOpts=' \
		TARGET=linux-glibc \
		USE_GETADDRINFO=1 \
		USE_LUA=1 LUA_INC=/usr/include/lua5.3 \
		USE_OPENSSL=1 \
		USE_PCRE2=1 USE_PCRE2_JIT=1 \
		USE_ZLIB=1 \
		\
		EXTRA_OBJS=" \
			contrib/prometheus-exporter/service-prometheus.o \
		" \
	' \
	&& nproc="$(nproc)" \
	&& eval "make -C /usr/src/haproxy -j '$nproc' all $makeOpts" \
	&& eval "make -C /usr/src/haproxy install-bin $makeOpts" \
	\
	&& mkdir -p /usr/local/etc/haproxy  /etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& cd /tmp \
	&& mkdir -p /etc/haproxy \
	&& mkdir /opt/consul-template \
	&& curl  https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip  -o consul_${CONSUL_VERSION}_linux_amd64.zip \
 	&& curl  https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip  -o consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip \
 	&& unzip  consul_${CONSUL_VERSION}_linux_amd64.zip -d /bin \
 	&& unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -d /opt/consul-template \
 	&& ln -s /opt/consul-template/consul-template /usr/local/bin/consul-template \
 	&& mkdir -p /var/log/consul-template \
	&& apt-mark auto '.*' > /dev/null \
	&& { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; } \
	&& find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
	&& rm -rf /tmp/* \
	&& rm -rf /usr/src/haproxy \
	&& groupadd haproxy && useradd -g haproxy haproxy \
	&& mkdir -p /usr/share/haproxy /docker-scripts.d \
	&& chown -R  haproxy /usr/share/haproxy \
	&& touch /var/log/haproxy.log \
	&& touch /tmp/haproxy.log \
	&& ln -sf /dev/stdout /var/log/haproxy.log \
	&& ln -sf /dev/stdout /tmp/haproxy.log \
	&& mkdir -p /etc/prometheus/exporters/ \
	&& echo "Download exporter haproxy https://github.com/prometheus/haproxy_exporter/releases/download/v${VERSION_EXPORTER_HAPROXY}/haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64.tar.gz" \
	&& curl  https://github.com/prometheus/haproxy_exporter/releases/download/v${VERSION_EXPORTER_HAPROXY}/haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64.tar.gz -o /etc/prometheus/exporters/haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64.tar.gz -L \
	&& cd /etc/prometheus/exporters/ \
	&& tar -xvf haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64.tar.gz \
	&& cp haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64/haproxy_exporter . \
	&& rm haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64.tar.gz \
	&& rm -rf haproxy_exporter-${VERSION_EXPORTER_HAPROXY}.linux-amd64 \
	&& chmod +x /etc/prometheus/exporters/haproxy_exporter
COPY files/configs/haproxy/haproxy.conf /etc/haproxy/haproxy.conf
COPY files/configs/consul-template /opt/consul-template/config
COPY files/docker-scripts.d /docker-scripts.d
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
COPY files/docker-healthcheck.sh /docker-healthcheck.sh
RUN /usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf \
	&& which supervisord \
	&& chmod +x -v -R /docker-scripts.d \
	&& chmod +x -v /docker-entrypoint.sh /docker-healthcheck.sh \
	&& ls -la /opt/consul-template/config/* \
	&& ls -la /docker-scripts.d
STOPSIGNAL SIGUSR1
ENTRYPOINT ["/docker-entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=15s --retries=12 CMD bash /docker-healthcheck.sh