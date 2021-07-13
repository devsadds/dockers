ARG IMAGE_TAG
FROM $IMAGE_TAG
RUN apk --no-cache add dnsmasq bash \
	&& touch /tmp/dnsmasq.log \
	&& ln -sf /dev/stdout /tmp/dnsmasq.log \
	&& if [ ! -d "/etc/dnsmasq/conf.d" ];then mkdir -p /etc/dnsmasq/conf.d ;fi \
	&& echo 'Create /etc/dnsmasq.conf'  \
       && { \
       echo 'listen-address=0.0.0.0'; \
       echo 'interface=eth0'; \
       echo 'user=root'; \
       echo 'server=8.8.8.8'; \
       echo 'conf-dir=/etc/dnsmasq/conf.d'; \
       #echo 'log-queries'; \
       #echo 'log-facility=/tmp/dnsmasq.log' ; \
       #echo 'strict-order' ; \
       #echo 'no-resolv' ; \
         } | tee /etc/dnsmasq.conf
ADD files/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 775 /docker-entrypoint.sh
VOLUME /etc/dnsmasq

EXPOSE 53 53/udp
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--keep-in-foreground", "--bogus-priv", "--log-queries", "--log-facility=-", "--strict-order", "--no-resolv"]