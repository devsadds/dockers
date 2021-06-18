#!/bin/bash
##############
PG_DB_NAME=$1 #db_name
#    .---------- constant part!
#    vvvv vvvv-- the code from above
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
#    .----------
DATETIME=$(date +%F_+%T) #date

export pg_password=$(export | grep "POS.*_PAS.*$" | head -n1  | awk -F "=" '{print $2}' | sed 's/^.//' | sed 's/.$//' )
export pg_user=$(export | grep "POS.*_USER.*$"  | awk 'END{print}' | awk -F "=" '{print $2}' | sed 's|\"||g'   | head -n 1)
if [ -z "$pg_user" ];then
    echo "pg_user undefined - fallback to user = postgres"
    pg_user="postgres"
fi
echo "pg_password=$pg_password"
echo "pg_user=$pg_user"

##############
help_usage(){
    echo "USAGE: scriptname PG_DB_USER  PG_DB_USER_PASS PG_DB_NAME"
    echo "EXAMPLE:  /bin/bash /docker-entrypoint-initdb.d/02-create-db.sh \"user1\" \"123123\" \"test_db\""
}

precheck () {

if [ "${PG_DB_NAME}" == "" ];
then
echo -e "${RED} Arg 1 - \"PG_DB_NAME\" is empty. Stop script  ${DATETIME} ${NC}"
exit 1
fi

}

prewarm_postgres() {

echo -e "${CYAN} Начинаем разогрев базы ${PG_DB_NAME}. Время начала  ${DATETIME} ${NC}"

echo -e "${CYAN} Creating extension prewarm_postgres if not exist in ${PG_DB_NAME} ${NC}"

psql  -qAt -c 'CREATE EXTENSION IF NOT EXISTS pg_prewarm;' ${PG_DB_NAME};

for tbl in `PGPASSWORD=${pg_password} psql  --username ${pg_user} -c  "select tablename from pg_tables where schemaname = 'public';" ${PG_DB_NAME}`;
do
    echo -e "${CYAN} MAKE WARM UP TABLE $tbl in DATABASE ${PG_DB_NAME} begin at ${DATETIME}${NC}"
    PGPASSWORD=${pg_password} psql  --username ${pg_user} -c  "SELECT pg_prewarm('$tbl')" ${PG_DB_NAME};
    echo -e "${GREEN} MAKE WARM UP TABLE $tbl in DATABASE ${PG_DB_NAME} finished at ${DATETIME}${NC}"

done
echo -e "${BLUE} Разогрев базы ${PG_DB_NAME} закончен в ${DATETIME} ${NC}"
}


precheck
prewarm_postgres


