package server

import (
	"encoding/json"
	"fmt"
	"github.com/graarh/golang-socketio"
	"log"
)

type stateMessage struct {
	Objects []object
	Code []string
}

const room string = "Clients"
var _server *gosocketio.Server

func emitClient(event string, args interface{}) {
	_server.BroadcastTo(room, event, args)
}

func setSockets(server *gosocketio.Server) {
	_server = server
	err := server.On(gosocketio.OnConnection, func(s *gosocketio.Channel, args interface{})  {
		log.Println("Новое соединение socket.io: ", s.Id())
		err := s.Join(room)

		if err != nil {
			log.Println("Не удалось добавить клиента в комнату Clients!")
		}
	})

	if err != nil {
		log.Println("Не удалось установить обработчик событию подключения!")
	}

	err = server.On(gosocketio.OnDisconnection, func(s *gosocketio.Channel) {
		err := s.Leave(room)

		if err != nil {
			log.Println("Не удалось отключить клиента от комнаты Clients!")
		}
	})

	if err != nil {
		log.Println("Не удалось подключиться на событие отключения!")
	}

	err = server.On("step", func (s *gosocketio.Channel) {
		fmt.Println("Step")
		opt.withDelay = false
		go step()
	})

	err = server.On("emulateDelayed", func (s *gosocketio.Channel, delay int) {
		fmt.Println("Emulate delayed: ", delay)
		opt.withDelay = true
		opt.delay = delay
		go step()
	})

	err = server.On("retrieveState", func (s *gosocketio.Channel) {
		fmt.Println("Retrieve State")
		sendCommand(command{Cmd: "getState",})
	})

	err = server.On("setState", func (s *gosocketio.Channel, msg string){
		fmt.Println("Set State: ", msg)

		stat := stateMessage{}
		err := json.Unmarshal([]byte(msg), &stat)

		if err != nil {
			fmt.Println("Unable to parse setState msg JSON: ", err)

			return
		}

		msgJSON := state{Objects: stat.Objects,}
		res, err := json.Marshal(msgJSON)

		setCode(stat.Code)

		sendCommand(command{Cmd: "setState", Data: string(res)})
	})
}