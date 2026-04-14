-module(chat_protocol).

-export([decode_message/1]).
-include("types.hrl").
-type message() :: register() | broadcast().

-spec decode_message(binary()) -> {ok, message(), binary()}
    | error
    | incomplete.
decode_message(<<1, Rest/binary>>) ->
    decode_register(Rest);
decode_message(<<2, Rest/binary>>) ->
    decode_broadcast(Rest);
decode_message(<<>>) ->
    incomplete;
decode_message(<<_/binary>>) ->
    error.


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
