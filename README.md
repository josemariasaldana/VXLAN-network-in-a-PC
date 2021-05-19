# VXLAN-network-in-a-PC
Create a VXLAN setup inside a single PC, using Linux network namespaces

This repository includes two kinds of tests:
-	Test of netns: Linux network namespaces.
-	Test of VXLAN tunnels.

With network namespaces, you can have different and separate instances of network interfaces and routing tables that operate independent of each other.
With VXLAN you can create tunnels that send the whole Ethernet frame inside a UDP / IP packet.

All the tests have been run inside a Windows machine, running Debian for Windows (Microsoft-Windows-Subsystem-Linux, WSL). 

# Bibliography

## 1
https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/ 
An interface can only be assigned to one namespace at a time. If the root namespace owns eth0, which provides access to the external world, only programs within the root namespace could reach the Internet .
The solution is to communicate a namespace with the root namespace via a veth pair. A veth pair works like a patch cable, connecting two sides. It consists of two virtual interfaces:
-	one of them is assigned to the root network namespace
-	the other lives within a network namespace.

Setting up their IP addresses and routing rules accordingly, plus enabling NAT in the host side, will be enough to provide Internet access to the network namespace.

## 2 https://superuser.com/questions/1229674/how-to-create-a-virtual-lan-on-linux-with-dummy-interfaces-and-bridges
You won't be able to build a virtual LAN with dummy interfaces.
Instead, use network namespaces as a substitute for different computers ("hosts"), and connect them with virtual ethernet links (veth pairs).
This way, you can build a LAN as complicated as you like. Bridge them any way you want, do forwarding and NAT, set up complicated routing, etc.

## 3
see https://blog.scottlowe.org/2013/09/04/introducing-linux-network-namespaces/ 

## 4
see https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/ 

Here, two namespaces (`netns1` and `netns2`) have been created, in addition to the main one (the host itself, yellow).

Each namespace has two interfaces, which are connected like a pipe. Virtual Ethernet interfaces always come in pairs, and they are connected like a tube: whatever comes in one veth interface will come out the other peer veth interface.

You can then use bridges to connect them.

# Note: Before running the experiments
To avoid the need of using sudo, you can do this, to act as root:
```
$ sudo bash
```
