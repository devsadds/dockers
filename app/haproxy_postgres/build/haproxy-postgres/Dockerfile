
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY files/configs/haproxy/haproxy.conf /etc/haproxy/haproxy.conf
COPY files/configs/consul-template /opt/consul-template/config
COPY files/docker-scripts.d /docker-scripts.d
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
RUN which supervisord \
	&& chmod +x -v -R /docker-scripts.d \
	&& chmod +x -v /docker-entrypoint.sh \
	&& ls -la /opt/consul-template/config/* \
	&& ls -la /docker-scripts.d
STOPSIGNAL SIGUSR1
ENTRYPOINT ["/docker-entrypoint.sh"]

