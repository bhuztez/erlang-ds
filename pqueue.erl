-module(pqueue).

-export(
   [
    new/1,
    insert/3,
    peek/1,
    pop/1,
    from_iter/2,
    iter/1,
    from_list/2,
    to_list/1,
    iter_values/1,
    values/1,
    test/0
   ]).


new(Mod) ->
    {?MODULE, Mod, Mod:empty()}.


insert(Priority, Elem, {?MODULE, Mod, Data}) ->
    Data1 = Mod:insert([Priority, Elem], Data),
    {?MODULE, Mod, Data1}.


peek({?MODULE, Mod, Data}) ->
    case Mod:peek(Data) of
        none ->
            none;
        {value, [Priority, Elem]} ->
            {Priority, Elem}
    end.


pop({?MODULE, Mod, Data}) ->
    case Mod:pop(Data) of
        empty ->
            empty;
        {ok, Data1} ->
            {ok, {?MODULE, Mod, Data1}}
    end.


from_iter(Iterator, Mod) ->
    iterator:foldl(
      fun ({Priority, Elem}, Queue) ->
              insert(Priority, Elem, Queue)
      end,
      new(Mod),
      Iterator).


iter({?MODULE, Mod, Data}) ->
    iterator:map(
      fun([Priority, Elem]) -> {Priority, Elem} end,
      Mod:iter(Data)).


from_list(List, Mod) ->
    from_iter(iterator:from_list(List), Mod).


to_list(Queue) ->
    iterator:to_list(iter(Queue)).


iter_values({?MODULE, Mod, Data}) ->
    iterator:map(
      fun([_, Elem]) -> Elem end,
      Mod:iter(Data)).


values(Queue) ->
    iterator:to_list(iter_values(Queue)).


test(Mod) ->
    Queue = from_list([{5,1},{3,2},{2,3},{4,4},{1,5}], Mod),
    [{1,5},{2,3},{3,2},{4,4},{5,1}] = to_list(Queue),
    [5,3,2,4,1] = values(Queue).


test() ->
    test(leftist_tree),
    ok.
