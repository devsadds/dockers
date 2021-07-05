ARG BASE_IMAGE
FROM $BASE_IMAGE
ENV NODEJS_VERSION=14.17.1-r0 NPM_VERSION=7.17.0-r0 YARN_VERSION=1.22.10-r0
ENV PHP_EXT_VER_SWOOLE_ASYNC=v4.5.5 PHP_EXT_VER_SWOOLE=v4.6.6 PHP_EXT_VER_APCU_BC=1.0.5 PHP_EXT_VER_APCU=5.1.20 PHP_EXT_VER_REDIS=5.3.4 PHP_EXT_VER_IMAGICK=3.4.4 IMAGICK_COMMIT=448c1cd0d58ba2838b9b6dff71c9b7e70a401b90
ENV PHP_EXTS \
        intl \
        gd \
        imap \
        zip \
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
        pdo_pgsql \
        pgsql \
        sockets
RUN deluser xfs && deluser www-data \
    && addgroup -g 33 -S www-data \
    && adduser -u 33 -D -S -G www-data www-data \
    && getent passwd www-data
RUN \
    apk add --update --no-cache  --virtual .runtime-deps \
        msmtp \
        mysql-client \
        postgresql-client \
        libpq \
        bash \
        git \
        curl \
        supervisor \
        nginx \
        openssh \
        libxml2-dev \
        icu-dev \
        libzip-dev \
        libpng \
        libgmpxx \
        libpng-dev \
        libjpeg-turbo \
        libjpeg-turbo-dev \
        libwebp-dev \
        zlib-dev \
        ghostscript \
        nano \
        libltdl \
        freetype \
        freetype-dev \
        libxpm-dev \
        oniguruma-dev \
        libvpx-dev \
        libxslt-dev \
        libmcrypt-dev \
        gmp \
        gmp-dev \
        ffmpeg \
        python2 \
        screen \
        rsync \
        imap-dev \
        krb5-dev \
        jq \
        nodejs=$NODEJS_VERSION npm=$NPM_VERSION yarn=$YARN_VERSION \
&& echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
&& apk add --no-cache \
        imagemagick \
        imagemagick-dev \
&&  apk add --no-cache --virtual .build-deps \
        postgresql-dev \
        autoconf \
        make \
        gcc \
        g++ \
        libstdc++ \
        zlib-dev \
        php8-dev \
        curl-dev \
        openssl-dev \
        pcre-dev \
        pcre2-dev \
        zlib-dev \
        $PHPIZE_DEPS \
&& docker-php-ext-configure gd \
      --with-freetype=/usr/include/ \
      --with-xpm=/usr/include/ \
      --with-webp=/usr/include/ \
      --with-jpeg=/usr/include/ \
      --with-webp=/usr/include/ \
&& docker-php-ext-configure zip \
&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
&& docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
&& for PHP_EXT in $PHP_EXTS;do echo "Install php ext begin  $PHP_EXT"; docker-php-ext-install -j$(nproc) $PHP_EXT ;echo "Install php ext finidhed  $PHP_EXT";done \
&& mkdir -p /usr/src/php/ext/ \
    && cd /usr/src/php/ext/ \
    && curl -L  https://github.com/phpredis/phpredis/archive/refs/tags/${PHP_EXT_VER_REDIS}.tar.gz -o /usr/src/php/ext/phpredis-${PHP_EXT_VER_REDIS}.tar.gz \
    && ls -la * \
    && tar -xvf phpredis-${PHP_EXT_VER_REDIS}.tar.gz \
    && rm -r /usr/src/php/ext/phpredis-${PHP_EXT_VER_REDIS}.tar.gz \
    && cd /usr/src/php/ext/ \
    && docker-php-ext-install phpredis-${PHP_EXT_VER_REDIS} \
    && pecl install apcu-$PHP_EXT_VER_APCU \
&&  mkdir -p /usr/src/php/ext/ \
    && mkdir -p /usr/src/php/ext/apcu_bc-$PHP_EXT_VER_APCU_BC \
    && git clone -q --branch=master https://github.com/krakjoe/apcu.git /usr/src/php/ext/apcu_bc \
    && cd /usr/src/php/ext/apcu_bc \
    && git checkout -qf b68953ccbc1a5234c2caf8ed5800afd222270948 \
    && docker-php-ext-install apcu_bc \
    && echo "Install OK apcu_bc-$PHP_EXT_VER_APCU_BC" \
&& git clone https://github.com/Imagick/imagick /usr/src/php/ext/imagick \
    && cd /usr/src/php/ext/imagick  \
    && git checkout $IMAGICK_COMMIT  \
    && phpize  \
    && ./configure  \
    && make  \
    && make install \
&& curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer  \
    && echo "alias composer='composer'" >> /root/.bashrc \
    && chmod +x /usr/local/bin/composer \
    && composer self-update --clean-backups 2.0.13 \
    && docker-php-source extract \
    && mkdir /usr/src/php/ext/swoole \
    && curl -sfL https://github.com/swoole/swoole-src/archive/${PHP_EXT_VER_SWOOLE}.tar.gz -o swoole.tar.gz \
    && tar xfz swoole.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole \
    && docker-php-ext-configure swoole \
        --enable-http2   \
        --enable-mysqlnd \
        --enable-openssl \
        --enable-sockets \
        --enable-swoole-curl \
        --enable-swoole-json  \
    && docker-php-ext-install -j$(nproc) swoole \
    && docker-php-source delete \
    && apk del .build-deps \
    && rm -rf /usr/src/php/ext/* /tmp/*


RUN echo "Load extensions" \
    && ln -sfn /usr/local/lib/php/extensions/no-debug-non-zts-20200930/swoole.so /usr/local/lib/php/extensions/no-debug-non-zts-20200930/swoole \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini \
    && docker-php-ext-enable --ini-name docker-php-ext-opcache.ini opcache \
    && echo "----EXTENSION swoole----" && php --ri swoole && echo "----EXTENSION swoole----"\
    && ls -la /usr/local/etc/php/conf.d/
RUN \
    mkdir -p /usr/local/etc/php-fpm.d \
    && mkdir -p  /etc/supervisor.d/ \
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
          } | tee /etc/supervisor.d/worker.ini \
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
        echo 'pm.max_children = 50'; \
        echo 'pm.start_servers = 10'; \
        echo 'pm.min_spare_servers = 10'; \
        echo 'pm.max_spare_servers = 40'; \
        echo 'pm.max_requests = 400'; \
        echo 'rlimit_files    = 131072'; \
        echo 'rlimit_core   = unlimited'; \
        echo 'clear_env = no'; \
        echo 'php_admin_flag[short_open_tag] = on'; \
        echo ';php_admin_value[date.timezone] = Europe/Moscow'; \
        echo 'php_value[memory_limit] = 5560M'; \
        echo 'php_admin_value[memory_limit] = 5560M'; \
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

ADD files/* /usr/sbin/
RUN chmod +x /usr/sbin/initbash_profile /usr/sbin/docker-entrypoint.sh  \
  && ln -s /usr/sbin/docker-entrypoint.sh /docker-entrypoint.sh \
  && /bin/bash -C "/usr/sbin/initbash_profile" \
  && mkdir -p /var/run /var/run/nginx  /var/www \
  && mkdir -p /var/lib/nginx/body /var/tmp/nginx/fastcgi \
  && chown -R www-data:www-data /var/lib/nginx \
  && chown -R www-data:www-data /var/tmp/nginx \
  && chown -R nobody.nobody /var/log/nginx \
  && rm -r /usr/src/* \
  && php -r 'print_r(gd_info());' \
  && php -i | grep imap \
  && yarn --version \
  && node --version \
  && npm --version
  EXPOSE 80  
  WORKDIR /var/www/
  ENTRYPOINT ["/docker-entrypoint.sh"]
