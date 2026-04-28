-module(chat_acceptor_pool_connection_supervisor).
-behaviour(supervisor).

%% Callbacks for `supervisor`
-export([init/1, start_link/1, start_connection/1]).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
-spec start_link(Options :: proplists:proplist()) -> supervisor:startlink_ret().
start_link(Options) ->
    supervisor:start_link({local, ?MODULE},?MODULE, Options).

start_connection(Socket) ->
    supervisor:start_child(?MODULE, [Socket]).

init(_Options) ->
    SupFlags = #{strategy => simple_one_for_one},
    ChildSpec = [
        #{
            id => chat_server_connection,
            start => {chat_server_connection, start_link, []},
            restart => temporary
        }
    ],
    {ok, SupFlags, ChildSpec}.
