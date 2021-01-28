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

    && ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 13650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp 1194

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/* \
	&& openvpn --version

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
