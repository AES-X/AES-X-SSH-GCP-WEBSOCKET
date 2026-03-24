#!/bin/bash
badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 &
dropbear -R -E -F -p 127.0.0.1:40000 -a -W 65535 &
sleep 1
./proxy

