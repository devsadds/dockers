#!/bin/bash
##############
POSTGRES_USER="postgres"
set -e
##############
export pg_password=$(export | grep "POS.*_PAS.*$" | head -n1  | awk -F "=" '{print $2}' | sed 's/^.//' | sed 's/.$//' )
export pg_user=$(export | grep "POS.*_USER.*$"  | awk 'END{print}' | awk -F "=" '{print $2}' | sed 's|\"||g'   | head -n 1)
if [ -z "$pg_user" ];then
    echo "pg_user undefined - fallback to user = postgres"
    pg_user="postgres"
fi
echo "pg_password=$pg_password"
echo "pg_user=$pg_user"


exporter_add() {
PGPASSWORD=${pg_password} psql  --username ${pg_user} <<-EOSQL

CREATE USER postgres_exporter PASSWORD 'kiokfhubhlundsfjbdsufdsf';
alter user postgres_exporter with password 'kiokfhubhlundsfjbdsufdsf';
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;
CREATE SCHEMA postgres_exporter AUTHORIZATION postgres_exporter;
CREATE VIEW postgres_exporter.pg_stat_activity AS SELECT * from pg_catalog.pg_stat_activity;
GRANT SELECT ON postgres_exporter.pg_stat_activity TO postgres_exporter;
CREATE VIEW postgres_exporter.pg_stat_replication AS SELECT * from pg_catalog.pg_stat_replication;
GRANT SELECT ON postgres_exporter.pg_stat_replication TO postgres_exporter;

EOSQL

}

##############
exporter_add
