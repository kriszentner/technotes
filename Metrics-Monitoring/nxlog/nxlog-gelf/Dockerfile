FROM ubuntu:18.04
#
ENV DUMB_INIT_VERSION=1.2.1
ENV GOSU_VERSION=1.10
RUN apt-get update \
 && apt-get install libapr1 libcap2 libdbi1 libexpat1 libperl5.26 libssl1.1 libssl1.0.0 gpg curl -y \
 && curl -s -L $(curl -s -L https://nxlog.co/products/all/download|grep "<span class=\"file\">"|grep bionic|awk -F\" '{ print $4 }') -o /tmp/nxlog.deb \
 && dpkg -i /tmp/nxlog.deb \
 && rm /tmp/nxlog.deb \
 && apt-get autoremove -y -q \
 && mkdir -p /nxlog/etc \
 && mkdir -p /nxlog/log \
 && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
 && curl -L  https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_$dpkgArch -o /usr/bin/dumb-init \
 && chmod +x /usr/bin/dumb-init \
 && curl -L "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" -o /usr/local/bin/gosu \
 && curl -L "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" -o /usr/local/bin/gosu.asc \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true
RUN rm -rf /var/lib/apt/lists/*

COPY nxlog.conf /nxlog/etc/
COPY entrypoint.sh /bin/
EXPOSE 5140/tcp

ENV NXLOG_OPT=""
ENV NXLOG_CONF="nxlog.conf"

ENTRYPOINT ["/bin/entrypoint.sh"]

CMD exec /usr/bin/nxlog -c /nxlog/etc/${NXLOG_CONF} -f