-module(chat_client).
-export([main/1]).

main(_Args) ->
    {ok, _} = application:ensure_all_started(chat_client),
    receive
        _ -> ok
    end.
