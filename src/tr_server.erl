%%%----------------------------------------------------------------------------
%%% @author Israel Ribeiro <israveri@gmail.com>
%%% @doc RCP over TCP server. Example written
%%%      based on the Erlang and OTP in Action
%%%      book.
%%% @end
%%%----------------------------------------------------------------------------
-module(tr_server).

-behaviour(gen_server).

%% Api
-export([start_link/0, start_link/1, get_count/0, stop/0]).

%% Behaviour (gen_server callbacks)
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(DEFAULT_PORT, 1055).

-record(state, {port, listening_socket, request_count = 0}).

%%%============================================================================
%%% Api
%%%============================================================================

%%-----------------------------------------------------------------------------
%% @doc Starts the server
%%
%% @spec start_link(Port::integer()) -> {ok, Pid}
%% where
%%  Pid = pid()
%% @end
%%-----------------------------------------------------------------------------
start_link(Port) ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [Port], []).

%% @spec start_link() -> {ok, Pid}
%% @doc Calls 'start_link(Port)' using the default port
start_link() ->
  start_link(?DEFAULT_PORT).

%%-----------------------------------------------------------------------------
%% @doc Fetches the number of requests made to this server.
%% @spec get_count() -> {ok, Count}
%% where
%%  Call = integer()
%% @end
%%-----------------------------------------------------------------------------
get_count() ->
  gen_server:call(?SERVER, get_count).

%%-----------------------------------------------------------------------------
%% @doc Stops the server.
%% @spec stop() -> ok
%% @end
%%-----------------------------------------------------------------------------
stop() ->
  gen_server:cast(?SERVER, stop).

%%%============================================================================
%%% gen_server callbacks
%%%============================================================================

init([Port]) ->
  {ok, ListeningSocket} = gen_tcp:listen(Port, [{active, true}]),
  {ok, #state{port = Port, listening_socket = ListeningSocket}, 0}.

handle_call(get_count, _From, State) ->
  {reply, {ok, State#state.request_count}, State}.

handle_cast(stop, State) ->
  {stop, normal, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

handle_info({tcp, Socket, RawData}, State) ->
  do_rpc(Socket, RawData),
  RequestCount = State#state.request_count,
  {noreply, State#state{request_count = RequestCount + 1}};
handle_info(timeout, #state{listening_socket = ListeningSocket} = State ) ->
  {ok, _Sock} = gen_tcp:accept(ListeningSocket),
  {noreply, State}.

%%%============================================================================
%%% Internal functions
%%%============================================================================

do_rpc(Socket, RawData) ->
  try
    {Module, Function, Args} = split_out_mfa(RawData),
    Result = apply(Module, Function, Args),
    gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Result]))
  catch
    _Class:Err ->
      gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Err]))
  end.

split_out_mfa(RawData) ->
  MFA = re:replace(RawData, "\r\n$", "", [{return, list}]),
  {match, [Module, Function, Args]} =
    re:run(MFA,
           "(.*):(.*)\s*\\((.*)\s*\\)\s*.\s*$",
           [{capture, [1,2,3], list}, ungreedy]),
    {list_to_atom(Module), list_to_atom(Function), args_to_terms(Args)}.

args_to_terms(RawArgs) ->
  {ok, Tokens, _Args} = erl_scan:string("[" ++ RawArgs ++ "]. ", 1),
  {ok, Args} = erl_parse:parse_term(Tokens),
  Args.
