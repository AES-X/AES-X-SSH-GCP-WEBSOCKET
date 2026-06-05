FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY proxy.go .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o proxy proxy.go

FROM alpine:3.19

RUN apk update && apk add --no-cache \
    tmux dropbear bash cmake make gcc g++ linux-headers

WORKDIR /workdir

COPY badvpn-src/ ./badvpn-src
COPY run.sh ./
COPY --from=builder /app/proxy ./

WORKDIR /workdir/badvpn-src/build
RUN cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) install

WORKDIR /workdir

RUN cat << 'EOF' > /etc/dropbear_banner
<center>
<br>
<font color="#FF9900">▬▬▬▬▬▬▬</font><big><big><big><b><font color="#FFFFFF"> 𝗡𝗘𝗧 </font><font color="#FF9900">𝗛𝗨𝗕 </font></b></big></big></big><font color="#FF9900">▬▬▬▬▬▬▬</font>
<br>
<b><font color="#AAAAAA">WELCOME TO PREMIUM SERVER</font></b>
<br>
<font color="#FF9900">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font>
<br>
<b><font color="#AAAAAA">SERVER RULES</font></b><br>
<font color="#FF3333">No Torrent  /  No DDOS  /  No Spam</font>
<br>
<font color="#FF9900">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font>
<br>
<b><font color="#AAAAAA">CHANNEL</font></b><br>
<font color="#FFFFFF">@NET_HUB</font><br>
<font color="#FFFFFF">t.me/NET_HUB</font>
<br>
<font color="#FF9900">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font>
<br>
<b><font color="#AAAAAA">MANAGEMENT</font></b><br>
<font color="#FFFFFF">Owner</font>  <font color="#FF9900">@N0T_ROBOT</font><br>
<font color="#FFFFFF">Admin</font>  <font color="#FF9900">@VOLTAGOO</font><br>
<font color="#FFFFFF">Admin</font>  <font color="#FF9900">@yalubloteba</font>
<br>
<font color="#FF9900">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font>
</center>
EOF

RUN rm -rf badvpn-src && \
    mkdir -p /etc/dropbear && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key && \
    adduser -D -s /bin/bash AES_X && \
    echo "AES_X:@NET_HUB" | chpasswd && \
    chmod +x /workdir/run.sh /workdir/proxy

RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

EXPOSE 8080
CMD ["./run.sh"]
