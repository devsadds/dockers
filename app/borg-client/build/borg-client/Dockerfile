ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG APP_VERSION
MAINTAINER a.v.galushko86@gmail.com
ENV LANG en_US.UTF-8
RUN apk add --no-cache openssh \
		sshfs \
		borgbackup=${APP_VERSION}-r1 \
		fuse-common  \
		bash \
		py-pip \
		curl \
	&& adduser -D -u 1000 borg \
    && pip install setuptools \
	&& echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
	&& mkdir -p /borg_client
COPY borg-backup.sh /
COPY borg_exclude_default.list /borg_client/borg_exclude_default.list
RUN chmod 777 /borg-backup.sh \
		&& cat /borg_client/borg_exclude_default.list
CMD [ "/borg-backup.sh" ]