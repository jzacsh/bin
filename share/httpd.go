package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
)

func main() {
	host := flag.String("host", "0.0.0.0", "Hostname to bind to")
	port := flag.Uint("port", 8080, "TCP Port to listen on")
	srcd := flag.String("src", "./", "Direcotry whose contents should be served")
	flag.Parse()

	boundTo := fmt.Sprintf("%s:%d", *host, *port)
	log.Printf("listening on %s & serving: %s\n", boundTo, *srcd)
	http.Handle("/", http.FileServer(http.Dir(*srcd)))
	http.ListenAndServe(boundTo, nil)
}
