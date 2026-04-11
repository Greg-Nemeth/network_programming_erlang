%%%-------------------------------------------------------------------
%% @doc tcp_echo_server top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(tcp_echo_server_sup).

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
        #{id => acceptor,       % mandatory
          start => {
            tcp_echo_server_acceptor, start_link, [[{port, 4000}]]
          },      % mandatory
          %% restart => restart(),   % optional
          %% shutdown => shutdown(), % optional
          type => worker,       % optional
          modules => [tcp_echo_server_acceptor]}
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
