## Experiment #6: Two VXLAN tunnels over the routing setup

Now, I will build two different VXLAN tunnels. The idea is that, in a real setup, `ns0` and `ns2` would be in the same lab (different subnetworks), and `ns1` would be in another location.

![experiment6](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment6.png)

This is a [script with all the commands](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment6.sh).

I create a VXLAN tunnel from `ns0` to `ns1`, and another one between `ns1` and `ns2`. In order to let traffic flow between both tunnels, I create a bridge `br-vx` inside `ns1`.

The objective is to ping from `vxlan0` to `vxlan2b` through the two tunnels.

These are the commands:

Remove namespaces if they exist
```
ip netns del ns0 &>/dev/null
ip netns del ns1 &>/dev/null
ip netns del ns2 &>/dev/null
```

Create namespaces
```
ip netns add ns0
ip netns add ns1
ip netns add ns2
```

Create a `veth` link with two peer interfaces: `v-eth0` and `v-peer0`
```
ip link add v-eth0 type veth peer name v-peer0
```

Create a `veth` link with two peer interfaces: `v-eth1` and `v-peer1`
```
ip link add v-eth1 type veth peer name v-peer1
```

Create a `veth` link with two peer interfaces: `v-eth2` and `v-peer2`
```
ip link add v-eth2 type veth peer name v-peer2
```

Add `v-peer-0` to `ns0`.
```
ip link set v-peer0 netns ns0
```

Add `v-peer-1` to `ns1`.
```
ip link set v-peer1 netns ns1
```

Add `v-peer-2` to `ns2`.
```
ip link set v-peer2 netns ns2
```

Setup IP address of `v-eth0`
```
ip addr add 10.200.0.1/24 dev v-eth0
ip link set v-eth0 up
```

Setup IP address of `v-eth1`
```
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up
```

Setup IP address of `v-eth2`.
```
ip addr add 10.200.2.1/24 dev v-eth2
ip link set v-eth2 up
```

Setup IP address of `v-peer0`.
```
ip netns exec ns0 ip addr add 10.200.0.2/24 dev v-peer0
ip netns exec ns0 ip link set v-peer0 up
```

Setup IP address of `v-peer1`.
```
ip netns exec ns1 ip addr add 10.200.1.2/24 dev v-peer1
ip netns exec ns1 ip link set v-peer1 up
```

Setup IP address of `v-peer2`.
```
ip netns exec ns2 ip addr add 10.200.2.2/24 dev v-peer2
ip netns exec ns2 ip link set v-peer2 up
```

set ‘lo’ interface up in ns0
```
ip netns exec ns0 ip link set lo up
```

# set ‘lo’ interface up in ns1
```
ip netns exec ns1 ip link set lo up
```

# set ‘lo’ interface up in ns2
```
ip netns exec ns2 ip link set lo up
```

# make all external traffic leaving ns0 go through v-eth0.
```
ip netns exec ns0 ip route add default via 10.200.0.1
```

# make all external traffic leaving ns1 go through v-eth1.
```
ip netns exec ns1 ip route add default via 10.200.1.1
```

# make all external traffic leaving ns2 go through v-eth2.
```
ip netns exec ns2 ip route add default via 10.200.2.1
```

## Share internet access between host and NS.

# Enable IP-forwarding.
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

# Flush forward rules, policy DROP by default.
```
iptables -P FORWARD DROP
iptables -F FORWARD
```

# Allow forwarding between eth0 and v-eth0
```
iptables -A FORWARD -i eth0 -o v-eth0 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth0 -j ACCEPT
```

# Allow forwarding between eth0 and v-eth1
```
iptables -A FORWARD -i eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth1 -j ACCEPT
```

# Allow forwarding between eth0 and v-eth2
```
iptables -A FORWARD -i eth0 -o v-eth2 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth2 -j ACCEPT
```

# Allow forwarding between v-eth0 and v-eth1
```
iptables -A FORWARD -i v-eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -i v-eth1 -o v-eth0 -j ACCEPT
```

# Allow forwarding between v-eth0 and v-eth2
```
iptables -A FORWARD -i v-eth0 -o v-eth2 -j ACCEPT
iptables -A FORWARD -i v-eth2 -o v-eth0 -j ACCEPT
```

# Allow forwarding between v-eth1 and v-eth2
```
iptables -A FORWARD -i v-eth1 -o v-eth2 -j ACCEPT
iptables -A FORWARD -i v-eth2 -o v-eth1 -j ACCEPT
```


# NAT rules
# Flush nat rules.
```
iptables -t nat -F
```

# Enable masquerading of 10.200.1.0. This is not necessary to reach eth0
```
iptables -t nat -A POSTROUTING -s 10.200.1.0/255.255.255.0 -o eth0 -j MASQUERADE
```


# VXLAN tunnels
# Create the VXLAN tunnel 10.0.0.0:
```
ip netns exec ns0 ip link add vxlan0 type vxlan id 1 remote 10.200.1.2 dstport 4789 dev v-peer0
ip netns exec ns0 ip link set vxlan0 up
ip netns exec ns0 ip addr add 10.0.0.20/24 dev vxlan0

ip netns exec ns1 ip link add vxlan1 type vxlan id 1 remote 10.200.0.2 dstport 4789 dev v-peer1
ip netns exec ns1 ip link set vxlan1 up
ip netns exec ns1 ip addr add 10.0.0.21/24 dev vxlan1
```

# Create the VXLAN tunnel 10.0.1.0:
```
ip netns exec ns1 ip link add vxlan1b type vxlan id 2 remote 10.200.2.2 dstport 4789 dev v-peer1
ip netns exec ns1 ip link set vxlan1b up
ip netns exec ns1 ip addr add 10.0.1.21/24 dev vxlan1b

ip netns exec ns2 ip link add vxlan2b type vxlan id 2 remote 10.200.1.2 dstport 4789 dev v-peer2
ip netns exec ns2 ip link set vxlan2b up
ip netns exec ns2 ip addr add 10.0.1.22/24 dev vxlan2b
```

#add a route in ns0 to reach the tunnel 10.0.1.0
```
ip netns exec ns0 ip route add 10.0.1.0/24 dev vxlan0
```

# at this point, you should be able to ping from ns0 to vxlan1b in ns1:
```
$ ip netns exec ns0 ping 10.0.1.21
```

# add a route in ns2 to reach the tunnel 10.0.0.0
```
ip netns exec ns2 ip route add 10.0.0.0/24 dev vxlan2b
```

# create a bridge inside ns1 and bridge ‘vxlan1’ and ‘vxlan1b’ together
# this makes it possible to send traffic between ns0 and ns2
```
ip netns exec ns1 brctl addbr br-vx
ip netns exec ns1 ip link set br-vx up
ip netns exec ns1 brctl addif br-vx vxlan1
ip netns exec ns1 brctl addif br-vx vxlan1b
```
# at this point, you should be able to ping from ns2 to ns0:
```
$ ip netns exec ns2 ping 10.0.0.20
```

and vice versa:
```
$ ip netns exec ns0 ping 10.0.1.22
```

The next capture has been obtained in v-eth1 (# tcpdump -i v-eth1 -w double_VXLAN.pcap) while running:
```
$ ip netns exec ns2 ping 10.0.0.20 
```

![experiment6.1](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment6.1.png)

As it can be seen, each ping request appears twice, because it has two hops corresponding to the two VXLAN tunnels it has to traverse.
Packet #1 goes from 10.200.2.2 to 10.200.1.2
Packet #2 goes from 10.200.1.2 to 10.200.0.2
 
In this other capture, the ARPs can be observed:
 
![experiment6.2](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment6.2.png)
