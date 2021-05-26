ARG BASE_IMAGE
FROM $BASE_IMAGE
ARG APP_VERSION
ENV CRYPTOGRAPHY_DONT_BUILD_RUST "1"
RUN apk --update upgrade && \
    apk add gcc libffi-dev musl-dev python3-dev openssl-dev tzdata libmagic && \
    rm -rf /var/cache/apk/* && \
    pip install elastalert==${APP_VERSION} && \
    apk del gcc libffi-dev musl-dev python3-dev openssl-dev

RUN mkdir -p /opt/elastalert/config && \
    mkdir -p /opt/elastalert/rules && \
    echo "#!/bin/sh" >> /opt/elastalert/run.sh && \
    echo "set -e" >> /opt/elastalert/run.sh && \
    echo "elastalert-create-index --config /opt/elastalert/config.yaml" >> /opt/elastalert/run.sh && \
    echo "exec elastalert --verbose --config /opt/elastalert/config.yaml  \"\$@\"" >> /opt/elastalert/run.sh && \
    chmod +x /opt/elastalert/run.sh

ENV TZ "UTC"

VOLUME [ "/opt/elastalert/config", "/opt/elastalert/rules" ]
WORKDIR /opt/elastalert
ENTRYPOINT ["/opt/elastalert/run.sh"]