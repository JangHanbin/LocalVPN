#!/bin/sh


IP_FORWARD_PATH=/proc/sys/net/ipv4/ip_forward

if [ ! -e $IP_FORWARD_PATH ]; then 
	echo 1 > $IP_FORWARD_PATH
else
	IS_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
	if [ $IS_FORWARD==0 ]; then
		echo 1 > $IP_FORWARD_PATH
	fi
fi
ip route add 10.7.0.0/16 via $TUN_IP_ADDR dev $TUN_DEV

if [ "$?" != "0" ]; then
	echo "There was an err to set routing table. retrying after 1 sec later.."
	sleep 1
	ip route add 10.7.0.0/16 via $TUN_IP_ADDR dev $TUN_DEV
fi

if [ "$?" != "0" ]; then
	echo "Failed to set routing table"
	exit 1
fi

iptables -t nat -A POSTROUTING -s 10.7.0.0/16 -o $NET_DEV -j MASQUERADE
#iptables -t nat -A PREROUTING -p icmp --icmp-type host-unreachable -d $LOCAL_IP -j DNAT --to-destination $RECV_ADDR
iptables -t nat -A PREROUTING -p icmp -d $LOCAL_IP -j DNAT --to-destination $RECV_ADDR 
echo "iptables -t nat -D POSTROUTING -s 10.7.0.0/16 -o $NET_DEV -j MASQUERADE" >> iptables.recover
echo "iptables -t nat -D PREROUTING -p icmp -d $LOCAL_IP -j DNAT --to-destination $RECV_ADDR" >> iptables.recover
chmod +x iptables.recover
