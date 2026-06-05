FROM golang:alpine AS builder
WORKDIR /app
COPY proxy.go .
RUN CGO_ENABLED=0 go build -o proxy proxy.go

FROM alpine
RUN apk update && apk add --no-cache tmux bash cmake make gcc g++ linux-headers \
    zlib-dev openssl-dev wget

WORKDIR /workdir
COPY badvpn-src/ ./badvpn-src
COPY run.sh ./
COPY --from=builder /app/proxy ./

# Build badvpn
WORKDIR /workdir/badvpn-src/build
RUN cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DCMAKE_BUILD_TYPE=Release && make -j2 install

# Build Dropbear 2013.60 from source with fake version
WORKDIR /tmp
RUN wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz2 && \
    tar xjf dropbear-2022.83.tar.bz2 && \
    cd dropbear-2022.83 && \
    sed -i 's/2022\.83/2013.60/g' configure.ac sysoptions.h Makefile.in 2>/dev/null || true && \
    sed -i 's/DROPBEAR_VERSION "2022.83"/DROPBEAR_VERSION "2013.60"/g' src/default_options.h 2>/dev/null || true && \
    sed -i 's/2022\.83/2013.60/g' src/runopts.h 2>/dev/null || true && \
    ./configure --disable-syslog && \
    make -j2 PROGRAMS="dropbear" && \
    make install && \
    cd /tmp && rm -rf dropbear-2022.83*

WORKDIR /workdir
RUN rm -rf badvpn-src && \
    mkdir -p /etc/dropbear && \
    dropbear -R 2>/dev/null || dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key

RUN adduser -D -s /bin/sh AES_X && \
    echo "AES_X:@NET_HUB" | chpasswd

RUN chmod +x /workdir/run.sh /workdir/proxy

RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

RUN cat > /etc/motd << 'BANNER'
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
BANNER

EXPOSE 8080
CMD ["./run.sh"]