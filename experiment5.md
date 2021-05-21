# Experiment #5: VXLAN over the routing setup

Now, I will build the VXLAN setup over the routing setup.

![experiment5](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment5.png)

These are the commands you need now (in addition to the previous ones):
```
ip netns exec ns0 ip link add vxlan0 type vxlan id 1 remote 10.200.1.2 dstport 4789 dev v-peer0
ip netns exec ns0 ip link set vxlan0 up
ip netns exec ns0 ip addr add 10.0.0.20/24 dev vxlan0

ip netns exec ns1 ip link add vxlan1 type vxlan id 1 remote 10.200.0.2 dstport 4789 dev v-peer1
ip netns exec ns1 ip link set vxlan1 up
ip netns exec ns1 ip addr add 10.0.0.21/24 dev vxlan1
```

Now you can ping from `ns0` to `ns1`:
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns0 ping 10.0.0.21
PING 10.0.0.21 (10.0.0.21) 56(84) bytes of data.
64 bytes from 10.0.0.21: icmp_seq=1 ttl=64 time=0.090 ms
64 bytes from 10.0.0.21: icmp_seq=2 ttl=64 time=0.097 ms
```

Analysis of the capture
You can see it in the capture `VXLAN_inside_my_laptop_routing.pcap` (the analysis is similar to the one presented above: 4 ARPs and then the pings):

![experiment5.1](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment5.1.png)
