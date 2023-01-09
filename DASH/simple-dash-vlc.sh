#######################################
# Topology
#  _______	  10mbit, 5ms	 _______
# |	      |                 |	    | 
# |	 h1   |-----------------|   h2  |
# |_______|                 |_______|
#	
#######################################

#!/bin/sh
cd /home/abhinaba/Major/MPTCP/server

# Encode video for live streaming
# rm -rf ./dash/encode/*
# ffmpeg -y -i ./videos/nitk.mp4 -c:v copy -f dash -seg_duration 1 -streaming 1 -window_size 200 ./dash/encode/manifest.mpd

# Creating two namespaces
ip netns add h1
ip netns add h2

# creating the veth pair anc connecting them
ip link add eth0 type veth peer eth1
ip link set eth0 netns h1
ip link set eth1 netns h2

# Activating the interface cards in each namespaces
ip netns exec h1 ip link set lo up
ip netns exec h1 ip link set eth0 up
ip netns exec h2 ip link set lo up
ip netns exec h2 ip link set eth1 up

# Assigning IP address to the interfaces
ip netns exec h1 ip address add 10.0.0.1/24 dev eth0
ip netns exec h2 ip address add 10.0.0.2/24 dev eth1

# Configuring delay and bandwidth of the veth pair
ip netns exec h1 tc qdisc add dev eth0 root netem delay 5ms rate 10mbit
ip netns exec h2 tc qdisc add dev eth1 root netem delay 5ms rate 10mbit

# Start Http Server
ip netns exec h2 python3 -m http.server ---background

# Stream DASH from client
cd ../
ip netns exec h1 vlc http://10.0.0.2:8000/dash/encode/manifest.mpd ---set-time-wait 2