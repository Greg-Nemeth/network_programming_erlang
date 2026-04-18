-module(chat_sup).
-moduledoc """
chat top level supervisor.
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
            id => chat_acceptor,
            start => {chat_acceptor, start_link, [[{port, 4000}]]},
            modules => [chat_acceptor]
        },
        #{
            id => chat_registry,
            start => {chat_registry, start_link, []},
            modules => [chat_registry]
        },
        #{
            id => chat_clients,
            start => {pg, start_link, [chat_clients]},
            type => worker
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
