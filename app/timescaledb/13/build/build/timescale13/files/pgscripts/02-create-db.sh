#!/bin/bash
##############
PG_DB_USER="$1"
PG_DB_USER_PASS="$2"
PG_DB_NAME="$3"


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


check_variables() {
pattern=$'*( |\t)'
if [[ ${PG_DB_USER} = $pattern ]]; then
    echo "First parameter PG_DB_USER has no non-whitespace characters"
    exit 1
fi
if [[ ${PG_DB_USER_PASS} = $pattern ]]; then
    echo "Second parameter PG_DB_USER_PASS has no non-whitespace characters"
    exit 1
fi
if [[ ${PG_DB_NAME} = $pattern ]]; then
    echo "Third parameter PG_DB_NAME has no non-whitespace characters"
    exit 1
fi
}



create_db() {
echo "Creating user ${PG_DB_USER} with password ${PG_DB_USER_PASS}"
echo "GRANT PRIVILEGES ON ${PG_DB_NAME} to USER ${PG_DB_USER}"
echo "From PGPASSWORD=${pg_password} psql -v --username ${pg_user}"

PGPASSWORD=${pg_password} psql  --username "${pg_user}" <<-EOSQL
create role "${PG_DB_USER}" with password '${PG_DB_USER_PASS}' login;
CREATE DATABASE "${PG_DB_NAME}" WITH OWNER "${PG_DB_USER}" ENCODING 'UTF8' TEMPLATE template0;
GRANT ALL PRIVILEGES on DATABASE "${PG_DB_NAME}" to "${PG_DB_USER}";
EOSQL

}


create_extensions() {
    if [[ -z ${EXTENSIONS} ]];then 
      EXTENSIONS=$(echo ${POSTGRES_EXTENSIONS} | tr "," "\n")
      echo "Creating postgres extension with list ${POSTGRES_EXTENSIONS}"
for EXTENSION in ${EXTENSIONS}
do
            echo "Create extension ${EXTENSION} in ${PG_DB_NAME}";
            PGPASSWORD=${pg_password} psql --username "${pg_user}" -qAt -c "CREATE EXTENSION IF NOT EXISTS \"${EXTENSION}\";" "${PG_DB_NAME}"
done
else
   echo "Skip create extensions"
fi
}

##############
help_usage
check_variables
create_db
create_extensions
#/bin/bash /pgscripts/02-create-db.sh "user1" "123123" "test_db"