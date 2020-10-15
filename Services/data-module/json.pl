:- use_module(library(http/json_convert)).

:- json_object
	point(x: integer, y: integer).
	
do(Pnt):- point(X, Y), prolog_to_json(point(X, Y), Pnt).

point(10, 20).
point(20, 30).
