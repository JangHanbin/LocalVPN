#!/bin/sh

# check Params count 
if [ ! $# -eq 1 ]; then
	echo "Usage : $PWD/run.sh <NETWORK INTERFACE>"
	exit 1
fi       

export NET_DEV=$1
export TUN_DEV="tun0"
export TUN_IP_ADDR="10.7.0.1"
export RECV_ADDR="10.7.7.7"
export NETMASK="255.255.0.0"
export MAIN_PROCESS="LocalVPN"
export LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
export IPTABLES_RECOVER="$PWD/iptables.recover"

#ingore icmp reply
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all

# init tun interface kernel setting
command "$PWD"/tun_interface_init.sh
# run main process in backround TUN interface made in main process
command "$PWD"/"$MAIN_PROCESS" $NET_DEV $TUN_DEV $TUN_IP_ADDR $NETMASK $LOCAL_IP &

# waiting for main process running
sleep 1

# check main process faild to run
if [ "$?" != "0" ]; then
	echo "Failed to run main process"
	exit 1
fi

# set routing table to forwarding to TUN interface
command ifconfig $TUN_DEV mtu 1350
command "$PWD"/routing_init.sh

if [ "$?" != "0" ]; then
	echo "There was an error terminate main process PID : $!"
	kill -9 "$!"
else 
	sigquit()
	{
		echo "\nsignal QUIT received. Try to terminate main process PID : $!"
		kill -9 "$!"
		command "$IPTABLES_RECOVER"
		rm "$IPTABLES_RECOVER"
		exit 0
	}
	
	sigint()
	{
		echo "\nsignal INT received. Try to terminate main process PID : $!"
		kill -9 "$!"
		command "$IPTABLES_RECOVER"
		rm "$IPTABLES_RECOVER"
		exit 0
	}
	trap "sigquit" QUIT
	trap "sigint" INT

	echo "Main Process Running... PID : $!"
	while /bin/true ; do
		sleep 30
	done
	# recover echo reply
	echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_all
fi



