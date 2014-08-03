-module(iterator).

-export(
   [
    empty/0,
    cons/2,
    map/2,
    foldl/3,
    foldr/3,
    from_list/1,
    to_list/1,
    append/2,
    reverse/1,
    reverse/2,
    all/2
   ]).

-export_type([iterator/1]).


-type stream(T) :: 'nil'
                | {'cons', T, iterator(T)}.

-type iterator(T) :: fun(() -> stream(T)).


-spec empty() -> stream(_).
empty() ->
    nil.


-spec cons(Elem, Iterator1) -> Iterator2 when
      Elem      :: T,
      Iterator1 :: iterator(T),
      Iterator2 :: iterator(T),
      T         :: term().
cons(Elem, Iterator) ->
    fun () -> {cons, Elem, Iterator} end.


-spec map(Fun, Iterator1) -> Iterator2 when
      Fun       :: fun((A) -> B),
      Iterator1 :: iterator(A),
      Iterator2 :: iterator(B),
      A         :: term(),
      B         :: term().
map(Fun, Iterator) ->
    fun () ->
            case Iterator() of
                nil ->
                    nil;
                {cons, H, T} ->
                    {cons, Fun(H), map(Fun, T)}
            end
    end.


-spec foldl(Fun, Acc0, Iterator) -> Acc1 when
      Fun      :: fun((Elem :: T, AccIn) -> AccOut),
      Acc0     :: term(),
      Acc1     :: term(),
      AccIn    :: term(),
      AccOut   :: term(),
      Iterator :: iterator(T),
      T        :: term().
foldl(Fun, Acc, Iterator) ->
    case Iterator() of
        nil ->
            Acc;
        {cons, H, T} ->
            foldl(Fun, Fun(H, Acc), T)
    end.


-spec foldr(Fun, Acc0, Iterator) -> Acc1 when
      Fun      :: fun((Elem :: T, AccIn) -> AccOut),
      Acc0     :: term(),
      Acc1     :: term(),
      AccIn    :: term(),
      AccOut   :: term(),
      Iterator :: iterator(T),
      T        :: term().
foldr(Fun, Acc, Iterator) ->
    case Iterator() of
        nil ->
            Acc;
        {cons, H, T} ->
            Fun(H, foldr(Fun, Acc, T))
    end.


-spec from_list(List) -> Iterator when
      List     :: [T],
      Iterator :: iterator(T),
      T        :: term().
from_list(List) ->
    fun () ->
            case List of
                [] ->
                    nil;
                [H|T] ->
                    {cons, H, from_list(T)}
            end
    end.


-spec to_list(Iterator) -> List when
      List     :: [T],
      Iterator :: iterator(T),
      T        :: term().
to_list(Iterator) ->
    foldl(
      fun(Elem, Acc) ->
              [Elem|Acc]
      end,
      [],
      reverse(Iterator)).


-spec append(Iterator1, Iterator2) -> Iterator3 when
      Iterator1 :: iterator(T),
      Iterator2 :: iterator(T),
      Iterator3 :: iterator(T),
      T     :: term().
append(A, B) ->
    fun () ->
            case A() of
                nil ->
                    B();
                {cons, H, T} ->
                    {cons, H, append(T, B)}
            end
    end.


-spec reverse(Iterator1) -> Iterator2 when
      Iterator1 :: iterator(T),
      Iterator2 :: iterator(T),
      T         :: term().
reverse(Iterator) ->
    reverse(Iterator, fun empty/0).


-spec reverse(Iterator1, Tail) -> Iterator2 when
      Iterator1 :: iterator(T),
      Tail      :: iterator(T),
      Iterator2 :: iterator(T),
      T         :: term().
reverse(Iterator, Tail) ->
    foldl(
      fun(Elem, Acc) ->
              fun () -> {cons, Elem, Acc} end
      end,
      Tail,
      Iterator).


-spec all(Pred, Iterator) -> boolean() when
      Pred     :: fun((Elem :: T) -> boolean()),
      Iterator :: iterator(T),
      T        :: term().
all(Pred, Iterator) ->
    foldl(fun(Elem, Acc) -> Pred(Elem) and Acc end, true, Iterator).
