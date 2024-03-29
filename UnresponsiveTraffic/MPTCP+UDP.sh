############################################################################
# Topology
#  ____                                                           ______
# | h1 |------------                                       ------|  s1  |
# |____|            |                                     |      |______|
#                   |                                     |
#                   |  _____                     _____    |
#    -----------------| r1  |-------------------| r3  |------------
#  __|_               |_____|                   |_____|        ___|___  
# | h2 |                                                      |  s2   |
# |____|               _____                                  |_______|       
#    |----------------| r2  |                    _____            |
#                     |_____|-------------------| r4  |------------
#                      |                        |_____|  |
#   ____               |                                 |       _______
#  | h3 |---------------                                 -------|  s3   |
#  |____|                                                       |_______|
#
############################################################################

#!/bin/sh
cd /home/abhinaba/Major/MPTCP/server

# Create three hosts: h1, h2 and h3
ip netns add h1
ip netns add h2
ip netns add h3

# Create one server
ip netns add s1
ip netns add s2
ip netns add s3

# Create four routers
ip netns add r1
ip netns add r2
ip netns add r3
ip netns add r4

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on the network namespaces
ip netns exec s2 sysctl -w net.mptcp.enabled=1
ip netns exec h2 sysctl -w net.mptcp.enabled=1
ip netns exec s2 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h2 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec s2 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h2 sysctl -w net.mptcp.stale_loss_cnt=10

# Configuring the MPTCP option C flag
ip netns exec s2 sysctl -w net.mptcp.allow_join_initial_addr_port=1
ip netns exec h2 sysctl -w net.mptcp.allow_join_initial_addr_port=1

# Create the virtual ethernet (veth) pairs
ip link add eh1 netns h1 type veth peer name er1a netns r1
ip link add eh2a netns h2 type veth peer name er1b netns r1
ip link add eh2b netns h2 type veth peer name er2a netns r2
ip link add eh3 netns h3 type veth peer name er2b netns r2
ip link add er1c netns r1 type veth peer name er3b netns r3
ip link add er2c netns r2 type veth peer name er4b netns r4
ip link add er3a netns r3 type veth peer name es2a netns s2
ip link add er4a netns r4 type veth peer name es2b netns s2
ip link add er3c netns r3 type veth peer name es1 netns s1
ip link add er4c netns r4 type veth peer name es3 netns s3

# Assign IP addresses to interfaces
ip -n h1 address add 10.0.0.1/24 dev eh1
ip -n h2 address add 10.0.1.1/24 dev eh2a
ip -n h2 address add 10.0.2.1/24 dev eh2b
ip -n h3 address add 10.0.3.1/24 dev eh3
ip -n r1 address add 10.0.0.2/24 dev er1a
ip -n r1 address add 10.0.1.2/24 dev er1b
ip -n r1 address add 11.0.0.1/24 dev er1c
ip -n r2 address add 10.0.2.2/24 dev er2a
ip -n r2 address add 10.0.3.2/24 dev er2b
ip -n r2 address add 11.0.1.1/24 dev er2c
ip -n r3 address add 12.0.1.1/24 dev er3a
ip -n r3 address add 11.0.0.2/24 dev er3b
ip -n r3 address add 12.0.0.1/24 dev er3c
ip -n r4 address add 12.0.2.1/24 dev er4a
ip -n r4 address add 11.0.1.2/24 dev er4b
ip -n r4 address add 12.0.3.1/24 dev er4c
ip -n s1 address add 12.0.0.2/24 dev es1
ip -n s2 address add 12.0.1.2/24 dev es2a
ip -n s2 address add 12.0.2.2/24 dev es2b
ip -n s3 address add 12.0.3.2/24 dev es3

# Turn ON all ethernet devices
ip -n h1 link set lo up
ip -n h1 link set eh1 up 
ip -n h2 link set lo up
ip -n h2 link set eh2a up
ip -n h2 link set eh2b up
ip -n h3 link set lo up
ip -n h3 link set eh3 up

ip -n r1 link set lo up
ip -n r1 link set er1a up
ip -n r1 link set er1b up
ip -n r1 link set er1c up
ip -n r2 link set lo up
ip -n r2 link set er2a up
ip -n r2 link set er2b up
ip -n r2 link set er2c up
ip -n r3 link set lo up
ip -n r3 link set er3a up
ip -n r3 link set er3b up
ip -n r3 link set er3c up
ip -n r4 link set lo up
ip -n r4 link set er4a up
ip -n r4 link set er4b up
ip -n r4 link set er4c up

ip -n s1 link set lo up
ip -n s1 link set es1 up
ip -n s2 link set lo up
ip -n s2 link set es2a up
ip -n s2 link set es2b up
ip -n s3 link set lo up
ip -n s3 link set es3 up

# Configure the routing table of host 'h1' and 'h3'
ip netns exec h1 ip route add default via 10.0.0.2 dev eh1
ip netns exec h3 ip route add default via 10.0.3.2 dev eh3

# Create two routing tables for two interface of host 'h2'
ip netns exec h2 ip rule add from 10.0.1.1 table 1
ip netns exec h2 ip rule add from 10.0.2.1 table 2

# Configure the two routing tables of 'h2'
ip netns exec h2 ip route add 10.0.1.0/24 dev eh2a scope link table 1
ip netns exec h2 ip route add default via 10.0.1.2 dev eh2a table 1   

ip netns exec h2 ip route add 10.0.2.0/24 dev eh2b scope link table 2
ip netns exec h2 ip route add default via 10.0.2.2 dev eh2b table 2

# Create two routing tables for two interace of server 's2'
ip netns exec s2 ip rule add from 12.0.1.2 table 3
ip netns exec s2 ip rule add from 12.0.2.2 table 4

# Configure the two routing tables of 's2'
ip netns exec s2 ip route add 12.0.1.0/24 dev es2a scope link table 3
ip netns exec s2 ip route add default via 12.0.1.1 dev es2a table 3  

ip netns exec s2 ip route add 12.0.2.0/24 dev es2b scope link table 4
ip netns exec s2 ip route add default via 12.0.2.1 dev es2b table 4

# Global Default route for 'h2' and 's2'
ip netns exec h2 ip route add default scope global nexthop via 10.0.1.2 dev eh2a
ip netns exec s2 ip route add default scope global nexthop via 12.0.2.1 dev es2b

# Configure the routing table of router 'r1'
ip netns exec r1 ip route add 10.0.0.1 via 10.0.0.1 dev er1a
ip netns exec r1 ip route add 10.0.1.1 via 10.0.1.1 dev er1b
ip netns exec r1 ip route add default via 11.0.0.2 dev er1c

# Configure the routing table of router 'r2'
ip netns exec r2 ip route add 10.0.2.1 via 10.0.2.1 dev er2a
ip netns exec r2 ip route add 10.0.3.1 via 10.0.3.1 dev er2b
ip netns exec r2 ip route add default via 11.0.1.2 dev er2c

# Configure the routing table of router 'r3'
ip netns exec r3 ip route add default via 11.0.0.1 dev er3b
ip netns exec r3 ip route add 12.0.1.2 via 12.0.1.2 dev er3a
ip netns exec r3 ip route add 12.0.0.2 via 12.0.0.2 dev er3c

# Configure the routing table of router 'r4'
ip netns exec r4 ip route add default via 11.0.1.1 dev er4b
ip netns exec r4 ip route add 12.0.2.2 via 12.0.2.2 dev er4a
ip netns exec r4 ip route add 12.0.3.2 via 12.0.3.2 dev er4c

# Configure the routing table of server 's1' and 's3'
ip netns exec s1 ip route add default via 12.0.0.1 dev es1
ip netns exec s3 ip route add default via 12.0.3.1 dev es3

# Enable IP forwarding on the routers
ip netns exec r1 sysctl -w net.ipv4.ip_forward=1
ip netns exec r2 sysctl -w net.ipv4.ip_forward=1
ip netns exec r3 sysctl -w net.ipv4.ip_forward=1
ip netns exec r4 sysctl -w net.ipv4.ip_forward=1

# Configure Delay and Bandwidth for each interfaces
ip netns exec h1 tc qdisc add dev eh1 root netem delay 1ms rate 1000mbit
ip netns exec h2 tc qdisc add dev eh2a root netem delay 1ms rate 1000mbit 
ip netns exec h2 tc qdisc add dev eh2b root netem delay 1ms rate 1000mbit
ip netns exec h3 tc qdisc add dev eh3 root netem delay 1ms rate 1000mbit
ip netns exec r1 tc qdisc add dev er1a root netem delay 1ms rate 1000mbit
ip netns exec r1 tc qdisc add dev er1b root netem delay 1ms rate 1000mbit
ip netns exec r1 tc qdisc add dev er1c root netem delay 10ms rate 10mbit
ip netns exec r2 tc qdisc add dev er2a root netem delay 1ms rate 1000mbit
ip netns exec r2 tc qdisc add dev er2b root netem delay 1ms rate 1000mbit
ip netns exec r2 tc qdisc add dev er2c root netem delay 10ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3a root netem delay 1ms rate 1000mbit
ip netns exec r3 tc qdisc add dev er3b root netem delay 10ms rate 10mbit
ip netns exec r3 tc qdisc add dev er3c root netem delay 1ms rate 1000mbit
ip netns exec r4 tc qdisc add dev er4a root netem delay 1ms rate 1000mbit
ip netns exec r4 tc qdisc add dev er4b root netem delay 10ms rate 10mbit
ip netns exec r4 tc qdisc add dev er4c root netem delay 1ms rate 1000mbit
ip netns exec s1 tc qdisc add dev es1 root netem delay 1ms rate 1000mbit
ip netns exec s2 tc qdisc add dev es2a root netem delay 1ms rate 1000mbit
ip netns exec s2 tc qdisc add dev es2b root netem delay 1ms rate 1000mbit
ip netns exec s3 tc qdisc add dev es3 root netem delay 1ms rate 1000mbit

# Configure MPTCP Endpoints
ip -n h2 mptcp endpoint flush
ip -n h2 mptcp limits set subflow 2 add_addr_accepted 2

ip -n s2 mptcp endpoint flush
ip -n s2 mptcp limits set subflow 2 add_addr_accepted 2

# Path Management 'in-kernel' using ip mptcp
ip -n s2 mptcp endpoint add 12.0.2.2 dev es2b signal
ip -n h2 mptcp endpoint add 10.0.2.1 dev eh2b subflow fullmesh

# Capture pacteks at '' interface ''
# cd /home/abhinaba/Major/MPTCP/server
# mkdir captures
# ip netns exec s2 tshark -i es2a -w captures/es2a-cap.pcap ---background
# ip netns exec s2 tshark -i es2b -w captures/es2b-cap.pcap ---background

# Start UDP server on 's1'
cd /home/abhinaba/Major/MPTCP/server
ip netns exec s1 iperf -u -s -p 5001 ---background

# Start UDP server on 's3'
cd /home/abhinaba/Major/MPTCP/server
ip netns exec s3 iperf -u -s -p 5002 ---background

# Create servers on 's2'
cd /home/abhinaba/Major/MPTCP/server
mptcpize run ip netns exec s2 python3.11 -m http.server --protocol HTTP/1.1 ---background

# Change Directory to client
cd /home/abhinaba/Major/MPTCP/client

# Run UDP clients on 'h1'
ip netns exec h1 iperf -u -c 12.0.0.2 -p 5001 -b 9M -t 0 ---background
# ip netns exec h1 iperf -u -c 12.0.0.2 -p 5001 -b 1.5M -t 0 ---background
# ip netns exec h1 iperf -u -c 12.0.0.2 -p 5001 -b 1.5M -t 0 ---background
# ip netns exec h1 iperf -u -c 12.0.0.2 -p 5001 -b 1.5M -t 0 ---background
# ip netns exec h1 iperf -u -c 12.0.0.2 -p 5001 -b 1.5M -t 0 ---background

# Run UDP clients on 'h3'
ip netns exec h3 iperf -u -c 12.0.3.2 -p 5002 -b 9M -t 0 ---background
# ip netns exec h3 iperf -u -c 12.0.3.2 -p 5002 -b 1.5M -t 0 ---background
# ip netns exec h3 iperf -u -c 12.0.3.2 -p 5002 -b 1.5M -t 0 ---background
# ip netns exec h3 iperf -u -c 12.0.3.2 -p 5002 -b 1.5M -t 0 ---background
# ip netns exec h3 iperf -u -c 12.0.3.2 -p 5002 -b 1.5M -t 0 ---background

# Stream DASH using MPTCP from 'h2'
cd /home/abhinaba/Major/MPTCP/client
mptcpize run ip netns exec h2 gpac -i http://12.0.1.2:8000/dash/BigBuckBunny/15sec/simple_manifest.mpd:gpac:algo=gbuf:start_with=max_q vout:buffer=1000:mbuffer=10000 -logs=all@info -log-file=gpac_log.log ---set-time-wait 5
# mptcpize run ip netns exec h2 gpac -i http://12.0.1.2:8000/dash/BigBuckBunny/1sec/simple_manifest.mpd:gpac:algo=gbuf:start_with=max_q vout ---set-time-wait 5
