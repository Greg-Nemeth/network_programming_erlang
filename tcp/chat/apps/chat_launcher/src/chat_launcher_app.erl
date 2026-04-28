
-module(chat_launcher_app).
-include_lib("kernel/include/logger.hrl").
-moduledoc """
chat_launcher public API
""".

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    App = case os:getenv("CHAT_IMPL") of
        "POOL" -> chat_acceptor_pool;
        "THOUSAND_ISLAND" -> chat_thousand_island;
        false -> chat_server
    end,
    ?LOG_INFO("Launching application ~s", [atom_to_list(App)]),
    case application:ensure_all_started(App) of
        {ok, _Application} -> 
            chat_launcher_sup:start_link();
        {error, Error} -> Error
    end.

stop(_State) ->
    ok.

%% internal functions
