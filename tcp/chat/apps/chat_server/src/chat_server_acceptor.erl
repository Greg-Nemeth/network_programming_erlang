-module(chat_server_acceptor).
-include_lib("kernel/include/logger.hrl").
-behaviour(gen_server).

-export([handle_cast/2,handle_info/2,  init/1, handle_call/3, start_link/1]).
-record(state, {listen_socket :: gen_tcp:socket(), supervisor :: pid()}).

-spec start_link(Opts :: proplists:proplist()) -> gen_server:start_ret().
start_link(Opts) ->
    gen_server:start_link(?MODULE, Opts, []).

init(Args) ->
    {port, Port} = lists:keyfind(port, 1, Args),

    ListenOptions = [
        binary,
        {active, once},
        {exit_on_close, false},
        {reuseaddr, true},
        {backlog, 25}
    ],

    maybe
        Sup = whereis(chat_conn_sup),
        true ?= is_pid(Sup),

        case gen_tcp:listen(Port, ListenOptions) of
            {ok, ListenSocket} ->
                ?LOG_INFO("Started chat server on port ~p", [Port]),
                gen_server:cast(self(), accept),
                {ok, #state{listen_socket = ListenSocket, supervisor = Sup}};
            {error, Reason} -> {stop, Reason}
        end
    end.

handle_cast(accept, #state{listen_socket = ListenSocket, supervisor = Sup} = State) ->
    case gen_tcp:accept(ListenSocket, 2000) of
        {ok, Socket} ->
            {ok, Pid} = chat_conn_sup:start_child(Socket,Sup),
            ok = gen_tcp:controlling_process(Socket, Pid),
            gen_server:cast(self(), accept),
            {noreply, State};
        {error, timeout} ->
            gen_server:cast(self(), accept),
            {noreply, State};
        {error, Reason} ->
            {stop, Reason, State}
    end.

handle_info(Info,_State) ->
    ?LOG_INFO(Info),
    erlang:error(not_implemented).

handle_call(Msg, _From,_State) ->
    ?LOG_INFO(Msg),
    erlang:error(not_implemented).

