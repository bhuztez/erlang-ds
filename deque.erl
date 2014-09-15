-module(deque).

-export(
   [
    empty/0,
    push/2,
    push_r/2,
    peek/1,
    peek_r/1,
    drop/1,
    drop_r/1
   ]).


empty() ->
    {deque, [], []}.


push(Elem, {deque, [], [_]=Rear}) ->
    {deque, Rear, [Elem]};
push(Elem, {deque, Front, Rear}) ->
    {deque, Front, [Elem|Rear]}.


push_r(Elem, {deque, [_]=Front, []}) ->
    {deque, [Elem], Front};
push_r(Elem, {deque, Front, Rear}) ->
    {deque, [Elem|Front], Rear}.


peek({deque, [], []}) ->
    empty;
peek({deque, [Head|_], _}) ->
    Head;
peek({deque, [], [Elem]}) ->
    Elem.


peek_r({deque, [], []}) ->
    empty;
peek_r({deque, _, [Head|_]}) ->
    Head;
peek_r({deque, [Elem], []}) ->
    Elem.


drop({deque, [], [_]}) ->
    {deque, [], []};
drop({deque, [_], Rear}) ->
    {A,B} = split(Rear),
    {deque, B, A};
drop({deque, [_|Tail], Rear}) ->
    {deque, Tail, Rear}.


drop_r({deque, [_], []}) ->
    {deque, [], []};
drop_r({deque, Front, [_]}) ->
    {A,B} = split(Front),
    {deque, A, B};
drop_r({deque, Front, [_|Tail]}) ->
    {deque, Front, Tail}.


split(List) ->
    {A,B} = lists:split(length(List) div 2, List),
    {A, lists:reverse(B)}.
