# Printnode Print Server Image

## Overview
Docker image including CUPS print server, printing drivers and Printnode client to print from web application directly to printers.

## Run the print server
```yaml
version: "3"
services:
    printnode:
        image: butopea/printnode-docker
        restart: unless-stopped
        ports:
            - "631:631"
            - "8888:8888"
        devices:
            - /dev/bus/usb:/dev/bus/usb
        environment:
            - CUPSADMIN=print
            - CUPSPASSWORD=print
            - PRINT_CLIENT_EMAIL=print@print.de
            - PRINT_CLIENT_PASSWORD=printprint
            - TZ="Europe/Budapest"
        volumes:
            - <persistent-config-path>:/etc/cups
            - <persistent-config-path-printnode>: /root/.printnode/printnode
```

### Parameters and defaults
- `cmd`: by default it starts printnode with following options `--computer-name $PRINTNODE_HOSTNAME --headless --web-interface --use-enviroment-variables`. Add cmd `/usr/local/PrintNode/PrintNode --your-options` to add more but keep the default ones within command to be functional
- `ports`: default cups network port `631:631`. Recommended to change if host has alreacy another cups server running. `8888` is the webinterface for Printnode
- `devices`: used to give docker access to USB printer or scales. Default recommendation is to pass the whole USB bus `/dev/bus/usb`, in case you change the USB port on your device later. change to specific USB port if it will always be fixed, for eg. `/dev/bus/usb/001/005`. Need to check for USB weighting scales
- `volume` -> adds a persistent volume for CUPS config files  and Printnode config files if you need to migrate or start a new container with the same settings. You can also mount your own cupsd.conf file or printnode config file this way.

Environment variables that can be changed to suit your needs

| Parameter    			| Default            | Type   | Description                       |
| --------------------- | ------------------ | ------ | --------------------------------- |
| TZ           			| "Europe/Budapest" |  string | Time zone of your server          |
| CUPSADMIN    			| print              | string | Name of admin user for server 	  |
| CUPSPASSWORD    		| print              | string | Password of admin user for server |
| PRINT_CLIENT_EMAIL 	|      		 		 | string | Email of Printnode account        |
| PRINT_CLIENT_PASSWORD |       		 	 | string | Password of Printnode account     |
| PRINTNODE_HOSTNAME    | docker             | string | Name of node for identification   |

## Add printers to the Cups server
1. Connect to the Cups server at [http://127.0.0.1:631](http://127.0.0.1:631) (or the port you have exposed)
2. Add printers: Administration > Printers > Add USB printers or remote network printer
3. It will be automatically picked up by Printnode

__Note__: The admin user/password for the Cups server is by default `print`/`print`. Can be customized via env vars.

## Add USB weighing scales to Printnode

> [!CAUTION]
> WIP. Haven't tested it myself yet. Serial interface scales are currently not supported.

First, check out if [your scale is supported](https://www.printnode.com/en/docs/supported-scales) by Printnode.

This client accesses USB devices via Linux's "hidraw" subsystem. On the Linux distros
PrintNode has tested the Client on, the default permissions for hidraw devices are 0x600,
i.e. access to USB HID scales is for root users only.

You can check the permissions currently assigned to HID devices on a system as follows:

`ls -al /dev/hid*`

Access to USB scales or other hidraw devices as an unprivileged user is controlled with
udev rules which can whitelist some or all devices.

The included executable "udev-rule-generator" can generate udev rules specifically
for your system and connected devices. In addition to this if you run "udev-rule-generator"
as the root user it will also write the rules file to the correct location and apply
the changes. "udev-rule-generator" is safe to run multiple times. You should run 
"udev-rule-generator" the first time you plug a new USB scale into a computer.

Using "udev-rule-generator" is the easiest way to create and manage udev rules.

`sudo ./udev-rule-generator`

If you choose to create udev rules manually. The following links may be helpful.

- https://github.com/signal11/hidapi/blob/master/udev/99-hid.rules
- http://www.reactivated.net/writing_udev_rules.html

To whitelist all USB hidraw devices for all users, add the following text to
/etc/udev/rules.d/10-scales.rules:

`KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666"`

## Credits

Inspiration has been drawn from [anujdatar/cups-docker](https://github.com/anujdatar/cups-docker) and [olbat/cupsd](https://github.com/olbat/dockerfiles/tree/master/cupsd)
