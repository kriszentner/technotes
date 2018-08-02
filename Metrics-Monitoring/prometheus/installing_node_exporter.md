# Introduction
Node Exporter is a handy tool that with gather Linux metrics fom an OS for Prometheus to grok.

# Installing
Download the latest release from:
https://github.com/prometheus/node_exporter/releases

```bash
tar -zxvf node_exporter-*
mv node_exporter*/node_exporter /usr/sbin/node_exporter
```

Create a systemd file for it:
`/etc/systemd/system/node-exporter.service`
```
[Unit]
Description=Node Exporter
[Service]
Restart=always
EnvironmentFile=/etc/node_exporter.conf
ExecStart=/usr/sbin/node_exporter $OPTIONS
[Install]
WantedBy=multi-user.target
```
Create a conf file for it, be sure to customize the collectors listed on the github page:
`/etc/node_exporter.conf
--no-collector.textfile --no-collector.wifi --no-collector.zfs --no-collector.mdadm --no-collector.xfs`

Enable and start it:
```bash
systemctl daemon-reload
systemctl start node-exporter
systemctl enable node-exporter
systemctl --no-pager status node-exporter
```