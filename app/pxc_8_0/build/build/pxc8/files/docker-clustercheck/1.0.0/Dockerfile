# clustercheck Dockerfile
# Solnet Solutions
# Version: 1.0.0

# Pull base image (Ubunu 14.04)
FROM ubuntu:14.04

# Build Instructions
# When building use the following flags:
#      --tag "solnetcloud/clustercheck:1.0.0"

# Run Instructions:
# You will want to expose the clustercheck port (9200) to the host
# When running use the following flags:
#      --restart=on-failure
# The following command line arguments are supported.
# usage: entry [-h] mysql_ip mysql_port mysql_user mysql_pass

# Run a docker container containing a clustercheck Instance

# positional arguments:
#   mysql_ip    The IP address of the host that is running MySQL
#   mysql_port  The port that the host is listening on for MySQL
#   mysql_user  The user to connect through to MySQL for monitor checks of the
#               cluster health
#   mysql_pass  The password for the user to connect through to MySQL for
#               monitor checks of the cluster health

# optional arguments:
#   -h, --help  show this help message and exit

# Information
MAINTAINER Eric Duggan <eric.duggan@solnet.co.nz>
LABEL Description="This image is used to stand up a clustercheck instance." Version="1.0.0"

# Set the clustercheck version to be pinned
ENV MSC_PKG_VRS 1.0.0

RUN \
    apt-get update && \
    apt-get install -y python-software-properties python python-jinja2 python-ipy mysql-client-5.6 wget xinetd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone
RUN \
    echo "Pacific/Auckland" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Create templates directory for clustercheck
RUN \
    mkdir -p /clustercheck-templates

# Templates
COPY templates/my.cnf /clustercheck-templates/my.cnf
COPY templates/clustercheck /clustercheck-templates/clustercheck

# Add clusterchk group and user
RUN \
    groupadd -g 7000 clustchk && \
    useradd -u 7000 -g 7000 -c "Clustercheck user,,," -d /nonexistent -s /bin/false clustchk

# Install clustercheck script
RUN \
    wget -O /usr/bin/clustercheck https://raw.githubusercontent.com/olafz/percona-clustercheck/master/clustercheck && \
    chmod 755 /usr/bin/clustercheck && \
    printf "clustercheck\t9201/tcp\n" >> /etc/services

# Entry script
COPY scripts/entry.py /usr/local/bin/entry
RUN chmod +x /usr/local/bin/entry

# Expose ports to other containers
# Expose 9201: clustercheck
EXPOSE 9201

# Define the default command as entrypoint
ENTRYPOINT ["/usr/local/bin/entry"]
