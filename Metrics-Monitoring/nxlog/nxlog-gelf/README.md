# Introduction
Let's give some basics on running nxlog. In this example we will put fluentd in a container, with the example of wanting it to sync a chef log.


# The Task
We'll take chef logs, and get nxlog to ship them to graylog.

To make this happen we'll need to do the following:  
* Identify what we want to log
* Enable tcp-gelf as an input on graylog
* Build a custom nxlog-gelf container that we'll use to ship logs
* Run it (you can also create a custom docker repo and host it there, but that's outside the scope of this article)

# The environment
## Chef Logs
Our chef logs are being shipped to `/var/log/chef/client`. So we have the folowing in our `/etc/chef/client.rb`
```
log_level :info
log_location "/var/log/chef/client.log"
```
Also, to be consistant, we have the permissions of this directory to owned by `syslog:adm`:
```
ls -ald /var/log/chef
drwxr-xr-x 2 syslog adm 4096 Aug  2 00:00 /var/log/chef
```

## Syslogs
We'll can ship all our syslogs to graylog. You can use the file 40-nxlog.conf in this directory, and copy it to your `/etc/rsyslog.d/` directory. After you start your docker container (below), you can activate it with
```bash
systemctl restart rsyslogd
```

# Build a nxlog-gelf container
The files in the this directory are a good start. You're best off if you copy that directory to the host you're building your container in.

You'll want to customize [Dockerfile](Dockerfile) if needed.  
The [run.sh](run.sh) should include the path to your log file (in this case it's chef).

You'll need to customize the [nxlog.conf](fluent.conf) to include the address of your graylog server. You can also use this to customize which logs you wish to grok. In this case I've created a custom regex parser for the chef logs. Also, the run script expects this file to be in `/nxlog/etc/nxlog_custom.conf` so it can be overriden. However, the Docker build script needs some sort of `nxlog.conf` to be in here as the default.

You'll also notice that in the `run.sh` the NXLOG_UID is set to syslog. This allows the fluentd script to go into the log dir that we have owned by syslog, and read contents. Fluentd also tracks the log with a `.pos` file, so it needs to be able to write this file in that directory.

Once you customize these files, it's as simple as running:
```
./build.sh
./run.sh
```

# Running the Container
Compared to fluentd, nxlog has very little logging unless set to debug mode (see the nxlog.conf). The logs it puts into graylog more strictly follow the [GELF spec](http://docs.graylog.org/en/latest/pages/gelf.html#gelf-payload-specification). Which means you get a preview of the message in the "message" field, but the "full_message" field contains the whole message. It is possible to modify graylog2 to display the full_message by default in the Search pane.


# References
Articles and Sites that made this possible

[NXLog Reference Manual](https://nxlog.co/docs/nxlog-ce/nxlog-reference-manual.html)  
[Regex Tester](https://regex101.com)  
[Fluentator Regex Tester](http://fluentular.herokuapp.com)  
