---
title: "Home Surveilance System"
date: 2019-12-25T22:41:49-05:00
description: ""
tags: ["self-hosted", "projects"]
draft: false
---

![Motioneye Logo](/img/camera-hacker.jpeg)

# Introduction

Depending on where you live in the US, your area can either be considered very nice or appealing to drug addicts. In my case, the latter is more true than the former unfortunately. However, there is one thing that can help to prevent this predicament from impacting our lives too much: technology! Network cameras have become incredibly cheap and I have found that this [offbrand IP camera](https://www.amazon.com/gp/product/B073GSSGWB/) has done a great job thus far. Additionally, I have tons of computer and networking equipment laying around the house collecting dust so a project like this allows me to put these things to use rather than just letting them rot away.

# Project Architecture

## Technical Concept

Any self-hosted surveilance network, at a fundamental level, must have the following components:

1. Storage - Somewhere for the recorded footage to be stored
2. Cameras - The meat of the operation; how we catch the bad guys
3. Networking - The bones of the operation; how we connect the cameras and the storage together

These components can be fitted together in a variety of ways but I found that the central server architecture was the most viable and easy to implement for me. The diagram below shows a rough concept:

```
{{< image src="/img/Home-Surveilance-Concept.jpg" alt="Camera Network Diagram" position="center" style="border-radius: 6px;" >}}
```

Additionally, I would like for this system to be highly redundant. This means that if the router loses power and comes back on everything should resume working; if the computer restarts for some reason, all cameras should be reconnected at boot and continue recording. If a camera is unplugged and moved somewhere else on the property, it should work and stream to the main computer at all times.

## Software Options

There are many options for self-hosted camera systems, some of which include [Kerberos](https://kerberos.io/) and [Shinobi](https://moeiscool.github.io/Shinobi/). These solutions seem to work nice but I found them a bit bloated and [Motioneye](https://github.com/ccrisan/motioneye/wiki) to be the better solution for a simple setup like what I wanted. Motioneye can even work on SBCs like the Raspberry Pi so that makes it even better for those who would like more low profile solutions. Therefore, I settled with [Motioneye](https://github.com/ccrisan/motioneye/wiki) as my camera management and video recording software.

If you know me, you would see this coming: **Docker**. I want this entire system to be as modular as possible, so Docker will help in making the software as modular as possible as well. Thankfully, Ccrisan, the author of Motioneye, has provided a Docker image for this already, so we can make a simple docker-compose like so:

```yaml
---
version: "3.5"
services:
  motioneye:
    image: ccrisan/motioneye:master-amd64  # Change to ccrisan/motioneye:master-armhf for ARM chips ($
    ports:
      - "80:8765"
    volumes:
      - /MOTION_CONFIGURATION_DIRECTORY/Motion/:/etc/motioneye
      - /RECORDINGS_DIRECTORY/CameraRecordings:/var/lib/motioneye
      - /etc/localtime:/etc/localtime:ro
```

Perfect! Add a start script for this compose file in /etc/rc.local and we're good to go :)

## Hardware Materials

For hardware, I had many peices already avaliable to me, such as the main computer for recording and camera management, the router for networking, ethernet cables, power cables, etc... However, what I did not have was a camera. I looked around for a bit on Amazon and settled for this [offbrand IP camera](https://www.amazon.com/gp/product/B073GSSGWB/) as a nice starting point. Additionally, because the computer and first camera were going to be detached from the house, I wanted to extend the WiFi network from this remote area into our house should I need to manage the computer remotely or add cameras on the main house without the need for cabling. I got a great deal on this [TLink WiFi extender](https://www.amazon.com/gp/product/B0195Y0A42/) on Amazon for only $15. These two components I was missing added up to a cool ~$60 price tag in total.

## Implementation

Once all of the hardware and software has been gathered and preped for frankenstining, we can start building our system!

### Computer 

I installed Ubuntu Server 18.04.3 onto the Dell computer and also put in a 1TB drive I had lying around that was in good health. Additionally, I installed some extra DDR2 RAM to give it 8GB of RAM total. N i c e. A quick install of openssh-server and docker.io made this machine ready to accept my docker-compose file and I also configured it with a static IP address in Netplan. Once that was setup I moved on to the camera...

### Camera

The camera wasn't too bad to connect to the WiFi network but finding the link for the video stream URL was a bit trickier. After some digging, I found the RTSP URL of my camera to be `rtsp://CAMERA_IP/11`. Why there is an 11 appended to the end is beside me, so please feel free to let me know if you know why they chose that URL...

### Access Point

The access point I used was an old Netgear router I've had laying around for years. Even at almost 10 years old, this thing beats the shit out of any Uverse router (they're absolutely abysmal). I simply put a strong password on it and set DHCP to only give out addresses between 10.0.0.99 and 10.0.0.255 so that the others could be saved for cameras and computers that were statically configured.

### Edge Computer

Because I didn't want to have to connect to my private camera network every time I wanted to view the recordings or live footage, I chose to create an edge computer that would be connected to both the private camera network and my home network. This *may* not be the best idea... but that's okay! ( Until it's not :| ). This computer was simply a Rasberry Pi that ran a [Caddy V1 proxy](https://caddyserver.com/) providing HTTPS access to the web interface from both inside the house and away from the house.

# Conclusion

Like magic, when everything was reset for the first time, it just worked (TM)! Sadly this was not the case, but it didn't put up too much of a fight once some debugging was done the system began to work just fine. The first issue I encountered was with the motion detection that is included with Motioneye. Unfortunately, due to the positioning of my camera, there was always some kind of motion in the shot due to cars, wind, dogs, people, etc., even with masks applied generously. Therefore, I abandonded trying to make it motion activated and instead elected to record 24/7 for 3 day intervals. This still crept up on 400GB :'( but it was better than nothing. I think I would like to possible reduce the video quality and framerate in the future to cut back on this massive disk usage as well as to make streaming video to the web interface more smooth and downloads from the computer to the house faster. All in all, I am satisfied with the outcome and the modularity of it. If you have any suggestions for improvements or notice any errors I may have made, feel free to leave a comment or reach out to me at my email. Thank you for reading!

# References

## Software

[Motioneye](https://github.com/ccrisan/motioneye/wiki)

[Kerberos](https://kerberos.io/)

[Shinobi](https://moeiscool.github.io/Shinobi/)

[Caddy V1 proxy](https://caddyserver.com/)

## Hardware

[SV3C IP Camera](https://www.amazon.com/gp/product/B073GSSGWB/)

[TLink WiFi extender](https://www.amazon.com/gp/product/B0195Y0A42/)