# Fabric 2.x is basically a rewrite, and doesn't support host lists very well
# We're waiting till more functionality gets backported.
FROM python:3-alpine3.8
RUN apk update \
 && apk add python3-dev libffi-dev openssl-dev dumb-init openssh-client \
 && apk add build-base \
 && pip install fabric3 \
 && apk del build-base \
 && mkdir /fabric \
 && mkdir /root/.ssh \
 && chmod 700 /root/.ssh \
COPY resolv.conf /etc/resolv.conf
COPY fabfile.py /fabric/fabfile.py
COPY entrypoint.sh /entrypoint.sh
COPY config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chmod 755 /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /fabric
#CMD ["-w","-R","misclinux","hostname"]
