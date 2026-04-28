-module(chat_acceptor_pool_sup).
-moduledoc """
chat_acceptor_pool top level supervisor.
""".

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    SupFlags = #{
        strategy => one_for_all,
        intensity => 0,
        period => 1
    },
    ChildSpecs = [
        #{
            id => chat_server_registry,
            start => {chat_server_registry, start_link, []},
            modules => [chat_server_registry]
        },       
        #{
            id => chat_acceptor_pool_connection_supervisor,
            start => {chat_acceptor_pool_connection_supervisor, start_link, []},
            modules => [chat_acceptor_pool_connection_supervisor],
            type => supervisor
        },
        #{
            id => chat_acceptor_pool_tcp_supervisor,
            start => {chat_acceptor_pool_tcp_supervisor, start_link, [[{port, 4000}]]},
            modules => [chat_acceptor_pool_tcp_supervisor],
            type => supervisor
        }       
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
