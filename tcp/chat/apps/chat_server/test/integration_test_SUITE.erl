-module(integration_test_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("chat_proto/include/types.hrl").
-export([
    server_closes_conn_on_duplicate_register/1,
    broadcast_messages/1, all/0, init_per_suite/1, end_per_suite/1, log/2
]).

all() -> [
    server_closes_conn_on_duplicate_register,
    broadcast_messages
].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(chat_server),
    CaptureLog = fun(Func, Timeout) ->
        HandlerId = capture_handler,
        Tester = self(),
        logger:add_handler(HandlerId, ?MODULE, #{config => #{tester => Tester}}),
        try
            Func(),
            receive
                {log, #{msg := {string, Msg}}} -> Msg
            after Timeout ->
                "log not found"
            end
        after
            logger:remove_handler(HandlerId)
        end
    end,
    [{capture_log, CaptureLog} | Config].

end_per_suite(_Config) ->
    application:stop(chat_server).

server_closes_conn_on_duplicate_register(Config) ->
    CaptureLog = ?config(capture_log, Config),
    {ok, Client} = gen_tcp:connect("localhost", 4000, [binary]),
    EncodedMessage = chat_protocol:encode_message(#register{username = ~"jd"}),
    ok = gen_tcp:send(Client, EncodedMessage),
    Log = CaptureLog(fun() -> gen_tcp:send(Client, EncodedMessage) end, 1500),
    Log =:= ~"Invalid Register message, had already received one".

broadcast_messages(_Config) ->
    Client_JD = connect_user(~"jd"),
    Client_Amy = connect_user(~"amy"),
    Client_Bern = connect_user(~"bern"),

    %% TODO : remove once we'll have "welcome" messages
    timer:sleep(100),

    ClientPidMap = #{User => {Pid, Socket} || {[User, Pid], Socket} <:- 
        lists:zip(
            lists:sort(ets:match(chat_users, {'$0', '$1'})),
            [Client_Amy, Client_Bern, Client_JD])
    },
     
    %% simulate amy sending a message
    BroadcastMsg = #broadcast{from_username = <<>>, contents = ~"hi"},
    EncodedMessage = chat_protocol:encode_message(BroadcastMsg),
    %% Install a debug hook that forwards internal events to the test process
    Logs = spy_messages(ClientPidMap,fun() -> gen_tcp:send(Client_Amy, EncodedMessage) end, 1000),
    %% Assert amy doesnt receive a broadcast message

    {~"amy", {Tag, _Port, _Data}} = lists:keyfind(~"amy", 1, Logs),
    ct:pal("Logs: ~p", [Logs]),
    broadcast /= Tag,

    %% assert the other clients receive the message
    {~"bern", {broadcast, #broadcast{from_username = From , contents =  Contents}}} = lists:keyfind(~"bern", 1, Logs),
    ~"amy" = From,
    ~"hi" = Contents,
    {~"jd", {tcp, _Port, _Data}} /= lists:keyfind(~"jd", 1, Logs)
    .

spy_messages(Map, Fun, Timeout) ->
    %% Trace all messages sent to the processes in our map
    Tester = self(),
    Pids = [Pid || _User := {Pid, _Socket} <- Map],
    
    Deadline = erlang:monotonic_time(millisecond) + Timeout,
    %% Set up tracing for 'receive' events
    [erlang:trace(Pid, true, ['receive', {tracer, Tester}]) || Pid <- Pids],
    
    %% Create a reverse mapping of Pid -> Username for easy lookup
    PidToUser = maps:from_list([{Pid, User} || User := {Pid, _Socket} <- Map]),
    
    Fun(),
    Logs = collect_trace_messages(Deadline, PidToUser, []),
    
    %% Disable tracing
    [erlang:trace(Pid, false, ['receive']) || Pid <- Pids],
    Logs.

collect_trace_messages(Deadline, PidToUser, Acc) ->
    Now = erlang:monotonic_time(millisecond),
    Remaining = Deadline - Now,
    case Remaining > 0 of
    true ->
        receive
            {trace, Pid, 'receive', Msg} ->
                IsMatch = is_tuple(Msg) andalso (tuple_size(Msg) >= 1) andalso
                          (element(1, Msg) =:= tcp orelse element(1, Msg) =:= broadcast),
                case {maps:find(Pid, PidToUser), IsMatch} of
                    {{ok, Username}, true} ->
                        collect_trace_messages(Deadline, PidToUser, [{Username, Msg} | Acc]);
                    _ ->
                        collect_trace_messages(Deadline, PidToUser, Acc)
                end;
            {trace, _Pid, _OtherType, _Data} ->
                collect_trace_messages(Deadline, PidToUser, Acc)
        after Remaining ->
            lists:reverse(Acc)
        end;
    false ->
        receive
            {trace, Pid, 'receive', Msg} ->
                lists:reverse(Acc)
        after 0 ->
            lists:reverse(Acc)
        end
    end.





connect_user(Username) ->
    {ok, Socket} = gen_tcp:connect("localhost", 4000, [binary]),
    RegisterMessage = #register{username = Username},
    EncodedMessage = chat_protocol:encode_message(RegisterMessage),
    ok = gen_tcp:send(Socket, EncodedMessage),
    Socket.

%%%%%%%%%  Callback for logger handler %%%%%%%%%
log(LogEvent, #{config := #{tester := Tester}}) ->
    Tester ! {log, LogEvent},
    ok.
