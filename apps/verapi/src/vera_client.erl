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
-export([security_alarm_status/1]).

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
