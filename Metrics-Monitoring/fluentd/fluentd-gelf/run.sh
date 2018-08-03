#!/bin/sh
FLUENT_UID=0
docker run \
  --name fluentd-gelf \
  -v/etc/fluentd/fluent_custom.conf:/fluentd/etc/fluent_custom.conf \
  -v/var/log/chef:/fluentd/log/chef \
  -e FLUENTD_CONF=fluent_custom.conf \
  -e FLUENT_UID=$(id -u syslog) \
  -d fluentd-gelf
