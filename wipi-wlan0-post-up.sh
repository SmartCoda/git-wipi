#!/bin/bash
#
# wipi-wlan0-post-up.sh - sets up iptables to pass data across interfaces
#
# wlan0 = broadcasts WiPi
# wlan1 = connects to available wifi
# eth0 = wired network, if available
#
# Author: SmartCoda
#

#
# setup variables
#
WIPI_ROUTER_IN_ETH=eth0
WIPI_ROUTER_IN_WLAN=wlan1
WIPI_ROUTER_OUT=wlan0
WIPI_ROUTER_IN=$WIPI_ROUTER_IN_WLAN
WIPI_ROUTER_ETH_IP=$(/sbin/ifconfig $WIPI_ROUTER_IN_ETH | /bin/grep 'inet addr:' | /usr/bin/cut --delimiter=: --fields=2 | /usr/bin/awk '{ print $1 }')
WIPI_ROUTER_WLAN_IP=$(/sbin/ifconfig $WIPI_ROUTER_IN_WLAN | /bin/grep 'inet addr:' | /usr/bin/cut --delimiter=: --fields=2 | /usr/bin/awk '{ print $1 }')
WIPI=0

#
# main program
#
echo "Starting WiPi Router..."

#
# check existance of IP addresses and add relevant value to WIPI
#
if [ ! -z $WIPI_ROUTER_ETH_IP ]; then
    echo "Ethernet IP: "$WIPI_ROUTER_ETH_IP
    WIPI=$(($WIPI + 1))
fi
if [ ! -z $WIPI_ROUTER_WLAN_IP ]; then
    echo "Wireless IP: "$WIPI_ROUTER_WLAN_IP
    WIPI=$(($WIPI + 2))
fi

#
# select option from WIPI value
#
case $WIPI in
    0 )
	echo "No interfaces available..."
	exit 1
    ;;
    1 )
	echo "Wired connection available..."
	WIPI_ROUTER_IN=$WIPI_ROUTER_IN_ETH
	echo "Using interface: "$WIPI_ROUTER_IN
    ;;
    2 )
 	echo "Wireless connection available..."
 	WIPI_ROUTER_IN=$WIPI_ROUTER_IN_WLAN
 	echo "Using interface: "$WIPI_ROUTER_IN
    ;;
    3 )
 	echo "Wired & wireless connection available..."
 	echo "Running speedtest to determine best connection..."
 	WIPI_ROUTER_SPEED_ETH=$(/home/pi/bin/wipi-speedtest.sh $WIPI_ROUTER_IN_ETH)
 	echo "Wired speed: "$WIPI_ROUTER_SPEED_ETH"KB/s"
 	WIPI_ROUTER_SPEED_WLAN=$(/home/pi/bin/wipi-speedtest.sh $WIPI_ROUTER_IN_WLAN)
 	echo "Wireless speed: "$WIPI_ROUTER_SPEED_WLAN"KB/s"
 	if [ "$WIPI_ROUTER_SPEED_ETH" -ge "$WIPI_ROUTER_SPEED_WLAN" ]; then
	    echo "Wired is faster or equal to Wireless..."
	    WIPI_ROUTER_IN=$WIPI_ROUTER_IN_ETH
	else
 	    echo "Wireless is faster than Wired..."
 	    WIPI_ROUTER_IN=$WIPI_ROUTER_IN_WLAN
 	fi
    ;;
esac

# setup iptables

iptables --flush
iptables --delete-chain

iptables --append INPUT --in-interface lo --jump ACCEPT
iptables --append OUTPUT --out-interface lo --jump ACCEPT
iptables --append INPUT --in-interface $WIPI_ROUTER_OUT --jump ACCEPT
iptables --append OUTPUT --out-interface $WIPI_ROUTER_OUT --jump ACCEPT
iptables --append POSTROUTING --table nat --out-interface $WIPI_ROUTER_IN --jump MASQUERADE
iptables --append FORWARD --in-interface $WIPI_ROUTER_OUT --jump ACCEPT

#
# log router IP
#
WIPI_NET_RTR=$(/sbin/ifconfig $WIPI_ROUTER_OUT | /bin/grep 'inet addr:' | /usr/bin/cut --delimiter=: --fields=2 | /usr/bin/awk '{ print $1 }')
# log location
WIPI_NET_LOG_RTR="/home/pi/log/wipi-net-rtr"

#
# save to log and chmod so all can read
#
echo "WiPi Router IP: $WIPI_NET_RTR"
echo $WIPI_NET_RTR > $WIPI_NET_LOG_RTR
chmod a+r $WIPI_NET_LOG_RTR

#
# end script
#