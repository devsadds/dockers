ARG IMAGE_TAG
FROM $IMAGE_TAG
ARG APP_VERSION
ENV APP_VERSION $APP_VERSION
RUN apk --no-cache add python bash py-setuptools py-pip gcc libffi py-cffi python-dev libffi-dev py-openssl musl-dev linux-headers openssl-dev libssl1.0 && \
    pip install elasticsearch-curator==${APP_VERSION} && \
    pip install boto3==1.9.143 && \
    pip install requests-aws4auth==0.9 && \
    pip install cryptography==2.6.1 && \
    apk del py-pip gcc python-dev libffi-dev musl-dev linux-headers openssl-dev && \
    sed -i '/import sys/a urllib3.contrib.pyopenssl.inject_into_urllib3()' /usr/bin/curator && \
    sed -i '/import sys/a import urllib3.contrib.pyopenssl' /usr/bin/curator && \
    sed -i '/import sys/a import urllib3' /usr/bin/curator
COPY files/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER nobody:nobody
ENTRYPOINT ["/docker-entrypoint.sh"]