-module(tcp_echo_server_SUITE).
-include_lib("common_test/include/ct.hrl").
-compile(export_all).

all() -> [
    sends_back_received_data,
    handles_fragmented_data,
    handles_multiple_clients
].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(tcp_echo_server),
    Config.

end_per_suite(_Config) ->
    application:stop(tcp_echo_server),
    ok.

init_per_testcase(handles_multiple_clients, Config) ->
    Config;

init_per_testcase(_TestCase, Config) ->
    {ok, Socket} = gen_tcp:connect("localhost", 4000, [
            binary,
            {active, false}
    ]),
    timer:sleep(250),
    [{socket, Socket} | Config].

end_per_testcase(handles_multiple_clients, _Config) ->
    ok;

end_per_testcase(_TestCase, Config) ->
    Socket = ?config(socket, Config),
    gen_tcp:close(Socket),
    ok.
    
sends_back_received_data(Config) ->
    Socket = ?config(socket, Config),
    Payload = ~"Hello, World!\n",
    ok = gen_tcp:send(Socket, Payload),
    {ok, Payload} = gen_tcp:recv(Socket, 0, 1000),
    ok = gen_tcp:close(Socket).

handles_fragmented_data(Config) ->
    timer:sleep(150),
    Socket = ?config(socket, Config),
    Part1 = ~"Hello",
    Part2 = ~" world\nand one more\n",
    ok = gen_tcp:send(Socket, Part1),
    ok = gen_tcp:send(Socket, Part2),
    {ok, Data} = gen_tcp:recv(Socket, 0, 1000),
    %% io:format(user, "========= Data is =======[ ~p ]=======~n", [Data]),
    Data =:= ~"Hello world\nand one more\n".

handles_multiple_clients(_Config) ->
    Lambda = fun()-> 
        {ok, Socket} = gen_tcp:connect("localhost", 4000, [
                binary,
                {active, false},
                {packet, line}
            ]),
        ok = gen_tcp:send(Socket, ~"Hello world!\n"),
        {ok, Data} = gen_tcp:recv(Socket, 0, 500),
        Data =:= ~"Hello world!\n"
    end,

    Monitors = [spawn_monitor(Lambda) || _ <- lists:seq(1, 5)],

    WaitAll = fun
        WaitLoop([]) -> ok;
        WaitLoop([{Pid, Ref}| Rest ]) ->
            receive
                {'DOWN', Ref, process, Pid, normal} -> WaitLoop(Rest);
                {'DOWN', Ref, process, Pid, Reason} -> ct:fail({client_process_crashed,Reason})
            end
    end,
    WaitAll(Monitors).
