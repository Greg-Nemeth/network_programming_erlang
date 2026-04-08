-module(tcp_echo_server_acceptor).
-behaviour(gen_server).
-include_lib("kernel/include/logger.hrl").

%% Callbacks for `gen_server`
-export([init/1, handle_call/3, handle_cast/2, start_link/1, handle_info/2]).

init(Args) ->
    {ok, Port} = lists:keyfind(port, 1, Args),
    ListenOptions = [
        binary,
        {active, true},
        {exit_on_close, false},
        {reuseaddr, true},
        {backlog, 25}
    ],
    case gen_tcp:listen(Port, ListenOptions) of
        {ok, ListenSocket} ->
            ?LOG_INFO("Started TCP server on port ~s", [Port]),
            self() ! accept,
            {ok, ListenSocket};
        {error, Reason} -> {stop, Reason}
    end.

handle_call(Request,From,State) ->
    erlang:error(not_implemented).

handle_cast(Request,State) ->
    erlang:error(not_implemented).

handle_info(accept, ListenSocket) ->
    case gen_tcp:accept(ListenSocket, 2_000) of
        {ok, Socket} ->
            {ok, Pid} = tcp_echo_server_connection:start_link(socket),
            ok = gen_tcp:controlling_process(Socket, Pid),
            self() ! accept,
            {noreply, ListenSocket};
        {error, timeout} ->
            self() ! accept,
            {noreply, ListenSocket};
        {error, Reason} ->
            {stop, Reason, ListenSocket}
    end.

%% Callback module
-spec start_link(proplists:proplist()) -> gen_server:start_ret().
start_link(Options) ->
    gen_server:start_link(?MODULE, Options, []).


%%%%%%%%%%%%%%%%%%%
%% TESTS
%%%%%%%%%%%%%%%%%%%

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
    start_link_args_test() ->
        ?AssertMatch({ok, _}, start_link([{port, 8080}])).
-endif.

