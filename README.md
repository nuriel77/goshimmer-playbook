# GoShimmer Playbook

## Requirements

Supported operating systems:

* CentOS 7
* Ubuntu 16/18.04LTS
* Debian 9.5

## Recommendations

* RAM: At least 1.5GB RAM, as less than this can result in out-of-memory failures.
* x2 CPUs are recommended

## Install

Run:
```sh
bash <(curl -s https://raw.githubusercontent.com/nuriel77/goshimmer-playbook/master/fullnode_install.sh)
```

This pulls the installation file from the root of this repository and executes it.


## Some Docker Commands

View all existing images:
```sh
docker images
```

View all running docker containers:
```sh
docker ps -a
```

Run goshimmer with `--help`: given that we know the image name and the tag:
```sh
docker run --rm -it iotaledger/goshimmer:9fda4b8 --help
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

## Goshimmer DB
The database is located in `/var/lib/goshimmer/mainnetdb`

