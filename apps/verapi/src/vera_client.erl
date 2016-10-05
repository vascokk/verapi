%%%-------------------------------------------------------------------
%%% @author vasco
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Oct 2016 21:08
%%%-------------------------------------------------------------------
-module(vera_client).
-author("vasco").

%% API
-export([security_alarm_status/1, run_scene/1]).

security_alarm_status(Status) ->
  Method = get,

  SceneId = case Status of
                 armed -> wf:config(vera_client, armed_scene_id);
              disarmed -> wf:config(vera_client, disarmed_scene_id)
            end,
  {IP, Port} =  wf:config(vera_client, vera_uri),
  URL = "http://" ++ IP ++":" ++ Port
        ++ wf:config(vera_client, scene_control_res)
        ++ wf:to_list(SceneId),
  Headers = [],
  Payload = <<>>,
  Options = [],
  hackney:request(Method, list_to_binary(URL),
                  Headers, Payload, Options).

run_scene(security_on) ->
  case vera_client:security_alarm_status(armed) of
    {ok, _, _, _} -> os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_armed));
    {error, _} -> os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_sorry))
  end;
run_scene(security_off) ->
  case vera_client:security_alarm_status(disarmed) of
    {ok, _, _, _} -> os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_disarmed));
    {error, _} -> os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_sorry))
  end.