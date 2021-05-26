ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ARG APP_VERSION
ARG FLUENTD_MODULES
ENV FLUENTD_VERSION=${APP_VERSION}
ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"
ENV LD_PRELOAD=""
ENV DUMB_INIT_SETSID 0

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
           ca-certificates \
           supervisor \
           ruby  \
           ruby-irb \
           ruby-etc \
           ruby-webrick \
           tzdata \
           libmaxminddb \
           geoip-dev \
           geoip \
           ruby-bigdecimal \
           libpq \
           su-exec \
           dumb-init \
           curl \
    && apk add --no-cache --virtual .build-deps \
           build-base \
           ruby-dev \
           wget \
           gnupg \
           ruby-dev \
           automake \
           postgresql-dev \
           autoconf \
           libtool \
           libc6-compat \
&& update-ca-certificates 2>/dev/null || true \
        && echo 'gem: --no-document' >> /etc/gemrc \
        && gem install oj -v 3.11.5 \
        && gem install json -v 2.5.1 \
        && gem install bigdecimal \
        && gem install typhoeus \
        && gem install geoip2_compat \
&& gem install fluentd -v ${FLUENTD_VERSION} \
        && for FLUENTD_MODULE in $(echo ${FLUENTD_MODULES} | tr ","  " ");do \
          echo "Install fluentd module ${FLUENTD_MODULE}" && gem install ${FLUENTD_MODULE}; \
        done \
&& rm -rf /var/cache/apk/* \
&& rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem \
&& mkdir -p /fluentd/log  /fluentd/buffer /fluentd/etc /fluentd/plugins /etc/supervisor/conf.d/ /etc/supervisor.d/ /etc/fluentd/plugins \
&& echo 'Create supervisord conf'  \
       && { \
       echo '[supervisord]'; \
       echo 'nodaemon=true'; \
       echo ''; \
       echo ''; \
       echo '[program:fluentd]'; \
       echo 'command=fluentd -c /etc/fluentd/fluent.conf -p /etc/fluentd/plugins'; \
       echo 'autostart=true'; \
       echo 'autorestart=unexpected'; \
       echo 'stdout_logfile=/proc/self/fd/2'; \
       echo 'stdout_logfile_maxbytes=0'; \
       echo 'stderr_logfile=/proc/self/fd/2'; \
       echo 'stderr_logfile_maxbytes=0'; \
       echo 'exitcodes=0'; \
       echo ''; \
       echo ''; \
       echo ''; \
       echo ''; \
       echo ''; \
       echo '[include]'; \
       echo 'files = /etc/supervisor.d/*.ini'; \
        } | tee /etc/supervisor.d/fluentd.ini \
&& apk del .build-deps
COPY fluent.conf /etc/fluentd/
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
EXPOSE 516
ENTRYPOINT ["/docker-entrypoint.sh"]