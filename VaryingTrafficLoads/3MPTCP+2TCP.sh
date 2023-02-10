#!/bin/sh

# Delete the existing interfaces/switches
ip link del b1
ip link del b2
ip link del b3
ip link del b4
ip link del b5
ip link del b6
ip link del b7
ip link del b8

# Create hosts/clients
ip netns add h1
ip netns add h2
ip netns add h3
ip netns add h4
ip netns add h5

# Create a server
ip netns add s1

# Create six routers
ip netns add r1
ip netns add r2
ip netns add r3
ip netns add r4
ip netns add r5
ip netns add r6

# Create eight switches
ip link add b1 type bridge
ip link set dev b1 up
ip link add b2 type bridge
ip link set dev b2 up
ip link add b3 type bridge
ip link set dev b3 up
ip link add b4 type bridge
ip link set dev b4 up
ip link add b5 type bridge
ip link set dev b5 up
ip link add b6 type bridge
ip link set dev b6 up
ip link add b7 type bridge
ip link set dev b7 up
ip link add b8 type bridge
ip link set dev b8 up

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on the hosts 'h2', 'h3', 'h4' and server 's1'
ip netns exec s1 sysctl -w net.mptcp.enabled=1
ip netns exec h2 sysctl -w net.mptcp.enabled=1
ip netns exec h3 sysctl -w net.mptcp.enabled=1
ip netns exec h4 sysctl -w net.mptcp.enabled=1
ip netns exec s1 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h2 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h3 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h4 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec s1 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h2 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h3 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h4 sysctl -w net.mptcp.stale_loss_cnt=10

# Configuring the C flag
ip netns exec s1 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h2 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h3 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h4 sysctl -w net.mptcp.allow_join_initial_addr_port=1

# Enable ip forwarding on the routers
ip netns exec r1 sysctl -w net.ipv4.ip_forward=1
ip netns exec r2 sysctl -w net.ipv4.ip_forward=1
ip netns exec r3 sysctl -w net.ipv4.ip_forward=1
ip netns exec r4 sysctl -w net.ipv4.ip_forward=1
ip netns exec r5 sysctl -w net.ipv4.ip_forward=1
ip netns exec r6 sysctl -w net.ipv4.ip_forward=1

# Create the virtual ethernet (veth) pairs
ip link add eh1 type veth peer name eb1a
ip link add eb1b type veth peer name er1a
ip link set eh1 netns h1
ip link set eb1a master b1
ip link set eb1b master b1
ip link set er1a netns r1

ip link add eh2a type veth peer name eb2a 
ip link add eb2b type veth peer name er1b
ip link set eh2a netns h2
ip link set eb2a master b2
ip link set eb2b master b2
ip link set er1b netns r1

ip link add eh2b type veth peer name eb3a
ip link add eb3b type veth peer name er2a
ip link set eh2b netns h2
ip link set eb3a master b3
ip link set eb3b master b3
ip link set er2a netns r2

ip link add eh3a type veth peer name eb4a
ip link add eb4b type veth peer name er1c
ip link set eh3a netns h3
ip link set eb4a master b4
ip link set eb4b master b4
ip link set er1c netns r1

ip link add eh3b type veth peer name eb5a
ip link add eb5b type veth peer name er2b
ip link set eh3b netns h3
ip link set eb5a master b5
ip link set eb5b master b5
ip link set er2b netns r2

ip link add eh4a type veth peer name eb6a
ip link add eb6b type veth peer name er1d
ip link set eh4a netns h4
ip link set eb6a master b6
ip link set eb6b master b6
ip link set er1d netns r1

ip link add eh4b type veth peer name eb7a
ip link add eb7b type veth peer name er2c
ip link set eh4b netns h4
ip link set eb7a master b7
ip link set eb7b master b7
ip link set er2c netns r2

ip link add eh5 type veth peer name eb8a
ip link add eb8b type veth peer name er2d
ip link set eh5 netns h5
ip link set eb8a master b8
ip link set eb8b master b8
ip link set er2d netns r2

ip link add er1e netns r1 type veth peer name er3a netns r3
ip link add er2e netns r2 type veth peer name er3b netns r3
ip link add er3c netns r3 type veth peer name er4a netns r4
ip link add er3d netns r3 type veth peer name er5a netns r5
ip link add er3e netns r3 type veth peer name er6a netns r6
ip link add er4b netns r4 type veth peer name es1a netns s1
ip link add er5b netns r5 type veth peer name es1b netns s1
ip link add er6b netns r6 type veth peer name es1c netns s1

# Assign IP addresses to the interfaces
ip -n h1 address add 10.0.0.1/24 dev eh1
ip -n h2 address add 11.0.0.1/24 dev eh2a
ip -n h2 address add 12.0.0.1/24 dev eh2b
ip -n h3 address add 13.0.0.1/24 dev eh3a
ip -n h3 address add 14.0.0.1/24 dev eh3b
ip -n h4 address add 15.0.0.1/24 dev eh4a
ip -n h4 address add 16.0.0.1/24 dev eh4b
ip -n h5 address add 17.0.0.1/24 dev eh5

ip -n r1 address add 10.0.0.2/24 dev er1a
ip -n r1 address add 11.0.0.2/24 dev er1b
ip -n r1 address add 13.0.0.2/24 dev er1c
ip -n r1 address add 15.0.0.2/24 dev er1d
ip -n r1 address add 10.0.1.1/24 dev er1e

ip -n r2 address add 12.0.0.2/24 dev er2a
ip -n r2 address add 14.0.0.2/24 dev er2b
ip -n r2 address add 16.0.0.2/24 dev er2c
ip -n r2 address add 17.0.0.2/24 dev er2d
ip -n r2 address add 17.0.1.1/24 dev er2e

ip -n r3 address add 10.0.1.2/24 dev er3a
ip -n r3 address add 17.0.1.2/24 dev er3b
ip -n r3 address add 10.0.2.1/24 dev er3c
ip -n r3 address add 14.0.1.1/24 dev er3d
ip -n r3 address add 17.0.2.1/24 dev er3e

ip -n r4 address add 10.0.2.2/24 dev er4a
ip -n r4 address add 10.0.3.1/24 dev er4b
ip -n r5 address add 14.0.1.2/24 dev er5a
ip -n r5 address add 14.0.2.1/24 dev er5b
ip -n r6 address add 17.0.2.2/24 dev er6a
ip -n r6 address add 17.0.3.1/24 dev er6b

ip -n s1 address add 10.0.3.2/24 dev es1a
ip -n s1 address add 14.0.2.2/24 dev es1b
ip -n s1 address add 17.0.3.2/24 dev es1c

# Turn ON the links/interfaces
ip link set eb1a up
ip link set eb1b up
ip link set eb2a up
ip link set eb2b up 
ip link set eb3a up
ip link set eb3b up
ip link set eb4a up
ip link set eb4b up
ip link set eb5a up
ip link set eb5b up
ip link set eb6a up
ip link set eb6b up
ip link set eb7a up 
ip link set eb7b up 
ip link set eb8a up
ip link set eb8b up

ip -n h1 link set lo up
ip -n h1 link set eh1 up

ip -n h2 link set lo up
ip -n h2 link set eh2a up
ip -n h2 link set eh2b up

ip -n h3 link set lo up
ip -n h3 link set eh3a up
ip -n h3 link set eh3b up

ip -n h4 link set lo up
ip -n h4 link set eh4a up
ip -n h4 link set eh4b up

ip -n h5 link set lo up
ip -n h5 link set eh5 up

ip -n r1 link set lo up
ip -n r1 link set er1a up
ip -n r1 link set er1b up
ip -n r1 link set er1c up
ip -n r1 link set er1d up
ip -n r1 link set er1e up

ip -n r2 link set lo up
ip -n r2 link set er2a up
ip -n r2 link set er2b up
ip -n r2 link set er2c up
ip -n r2 link set er2d up
ip -n r2 link set er2e up

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

# Configure the bandwidth and delay of the interfaces
ip netns exec h1 tc qdisc add dev eh1 root netem delay 5ms rate 10mbit
ip netns exec h2 tc qdisc add dev eh2a root netem delay 5ms rate 10mbit
ip netns exec h2 tc qdisc add dev eh2b root netem delay 5ms rate 10mbit
ip netns exec h3 tc qdisc add dev eh3a root netem delay 5ms rate 10mbit
ip netns exec h3 tc qdisc add dev eh3b root netem delay 5ms rate 10mbit
ip netns exec h4 tc qdisc add dev eh4a root netem delay 5ms rate 10mbit
ip netns exec h4 tc qdisc add dev eh4b root netem delay 5ms rate 10mbit
ip netns exec h5 tc qdisc add dev eh5 root netem delay 5ms rate 10mbit

ip netns exec r1 tc qdisc add dev er1a root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1b root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1c root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1d root netem delay 5ms rate 10mbit
ip netns exec r1 tc qdisc add dev er1e root netem delay 5ms rate 10mbit

ip netns exec r2 tc qdisc add dev er2a root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2b root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2c root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2d root netem delay 5ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2e root netem delay 5ms rate 10mbit

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

# Configure the routing table of 'h1' and 'h2'
ip netns exec h1 ip route add default via 10.0.0.2 dev eh1
ip netns exec h5 ip route add default via 17.0.0.2 dev eh5

# Configure two routing tables for the two interfaces of host 'h2'
ip netns exec h2 ip rule add from 11.0.0.1 table 1
ip netns exec h2 ip rule add from 12.0.0.1 table 2

ip netns exec h2 ip route add 11.0.0.0/24 dev eh2a scope link table 1
ip netns exec h2 ip route add default via 11.0.0.2 dev eh2a table 1

ip netns exec h2 ip route add 12.0.0.0/24 dev eh2b scope link table 2
ip netns exec h2 ip route add default via 12.0.0.2 dev eh2b table 2

# Configure two routing tables for the two interfaces of host 'h3'
ip netns exec h3 ip rule add from 13.0.0.1 table 3
ip netns exec h3 ip rule add from 14.0.0.1 table 4

ip netns exec h3 ip route add 13.0.0.0/24 dev eh3a scope link table 3
ip netns exec h3 ip route add default via 13.0.0.2 dev eh3a table 3

ip netns exec h3 ip route add 14.0.0.0/24 dev eh3b scope link table 4
ip netns exec h3 ip route add default via 14.0.0.2 dev eh3b table 4

# Configure two routing tables for the two interfaces of host 'h4'
ip netns exec h4 ip rule add from 15.0.0.1 table 5
ip netns exec h4 ip rule add from 16.0.0.1 table 6

ip netns exec h4 ip route add 15.0.0.0/24 dev eh4a scope link table 5
ip netns exec h4 ip route add default via 15.0.0.2 dev eh4a table 5

ip netns exec h4 ip route add 16.0.0.0/24 dev eh4b scope link table 6
ip netns exec h4 ip route add default via 16.0.0.2 dev eh4b table 6

# Configure the routing tables of server 's1'
ip netns exec s1 ip rule add from 10.0.3.2 table 7
ip netns exec s1 ip rule add from 14.0.2.2 table 8
ip netns exec s1 ip rule add from 17.0.3.2 table 9

ip netns exec s1 ip route add 10.0.3.0/24 dev es1a scope link table 7
ip netns exec s1 ip route add default via 10.0.3.1 dev es1a table 7

ip netns exec s1 ip route add 14.0.2.0/24 dev es1b scope link table 8
ip netns exec s1 ip route add default via 14.0.2.1 dev es1b table 8

ip netns exec s1 ip route add 17.0.3.0/24 dev es1c scope link table 9
ip netns exec s1 ip route add default via 17.0.3.1 dev es1c table 9

# Global Default route for 'h2', 'h3', 'h4', and 's1'
ip netns exec h2 ip route add default scope global nexthop via 11.0.0.2 dev eh2a
ip netns exec h3 ip route add default scope global nexthop via 14.0.0.2 dev eh3b
ip netns exec h4 ip route add default scope global nexthop via 16.0.0.2 dev eh4b
ip netns exec s1 ip route add default scope global nexthop via 14.0.2.1 dev es1b

# Configure the routing table of routers
ip netns exec r1 ip route add 10.0.0.1 via 10.0.0.1 dev er1a
ip netns exec r1 ip route add 11.0.0.1 via 11.0.0.1 dev er1b
ip netns exec r1 ip route add 13.0.0.1 via 13.0.0.1 dev er1c
ip netns exec r1 ip route add 15.0.0.1 via 15.0.0.1 dev er1d
ip netns exec r1 ip route add default via 10.0.1.2 dev er1e

ip netns exec r2 ip route add 12.0.0.1 dev 12.0.0.1 dev er2a
ip netns exec r2 ip route add 14.0.0.1 dev 14.0.0.1 dev er2b
ip netns exec r2 ip route add 16.0.0.1 dev 16.0.0.1 dev er2c
ip netns exec r2 ip route add 17.0.0.1 dev 17.0.0.1 dev er2d
ip netns exec r2 ip route add default via 17.0.1.2 dev er2e

ip netns exec r3 ip route add 10.0.0.1 via 10.0.1.1 dev er3a
ip netns exec r3 ip route add 11.0.0.1 via 10.0.1.1 dev er3a
ip netns exec r3 ip route add 13.0.0.1 via 10.0.1.1 dev er3a
ip netns exec r3 ip route add 15.0.0.1 via 10.0.1.1 dev er3a
ip netns exec r3 ip route add 12.0.0.1 via 17.0.1.1 dev er3b
ip netns exec r3 ip route add 14.0.0.1 via 17.0.1.1 dev er3b
ip netns exec r3 ip route add 16.0.0.1 via 17.0.1.1 dev er3b
ip netns exec r3 ip route add 17.0.0.1 via 17.0.1.1 dev er3b
ip netns exec r3 ip route add 10.0.3.2 via 10.0.2.2 dev er3c
ip netns exec r3 ip route add 14.0.2.2 via 14.0.1.2 dev er3d
ip netns exec r3 ip route add 17.0.3.2 via 17.0.2.2 dev er3e

ip netns exec r4 ip route add 10.0.3.2 via 10.0.3.2 dev er4b
ip netns exec r4 ip route add default via 10.0.2.1 dev er4a

ip netns exec r5 ip route add 14.0.2.2 via 14.0.2.2 dev er5b
ip netns exec r5 ip route add default via 14.0.1.1 dev er5a

ip netns exec r6 ip route add 17.0.3.2 via 17.0.3.2 dev er6b
ip netns exec r6 ip route add default via 17.0.2.1 dev er6a

# Define subflows for MPTCP
ip -n h2 mptcp endpoint flush
ip -n h2 mptcp limits set subflow 6 add_addr_accepted 6
ip -n h3 mptcp endpoint flush
ip -n h3 mptcp limits set subflow 6 add_addr_accepted 6
ip -n h4 mptcp endpoint flush
ip -n h4 mptcp limits set subflow 6 add_addr_accepted 6
ip -n s1 mptcp endpoint flush
ip -n s1 mptcp limits set subflow 6 add_addr_accepted 6

# Path Management 'in-kernel' using ip mptcp
ip -n s1 mptcp endpoint add 14.0.2.2 dev es1b signal
ip -n s1 mptcp endpoint add 17.0.3.2 dev es1c signal

ip -n h2 mptcp endpoint add 12.0.0.1 dev eh2b subflow fullmesh
ip -n h2 mptcp endpoint add 11.0.0.1 dev eh2a subflow fullmesh

ip -n h3 mptcp endpoint add 14.0.0.1 dev eh3b subflow fullmesh
ip -n h3 mptcp endpoint add 13.0.0.1 dev eh3a subflow fullmesh

ip -n h4 mptcp endpoint add 16.0.0.1 dev eh4b subflow fullmesh
ip -n h4 mptcp endpoint add 15.0.0.1 dev eh4a subflow fullmesh

# Start the http server
cd /home/abhinaba/Major/MPTCP/server
# mptcpize run ip netns exec s1 iperf -s ---background
mptcpize run ip netns exec s1 python3.11 -m http.server --protocol HTTP/1.1 ---background

# Start video streaming 
cd /home/abhinaba/Major/MPTCP/client
# mkdir captures
# ip netns exec s1 tshark -i es1a -w captures/master.pcap ---background
# ip netns exec s1 tshark -i es1b -w captures/subflow-1.pcap ---background
# ip netns exec s1 tshark -i es1c -w captures/subflow-2.pcap ---background

# mptcpize run ip netns exec h2 iperf -c 10.0.3.2 ---background
# mptcpize run ip netns exec h3 iperf -c 10.0.3.2 ---background
# mptcpize run ip netns exec h4 iperf -c 10.0.3.2
# mptcpize run ip netns exec h2 gpac -i http://10.0.3.2:8000/dash/BigBuckBunny/2sec/simple_manifest.mpd:gpac:algo=grate:start_with=max_bw aout vout:buffer=1000:mbuffer=10000 -logs=all@info -log-file=gpac_log1.log ---set-time 1
# mptcpize run ip netns exec h3 gpac -i http://10.0.3.2:8000/dash/BigBuckBunny/2sec/simple_manifest.mpd:gpac:algo=grate:start_with=max_bw aout vout:buffer=1000:mbuffer=10000 -logs=all@info -log-file=gpac_log2.log ---set-time 1
mptcpize run ip netns exec h4 gpac -i http://10.0.3.2:8000/dash/BigBuckBunny/2sec/simple_manifest.mpd:gpac:algo=grate:start_with=max_bw aout vout:buffer=1000:mbuffer=10000 -logs=all@info -log-file=gpac_log3.log 