/* Main */
:- use_module(library(http/websocket)).
:- use_module(library(http/json_convert)).
:- encoding(utf8).

sendState(WS):-
	findall(object(X, Y, V), valueObject(X, Y, V), Res),
	prolog_to_json(state(Res), J),
	ws_send(WS, json(J)).
	
valueObject(X, Y, V):- object(X, Y), value(X, V).
	
mainLoop(WS):-
	repeat,
	ws_receive(WS, Msg, [format(json)]),
	Cmd = Msg.data.'Cmd',
	Data = Msg.data.'Data',
	commandHandler(WS, Cmd, Data),
	fail.

serve():-
	URL = 'http://localhost:4242/data',
	http_open_websocket(URL, WS, []),
	mainLoop(WS).
	
finish(WS):-
	ws_close(WS, 1000, "Offline").
	
/* Command Handlers */
commandHandler(WS, "getState", _):- sendState(WS).
commandHandler(WS, "setState", JSONString):- setState(JSONString), sendState(WS).
commandHandler(WS, "runCode", Line) :- write("Running code..."), writeln(Line), evaluateCode(Line), sendState(WS).
commandHandler(WS, "getStats", _) :- 
	findall(object(X, Y, Z), stat(X, Y, Z), Stat),
	prolog_to_json(state(Stat), J),
	ws_send(WS, json(J)).
commandHandler(WS, "clearStats", _):- retractall(stat(_, _, _)), sendState(WS).	
commandHandler(WS, "close", _):- finish(WS).

setState(JSONString):-
	atom_string(JSONAtom, JSONString),
	json:atom_json_term(JSONAtom, State, []),
	State = json(J),
	Objects = J.'Objects',
	setStateLoop(Objects).
setStateLoop([]).
setStateLoop([H | T]):-
	H = json(J),
	Name = J.'Name',
	Value = J.'Value',
	setValue(Name, Value),
	setStateLoop(T).
	
evaluateCode(Line):-
	term_string(Cmd, Line),
	writeln('Checking term...'),
	(Cmd, true ; writeln('No Command found')),!,
	writeln('Done').

/* Utils */
pow(2, 8, 256).
pow(2, 16, 65536).

setValue(Who, Value):-
	consists(Who, High, Low),
	High \= nil,
	Low \= nil,
	capacity(High, HCap),
	HighValue is (Value >> HCap),
	setValue(High, HighValue),!,
	setValue(Low, Value - (HighValue * (2 >> HCap))), !.	
setValue(Who, Value):- 
	capacity(Who, Cap),!,
	value(Who, V), !,
	retract(value(Who, V)),
	pow(2, Cap, MValue),
	LimitedValue is Value mod MValue,
	asserta(value(Who, LimitedValue)).


:- json_object
	object(name: symbol, nature: symbol, value: integer).
:- json_object
	state(objects: list(object)).
:- json_object
	command(cmd: symbol, data: symbol).
/* Objects */
object(ah, register).
object(al, register).
object(ax, register).
object(bh, register).
object(bl, register).
object(bx, register).
object(dh, register).
object(dl, register).
object(dx, register).
object(bp, register).
object(sp, register).
object(si, register).
object(di, register).

/* Static Properties */
consists(ax, ah, al).
consists(ah, nil, nil).
consists(al, nil, nil).
consists(bx, bh, bl).
consists(bh, nil, nil).
consists(bl, nil, nil).
consists(dx, dh, dl).
consists(dh, nil, nil).
consists(dl, nil, nil).
consists(bp, nil, nil).
consists(sp, nil, nil).
consists(si, nil).
consists(di, nil).

capacity(nil, 0).
capacity(ah, 8).
capacity(al, 8).
capacity(bh, 8).
capacity(bl, 8).
capacity(dh, 8).
capacity(dl, 8).
capacity(bp, 16).
capacity(sp, 16).
capacity(si, 16).
capacity(di, 16).
capacity(word, 16).
capacity(byte, 8).
capacity(R, C):- consists(R, XH, XL), capacity(XH, XHC), capacity(XL, XLC), !, C is XHC + XLC.

/* Commands interface */
command(mov, To, From):- number(From),setValue(To, From), !, incStat('mov(регистр-число)', command), incStat(To, register).
command(mov, To, From):- value(From, V), setValue(To, V), !, incStat('mov(регистр-регистр)', command), incStat(To, register), incStat(From, register).
command(mov, From):- command(mov, From, ax).
command(inc, Reg):- value(Reg, V), setValue(Reg, V + 1), !, incStat('inc', command), incStat(Reg, register).
command(add, To, From):- number(From), value(To, V), setValue(To, V + From), !, incStat('add(регистр-число)', command), incStat(To, register).
command(add, To, From):- value(From, V1), value(To, V2), setValue(To, V1 + V2), !, incStat('add(регистр-регистр)', command), incStat(To, register), incStat(From, register).
command(push, Value):- number(Value), High is (Value >> 8), pushStack(High), Low is Value - (High * (2 ** 8)), pushStack(Low), !, incStat('push(число)', command),
	incStat('Память', register).
command(push, Reg):- value(Reg, V), !, capacity(Reg, Cap), pushByByte(V, Cap), !, incStat('push(регистр)', command), incStat(Reg, register), incStat('Память', register).
command(pop, Reg):- capacity(Reg, Cap), setValue(Reg, 0), !, popByByte(Reg, Cap), !, incStat('pop(регистр)', command), incStat(Reg, register).
command(mov, Size, ptr, '[', bp, '-', Shift, ']', Value):- number(Value),  capacity(Size, Cap), writeBytes(Value, Cap, Shift), !, incStat('mov(стек-число)', command), 
incStat('Память', register).
command(mov, Size, ptr, '[', bp, '-', Shift, ']', Reg):- value(Reg, V), !, command(mov, Size, ptr, '[', bp, '-', Shift, ']', V), !, 
	incStat('mov(стек-регистр)', command), incStat(Reg, register), incStat('Память', register).
command(mov, Reg, Size, ptr, '[', bp, '-', Shift, ']'):- capacity(Size, Cap), RShift is (Shift - (Cap // 8) + 1), 
	readBytes(V, 0, Cap, RShift), setValue(Reg, V), !, incStat('mov(регистр-стек)', command), incStat(Reg, register), incStat('Память', register).
command(sub, To, From):- number(From), value(To, V), setValue(To, V - From), !, incStat('sub(регистр-число)', command), incStat(To, register).
command(sub, To, From):- value(From, V1), value(To, V2), setValue(To, V1 - V2), !, incStat('sub(регистр-регистр)', command), incStat(To, register), incStat(From, register).

/* Documentary */
help(ax, "A 16-bit general purpose register").
help(ah, "An 8-bit top half of ax").
help(al, "An 8-bit bottom half of ax").
help(command(mov, to, from), "Moves data from 'from' to 'to'").
help(command(mov, to), "Moves data from 'from' to ax").
help(command(mov), Description):- help(command(mov, to), D1),
    help(command(mov, to, from), D2),
    Description = "Возможные команды: \n" + D1 + "\n" + D2.
    

/* Dynamic Properties */
:- dynamic value/2.

value(ah,1).
value(al, 16).
value(bh, 0).
value(bl, 0).
value(dh, 0).
value(dl, 0).
value(di, 0).
value(si, 0).
value(bp, 65535).
value(sp, 65535).
value(R, V):- consists(R, XH, XL), value(XH, Vah), !, value(XL, Val), !, capacity(XH, Cah),
    pow(2, Cah, Pah), V is (Vah * Pah) + Val.
	
:- dynamic stat/3.
incStat(Stat, Type):- stat(Stat, Type, Count), retract(stat(Stat, Type, Count)), NewCount is Count + 1,asserta(stat(Stat, Type, NewCount)), !.
incStat(Stat, Type):- asserta(stat(Stat, Type, 1)), !.

:- dynamic stack/2.
pushStack(V):- value(sp, A), !, NA is A - 1, setValue(sp, NA), !, asserta(stack(NA, V)).
pushByByte(V, Cap):- Cap = 8, !, pushStack(V).
pushByByte(V, Cap):- Byte is (V >> (Cap - 8)), pushStack(Byte), NCap is (Cap - 8), NValue is (V - (Byte * (2 ** (Cap - 8)))), pushByByte(NValue, NCap).
popStack(Byte):- value(sp, A), !, stack(A, Byte), !, NA is A + 1, setValue(sp, NA), !, retract(stack(A, Byte)).
popByByte(_, Cap):- Cap = 0, !.
popByByte(Reg, Cap):- popStack(Byte), capacity(Reg, C), Dif is (C - Cap), value(Reg, V), !, V2 is V + (Byte * (2 ** Dif)), setValue(Reg, V2), !, NCap is (Cap - 8), popByByte(Reg, NCap).

writeByte(Byte, Shift):- value(bp, V), !,  A is (V - Shift), (stack(A, Val), !, retract(stack(A, Val)) ; true), asserta(stack(A, Byte)).
writeBytes(_, Size, _):- Size = 0, !.
writeBytes(Value, Size, Shift):- Byte is (Value mod 256), writeByte(Byte, Shift), NValue is (Value >> 8),
NSize is (Size - 8), NShift is Shift - 1, writeBytes(NValue, NSize, NShift).
readByte(Byte, Shift):- value(bp, V), !, A is (V - Shift), (stack(A, Byte), ! ; Byte = 0).
readBytes(Res, Value, Size, _):- Size = 0, Res = Value, !.
readBytes(Res, Value, Size, Shift):- readByte(Byte, Shift), NValue is ((Value * (2 << 7)) + Byte), NSize is (Size - 8), NShift is (Shift + 1), readBytes(Res, NValue, NSize, NShift).

