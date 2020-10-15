package main

import "sync-module/server"

func main() {
	go server.Setup()
	server.MainLoop()
}