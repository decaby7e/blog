---
title: "Wireguard Management System - Concept Introduction"
date: 2019-12-28T23:49:20-05:00
description: "See how I approached the problem of conveinently managing Wireguard configuration files..."
tags: ["projects", "wireguard", "bash"]
draft: false
---

# Introduction

Wireguard is a beautiful thing :sob:. But one thing that I have found to be a point of contention is the lack of a simple interface for managing an existing Wireguard server. From some light browsing, I have found a couple of solutions that are mainly geared towards enterprise use or paid services but no simple FOSS CLI alternatives. Therefore, I feel that it would be nice to have a simple Bash script or Python script to accomplish this task. I'll keep it short and just share my early development notes below:

---

## To-Do

### Features

- [ ] Add ability to append individual users to an existing configuration hierarchy

### Enhancements

- [ ] Add a web interface
- [ ] Add address collision detection while reading server.conf

---

## Development Notes

- Scripts should be used on a per server basis; one set of scripts manages one set of servers
- Scripts should be stateless; can be used regardless of current server configuration
  - According to this logic, there should be some static file set somewhere detailing current server structure. Let this be called `server.conf`

#### Example servers.conf

```ini
[wg0]
# Path to the server configuration file
server_conf=/etc/wireguard/neuron/wg0.conf

# Public key of the server
server_pubkey=U29TZWN1cmVNdWNoV293ISEhcXdlcnR5MTIzNA==

# Where will we store client configuration files?
clients_directory=/etc/wireguard/neuron/clients

[wg#]
# ...
```

- This file will, by default, be loaded from the current running directory of the script. However, a new config can be specified by using the `-c` parameter.
- This script should be able to leave the existing configuration alone and only append its additions to its own section in the server.conf file. See example below:

```ini
# Normal typical server configuration
[Interface]
Address = 192.168.5.1/24
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 42387
PrivateKey = iMa3i2nmks1A3j2kn3VaRWuIto23DFasxk4=

# Peer name
[Peer]
PublicKey = FS/HMHIMrihc+37tVR816pjh2WcoNg4cqgeGGhC8SyM=
AllowedIPs = 192.168.5.2

# ...
```

```ini
# Server configuration *with* wg-man entries
[Interface]
Address = 192.168.5.1/24
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 42387
PrivateKey = iMa3i2nmks1A3j2kn3VaRWuIto23DFasxk4=

# Peer name
# Random custom comments
[Peer]
PublicKey = FS/HMHIMrihc+37tVR816pjh2WcoNg4cqgeGGhC8SyM=
AllowedIPs = 192.168.5.2

####################
## WG-MAN ENTRIES ##
####################

# Example_Client_Name
NOTE ANNOTATION - The items below are to be used by wg-man as client properties
# Date Added: 2019.01.05
[Peer]
PublicKey = FS/HMHIMrihc+37tVR816pjh2WcoNg4cqgeGGhC8SyM=
AllowedIPs = 192.168.5.3
```

- Method for adding strings after expressions:

  ```bash
  sed -i '/## WG-MAN ENTRIES ##/a CLIENT_STRING_HERE' ./server.conf
  ```

- wg-man should also be able to initialize new server configurations. This is where the two use cases of the script appear:
	1. Management mode - Used to add and remove clients from an existing wireguard configuration file
	2. Tool mode - Used to wrap many common procedures that may be used in a Wireguard configuration collection, e.g:
		1. Generating server configurations
		2. Generating client configurations to be outputted directly to tty as text or as a file
		3. Convert wireguard client configs to QR codes

### Script Structure

1. wg-man - Master management script. Other scripts will be used inside this one but ultimately this _should_ be the only thing the user has to use
2. scripts/ - Additional scripts used with **wg-man** that supplement it.
3. ./servers.conf

#### Server command usage

| *        | Required parameter            |
| -------- | ----------------------------- |
| **(-x)** | **Synonym to long parameter** |

```bash
# Parameters

## Specifying configuration file
wg-man ... # With configuration file in working directory
wg-man --config (-c) /path/to/config/file.conf ...

# Subcommands

## Description: Initialize a new server and add entry to servers.conf
## Parameters:
## --interface (-i)*:   Name of interface
## --name (-n):         Name of server		    (Default: Random UUID)
## --ip (-a):           IP of server            (Default: 192.168.1.1)
## --privkey (-k):      Private key of server   (Default: Generated from wg)
wg-man init --name "Server_Nickname"

## Description: Add clients (existing or not) to a server configuration
## Parameters:
## --ip (-a)*:     IP of client
## --cat (-l):     Display client entry
## --name (-n):    Name of client         (Default: Random UUID)
## --pubkey (-k):  Public key of client   (Default: Generated from wg)
wg-man add --name "Client_Nickname" --ip  "192.168.5.2" --pubkey "EQWEF234fbi234bfawSEFqi3jh4bFq==" --cat

## Description: Create a client configuration for a server configuration and add them to the server configuration
## Parameters:
## --ip (-a)*:     IP of client
## --cat (-l):     Display client entry
## --name (-n):    Name of client         (Default: Random UUID)
wg-man create --name "Client_Nickname" --ip "192.168.5.65"
```

###### \* Making this beautiful spec is making me want to do this proper and not just make it a bash script lol

