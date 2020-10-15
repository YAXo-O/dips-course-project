:- use_module(library(http/websocket)).

connect(Reply):-
	URL = 'http://localhost:4242/data',
	http_open_websocket(URL, WS, []),
	ws_send(WS, text('Hello, World!')),
	ws_receive(WS, Reply),
	ws_close(WS, 1000, "Goodbye").