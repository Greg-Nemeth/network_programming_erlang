-module(chat_connection).

-export([start_link/2]).
-include("constants.hrl").
-behaviour(gen_server).

-spec start_link(Socket :: gen_tcp:socket(), Active :: non_neg_integer()) -> gen_server:start_ret().
start_link(Socket, Active) when Active < ?CONN_LIMIT ->
  gen_server:start_link(?MODULE, Socket, []);
start_link(_, Active) -> erlang:error(io:format("Connection Limit Reached! ~p", [Active])).

