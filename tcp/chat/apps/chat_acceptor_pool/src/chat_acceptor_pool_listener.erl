-module(chat_acceptor_pool_listener).

-export([start_link/1, init/1, handle_continue/2]).
-include_lib("kernel/include/logger.hrl").
-behaviour(gen_server).

-spec start_link(Options :: tuple()) -> gen_server:start_ret().
start_link({Options, Sup}) ->
    gen_server:start_link(?MODULE, {Options, Sup}, []).

init({Options, Sup}) ->
    {port, Port} = lists:keyfind(port, 1, Options),
    ListenOpts = [
        binary,
        {active, once},
        {exit_on_close, false},
        {reuseaddr, true}
    ],

    case gen_tcp:listen(Port, ListenOpts) of
    {ok, ListenSocket} ->
        ?LOG_INFO("Started pooled chat server on ~p", [Port]),
        State = {ListenSocket, Sup},
        {ok, State, {continue, start_acceptor_pool}};
    {error, Reason} ->
        {stop, {listen_error, Reason}}
    end.

handle_continue(start_acceptor_pool, {ListenSocket, Sup}) ->
    Spec = #{
        id => chat_acceptor_pool_acceptor_supervisor,
        start => {chat_acceptor_pool_acceptor_supervisor, start_link, [{listen_socket, ListenSocket}]},
        type => supervisor
    },

    {ok, _} = supervisor:start_child(Sup, Spec),

    {noreply, {ListenSocket, Sup}}.
