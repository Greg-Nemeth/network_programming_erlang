%%%-------------------------------------------------------------------
%% @doc tcp_echo_server public API
%% @end
%%%-------------------------------------------------------------------

-module(tcp_echo_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    tcp_echo_server_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
