-module(chat_acceptor_pool_tcp_supervisor).
-behaviour(supervisor).

%% Callbacks for `supervisor`
-export([init/1, start_link/1]).

-spec start_link(Options :: proplists:proplist()) -> supervisor:startlink_ret().
start_link(Options) ->
    supervisor:start_link(?MODULE, Options).

init(Options) ->
    SupFlags = #{
        strategy => rest_for_one
    },
    ChildSpecs = [#{
            id => chat_acceptor_pool_listener,
            start => {chat_acceptor_pool_listener, start_link, [{Options, self()}]},
            restart => transient
    }],
    {ok, {SupFlags, ChildSpecs}}.
