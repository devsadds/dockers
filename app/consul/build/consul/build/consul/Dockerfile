ARG BASE_IMAGE
FROM ${BASE_IMAGE}
RUN mkdir -p /consul/config/ \
	&&  apk add --no-cache bash 
ADD files/configs/consul/config.json /consul/config/config.json
ADD files/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 777 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [""]
