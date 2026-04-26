-module(chat_server_conn_sup).
-behaviour(supervisor).

%% Callbacks for `supervisor`
-export([init/1, start_child/1]).


start_child(Socket) ->
    {active, Active} = lists:keyfind(active, 1, supervisor:count_children(?MODULE)) ,
    supervisor:start_child(?MODULE, [Socket, Active]).


init([]) ->
    SupFlags = #{strategy => simple_one_for_one, intensity => 5, period => 10},
    ChildSpecs = [#{
        id => chat_server_connection,
        start => {chat_server_connection, start_link, []},
        restart => temporary
    }],
    {ok, {SupFlags, ChildSpecs}}.
