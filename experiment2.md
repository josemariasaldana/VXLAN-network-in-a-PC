## Experiment #2: Adding a VXLAN tunnel between the two bridged namespaces

I follow this example https://programmer.help/blogs/practice-vxlan-under-linux.html

This is the scheme I want to build:

![Experiment 2](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment2.png)

Add the VXLAN in namespace `ns0`

Move to `ns0` namespace:
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns0 bash
```

Check the connectivity with the other namespace `ns1`
```
root@JMSALDANA:/home/jmsaldana# ping 192.168.1.21
PING 192.168.1.21 (192.168.1.21) 56(84) bytes of data.
64 bytes from 192.168.1.21: icmp_seq=1 ttl=64 time=0.044 ms
64 bytes from 192.168.1.21: icmp_seq=2 ttl=64 time=0.070 ms
```

Create the VXLAN interface `vxlan0`:
```
root@JMSALDANA:/home/jmsaldana# ip link add vxlan0 type vxlan id 1 remote 192.168.1.21 dstport 4789 dev veth0
```

Set the interface up and add an IP address to it:
```
root@JMSALDANA:/home/jmsaldana# ip link set vxlan0 up
root@JMSALDANA:/home/jmsaldana# ip addr add 10.0.0.20/24 dev vxlan0
root@JMSALDANA:/home/jmsaldana# ifconfig
(…)
vxlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 10.0.0.20  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::7009:ccff:fe8f:97e7  prefixlen 64  scopeid 0x20<link>
        ether 72:09:cc:8f:97:e7  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 8  bytes 544 (544.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Check the routes: it can be observed that the route to `10.0.0.0` goes through `vxlan0` interface:
```
root@JMSALDANA:/home/jmsaldana# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 vxlan0
192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 veth0
```

Add the VXLAN in namespace `ns1`
(Same process)
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns1 bash
root@JMSALDANA:/home/jmsaldana# ping 192.168.1.20
PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.
64 bytes from 192.168.1.20: icmp_seq=1 ttl=64 time=0.044 ms
64 bytes from 192.168.1.20: icmp_seq=2 ttl=64 time=0.070 ms

root@JMSALDANA:/home/jmsaldana# ip link add vxlan1 type vxlan id 1 remote 192.168.1.20 dstport 4789 dev veth1
root@JMSALDANA:/home/jmsaldana# ip link set vxlan1 up
root@JMSALDANA:/home/jmsaldana# ip addr add 10.0.0.21/24 dev vxlan1
root@JMSALDANA:/home/jmsaldana# ifconfig
(…)
Vxlan1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 10.0.0.21  netmask 255.255.255.0  broadcast 0.0.0.0
        inet6 fe80::2822:a6ff:fe35:3f26  prefixlen 64  scopeid 0x20<link>
        ether 2a:22:a6:35:3f:26  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7  bytes 488 (488.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

root@JMSALDANA:/home/jmsaldana# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 vxlan1
192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 veth1
```

## These are all the commands required to create the VXLAN on both sides

The commands must be executed from the main namespace.
```
ip netns exec ns0 ip link add vxlan0 type vxlan id 1 remote 192.168.1.21 dstport 4789 dev veth0
ip netns exec ns0 ip link set vxlan0 up
ip netns exec ns0 ip addr add 10.0.0.20/24 dev vxlan0

ip netns exec ns1 ip link add vxlan1 type vxlan id 1 remote 192.168.1.20 dstport 4789 dev veth1
ip netns exec ns1 ip link set vxlan1 up
ip netns exec ns1 ip addr add 10.0.0.21/24 dev vxlan1
```

## Check that it works

ping between the endpoints of the VXLAN

From `ns1`, I can ping the other side of the VXLAN (inside `ns0`):
```
root@JMSALDANA:/home/jmsaldana# ping 10.0.0.20
PING 10.0.0.20 (10.0.0.20) 56(84) bytes of data.
64 bytes from 10.0.0.20: icmp_seq=1 ttl=64 time=0.048 ms
64 bytes from 10.0.0.20: icmp_seq=2 ttl=64 time=0.085 ms
64 bytes from 10.0.0.20: icmp_seq=3 ttl=64 time=0.075 ms
64 bytes from 10.0.0.20: icmp_seq=4 ttl=64 time=0.092 ms
```

I capture the traffic in the main namespace, in the bridge `br10`, so I can see the tunneled packets:
```
root@JMSALDANA:/home/jmsaldana# tcpdump -i br10 -w VXLAN_inside_my_laptop.pcap
```

## Analysis of the capture

### First ARP exchange

Packet 1 is the ARP request sent by `veth1`, asking for the MAC address of `192.168.1.20`, i.e. the other side of the tunnel.
Packet 2 is the response to that ARP request.

These packets are not tunneled, because they are needed in order to build the tunnel:

![experiment2.1](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment2.1.png)
 
### Second ARP exchange

Packet 3 is the ARP request sent by `vxlan1`, asking for the MAC address of `10.0.0.2`. This packet is the first one that goes through the VXLAN tunnel.
Packet 4 is the response to that ARP request. It is also tunneled.

These packets are the first ones that go through the tunnel:
 
![experiment2.2](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment2.2.png)

Finally, the ICMP Exchange takes place through the tunnel.

Each ICMP packet has:
- An external Ethernet + IP + UDP header
- The VXLAN header, with Virtual Network Identifier 1
- The inner Ethernet + IP + ICMP header

The extra overhead is 50 bytes: 
- 14: outer Ethernet header
- 20: outer IP header
- 8: outer UDP header
- 8: VXLAN header

![experiment2.3](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment2.3.png)


### Check that it works: UDP between the endpoints of the VXLAN

I can also send a UDP packet to the other side of the tunnel.
```
root@JMSALDANA:/home/jmsaldana# echo "This is my data" > /dev/udp/10.0.0.20/8000
```

Packet 1 is the UDP packet sent to `10.0.0.20`

The UDP packet has:
- An external Ethernet + IP + UDP header
- The VXLAN header, with Virtual Network Identifier 1
- The inner Ethernet + IP + UDP header
- The data

The extra overhead is again 50 bytes.

Packet 2 is just an ICMP packet that the destination returns saying that port `8000` is not reachable: there is no process listening in that port.

![experiment2.4](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment2.4.png)
