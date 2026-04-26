-module(chat_client_shell).
-include_lib("chat_proto/include/types.hrl").
-export([start_link/0, init/1, input_loop/2]).

-define(CLEAR_LINE, "\e[2K").
-define(MOVE_TO_START, "\r").
-define(UP_ONE, "\e[1A").

start_link() ->
    proc_lib:start_link(?MODULE, init, [self()]).

init(Parent) ->
    {ok, Socket} = gen_tcp:connect("localhost", 4000, [binary, {active, once}]),
    proc_lib:init_ack(Parent, {ok, self()}),

    User = get_username(),
    Bin = iolist_to_binary(User),
    Msg = chat_protocol:encode_message(#register{username = Bin}),
    ok = gen_tcp:send(Socket, Msg),

    spawn_link(?MODULE, input_loop, [self(), User]),
    
    loop(Socket, User, <<>>)
    .

loop(Socket, User, Buffer) ->
    receive
        {user_input, Text} ->
            Msg = #broadcast{from_username = <<>>, contents = iolist_to_binary(Text)},
            EncodedMsg = chat_protocol:encode_message(Msg),
            ok = gen_tcp:send(Socket, EncodedMsg),
            handle_incoming_own([User, ": ", Text], User),
            loop(Socket, User, Buffer);
        {tcp, Socket, Data} ->
            NewBuffer = <<Buffer/binary, Data/binary>>,
            case chat_protocol:decode_message(NewBuffer) of
                {ok, #broadcast{from_username = From, contents = Content}, Rest} ->
                    Formatted = [From, ": ", Content],
                    handle_incoming(Formatted, User),
                    inet:setopts(Socket, [{active, once}]),
                    loop(Socket, User, Rest);
                {ok, _, Rest} ->
                    inet:setopts(Socket, [{active, once}]),
                    loop(Socket, User, Rest);
                incomplete ->
                    inet:setopts(Socket, [{active, once}]),
                    loop(Socket, User, NewBuffer);
                error ->
                    io:format("Protocol error~n"),
                    exit(protocol_error)
            end;
        {tcp_closed, Socket} ->
            io:format("~nConnection closed.~n"),
            init:stop()
    end.


input_loop(Parent, User) ->
    Prompt = [User, "> "],
    Input = io:get_line(Prompt),
    case Input of
        eof -> exit(done);
        _ -> 
            Parent ! {user_input, string:trim(Input, trailing, "\n")},
            input_loop(Parent, User)
    end.

handle_incoming(Msg, User) ->
    Prompt = [User, "> "],
    io:format("~s~s~s~n~s", [?CLEAR_LINE, ?MOVE_TO_START, Msg, Prompt]).

handle_incoming_own(Msg, User) ->
    Prompt = [User, "> "],
    io:format("~s~s~s~s~n~s", [?UP_ONE, ?CLEAR_LINE, ?MOVE_TO_START, Msg, Prompt]).

get_username() ->
    string:trim(io:get_line("Enter your username: "), trailing, "\n").
