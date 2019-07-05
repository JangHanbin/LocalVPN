#!/bin/sh
if [ ! -d "/dev/net" ]; then
	mkdir /dev/net

fi

if [ ! -c "/dev/net/tun" ]; then
	#if there is no tun interface char dev file
	mknod /dev/net/tun c 10 200
	chmod 0666 /dev/net/tun
fi
