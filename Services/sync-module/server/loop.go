package server

import (
	"fmt"
	"time"
)

type options struct {
	code []string
	evaluated []string
	pointer int
	delay int //msecs
	withDelay bool
}

var opt options

var control chan bool

func setCode(_code []string){
	opt.code = _code
	opt.pointer = -1
}

func step() {
	control <- true
}

func initLoop() {
	control = make(chan bool)
	opt = options{
		evaluated: make([]string, 0),
		pointer: -1,
		delay: 1500,
		withDelay: false,
	}
}

func delay() {
	if opt.withDelay {
		time.Sleep(time.Duration(opt.delay) * time.Millisecond)
		control <- true
	}
}

func MainLoop() {
	initLoop()
	for {
		fmt.Println("Ожидание ввода")
		go delay()
		<- control
		opt.pointer++
		if opt.pointer >= len(opt.code) {
			fmt.Println("Код выполнен")
			opt.pointer = -1
			opt.withDelay = false
			go gatherStatistics()
			continue
		}

		line := opt.code[opt.pointer]
		sendCommand(command{
			Cmd: "runCode",
			Data: line,
		}, )
		opt.evaluated = append(opt.evaluated, line)
		fmt.Println("Исполнение кода: ", line)
	}
}
