# Docker container for FreeFileSync
[![Release](https://img.shields.io/github/release/jlesage/docker-freefilesync.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-freefilesync/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/freefilesync/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/freefilesync/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/freefilesync?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/freefilesync)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/freefilesync?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/freefilesync)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-freefilesync/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-freefilesync/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-freefilesync)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [FreeFileSync](https://freefilesync.org).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

---

[![FreeFileSync logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/freefilesync-icon.png&w=110)](https://freefilesync.org)[![FreeFileSync](https://images.placeholders.dev/?width=384&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=FreeFileSync&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://freefilesync.org)

FreeFileSync is a folder comparison and synchronization software that
creates and manages backup copies of all your important files. Instead
of copying every file every time, FreeFileSync determines the differences
between a source and a target folder and transfers only the minimum amount
of data needed.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the FreeFileSync docker container with the following command:
```shell
docker run -d \
    --name=freefilesync \
    -p 5800:5800 \
    -v /docker/appdata/freefilesync:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/freefilesync
```

Where:
  - `/docker/appdata/freefilesync`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `/home/user`: This location contains files from your host that need to be accessible to the application.

Browse to `http://your-host-ip:5800` to access the FreeFileSync GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-freefilesync.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-freefilesync/issues
