echo  "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-${MARIADB_ROOT_PASSWORD}}"

mysqlroot() {
	echo "Run mysql with root from env" && mysql -u root -p"${MYSQL_ROOT_PASSWORD:-${MARIADB_ROOT_PASSWORD}}" "$@"
}
