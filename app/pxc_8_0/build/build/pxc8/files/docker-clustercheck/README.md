# docker-clustercheck
clustercheck is a script for proper reporting of Percona XtraDB cluster nodes

More details can be found at the github page at https://github.com/olafz/percona-clustercheck

This Docker build builds on top of a Ubuntu image to provide an instance that listens on TCP port 9200 using xinetd.  It uses the clustercheck script to check the status of each node in a Galera cluster.  The script monitors the Galera status on each node, and returns 200 if the node is up and synced or 503 if not.  This is designed to be used by HAProxy to determine whether or not to send traffic to that node.

You need to provide the IP address of the host running the MySQL container you are monitoring, the port listening on the host, the cluster monitor use to connect as, and the cluster monitor user's password.  It is recommend you use restart on-failure.

    docker run -d --restart=on-failure -p 9200 --name mysqlchk-1 solnetcloud/mysqlchk:1.0.0 10.1.40.109 49174 clustercheckuser clustercheckpwd

    usage: entry [-h] mysql_ip mysql_port mysql_user mysql_pass

    Run a docker container containing a clustercheck Instance

    positional arguments:
      mysql_ip    The IP address of the host that is running MySQL
      mysql_port  The port that the host is listening on for MySQL
      mysql_user  The user to connect through to MySQL for monitor checks of the
                  cluster health
      mysql_pass  The password for the user to connect through to MySQL for
                  monitor checks of the cluster health

    optional arguments:
      -h, --help  show this help message and exit

The configuration of the clustercheck is designed to be orchestrated by a tool such as Puppet.  
