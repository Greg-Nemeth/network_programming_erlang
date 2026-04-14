-module(chat_protocol).

-export([decode_message/1, encode_message/1]).
-include("types.hrl").
-type message() :: register() | broadcast().

-spec decode_message(Data :: binary()) -> {ok, message(), binary()}
    | error
    | incomplete.
decode_message(<<1, Rest/binary>>) -> decode_register(Rest);
decode_message(<<2, Rest/binary>>) -> decode_broadcast(Rest);
decode_message(<<>>) -> incomplete;
decode_message(<<_/binary>>) -> error.

-spec encode_message(Message :: message()) -> iodata().
encode_message(#register{} = Msg) ->
    [1, encode_string(Msg#register.username)];
encode_message(#broadcast{} = Msg) ->
    [2, encode_string(Msg#broadcast.from_username), encode_string(Msg#broadcast.contents)].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INTERNALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
decode_register(<<
        UsernameLen:16,
        Username:UsernameLen/binary,
        Rest/binary
    >>) ->
    {ok, #register{username = Username}, Rest};
decode_register(<<_/binary>>) -> incomplete.

decode_broadcast(<<
        UsernameLen:16, Username:UsernameLen/binary,
        ContentsLen:16, Contents:ContentsLen/binary,
        Rest/binary
    >>) ->
    {ok, #broadcast{from_username = Username, contents = Contents}, Rest};
decode_broadcast(<<_/binary>>) -> incomplete.

encode_string(Str) ->
    [<<(byte_size(Str)):16>>, Str].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TESTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-ifdef('EUNIT').
-include_lib("eunit/include/eunit.hrl").

decode_message_test_() ->
    {inparallel, [
        {"CASE: can decode register messages", fun can_decode_register_messages/0},
        {"CASE: can decode broadcast messages", fun can_decode_broadcast_messages/0},
        {"CASE: returns incomplete for empty data", fun() -> ?assertEqual(incomplete, decode_message(~""))end},
        {"CASE: returns error for unknown message types", fun() -> ?assertEqual(error, decode_message(<<3, "rest">>))end}
    ]}.
encode_message_test_() ->
    {inparallel, [
       {"CASE: can encode Register messages", fun() ->
            Message = #register{username = ~"meg"},
            IoData = encode_message(Message),
            ?assertEqual(<<1,0,3, "meg">>, iolist_to_binary(IoData))
        end} ,
       {"CASE: can encode Broadcast messages", fun() ->
            Message = #broadcast{from_username = ~"meg", contents = ~"hi"},
            IoData = encode_message(Message),
            ?assertEqual(<<2,0,3, "meg", 0, 2, "hi">>, iolist_to_binary(IoData))
        end} 
    ]}.
can_decode_register_messages() ->
    Binary = <<1,0,3, "meg", "rest">>,
    {ok, Message, Rest} = decode_message(Binary),
    ?assertMatch({ok, Message, Rest}, decode_message(Binary)),
    ?assert(Message == #register{username = ~"meg"}),
    
    ?assert(Rest == ~"rest"),
    %% make sure 'incomplete' is returned when the message is incomplete
    ?assert(decode_message(<<1, 0>>) =:= incomplete).

can_decode_broadcast_messages() ->
    Binary = <<2,3:16, "meg", 2:16, "hi", "rest">>,
    {ok, Message, Rest} = decode_message(Binary),
    ?assertMatch({ok, Message, Rest}, decode_message(Binary)),
    ?assert(Message == #broadcast{from_username = ~"meg", contents = ~"hi"}),

    ?assert(Rest == ~"rest"),
    %% make sure 'incomplete' is returned when the message is incomplete
    ?assert(decode_message(<<2, 0>>) =:= incomplete).

-endif.
