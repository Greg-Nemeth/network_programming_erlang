-module(tcp_echo_server_connection).

-export([handle_info/2]).
-include_lib("kernel/include/logger.hrl").
-behaviour(gen_server).
-export([start_link/1]).
-record(state, {socket        :: gen_tcp:socket(),
                buffer = <<>> :: erlang:binary()}).

%% Callbacks for `gen_server`
-export([init/1, handle_call/3, handle_cast/2]).

-spec init(Socket :: gen_tcp:socket()) -> tuple().
init(Socket) ->
    State = #state{socket = Socket},
    {ok, State}.

handle_info({tcp, Socket, Data}, #state{socket = Socket} = State) ->
    ConcatData = State#state{
        buffer = <<Data/binary, (State#state.buffer)/binary>>
    },
    NewState = handle_new_data(ConcatData),
    {noreply, NewState};

handle_info({tcp_closed, Socket}, #state{socket = Socket} = State) ->
    {stop, normal, State};

handle_info({tcp_error, Socket, Reason}, #state{socket = Socket} = State) ->
    ?LOG_ERROR("TCP connection error: ~p", [Reason]),
    {stop, normal, State}.

handle_new_data(ConcatData) ->
    case binary:split(ConcatData#state.buffer, ~"\n", []) of
        [Line, Rest] ->
            ok = gen_tcp:send(ConcatData#state.socket, <<Line/binary, "\n">>),
            UpdatedState = ConcatData#state{buffer = Rest},
            handle_new_data(UpdatedState);
        _other ->
            ConcatData
    end.
    
handle_call(Request,From,State) ->
    erlang:error(not_implemented).

handle_cast(Request,State) ->
    erlang:error(not_implemented).

%% callback module
-spec start_link(Socket :: gen_tcp:socket()) -> gen_server:start_ret().
start_link(Socket) ->
    gen_server:start_link(?MODULE, Socket, []).

