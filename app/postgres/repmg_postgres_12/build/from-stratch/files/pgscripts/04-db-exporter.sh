#!/bin/bash
##############
POSTGRES_USER="postgres"
set -e
##############
exporter_add() {

PGPASSWORD=${POSTGRESQL_PASSWORD} psql --username="$POSTGRESQL_USERNAME" -v --username "$POSTGRES_USER" <<-EOSQL

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
