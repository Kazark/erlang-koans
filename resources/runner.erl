-module(runner).
-export([lookup/0, test/0, run/0]).

lookup() ->
  try throw(purposeful_error)
  catch throw:purposeful_error ->
    StackTrace = erlang:get_stacktrace(),
    {Module, Function, _, _} = lists:nth(2, StackTrace),
    {_, Last} = lists:last(read_config()),
    {_, ModuleAnswers} = lists:keyfind(Module, 1, read_config()),
    {_, Answer} = lists:keyfind(Function, 1, ModuleAnswers),
    case Answer of
      {function, RawCode} ->
        eval(RawCode);
      _ ->
        Answer
    end
  end.

test() ->
  ModuleNames = lists:map(fun({Module, _}) -> atom_append(Module, '_test') end, read_config()),
  eunit:test(ModuleNames),
  halt().

run() ->
  Reporter = fun({Module, {Function, _}}) ->
               TestFunction = atom_append(Function, '_test'),
               TestModule = atom_append(Module, '_test'),
               try apply(TestModule, TestFunction, []) of
                 ok -> {ok, Module, Function, {}}
               catch
                 _:{Exception, Reason} ->
                   if
                     (Exception =:= assertion_failed) orelse (Exception =:= assertEqual_failed) ->
                       Expected = lists:keyfind(expected, 1, Reason),
                       Value = lists:keyfind(value, 1, Reason),
                       Line = lists:keyfind(line, 1, Reason),
                       {error, Module, Function, {Expected, Value, Line}};
                     true ->
                      {error, Module, Function, {Exception, Reason}}
                    end;
                 _:Reason -> {error, Module, Function, {failure, Reason}}
               end
             end,
  Report = excercise_all(read_config(), Reporter),
  case lists:keyfind(error, 1, Report) of
    false -> io:format("You have completed the Erlang Koans. Namaste.\n");
    {error, Module, Function, Reason} ->
      io:format("The following function failed its test:\n"),
      case Reason of
        {Expected, Actual, Line} ->
          erlang:display({Module, Function, Line}),
          io:format("For the following reason:\n"),
          erlang:display(Expected),
          erlang:display(Actual);
        {Exception, Reason} ->
          erlang:display({Module, Function}),
          io:format("With the exception"),
          erlang:display(Exception),
          erlang:display(Reason);
        AnyReason ->
          io:format("Something is majorly broken!"),
          erlang:display(AnyReason)
      end
  end,
  halt().

excercise_all(Answers, Reporter) ->
  excercise_all(Answers, Reporter, []).
excercise_all(Answers, Reporter, Report) ->
  if
    Answers == [] -> Report;
    true ->
      [ModuleAnswers | Tail] = Answers,
      excercise_all(Tail, Reporter, (Report ++ exercise_module(ModuleAnswers, Reporter)))
  end.

exercise_module(ModuleAnswers, Reporter) ->
  {ModuleName, FunctionAnswerKey} = ModuleAnswers,
  lists:map(Reporter, lists:map(fun(FunctionAnswer) -> {ModuleName, FunctionAnswer} end, FunctionAnswerKey)).

eval(RawCode) ->
  {ok, Tokens, _} = erl_scan:string(RawCode),
  {ok, [Form]} = erl_parse:parse_exprs(Tokens),
  Bindings = erl_eval:add_binding('B', 2, erl_eval:new_bindings()),
  {value, Fun, _} = erl_eval:expr(Form, Bindings),
  Fun.

atom_append(Atom1, Atom2) ->
  list_to_atom(atom_to_list(Atom1) ++ atom_to_list(Atom2)).

read_config() ->
  {ok, Config} = file:consult("resources/answers.config"),
  Config.

