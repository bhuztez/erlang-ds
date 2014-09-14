-module(redblack_tree).

-export(
   [
    is_valid/1,
    is_valid_subtree/1,
    empty/0,
    is_empty/1,
    lookup/2,
    enter/2,
    delete/2,
    iter/1
   ]).

-type tree(K, V) :: 'leaf'
                  | {'tree', 'black', nonempty_maybe_improper_list(K,V), subtree(K,V), subtree(K,V)}.

-type subtree(K, V) :: tree(K,V)
                     | {'tree', 'red', nonempty_maybe_improper_list(K,V), tree(K,V), tree(K,V)}.

black_depth(leaf) ->
    0;
black_depth({tree, Color, _, Left, Right}) ->
    case {black_depth(Left), black_depth(Right)} of
        {invalid, _} ->
            invalid;
        {_, invalid} ->
            invalid;
        {D, D} ->
            case Color of
                black ->
                    D + 1;
                red ->
                    D
            end;
        _ ->
            invalid
    end.


-spec is_valid(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_valid(leaf) ->
    true;
is_valid({tree, black, _, _, _}=Tree) ->
    lists:all(
      [
       is_valid_subtree(Tree)
      ]);
is_valid(_) ->
    false.


-spec is_valid_subtree(Tree) -> boolean() when
      Tree :: tree(K, V),
      K    :: term(),
      V    :: term().
is_valid_subtree(leaf) ->
    true;
is_valid_subtree({tree, red, _, {tree, red, _, _, _}, _}) ->
    false;
is_valid_subtree({tree, red, _, _, {tree, red, _, _, _}}) ->
    false;
is_valid_subtree({tree, _, [Key|_], Left, Right}=Tree) ->
    %% TODO: no two reds
    lists:all(
      [
       is_valid_subtree(Left),
       is_valid_subtree(Right),
       iterator:all(fun([K|_]) -> K < Key end, iter(Left)),
       iterator:all(fun([K|_]) -> K > Key end, iter(Right)),
       black_depth(Tree) /= invalid
      ]).


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


redder(black) ->
    red;
redder(double_black) ->
    black.

blacker(red) ->
    black;
blacker(black) ->
    double_black.


make_tree(Color, Node, {tree, red, NodeL, {tree, red, NodeLL, LLL, LLR}, LR}, Bigger) ->
    {tree, redder(Color), NodeL,
     {tree, black, NodeLL, LLL, LLR},
     {tree, black, Node, LR, Bigger}};
make_tree(Color, Node, {tree, red, NodeL, LL, {tree, red, NodeLR, LRL, LRR}}, Bigger) ->
    {tree, redder(Color), NodeLR,
     {tree, black, NodeL, LL, LRL},
     {tree, black, Node, LRR, Bigger}};
make_tree(Color, Node, Smaller, {tree, red, NodeR, {tree, red, NodeRL, RLL, RLR}, RR}) ->
    {tree, redder(Color), NodeRL,
     {tree, black, Node, Smaller, RLL},
     {tree, black, NodeR, RLR, RR}};
make_tree(Color, Node, Smaller, {tree, red, NodeR, RL, {tree, red, NodeRR, RRL, RRR}}) ->
    {tree, redder(Color), NodeR,
     {tree, black, Node, Smaller, RL},
     {tree, black, NodeRR, RRL, RRR}};
make_tree(Color, Node, Smaller, Bigger) ->
    {tree, Color, Node, Smaller, Bigger}.


-spec enter(Elem, Tree1) -> {Op, Tree2} when
      Elem  :: nonempty_maybe_improper_list(K,V),
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      Op    :: 'insert' | 'update',
      K     :: term(),
      V     :: term().
enter(Elem, Tree) ->
    case enter_aux(Elem, Tree) of
        {update, Tree1} ->
            {update, Tree1};
        {insert, {tree, red, Elem1, Smaller, Bigger}} ->
            {insert, {tree, black, Elem1, Smaller, Bigger}};
        {insert, Tree1} ->
            {insert, Tree1}
    end.

enter_aux(Elem, leaf) ->
    {insert, {tree, red, Elem, leaf, leaf}};
enter_aux([Key|_]=Elem, {tree, Color, [KN|_], Smaller, Bigger})
  when Key == KN ->
    {update, {tree, Color, Elem, Smaller, Bigger}};
enter_aux([Key|_]=Elem, {tree, Color, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    case enter_aux(Elem, Smaller) of
        {update, Smaller1} ->
            {update, {tree, Color, Node, Smaller1, Bigger}};
        {insert, Smaller1} ->
            {insert, make_tree(Color, Node, Smaller1, Bigger)}
    end;
enter_aux([Key|_]=Elem, {tree, Color, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    case enter_aux(Elem, Bigger) of
        {update, Bigger1} ->
            {update, {tree, Color, Node, Smaller, Bigger1}};
        {insert, Bigger1} ->
            {insert, make_tree(Color, Node, Smaller, Bigger1)}
    end.


bubble(Color, Node, double_black, {tree, black, NodeR, RL, RR}) ->
    make_tree(blacker(Color), Node, leaf, {tree, red, NodeR, RL, RR});
bubble(Color, Node, {tree, double_black, NodeL, LL, LR}, {tree, black, NodeR, RL, RR}) ->
    make_tree(blacker(Color), Node, {tree, black, NodeL, LL, LR}, {tree, red, NodeR, RL, RR});
bubble(Color, Node, {tree, black, NodeL, LL, LR}, double_black) ->
    make_tree(blacker(Color), Node, {tree, red, NodeL, LL, LR}, leaf);
bubble(Color, Node, {tree, black, NodeL, LL, LR}, {tree, double_black, NodeR, RL, RR}) ->
    make_tree(blacker(Color), Node, {tree, red, NodeL, LL, LR}, {tree, black, NodeR, RL, RR});

bubble(black, Node, double_black, {tree, red, NodeR, {tree, black, NodeRL, RLL, RLR}, {tree, black, NodeRR, RRL, RRR}}) ->
    {tree, black, NodeRL,
     {tree, black, Node, leaf, RLL},
     make_tree(black, NodeR, RLR, {tree, red, NodeRR, RRL, RRR})};
bubble(black, Node, {tree, double_black, NodeL, LL, LR}, {tree, red, NodeR, {tree, black, NodeRL, RLL, RLR}, {tree, black, NodeRR, RRL, RRR}}) ->
    {tree, black, NodeRL,
     {tree, black, Node, {tree, black, NodeL, LL, LR}, RLL},
     make_tree(black, NodeR, RLR, {tree, red, NodeRR, RRL, RRR})};
bubble(black, Node, {tree, red, NodeL, {tree, black, NodeLL, LLL, LLR}, {tree, black, NodeLR, LRL, LRR}}, double_black) ->
    {tree, black, NodeLR,
     make_tree(black, NodeL, {tree, red, NodeLL, LLL, LLR}, LRL),
     {tree, black, Node, LRR, leaf}};
bubble(black, Node, {tree, red, NodeL, {tree, black, NodeLL, LLL, LLR}, {tree, black, NodeLR, LRL, LRR}}, {tree, double_black, NodeR, RL, RR}) ->
    {tree, black, NodeLR,
     make_tree(black, NodeL, {tree, red, NodeLL, LLL, LLR}, LRL),
     {tree, black, Node, LRR, {tree, black, NodeR, RL, RR}}};
bubble(Color, Node, Smaller, Bigger) ->
    make_tree(Color, Node, Smaller, Bigger).

remove({tree, red, _, leaf, Bigger}) ->
    Bigger;
remove({tree, red, _, Smaller, leaf}) ->
    Smaller;
remove({tree, black, _, leaf, {tree, red, Node, Smaller, Bigger}}) ->
    {tree, black, Node, Smaller, Bigger};
remove({tree, black, _, {tree, red, Node, Smaller, Bigger}, leaf}) ->
    {tree, black, Node, Smaller, Bigger};
remove({tree, black, _, leaf, leaf}) ->
    double_black;
remove({tree, Color, _, Smaller, Bigger}) ->
    {Max, Smaller1} = pop_max(Smaller),
    bubble(Color, Max, Smaller1, Bigger).

pop_max({tree, _, Node, _, leaf}=Tree) ->
    {Node, remove(Tree)};
pop_max({tree, Color, Node, Smaller, Bigger}) ->
    {Max, Bigger1} = pop_max(Bigger),
    {Max, bubble(Color, Node, Smaller, Bigger1)}.


-spec delete(Key, Tree1) -> not_found | {deleted, Tree2} when
      Key   :: K,
      Tree1 :: tree(K,V),
      Tree2 :: tree(K,V),
      K     :: term(),
      V     :: term().
delete(Key, Tree) ->
    case delete_aux(Key, Tree) of
        not_found ->
            not_found;
        {deleted, double_black} ->
            {deleted, leaf};
        {deleted, {tree, black, _, _, _}=Tree1} ->
            {deleted, Tree1};
        {deleted, {tree, _, Node, Smaller, Bigger}} ->
            {deleted, {tree, black, Node, Smaller, Bigger}}
    end.


delete_aux(_, leaf) ->
    not_found;
delete_aux(Key, {tree, _, [KN|_], _, _}=Tree)
  when Key == KN ->
    {deleted, remove(Tree)};
delete_aux(Key, {tree, Color, [KN|_]=Node, Smaller, Bigger})
  when Key < KN ->
    case delete_aux(Key, Smaller) of
        not_found ->
            not_found;
        {deleted, Smaller1} ->
            {deleted, bubble(Color, Node, Smaller1, Bigger)}
    end;
delete_aux(Key, {tree, Color, [KN|_]=Node, Smaller, Bigger})
  when Key > KN ->
    case delete_aux(Key, Bigger) of
        not_found ->
            not_found;
        {deleted, Bigger1} ->
            {deleted, bubble(Color, Node, Smaller, Bigger1)}
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
