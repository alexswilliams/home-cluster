#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "! This script must be run as root, or with sudo."
    exit 1
fi

EXTERNAL_INTERFACE="ens3"
CHAIN_NAME="CUSTOM-FIREWALL"

case $1 in
start)
    echo "Installing public-facing firewall"

    # Misc Security Things
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/accept_redirects
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/accept_source_route
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/send_redirects
    echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
    echo 1 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/rp_filter
    echo 1 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/log_martians

    # Chain Definition
    iptables -N ${CHAIN_NAME} || iptables -F ${CHAIN_NAME}
    iptables -A ${CHAIN_NAME} -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Kubernetes Services
    iptables -A ${CHAIN_NAME} -p gre -j RETURN # PPTP VPN
    iptables -A ${CHAIN_NAME} -p tcp --dport 443 -j RETURN # HTTPS
    iptables -A ${CHAIN_NAME} -p tcp --dport 1723 -j RETURN # PPTP
    iptables -A ${CHAIN_NAME} -s 10.254.0.0/16 -p udp --dport 5140 -j RETURN # Syslog (new)
    iptables -A ${CHAIN_NAME} -s 10.254.0.0/16 -p udp --dport 5141 -j RETURN # Syslog (old)

    # Host Services
    iptables -A ${CHAIN_NAME} -p icmp -j ACCEPT
    iptables -A ${CHAIN_NAME} -p tcp --dport 8443 -j ACCEPT

    # Filtering
    iptables -A ${CHAIN_NAME} -m conntrack --ctstate INVALID -j DROP
    iptables -A ${CHAIN_NAME} -s 10.0.0.0/8 -j DROP
    iptables -A ${CHAIN_NAME} -s 172.16.0.0/12 -j DROP
    iptables -A ${CHAIN_NAME} -s 192.168.0.0/16 -j DROP
    iptables -A ${CHAIN_NAME} -s 224.0.0.0/4 -j DROP

    # Default Policy
    iptables -A ${CHAIN_NAME} -j LOG --log-prefix "Rejected external packet: "
    iptables -A ${CHAIN_NAME} -j REJECT


    # Chain Installation
    iptables -C INPUT -i ${EXTERNAL_INTERFACE} -j ${CHAIN_NAME} || iptables -I INPUT 1 -i ${EXTERNAL_INTERFACE} -j ${CHAIN_NAME}

    ;;
stop)
    echo "Removing public-facing firewall"

    iptables -D INPUT -i ${EXTERNAL_INTERFACE} -j ${CHAIN_NAME} || true
    iptables -F ${CHAIN_NAME} || true
    iptables -X ${CHAIN_NAME} || true

    ;;
*)
    echo "Usage: $0 <start|stop>"
    exit 1
    ;;
esac
