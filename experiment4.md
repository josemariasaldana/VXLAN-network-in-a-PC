## Experiment #4: Routing traffic between two namespaces

![Experiment 4](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment4.png)

This is a [script with all the commands](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment4.sh).

Remove namespaces if they exist
```
ip netns del ns0 &>/dev/null
ip netns del ns1 &>/dev/null
```

Create namespaces
```
ip netns add ns0
ip netns add ns1
```

Create `veth` link with two peer interfaces: `v-eth0` and `v-peer0`
```
ip link add v-eth0 type veth peer name v-peer0
```

Create `veth` link with two peer interfaces: `v-eth1` and `v-peer1`
```
ip link add v-eth1 type veth peer name v-peer1
```

Add `v-peer-0` to NS.
```
ip link set v-peer0 netns ns0
```

Add `v-peer-1` to NS.
```
ip link set v-peer1 netns ns1
```

Setup IP address of `v-eth0`.
```
ip addr add 10.200.0.1/24 dev v-eth0
ip link set v-eth0 up
```

Setup IP address of `v-eth1`.
```
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up
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

set `lo` interface up in `ns0`
```
ip netns exec ns0 ip link set lo up
```
set `lo` interface up in `ns1`
```
ip netns exec ns1 ip link set lo up
```

make all external traffic leaving `ns0` go through `v-eth0`.
```
ip netns exec ns0 ip route add default via 10.200.0.1
```

make all external traffic leaving `ns1` go through `v-eth1`.
```
ip netns exec ns1 ip route add default via 10.200.1.1
```

## Share internet access between host and NS.

Enable IP-forwarding.
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Flush forward rules, policy `DROP` by default.
```
iptables -P FORWARD DROP
iptables -F FORWARD
```

Allow forwarding between `eth0` and `v-eth0`
```
iptables -A FORWARD -i eth0 -o v-eth0 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth0 -j ACCEPT
```

Allow forwarding between `eth0` and `v-eth1`
```
iptables -A FORWARD -i eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth1 -j ACCEPT
```

Allow forwarding between `v-eth0` and `v-eth1`
```
iptables -A FORWARD -i v-eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -o v-eth0 -i v-eth1 -j ACCEPT
```

at this point, you should be able to ping from `ns1` to `ns0`:
```
$ ip netns exec ns1 ping 10.200.0.2
```

Flush nat rules.
```
iptables -t nat -F
```

Enable masquerading of `10.200.1.0`. This is not necessary to reach `eth0`, but it is necessary to go to the Internet
```
iptables -t nat -A POSTROUTING -s 10.200.1.0/255.255.255.0 -o eth0 -j MASQUERADE
```

Now, you should be able to ping from `ns1` to the IP address inside `ns0`
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns1 ping 10.200.0.2
PING 10.200.0.2 (10.200.0.2) 56(84) bytes of data.
64 bytes from 10.200.0.2: icmp_seq=1 ttl=63 time=0.045 ms
64 bytes from 10.200.0.2: icmp_seq=2 ttl=63 time=0.059 ms
```

And you should be able to ping outside
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns1 ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=114 time=7.59 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=114 time=7.85 ms
```
