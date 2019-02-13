# Auto-Consul
[![Awesome](https://img.shields.io/badge/Auto_Linux-Consul-green.svg)]()

The project help installing consul more easily

## Dependency
  + `consul_1.4.1_linux_amd64`

## Installation
#### #. Clone
Clone or copy the repository to the target machine


### Client
#### #. install client
  ```sh
    ./client-install.sh
  ```

#### #. start client
  ```sh
    ./client.sh start-client
  ```

### Server
#### #. install server
  ```sh
    mv bin/consul /usr/local/bin/
  ```

#### #. systemctl config
  ```sh
    useradd consul

    ln -s consul.d/server /etc/consul.d

    cp server/systemd/consul /etc/sysconfig/consul
    cp server/systemd/consul.service /etc/systemd/system/consul.service

    mkdir /run/consul && chown consul:consul /run/consul
  ```

#### #. start server
  ```sh
    # systemctl status consul.service
    systemctl start consul.service
  ```
