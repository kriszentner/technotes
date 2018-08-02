#!/bin/bash
sudo curl -L $(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | cut -d '"' -f 4|grep "$(uname -s)-$(uname -m)$") -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
