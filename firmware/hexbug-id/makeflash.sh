#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "usage: makeflash.sh <port>"
    exit
fi

make && avrdude -c arduino -p m328p -b 115200 -P $1 -D -U flash:w:main.hex
