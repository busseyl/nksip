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

%% @doc Plugin implementing automatic registrations and pings support for Services.
-module(nksip_uac_auto_register).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([start_ping/4, stop_ping/2, get_pings/1]).
-export([start_register/4, stop_register/2, get_registers/1]).

-include("nksip_uac_auto_register.hrl").


%% ===================================================================
%% Public
%% ===================================================================


%% @doc Starts a new registration serie.
-spec start_register(nkservice:name()|nksip:srv_id(), term(), nksip:user_uri(), 
                     nksip:optslist()) -> 
    {ok, boolean()} | {error, term()}.

start_register(Srv, RegId, Uri, Opts) when is_list(Opts) ->
    try
        case nkservice_srv:get_srv_id(Srv) of
            {ok, SrvId} -> ok;
            _ -> SrvId = throw(service_not_found)
        end,
        case lists:keymember(meta, 1, Opts) of
            true -> throw(meta_not_allowed);
            false -> ok
        end,
        case nksip_call_uac_make:make(SrvId, 'REGISTER', Uri, Opts) of
            {ok, _, _} -> ok;
            {error, MakeError} -> throw(MakeError)
        end,
        Msg = {nksip_uac_auto_register_start_reg, RegId, Uri, Opts},
        nkservice:call(SrvId, Msg)
    catch
        throw:Error -> {error, Error}
    end.


%% @doc Stops a previously started registration serie.
-spec stop_register(nkservice:name()|nksip:srv_id(), term()) -> 
    ok | not_found.

stop_register(Srv, RegId) ->
    nkservice:call(Srv, {nksip_uac_auto_register_stop_reg, RegId}).
    

%% @doc Get current registration status.
-spec get_registers(nkservice:name()|nksip:srv_id()) -> 
    [{RegId::term(), OK::boolean(), Time::non_neg_integer()}].
 
get_registers(Srv) ->
    nkservice:call(Srv, nksip_uac_auto_register_get_regs).



%% @doc Starts a new automatic ping serie.
-spec start_ping(nkservice:name()|nksip:srv_id(), term(), nksip:user_uri(), 
                 nksip:optslist()) -> 
    {ok, boolean()} | {error, invalid_uri}.


start_ping(Srv, PingId, Uri, Opts) when is_list(Opts) ->
    try
        case nkservice_srv:get_srv_id(Srv) of
            {ok, SrvId} -> ok;
            _ -> SrvId = throw(service_not_found)
        end,
        case lists:keymember(meta, 1, Opts) of
            true -> throw(meta_not_allowed);
            false -> ok
        end,
        case nksip_call_uac_make:make(SrvId, 'OPTIONS', Uri, Opts) of
            {ok, _, _} -> ok;
            {error, MakeError} -> throw(MakeError)
        end,
        Msg = {nksip_uac_auto_register_start_ping, PingId, Uri, Opts},
        nkservice:call(SrvId, Msg)
    catch
        throw:Error -> {error, Error}
    end.


%% @doc Stops a previously started ping serie.
-spec stop_ping(nkservice:name()|nksip:srv_id(), term()) -> 
    ok | not_found.

stop_ping(Srv, PingId) ->
    nkservice:call(Srv, {nksip_uac_auto_register_stop_ping, PingId}).
    

%% @doc Get current ping status.
-spec get_pings(nkservice:name()|nksip:srv_id()) -> 
    [{PingId::term(), OK::boolean(), Time::non_neg_integer()}].
 
get_pings(Srv) ->
    nkservice:call(Srv, nksip_uac_auto_register_get_pings).

