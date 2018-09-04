# Scenario
Let's say you want to be able to allow users to log into a host, say as a gateway or bastion host. However you want the functionality to be fairly locked down. This is not to make an sftp only host. You want to provide terminal access.

One such method is to use a chroot, and it is fairly secure. However, to provide access to binaries and such you need to provide libraries and devices. Doing so isn't always straight forward. Sometimes ldd doesn't provide all the libraries that the binary would need.

You also want to be able to have admin access with more enhanced functionality to the host, so you can't strip all the binaries on the host. You could make a separate VM or...you could use Docker.

# Solution
There are three parts to this solution:
* Modification of the sshd_config file is /etc/ssh/
* A script that is executed by the ssh daemon
* A docker container

## SSHD Modification
Most of the secret sauce is in using the `ForceCommand` directive. If your admins are also in your users group. You'll want to whitelist them with the Match rule first. Users will take the ForceCommand script. Here's a sample of what to put at the end of your `sshd_config`:
```conf
Match group admins
  ForceCommand none

Match group users
  ForceCommand /usr/local/bin/execdocker.sh %u
```

## ForceCommand Script
The ssh program will usually pass PAM_USER as an environment variable to scripts it runs (Like `ForceCommand` and `AuthorizedKeysCommand`). You'll see that I'm creating some additional files for the user by default. However note that pam_mkhomedir does run with `ForceCommand` (it won't with `ChrootDirectory`). Also you'll see that I'm getting the UID of the username, and not the ID name. This is because Docker won't work so will if you do a -u with an ID name that is not in /etc/passwd, so this takes care of that. If you want to mount /etc/passwd in your container, that's up to you. Also if you're using some sort of network based password system like nss_ldap, you'll need to build that into your container for UID->ID Name resolution to work

`/usr/local/bin/execdocker.sh`
```
#!/usr/bin/env sh
if [ -n "$PAM_USER" ];then
  USERNAME=$PAM_USER
elif [ -n "$USER" ];then
  USERNAME=$USER
elif [ -n "$SUDO_USER" ];then
  USERNAME=$SUDO_USER
else
  exit 0
fi
USERHOME=$(eval echo ~$USERNAME)
if [ ! -d $USERHOME/.ssh ];then
  mkdir -p $USERHOME/.ssh
  touch ${USERHOME}/.ssh/authorized_keys
  chmod 644 ${USERHOME}/.ssh/authorized_keys
fi
/usr/bin/docker exec -it -u $(id -u $USERNAME) -w $(eval echo ~$USERNAME) docker-chroot /bin/bash
```
## Replacing pam_mkhomedir (optional)
With ForceCommand, PAM's mkhomedir is usually executed by default. On Ubuntu systems. You can find this at the end of `/etc/pam.d/common-session`. Of course if you wanted further customization. You could replace `pam_mkhomedir` with a script of your choice like so:
`/etc/pam.d/common-session`  
Replace this:
```
session required     pam_mkhomedir.so skel=/etc/skel/ umask=0077
```
with:
```
session required     pam_exec.so /usr/local/bin/userlogin.sh
```
## The Container
For the container, you want something as minimal as you can make it. If you can get away with [busybox](https://hub.docker.com/_/busybox/), or [alpine](https://hub.docker.com/_/alpine/) you'll be better off. In this case I'm using Ubuntu which still provides a fairly minimalistic container. In this case, I'm allowing users to edit a file in their home directory with an editor of their choice. Much of the reason for this was that chrooting emacs isn't trivial, and my users really like emacs.

### Better security
For your Dockerfile. If this is a container to lock down what users can do. It would be worthwhile to look into Linux Kernel Capabilities and drop ones as appropriate. Looking at the [capabilities(7)](http://man7.org/linux/man-pages/man7/capabilities.7.html) man page is a good place to start. As is this [primer on Docker security tuning](https://opensource.com/business/15/3/docker-security-tuning) and . You'll see in my `docker run` command below, I've restricted some default docker capabilities.

`Dockerfile`
```Dockerfile
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install apt-utils \
                     vim \
                     nano \
                     emacs-nox \
                    -y \
  && rm -rf /var/lib/apt/lists/*
```
From here you can build your dockerfile:
```
docker build -t docker-chroot Dockerfile .
```
And run it. Be sure you mount the home directories so users have a place to be:
```bash
docker run \
  --restart=always \
  -it \
  --cap-drop kill \
  --cap-drop net_bind_service \
  --cap-drop dac_override \
  --cap-drop mknod \
  --cap-drop net_raw \
  --cap-drop setfcap \
  -h docker-chroot \
  --name docker-chroot \
  -v/home:/home \
  -d \
  docker-chroot
```

# References
* [Linux Capabilities and when to drop all](https://raesene.github.io/blog/2017/08/27/Linux-capabilities-and-when-to-drop-all/)
* [Man capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html)
* [Docker security tuning](https://opensource.com/business/15/3/docker-security-tuning)