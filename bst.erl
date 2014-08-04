-module(bst).

-export(
   [
    is_valid/1,
    empty/0,
    is_empty/1,
    lookup/2,
    enter/2,
    delete/2,
    iter/1
   ]).


-type tree(K, V) :: 'leaf'
                  | {'tree', [K|V], tree(K,V), tree(K,V)}.


-spec is_valid(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_valid(leaf) ->
    true;
is_valid({tree, [Key|_], Left, Right}) ->
    lists:all(
      [
       is_valid(Left),
       is_valid(Right),
       iterator:all(fun([K|_]) -> K < Key end, iter(Left)),
       iterator:all(fun([K|_]) -> K > Key end, iter(Right))
      ]).


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


-spec lookup(Key, Tree) -> 'none' | {'value', Elem} when
      Key  :: K,
      Tree :: tree(K,V),
      Elem :: [K|V],
      K    :: term(),
      V    :: term().
lookup(_, leaf) ->
    none;
lookup(Key, {tree, [KN|_]=Elem, _, _})
  when Key == KN ->
    {value, Elem};
lookup(Key, {tree, [KN|_], Smaller, _})
  when Key < KN ->
    lookup(Key, Smaller);
lookup(Key, {tree, [KN|_], _, Bigger})
  when Key > KN ->
    lookup(Key, Bigger).


-spec enter(Elem, Tree1) -> {Op, Tree2} when
      Elem  :: [K|V],
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      Op    :: 'insert' | 'update',
      K     :: term(),
      V     :: term().
enter(Elem, leaf) ->
    {insert, {tree, Elem, leaf, leaf}};
enter([Key|_]=Elem, {tree, [KN|_], Smaller, Bigger})
  when Key == KN ->
    {update, {tree, Elem, Smaller, Bigger}};
enter([Key|_]=Elem, {tree, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    {Op, Smaller1} = enter(Elem, Smaller),
    {Op, {tree, Node, Smaller1, Bigger}};
enter([Key|_]=Elem, {tree, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    {Op, Bigger1} = enter(Elem, Bigger),
    {Op, {tree, Node, Smaller, Bigger1}}.


pop_max({tree, Elem, Smaller, leaf}) ->
    {Elem, Smaller};
pop_max({tree, Elem, Smaller, Bigger}) ->
    {Max, Bigger1} = pop_max(Bigger),
    {Max, {tree, Elem, Smaller, Bigger1}}.


-spec delete(Key, Tree1) -> not_found | {deleted, Tree2} when
      Key   :: K,
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      K     :: term(),
      V     :: term().
delete(_, leaf) ->
    not_found;
delete(Key, {tree, [KN|_], leaf, Bigger})
  when Key == KN ->
    {deleted, Bigger};
delete(Key, {tree, [KN|_], Smaller, leaf})
  when Key == KN ->
    {deleted, Smaller};
delete(Key, {tree, [KN|_], Smaller, Bigger})
  when Key == KN ->
    {Elem, Smaller1} = pop_max(Smaller),
    {deleted, {tree, Elem, Smaller1, Bigger}};
delete(Key, {tree, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    case delete(Key, Smaller) of
        not_found ->
            not_found;
        {deleted, Smaller1} ->
            {deleted, {tree, Node, Smaller1, Bigger}}
    end;
delete(Key, {tree, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    case delete(Key, Bigger) of
        not_found ->
            not_found;
        {deleted, Bigger1} ->
            {deleted, {tree, Node, Smaller, Bigger1}}
    end.


-spec iter(Tree) -> Iterator when
      Tree     :: tree(K,V),
      Iterator :: iterator:iterator([K|V]),
      K        :: term(),
      V        :: term().
iter(Tree) ->
    case Tree of
        leaf ->
            fun iterator:empty/0;
        {tree, Elem, Left, Right} ->
            iterator:append(
              iter(Left),
              iterator:cons(
                Elem,
                iter(Right)))
    end.
