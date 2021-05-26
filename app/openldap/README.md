


main.load

```lisp
load database
  from sqlite:///docker-compose/org/foxcom/monitoring/data/grafana/grafana.db
  into postgresql://grafana-user-foxcom:grafana-pass-foxcom@postgres-server/grafana-foxcom
  with data only, reset sequences
  set work_mem to '16MB', maintenance_work_mem to '512 MB';
```

Run options

```


```


# DOCS
https://github.com/dimitri/pgloader/tree/v3.6.2

https://polyglot.jamie.ly/programming/2019/07/01/grafana-sqlite-to-postgres.html