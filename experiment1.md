# Experiment 1: Create two namespaces (in the same IP network) and connect them with a bridge

This is the scheme I will create:

![experiment1](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment1.png)

I'm trying to set up two network namespaces to communicate with each other. I've set up two namespaces, `ns0` and `ns1` that each have a `veth` pair, where the non-namespaced side of the veth (i.e. the `brveth`) is linked to a bridge.

## Create the setup

Create two linked interfaces `veth0` and `brveth0`, and set up `rveth0`:
```
ip link add veth0 type veth peer name brveth0
ip link set brveth0 up
```

Create two linked interfaces `veth1` and `brveth1`, and set up `brveth1`:
```
ip link add veth1 type veth peer name brveth1
ip link set brveth1 up
```

Add a bridge `br10` and set it up:
```
ip link add br10 type bridge
ip link set br10 up
```

Add an IP address to the bridge (`brd` is for also adding broadcast):
```
ip addr add 192.168.1.11/24 brd + dev br10
```

Note: this allows you to communicate `ns0` and `ns1` with the global namespace.


Add two network namespaces `ns0` and `ns1`:
```
ip netns add ns0
ip netns add ns1
```

You can now see the global namespace list:
```
$ ip netns list
ns1 (id: 1)
ns0 (id: 0)
```

Assign `veth0` to `ns0`, and `veth1` to `ns1`:
```
ip link set veth0 netns ns0
ip link set veth1 netns ns1
```

Inside ns0, add the IP address to `veth0`, set it up, and also set up the local interface `lo`:
```
ip netns exec ns0 ip addr add 192.168.1.20/24 dev veth0
ip netns exec ns0 ip link set veth0 up
ip netns exec ns0 ip link set lo up
```

Inside `ns1`, add the IP address to `veth1`, set it up, and also set up the local interface `lo`:
```
ip netns exec ns1 ip addr add 192.168.1.21/24 dev veth1
ip netns exec ns1 ip link set veth1 up
ip netns exec ns1 ip link set lo up
```

Associate `brveth0` and `brveth1` to the bridge `br10`:
```
ip link set brveth0 master br10
ip link set brveth1 master br10
```

List the bridges:
```
root@JMSALDANA:/home/jmsaldana# brctl show
bridge name     bridge id               STP enabled     interfaces
br10            8000.128812c192fd       no              brveth0
                                                        brveth1
```

As expected, I can ping from `ns1` to the interface in `ns0`:
```
$ ip netns exec ns1 ping -c 3  192.168.1.20
PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.
64 bytes from 192.168.1.20: icmp_seq=1 ttl=64 time=0.099 ms
64 bytes from 192.168.1.20: icmp_seq=2 ttl=64 time=0.189 ms
```

Note: eth0 is not connected with the bridge br10, so traffic cannot go outside.

The full script to create this network scheme is [here](https://github.com/josemariasaldana/VXLAN-network-in-a-PC/blob/main/experiment1.sh).

Interesting bibliography: https://unix.stackexchange.com/questions/546235/i-can-ping-across-namespaces-but-not-connect-with-tcp

## Test the setup

Move to a namespace and ping from it. Move to `ns1` namespace:
```
$ ip netns exec ns1 bash
```

I am now in the second namespace:
```
root@JMSALDANA:/home/jmsaldana# ip netns identify
ns1
```

Ping from `ns1` to the interface in `ns0`:
```
# ping 192.168.1.20
PING 192.168.1.20 (192.168.1.20) 56(84) bytes of data.
64 bytes from 192.168.1.20: icmp_seq=1 ttl=64 time=0.028 ms
64 bytes from 192.168.1.20: icmp_seq=2 ttl=64 time=0.059 ms
```

See the list of IP interfaces of `ns1`:
```
root@JMSALDANA:/home/jmsaldana# ip link list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0
12: veth1@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 32:91:50:17:a4:c4 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```

### Using `netcat` between different namespaces:

Move to `ns0` and run a `netcat` server, listening in port `1234`.
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns0 bash
root@JMSALDANA:/home/jmsaldana# ip netns identify
ns0
root@JMSALDANA:/home/jmsaldana# nc -lp 1234
```

`netcat` works normally:
Move to `ns1` and run `netcat` client
```
root@JMSALDANA:/home/jmsaldana# ip netns exec ns1 bash
root@JMSALDANA:/home/jmsaldana# ip netns identify
ns1
root@JMSALDANA:/home/jmsaldana# nc 192.168.1.20 1234
```
