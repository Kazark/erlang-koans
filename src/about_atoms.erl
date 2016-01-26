-module(about_atoms).
-export([truth/0,
         truth_is_not_always_boolean/0,
         strings_are_not_atoms/0,
         however_atoms_might_look_like_a_string/0,
         atoms_are_the_basis_of_all_calls/0
        ]).

truth() ->
    true =:= true.

truth_is_not_always_boolean() ->
    is_atom(true) =:= true.

strings_are_not_atoms() ->
    is_atom("true") =:= false.

however_atoms_might_look_like_a_string() ->
    is_atom('true') =:= true.

atoms_are_the_basis_of_all_calls() ->
    apply(erlang, list_to_atom, ["erlang"]) =:= 'erlang'.

