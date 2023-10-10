# Ladies First Chicken Door Control

This is a small webservice for controlling the [ladies first chicken door](https://www.ladiesfirstchickendoor.com/) remotely

* GET http://hostname:3000/api/ladiesfirst/door

returns a status object

```json
{
    "state": "sensor",
    "close_line": 22,
    "close_active": false,
    "open_line": 5,
    "open_active": false
}
```

Open the door:

* POST http://hostname:3000/api/ladiesfirst/door/open
  * accepts: `open`, `close`, `sensor`

## Building image

I have an image at stakach/ladiesfirst that you can use (see docker-compose.yml)

```
docker buildx build --progress=plain --label org.opencontainers.image.title=ladiesfirst --platform linux/arm64 --tag stakach/ladiesfirst:latest --push .
```

### Deploying

Designed to run on a [raspberry pi zero or zero 2 wireless](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/) with a [relay hat](https://thepihut.com/products/zero-relay-2-channel-5v-relay-board-for-pi-zero)

Configuring the pi from scratch:

1. Use the [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
1. configure with Raspberry Pi OS (other) -> Raspberry Pi OS Lite (64bit)
1. log into the OS and update: `sudo apt update && sudo apt install -y`
1. Install docker-compse
   * https://docs.docker.com/engine/install/debian/#install-using-the-repository
   * https://docs.docker.com/engine/install/linux-postinstall/
   * sudo apt install docker-compose
1. git clone https://github.com/stakach/ladies-first-chicken-door
1. cd ladies-first-chicken-door
1. ./setup_gpio.sh
1. docker-compose up -d

Customise docker-compose.yml to match your setup as required. The setup script configures access to the hardware using `udev` so it can be used from within the docker container. The docker image is highly secure by default.

## Documentation

Relay channels 1 and 2 are connected with pin numbers 15 and 29 of the Raspberry Pi GPIO respectively according to the [relay hat details](https://thepihut.com/products/zero-relay-2-channel-5v-relay-board-for-pi-zero)

So given the pinout:

![image](https://github.com/stakach/ladies-first-chicken-door/assets/368013/bed9bc59-0e4f-47cf-abd9-827de9f3b5b2)
[pinout details](https://www.etechnophiles.com/rpi-zero-2w-board-layout-pinout-specs-price/#rpi-zero-2w-gpio-pinout-in-detail)

and given the output from running `gpioinfo` (install via `sudo apt install gpiod libgpiod-dev`) we can determine the lines that the relays run on.

* Relay channel 1 == pin15, GPIO22 (line 22)
* Relay channel 2 == pin29, GPIO5  (line 5)
