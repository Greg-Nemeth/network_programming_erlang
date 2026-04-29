-module(chat_acceptor_pool_acceptor_supervisor).
-include_lib("kernel/include/logger.hrl").
-behaviour(supervisor).

%% Callbacks for `supervisor`
-export([init/1, start_link/1]).

-spec start_link(Options :: proplists:proplist()) -> supervisor:startlink_ret().
start_link(Options) ->
    supervisor:start_link(?MODULE, Options).

init(Args) ->
    PoolSize = proplists:get_value(pool_size, Args, 10),
    ?LOG_ALERT("---------- args in acceptor sup : ~p   ------------", [Args]),
    {listen_socket, ListenSocket} = lists:keyfind(listen_socket, 1, Args),
   

    ChildSpecs = [#{
        id => list_to_atom("acceptor_" ++ integer_to_list(Idx)),
        start => {chat_acceptor_pool_acceptor, start_link, [ListenSocket]},
        restart => transient,
        type => worker
        } || Idx <- lists:seq(1, PoolSize)],

    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },

    {ok, {SupFlags, ChildSpecs}}.
