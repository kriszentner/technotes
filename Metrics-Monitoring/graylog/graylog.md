# Installation
This will focus on the docker install showing other options as possibilities.

## Chef
Installation [with Chef](https://github.com/Graylog2/graylog2-cookbook) requires installing the following community cookbooks:
* java
* mongodb
* elasticsearch
* authbind
* graylog2

## Ubuntu
The [Ubuntu Installation](http://docs.graylog.org/en/latest/pages/installation.html) is also somewhat straightforward

## Docker
Using [Docker](http://docs.graylog.org/en/latest/pages/installation/docker.html) is also possible. This seems like a pretty smart way to do it.
Initial Setup
```bash
docker volume create mongo_data
docker volume create es_data
docker volume create graylog_journal
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/ssl
```
## Configs and Certs
*[reference: nginx ssl cert creation](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04https:/www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04)*

Create your nginx default.conf in `/etc/nginx/conf.d`  
Put your certs in `/etc/nginx/ssl`, for self sign:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/private/nginx-selfsigned.key -out /etc/nginx/ssl/certs/nginx-selfsigned.crt
sudo openssl dhparam -out /etc/nginx/ssl/certs/dhparam.pem 2048
```
## Start Docker Containers
See [here](https://github.com/Graylog2/graylog2-server/blob/master/misc/graylog.conf) for a list of greylog container env variables
If you start these with docker-compose first, docker compose
by default will use the root_default network (see `docker network ls`). You can specify networks with:
`docker run --network="root_default"`

```bash
docker run --restart=unless-stopped \
  --name mongo \
  -d mongo:3

docker run --restart=unless-stopped \
  --name elasticsearch \
 -e "http.host=0.0.0.0"\
  -e "xpack.security.enabled=false" \
 -d docker.elastic.co/elasticsearch/elasticsearch:5.6.2

docker run --restart=unless-stopped \
  --link mongo \
  --link elasticsearch \
 -p 9000:9000 \
  -p 12201:12201 \
  -p 514:514 \
# This needs to be the endpoint your browser hits
 -e GRAYLOG_WEB_ENDPOINT_URI=http://grayloghost.westus2.cloudapp.azure.com:9000/api \
# Generate this with echo -n yourpassword | shasum -a 256 \
 -e GRAYLOG_ROOT_PASSWORD_SHA2=83319aa4190536f2e404ca8514ab12397da37665c7ad8f0e3439d962871695d2 \
 -e GRAYLOG_PASSWORD_SECRET=peppersalttabascopiripiri \
 -d graylog/graylog:2.4

docker run --restart=unless-stopped \
  --name nginx \
  -p:443:443 \
  --link graylog \
  -v/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf \
  -v/etc/nginx/ssl:/etc/ssl \
  -d nginx:mainline-alpine
```

## Adding Kibana
You can run kibana on graylog fairly easily. Just start the kibana container:
```bash
docker run --name kibana \
   --link elasticsearch \
  -p5601:5601 \
  -d kibana
```
When you go to the kibana page, it'll ask you for the index pattern. Use `graylog_*`

# Scaling Out
Eventually you'll want to get a number of elasticsearch servers. Which will case some changes with the above:
* No more starting elasticsearch on the same server. You'll need a cluster
* You'll need to add: `-e GRAYLOG_ELASTICSEARCH_HOSTS = http://host1:9200/,http://host2:9200/`