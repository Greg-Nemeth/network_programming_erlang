%%%-------------------------------------------------------------------
%% @doc chat_acceptor_pool public API
%% @end
%%%-------------------------------------------------------------------

-module(chat_acceptor_pool_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    chat_acceptor_pool_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
