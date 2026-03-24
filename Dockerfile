FROM golang:alpine AS builder
WORKDIR /app
COPY proxy.go .
RUN CGO_ENABLED=0 go build -o proxy proxy.go

FROM alpine
RUN apk update && apk add --no-cache tmux dropbear bash cmake make gcc g++ linux-headers
WORKDIR /workdir
COPY badvpn-src/ ./badvpn-src
COPY run.sh ./
COPY --from=builder /app/proxy ./
WORKDIR /workdir/badvpn-src/build
RUN cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 -DCMAKE_BUILD_TYPE=Release && make -j2 install
WORKDIR /workdir
RUN rm -rf badvpn-src && \
    mkdir -p /etc/dropbear && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key

RUN adduser -D -s /bin/sh AES_X && \
    echo "AES_X:@NET_HUB" | chpasswd

RUN chmod +x /workdir/run.sh /workdir/proxy

RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
RUN echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

EXPOSE 8080
CMD ["./run.sh"]

