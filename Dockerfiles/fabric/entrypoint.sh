#!/usr/bin/dumb-init /bin/sh

if [ -f /fabric/id_rsa ];then
  mkdir -p /root/.ssh/
  chmod 700 /root/.ssh/
  cp /fabric/id_rsa /root/.ssh/id_rsa
  chmod 400 /root/.ssh/id_rsa
fi
exec "$@"
