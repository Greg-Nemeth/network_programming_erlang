-module(chat_connection).
-include("constants.hrl").
-include("types.hrl").
-include_lib("kernel/include/logger.hrl").
-export([start_link/2, init/1, handle_cast/2]).
-behaviour(gen_server).
-record(connection, {socket        :: gen_tcp:socket()    ,
                     username      :: binary() | undefined,
                     buffer = <<>> :: binary()          }).

-spec start_link(Socket :: gen_tcp:socket(), Active :: non_neg_integer()) -> gen_server:start_ret().
start_link(Socket, Active) when Active < ?CONN_LIMIT ->
  gen_server:start_link(?MODULE, Socket, []);
start_link(_, Active) -> erlang:error(io:format("Connection Limit Reached! ~p", [Active])).

init(Socket) ->
    {ok, #connection{socket = Socket}}.


handle_cast({tcp, Socket, Data}, #connection{buffer = Buffer} = State) ->
    NewState = State#connection{buffer = <<Data/binary, Buffer/binary>>},
    ok = inet:setopts(Socket, [{active, once}]),
    handle_new_data(NewState).

handle_new_data(#connection{buffer = Buffer} = State) ->
    case chat_protocol:decode_message(Buffer) of
        {ok, Message, Rest} ->
            NewState = State#connection{buffer = Rest},
            case handle_message(Message, NewState) of
                {ok, State} -> handle_new_data(NewState);
                error -> {stop, normal, NewState}
            end;
        incomplete ->
            {noreply, State};
        error ->
            ?LOG_ERROR("Received invalid data, closing connection"),
            {stop, normal, State}
    end.

handle_message(#register{username = Username}, #connection{username = undefined}= State) ->
    {ok, State#connection{username = Username}};
handle_message(#register{}, _State) ->
    ?LOG_ERROR("Invalid Register message, had already received one"),
    error.

