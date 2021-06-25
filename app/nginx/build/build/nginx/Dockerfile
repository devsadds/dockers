ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ENV COMPILE_DIR /build
ENV LIBRESSL_DIR /libressl
ENV NB_PROC 12

ENV VERSION_PCRE pcre-8.42
ENV VERSION_LIBRESSL libressl-3.0.2
ARG APP_VERSION
ENV VERSION_NGINX nginx-$APP_VERSION
ENV SOURCE_LIBRESSL http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/
ENV SOURCE_PCRE https://ftp.pcre.org/pub/pcre/
ENV SOURCE_NGINX http://nginx.org/download/
ENV STATICLIBSSL $LIBRESSL_DIR/$VERSION_LIBRESSL
ENV VERSION_NGINX_DEVEL_KIT 0.3.1
ENV VERSION_LUA_NGINX_MODULE 0.10.15
ENV VERSION_LUA_JIT 2.0.5
ARG BUIL_ARG_1
RUN \
     if [ "${BUIL_ARG_1}" == "http1" ];then additional_params="--with-http_ssl_module"; else additional_params="--with-http_ssl_module --with-http_v2_module";fi \
     && echo "BUIL_ARG_1=${BUIL_ARG_1}" \
     && echo "additional_params=$additional_params" \
     && apk add --no-cache \
        openldap-dev \
        pcre \
        zlib \
        bash \
        curl \
        libressl \
        tzdata \
        ca-certificates \
        tini \
        shadow \
        brotli-libs \
        inotify-tools \
    && deluser xfs \
    && addgroup -g 33 -S www-data \
    && adduser -u 33 -D -S -G www-data www-data \
    && addgroup -g 101 -S nginx\
    && adduser -u 101 -D -S -G nginx nginx \
    && /usr/sbin/usermod -aG www-data nginx \
    && apk add --no-cache --virtual .build-deps \
     build-base \
     autoconf \
     automake \
     bind-tools \
     binutils \
     build-base \
     ca-certificates \
     cmake \
     file \
     gcc \
     gd-dev \
     geoip-dev \
     git \
     gnupg \
     libc-dev \
     libstdc++ \
     readline \
     libtool \
     libxslt-dev \
     linux-headers \
     make \
     patch \
     pcre \
     pcre-dev \
     perl-dev \
     su-exec \
     tar \
     zlib \
     zlib-dev \
     libgcc \
     ca-certificates \
 && mkdir -p ${COMPILE_DIR} && mkdir -p ${LIBRESSL_DIR} \
 && wget -P $COMPILE_DIR http://nginx.org/download/${VERSION_NGINX}.tar.gz \
 && wget -P $COMPILE_DIR https://ftp.pcre.org/pub/pcre/${VERSION_PCRE}.tar.gz \
 && wget -P $COMPILE_DIR https://github.com/simplresty/ngx_devel_kit/archive/v${VERSION_NGINX_DEVEL_KIT}.tar.gz \
 && wget -P $COMPILE_DIR https://github.com/openresty/lua-nginx-module/archive/v${VERSION_LUA_NGINX_MODULE}.tar.gz \
 && wget -P $COMPILE_DIR http://luajit.org/download/LuaJIT-${VERSION_LUA_JIT}.tar.gz \
 && wget -P $COMPILE_DIR https://people.freebsd.org/~osa/ngx_http_redis-0.3.9.tar.gz \
 && git clone git://github.com/vozlt/nginx-module-vts.git $COMPILE_DIR/nginx-module-vts \
 && git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git $COMPILE_DIR/ngx_http_substitutions_filter_module \
 && git clone https://github.com/kvspb/nginx-auth-ldap.git $COMPILE_DIR/nginx-auth-ldap \
 && git clone https://github.com/openresty/srcache-nginx-module.git $COMPILE_DIR/srcache-nginx-module \
 && git clone https://github.com/openresty/echo-nginx-module.git $COMPILE_DIR/echo-nginx-module \
 && git clone https://github.com/openresty/redis2-nginx-module.git $COMPILE_DIR/redis2-nginx-module \
 && git clone https://github.com/openresty/rds-json-nginx-module.git $COMPILE_DIR/rds-json-nginx-module \
 && git clone https://github.com/calio/form-input-nginx-module $COMPILE_DIR/form-input-nginx-module \
 && git clone https://github.com/yaoweibin/nginx_upstream_check_module.git $COMPILE_DIR/nginx_http_upstream_check_module \
 && git clone https://github.com/Lax/traffic-accounting-nginx-module.git $COMPILE_DIR/traffic-accounting-nginx-module \
 && git clone https://github.com/google/ngx_brotli.git $COMPILE_DIR/ngx_brotli && cd $COMPILE_DIR/ngx_brotli && git submodule update --init \
 && cd $COMPILE_DIR && tar xzf $VERSION_NGINX.tar.gz \
 && cd $COMPILE_DIR && tar xzf ngx_http_redis-0.3.9.tar.gz \
 && cd $COMPILE_DIR && tar xzf ${VERSION_PCRE}.tar.gz \
 && cd $COMPILE_DIR && tar xzf v${VERSION_NGINX_DEVEL_KIT}.tar.gz \
 && cd $COMPILE_DIR && tar xzf v${VERSION_LUA_NGINX_MODULE}.tar.gz \
 && cd $COMPILE_DIR && tar xzf LuaJIT-${VERSION_LUA_JIT}.tar.gz \
 && cd $COMPILE_DIR/LuaJIT-${VERSION_LUA_JIT} && make && make install \
 #&& cd $COMPILE_DIR/$VERSION_NGINX && patch -p1 < $COMPILE_DIR/nginx_http_upstream_check_module/check_1.16.1+.patch \
 && cd $COMPILE_DIR/$VERSION_NGINX && ./configure \
 ${additional_params} \
 --with-ld-opt="-lrt"  \
 --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -DTCP_FASTOPEN=23' \
 --with-ld-opt='-Wl,-z,relro -Wl,-E' \
#--with-ld-opt="-lrt"  \
#--with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
#--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \

--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--with-pcre=$COMPILE_DIR/$VERSION_PCRE \
--with-file-aio \
--with-http_sub_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-http_image_filter_module \
--with-threads \
--with-mail \
--with-http_dav_module \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-debug \
--with-pcre-jit \
--with-http_realip_module \
--with-http_gunzip_module \
--with-http_auth_request_module \
--with-http_addition_module \
--with-http_gzip_static_module \
--add-module=$COMPILE_DIR/ngx_devel_kit-${VERSION_NGINX_DEVEL_KIT} \
--add-module=$COMPILE_DIR/lua-nginx-module-${VERSION_LUA_NGINX_MODULE} \
--add-module=$COMPILE_DIR/ngx_http_substitutions_filter_module \
--add-module=$COMPILE_DIR/nginx-auth-ldap \
--add-module=$COMPILE_DIR/nginx-module-vts \
--add-module=$COMPILE_DIR/srcache-nginx-module \
--add-module=$COMPILE_DIR/echo-nginx-module \
--add-module=$COMPILE_DIR/redis2-nginx-module \
--add-module=$COMPILE_DIR/ngx_http_redis-0.3.9 \
--add-module=$COMPILE_DIR/ngx_brotli \
--add-module=$COMPILE_DIR/rds-json-nginx-module \
--add-module=$COMPILE_DIR/form-input-nginx-module \
#--add-module=$COMPILE_DIR/nginx_http_upstream_check_module \
#--add-module=$COMPILE_DIR/traffic-accounting-nginx-module \
&& cd $COMPILE_DIR/$VERSION_NGINX \
&& make -j 12 \
&& make install \
&& apk add --no-cache --virtual .gettext gettext \
&& mv /usr/bin/envsubst /tmp/ \
&& runDeps="$( \
    scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
    ) sed tzdata ca-certificates tini shadow" \
  && echo "------runDeps------------------" \
  && echo "$runDeps" \
  && echo "$runDeps" > /root/runDeps-nginx.txt \
  && echo "------runDeps------------------" \
  && apk add --verbose --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .build-deps .gettext \
  && mv /tmp/envsubst /usr/local/bin/ \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && mkdir -p /var/www \
  && rm -rf /tmp/* /usr/src/* /var/cache/apk/* /root/.gnupg /libressl* /nginx*  $COMPILE_DIR/* \
  && mkdir -p /var/lib/nginx/body \
    && mkdir -p /caches/nginx/proxy \
    && mkdir -p /fpm-sockets \
    && chmod 777 -R  /caches/nginx /fpm-sockets \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi} \
    && chown -R 33:0 /var/cache/nginx \
    && chown -R 33:0 /home \
    && chown -R 33:33 /etc/nginx \
    && chmod -R g+w /var/cache/nginx \
    && touch /var/run/nginx.pid \
    && chown -R www-data:www-data /var/run/nginx.pid \
    && chown -R www-data:www-data /var/cache/nginx /fpm-sockets /var/lib/nginx
ARG BUILD_DATE
ENV BUILD_DATE $BUILD_DATE
LABEL maintainer "a.v.galushko86@gmail.com"
ADD files/nginx.conf /etc/nginx/nginx.conf
ADD files/nginx-logs.conf /etc/nginx/nginx-logs.conf
ADD files/nginx-logs-headers.conf /etc/nginx/nginx-logs-headers.conf
ADD files/conf.d /etc/nginx/conf.d
ADD files/html /usr/share/nginx/html
ADD files/docker-entrypoint.sh /docker-entrypoint.sh
ADD files/nginxReloader.sh /nginxReloader.sh
RUN chmod +x /docker-entrypoint.sh  /nginxReloader.sh\
    && cat /root/runDeps-nginx.txt && getent passwd \
    && chown -R www-data:www-data /usr/share/nginx/  /etc/nginx -v \
    && ls -la /etc/nginx/conf.d 

  EXPOSE 80 443
  STOPSIGNAL SIGTERM
  ENTRYPOINT [ "/docker-entrypoint.sh" ]
  CMD ["nginx", "-g", "daemon off;"]