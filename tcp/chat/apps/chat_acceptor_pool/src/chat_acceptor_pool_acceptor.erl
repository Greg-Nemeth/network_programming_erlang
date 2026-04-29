-module(chat_acceptor_pool_acceptor).
-include_lib("kernel/include/logger.hrl").

-export([start_link/1, accept_loop/1]).

-spec start_link({listen_socket , Socket :: gen_tcp:socket()}) -> {ok, pid()}.
start_link(Socket) ->
    Pid = proc_lib:spawn_link(?MODULE, accept_loop, [Socket]),
    {ok, Pid}.

accept_loop(ListenSocket) ->
    case gen_tcp:accept(ListenSocket, 2000) of
        {ok, Socket} ->
            {ok, Pid} = chat_acceptor_pool_connection_supervisor:start_connection(Socket),
            ok = gen_tcp:controlling_process(Socket, Pid),
            accept_loop(ListenSocket);
        {error, timeout} -> accept_loop(ListenSocket);
        {error, Reason} ->
            ?LOG_ERROR(Reason),
            error
    end.
