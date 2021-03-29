ARG DOCKER_IMAGE_BASE
FROM ${DOCKER_IMAGE_BASE}
ENV APCU_VERSION 5.1.18
ENV REDIS_VERSION 5.2.1
ENV DEBIAN_FRONTEND noninteractive
ENV PG_VERSION=13
ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_VERSION 7.4.16
ENV PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz" 
ENV PHP_ASC_URL="https://secure.php.net/get/php-${PHP_VERSION}.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="6e51a2fc610352438b2a1c40310468a1e2b5baf2fff43be77f9f408a9111590c" 
ENV PHP_MD5=""
ENV PHP_SOURCE_URL https://raw.githubusercontent.com/docker-library/php/1bc63c1ce4294a4ecb50c60dcf6a57d6749cba7d/7.4/buster/fpm

ENV PHPIZE_DEPS \
        autoconf \
        bzip2 \
        file \
        gnupg \
        graphviz \
        lbzip2 \
        libmemcached11 \
        libmemcachedutil2 \
        unzip \
        pkg-config \
        re2c \
        postgresql-client-${PG_VERSION}

ENV runtimeDeps \
        rsync \
        openssh-client \
        bash \
        openssl \
        git \
        curl \
        gettext \
        fping \
        sshpass \
        sudo \
        ca-certificates \
        supervisor \
        nginx \
        wget \
        imagemagick \
        dirmngr \
        libwebp-dev \
        libonig-dev
ENV buildDeps \
        make \
        libffi-dev \
        postgresql-server-dev-${PG_VERSION} \
        libpq-dev \
        g++ \
        gcc \
        autoconf \
        dirmngr \
        gnupg \
        libbz2-dev \
        dpkg-dev \
        libz-dev \
        libzip-dev \
        locales-all \
        unixodbc-dev \
        zlib1g-dev \
        libpng-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxpm-dev \
        libxslt1-dev \
        libbz2-dev \
        libc-client2007e \
        libc-client2007e-dev \
        libc-client-dev \
        libc-dev \
        libcurl4-openssl-dev \
        libedit-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libkrb5-dev \
        libmagickcore-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libmemcached-dev \
        freetds-dev \
        default-libmysqlclient-dev
ENV savedAptMark \
        curl        

RUN apt update --fix-missing \
    && apt install -y  $runtimeDeps

ENV RUN_USER www-data
RUN deluser ${RUN_USER} \
  && groupadd --gid 33 ${RUN_USER} \
  && useradd --uid 33 --gid ${RUN_USER} --shell  /sbin/nologin --home-dir /var/www  ${RUN_USER} \
  && if [ ! -d /var/www ]; then mkdir -p /var/www;fi \
  && chown -R ${RUN_USER}:${RUN_USER}  /var/www;

RUN echo "Get sources" \
    && mkdir -p /usr/local/bin/  /usr/src/ \
    && curl -L ${PHP_SOURCE_URL}/docker-php-entrypoint -o /usr/local/bin/docker-php-entrypoint \
    && curl -L ${PHP_SOURCE_URL}/docker-php-ext-configure -o  /usr/local/bin/docker-php-ext-configure \
    && curl -L ${PHP_SOURCE_URL}/docker-php-ext-enable -o /usr/local/bin/docker-php-ext-enable \
    && curl -L ${PHP_SOURCE_URL}/docker-php-ext-install -o  /usr/local/bin/docker-php-ext-install \
    && curl -L ${PHP_SOURCE_URL}/docker-php-source -o /usr/local/bin/docker-php-source \
    && curl -L ${PHP_URL} -o /usr/src/php.tar.xz \
    && chmod +x /usr/local/bin/docker-php-source 
#RUN which phpize

RUN echo "" \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main' >> /etc/apt/sources.list \
    && apt update \
    && apt install -y  $PHPIZE_DEPS \
    && apt install -y  $buildDeps
RUN ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a \
  && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a
RUN cd /usr/src && export \
    CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS" \
  ; \
  /usr/local/bin/docker-php-source extract; \
  cd /usr/src/php; \
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
  debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
  if [ ! -d /usr/include/curl ]; then \
    ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
  fi; \
  ./configure \
    --build="$gnuArch" \
    --with-config-file-path="$PHP_INI_DIR" \
    --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
    --with-mysqli=/usr/bin/mysql_config \
    --with-curl \
    --with-pdo-mysql \
    --with-pdo-sqlite \
    --with-sqlite3 \
    --with-pgsql \
    --with-libedit \
    --with-openssl \
    --with-kerberos \
    --with-imap-ssl \
    --with-imap \
    --with-zlib \
    --with-gettext \
    --with-xsl \
    --with-curl \
    --with-mhash \
    --enable-option-checking=fatal \
    --enable-ftp \
    --enable-mbstring \
    --enable-mysqlnd \
    --enable-calendar \
    --enable-exif \
    --enable-soap \
    --enable-pcntl \
    --enable-intl \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-fpm \
    --enable-sockets \
    --enable-opcache \
    \
    $(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
    --with-libdir="lib/$debMultiarch" \
    \
    ${PHP_EXTRA_CONFIGURE_ARGS:-} \
    ; \
    make -j 12; \
    make install
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && composer --version \
        && echo "alias composer='composer'" >> /root/.bashrc \
        && composer --version 
RUN touch /source.image
FROM php:7.4.16-fpm-buster AS ext-imagick

RUN apt-get update && apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN printf "\n" | pecl install imagick
RUN docker-php-ext-enable imagick 
RUN find / -iname 'imagick.so'
RUN ls -la /usr/local/etc/php/conf.d/* && find / -iname '.*imagick.ini'
# ext-mongodb
COPY --from=ext-imagick /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini
COPY --from=ext-imagick /usr/local/lib/php/extensions/no-debug-non-zts-20190902/imagick.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/imagick.so
RUN cat /source.image
RUN exit 1
###RUN pecl install \
        ###imagick \
        ###apcu-${APCU_VERSION} \
        ###apcu_bc \
        ###redis-${REDIS_VERSION} \

RUN docker-php-ext-configure gd \
        --with-freetype=/usr/include/ \
        --with-xpm=/usr/include/ \
        --with-webp=/usr/include/ \
        --with-jpeg=/usr/include/ \
&& docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
&& docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd \
&& docker-php-ext-configure zip \
&& docker-php-ext-configure opcache --enable-opcache \
&& docker-php-ext-install \
        zip \
        intl \
        pdo_mysql \
        xml \
        exif \
        bcmath \
        mysqli \
        pdo \
        json \
        ctype \
        tokenizer \
        mbstring \
        pcntl \
        opcache \
        pdo_pgsql \
        pgsql \
        gmp \
        ldap \
        bz2 \
&& docker-php-ext-enable --ini-name 20-imagick.ini imagick \
&& docker-php-ext-enable --ini-name 20-apcu.ini apcu \
&& docker-php-ext-enable --ini-name 21-apc.ini apc \
&& docker-php-ext-enable --ini-name 05-opcache.ini opcache \
&& docker-php-ext-enable --ini-name 20-redis.ini redis \
&& docker-php-ext-enable mysqli \
&& apk del --no-cache  .build-deps  freetype-dev libpng-dev libjpeg-turbo-dev
RUN ldconfig\
    && mkdir -p /usr/local/etc/php-fpm.d \
    && mkdir -p  /etc/supervisor/conf.d/ \
    && echo 'Create supervisord worker conf'  \
       && { \
        echo '[supervisord]'; \
        echo 'nodaemon=true'; \
        echo ''; \
        echo ''; \
        echo '[program:php-fpm]'; \
        echo 'command=/usr/local/sbin/php-fpm -F --pid /var/run/php-fpm.pid'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'stderr_logfile=/dev/stderr'; \
        echo 'stderr_logfile_maxbytes=0'; \
        echo 'autorestart=false'; \
        echo 'startretries=0'; \
        echo ''; \
        echo '[program:nginx]'; \
        echo "command=nginx -g 'daemon off;'"; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'stderr_logfile=/dev/stderr'; \
        echo 'stderr_logfile_maxbytes=0'; \
        echo 'autorestart=false'; \
        echo 'startretries=0'; \
          } | tee /etc/supervisor/conf.d/worker.conf \
       && echo 'Change php.ini'  \
       && { \
        echo 'upload_max_filesize = 100M'; \
        echo 'doc_root ='; \
        echo 'user_dir ='; \
        echo 'enable_dl = Off'; \
        echo 'allow_url_fopen = On'; \
        echo 'short_open_tag = On'; \
        echo 'post_max_size = 200M'; \
        echo 'memory_limit = 5000M'; \
        echo 'file_uploads = On'; \
        echo 'max_input_vars = 2000'; \
        echo 'max_execution_time = 280'; \
        echo 'opcache.max_accelerated_files = 20000'; \
        echo 'opcache.memory_consumption = 256'; \
        echo 'opcache.interned_strings_buffer = 64'; \
        echo 'cgi.fix_pathinfo = 0'; \
        echo 'opcache.force_restart_timeout = 180'; \
          } | tee /usr/local/etc/php/conf.d/php.ini \
       && if [ -f "/usr/local/etcphp-fpm.d/www.conf" ];then rm /usr/local/etc/php-fpm.d/www.conf;else touch  /usr/local/etc/php-fpm.d/www.conf;fi\
       && echo 'Create www php-fpm pool'  \
       && { \
        echo '[global]'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo '[www]'; \
        echo 'user = www-data'; \
        echo 'group = www-data'; \
        echo 'listen.owner = www-data'; \
        echo 'listen.group = www-data'; \
        echo 'listen = 9000'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 90'; \
        echo 'pm.start_servers = 10'; \
        echo 'pm.min_spare_servers = 10'; \
        echo 'pm.max_spare_servers = 40'; \
        echo 'pm.max_requests = 400'; \
        echo 'rlimit_files = 131072'; \
        echo 'rlimit_core = unlimited'; \
        echo 'clear_env = no'; \
        echo 'php_admin_flag[short_open_tag] = on'; \
        echo 'php_admin_value[date.timezone] = Europe/Moscow'; \
        echo 'php_value[memory_limit] = 1560M'; \
        echo 'php_admin_value[memory_limit] = 1560M'; \
        echo 'php_value[max_file_uploads] = 550'; \
        echo 'php_value[upload_max_filesize] = 100M'; \
        echo 'php_value[post_max_size] = 100M'; \
        echo 'pm.status_path = /status'; \
        echo 'catch_workers_output = yes'; \
        echo 'php_flag[display_errors] = on'; \
        echo 'php_admin_value[error_reporting] = E_ALL & ~E_NOTICE & ~E_WARNING & ~E_STRICT & ~E_DEPRECATED'; \
        echo 'access.log = /proc/self/fd/2'; \
        echo 'php_admin_flag[log_errors] = on'; \
          } | tee /usr/local/etc/php-fpm.d/www.conf \
       && rm /usr/local/etc/php-fpm.conf \
       && echo 'Create php-fpm.conf'  \
       && { \
        echo '[global]'; \
        echo 'pid = /var/run/php-fpm.pid'; \
        echo 'rlimit_core = 0'; \
        echo 'events.mechanism = epoll'; \
        echo 'include=etc/php-fpm.d/*.conf'; \
          } | tee /usr/local/etc/php-fpm.conf \
       && cd /usr/local/etc/php-fpm.d/ \
       && rm docker.conf  www.conf.default  zz-docker.conf
ADD ./files/bashrc_alias.sh /usr/sbin/bashrc_alias.sh
ADD ./files/initbash_profile.sh /usr/sbin/initbash_profile
ADD ./files/docker-entrypoint.sh /
ADD ./files/configs/nginx-backend/ /etc/nginx
RUN  /bin/bash -C "/usr/sbin/initbash_profile" \
  && chmod +x /docker-entrypoint.sh \
  && mkdir -p /var/run /var/run/nginx  /var/www \
  && mkdir -p /var/lib/nginx/body /var/tmp/nginx/fastcgi \
  && chown -R www-data:www-data /var/lib/nginx \
  && chown -R www-data:www-data /var/tmp/nginx \
  && chown -R nobody.nobody /var/log/nginx \
  && rm -r /usr/src/* \
  && rm /usr/local/etc/php/conf.d/05-opcache.ini  /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini-production \
  && php-fpm -t && php -r "print_r(get_loaded_extensions());" \
  && sed -i "s/^.*policy\sdomain=.*reso.*map.*value.*$/\ \ \<policy\ domain=\"resource\"\ name=\"map\"\ value=\"1GiB\"\/\>/" /etc/ImageMagick-6/policy.xml \
  && sed -i "s/^.*policy\sdomain=.*reso.*memory.*value.*$/\ \ \<policy\ domain=\"resource\"\ name=\"memory\"\ value=\"1GiB\"\/\>/" /etc/ImageMagick-6/policy.xml \
  EXPOSE 80  
  WORKDIR /var/www/
  ENTRYPOINT ["/docker-entrypoint.sh"]