ARG BASE_IMAGE
FROM $BASE_IMAGE
MAINTAINER a.v.galusgko86@gmail.com
ARG APP_VERSION
#Install Borg & SSH
RUN apk add openssh sshfs screen borgbackup=$APP_VERSION supervisor --no-cache bash \
	&& adduser -D -u 1000 borg \
    && ssh-keygen -A \
    && mkdir -p /bup/borg/pool \
    && chown borg.borg /bup/borg/pool \
    && sed -i -e 's/^#PasswordAuthentication yes$/PasswordAuthentication no/g' /etc/ssh/sshd_config \
    && sed -i -e 's/^PermitRootLogin without-password$/PermitRootLogin no/g' /etc/ssh/sshd_config
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN ln -sf  /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh  \
	&& chmod +x /usr/local/bin/docker-entrypoint.sh \
	&& passwd -u borg \
	&& rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key
EXPOSE 22
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]