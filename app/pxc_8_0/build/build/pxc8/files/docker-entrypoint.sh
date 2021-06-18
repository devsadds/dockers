#!/bin/bash
set -e
cmd_args="${1}"

ipaddr=$(ifconfig "${SERVER_INTERFACE_BIND:-eth0}" | grep 'inet' | awk '{print $2}')
hostname=$(hostname)
tags="[$tags]"
m_config="${MYSQL_CONF_FILE:-/etc/mysql/conf.d/node.cnf}"
MYSQL_ERROR_LOG_DIR="${MYSQL_ERROR_LOG_DIR:-${DATADIR:-/var/lib/mysql}}"
wsrep_notify_cmd=${WRESP_NOTIFY_CMD:-/docker-scripts.d/wsrep_notify.sh}

if [ -f "${DATADIR:-/var/lib/mysql}/master_rep.info" ];then
    master_server_id=$(cat ${DATADIR:-/var/lib/mysql}/master_rep.info | grep master_server_id | cut -d\= -f2)
  else
    master_server_id=$(echo ${hostname//[!1-9]/}   |  grep -o '....$')
fi

if [ -z "$DISCOVERY_SERVICE" ]; then
  echo >&2 'Error:  You need to specify DISCOVERY_SERVICE'
  exit 1
fi

if [ "${1:0:1}" = '-' ]; then
  CMDARG="$@"
fi

if [ -z "$CLUSTER_NAME" ]; then
  echo >&2 'Error:  You need to specify CLUSTER_NAME'
  exit 1
fi

if [ -z "${DATADIR:-/var/lib/mysql}" ];then
  DATADIR="/var/lib/mysql"
fi

if [ -z "${SERVER_NAME}" ];then
  SERVER_NAME="${CLUSTER_NAME:-pxc8-cluster}"
fi

if [ -z "${CONSUL_SERVICE}" ];then
  CONSUL_SERVICE="pxc"
fi

if [ -z "${CONSUL_AGENT_SLEEP_TIME:-6}" ];then
  CONSUL_AGENT_SLEEP_TIME="20"
fi


if [[ ! -d "${MYSQL_ERROR_LOG_DIR}" ]];then
  mkdir -pv ${MYSQL_ERROR_LOG_DIR} || MYSQL_ERROR_LOG_DIR="/tmp"
fi

if [ -z "${XTRABACKUP_PASSWORD}" ];then
  echo >&2 'Error:  You need to specify env var XTRABACKUP_PASSWORD'
  exit 1
fi

echo
echo "DATADIR = $DATADIR"
echo "ipaddr = $ipaddr"
echo "hostname = $hostname"
echo "tags = $tags"
echo "m_config = $m_config"
echo "master_server_id = $master_server_id"
echo "DISCOVERY_SERVICE=$DISCOVERY_SERVICE"
echo "CONSUL_SERVICE=$CONSUL_SERVICE"
echo "MYSQL_ERROR_LOG_DIR = $MYSQL_ERROR_LOG_DIR"
echo "XTRABACKUP_PASSWORD = $XTRABACKUP_PASSWORD"
echo "CONSUL_AGENT_SLEEP_TIME=${CONSUL_AGENT_SLEEP_TIME:-6}"
echo



progress-bar() {
  local duration=${1}


    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }
    clean_line() { printf "\r"; }

  for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
      already_done; remaining; percentage
      sleep 1
      clean_line
  done
  clean_line
}


func_consul_agent_start(){
  echo "Begin func ${FUNCNAME[0]}" 
  echo "{ \"services\": [ { \"name\": \"${CONSUL_SERVICE}\", \"address\": \"$ipaddr\", \"port\": 3306, \"Tags\": $tags, \"checks\": [ { \"name\": \"check if percona port is open\", \"tcp\": \"$ipaddr:3306\", \"interval\": \"10s\", \"timeout\": \"5s\" } ] } ] }" > /tmp/pxc.json

  sleep 1;
  echo "show /tmp/pxc.json"
  echo "------------------------------------"
  cat /tmp/pxc.json
  echo "------------------------------------"
# Starting consul client
  echo "------------------------------------"
  echo "exec /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-format json -config-file /tmp/pxc.json &"
  echo "------------------------------------"
  echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-6} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-6}
  if [[ $(ps aux | grep "consul.*agent" | grep -ve 'grep') == "" ]];then
      /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-file /tmp/pxc.json 2>&1 & disown;
      echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-6} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-6}
  else
      echo "consul agent already running"
  fi


  echo "End func ${FUNCNAME[0]}" 
}

funct_join() {
    local IFS="$1"
    shift
    joined=$(tr "$IFS" '\n' <<< "$*" | sort -u | tr '\n' "$IFS")
    echo "${joined%?}"
}
  
mysql_postcheck(){
  if [[ ! -f "/docker-scripts.d/wsrep_notify.sh" ]];then
    cat <<OEF> ${wsrep_notify_cmd}
#!/bin/sh -eu

# This is a simple example of wsrep notification script (wsrep_notify_cmd).
# It will create 'wsrep' schema and two tables in it: 'membership' and 'status'
# and insert data into them on every membership or node status change.
#
# Edit parameters below to specify the address and login to server.

USER=root
PSWD=${MYSQL_ROOT_PASSWORD}
HOST=localhost
PORT=3306

SCHEMA="wsrep"
MEMB_TABLE="$SCHEMA.membership"
STATUS_TABLE="$SCHEMA.status"

BEGIN="
   SET wsrep_on=0;
   DROP SCHEMA IF EXISTS $SCHEMA; CREATE SCHEMA $SCHEMA;
   CREATE TABLE $MEMB_TABLE (
      idx  INT UNIQUE PRIMARY KEY,
      uuid CHAR(40) UNIQUE, /* node UUID */
      name VARCHAR(32),     /* node name */
      addr VARCHAR(256)     /* node address */
   ) ENGINE=MEMORY;
   CREATE TABLE $STATUS_TABLE (
      size   INT,      /* component size   */
      idx    INT,      /* this node index  */
      status CHAR(16), /* this node status */
      uuid   CHAR(40), /* cluster UUID */
      prim   BOOLEAN   /* if component is primary */
   ) ENGINE=MEMORY;
   BEGIN;
   DELETE FROM $MEMB_TABLE;
   DELETE FROM $STATUS_TABLE;
"
END="COMMIT;"

configuration_change()
{
   echo "$BEGIN;"

   local idx=0

   for NODE in $(echo $MEMBERS | sed s/,/\ /g)
   do
      echo "INSERT INTO $MEMB_TABLE VALUES ( $idx, "
      # Don't forget to properly quote string values
      echo "'$NODE'" | sed  s/\\//\',\'/g
      echo ");"
      idx=$(( $idx + 1 ))
   done

   echo "
      INSERT INTO $STATUS_TABLE
      VALUES($idx, $INDEX,'$STATUS', '$CLUSTER_UUID', $PRIMARY);
   "

   echo "$END"
}

status_update()
{
   echo "
      SET wsrep_on=0;
      BEGIN;
      UPDATE $STATUS_TABLE SET status='$STATUS';
      COMMIT;
   "
}

COM=status_update # not a configuration change by default

while [ $# -gt 0 ]
do
   case $1 in
      --status)
         STATUS=$2
         shift
         ;;
      --uuid)
         CLUSTER_UUID=$2
         shift
         ;;
      --primary)
         [ "$2" = "yes" ] && PRIMARY="1" || PRIMARY="0"
         COM=configuration_change
         shift
         ;;
      --index)
         INDEX=$2
         shift
         ;;
      --members)
         MEMBERS=$2
         shift
         ;;
         esac
         shift
   done

# Undefined means node is shutting down
if [ "$STATUS" != "Undefined" ]
then
   $COM | mysql -B -u$USER -p$PSWD -h$HOST -P$PORT
fi

exit 0

OEF

chown mysql:mysql ${wsrep_notify_cmd}
chmod 700 ${wsrep_notify_cmd}
fi

}

mysql_tune(){
  echo "Begin func ${FUNCNAME[0]}" 
  if [[ "${MYSQL_TUNE_BEFORE_START}" == "true" ]];then
      if [[ -f "${m_config}" ]];then
        echo "Begin tune mysql"
        grep -q '^innodb_flush_method' "${m_config}" && sed -i  "s/innodb_flush_method.*$/innodb_flush_method = O_DIRECT/g" "${m_config}" || echo "" >> "${m_config}" 
        #grep -q '^innodb_log_files_in_group' "${m_config}" && sed -i  "s/innodb_log_files_in_group.*$/innodb_log_files_in_group = ${INNODB_LOG_FILES_IN_GROUP:-2}/g" "${m_config}" || echo "innodb_log_files_in_group = ${INNODB_LOG_FILES_IN_GROUP:-2}" >> "${m_config}"
        #grep -q '^innodb_log_file_size' "${m_config}" && sed -i  "s/innodb_log_file_size.*$/innodb_log_file_size = ${INNODB_LOG_FILE_SIZE:-128M}/g" "${m_config}" || echo "innodb_log_file_size = ${INNODB_LOG_FILE_SIZE:-128M}" >> "${m_config}"
        grep -q '^innodb_flush_log_at_trx_commit' "${m_config}" && sed -i  "s/innodb_flush_log_at_trx_commit.*$/innodb_flush_log_at_trx_commit = ${INNODBFLUSH_LOG_AT_TRX_COMMIT:-2}/g" "${m_config}" || echo "innodb_flush_log_at_trx_commit = ${INNODBFLUSH_LOG_AT_TRX_COMMIT:-2}" >> "${m_config}"
        grep -q '^innodb_file_per_table' "${m_config}" && sed -i  "s/innodb_file_per_table.*$/innodb_file_per_table = ${INNODB_FILE_PER_TABLE:-1}/g" "${m_config}" || echo "innodb_file_per_table = ${INNODB_FILE_PER_TABLE:-1}" >> "${m_config}"
        grep -q '^innodb_buffer_pool_size' "${m_config}" && sed -i  "s/innodb_buffer_pool_size.*$/innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE:-2G}/g" "${m_config}" || echo "innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE:-2G}" >> "${m_config}"
        grep -q '^innodb_autoinc_lock_mode' "${m_config}" "${m_config}" && sed -i  "s/innodb_autoinc_lock_mode.*$/innodb_autoinc_lock_mode = ${INNODB_AUTOINC_LOCK_MODE:-2}/g" "${m_config}" || echo "innodb_autoinc_lock_mode = ${INNODB_AUTOINC_LOCK_MODE:-2}" >> "${m_config}"
        grep -q '^max_allowed_packet' "${m_config}" && sed -i  "s/max_allowed_packet.*$/max_allowed_packet = ${MAX_ALLOWED_PACKET:-172M}/g" "${m_config}" || echo "max_allowed_packet = ${MAX_ALLOWED_PACKET:-172M}" >> "${m_config}"
        grep -q '^max_connect_errors' "${m_config}" && sed -i  "s/max_connect_errors.*$/max_connect_errors = ${MAX_CONNECT_ERRORS:-1000000}/g" "${m_config}" || echo "max_connect_errors = ${MAX_CONNECT_ERRORS:-1000000}" >> "${m_config}"
        grep -q '^max_connections' "${m_config}" && sed -i  "s/max_connections.*$/max_connections = ${MAX_CONNECTIONS:-300}/g" "${m_config}" || echo "max_connections = ${MAX_CONNECTIONS:-300}" >> "${m_config}"
        grep -q '^wsrep_slave_threads' "${m_config}" && sed -i  "s/wsrep_slave_threads.*$/wsrep_slave_threads = ${WSREP_SLAVE_THREADS:-8}/g" "${m_config}" || echo "wsrep_slave_threads = ${WSREP_SLAVE_THREADS:-2}" >> "${m_config}"
        grep -q '^wsrep_cluster_name' "${m_config}" && sed -i  "s/wsrep_cluster_name.*$/wsrep_cluster_name = ${CLUSTER_NAME:-percona}/g" "${m_config}" || echo "wsrep_cluster_name = ${CLUSTER_NAME:-percona}" >> "${m_config}"
        grep -q '^wait_timeout' "${m_config}" && sed -i  "s/wait_timeout.*$/wait_timeout = ${WAIT_TIMEOUT:-200}/g" "${m_config}" || echo "wait_timeout = ${WAIT_TIMEOUT:-200}" >> "${m_config}"
        grep -q '^table_open_cache' "${m_config}" && sed -i  "s/table_open_cache.*$/table_open_cache = ${TABLE_OPEN_CACHE:-4096}/g" "${m_config}" || echo "table_open_cache = ${TABLE_OPEN_CACHE:-4096}" >> "${m_config}"
        grep -q '^max_heap_table_size' "${m_config}" && sed -i  "s/max_heap_table_size.*$/max_heap_table_size = ${MAX_HEAD_TABLE_SIZE:-64M}/g" "${m_config}" || echo "max_heap_table_size = ${MAX_HEAD_TABLE_SIZE:-64M}" >> "${m_config}"
        grep -q '^tmp_table_size' "${m_config}" && sed -i  "s/tmp_table_size.*$/tmp_table_size = ${TMP_TABLE_SIZE:-64M}/g" "${m_config}" || echo "tmp_table_size = ${TMP_TABLE_SIZE:-64M}" >> "${m_config}"
        #grep -q '^binlog_format' "${m_config}" && sed -i  "s/binlog_format.*$/binlog_format=${BINLOG_FOMAT:-ROW}/g" "${m_config}" || echo "binlog_format=${BINLOG_FOMAT:-ROW}" >> "${m_config}"
    else
      echo "File ${MYSQL_CONF_FILE:-/etc/mysql/conf.d/node.cnf} not exist. Skip tuning"
    fi
  fi
  if [[ "${GTID_REPLICATION}" == "true"  && "${REPLICATION_ROLE}" == "master" ]];then

    if [[ -f "${m_config}" ]];then
      grep -q '^skip-log-bin' "${m_config}" && sed -i  "s/skip-log-bin.*$/#skip-log-bin/g" "${m_config}"
      grep -q '^disable_log_bin' "${m_config}" && sed -i  "s/disable_log_bin.*$/#disable_log_bing" "${m_config}"
      grep -q '^binlog_format' "${m_config}" && sed -i  "s/binlog_format.*$/binlog_format=${BINLOG_FOMAT:-ROW}/g" "${m_config}" || echo "binlog_format=${BINLOG_FOMAT:-ROW}" >> "${m_config}"
      grep -q '^server-id' "${m_config}" && sed -i  "s/server-id.*$/server-id=${mysql_server_id:-${master_server_id}}/g" "${m_config}" || echo "server-id=${mysql_server_id:-${master_server_id}}" >> "${m_config}"
      grep -q '^log-bin' "${m_config}" && sed -i  "s/log-bin.*$/log-bin=percona_${mysql_server_id:-${master_server_id}}_bin/g" "${m_config}" || echo "log-bin=percona_${mysql_server_id:-${master_server_id}}_bin" >> "${m_config}"
      grep -q '^log_slave_updates' "${m_config}" && sed -i  "s/log_slave_updates.*$/log_slave_updates/g" "${m_config}" || echo "log_slave_updates" >> "${m_config}"
      grep -q '^enforce_gtid_consistency' "${m_config}" && sed -i "s/enforce_gtid_consistency.*$/enforce_gtid_consistency=1/g" "${m_config}" || echo "enforce_gtid_consistency=1" >> "${m_config}"
      grep -q '^gtid_mode' "${m_config}" && sed -i "s/gtid_mode.*$/gtid_mode=on/g" "${m_config}" || echo "gtid_mode=on" >> "${m_config}"
      grep -q '^expire_logs_days' "${m_config}" && sed -i "s/expire_logs_days.*$/expire_logs_days=${EXPIRE_LOGS_DAYS:-5}/g" "${m_config}" || echo "expire_logs_days=${EXPIRE_LOGS_DAYS:-5}" >> "${m_config}"
      grep -q '^max_binlog_size' "${m_config}" && sed -i "s/max_binlog_size.*$/max_binlog_size=${MAX_BINLOG_SIZE:-1000M}/g" "${m_config}" || echo "max_binlog_size=${MAX_BINLOG_SIZE:-1000M}" >> "${m_config}"
      grep -q '^innodb_locks_unsafe_for_binlog' "${m_config}" && sed -i "s/innodb_locks_unsafe_for_binlog.*$/innodb_locks_unsafe_for_binlog=${INNODB_LOCKS_UNSAFE_FOR_BINLOG:-1}/g" "${m_config}" || echo "innodb_locks_unsafe_for_binlog=${INNODB_LOCKS_UNSAFE_FOR_BINLOG:-1}" >> "${m_config}"
    else
      echo "File ${MYSQL_CONF_FILE:-/etc/mysql/conf.d/node.cnf} not exist. Skip set replication"
    fi
  fi
  echo "End func ${FUNCNAME[0]}"
  if [[ ! -f "${DATADIR:-/var/lib/mysql}/master_rep.info" ]];then
    echo "master_server_id=$(echo ${hostname//[!1-9]/}   |  grep -o '....$')" > ${DATADIR:-/var/lib/mysql}/master_rep.info
  fi
}



supervisor_update(){
  supervisorctl \
      --configuration=/etc/supervisor/supervisord.conf reread;
  supervisorctl \
      --configuration=/etc/supervisor/supervisord.conf update;
}

mysql_check_config(){
  mysqld --help
}


supervisord_run(){
  if [[ $(ps aux | grep "/usr/bin/supervisord" | grep -ve 'grep') == "" ]];then
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  else
    echo "Process /usr/bin/supervisord. Skip running"
  fi
    
}



docker_customizer(){
  
      for f in /docker-entrypoint.d/*; do
      case "$f" in
        *.sh)
          if [ -x "$f" ]; then
            echo "$0: running $f"
            "$f"
          else
            echo "$0: sourcing $f"
            . "$f"
          fi
          ;;
        *)        echo "$0: ignoring $f" ;;
      esac
    done
      
}

mysql_main(){

cat << OEF > /etc/mysql/conf.d/node.cnf
[mysqld]

datadir=${DATADIR:-/var/lib/mysql}

default_storage_engine=InnoDB
default-authentication-plugin=mysql_native_password
innodb_flush_log_at_trx_commit  = 0
innodb_flush_method             = O_DIRECT
innodb_file_per_table           = 1
innodb_autoinc_lock_mode=2

bind_address = 0.0.0.0

wsrep_slave_threads=8
wsrep_cluster_address=gcomm://
wsrep_provider=/usr/lib/galera4/libgalera_smm.so
wsrep_cluster_name=${CLUSTER_NAME:-pxc8-cluster}
wsrep_log_conflicts
wsrep_sst_method=xtrabackup-v2

pxc-encrypt-cluster-traffic=OFF
skip-log-bin
disable_log_bin

max_allowed_packet=${MAX_ALLOWED_PACKET:-256M}
max_connections=${MAX_CONNECTIONS:-300}
wsrep_node_address=${ipaddr}
sort_buffer_size=${SORT_BUFFER_SIZE:-2M}
skip_name_resolve
OEF


  if [ -z "$CLUSTER_JOIN" ]; then
    if [ ! -e "${DATADIR:-/var/lib/mysql}/mysql" ]; then
       if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" -a -z "$MYSQL_ROOT_PASSWORD_FILE" ]; then
                           echo >&2 'error: database is uninitialized and password option is not specified '
                           echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ROOT_PASSWORD_FILE,  MYSQL_ALLOW_EMPTY_PASSWORD or MYSQL_RANDOM_ROOT_PASSWORD'
                           exit 1
       fi
   
       if [ ! -z "$MYSQL_ROOT_PASSWORD_FILE" -a -z "$MYSQL_ROOT_PASSWORD" ]; then
         MYSQL_ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)
       fi
       echo "Exec mkdir -pv ${DATADIR:-/var/lib/mysql}"
       mkdir -pv "${DATADIR:-/var/lib/mysql}"
       chown -R -v mysql:mysql ${DATADIR:-/var/lib/mysql}
       echo "Running --initialize-insecure on ${DATADIR:-/var/lib/mysql}"
       ls -lah ${DATADIR:-/var/lib/mysql}
       #mysqld --initialize-insecure --verbose --user=mysql
       mysqld --initialize-insecure --verbose
       chown -R -v mysql:mysql ${DATADIR:-/var/lib/mysql}
       echo 'Finished --initialize-insecure'
   
       mysqld --user=mysql --datadir="${DATADIR:-/var/lib/mysql}" --skip-networking &
       pid="$!"
   
       mysql=( mysql --protocol=socket -uroot )
   
       for i in {30..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
           break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
        done
       if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
       fi
   
   
       mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
   
       if [ -n "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        MYSQL_ROOT_PASSWORD="$(pwmake 16)"
        echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
       fi
       if [ ! -n "$MONITOR_PASSWORD" ]; then
        MONITOR_PASSWORD="$(pwmake 16)"
        echo "GENERATED user monitor PASSWORD: $MONITOR_PASSWORD"
        echo "GENERATED user monitor PASSWORD: $MONITOR_PASSWORD" > ${DATADIR:-/var/lib/mysql}/user_password_monitor.txt
       fi


       if [ ! -n "$EXPORTER_PASSWORD" ]; then
        EXPORTER_PASSWORD="$(pwmake 16)"
        echo "GENERATED user exporter PASSWORD: $EXPORTER_PASSWORD"
        echo "GENERATED user exporter PASSWORD: $EXPORTER_PASSWORD" > ${DATADIR:-/var/lib/mysql}/user_password_exporter.txt
       fi
       echo "GENERATED user ROOT PASSWORD: $MYSQL_ROOT_PASSWORD" > ${DATADIR:-/var/lib/mysql}/user_password_root.txt


echo "Mysql query 0"
"${mysql[@]}" <<-EOSQL
  SET @@SESSION.SQL_LOG_BIN=0;
  CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so';
  CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so';
  CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so';
EOSQL

echo "Mysql query 1 - create user root with password $MYSQL_ROOT_PASSWORD"
"${mysql[@]}" <<-EOSQL
      CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password by '${MYSQL_ROOT_PASSWORD}';
      GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
EOSQL
echo "Mysql query 3"
"${mysql[@]}" <<-EOSQL
      CREATE USER 'xtrabackup'@'%' IDENTIFIED WITH mysql_native_password by '${XTRABACKUP_PASSWORD}';
EOSQL
echo "Mysql query 4"
"${mysql[@]}" <<-EOSQL
      GRANT RELOAD,PROCESS,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'%';
EOSQL
echo "Mysql query 5"
"${mysql[@]}" <<-EOSQL
      CREATE USER 'monitor'@'%' IDENTIFIED WITH mysql_native_password by '${MONITOR_PASSWORD}';
EOSQL
echo "Mysql query 6"
"${mysql[@]}" <<-EOSQL
      GRANT REPLICATION CLIENT ON *.* TO monitor@'%';
EOSQL
echo "Mysql query 7"
"${mysql[@]}" <<-EOSQL
      GRANT PROCESS ON *.* TO monitor@'%';
EOSQL
echo "Mysql query 8"
"${mysql[@]}" <<-EOSQL
      CREATE USER 'hpclustercheckuser'@'%' IDENTIFIED WITH mysql_native_password by '';
      ALTER USER 'hpclustercheckuser'@'%' WITH MAX_CONNECTIONS_PER_HOUR 0;
EOSQL
echo "Mysql query 9"
"${mysql[@]}" <<-EOSQL
      DROP DATABASE IF EXISTS test;
EOSQL
echo "Mysql query 10"
"${mysql[@]}" <<-EOSQL
      FLUSH PRIVILEGES;
EOSQL
echo "Mysql query 11"
"${mysql[@]}" <<-EOSQL
      ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by '${MYSQL_ROOT_PASSWORD}';
      ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password by '${MYSQL_ROOT_PASSWORD}';
EOSQL



       if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
        mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
       fi
   
       if [ "$MYSQL_DATABASE" ]; then
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
        mysql+=( "$MYSQL_DATABASE" )
       fi
   
       if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
        echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED  '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"
   
        if [ "$MYSQL_DATABASE" ]; then
          echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
        fi
   
        echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
       fi
   
       if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
        "${mysql[@]}" <<-EOSQL
           ALTER USER 'root'@'%' PASSWORD EXPIRE;
EOSQL
       fi
       if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'MySQL init process failed.'
        exit 1
       fi
       if [[ ! -f "${MYSQL_ERROR_LOG_DIR}/error.log" ]] ;then 
        touch ${MYSQL_ERROR_LOG_DIR}/error.log
       fi
       ln -sf  ${MYSQL_ERROR_LOG_DIR}/error.log /dev/stdout
       chown mysql:mysql ${MYSQL_ERROR_LOG_DIR}/error.log
       echo 'MySQL init process done. Ready for start up.'
       echo
    fi
    fi
    chown mysql:mysql -R -v ${DATADIR:-/var/lib/mysql}
   
}

supervisord_mysql(){
  echo
  echo "Registering in the discovery service $DISCOVERY_SERVICE"
  echo
     
set +e
  # Get ips from pxc services
  i1=$(dig +short -p 8600 $PXC_SERVICE) || ""
  # Remove this container ip from the list
  i2=$(echo $i1 | sed -r "s/$ipaddr//") || ""
  cluster_join=$(funct_join , $i2 )
  echo "Joining cluster $cluster_join"
set -e
  
  if [[ ! -f "${MYSQL_ERROR_LOG_DIR}/error.log" ]] ;then 
    touch ${MYSQL_ERROR_LOG_DIR}/error.log
  fi
  ln -sf  ${MYSQL_ERROR_LOG_DIR}/error.log /dev/stdout
  chown mysql:mysql ${MYSQL_ERROR_LOG_DIR}/error.log
  /bin/cat <<OEF> /tmp/script_run_pxc8.sh
#!/usr/bin/env bash
if [[ -d "${DATADIR:-/var/lib/mysql}/sst-xb-tmpdir" ]];then
  rm -rf ${DATADIR:-/var/lib/mysql}/sst-xb-tmpdir
fi     
mysqld --user=mysql  --log-error-verbosity=2 --wsrep-cluster-name=$CLUSTER_NAME --wsrep-cluster-address="gcomm://$cluster_join" --wsrep-sst-method=xtrabackup-v2  --wsrep-node-address="$ipaddr"  --wsrep-log-conflicts --pxc-encrypt-cluster-traffic=OFF --log-error=${MYSQL_ERROR_LOG_DIR}/error.log $CMDARG
OEF
  chmod +x  /tmp/script_run_pxc8.sh
  /bin/cat <<OEF> /etc/supervisor/conf.d/pxc-8-0.conf

[supervisord]
nodaemon=true

[program:pxc-8-0]
command=/tmp/script_run_pxc8.sh
process_name=%(program_name)s
autostart=true
autorestart=true
user=root
startretries=10
priority=999
stopsignal=TERM
stopwaitsecs=25
stopasgroup=false
killasgroup=false
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0

[program:dumb]
command=tail -f /dev/null
autostart=true
autorestart=true
user=root
startretries=10
priority=10
stopsignal=TERM
stopwaitsecs=50
stopasgroup=false
killasgroup=false
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0




OEF
echo "Run mysqld supervisord Options"
echo "------------------------"
cat /tmp/script_run_pxc8.sh | grep 'mysqld'
echo "------------------------"
}

supervisord_consul(){

  echo "{ \"services\": [ { \"name\": \"${CONSUL_SERVICE}\", \"address\": \"$ipaddr\", \"port\": 3306, \"Tags\": $tags, \"checks\": [ { \"name\": \"check if percona port is open\", \"tcp\": \"$ipaddr:3306\", \"interval\": \"10s\", \"timeout\": \"5s\" } ] } ] }" > /tmp/pxc.json

  /bin/cat <<OEF> /etc/supervisor/conf.d/consul-client.conf

[supervisord]
nodaemon=true

[program:consul-client]
command=/bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-file /tmp/pxc.json
autostart=true
autorestart=true
user=root
startretries=10
priority=2
stopsignal=TERM
stopwaitsecs=50
stopasgroup=false
killasgroup=false
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
OEF
}

main(){
  echo "cmd_args = ${cmd_args}"
  if [[ "${cmd_args}" == "mysql_tune" ]];then
    mysql_tune
  else
    func_consul_agent_start
    mysql_main
    mysql_tune
    mysql_postcheck
    supervisord_mysql
    supervisord_run
  fi
}

main