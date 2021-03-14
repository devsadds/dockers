FROM microsoft/mssql-server-linux:2017-CU12



RUN apt-get update && apt-get install supervisor -y \
    && mkdir -p /var/log/supervisor \
    && cat /etc/supervisor/supervisord.conf \
    && echo '' > /etc/supervisor/supervisord.conf

RUN  echo 'Create supervisord conf'  \
       && { \
       echo ';supervisor config file'; \
       echo '[unix_http_server]'; \
       echo 'file=/var/run/supervisor.sock'; \
       echo 'chmod=0700'; \
       echo '[supervisord]'; \
       echo 'logfile=/dev/stdout'; \
       echo 'pidfile=/var/run/supervisord.pid'; \
       echo 'childlogdir=/var/log/supervisor'; \
       echo 'minfds=264000'; \
       echo '[rpcinterface:supervisor]'; \
       echo 'supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface'; \
       echo ''; \
       echo '[supervisorctl]'; \
       echo 'serverurl=unix:///var/run/supervisor.sock'; \
       echo ''; \
       echo '[include]'; \
       echo 'files = /etc/supervisor/conf.d/*.conf'; \
       } | tee /etc/supervisor/supervisord.conf \
 && echo 'Create supervisord conf'  \
       && { \
       echo '[supervisord]'; \
       echo 'nodaemon=true'; \
       echo 'logfile=/dev/null'; \
       echo ''; \
       echo ''; \
       echo '[program:mssql-server]'; \
       echo 'command=/opt/mssql/bin/sqlservr'; \
       echo 'autostart=true'; \
       echo 'autorestart=unexpected'; \
       echo 'stdout_logfile=/dev/stdout'; \
       echo 'stdout_logfile_maxbytes=0'; \
       echo 'stderr_logfile=/dev/stdout'; \
       echo 'stderr_logfile_maxbytes=0'; \
       echo 'exitcodes=0'; \
       echo ''; \
       echo ''; \
       echo ''; \
       echo '[include]'; \
       echo 'files = /etc/supervisor/conf.d/*.conf'; \
	      } | tee /etc/supervisor/conf.d/mssql-server.conf

WORKDIR /
ENTRYPOINT /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

EXPOSE 1433
#HEALTHCHECK --interval=15s CMD /opt/mssql-tools/bin/sqlcmd -U sa -P $SA_PASSWORD -Q "select 1" && grep -q "MSSQL CONFIG COMPLETE" ./config.log