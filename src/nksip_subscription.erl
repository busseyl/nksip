%% -------------------------------------------------------------------
%%
%% Copyright (c) 2015 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc User Subscriptions Management Module.
%% This module implements several utility functions related to subscriptions.

-module(nksip_subscription).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([get_handle/1, srv_id/1, srv_name/1, call_id/1, meta/2, metas/2]).
-export([get_all/0, get_all/2]).
-export_type([field/0, status/0, subscription_state/0, terminated_reason/0]).

-include("nksip.hrl").
-include("nksip_call.hrl").


%% ===================================================================
%% Types
%% ===================================================================

-type field() :: 
    id | internal_id | status | event | class | answered | expires |
    nksip_dialog:field().

-type subscription_state() ::
    {active, undefined|non_neg_integer()} | {pending, undefined|non_neg_integer()}
    | {terminated, terminated_reason(), undefined|non_neg_integer()}.

-type terminated_reason() :: 
    deactivated | {probation, undefined|non_neg_integer()} | rejected |
    timeout | {giveup, undefined|non_neg_integer()} | noresource | invariant | 
    forced | {code, nksip:sip_code()}.

%% All dialog event states
-type status() :: 
    init | active | pending | {terminated, terminated_reason()} | binary().



%% ===================================================================
%% Public
%% ===================================================================


%% @doc Get the subscripion a request, response or id
-spec get_handle(nksip:subscription()|nksip:request()|nksip:response()|nksip:handle()) ->
    {ok, nksip:handle()} | {error, term()}.

get_handle(<<Class, $_, _/binary>>=Handle) when Class==$R; Class==$S ->
    case nksip_sipmsg:remote_meta(subscription_handle, Handle) of
        {ok, SubsHandle} -> {ok, SubsHandle};
        {error, _} -> {error, invalid_subscription}
    end;
get_handle(Term) ->
    {ok, nksip_subscription_lib:get_handle(Term)}.


%% @doc Gets thel SrvId of a dialog
-spec srv_id(nksip:subscription()|nksip:handle()) ->
    {ok, nksip:srv_id()}.

srv_id({user_subs, _, #dialog{srv_id=SrvId}}) ->
    {ok, SrvId};
srv_id(Handle) ->
    {SrvId, _SubsId, _DialogId, _CallId} = nksip_subscription_lib:parse_handle(Handle),
    {ok, SrvId}.


%% @doc Gets app's name
-spec srv_name(nksip:dialog()|nksip:handle()) -> 
    {ok, nkservice:name()} | {error, term()}.

srv_name(Term) -> 
    {ok, SrvId} = srv_id(Term),
    {ok, SrvId:name()}.


%% @doc Gets thel Call-ID of the subscription
-spec call_id(nksip:subscription()|nksip:handle()) ->
    {ok, nksip:call_id()}.

call_id({user_subs, _, #dialog{call_id=CallId}}) ->
    {ok, CallId};
call_id(Id) ->
    {_SrvId, _SubsId, _DialogId, CallId} = nksip_subscription_lib:parse_handle(Id),
    {ok, CallId}. 



%% @doc Get a specific metadata
-spec meta(field(), nksip:subscription()|nksip:handle()) ->
    {ok, term()} | {error, term()}.

meta(Field, {user_subs, _, _}=Subs) -> 
    {ok, nksip_subscription_lib:meta(Field, Subs)};
meta(Field, <<Class, $_, _/binary>>=MsgHandle) when Class==$R; Class==$S ->
    case get_handle(MsgHandle) of
        {ok, SubsHandle} -> meta(Field, SubsHandle);
        {error, Error} -> {error, Error}
    end;
meta(Field, Handle) ->
    nksip_subscription_lib:remote_meta(Field, Handle).


%% @doc Get a group of specific metadata
-spec metas([field()], nksip:subscription()|nksip:handle()) ->
    {ok, [{field(), term()}]} | {error, term()}.

metas(Fields, {user_subs, _, _}=Subs) when is_list(Fields) ->
    {ok, nksip_subscription_lib:metas(Fields, Subs)};
metas(Fields, <<Class, $_, _/binary>>=MsgHandle) when Class==$R; Class==$S ->
    case get_handle(MsgHandle) of
        {ok, SubsHandle} -> metas(Fields, SubsHandle);
        {error, Error} -> {error, Error}
    end;
metas(Fields, Handle) when is_list(Fields) ->
    nksip_subscription_lib:remote_metas(Fields, Handle).


% %% @doc Gets the subscription object corresponding to a request or subscription and a call
% -spec get_subscription(nksip:request()|nksip:response()|nksip:subscription(), nksip:call()) ->
%     {ok, nksip:subscription()} | {error, term()}.

% get_subscription({uses_subs, _Subs, _Dialog}=UserSubs, _) ->
%     UserSubs;

% get_subscription(#sipmsg{}=SipMsg, #call{}=Call) ->
%     nksip_subscription_lib:get_subscription(SipMsg, Call).


%% @doc Gets all started subscription ids.
-spec get_all() ->
    [nksip:handle()].

get_all() ->
    lists:flatten([
        case nksip_dialog:meta(subscriptions, Id) of
            {ok, Ids} -> Ids;
            _ -> []
        end
        || Id <- nksip_dialog:get_all()
    ]).


%% @doc Finds all existing subscriptions having a `Call-ID'.
-spec get_all(nksip:srv_id(), nksip:call_id()) ->
    [nksip:handle()].

get_all(SrvId, CallId) ->
    lists:flatten([
        case nksip_dialog:meta(subscriptions, Id) of
            {ok, Ids} -> Ids;
            _ -> []
        end
        || Id <- nksip_dialog:get_all(SrvId, CallId)
    ]).



