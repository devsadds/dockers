

  elasticsearch_exporter:
    image: "registry.gitlab.com/devops_containers/dockers/exporter_elasticsearch:v1.2.1"
    environment:
      ES_URI: "http://svc-elasticsearch-lb.es-standalone:9200"
      WEB_TELEMETRY_PATH: "/metrics"
      WEB_LISTEN_ADDRESS: ":9114"
      ES_SNAPSHOTS: "true"
      ES_SHARDS: "true"
    #ports:
    #- "127.0.0.1:9114:9114"
    networks:
      - elastic
      - ingress
    deploy:
      replicas: 1
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 10s