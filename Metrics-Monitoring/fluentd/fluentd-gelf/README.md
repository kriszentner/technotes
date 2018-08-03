# Introduction
Let's give some basics on running fluentd. In this example we will spin put fluentd in a container, with the example of wanting it to sync a chef log.


# The Task
We'll take chef logs, and get fluentd to ship them to graylog. Yes I know chef can ship to syslog, but we'll use the example of chef logging to it's own directory.

To make this happen we'll need to do the following:  
* Identify what we want to log
* Enable tcp-gelf as an input on graylog
* Build a custom fluentd-gelf that we'll use to ship logs
* Run it (you can also create a custom docker repo and host it there, but that's outside the scope of this article)

# The environment
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


# Build a fluentd-gelf container
The files in the this directory are a good start. You're best off if you copy that directory to the host you're building your container in.

You'll want to customize [Dockerfile](Dockerfile) if needed.  
The [run.sh](run.sh) should include the path to your log file (in this case it's chef).

You'll need to customize the [fluent.conf](fluent.conf) to include the address of your graylog server. You can also use this to customize which logs you wish to grok. In this case I've created a custom regex parser for the chef logs. Also, the run script expects this file to be in `/fluentd/etc/fluent_custom.conf` so it can be overriden. However, the Docker build script needs some sort of `fluent.conf` to be in here as the default.

You'll also notice that in the `run.sh` the FLUENT_UID is set to syslog. This allows the fluentd script to go into the log dir that we have owned by syslog, and read contents. Fluentd also tracks the log with a `.pos` file, so it needs to be able to write this file in that directory.

Once you customize these files, it's as simple as running:
```
./build.sh
./run.sh
```

# References
Articles and Sites that made this possible

[Fluentd Container](https://hub.docker.com/r/fluent/fluentd/)  
https://docs.treasuredata.com/articles/td-agent  
https://www.fluentd.org/guides/recipes/graylog2  
[Fluentd Plugin (fork)](https://github.com/craigplafferty/fluent-plugin-gelf-hs)  
[Fluentd: config file syntax](https://docs.fluentd.org/v1.0/articles/config-file)  
[Fluentd: tail input type](https://docs.fluentd.org/v1.0/articles/in_tail)
[Fluentd: List of parser plugins](https://docs.fluentd.org/v1.0/articles/parser-plugin-overview)
[Fluentd: Regexp Parser Plugin](https://docs.fluentd.org/v1.0/articles/parser_regexp)  
[Regex Tester](https://regex101.com)  
[Fluentator Regex Tester](http://fluentular.herokuapp.com)  
