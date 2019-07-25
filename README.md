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


## I just want to run it so that I see the statusscreen!

This is possible, until goshimmer has a webgui or API:

1. Stop any running goshimmer: `systemctl stop goshimmer`

2. Run the following:
```sh
docker rm -f goshimmer ; source /etc/default/goshimmer && docker run --rm -it --name goshimmer --net=host --user=1000 --cap-drop=ALL -v /etc/localtime:/etc/localtime:ro,Z -v /var/lib/goshimmer/mainnetdb:/app/mainnetdb:rw,Z ${SHIMMER_IMAGE}:${TAG}
```

*Okay* a few notes about this:

* 1) `/etc/default/goshimmer` is for ubuntu/debian, use `/etc/sysconfig/goshimmer` for CentOS.
* 2) The `--user=1000` is the uid if user shimmer, you can get it via `id shimmer`. It might be different on your system so adapt to the above command accordingly.
* 3) You might need to add the entry nodes yourself (if differ from default). This can be found in the file mentioned in point 1.

