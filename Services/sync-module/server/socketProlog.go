package server

import (
	"encoding/json"
	"github.com/gorilla/websocket"
	"log"
	"net/http"
)

var upgrader = websocket.Upgrader{} // use default options
var cmdChannel chan command

type command struct {
	Cmd string `json: "cmd"`
	Data string	`json: "data"`
}

type object struct {
	Name string `json: "name"`
	Nature string `json: "nature"`
	Value int `json: "value"`
}

type state struct {
	Objects []object `json: "objects"`
}

func setSocketDB(w http.ResponseWriter, r *http.Request) {
	c, err := upgrader.Upgrade(w, r, nil)

	if cmdChannel == nil {
		cmdChannel = make(chan command)
	}

	log.Println("New connection")

	if err != nil {
		log.Print("upgrade:", err)
		return
	}

	defer log.Println("Socket's closed")
	defer c.Close()

	for {
		select {
			case cmd := <- cmdChannel:
				writeCommand(&cmd, c)

				stat := state{}
				readJSON(&stat, c)

				for _, elem := range stat.Objects {
					log.Println(elem)
				}

				if cmd.Cmd == "getStats" {
					statChannel <- stat
					log.Println("Update Stats sent")
				} else {
					emitClient("updateState", stat)
					log.Println("Update State sent")
				}
		}
	}
}

func sendCommand(cmd command) {
	cmdChannel <- cmd
}

func writeCommand(cmd *command, conn *websocket.Conn) error {
	err := conn.WriteJSON(cmd)
	if err != nil {
		log.Println("Error occurred while writing JSON: ", err)
	}

	return err
}

func readJSON(v interface{}, conn *websocket.Conn) error {
	_, s, err := conn.ReadMessage()
	if err != nil {
		log.Println("Error while reading message: ", err)

		return err
	}

	err = json.Unmarshal(s, v)
	if err != nil {
		log.Println("Error while parsing JSON: ", err)

		return err
	}

	return nil
}
