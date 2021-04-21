
curl -L https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz -o /tmp/node_exporter-1.1.2.linux-amd64.tar.gz
cd /tmp/ && tar -xvf node_exporter-1.1.2.linux-amd64.tar.gz

if [[ ! -d "/etc/prometheus/exporters/bin/" ]];then 
	mkdir -p /etc/prometheus/exporters/bin/
fi
mv /tmp/node_exporter-1.1.2.linux-amd64/node_exporter /etc/prometheus/exporters/bin/
chmod +x  /etc/prometheus/exporters/bin/node_exporter



/etc/prometheus/exporters/bin/node_exporter --collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)" --web.max-requests=3 --web.listen-address="172.22.1.1:9101" --collector.systemd  --web.disable-exporter-metrics




EXPORTER_NODE_URL: "172.22.1.1:9100"
EXPORTER_CADVISOR_URL: "172.45.0.12:8080"

curl -s -o /dev/null -w "%{http_code}" http://heplify-server:9096

cat <<OEF> /etc/supervisor/conf.d/exporter_node.conf
#<!-- BEGIN node_exporter -->
[supervisord]
nodaemon=true
environment=HOME="/usr/bin/"
[program:node_exporter]
command=/etc/prometheus/exporters/bin/node_exporter --collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)" --web.max-requests=3 --web.listen-address="10.11.0.7:9101" --web.disable-exporter-metrics
autostart=true
autorestart=true
startretries=300
stderr_logfile=/var/log/node_exporter.err
stdout_logfile=/var/log/node_exporter.log
[include]
files = /etc/supervisor/conf.d/*.conf
#<!-- END node_exporter -->
OEF
supervisorctl reread
supervisorctl update

cat <<OEF>  /etc/prometheus/exporters/docker-compose.yml

version: '2.0'

services:
  nginx:
    #image: "devsadds/nginx-exporter-proxy:latest"
    image: "devsadds/nginx_proxy_exporters:1.1.0"
    restart: always
    ports:
      - "9100:9100"
      - "9325:9325"
    environment:
      EXPORTERS_SCRAPE_ALLOW_NET: "217.195.215.206/32,10.0.0.0/8,172.0.0.0/8,217.195.215.247/32,95.217.14.7/32,82.142.149.214/32"
      EXPORTER_NODE_URL: "172.45.0.11:9100"
    mem_limit: 128M
    networks:
      exporters-network:
        ipv4_address: 172.45.0.10
        aliases:
          - nginx-expoter

  exporter_node:
    image: "prom/node-exporter:v1.1.2"
    user: root
    privileged: true
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
      - /run/systemd/private:/run/systemd/private:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
      - '--web.listen-address=:9100'
      - '--web.max-requests=3'
      - '--collector.tcpstat'
      - '--collector.interrupts'
      - '--collector.qdisc'
    restart: unless-stopped
    mem_limit: 128M
    networks:
      exporters-network:
        ipv4_address: 172.45.0.11
        aliases:
          - node-exporter
    labels:
      org.label-schema.group: "monitoring"
  cadvisor:
    image: "google/cadvisor:v0.33.0"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /sys/fs/cgroup:/cgroup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /dev/disk/:/dev/disk:ro
      - /dev/kmsg:/dev/kmsg:ro
    privileged: true
    restart: unless-stopped
    mem_limit: 128M
    networks:
      exporters-network:
        ipv4_address: 172.45.0.12
        aliases:
          - cadvisor-exporter
    labels:
      org.label-schema.group: "monitoring"


  reports:
    image: skedler/reports:latest
    container_name: reports
    ports:
      - 3000:3000
    privileged: true
    cap_add:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - ./data/skedler:/var/lib/skedler
      - /docker-compose/develop/reports/reporting.yml:/opt/skedler/config/reporting.yml
    command: /opt/skedler/bin/skedler
    networks:
      exporters-network:
        ipv4_address: 172.45.0.13
        aliases:
          - reports

networks:
  exporters-network:
    ipam:
      config:
        - subnet: 172.45.0.0/24


OEF

mkdir -p /etc/prometheus/exporters/data/skedler
chmod 777 -R /etc/prometheus/exporters/data/skedler
cd  /etc/prometheus/exporters/ &&  docker-compose pull  && docker-compose up -d