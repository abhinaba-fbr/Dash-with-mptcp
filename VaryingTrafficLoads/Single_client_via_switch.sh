##############################################################
# Topology:
#
#        ----- r1 -----            ----- r4 -----
#      /                \        /                \
#     b1                 \      /                  \
#    /                    \    /                    \
#  h1                       r3 --------- r5 -------- s1
#    \                    /    \                    /
#     b2                 /      \                  /
#      \                /        \                /
#        ----- r2 -----            ----- r6 -----     
#
# h1: host  s1: server  b1,b2: switches  r1-r6:routers  
##############################################################

#!/bin/sh

# Create a host/client
ip netns add h1

# Create a server
ip netns add s1

# Create six routers
ip netns add r1
ip netns add r2
ip netns add r3
ip netns add r4
ip netns add r5
ip netns add r6

# Create two switches
ip link add b1 type bridge
ip link set dev b1 up
ip link add b2 type bridge
ip link set dev b2 up

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on the network namespaces
ip netns exec s1 sysctl -w net.mptcp.enabled=1
ip netns exec h1 sysctl -w net.mptcp.enabled=1
ip netns exec s1 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h1 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec s1 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h1 sysctl -w net.mptcp.stale_loss_cnt=10

# Configuring the C flag
ip netns exec s1 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h1 sysctl -w net.mptcp.allow_join_initial_addr_port=1

# Enable ip forwarding on the routers
ip netns exec r1 sysctl -w net.ipv4.ip_forward=1
ip netns exec r2 sysctl -w net.ipv4.ip_forward=1
ip netns exec r3 sysctl -w net.ipv4.ip_forward=1
ip netns exec r4 sysctl -w net.ipv4.ip_forward=1
ip netns exec r5 sysctl -w net.ipv4.ip_forward=1
ip netns exec r6 sysctl -w net.ipv4.ip_forward=1

# Create the virtual ethernet (veth) pairs

ip link add eh1a type veth peer name eb1a
ip link add eb1b type veth peer name er1a

ip link add eh1b type veth peer name eb2a
ip link add eb2b type veth peer name er2a

ip link set eh1a netns h1
ip link set eh1b netns h1
ip link set er1a netns r1
ip link set er2a netns r2
ip link set eb1a master b1
ip link set eb1b master b1
ip link set eb2a master b2
ip link set eb2b master b2

ip link add er1b netns r1 type veth peer name er3a netns r3
ip link add er2b netns r2 type veth peer name er3b netns r3

ip link add er3c netns r3 type veth peer name er4a netns r4
ip link add er3d netns r3 type veth peer name er5a netns r5
ip link add er3e netns r3 type veth peer name er6a netns r6
ip link add er4b netns r4 type veth peer name es1a netns s1
ip link add er5b netns r5 type veth peer name es1b netns s1
ip link add er6b netns r6 type veth peer name es1c netns s1

# Assign IP addresses to the interfaces
ip -n h1 address add 10.0.0.1/24 dev eh1a
ip -n h1 address add 192.168.0.1/24 dev eh1b

ip -n r1 address add 10.0.0.2/24 dev er1a
ip -n r1 address add 10.0.1.1/24 dev er1b

ip -n r2 address add 192.168.0.2/24 dev er2a
ip -n r2 address add 192.168.1.1/24 dev er2b

ip -n r3 address add 10.0.1.2/24 dev er3a
ip -n r3 address add 192.168.1.2/24 dev er3b
ip -n r3 address add 10.0.2.1/24 dev er3c
ip -n r3 address add 11.0.0.1/24 dev er3d
ip -n r3 address add 192.168.2.1/24 dev er3e 

ip -n r4 address add 10.0.2.2/24 dev er4a
ip -n r4 address add 10.0.3.1/24 dev er4b

ip -n r5 address add 11.0.0.2/24 dev er5a
ip -n r5 address add 11.0.1.1/24 dev er5b

ip -n r6 address add 192.168.2.2/24 dev er6a
ip -n r6 address add 192.168.3.1/24 dev er6b

ip -n s1 address add 10.0.3.2/24 dev es1a
ip -n s1 address add 11.0.1.2/24 dev es1b
ip -n s1 address add 192.168.3.2/24 dev es1c

# Turn up the links
ip -n h1 link set lo up
ip -n h1 link set eh1a up
ip -n h1 link set eh1b up
ip -n r1 link set lo up
ip -n r1 link set er1a up
ip -n r1 link set er1b up
ip -n r2 link set lo up
ip -n r2 link set er2a up
ip -n r2 link set er2b up
ip -n r3 link set lo up
ip -n r3 link set er3a up
ip -n r3 link set er3b up
ip -n r3 link set er3c up
ip -n r3 link set er3d up
ip -n r3 link set er3e up
ip -n r4 link set lo up
ip -n r4 link set er4a up
ip -n r4 link set er4b up
ip -n r5 link set lo up
ip -n r5 link set er5a up
ip -n r5 link set er5b up
ip -n r6 link set lo up
ip -n r6 link set er6a up
ip -n r6 link set er6b up
ip -n s1 link set lo up
ip -n s1 link set es1a up
ip -n s1 link set es1b up
ip -n s1 link set es1c up

ip link set eb1a up
ip link set eb1b up
ip link set eb2a up
ip link set eb2b up

# Configure the bandwidth and delay of each interface
ip netns exec h1 tc qdisc add dev eh1a root netem delay 5ms rate 10mbit
ip netns exec h1 tc qdisc add dev eh1b root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1a root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1b root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2a root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2b root netem delay 5ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3a root netem delay 5ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3b root netem delay 5ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3c root netem delay 5ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3d root netem delay 5ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3e root netem delay 5ms rate 10mbit
ip netns exec r4 tc qdisc add dev er4a root netem delay 5ms rate 10mbit
ip netns exec r4 tc qdisc add dev er4b root netem delay 5ms rate 10mbit
ip netns exec r5 tc qdisc add dev er5a root netem delay 5ms rate 10mbit
ip netns exec r5 tc qdisc add dev er5b root netem delay 5ms rate 10mbit
ip netns exec r6 tc qdisc add dev er6a root netem delay 5ms rate 10mbit
ip netns exec r6 tc qdisc add dev er6b root netem delay 5ms rate 10mbit
ip netns exec s1 tc qdisc add dev es1a root netem delay 5ms rate 10mbit
ip netns exec s1 tc qdisc add dev es1b root netem delay 5ms rate 10mbit
ip netns exec s1 tc qdisc add dev es1c root netem delay 5ms rate 10mbit

# Configure two routing tables for the two interfaces of host 'h1'
ip netns exec h1 ip rule add from 10.0.0.1 table 1
ip netns exec h1 ip rule add from 192.168.0.1 table 2

ip netns exec h1 ip route add 10.0.0.0/24 dev eh1a scope link table 1
ip netns exec h1 ip route add default via 10.0.0.2 dev eh1a table 1

ip netns exec h1 ip route add 192.168.0.0/24 dev eh1b scope link table 2
ip netns exec h1 ip route add default via 192.168.0.2 dev eh1b table 2

# ip netns exec h2 ip route add 12.0.0.2 via 10.0.1.2 dev eh2a
# ip netns exec h2 ip route add 12.0.1.2 via 10.0.2.2 dev eh2b

# Configure three routing tables for the three interfaces of server 's1'
ip netns exec s1 ip rule add from 10.0.3.2 table 3
ip netns exec s1 ip rule add from 11.0.1.2 table 4
ip netns exec s1 ip rule add from 192.168.3.2 table 5

ip netns exec s1 ip route add 10.0.3.0/24 dev es1a scope link table 3
ip netns exec s1 ip route add default via 10.0.3.1 dev es1a table 3

ip netns exec s1 ip route add 11.0.1.0/24 dev es1b scope link table 4
ip netns exec s1 ip route add default via 11.0.1.1 dev es1b table 4

ip netns exec s1 ip route add 192.168.3.0/24 dev es1c scope link table 5
ip netns exec s1 ip route add default via 192.168.3.1 dev es1c table 5

# Global Default route for 'h1' and 's1'
ip netns exec h1 ip route add default scope global nexthop via 10.0.0.2 dev eh1a
ip netns exec s1 ip route add default scope global nexthop via 192.168.3.1 dev es1c

# Configure the routing table of routers 'r1, 'r2', 'r4', 'r5' and 'r6'
ip netns exec r1 ip route add 10.0.0.1 via 10.0.0.1 dev er1a
ip netns exec r1 ip route add default via 10.0.1.2 dev er1b

ip netns exec r2 ip route add 192.168.0.1 via 192.168.0.1 dev er2a
ip netns exec r2 ip route add default via 192.168.1.2 dev er2b

ip netns exec r4 ip route add 10.0.3.2 via 10.0.3.2 dev er4b
ip netns exec r4 ip route add default via 10.0.2.1 dev er4a

ip netns exec r5 ip route add 11.0.1.2 via 11.0.1.2 dev er5b
ip netns exec r5 ip route add default via 11.0.0.1 dev er5a

ip netns exec r6 ip route add 192.168.3.2 via 192.168.3.2 dev er6b
ip netns exec r6 ip route add default via 192.168.2.1 dev er6a

# Configure the routing table of router 'r3'
ip netns exec r3 ip route add 10.0.0.1 via 10.0.1.1 dev er3a
ip netns exec r3 ip route add 192.168.0.1 via 192.168.1.1 dev er3b
ip netns exec r3 ip route add 10.0.3.2 via 10.0.2.2 dev er3c
ip netns exec r3 ip route add 11.0.1.2 via 11.0.0.2 dev er3d
ip netns exec r3 ip route add 192.168.3.2 via 192.168.2.2 dev er3e
ip netns exec r3 ip route add default via 192.168.2.2 dev er3e

# ip netns exec h1 ping -c 5 10.0.3.2
# ip netns exec h1 ping -c 5 11.0.1.2
# ip netns exec h1 ping -c 5 192.168.3.2

# Define subflows for MPTCP
ip -n h1 mptcp endpoint flush
ip -n h1 mptcp limits set subflow 6 add_addr_accepted 6
ip -n s1 mptcp endpoint flush
ip -n s1 mptcp limits set subflow 6 add_addr_accepted 6

# Path Management 'in-kernel' using ip mptcp
ip -n s1 mptcp endpoint add 192.168.3.2 dev es1c signal
ip -n s1 mptcp endpoint add 11.0.1.2 dev es1b signal
ip -n h1 mptcp endpoint add 192.168.0.1 dev eh1b subflow fullmesh
ip -n h1 mptcp endpoint add 10.0.0.1 dev eh1a subflow fullmesh

# Capture packets on the server 's1'
cd /home/dayma_khan/client
# mkdir captures
# ip netns exec s1 tshark -i es1a -w captures/master.pcap ---background
# ip netns exec s1 tshark -i es1b -w captures/subflow-1.pcap ---background
# ip netns exec s1 tshark -i es1c -w captures/subflow-2.pcap ---background

# Start the http server
cd /home/dayma_khan/Server
mptcpize run ip netns exec s1 python3.11 -m http.server --protocol HTTP/1.1 ---background

# Start the streaming on client
cd /home/dayma_khan/client
mptcpize run ip netns exec h1 gpac -i http://10.0.3.2:8000/dash/encode3/manifest.mpd:gpac:algo=grate:start_with=max_bw aout vout -logs=all@info -log-file=gpac_log.txt ---set-time-wait 2


