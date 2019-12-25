# GoShimmer Playbook

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
     * [GoShimmer Web](#goshimmer-web)
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
* Add some helpful tools, e.g.: `gosc` and `run-screen` (read below).

### For Development

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
docker rmi iotaledger/goshimmer:af1fee9
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


### Goshimmer Web
Since August 3rd 2019 nginx has been added to serve as a reverse proxy for some of goshimmer's common services.

#### Check if new UI is enabled
Make sure that the plugins are configured in `/etc/default/goshimmer` (or `/etc/sysconfig/goshimmer` in CentOS). Under the OPTIONS option you should see something like `--node.enablePlugins 'dashboard spammer ui'`. If you are missing `ui`, simply add it and restart goshimmer.

#### Access new UI
New full-feature dashboard UI is accessible via the web-browser on port 18081, e.g.: `https://your-ip:18080/ui`.

#### Old Dashboard
Older dashboard is accessible via the web-browser on port 18081, e.g.: `https://your-ip:18081/dashboard`

#### Certificate Security Warning
*NOTE* You can safely ignore the browser's warning about the certificate, as a self-signed one has been generated during the installation.

### Spam Test
If not via the above Web/UI, you can use the command line.
No need to open ports, forward ports etc, no need for browser. You can run on the commandline:
```sh
curl "http://localhost:8080/spammer?cmd=start"
```
You can add the parameter "tps=<number>" to specify how many TPS to spam with, for example:
```sh
curl "http://localhost:8080/spammer?cmd=start&tps=100"
```


To stop:
```sh
curl "http://localhost:8080/spammer?cmd=stop"
```

## See the statusscreen

Since Saturday, July 27 a new script has been added to help run goshimmer with the status screen. If you already have the playbook installed, don't worry, you can run the initial installation command to get the script ready!

To activate the screen run:
```sh
sudo run-screen
```

Use CTRL-c to exit.

If you want to leave the server running with this screen you need to run it within what is called a `screen` session.

Please refer to this article on how to use `screen` (you might need to install it): https://linuxize.com/post/how-to-use-linux-screen/

## Update the run-screen script or gosc

To update any scripts provided by this playbook simply use `gosc` and select to update gosc and scripts option from the menu.

# Appendix

## Install Alongside IRI-Playbook

It is possible to run this installation on an IRI-playbook node. You must have enough RAM and CPU power to accommodate both.

A few notes:

* This has only been tested in the case where you already have a Dockerized IRI-playbook node and run this installer afterwards.
* GoShimmer-playbook re-uses IRI's HTTPS configuration (SSL certificate)
* You will also be able to access the web services using the user you have configured for IRI

# Donations

If you liked this playbook, and would like to leave a donation you can use this IOTA address:
```
JFYIHZQOPCRSLKIYHTWRSIR9RZELTZKHNZFHGWXAPCQIEBNJSZFIWMSBGAPDKZZGFNTAHBLGNPRRQIZHDFNPQPPWGC
```
