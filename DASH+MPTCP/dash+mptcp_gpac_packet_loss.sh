#######################################
# Topology
#  _______	  10mbit, 5ms	 _______
# |	      |-----------------|	    | 
# |	 h1   |					|   h2  |
# |_______|-----------------|_______|
#			  5mbit, 10ms	
#######################################

#!/bin/sh

# Encode video for live streaming
cd /home/abhinaba/Major/MPTCP/server/
# rm -rf dash/encode/*
# ffmpeg -y -i ./videos/nitk.mp4 -c:v copy -f dash -seg_duration 1 -streaming 1 -window_size 170 ./dash/encode/manifest.mpd

#Create two network namespaces: h1 and h2
ip netns add h1
ip netns add h2

# Disable the reverse path filtering
sysctl -w net.ipv4.conf.all.rp_filter=0

# Enable MPTCP on both the network namespaces
ip netns exec h2 sysctl -w net.mptcp.enabled=1
ip netns exec h1 sysctl -w net.mptcp.enabled=1
ip netns exec h1 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h2 sysctl -w net.mptcp.checksum_enabled=1
ip netns exec h1 sysctl -w net.mptcp.stale_loss_cnt=10
ip netns exec h2 sysctl -w net.mptcp.stale_loss_cnt=10

# Create two virtual ethernet (veth) pairs between h1 and h2
ip link add eth1a netns h1 type veth peer eth2a netns h2
ip link add eth1b netns h1 type veth peer eth2b netns h2

# Assign IP address to each interface on h1
ip -n h1 address add 10.0.0.1/24 dev eth1a
ip -n h1 address add 192.168.0.1/24 dev eth1b

# Assign IP address to each interface on h2
ip -n h2 address add 10.0.0.2/24 dev eth2a
ip -n h2 address add 192.168.0.2/24 dev eth2b

# Set the data rate and delay on the veth devices at h1
ip netns exec h1 tc qdisc add dev eth1a root netem delay 5ms rate 10mbit
ip netns exec h1 tc qdisc add dev eth1b root netem delay 10ms rate 5mbit

# Set the data rate and delay on the veth devices at h2
ip netns exec h2 tc qdisc add dev eth2a root netem delay 5ms rate 10mbit
ip netns exec h2 tc qdisc add dev eth2b root netem delay 10ms rate 5mbit

# Turn ON all ethernet devices
ip -n h1 link set lo up
ip -n h2 link set lo up
ip -n h1 link set eth1a up
ip -n h1 link set eth1b up
ip -n h2 link set eth2a up
ip -n h2 link set eth2b up

# Define subflows for MPTCP
ip -n h1 mptcp endpoint flush
ip -n h1 mptcp limits set subflow 3 add_addr_accepted 3

ip -n h2 mptcp endpoint flush
ip -n h2 mptcp limits set subflow 3 add_addr_accepted 3

ip -n h2 mptcp endpoint add 192.168.0.2 dev eth2b id 1 signal
ip -n h1 mptcp endpoint add 192.168.0.1 dev eth1b id 1 fullmesh

# Create Routing rules for h1
ip netns exec h1 ip rule add from 10.0.0.1 table 1
ip netns exec h1 ip rule add from 192.168.0.1 table 2

ip netns exec h1 ip route add 10.0.0.0/24 dev eth1a scope link table 1
ip netns exec h1 ip route add default via 10.0.0.2 dev eth1a table 1

ip netns exec h1 ip route add 192.168.0.0/24 dev eth1b scope link table 2
ip netns exec h1 ip route add default via 192.168.0.2 dev eth1b table 2

# Creating Routing rules for h2
ip netns exec h2 ip rule add from 10.0.0.2 table 3
ip netns exec h2 ip rule add from 192.168.0.2 table 4

ip netns exec h2 ip route add 10.0.0.0/24 dev eth2a scope link table 3
ip netns exec h2 ip route add default via 10.0.0.1 dev eth2a table 3

ip netns exec h2 ip route add 192.168.0.0/24 dev eth2b scope link table 4
ip netns exec h2 ip route add default via 192.168.0.1 dev eth2b table 4

# Adding delay and error, and reordering the packets
ip netns exec h1 tc qdisc add dev eth1a root netem delay 100ms 10ms 20% rate 10mbit corrupt 10% 50% reorder 25% 50%
ip netns exec h1 tc qdisc add dev eth1b root netem delay 100ms 10ms 20% rate 10mbit corrupt 10% 50% reorder 25% 50%

# Test by turning off the interface
ip netns exec h1 ip link set dev eth1a down ---set-time 20
ip netns exec h1 ip link set dev eth1a up ---set-time 40

# Capture packets at h2
mkdir -p captures
ip netns exec h2 tshark -i eth2a -w captures/master.pcap ---background
ip netns exec h2 tshark -i eth2b -w captures/subflow.pcap ---background

# Start Http Server
ip netns exec h2 nstat > nstatbefore.txt
mptcpize run ip netns exec h2 python3.11 -m http.server --protocol HTTP/1.1 ---background

# Stream DASH from client
cd ../client
mptcpize run ip netns exec h2 gpac -i http://10.0.0.2:8000/dash/BigBuckBunny/2sec/simple_manifest.mpd:gpac:algo=gbuf:start_with=min_bw aout vout:buffer=1000:mbuffer=10000 -logs=all@info -log-file=gpac_log.log ---set-time-wait 3

# Capture network statistics after
cd ../server
ip netns exec h2 nstat > nstatafter.txt