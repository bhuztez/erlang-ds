-module(pque).

-export(
   [
    new/1,
    insert/2,
    peek/1,
    pop/1,
    from_iter/2,
    iter/1,
    from_list/2,
    to_list/1,
    test/0
   ]).


new(Mod) ->
    {?MODULE, Mod, Mod:empty()}.


insert(Elem, {?MODULE, Mod, Data}) ->
    Data1 = Mod:insert([Elem], Data),
    {?MODULE, Mod, Data1}.


peek({?MODULE, Mod, Data}) ->
    case Mod:peek(Data) of
        none ->
            none;
        {value, [Elem]} ->
            Elem
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
      fun insert/2,
      new(Mod),
      Iterator).


iter({pque, Mod, Data}) ->
    iterator:map(
      fun([Elem]) -> Elem end,
      Mod:iter(Data)).


from_list(List, Mod) ->
    from_iter(iterator:from_list(List), Mod).


to_list(Queue) ->
    iterator:to_list(iter(Queue)).


test(Mod) ->
    Queue = from_list([5,3,2,4,1], Mod),
    [1,2,3,4,5] = to_list(Queue).

test() ->
    test(leftist_tree),
    ok.
