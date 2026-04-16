-module(integration_test_SUITE).
-include_lib("common_test/include/ct.hrl").
-include("types.hrl").
-compile(export_all).

all() -> [
    server_closes_conn_on_duplicate_register    
].

init_per_suite(Config) ->
    {ok, _} = application:ensure_all_started(chat),
    CaptureLog = fun(Func, Timeout) ->
        HandlerId = capture_handler,
        Tester = self(),
        logger:add_handler(HandlerId, ?MODULE, #{config => #{tester => Tester}}),
        try
            Func(),
            receive
                {log, #{msg := {string, Msg}}} -> Msg
            after Timeout ->
                ct:fail("log not found")
            end
        after
            logger:remove_handler(HandlerId)
        end
    end,
    [{capture_log, CaptureLog} | Config].

end_per_suite(_Config) ->
    application:stop(chat).

server_closes_conn_on_duplicate_register(Config) ->
    CaptureLog = ?config(capture_log, Config),
    {ok, Client} = gen_tcp:connect("localhost", 4000, [binary]),
    EncodedMessage = chat_protocol:encode_message(#register{username = ~"jd"}),
    ok = gen_tcp:send(Client, EncodedMessage),
    Log = CaptureLog(fun() -> gen_tcp:send(Client, EncodedMessage) end, 1500),
    Log =:= ~"Invalid Register message, had already received one".

%%%%%%%%%  Callback for logger handler %%%%%%%%%
log(LogEvent, #{config := #{tester := Tester}}) ->
    Tester ! {log, LogEvent},
    ok.
