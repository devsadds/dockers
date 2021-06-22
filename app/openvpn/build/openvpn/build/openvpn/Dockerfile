ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG APP_VERSION
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update \
    	openvpn=$APP_VERSION \
    	openvpn-auth-pam \
    	iptables \
    	bash \
    	easy-rsa \
    	google-authenticator \
    	pamtester \
        dnsmasq \
        supervisor \
    && ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*
ADD ./otp/openvpn /etc/pam.d/
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/* \
	&& openvpn --version \
    && touch /tmp/dnsmasq.log \
    && ln -sf /dev/stdout /tmp/dnsmasq.log

ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars
ENV EASYRSA_CRL_DAYS 13650


VOLUME ["/etc/openvpn", "/etc/dnsmasq.d"]
EXPOSE 1194/udp 1194

CMD ["ovpn_run"]