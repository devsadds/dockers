ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

RUN apk add bash curl

COPY files/pgscripts /pgscripts/
RUN chown -R postgres /pgscripts &&  chmod +x /pgscripts/*