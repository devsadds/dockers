ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

RUN apt-get update \
	&& apt install -y bash curl locales-all  inetutils-ping\
	&& localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 \
	&& rm -rfv /var/lib/apt/lists/*
ENV LANG ru_RU.utf8
COPY files/pgscripts /pgscripts/
RUN chown -R postgres /pgscripts &&  chmod +x /pgscripts/*