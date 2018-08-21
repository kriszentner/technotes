#!/bin/bash
#
# This won't run so well in WSL as it seems to have a hard time importing files as not directories. 
# Also you can do -v/path/to/ubuntu_password:/fabric/ubuntu_pass if you want to be able to use
# fabric with a password. Assuming you have hosts that support it.
#
myhome=$(ls -d1 ~/)
if [ -f ~/.ssh/id_rsa ];then
   myrsa=$myhome/id_rsa
elif [ -f ~/.ssh/id_dsa ];then
   myrsa=$myhome/id_dsa
fi
docker run --rm \
           -it \
           -v$myrsa:/fabric/id_rsa \
           fabric \
           /bin/sh
# Run fabric
# docker run -it --rm -v/home/krisz/.ssh/id_rsa:/fabric/id_rsa fabric fab -w -R test hostname
# Run ad-hoc
# docker run -it --rm -v/home/krisz/.ssh/id_rsa:/fabric/id_rsa fabric fab -w -Hmyhostname 'hostname'
