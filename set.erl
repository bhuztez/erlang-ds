-module(set).

-export(
   [
    new/1,
    is_element/2,
    add_element/2,
    del_element/2,
    from_iter/2,
    iter/1,
    from_list/2,
    to_list/1,
    test/0
   ]).


new(Mod) ->
    {?MODULE, Mod, Mod:empty()}.


is_element(Elem, {?MODULE, Mod, Data}) ->
    case Mod:lookup(Elem, Data) of
        none ->
            false;
        {value, _} ->
            true
    end.


add_element(Elem, {?MODULE, Mod, Data}) ->
    {insert, Data1} = Mod:enter([Elem], Data),
    {?MODULE, Mod, Data1}.


del_element(Elem, {?MODULE, Mod, Data} = Set) ->
    case Mod:delete(Elem, Data) of
        not_found ->
            Set;
        {deleted, Data1} ->
            {?MODULE, Mod, Data1}
    end.


from_iter(Iterator, Mod) ->
    iterator:foldl(
      fun add_element/2,
      new(Mod),
      Iterator).


iter({set, Mod, Data}) ->
    iterator:map(
      fun([Elem]) -> Elem end,
      Mod:iter(Data)).


from_list(List, Mod) ->
    from_iter(iterator:from_list(List), Mod).


to_list(Set) ->
    iterator:to_list(iter(Set)).


test(Mod) ->
    Set1 = from_list([1,3,5,7,9], Mod),
    [1,3,5,7,9] = to_list(Set1),
    Set2 = del_element(1, Set1),
    Set3 = add_element(2, Set2),
    Set4 = add_element(4, Set3),
    Set5 = add_element(6, Set4),
    Set6 = del_element(9, Set5),
    [2,3,4,5,6,7] = to_list(Set6),
    false = is_element(1, Set6),
    true = is_element(2, Set6).


test() ->
    test(bst),
    test(avl_tree),
    test(redblack_tree),
    ok.
