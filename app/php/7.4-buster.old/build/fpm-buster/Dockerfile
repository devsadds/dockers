ARG DOCKER_IMAGE_TAG
FROM ${DOCKER_IMAGE_TAG}
ENV APCU_VERSION 5.1.18
ENV REDIS_VERSION 5.2.1

ENV DEBIAN_FRONTEND noninteractive
ENV PG_VERSION=13
ENV PHPIZE_DEPS \
    dpkg-dev \
    bzip2 \
    file \
    libc-dev \
    libxpm-dev \
    pkg-config \
    default-libmysqlclient-dev \
    libmagickwand-dev \
    libmagickcore-dev \
    libedit-dev \
    locales-all \
    libmcrypt-dev \
    re2c \
    libcurl4-openssl-dev \
    libsqlite3-dev \
    libssl-dev \
    zlib1g-dev \
    libzip-dev \
    lbzip2 \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libkrb5-dev \
    libxml2-dev \
    libxslt1-dev \
    libbz2-dev \
    libc-client-dev \
    libmemcached11 \
    libmemcachedutil2 \
    libmemcached-dev \
    libz-dev \
    libc-client2007e-dev \
    libc-client2007e \
    unzip \
    graphviz \

    gnupg \
    freetds-dev \
    unixodbc-dev

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
            nodejs \
            npm \
            postgresql-client \
            ${PHPIZE_DEPS} \
            wget


ENV buildDeps \
            make \
            libffi-dev \
            postgresql-server-dev-${PG_VERSION} \
            libpq-dev \
            g++ \
            gcc \
            autoconf

RUN apt update --fix-missing && apt install -y  $runtimeDeps \
        && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
        && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' >> /etc/apt/sources.list \
    && apt update \
    && apt install -y  $buildDeps \
    && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && composer --version \
        && echo "alias composer='composer'" >> /root/.bashrc \
        && composer
ENV RUN_USER www-data
RUN deluser ${RUN_USER} \
  && groupadd --gid 33 ${RUN_USER} \
  && useradd --uid 33 --gid ${RUN_USER} --shell  /sbin/nologin --home-dir /var/www  ${RUN_USER} \
  && if [ ! -d /var/www ]; then mkdir -p /var/www;fi \
  && chown -R ${RUN_USER}:${RUN_USER}  /var/www;

RUN apt install -y libwebp-dev libonig-dev
RUN pecl install \
        imagick \
        apcu-${APCU_VERSION} \
        apcu_bc \
        redis-${REDIS_VERSION} \
&&  docker-php-ext-configure gd \
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
&& docker-php-ext-enable --ini-name 20-imagick.ini imagick \
&& docker-php-ext-enable --ini-name 20-apcu.ini apcu \
&& docker-php-ext-enable --ini-name 21-apc.ini apc \
&& docker-php-ext-enable --ini-name 05-opcache.ini opcache \
&& docker-php-ext-enable --ini-name 20-redis.ini redis \
&& docker-php-ext-enable mysqli \
&& apk del --no-cache  .build-deps  freetype-dev libpng-dev libjpeg-turbo-dev \
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
  && php-fpm -t && php -r "print_r(get_loaded_extensions());"
  EXPOSE 80  
  WORKDIR /var/www/
  ENTRYPOINT ["/docker-entrypoint.sh"]