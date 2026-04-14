-export_type([broadcast/0, register/0]).

-record(broadcast, {from_username :: binary(),
                    contents      :: binary()}).
-type broadcast() :: #broadcast{}.

-record(register, {username :: binary()}).
-type register() :: #register{}.
