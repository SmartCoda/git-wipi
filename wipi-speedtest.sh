#!/bin/bash
#
# wipi-netspeed.sh - uses curl...
#
# requires additional code to check existing interface is connected to web
#
#
# Author: SmartCoda
#

#
# setup variables
#
WHATISMYIP=http://ifconfig.me/ip
NETSPEEDURL=http://ftp.nl.debian.org/debian/dists/squeeze/main/installer-i386/current/images/netboot/debian-installer/i386/linux

#
# check if interface passed accross
#
if [ -z $1 ]; then
    if [[ -t 1 ]]; then echo "No interface supplied, using default of 'wlan1'..."; fi
    NETSPEEDINTERFACE=wlan1
else
    if [[ -t 1 ]]; then echo "Interface of '"$1"' supplied, checking existance..."; fi
    NETSPEEDINTERFACECHECK=$(/sbin/ifconfig $1 | /bin/grep "Link" | /usr/bin/awk '{ print $1 }')
    if [ "$NETSPEEDINTERFACECHECK" = "$1" ]; then
     if [[ -t 1 ]]; then echo "Supplied interface '"$1"' exists, testing for internet connection..."; fi
  NETSPEEDINTERFACEEXTIP=$(/usr/bin/curl --silent --interface $1 $WHATISMYIP)
  if [ ! -z $NETSPEEDINTERFACEEXTIP ]; then
      if [[ -t 1 ]]; then echo "Supplied interface '"$1"' has external IP "$NETSPEEDINTERFACEEXTIP" and will be speed checked..."; fi
         NETSPEEDINTERFACE=$1
  else
      if [[ -t 1 ]]; then echo "Supplied interface '"$1"' has no external IP, using default of 'wlan1' for speed check..."; fi
      NETSPEEDINTERFACE=wlan1
  fi
 else
     if [[ -t 1 ]]; then echo "Supplied interface '"$1"' does not exist, using default of 'wlan1' for speed check..."; fi
     NETSPEEDINTERFACE=wlan1
 fi
fi

#
# main program
#
NETSPEED=$(curl --output /dev/null --silent --write-out %{speed_download} --interface $NETSPEEDINTERFACE $NETSPEEDURL)
echo "$NETSPEED / 1024" | bc