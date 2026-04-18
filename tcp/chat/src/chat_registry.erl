-module(chat_registry).

-export([broadcast_message/2]).
-behaviour(gen_server).
-include("types.hrl").

%% Callbacks for `gen_server`
-export([init/1, handle_call/3, handle_cast/2, start_link/0]).
%% API
-export([register_client/1, register_user/2]).

-spec start_link() -> gen_server:start_ret().
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% API
register_client(Client) ->
    gen_server:call(?MODULE, {register_client, Client}).

register_user(Username, Address) ->
    gen_server:call(?MODULE, {register_user, Username, Address}).

broadcast_message(#broadcast{} = Msg, Sender) ->
    gen_server:call(?MODULE, {dispatch, Msg, Sender}),
    erlang:error("1").

%% Callbacks
init([]) ->
    ets:new(chat_users, [
        named_table,
        protected,
        {read_concurrency, true}
    ]),
    {ok, []}.

handle_call({register_client, Client},_From,State) ->
    ok = pg:join(chat_clients, broadcast, Client),
    {reply, ok, State};
handle_call({register_user, Username, Address},_From,State) ->
    case ets:insert_new(chat_users, {Username, Address}) of
    true -> {reply, ok, State};
    false -> {reply, {error, username_taken}, State}
    end;
handle_call({dispatch, #broadcast{} = Message, Sender}, _From, State) ->
    Members = pg:get_local_members(chat_clients, broadcast),
    Recipients = lists:filter(fun(Member) -> Member =/= Sender end, Members),
    [Recipient ! {broadcast, Message} || Recipient <- Recipients, is_pid(Recipient)],
    {reply, ok, State}.

handle_cast(Request,State) ->
    erlang:error(not_implemented).
