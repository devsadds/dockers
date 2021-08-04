#!/bin/sh
TDS_SER_NAME_DEF="mssql01"
TDS_HOST_DEF="mssql01"
TDS_PORT_DEF="1433"
TDS_VER_DEF="7.1"
TDS_INSTANCE_DEF="MSSQL01"


freetds_conf_init() {

/bin/cat <<OEF> /etc/freetds/freetds.conf

[global]
        # TDS protocol version
;	tds version = 4.2

	# Whether to write a TDSDUMP file for diagnostic purposes
	# (setting this to /tmp is insecure on a multi-user system)
;	dump file = /tmp/freetds.log
;	debug flags = 0xffff

	# Command and connection timeouts
;	timeout = 10
;	connect timeout = 10
	
	text size = 164512


# A typical Microsoft server
[${TDS_SER_NAME:-${TDS_SER_NAME_DEF}}]
  host = ${TDS_HOST:-${TDS_HOST_DEF}}
  port = ${TDS_PORT:-${TDS_PORT_DEF}}
  tds version = ${TDS_VER:-${TDS_VER_DEF}}
  instance = ${TDS_INSTANCE:-${TDS_INSTANCE_DEF}}


OEF
}


main() {
	freetds_conf_init
}

main


