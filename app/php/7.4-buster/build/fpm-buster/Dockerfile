FROM php:7.4.16-fpm-buster AS builder_ext_1
ENV buildDeps_1 \
        make \
        libffi-dev \
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
        zlib1g \
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
        default-libmysqlclient-dev \
        pkg-config
RUN echo "buildDeps_1=$buildDeps_1" \
    && apt-get update \
    && apt-get install -y $buildDeps_1
RUN printf "\n" | pecl install \
        imagick-3.4.4 \
        apcu-5.1.20 \
        apcu_bc-1.0.5  \
        redis-5.3.4
RUN docker-php-ext-enable --ini-name docker-php-ext-redis.ini redis \
    && docker-php-ext-enable --ini-name docker-php-ext-imagick.ini imagick \
    && docker-php-ext-enable --ini-name docker-php-ext-apcu.ini apcu \
    && docker-php-ext-enable --ini-name docker-php-ext-apc.ini apc \
    && docker-php-ext-enable --ini-name docker-php-ext-opcache.ini opcache \
    && ls -la /usr/local/etc/php/conf.d/*
RUN apt install -y libonig-dev
RUN  docker-php-ext-install \
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
        gd
RUN ls -la /usr/local/etc/php/conf.d/*

RUN docker-php-ext-enable mysqli \
    && docker-php-ext-enable imap

RUN ls -la /usr/local/etc/php/conf.d/* \
    && ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20190902/* \
    && cat /usr/local/etc/php/conf.d/docker-php-ext-gd.ini
RUN ldd  /usr/local/lib/php/extensions/no-debug-non-zts-20190902/gd.so | awk -F\> '{print $2}' | awk '{print $1}'  | sort

FROM php:7.4.16-fpm-buster
COPY --from=builder_ext_1 /usr/local/etc/php/conf.d/docker-php-ext-gd.ini /usr/local/etc/php/conf.d/docker-php-ext-gd.ini
COPY --from=builder_ext_1 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/gd.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/gd.so
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libc.so.6  /lib/x86_64-linux-gnu/libc.so.6 
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libm.so.6  /lib/x86_64-linux-gnu/libm.so.6 
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libz.so.1  /lib/x86_64-linux-gnu/libz.so.1 
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libpng16.so.16  /usr/lib/x86_64-linux-gnu/libpng16.so.16 
COPY --from=builder_ext_1 /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini
COPY --from=builder_ext_1 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/imagick.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/imagick.so
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libMagickWand-6.Q16.so.6 /usr/lib/x86_64-linux-gnu/libMagickWand-6.Q16.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libMagickCore-6.Q16.so.6 /usr/lib/x86_64-linux-gnu/libMagickCore-6.Q16.so.6
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libX11.so.6 /usr/lib/x86_64-linux-gnu/libX11.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libgomp.so.1 /usr/lib/x86_64-linux-gnu/libgomp.so.1
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/liblcms2.so.2 /usr/lib/x86_64-linux-gnu/liblcms2.so.2
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/liblqr-1.so.0 /usr/lib/x86_64-linux-gnu/liblqr-1.so.0
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libfftw3.so.3 /usr/lib/x86_64-linux-gnu/libfftw3.so.3
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libxml2.so.2 /usr/lib/x86_64-linux-gnu/libxml2.so.2
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 /usr/lib/x86_64-linux-gnu/libfontconfig.so.1
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libfreetype.so.6 /usr/lib/x86_64-linux-gnu/libfreetype.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libXext.so.6 /usr/lib/x86_64-linux-gnu/libXext.so.6
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libbz2.so.1.0 /lib/x86_64-linux-gnu/libbz2.so.1.0
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libltdl.so.7 /usr/lib/x86_64-linux-gnu/libltdl.so.7
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libxcb.so.1 /usr/lib/x86_64-linux-gnu/libxcb.so.1
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libglib-2.0.so.0 /usr/lib/x86_64-linux-gnu/libglib-2.0.so.0
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libicui18n.so.63 /usr/lib/x86_64-linux-gnu/libicui18n.so.63
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libicuuc.so.63 /usr/lib/x86_64-linux-gnu/libicuuc.so.63
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libicudata.so.63 /usr/lib/x86_64-linux-gnu/libicudata.so.63
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/liblzma.so.5 /lib/x86_64-linux-gnu/liblzma.so.5
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libexpat.so.1 /lib/x86_64-linux-gnu/libexpat.so.1
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libuuid.so.1 /lib/x86_64-linux-gnu/libuuid.so.1
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libpng16.so.16 /usr/lib/x86_64-linux-gnu/libpng16.so.16
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libXau.so.6 /usr/lib/x86_64-linux-gnu/libXau.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 /usr/lib/x86_64-linux-gnu/libXdmcp.so.6
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/libpcre.so.3 /lib/x86_64-linux-gnu/libpcre.so.3
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6
COPY --from=builder_ext_1 /usr/lib/x86_64-linux-gnu/libbsd.so.0 /usr/lib/x86_64-linux-gnu/libbsd.so.0
COPY --from=builder_ext_1 /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=composer:2.0.11 /usr/bin/composer /usr/bin/composer



RUN php-fpm -t && php -r "print_r(get_loaded_extensions());"

RUN ln -s /usr/lib/libc-client.a /usr/lib/x86_64-linux-gnu/libc-client.a \
  && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/libsybdb.a


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
          } | tee /etc/supervisor/conf.d/worker.conf \
       && echo 'Change php.ini'  \
       && { \
        echo 'upload_max_filesize = 200M'; \
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
        echo 'php_value[upload_max_filesize] = 200M'; \
        echo 'php_value[post_max_size] = 200M'; \
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
RUN  /bin/bash -C "/usr/sbin/initbash_profile" \
  && chmod +x /docker-entrypoint.sh \
  && chown -R www-data:www-data /var/www  \
  && php-fpm -t && php -r "print_r(get_loaded_extensions());" \
  #&& sed -i "s/^.*policy\sdomain=.*reso.*map.*value.*$/\ \ \<policy\ domain=\"resource\"\ name=\"map\"\ value=\"1GiB\"\/\>/" /etc/ImageMagick-6/policy.xml \
  #&& sed -i "s/^.*policy\sdomain=.*reso.*memory.*value.*$/\ \ \<policy\ domain=\"resource\"\ name=\"memory\"\ value=\"1GiB\"\/\>/" /etc/ImageMagick-6/policy.xml \
  && echo "alias composer='composer'" >> /root/.bashrc
  EXPOSE 9000 
  WORKDIR /var/www/
  ENTRYPOINT ["/docker-entrypoint.sh"]