mysqlroot() {
	echo "Run mysql with root from env" && mysql -u root -p$MYSQL_ROOT_PASSWORD "$@"
}
