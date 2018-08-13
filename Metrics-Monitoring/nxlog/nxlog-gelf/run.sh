#!/bin/sh
#
# We set the hostname to be the root's hostname so the source value is correct in graylog
# The UID is set to the systems syslog account to be able to grok and write the .pos file. 
#
# Change the NXLOG_CONF to be /nxlog_custom.conf if you want to use the custom one.
# To use the built-in one use nxlog.conf. The -v/etc/nxlog/nxlog_custom.conf line can also
# be removed.
#
docker run \
  --rm \
  --name nxlog-gelf \
  --hostname $(hostname) \
  -v/etc/nxlog/nxlog_custom.conf:/nxlog/etc/nxlog_custom.conf \
  -v/var/log/chef:/nxlog/log/chef \
  -e NXLOG_CONF=nxlog_custom.conf \
  -e nxlog_UID=$(id -u syslog) \
  -p 5140:5140 \
  -d nxlog-gelf
