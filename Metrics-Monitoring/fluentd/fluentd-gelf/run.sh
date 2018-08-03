#!/bin/sh
#
# We set the hostname to be the root's hostname so the source value is correct in graylog
# The UID is set to the systems syslog account to be able to grok and write the .pos file. 
#
docker run \
  --name fluentd-gelf \
  --hostname $(hostname) \
  -v/etc/fluentd/fluent_custom.conf:/fluentd/etc/fluent_custom.conf \
  -v/var/log/chef:/fluentd/log/chef \
  -e FLUENTD_CONF=fluent_custom.conf \
  -e FLUENT_UID=$(id -u syslog) \
  -d fluentd-gelf
