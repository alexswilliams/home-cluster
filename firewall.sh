#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "! This script must be run as root, or with sudo."
    exit 1
fi

EXTERNAL_INTERFACE="ens3"
INPUT_CHAIN_NAME="CUSTOM-INPUT-FIREWALL"
FORWARD_CHAIN_NAME="CUSTOM-FORWARD-FIREWALL"
OUTPUT_CHAIN_NAME="CUSTOM-OUTPUT-FIREWALL"

case $1 in
start)
    echo "Enabling PPTP connection tracking"
    modprobe nf_conntrack_pptp


    echo "Configuring kernel"

    # Misc Security Things
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/accept_redirects
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/accept_source_route
    echo 0 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/send_redirects
    echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
    echo 1 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/rp_filter
    echo 1 > /proc/sys/net/ipv4/conf/${EXTERNAL_INTERFACE}/log_martians

    echo "Installing ingress firewall"

    # Chain Definition
    iptables -N ${INPUT_CHAIN_NAME} || iptables -F ${INPUT_CHAIN_NAME}
    iptables -A ${INPUT_CHAIN_NAME} -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Kubernetes Services
    iptables -A ${INPUT_CHAIN_NAME} -p gre -j RETURN # PPTP VPN
    iptables -A ${INPUT_CHAIN_NAME} -p tcp --dport 80 -j RETURN # HTTP (for lets encrypt)
    iptables -A ${INPUT_CHAIN_NAME} -p tcp --dport 443 -j RETURN # HTTPS
    iptables -A ${INPUT_CHAIN_NAME} -p tcp --dport 1723 -j RETURN # PPTP
    iptables -A ${INPUT_CHAIN_NAME} -s 10.254.0.0/16 -p udp --dport 5140 -j RETURN # Syslog (new)
    iptables -A ${INPUT_CHAIN_NAME} -s 10.254.0.0/16 -p udp --dport 5141 -j RETURN # Syslog (old)

    # Host Services
    iptables -A ${INPUT_CHAIN_NAME} -p icmp -j ACCEPT
    iptables -A ${INPUT_CHAIN_NAME} -p tcp --dport 8443 -j ACCEPT

    # Filtering
    iptables -A ${INPUT_CHAIN_NAME} -m conntrack --ctstate INVALID -j DROP
    iptables -A ${INPUT_CHAIN_NAME} -s 10.0.0.0/8 -j DROP
    iptables -A ${INPUT_CHAIN_NAME} -s 172.16.0.0/12 -j DROP
    iptables -A ${INPUT_CHAIN_NAME} -s 192.168.0.0/16 -j DROP
    iptables -A ${INPUT_CHAIN_NAME} -s 224.0.0.0/4 -j DROP

    # Default Policy
    iptables -A ${INPUT_CHAIN_NAME} -j LOG --log-prefix "Rejected inbound packet: "
    iptables -A ${INPUT_CHAIN_NAME} -j REJECT

    # Chain Installation
    iptables -C INPUT -i ${EXTERNAL_INTERFACE} -j ${INPUT_CHAIN_NAME} || iptables -I INPUT 1 -i ${EXTERNAL_INTERFACE} -j ${INPUT_CHAIN_NAME}


    echo "Installing egress firewall"

    # Chain Definition
    iptables -N ${OUTPUT_CHAIN_NAME} || iptables -F ${OUTPUT_CHAIN_NAME}
    iptables -A ${OUTPUT_CHAIN_NAME} -m state --state ESTABLISHED,RELATED -j ACCEPT

    # VPN
    iptables -A ${OUTPUT_CHAIN_NAME} -p gre -j RETURN

    # Default Policy
    iptables -A ${OUTPUT_CHAIN_NAME} -j LOG --log-prefix "Outbound packet: "
    iptables -A ${OUTPUT_CHAIN_NAME} -j RETURN

    # Chain Installation
    iptables -C OUTPUT -o ${EXTERNAL_INTERFACE} -j ${OUTPUT_CHAIN_NAME} || iptables -I OUTPUT 1 -o ${EXTERNAL_INTERFACE} -j ${OUTPUT_CHAIN_NAME}


    echo "Installing VPN firewall"

    # Chain Definition
    iptables -N ${FORWARD_CHAIN_NAME} || iptables -F ${FORWARD_CHAIN_NAME}
    iptables -A ${FORWARD_CHAIN_NAME} -j LOG --log-prefix "Forwarded packet: "
    iptables -A ${FORWARD_CHAIN_NAME} -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Default Policy
    iptables -A ${FORWARD_CHAIN_NAME} -j RETURN

    # Chain Installation
    iptables -C FORWARD -j ${FORWARD_CHAIN_NAME} || iptables -I FORWARD 1 -j ${FORWARD_CHAIN_NAME}



    ;;
stop)
    echo "Removing public-facing firewall"

    iptables -D INPUT -i ${EXTERNAL_INTERFACE} -j ${INPUT_CHAIN_NAME} || true
    iptables -F ${INPUT_CHAIN_NAME} || true
    iptables -X ${INPUT_CHAIN_NAME} || true

    iptables -D OUTPUT -o ${EXTERNAL_INTERFACE} -j ${OUTPUT_CHAIN_NAME} || true
    iptables -F ${OUTPUT_CHAIN_NAME} || true
    iptables -X ${OUTPUT_CHAIN_NAME} || true

    iptables -D FORWARD -j ${FORWARD_CHAIN_NAME} || true
    iptables -F ${FORWARD_CHAIN_NAME} || true
    iptables -X ${FORWARD_CHAIN_NAME} || true

    ;;
*)
    echo "Usage: $0 <start|stop>"
    exit 1
    ;;
esac
