---
title: "Wireguard AppIndicator"
date: 2019-12-30T20:03:30-05:00
description: "An easy way to manage your Wireguard connection."
tags: ["projects", "wireguard", "gnome-shell", "appindicator"]
draft: false

---

# Wireguard AppIndicator

At the time of writing, December of 2019, there exists no simple to use graphical interface for managing Wireguard connections as far as I'm concerned. To resolve this issue, I wanted to make an AppIndicator with the following capabilities:

- View status of Wireguard interface
- Enable and disable Wireguard interface
- View and copy the IP address of the interface

I also wanted to be able to use this on both Gnome Shell systems and systems with only support for AppIndicators, so the script is able to be used as either a standalone script running in the background or as a Gnome Shell extension. See both releases below:

## Releases

https://git.ranvier.net/decaby7e/wireguard-appindicator

https://extensions.gnome.org/extension/2488/wireguard-appindicator/

