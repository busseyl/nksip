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

%% @doc NkSIP Registrar Plugin Callbacks
-module(nksip_registrar_callbacks).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("../include/nksip.hrl").
-include("../include/nksip_call.hrl").
-include("nksip_registrar.hrl").

-export([sip_registrar_store/2]).

-export([nks_sip_method/2, nks_sip_authorize_data/3]).
-export([nks_sip_registrar_request_opts/2, nks_sip_registrar_request_reply/3,
         nks_sip_registrar_get_index/2, nks_sip_registrar_update_regcontact/4]).


% @doc Called when a operation database must be done on the registrar database.
%% This default implementation uses the built-in memory database.
-spec sip_registrar_store(StoreOp, SrvId) ->
    [RegContact] | ok | not_found when 
        StoreOp :: {get, AOR} | {put, AOR, [RegContact], TTL} | 
                   {del, AOR} | del_all,
        SrvId :: nksip:srv_id(),
        AOR :: nksip:aor(),
        RegContact :: nksip_registrar:reg_contact(),
        TTL :: integer().

sip_registrar_store(Op, SrvId) ->
    case Op of
        {get, AOR} ->
            nklib_store:get({nksip_registrar, SrvId, AOR}, []);
        {put, AOR, Contacts, TTL} -> 
            nklib_store:put({nksip_registrar, SrvId, AOR}, Contacts, [{ttl, TTL}]);
        {del, AOR} ->
            nklib_store:del({nksip_registrar, SrvId, AOR});
        del_all ->
            FoldFun = fun(Key, _Value, Acc) ->
                case Key of
                    {nksip_registrar, SrvId, AOR} -> 
                        nklib_store:del({nksip_registrar, SrvId, AOR});
                    _ -> 
                        Acc
                end
            end,
            nklib_store:fold(FoldFun, none)
    end.



%%%%%%%%%%%%%%%% Implemented core plugin callbacks %%%%%%%%%%%%%%%%%%%%%%%%%


%% @private This plugin callback is called when a call to one of the method specific
%% application-level Service callbacks is needed.
-spec nks_sip_method(nksip_call:trans(), nksip_call:call()) ->
    {reply, nksip:sipreply()} | noreply.


nks_sip_method(#trans{method='REGISTER', request=Req}, #call{srv_id=SrvId}) ->
    Module = SrvId:callback(),
    case erlang:function_exported(Module, sip_register, 2) of
        true ->
            continue;
        false ->
            {reply, nksip_registrar:request(Req)}
    end;
nks_sip_method(_Trans, _Call) ->
    continue.


%% @private
nks_sip_authorize_data(List, #trans{request=Req}=Trans, Call) ->
    case nksip_registrar:is_registered(Req) of
        true -> {continue, [[register|List], Trans, Call]};
        false -> continue
    end.



%%%%%%%%%%%%%%%% Published plugin callbacks %%%%%%%%%%%%%%%%%%%%%%%%%


%% @private
-spec nks_sip_registrar_request_opts(nksip:request(), list()) ->
    {continue, list()}.

nks_sip_registrar_request_opts(Req, List) ->
    {continue, [Req, List]}.


%% @private
-spec nks_sip_registrar_request_reply(nksip:sipreply(), #reg_contact{}, list()) ->
    {continue, list()}.

nks_sip_registrar_request_reply(Reply, Regs, Opts) ->
    {continue, [Reply, Regs, Opts]}.


%% @private
-spec nks_sip_registrar_get_index(nksip:uri(), list()) ->
    {continue, list()}.

nks_sip_registrar_get_index(Contact, Opts) ->
    {continue, [Contact, Opts]}.


%% @private
-spec nks_sip_registrar_update_regcontact(#reg_contact{}, #reg_contact{}, 
                                             nksip:request(), list()) ->
    {continue, list()}.

nks_sip_registrar_update_regcontact(RegContact, Base, Req, Opts) ->
    {continue, [RegContact, Base, Req, Opts]}.
