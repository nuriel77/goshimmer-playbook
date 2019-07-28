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


## Spam Test

No need to open ports, forward ports etc, no need for browser. You can run on the commandline:
```sh
curl http://localhost:8080/spammer?cmd=start
```
You can add the parameter "tps=<number>" to specify how many TPS to spam with, for example:
```sh
curl http://localhost:8080/spammer?cmd=start&tps=100
```


To stop:
```sh
curl http://localhost:8080/spammer?cmd=stop
```

Although it is not recommeneded to open port 8080 on the server, should you choose to do so in order to be able to initiate spam remotely, you can run:
```sh
sudo ufw allow 8080
```
or, on CentOS:
```sh
firewall-cmd --allow-port=8080/tcp --permanent && firewall-cmd --reload
```

In the future this playbook might include a user/password lock (via nginx) on this port so that it is more protected. This really depends on the next steps with goshimmer, as it would be a shame to add this functionality now if things are to change completely.

## I just want to run it so that I see the statusscreen!

Since Saturday, July 27 a new script has been added to help run goshimmer with the status screen. If you already have the playbook installed, don't worry, you can run the initial installation command to get the script ready!

To activate the screen run:
```sh
sudo run-screen
```

Use CTRL-c to exit.

If you want to leave the server running with this screen you need to run it within what is called a `screen` session.

Please refer to this article on how to use `screen` (you might need to install it): https://linuxize.com/post/how-to-use-linux-screen/

# Donations

If you liked this playbook, and would like to leave a donation you can use this IOTA address:
```
JFYIHZQOPCRSLKIYHTWRSIR9RZELTZKHNZFHGWXAPCQIEBNJSZFIWMSBGAPDKZZGFNTAHBLGNPRRQIZHDFNPQPPWGC
```
