# Experiment #3: Routing traffic from a namespace

I follow the example in https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/ 

The idea is to send traffic from a namespace to the physical interface, routing it without a bridge.

This is a [script with all the commands](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment3.sh).

Remove the namespace if it exists
```
ip netns del ns1 &>/dev/null
```

Create the namespace
```
ip netns add ns1
```

Create veth link with two peer interfaces: v-eth1 and v-peer1
```
ip link add v-eth1 type veth peer name v-peer1
```

Add v-peer-1 to NS.
```
ip link set v-peer1 netns ns1
```

Setup IP address of v-eth1.
```
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up
```

Setup IP address of v-peer1.
```
ip netns exec ns1 ip addr add 10.200.1.2/24 dev v-peer1
ip netns exec ns1 ip link set v-peer1 up
```

set ‘lo’ interface up
```
ip netns exec ns1 ip link set lo up
```

make all external traffic leaving ns1 go through v-eth1.
```
ip netns exec ns1 ip route add default via 10.200.1.1
```

## Share internet access between host and NS.

Enable IP-forwarding.
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Flush forward rules, policy DROP by default.
```
iptables -P FORWARD DROP
iptables -F FORWARD
```

Allow forwarding between eth0 and v-eth1.
```
iptables -A FORWARD -i eth0 -o v-eth1 -j ACCEPT
iptables -A FORWARD -o eth0 -i v-eth1 -j ACCEPT
```

Now, you should be able to ping eth0 from the namespace ns1:
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns1 ping 172.23.43.179
PING 172.23.43.179 (172.23.43.179) 56(84) bytes of data.
64 bytes from 172.23.43.179: icmp_seq=1 ttl=64 time=0.033 ms
64 bytes from 172.23.43.179: icmp_seq=2 ttl=64 time=0.023 ms
```

Add NAT
If you want to go out, you have to add some NAT rules
Note: The NAT commands below are the legacy ones. In order to run them, you must first do
```
$ update-alternatives --config iptables
```
And choose option 1 “/usr/sbin/iptables-legacy”

Flush nat rules.
```
iptables -t nat -F
```

Enable masquerading of 10.200.1.0. This is not necessary to reach eth0
```
iptables -t nat -A POSTROUTING -s 10.200.1.0/255.255.255.0 -o eth0 -j MASQUERADE
```

The new (not legacy) command should be something like:
```
nft add rule nat postrouting ip saddr 10.200.1.0/24 oif eth0 masquerade
```

After this, you should be able to do this:
```
$ ip netns exec ns1 ping 8.8.8.8
```
