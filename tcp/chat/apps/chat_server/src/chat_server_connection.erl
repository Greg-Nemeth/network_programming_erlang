-module(chat_server_connection).
-include_lib("chat_proto/include/constants.hrl").
-include_lib("chat_proto/include/types.hrl").
-include_lib("kernel/include/logger.hrl").
-export([start_link/2, init/1, handle_info/2, handle_call/3, handle_cast/2]).
-behaviour(gen_server).
-record(connection, {socket          :: gen_tcp:socket(),
                     username = <<>> :: binary()        ,
                     buffer   = <<>> :: binary()
                    }).

-spec start_link(Socket :: gen_tcp:socket(), Active :: non_neg_integer()) -> gen_server:start_ret().
start_link(Socket, Active) when Active < ?CONN_LIMIT ->
  gen_server:start_link(?MODULE, Socket, []);
start_link(_, Active) -> erlang:error(io:format("Connection Limit Reached! ~p", [Active])).

init(Socket) ->
    {ok, #connection{socket = Socket}}.

handle_info({broadcast, #broadcast{} = Message}, State) ->
    EncodedMsg = chat_protocol:encode_message(Message),
    ok = gen_tcp:send(State#connection.socket, EncodedMsg),
    {noreply, State};
handle_info({tcp, Socket, Data}, #connection{buffer = Buffer} = State) ->
    NewState = State#connection{buffer = <<Buffer/binary, Data/binary>>},
    ok = inet:setopts(Socket, [{active, once}]),
    handle_new_data(NewState);
handle_info({tcp_closed, Socket}, #connection{socket = Socket} = State) ->
    {stop, normal, State};
handle_info({tcp_error, Socket, Reason}, #connection{socket = Socket} = State) ->
    ?LOG_ERROR("TCP connection error: ~w", Reason),
    {stop, normal, State}.


handle_call(Request,_From,State) ->
    ?LOG_ERROR("~p", Request),
    {reply, {error, unknown_call}, State}.

handle_cast(Request,State) ->
    ?LOG_ERROR("~p", Request),
    {noreply, State}.

handle_new_data(#connection{buffer = Buffer} = State) ->
    case chat_protocol:decode_message(Buffer) of
        {ok, Message, Rest} ->
            NewState = State#connection{buffer = Rest},
            case handle_message(Message, NewState) of
                {ok, UpdatedState} -> handle_new_data(UpdatedState);
                error -> {stop, normal, NewState}
            end;
        incomplete ->
            {noreply, State};
        error ->
            ?LOG_ERROR("Received invalid data, closing connection"),
            {stop, normal, State}
    end.

handle_message(#register{username = Username}, #connection{username =  <<>>} = State) ->
    ok = chat_server_registry:register(Username, self()),
    {ok, State#connection{username = Username}};
handle_message(#register{}, _State) ->
    ?LOG_ERROR("Invalid Register message, had already received one"),
    error;
handle_message(#broadcast{}, #connection{username = <<>>}) ->
    ?LOG_ERROR("Invalid Broadcast message, had not received a Register"),
    error;
handle_message(#broadcast{} = Message, State) ->
    Sender = self(),
    MessageWithUser = Message#broadcast{from_username = State#connection.username },
    chat_server_registry:broadcast_message(MessageWithUser, Sender),
    {ok, State}.
    

