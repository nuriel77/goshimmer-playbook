# GoShimmer Playbook

This repository installs a fully operational [IOTA GOSHIMMER](https://github.com/iotaledger/goshimmer) node.

*Table of contents*

<!--ts-->
   * [Requirements](#requirements)
   * [Recommendations](#recommendations)
   * [Installation](#installation)
     * [For Development](#for-development)
   * [Docker Usage Commands](#docker-usage-commands)
     * [Docker Images](#docker-images)
     * [View Docker Containers](#view-docker-containers)
     * [GoShimmer Help Output](#goshimmer-help-output)
   * [Configuration](#configuration)
   * [Control GoShimmer](#control-goshimmer)
     * [GoShimmer Controller](#goshimmer-controller)
     * [Update Goshimmer](#update-goshimmer)
     * [GoShimmer DB](#goshimmer-db)
     * [GoShimmer Dashboard](#goshimmer-dashboard)
     * [Spam Test](#spam-test)
     * [See the statusscreen](#see-the-statusscreen)
   * [Ports and URLs](#ports-and-urls)
     * [Forward Ports](#forward-ports)
     * [Expose WebApi Connection On HTTP](#expose-webapi-connection-on-http)
   * [Connect to Wallet](#connect-to-wallet)
   * [Troubleshooting](#troubleshooting)
     * [502 Bad Gateway](#502-bad-gateway)
     * [Connection not Private](#connection-not-private)
     * [Logs](#logs)
     * [Rerun Playbook](#rerun-playbook)
   * [Donations](#donations)
<!--te-->

## Requirements

Tested on the following operating systems:

* CentOS 7.x, CentOS 8.x
* Ubuntu 18/19/20.04LTS
* Debian 9.5 and 10
* Raspbian 9.9 and 10 (Tested with Raspberry Pi 4 - 4GB RAM)

Architectures (x86_64, arm/aarch 64 bit)

## Recommendations

* RAM: At least 2GB RAM, as less than this can result in out-of-memory failures.
* x2 CPUs are recommended

## Installation

You can first download the script to inspect it before running it, or run it directly:

```sh
sudo bash -c "bash <(curl -s https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/main/goshimmer_install.sh)"
```
This pulls the installation file from the root of this repository and executes it.

The installation will:

* Install latest GoShimmer and start it up.
* Configure basic security (firewalls) and open all required ports for GoShimmer to operate.
* Install nginx as a reverse proxy to access GoShimmer's Dashboard, spammer, etc.
* Add some helpful tools, e.g.: `gosc`

### For Development

If you are working on a fork in a feature branch or happen to directly contribute to this repository you can run the installer as user root, pointing it to the appropriate branch, e.g.:
```sh
BRANCH="dev-branch"; GIT_OPTIONS="-b $BRANCH" bash <(curl -s "https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/$BRANCH/goshimmer_install.sh")
```

## Docker Usage Commands

These are just a few helpful commands to help you find your way around docker:

### Docker Images

List all images
```sh
docker images
```
The output will look something like:
```sh
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
iotaledger/goshimmer   588e0ff             506e4a44db0d        2 days ago          23MB
iotaledger/goshimmer   af1fee9             ffef5d662ba0        6 days ago          23MB
nginx                  latest              e445ab08b2be        2 weeks ago         126MB
golang                 1.12-alpine         6b21b4c6e7a3        4 weeks ago         350MB
alpine                 latest              b7b28af77ffe        4 weeks ago         5.58MB
```
Note that an image consists of a "REPOSITORY" name and a "TAG". Above we have 2 `iotaledger/goshimmer` images. The older can be deleted if no longer in use.

Delete a certain image (or example an older version of goshimmer you don't use anymore):
```sh
docker rmi iotaledger/goshimmer:v0.1
```

### View Docker Containers

View all docker containers:
```sh
docker ps -a
```

### GoShimmer Help Output
Run goshimmer with `--help`: given that we know the image name and the tag. A quick way to get the tag variable configured:
```sh
docker run --rm -it iotaledger/goshimmer:9fda4b8 --help
```

You can get the tag by viewing all images, or check the configuration file to see what is the currently used TAG:

On CentOS:
```sh
grep ^TAG /etc/sysconfig/goshimmer
```

On Ubuntu/Debian/Raspbian:
```sh
grep ^TAG /etc/default/goshimmer
```

## Configuration

In the file below we can specify the image and tag to use. In addition we can configure which command line arguments to pass to goshimmer:

* On Ubuntu: `/etc/default/goshimmer`

* On CentOS: `/etc/sysconfig/goshimmer`

## Control GoShimmer

Goshimmer app start:
```sh
systemctl start goshimmer
```
You can also replace `start` with `stop` or `restart`.

GoShimmer logs follow:

```sh
journalctl -u goshimmer -e -f
```
### Goshimmer Controller

A GUI utility has been added to help manage some basics like controlling the server, viewing logs, upgrading goshimmer etc.

Run:
```sh
sudo gosc
```

### Update Goshimmer

Once a new version of Goshimmer is released you should get a notification about it when running `gosc`.

Please note that since Goshimmer is still in development phase, you'll most likely have to first stop Goshimmer, delete the existing database and only then proceed to upgrade. Before upgrading via `gosc` please run `sudo systemctl stop goshimmer && sudo rm -rf /var/lib/goshimmer/mainnetdb/*` (will take a moment to execute).

### Goshimmer DB
The database is located in `/var/lib/goshimmer/mainnetdb`

### Goshimmer Dashboard
Goshimmer dashboard is accessible by default via your public IP and port 8081. e.g:

```
https://mydomain.io
```

You can login using the username and password you've selected during the installation.

#### Certificate Security Warning
*NOTE* You can safely ignore the browser's warning about the certificate, as a self-signed one has been generated during the installation.

If you'd like to add a valid HTTPS/TLS certificate use `gosc` to request a certificate for your node. You must have a DNS A record pointing to your node's IP.

### Spam Test
If you've enabled the spammer plugin (e.g. via `gosc`) you can start or stop spamming from the commandline.

No need to open ports, forward ports etc, no need for browser. You can run on the commandline:
```sh
curl "http://localhost:8012/spammer?cmd=start"
```

You can add the parameter "tps=<number>" to specify how many TPS to spam with, for example:
```sh
curl "http://localhost:8012/spammer?cmd=start&tps=100"
```

To stop:
```sh
curl "http://localhost:8012/spammer?cmd=stop"
```

Note that for security reasons the spammer is not made available on the browser by default.

You can enable it on the browser by running:
```
grep -q "^goshimmer_webapi_external_address: 0.0.0.0" /opt/goshimmer-playbook/group_vars/all/z-installer-override.yml || echo "goshimmer_webapi_external_address: 0.0.0.0" >> /opt/goshimmer-playbook/group_vars/all/z-installer-override.yml
```

Then run the following to apply the change:
```sh
cd /opt/goshimmer-playbook && ansible-playbook -i inventory site.yml -v --tags=nginx_role
```

For the browser use https and port 8080. You will also have to login.

# Ports and URLs

Here's a list of ports configured by the playbook by default. External communication for dashboard, webapi grafana etc. goes via nginx that serves as a reverse proxy. Other ports (fpc, gossip and autopeering) are exposed directly on the host.

NAME               | PORT INTERNAL | PORT EXTERNAL | PROTOCOL | PATH          | DESCRIPTION
-------------------|---------------|---------------|----------|---------------|--------------------------
Autopeering        | 14626         | 14626         | UDP      | n/a           | Autopeering
Gossip             | 14666         | 14666         | TCP      | n/a           | Gossip
FPC                | 10895         | 10895         | TCP      | n/a           | FPC
WebAPI             | 8012          | 443           | TCP      | /api          | Web API (e.g. for Wallet)
Dashboard          | 8011          | 443           | TCP      | /dashboard    | Main dashboard
Grafana            | 3000          | 443           | TCP      | /grafana      | Grafana monitoring
Prometheus         | 9090          | 443           | TCP      | /prometheus   | Prometheus metrics
Alertmanager       | 9093          | 443           | TCP      | /alertmanager | Alertmanager for prometheus

All the external ports have been made accessible in the firewall. There is no need to configure the firewall on the node.


## Forward Ports

If you are running the node in an internal network/lan you have to forward at least the following ports from the router to the node:

80/tcp, 443/tcp, 10895/tcp, 14666/tcp, 14626/udp


## Expose WebApi Connection On HTTP

Run the following commands if you want to connect to your node's API without having to go through HTTPS (this is a discouraged practice when goshimmer goes live).

```sh
grep -q "^goshimmer_webapi_internal_address: 0.0.0.0" /opt/goshimmer-playbook/group_vars/all/z-append.yml || echo "goshimmer_webapi_internal_address: 0.0.0.0" >> /opt/goshimmer-playbook/group_vars/all/z-append.yml
```

Then run:
```sh
run-playbook --tags=goshimmer_config_file -e overwrite=yes && ufw allow 8012
```

The node will be accessible via IP or DNS name, e.g.: `http://my-node-ip:8012`


# Connect to Wallet

The wallet connects to the `/api/` path. For example `https://my-node.io/api/`.

Note that by default the `goshimmer-playbook` forces HTTPS connections to the node. The wallet requires a valid HTTPS certificate when HTTPS is used. You can request a certificate for your node via `gosc`. You'll need a DNS pointing to your node's IP.

Alternatively, you can follow [Expose WebApi Connection On HTTP](#expose-webapi-connection-on-http) while goshimmer is still not on mainnet.


## Troubleshooting

If something isn't working as expected, try to gather as much data as possible, as this can help someone who is able to help you finding out the cause of the issue.

If anything is wrong related to Goshimmer, first thing to look at are Goshimmer's logs. See how to get logs in [Control GoShimmer](#control-goshimmer) chapter.

To check if Goshimmers's API port is listening you can use the command to see if any output (use 8011 or 8012 as port number):
```sh
sudo lsof -Pni:8011
```
Note that after restarting Goshimmer it might take some time to see the port available.


### 502 Bad Gateway

If you receive this error when trying to browse to the dashboard then:

* nginx (the webserver/proxy) is working properly
* the back-end to which it is trying to connect isn't working properly (goshimmer).

Nginx takes requests from the web and forwards those internally. For example, `https://my-site.io` tells nginx to connect to Goshimmers's dashboard. If Goshimmer is inactive (crashed? starting up?) then nginx would not be able to forward your requests to it. Make sure that Goshimmer is working properly, e.g. checking logs: see [Control GoShimmer](#control-goshimmer). Note that when checking the logs, start from the bottom of the logs and scroll up to the line where you see the error began.


### Connection not Private

You will probably get this message when trying to connect to the dashboard using your IP address.

Other messages might claim certificate is invalid for the domain.

You can safely proceed (most browsers allow to bypass the warning). If you have a DNS pointing to your node's IP address you can use `gosc` to request a HTTPS certificate. That will allow to connect from browsers or the wallet safely to your node.

### Logs
In the following link you can read more about how to collect logs from your system. Although this documentation is for IRI, the commands are similar (just replace iri with hornet if needed):

https://iri-playbook.readthedocs.io/en/master/troubleshooting.html#troubleshooting


### Rerun Playbook

You can rerun the playbook to fix most issues. Use the tool `gosc`, there's an option to rerun the playbook.

If `gosc` isn't working, try the following command:

```sh
cd /opt/goshimmer-playbook && git pull && ansible-playbook -v site.yml -i inventory -e overwrite=yes
```
This command will reset all configuration files and restart any required services.


# Donations

To create, test and maintain this playbook requires many hours of work and resources. This is done wholeheartedly for the IOTA community.

If you liked this project and would like to leave a donation you can use this IOTA address:

```
iota1qpsszw7jnknct8960t80ffxn2hmx8wrrrw69ca3us6u5kt92c2hhj8s7ccf
```

No IOTA? :star: the project is also a way of saying thank you! :sunglasses:
