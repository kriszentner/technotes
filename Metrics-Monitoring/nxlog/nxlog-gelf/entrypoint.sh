#!/usr/bin/dumb-init /bin/sh

uid=${NXLOG_UID:-1000}

# check if a old fluent user exists and delete it
cat /etc/passwd | grep nxlog
if [ $? -eq 0 ]; then
    deluser nxlog
fi

# (re)add the fluent user with $NXUSER_UID
useradd -u ${uid} -o -c "" -m nxlog

# chown home and data folder
chown -R nxlog /home/nxlog
chown -R nxlog /nxlog
chown -R nxlog /var/run/nxlog
mkdir -p /var/spool/nxlog
chown -R nxlog /var/spool/nxlog

exec gosu nxlog "$@"