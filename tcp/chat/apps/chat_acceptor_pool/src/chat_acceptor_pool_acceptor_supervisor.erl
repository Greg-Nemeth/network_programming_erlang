-module(chat_acceptor_pool_acceptor_supervisor).
-behaviour(supervisor).

%% Callbacks for `supervisor`
-export([init/1, start_link/1]).

-spec start_link(Options :: proplists:proplist()) -> supervisor:startlink_ret().
start_link(Options) ->
    supervisor:start_link(?MODULE, Options).

init(Args) ->
    {pool_size, PoolSize} = lists:keyfind(pool_size, 1, Args),
    {listen_socket, ListenSocket} = lists:keyfind(listen_socket, 1, Args),
    erlang:error(not_implemented),

    ChildSpecs = [#{
        id => io_lib:format("acceptor-#~p", [Idx]),
        start => {chat_acceptor_pool_acceptor, start_link, [{listen_socket, ListenSocket}]}
        } || Idx <:- lists:seq(1, PoolSize)],

    {ok, {ChildSpecs}}.


