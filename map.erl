-module(map).

-export(
   [
    new/1,
    is_defined/2,
    lookup/2,
    enter/3,
    insert/3,
    update/3,
    delete/2,
    from_iter/2,
    iter/1,
    from_list/2,
    to_list/1,
    iter_keys/1,
    iter_values/1,
    keys/1,
    values/1,
    test/0
   ]).


new(Mod) ->
    {?MODULE, Mod, Mod:empty()}.


is_defined(Key, {?MODULE, Mod, Data}) ->
    case Mod:lookup(Key, Data) of
        none ->
            false;
        {value, _} ->
            true
    end.


lookup(Key, {?MODULE, Mod, Data}) ->
    case Mod:lookup(Key, Data) of
        none ->
            none;
        {value, [Key, Value]} ->
            {value, Value}
    end.


enter(Key, Value, {?MODULE, Mod, Data}) ->
    {_, Data1} = Mod:enter([Key, Value], Data),
    {?MODULE, Mod, Data1}.


insert(Key, Value, {?MODULE, Mod, Data}) ->
    {insert, Data1} = Mod:enter([Key, Value], Data),
    {?MODULE, Mod, Data1}.


update(Key, Value, {?MODULE, Mod, Data}) ->
    {update, Data1} = Mod:enter([Key, Value], Data),
    {?MODULE, Mod, Data1}.


delete(Key, {?MODULE, Mod, Data}=Map) ->
    case Mod:delete(Key, Data) of
        not_found ->
            Map;
        {deleted, Data1} ->
            {?MODULE, Mod, Data1}
    end.


from_iter(Iterator, Mod) ->
    iterator:foldl(
      fun ({Key, Value}, Map) ->
              insert(Key, Value, Map)
      end,
      new(Mod),
      Iterator).


iter({?MODULE, Mod, Data}) ->
    iterator:map(
      fun([Key, Value]) -> {Key, Value} end,
      Mod:iter(Data)).


from_list(List, Mod) ->
    from_iter(iterator:from_list(List), Mod).


to_list(Map) ->
    iterator:to_list(iter(Map)).


iter_keys({?MODULE, Mod, Data}) ->
    iterator:map(
      fun([Key, _]) -> Key end,
      Mod:iter(Data)).


keys(Map) ->
    iterator:to_list(iter_keys(Map)).


iter_values({?MODULE, Mod, Data}) ->
    iterator:map(
      fun([_, Value]) -> Value end,
      Mod:iter(Data)).


values(Map) ->
    iterator:to_list(iter_values(Map)).


test(Mod) ->
    Map1 = from_list([{1,2},{2,3},{3,4}], Mod),
    [{1,2},{2,3},{3,4}] = to_list(Map1),
    [1,2,3] = keys(Map1),
    [2,3,4] = values(Map1),
    true = is_defined(1, Map1),
    false = is_defined(0, Map1),
    Map2 = insert(4,5,Map1),
    {value, 5} = lookup(4, Map2),
    Map3 = update(4,6,Map2),
    {value, 6} = lookup(4, Map3),
    Map5 = delete(4, Map3),
    none = lookup(4, Map5),
    Map6 = enter(4, 7, Map5),
    {value, 7} = lookup(4, Map6),
    Map7 = enter(4, 8, Map6),
    {value, 8} = lookup(4, Map7).


test() ->
    test(bst),
    ok.
