#!/bin/bash
# Remove the namespace if it exists
ip netns del ns1 &>/dev/null

# Create the namespace
ip netns add ns1

# Create veth link with two peer interfaces: v-eth1 and v-peer1
ip link add v-eth1 type veth peer name v-peer1

# Add v-peer-1 to NS.
ip link set v-peer1 netns ns1

# Setup IP address of v-eth1.
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up

# Setup IP address of v-peer1.
ip netns exec ns1 ip addr add 10.200.1.2/24 dev v-peer1
ip netns exec ns1 ip link set v-peer1 up

# set ‘lo’ interface up
ip netns exec ns1 ip link set lo up

# make all external traffic leaving ns1 go through v-eth1.
ip netns exec ns1 ip route add default via 10.200.1.1

## Share internet access between host and NS.

# Enable IP-forwarding.
echo 1 > /proc/sys/net/ipv4/ip_forward

# Flush forward rules, policy DROP by default.
iptables -P FORWARD DROP
iptables -F FORWARD

# Allow forwarding between eth0 and v-eth1.
iptables -A FORWARD -i eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth1 -j ACCEPT
