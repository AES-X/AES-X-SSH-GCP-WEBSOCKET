package main

import (
	"io"
	"net"
	"net/http"
	"os"
	"strings"
)

func handleConnection(w http.ResponseWriter, r *http.Request) {
	if strings.Contains(r.Header.Get("User-Agent"), "GoogleHC") {
		w.WriteHeader(http.StatusOK)
		return
	}
	if !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Proxy Engine Active"))
		return
	}
	hj, ok := w.(http.Hijacker)
	if !ok { return }
	client, bufrw, err := hj.Hijack()
	if err != nil { return }
	defer client.Close()

	bufrw.WriteString("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
	bufrw.Flush()

	target, err := net.Dial("tcp", "127.0.0.1:40000")
	if err != nil { return }
	defer target.Close()

	if tcp, ok := target.(*net.TCPConn); ok {
		tcp.SetNoDelay(true)
		tcp.SetKeepAlive(true)
	}

	done := make(chan struct{}, 2)

	go func() {
		buf := make([]byte, 32*1024)
		io.CopyBuffer(target, bufrw, buf)
		done <- struct{}{}
	}()

	go func() {
		buf := make([]byte, 32*1024)
		io.CopyBuffer(client, target, buf)
		done <- struct{}{}
	}()

	<-done
}

func main() {
	port := os.Getenv("PORT")
	if port == "" { port = "8080" }
	http.HandleFunc("/", handleConnection)
	http.ListenAndServe(":"+port, nil)
}

