# Running the Container
Reference: [Using Docker](http://docs.grafana.org/installation/docker/)

## Create Storage
You should probably create some storage:
```bash
docker volume create grafana-storage
```

## Docker Run
```bash
docker run \
--restart=unless-stopped \
-d \
-p 3000:3000 \
--name grafana \
-v grafana-storage:/var/lib/grafana \
-e "GF_SECURITY_ADMIN_USER=admin" \
-e "GF_SECURITY_ADMIN_PASSWORD=MyGrafanaPassword" \
-e "GF_USERS_ALLOW_SIGN_UP=false" \
grafana/grafana
```

# Docker Compose
```bash
 grafana:
    image: grafana/grafana:5.2.1
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    networks:
      - backend
    links:
      - prometheus
    volumes:
      - grafana-storage:/var/lib/grafana
      - /var/batch-shipyard/grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER={GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD={GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
```