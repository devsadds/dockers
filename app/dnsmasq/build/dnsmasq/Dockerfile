ARG IMAGE_TAG
FROM $IMAGE_TAG
RUN apk --no-cache add dnsmasq bash \
	&& touch /tmp/dnsmasq.log \
	&& ln -sf /dev/stdout /tmp/dnsmasq.log

VOLUME /etc/dnsmasq

EXPOSE 53 53/udp
ENTRYPOINT ["dnsmasq", "-k"]
