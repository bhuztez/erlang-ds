-module(leftist_tree).

-export(
   [
    is_valid/1,
    empty/0,
    is_empty/1,
    merge/2,
    insert/2,
    peek/1,
    pop/1,
    iter/1
   ]).


-type tree(K, V) :: 'leaf'
                  | {'tree', pos_integer(), [K|V], tree(K,V), tree(K,V)}.


-spec is_valid(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_valid(leaf) ->
    true;
is_valid({tree, Dist, [Key|_], Left, Right}) ->
    lists:all(
      [
       Dist == dist(Right) + 1,
       is_valid(Left),
       is_valid(Right),
       iterator:all(fun([K|_]) -> K >= Key end, iter(Left)),
       iterator:all(fun([K|_]) -> K >= Key end, iter(Right)),
       dist(Left) >= dist(Right)
      ]).


dist(leaf) ->
    0;
dist({tree, Dist, _, _, _}) ->
    Dist.


make_tree(Elem, Tree1, Tree2) ->
    Dist1 = dist(Tree1),
    Dist2 = dist(Tree2),

    case Dist1 >= Dist2 of
        true ->
            {tree, Dist2+1, Elem, Tree1, Tree2};
        false ->
            {tree, Dist1+1, Elem, Tree2, Tree1}
    end.


-spec empty() -> Tree when
      Tree :: tree(K,V),
      K    :: term(),
      V    :: term().
empty() ->
    leaf.


-spec is_empty(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_empty(leaf) ->
    true;
is_empty(_) ->
    false.


-spec merge(Tree1, Tree2) -> Tree3 when
      Tree1 :: tree(K, V),
      Tree2 :: tree(K, V),
      Tree3 :: tree(K, V),
      K    :: term(),
      V    :: term().
merge(leaf, leaf) ->
    leaf;
merge(Tree1, leaf) ->
    Tree1;
merge(leaf, Tree2) ->
    Tree2;
merge({tree, _, [K1|_]=Elem, Left, Right}, {tree, _, [K2|_], _, _}=Tree2)
  when K1 =< K2 ->
    make_tree(Elem, Left, merge(Right, Tree2));
merge({tree, _, [K1|_], _, _}=Tree1, {tree, _, [K2|_]=Elem, Left, Right})
  when K1 > K2 ->
    make_tree(Elem, Left, merge(Tree1, Right)).


-spec insert(Elem, Tree1) -> Tree2 when
      Elem  :: [K|V],
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      K     :: term(),
      V     :: term().
insert(Elem, Tree) ->
    merge({tree, 1, Elem, leaf, leaf}, Tree).


-spec peek(Tree) -> none | {value, Elem} when
      Tree :: tree(K,V),
      Elem :: [K|V],
      K    :: term(),
      V    :: term().
peek(leaf) ->
    none;
peek({tree, _, Elem, _, _}) ->
    {value, Elem}.


-spec pop(Tree1) -> empty | {ok, Tree2} when
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      K    :: term(),
      V    :: term().
pop(leaf) ->
    empty;
pop({tree, _, _, Left, Right}) ->
    {ok, merge(Left, Right)}.


-spec iter(Tree) -> Iterator when
      Tree     :: tree(K,V),
      Iterator :: iterator:iterator([K|V]),
      K        :: term(),
      V        :: term().
iter(Tree) ->
    case Tree of
        leaf ->
            fun iterator:empty/0;
        {tree, _, Elem, Left, Right} ->
            iterator:cons(
              Elem,
              iter(merge(Left, Right)))
    end.
