-module(hash_table).

-export(
   [
    empty/0,
    is_empty/1,
    lookup/2,
    enter/2,
    delete/2
   ]).


-define(SEG_SIZE, 4).
-define(EXPAND_LOAD, 5).
-define(CONTRACT_LOAD, 3).

-record(table, {size, active, slots, segs}).


make_seg(N) ->
    list_to_tuple(lists:duplicate(N, [])).


empty() ->
    #table{
       size=0,
       active=?SEG_SIZE,
       slots=?SEG_SIZE,
       segs={make_seg(?SEG_SIZE)}}.


is_empty(#table{size=0}) ->
    true;
is_empty(#table{}) ->
    false.


get_bucket_number(Slot) ->
    {(Slot-1) div ?SEG_SIZE + 1, (Slot-1) rem ?SEG_SIZE + 1}.


find_bucket_number(#table{active=Active, slots=Slots}, Key) ->
    Hash = erlang:phash(Key, Slots),
    Slot =
        case Hash > Active of
            true ->
                Hash - Slots div 2;
            false ->
                Hash
        end,
    get_bucket_number(Slot).


lookup(Key, #table{segs=Segs} = Table) ->
    {SegN, BktN} = find_bucket_number(Table, Key),
    Bkt = element(BktN, element(SegN, Segs)),
    lookup_aux(Key, Bkt).


lookup_aux(_, []) ->
    none;
lookup_aux(Key, [[Key|_]=Elem|_]) ->
    {value, Elem};
lookup_aux(Key, [_|Tail]) ->
    lookup_aux(Key, Tail).


enter([Key|_]=Elem, #table{size=Size, segs=Segs}=Table) ->
    {SegN, BktN} = find_bucket_number(Table, Key),
    Seg = element(SegN, Segs),
    Bkt = element(BktN, Seg),
    case enter_aux(Elem, Bkt) of
        not_found ->
            Segs1 = setelement(SegN, Segs, setelement(BktN, Seg, [Elem|Bkt])),
            {insert, maybe_expand(Table#table{size=Size+1, segs=Segs1})};
        {update, Bkt1} ->
            Segs1 = setelement(SegN, Segs, setelement(BktN, Seg, Bkt1)),
            {update, Table#table{segs=Segs1}}
    end.


enter_aux(_, []) ->
    not_found;
enter_aux([Key|_]=Elem, [[Key|_]|Tail]) ->
    {update, [Elem|Tail]};
enter_aux(Elem, [Head|Tail]) ->
    case enter_aux(Elem, Tail) of
        not_found ->
            not_found;
        {update, Tail1} ->
            {update, [Head|Tail1]}
    end.


maybe_expand(#table{size=Size, active=Active} = Table)
  when Size =< Active * ?EXPAND_LOAD ->
    Table;
maybe_expand(#table{size=Size, active=Active, slots=Slots, segs=Segs}) ->
    {Segs1, Slots1} =
        case Active =:= Slots of
            true ->
                {expand_segs(Segs), Slots*2};
            false ->
                {Segs, Slots}
        end,

    SlotN2 = Active + 1,
    SlotN1 = SlotN2 - Slots1 div 2,
    {SegN1, BktN1} = get_bucket_number(SlotN1),
    {SegN2, BktN2} = get_bucket_number(SlotN2),
    Bkt = element(BktN1, element(SegN1, Segs1)),

    {Bkt1, Bkt2} = rehash(Bkt, SlotN1, SlotN2, Slots1),
    Segs2 =
        setelement(SegN1, Segs1,
                   setelement(BktN1, element(SegN1, Segs1), Bkt1)),
    Segs3 =
        setelement(SegN2, Segs2,
                   setelement(BktN2, element(SegN2, Segs2), Bkt2)),
    #table{size=Size, active=Active+1, slots=Slots1, segs=Segs3}.


rehash([], _, _, _) ->
    {[], []};
rehash([[Key|_]=Elem|Tail], SlotN1, SlotN2, Slots) ->
    {B1, B2} = rehash(Tail, SlotN1, SlotN2, Slots),
    case erlang:phash(Key, Slots) of
        SlotN1 ->
            {[Elem|B1], B2};
        SlotN2 ->
            {B1, [Elem|B2]}
    end.


expand_segs(Segs) ->
    list_to_tuple(
      lists:append(
        tuple_to_list(Segs),
        lists:duplicate(size(Segs), make_seg(?SEG_SIZE)))).


delete(Key, #table{size=Size, segs=Segs}=Table) ->
    {SegN, BktN} = find_bucket_number(Table, Key),
    Seg = element(SegN, Segs),
    Bkt = element(BktN, Seg),
    case delete_aux(Key, Bkt) of
        not_found ->
            not_found;
        {deleted, Bkt1} ->
            Segs1 = setelement(SegN, Segs, setelement(BktN, Seg, Bkt1)),
            {deleted, maybe_contract(Table#table{size=Size-1, segs=Segs1})}
    end.


delete_aux(_, []) ->
    not_found;
delete_aux(Key, [[Key|_]|Tail]) ->
    {deleted, Tail};
delete_aux(Key, [Head|Tail]) ->
    case delete_aux(Key, Tail) of
        not_found ->
            not_found;
        {deleted, Tail1} ->
            {deleted, [Head|Tail1]}
    end.



maybe_contract(#table{active=Active} = Table)
  when Active =< ?SEG_SIZE->
    Table;
maybe_contract(#table{size=Size, active=Active} = Table)
  when Size >= Active * ?CONTRACT_LOAD ->
    Table;
maybe_contract(#table{size=Size, active=Active, slots=Slots, segs=Segs}) ->
    SlotN2 = Active,
    SlotN1 = SlotN2 - Slots div 2,
    {SegN1, BktN1} = get_bucket_number(SlotN1),
    {SegN2, BktN2} = get_bucket_number(SlotN2),
    Bkt1 = element(BktN1, element(SegN1, Segs)),
    Bkt2 = element(BktN2, element(SegN2, Segs)),

    Segs1 =
        setelement(SegN1, Segs,
                   setelement(BktN1, element(SegN1, Segs), Bkt1 ++ Bkt2)),
    {Segs2, Slots1} =
        case (Active-1) =:= Slots div 2 of
            true ->
                {contract_segs(Segs1), Slots div 2};
            false ->
                {Segs1, Slots}
        end,
    #table{size=Size, active=Active-1, slots=Slots1, segs=Segs2}.


contract_segs(Segs) ->
    list_to_tuple(
      lists:sublist(
        tuple_to_list(Segs), 1, size(Segs) div 2)).
