-module(chat_registry).

-behaviour(gen_server).
-include("types.hrl").
-include_lib("kernel/include/logger.hrl").

%% Callbacks for `gen_server`
-export([init/1, handle_call/3, handle_cast/2, start_link/0, handle_info/2]).
%% API
-export([register/2]).
-export([broadcast_message/2]).
-record(state, { group_ref :: reference() }).

-spec start_link() -> gen_server:start_ret().
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% API
register(Username, Address) ->
    gen_server:call(?MODULE, {register, Username, Address}).

broadcast_message(#broadcast{} = Msg, Sender) ->
    gen_server:call(?MODULE, {dispatch, Msg, Sender}).

%% Callbacks
init(_) ->
    {Ref , _Pids} = pg:monitor(chat_clients, broadcast),
    State = #state{group_ref = Ref},
    ets:new(chat_users, [
        named_table,
        protected,
        {read_concurrency, true}
    ]),
    {ok, State}.


handle_call({register, Username, Address},_From,State) ->
    case ets:insert_new(chat_users, {Username, Address}) of
    true ->
        ok = pg:join(chat_clients, broadcast, Address),
        {reply, ok, State};
    false -> {reply, {error, username_taken}, State}
    end;

handle_call({dispatch, #broadcast{} = Message, Sender}, _From, State) ->
    Members = pg:get_local_members(chat_clients, broadcast),
    Recipients = lists:filter(fun(Member) -> Member =/= Sender end, Members),
    [Recipient ! {broadcast, Message} || Recipient <- Recipients, is_pid(Recipient)],
    {reply, ok, State}.

handle_info({Ref, join, Group, Pids}, #state{group_ref = Ref} = State) ->
    ?LOG_INFO("Client joined ~p with Pid: ~p", [Group, Pids]),
    {noreply, State};
handle_info({Ref, leave, Group, [Pid]}, #state{group_ref = Ref} = State) ->
    ?LOG_INFO("User with Pid: ~p removed from ~p group", [Pid, Group]),
    ets:match_delete(chat_users, {'_', Pid}),
    {noreply, State}.

handle_cast(_Request,_State) ->
    erlang:error(not_implemented).
