# Running it as a container
```bash
mkdir /conf
mkdir /promethus
chmod 755 /prometheus
```
Create your `/conf/prometheus.yml`. A simple one without alerting
```bash
global:
  scrape_interval: 10s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'dummy'
    file_sd_configs:
      - files:
        - '/conf/*.json'
```
## Create Storage
```bash
docker volume create prometheus-storage
```

## Run docker

Finish setting up prometheus. You can run the below as a script
```bash
docker run \
--restart=unless-stopped \
--name prometheus \
-d \
-v/conf:/conf \
-vprometheus-storage:/prometheus \
-p9090:9090 \
--entrypoint='/bin/prometheus' \
quay.io/prometheus/prometheus \
'--config.file=/conf/prometheus.yml' \
'--storage.tsdb.path=/prometheus' \
'--web.console.libraries=/usr/share/prometheus/console_libraries' \
'--web.console.templates=/usr/share/prometheus/consoles'
```
From here you should be able to to the host at port 9090 and query.

# Some basic queries
[Query Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)  
[Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)  

Show all  metrics:
```
{__name__=~".+"}
```
Show free MB on filesytem:
```
node_filesystem_free_bytes/(1024^2)
```
CPU Metric:
[Understanding CPU Usage](https://www.robustperception.io/understanding-machine-cpu-usage)
```
irate(node_cpu_seconds_total{job="kznode01", mode="user"}[5m])
```