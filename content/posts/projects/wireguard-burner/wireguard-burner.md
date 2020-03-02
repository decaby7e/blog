---
title: "Wireguard Burner VPN"
date: 2019-11-30T04:38:51Z
description: ""
tags: []
categories: []
draft: false
---

![Wireguard Burner](/img/wg-burner.png)

# Introduction

Have you ever gone to the conveinence store and bought a disposable phone as a kid? Maybe not, but I was always fascinated by those kinds of things and I did that!
I thought that the idea of having a burner phone was interesting because it was another way to detach your name from whatever communication medium you were using. Nowadays anytime you communicate your name is always tied with that message. Even if you decide to spin up a VPN on a VPS provider like AWS, Digital Ocean, etc. your name is still tied to whatever payment method you use! Even when you get a VPN up and running on a VPS or a personal computer somewhere, that IP is then tied to whatever actions you perform on the internet. So even though you've gone through all the trouble of attempting to hide your **real** IP, you've effectively made yourself another **real** IP 😑.
If you choose to go with a VPN provider like Private Internet Access or NordVPN, you can circumvent this issue but now you have to worry about *them* taking your information instead of the ISP doing it. What to do...
I figured that the most practical approach to this situation was to look back to those simpler times where you could go to the store and buy a disposable communication medium. What if we could apply this concept to a VPN...?

In this project, I aim to create a "burner" VPN hosted on Digital Ocean. This involves creating script(s) that will do the following:

&nbsp;

1. Create a Droplet and upload a private SSH key that can be disposed of once done with it.

2. Install the necessary software for hosting a VPN server and other useful utilities.

3. Serve up the client configuration in a user friendly manner for quick and easy connection to the server.

4. Start up the VPN server and begin traffic forwarding.

5. Once the user decides they want to nuke their server, hit a button and make it disappear.

&nbsp;

Sounds simple enough (and it mostly is) so lets get into it!

___

# Working with the Digital Ocean API

## Defining Project Secrets
Before we can even begin to work with our Droplet we need to define some common authorization variables that will be used for the duration of the project. To interact with the Digital Ocean API we need to generate an API token from our user dashboard. Additionally, we need to have an SSH key to be able to connect to our Droplet once it is created. I created a JSON object to hold all of this information and a template for this object is below:

```json
{
    "user_token": "DIGITAL OCEAN API TOKEN STRING",
    "ssh_fingerprint": "SSH KEY FINGERPRINT STRING",
    "ssh_pubkey": "SSH PUBLIC KEY STRING",
    "ssh_privkey": "NAME OF SSH PRIVATE KEY FILE"
}
```

Once we have our secrets.json file defined, we can move on to the next step: creating and interacting with our Droplet.

## Creating a Droplet object
In order to keep things nice and tidy, it would be nice to create an object that represents our Droplet rather than attempting to integrate this into the main script. Additionally, we can reuse this object in future projects and add onto it if we'd like to. The basic Droplet object that was created for this project is shown below:
```python
#!/usr/bin/python3

import json
import requests
import os
import time

class Droplet:
    def __init__(self, token, name, region, ssh_key_fingerprint):
        self.api_url_base = 'https://api.digitalocean.com/v2/'
        self.status = 'destroyed'
        
        self.token = token
        self.name = name
        self.region = region

        self.privkey = 'privkey'
        self.ssh_key_fingerprint = ssh_key_fingerprint
        
        self.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer {0}'.format(self.token)
        }

    #Creates a new Droplet with the given information
    def create(self):
        # Create a new Droplet with object information
        active_url = '{0}droplets'.format(self.api_url_base)
        data = json.dumps({
            "name": "{0}".format(self.name),
            "region": "{0}".format(self.region),
            "size": "s-1vcpu-1gb",
            "image": "ubuntu-18-04-x64",
            "ssh_keys": ["{0}".format(self.ssh_key_fingerprint)],
            "backups": False,
            "ipv6": False,
            "user_data": None,
            "private_networking": None,
            "volumes": None,
            "tags": None})
        response = requests.post(active_url, headers=self.headers, data=data)
        

        if response:
            new_droplet = response.json()
            self.id = new_droplet["droplet"]["id"]
            self.status = 'created'

            print( 'Droplet {0} created.'.format(self.id) )
        else:
            print( 'Error: {0}'.format(response.json()['message']) )
            return False


        # Give some time between creation and getting the full Droplet information
        time.sleep(2)


        # Get the full Droplet JSON
        active_url='{0}droplets/{1}'.format(self.api_url_base, self.id)
        response = requests.get(active_url, headers=self.headers)
        
        if response:
            self.droplet_JSON = response.json()
            self.ip = self.droplet_JSON["droplet"]["networks"]["v4"][0]["ip_address"]
            print ( 'Droplet IP: {0}'.format(self.ip) )
            return True
        else:
            return False

    #Destroys the Droplet
    def destroy(self):
        if(self.status == 'created'):
            active_url = '{0}droplets/{1}'.format(self.api_url_base, self.id)
            requests.delete(active_url, headers=self.headers)

            print( 'Droplet {0} destroyed.'.format(self.id) )

            self.status = 'destroyed'
            self.id = None
            self.ip = None
            self.droplet_JSON = None

            return True
        
        else:
            return False

    #Runs a command in the Droplet given a command and a private key
    def run(self, command_string):
        if self.status == 'created':
            ssh_prefix='ssh -o StrictHostKeyChecking=no -i {0} root@{1}'.format(self.privkey, self.ip)
            cmd='{0} \' {1} \''.format(ssh_prefix, command_string)
            return os.system(cmd)
        
        else:
            return None
```

With this, we can create and destroy a new Droplet as well as execute commands on it. The final step of this project is to create a script that uses this object to create and destroy a burner VPN.

## Burner VPN Script

The final script of this project involves implementing the Droplet object that we just created to create and destroy our burner VPN. Wireguard was chosen for this project for several reasons, the most important of which are because of its speed and simplicity in configuration. The finished script is below:

```python
#!/usr/bin/python3

from Droplet import Droplet

import json
import requests

import uuid

import os
import time
from random import randint

api_url_base = 'https://api.digitalocean.com/v2/'

## Methods ##

def add_ssh_key(token, name, pubkey):
  curr_url = '{0}account/keys'.format(api_url_base)

  headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer {0}'.format(token)
        }

  data = json.dumps(
    {
      "name": "{0}".format(name),
      "public_key": "{0}".format(pubkey)
    }
  )

  requests.post(curr_url, data=data, headers=headers)

def del_ssh_key(token, fingerprint):
  curr_url = '{0}account/keys/{1}'.format(api_url_base, fingerprint)

  headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer {0}'.format(token)
          }

  requests.delete(curr_url, headers=headers)

def init_wg(droplet):
  droplet.run('apt update && add-apt-repository ppa:wireguard/wireguard && apt install -y wireguard git python qrencode')

  droplet.run('git clone https://github.com/decaby7e/wireguard-management')

  droplet.run('wireguard-management/generate-wg-configs.sh -i {0}; cp configs/server/wg0.conf /etc/wireguard/'.format(droplet.ip))

  # INSECURE: Exposes client and server private keys
  # print("DEBUG: Serving up client configs...") #DEBUG
  # listen_port = randint(20000, 50000)
  # print('Visit {0}:{1} for configuration files.'.format(droplet.ip, listen_port))
  # print('Press ctrl-c when finished.')
  # cmd = 'python -m SimpleHTTPServer {0}'.format(listen_port)
  # droplet.run(cmd)

  droplet.run('qrencode -t ansiutf8 < configs/client-2/wg2.conf')
  input('> Press enter when done.')

  droplet.run('sysctl -w net.ipv4.ip_forward=1')

  droplet.run('wg-quick up wg0')

## Main ##

def main():
  global droplet

  secrets = json.load(open('secrets.json', 'r'))
  token=secrets['user_token']
  droplet = Droplet(token, str(uuid.uuid1()), 'nyc3', secrets['ssh_fingerprint'])

  print("> Adding SSH key...")
  add_ssh_key(token, droplet.name, secrets['ssh_pubkey'])

  print("> Creating Droplet...")
  droplet.create()

  server_online = False
  print("> Waiting for server to come online...")
  while not server_online:
    if(droplet.run('echo Connection Established') == 0):
      server_online = True

  print("> Starting Instance...")
  init_wg(droplet)
  
  input("Press any key to nuke instance. (DISABLE VPN ON CLINET BEFORE NUKING)")
  
  print("> Removing Droplet...")
  droplet.destroy()
  
  print("> Removing SSH key...")
  del_ssh_key(token, secrets['ssh_fingerprint'])

if __name__ == '__main__':
  try:
    main()
  except Exception as e:
    print('Error: {0}'.format(e))
    print('Error: Exception caught. Cleaning up...')
    droplet.destroy()
```

Another project that I worked on is implemented in this script, where it is used to generate server and client configurations for Wireguard. This project can be found here: [Wireguard Management Scripts](/posts/projects/wireguard-management)

## Setup

Here is a brief video that shows the entire setup process:

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
  <iframe src="/vid/wg-burner-tutorial.webm" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border:0;" allowfullscreen title="Wireguard Burner Setup"></iframe>
</div>

___

# Conclusion

So it isnt' exactly the same as the burner phones that I played with as a kid, but I think that what I have here will do a pretty good job at being close :p

This project was a ton of fun to work on, even if it was during time that might've been better for studying or sleep lol. There are many improvements that I can see being implemented in the future:

- Migrate the SSH key management to its own object / script / the existing Droplet object
- Create a new object that manages just the Digital Ocean account for things like SSH keys, authorization for API calls, etc.

If you have any reccomendations or questions about this project, feel free to let me know about them at my [email](mailto:jack.polk314@gmail.com).

___

## Authors Notes

+ I do recognize that when you create a Digital Ocean account your name and relevant information is tied to it. However, when there's a will there's a way: one way to circumvent this is to use *cough* disposable *cough* personal information tied to a disposable gift card. I don't know if this complies with Digital Ocean's policies and I don't care enough to find out. Therefore, I do not endorse doing this and if you choose to do so it is at your complete risk.

## Sources

- [Digital Ocean API Documentation](https://developers.digitalocean.com/documentation/v2/)
- [Dragon used in post logo](https://www.pngfind.com/mpng/ihwowoT_d-d-logo-png-dungeons-dragons-transparent-png/)
- [Digital Ocean logo](https://en.wikipedia.org/wiki/DigitalOcean#/media/File:DigitalOcean_logo.svg)
