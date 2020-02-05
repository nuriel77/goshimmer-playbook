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
     * [GoShimmer DB](#goshimmer-db)
     * [GoShimmer Dashboard](#goshimmer-dashboard)
     * [Spam Test](#spam-test)
     * [See the statusscreen](#see-the-statusscreen)
   * [Appendix](#appendix)
     * [Install Alongside IRI-Playbook](#install-alongside-iri-playbook)
   * [Donations](#donations)
<!--te-->

## Requirements

Tested on the following operating systems:

* CentOS 7.x, CentOS 8.x
* Ubuntu 16/18.04LTS
* Debian 9.5 and 10
* Raspbian 9.9 and 10 (Tested with Raspberry Pi 4 - 4GB RAM)

Architectures (x86_64, arm/aarch 32 and 64 bit)

## Recommendations

* RAM: At least 1.5GB RAM, as less than this can result in out-of-memory failures.
* x2 CPUs are recommended

## Installation

Run (as root):
```sh
bash <(curl -s https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/master/goshimmer_install.sh)
```

This pulls the installation file from the root of this repository and executes it.

The installation will:

* Install latest GoShimmer and start it up.
* Configure basic security (firewalls) and open all required ports for GoShimmer to operate.
* Install nginx as a reverse proxy to access GoShimmer's Dashboard, spammer, etc.
* Add some helpful tools, e.g.: `gosc`

### For Development

If you are working on a fork in a feature branch or happen to directly contribute to this repository you can run the installer pointing it to the appropriate branch, e.g.:
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

Make sure you are root (`sudo su`) and run:
```sh
gosc
```

### Goshimmer DB
The database is located in `/var/lib/goshimmer/mainnetdb`


### Goshimmer Dashboard
Goshimmer dashboard is accessible by default via your public IP and port 8081. e.g:

```
https://mydomain.io:8081
```

You can login using the username and password you've selected during the installation.

### Tangle Visualiser
If you've enabled the graph plugin (e.g. via `gosc`) you can point your browser to your node's public IP (or domain-name) and port 8082, e.g.:

```
https://mydomain.io:8082
```

You can login using the username and password you've selected during the installation.

#### Certificate Security Warning
*NOTE* You can safely ignore the browser's warning about the certificate, as a self-signed one has been generated during the installation.

### Spam Test
If you've enabled the spammer plugin (e.g. via `gosc`) you can start or stop spamming from the commandline.

No need to open ports, forward ports etc, no need for browser. You can run on the commandline:
```sh
curl "http://localhost:18080/spammer?cmd=start"
```

You can add the parameter "tps=<number>" to specify how many TPS to spam with, for example:
```sh
curl "http://localhost:18080/spammer?cmd=start&tps=100"
```

To stop:
```sh
curl "http://localhost:18080/spammer?cmd=stop"
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

# Appendix

## Install Alongside IRI-Playbook

It is possible to run this installation on an IRI-playbook node. You must have enough RAM and CPU power to accommodate both.

A few notes:

* This has only been tested in the case where you already have a Dockerized IRI-playbook node and run this installer afterwards.
* GoShimmer-playbook re-uses IRI's HTTPS configuration (SSL certificate)
* You will also be able to access the web services using the user you have configured for IRI

# Donations

To create, test and maintain this playbook requires many hours of work and resources. This is done wholeheartedly for the IOTA community.

If you liked this project and would like to leave a donation you can use this IOTA address:

```
JFYIHZQOPCRSLKIYHTWRSIR9RZELTZKHNZFHGWXAPCQIEBNJSZFIWMSBGAPDKZZGFNTAHBLGNPRRQIZHDFNPQPPWGC
```

No IOTA? :star: the project is also a way of saying thank you! :sunglasses:
