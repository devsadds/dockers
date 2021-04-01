ARG IMAGE_TAG
FROM $IMAGE_TAG
USER root
RUN /bin/alertmanager --help \
	&& if [ ! -d "/usr/local/bin/" ];then mkdir -p  /usr/local/bin/;fi \
	&& ln -sfn /bin/alertmanager /usr/local/bin/alertmanager \
	&& chmod +x /usr/local/bin/alertmanager \
	&& /usr/local/bin/alertmanager --help \
	&& chown -R nobody /usr/local/bin/alertmanager
USER nobody