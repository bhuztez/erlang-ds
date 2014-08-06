-module(avl_tree).

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
                  | {'tree', pos_integer(), nonempty_maybe_improper_list(K,V), tree(K,V), tree(K,V)}.


-spec is_valid(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_valid(leaf) ->
    true;
is_valid({tree, Height, [Key|_], Left, Right}) ->
    lists:all(
      [
       is_valid(Left),
       is_valid(Right),
       iterator:all(fun([K|_]) -> K < Key end, iter(Left)),
       iterator:all(fun([K|_]) -> K > Key end, iter(Right)),
       Height == max(height(Left), height(Right)) + 1,
       height(Left) + 1 >= height(Right),
       height(Right) + 1 >= height(Left)
      ]).



height(leaf) ->
    0;
height({tree, Height, _, _, _}) ->
    Height.


fill_height(Elem, Tree1, Tree2) ->
    {tree, max(height(Tree1), height(Tree2))+1, Elem, Tree1, Tree2}.


rotate_left({tree, _, Elem, Left, Right}=Tree) ->
    HL = height(Left),
    HR = height(Right),
    case HL - HR of
        -1 ->
            {tree, _, E1, Left1, Right1} = Right,
            fill_height(E1, fill_height(Elem, Left, Left1), Right1);
        _ ->
            Tree
    end.

rotate_right({tree, _, Elem, Left, Right}=Tree) ->
    HL = height(Left),
    HR = height(Right),
    case HL - HR of
        1 ->
            {tree, _, E1, Left1, Right1} = Left,
            fill_height(E1, Left1, fill_height(Elem, Right1, Right));
        _ ->
            Tree
    end.


make_tree(Elem, Tree1, Tree2) ->
    H1 = height(Tree1),
    H2 = height(Tree2),
    case H1 - H2 of
        2 ->
            {tree, _, E1, Left, Right} = rotate_left(Tree1),
            fill_height(E1, Left, fill_height(Elem, Right, Tree2));
        -2 ->
            {tree, _, E1, Left, Right} = rotate_right(Tree2),
            fill_height(E1, fill_height(Elem, Tree1, Left), Right);
        _ ->
            {tree, max(H1,H2)+1, Elem, Tree1, Tree2}
    end.



-spec empty() -> 'leaf'.
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
      Elem :: nonempty_maybe_improper_list(K,V),
      K    :: term(),
      V    :: term().
lookup(_, leaf) ->
    none;
lookup(Key, {tree, _, [KN|_]=Elem, _, _})
  when Key == KN ->
    {value, Elem};
lookup(Key, {tree, _, [KN|_], Smaller, _})
  when Key < KN ->
    lookup(Key, Smaller);
lookup(Key, {tree, _, [KN|_], _, Bigger})
  when Key > KN ->
    lookup(Key, Bigger).


-spec enter(Elem, Tree1) -> {Op, Tree2} when
      Elem  :: nonempty_maybe_improper_list(K,V),
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      Op    :: 'insert' | 'update',
      K     :: term(),
      V     :: term().
enter(Elem, leaf) ->
    {insert, {tree, 1, Elem, leaf, leaf}};
enter([Key|_]=Elem, {tree, Height, [KN|_], Smaller, Bigger})
  when Key == KN ->
    {update, {tree, Height, Elem, Smaller, Bigger}};
enter([Key|_]=Elem, {tree, Height, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    case enter(Elem, Smaller) of
        {update, Smaller1} ->
            {update, {tree, Height, Node, Smaller1, Bigger}};
        {insert, Smaller1} ->
            {insert, make_tree(Node, Smaller1, Bigger)}
    end;
enter([Key|_]=Elem, {tree, Height, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    case enter(Elem, Bigger) of
        {update, Bigger1} ->
            {update, {tree, Height, Node, Smaller, Bigger1}};
        {insert, Bigger1} ->
            {insert, make_tree(Node, Smaller, Bigger1)}
    end.


pop_max({tree, _, Elem, Smaller, leaf}) ->
    {Elem, Smaller};
pop_max({tree, _, Elem, Smaller, Bigger}) ->
    {Max, Bigger1} = pop_max(Bigger),
    {Max, make_tree(Elem, Smaller, Bigger1)}.


-spec delete(Key, Tree1) -> not_found | {deleted, Tree2} when
      Key   :: K,
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      K     :: term(),
      V     :: term().
delete(_, leaf) ->
    not_found;
delete(Key, {tree, _, [KN|_], leaf, Bigger})
  when Key == KN ->
    {deleted, Bigger};
delete(Key, {tree, _, [KN|_], Smaller, leaf})
  when Key == KN ->
    {deleted, Smaller};
delete(Key, {tree, _, [KN|_], Smaller, Bigger})
  when Key == KN ->
    {Elem, Smaller1} = pop_max(Smaller),
    {deleted, make_tree(Elem, Smaller1, Bigger)};
delete(Key, {tree, _, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    case delete(Key, Smaller) of
        not_found ->
            not_found;
        {deleted, Smaller1} ->
            {deleted, make_tree(Node, Smaller1, Bigger)}
    end;
delete(Key, {tree, _, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    case delete(Key, Bigger) of
        not_found ->
            not_found;
        {deleted, Bigger1} ->
            {deleted, make_tree(Node, Smaller, Bigger1)}
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
        {tree, _, Elem, Left, Right} ->
            iterator:append(
              iter(Left),
              iterator:cons(
                Elem,
                iter(Right)))
    end.
