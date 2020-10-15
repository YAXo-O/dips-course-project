package server

import (
	"github.com/graarh/golang-socketio"
	"github.com/graarh/golang-socketio/transport"
	"log"
	"net/http"

)

func Setup() {
	server := gosocketio.NewServer(transport.GetDefaultWebsocketTransport())


	setSockets(server)

	serveMux := http.NewServeMux()
	serveMux.Handle("/socket.io/", server)
	serveMux.Handle("/", http.FileServer(http.Dir("D:/Study/Диплом/visualisation-module/dist/")))
	serveMux.HandleFunc("/data/", setSocketDB)

	log.Println("Serving at localhost:4242...")
	log.Fatal(http.ListenAndServe(":4242", serveMux))
}