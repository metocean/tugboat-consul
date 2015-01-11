# Tugboat Consul

Connect Docker to Consul using tugboat.

This tool creates a directory inside Consul that can be used to start and stop groups of Docker containers. The daemon watches the Consul key value store for changes and adjusts the running Docker containers as entries are created and deleted.

![Hosts](ss_hosts.png?raw=true)
![Groups](ss_groups.png?raw=true)


# Installation

```sh
npm install -g tugboat-consul
```

This will install the `tugboat-consul` command line daemon.


# Configuration

`tugboat-consul` will use the current hostname and attempt to connect to a local Consul agent. These can be overriden using the `TUGBOAT_HOST` and `CONSUL_HOST` environment variables.

The daemon expects to be run inside a directory of `.yml` files in the normal tugboat format. See the [tugboat documentation](https://github.com/metocean/tugboat) for details.


# Docker Container

A docker container has been provided that bundles Consul 1.4 and Tugboat Consul. Check out tugboat.yml and the examples folder for configuration.

The image will be available on the docker hub as `metocean/tugboat` soon.