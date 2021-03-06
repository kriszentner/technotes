# Introduction
There are a variety of methods of getting logs into graylog. Graylog can accept logs by enabling inputs, of which there is a variety.
## Graylog Inuts
Some of the more common ones:
* Syslog
* [GELF](http://docs.graylog.org/en/latest/pages/gelf.html) - Logstash's own structured format

## Client Tools
For the following client tools, Logstash and Fluentd were the more heavy services, but also the most flexible. They could be run as a standalone service on each client, or a centralized service. Logstash was by far the heaviest service, and for this reason I didn't pursue a Logstash tutorial. NXLog had the least memory usage.
* rsyslogd (standard on Ubuntu)
* [Logstash](https://github.com/elastic/logstash) - From the competing ELK stack. Ruby based log sender.
  * [Can send to graylog via GELF](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-gelf.html)
  * [Can be run via docker](https://www.elastic.co/guide/en/logstash/current/docker-config.html)
  * In my tests, 520MB memory used in container. 700MB image.
* [Fluentd](https://github.com/fluent/fluentd) - Ruby based log sender
  * Possible with the fluent-plugin-gelf forks.
  * See [tutorial](/Metrics-Monitoring/fluentd/fluentd-gelf/README.md) in this repo
  * In my tests, the container uses about 50MB memory. 36MB image size.
* [FluentBit](http://fluentbit.org)
  * Should have GELF support in after [0.14](https://github.com/fluent/fluent-bit/pull/521) release.
  * 7MB memory used in container. 83MB image size (Debian base)
* [NXLog](https://nxlog.co) - C based log sender
  * Has a native GELF plugin. Similar configuration to Fluentd
  * See [tutorial](/Metrics-Monitoring/nxlog/nxlog-gelf-gelf/README.md) in this repo  
  * In  my tests, container uses about 4MB memory, 196MB image size due to running Ubuntu instead of Alpine.


# Enable a syslog input
The easiest way to get logs into graylog is to enable an [input on graylog](docs.graylog.org/en/latest/pages/sending_data.html).

The downside of this versus the [GELF format](http://docs.graylog.org/en/latest/pages/gelf.html) is that your logs end up in graylog fairly unstructured. That is, you don't have fields for the process, pid, etc. This makes searching and creating dashboards more difficult and less efficient. Using tools like Fluentd and Logstash to send logs to a GELF input on graylog get around this.

## On the client
If using Ubuntu, you can simply create a file (replacing the ip with your graylog instance below):
`/etc/rsyslog.d/40-graylog.conf`
```conf
*.* action(type="omfwd" target="10.11.12.13" port="514" protocol="tcp"
           action.resumeRetryCount="100"
           queue.type="linkedList" queue.size="10000")
```
Then restart rsyslog
```bash
systemctl restart rsyslog