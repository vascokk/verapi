-module(index).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("nitro/include/nitro.hrl").

peer()    -> wf:to_list(wf:peer(?REQ)).
%%message() -> wf:js_escape(wf:html_encode(wf:to_list(wf:q(message)))).
main() ->
  #dtl{file = "index", app = verapi, bindings = [{body, body()}]}.
body() ->
  Center = "margin:10 auto; width: 50%; border: 3px solid; padding: 10px;",
  BtnStyle = "padding: 20px;",
  BtnClass = [btn, "btn-default", "btn-primary", "btn-lg"],
  BtnPanelStyle = "padding: 3px;width: 50%;margin: 0 auto;",
  [#panel{
          id = keypad,
          class=["panel", "panel-default"], 
          style="padding: 3px; margin: 0 auto; width:350px;",
          body = [
                  #panel{
                     class=["panel-body"],
                     style=BtnPanelStyle,
                     body = [
                        #button{id = '1', style=BtnStyle, class=BtnClass, body = "1", postback = {keypad, "1"}, source = []},
                        #button{id = '2', style=BtnStyle, class=BtnClass, body = "2", postback = {keypad, "2"}, source = []},
                        #button{id = '3', style=BtnStyle, class=BtnClass, body = "3", postback = {keypad, "3"}, source = []}
                     ]},
                  #panel{
                    class=["panel-body"],
                    style=BtnPanelStyle,
                      body = [
                        #button{id = '4', style=BtnStyle, class=BtnClass, body = "4", postback = {keypad, "4"}, source = []},
                        #button{id = '5', style=BtnStyle, class=BtnClass, body = "5", postback = {keypad, "5"}, source = []},
                        #button{id = '6', style=BtnStyle, class=BtnClass, body = "6", postback = {keypad, "6"}, source = []}
                      ]},
                  #panel{class=["panel-body"],
                    style=BtnPanelStyle,
                      body = [
                        #button{id = '7', style=BtnStyle, class=BtnClass, body = "7", postback = {keypad, "7"}, source = []},
                        #button{id = '8', style=BtnStyle, class=BtnClass, body = "8", postback = {keypad, "8"}, source = []},
                        #button{id = '9', style=BtnStyle, class=BtnClass, body = "9", postback = {keypad, "9"}, source = []}
                      ]},
                  #panel{class=["panel-body"],
                    style=BtnPanelStyle,
                      body = [
                        #button{id = '#', style=BtnStyle, class=BtnClass, body = "#", postback = {keypad, "#"}, source = []},
                        #button{id = '0', style=BtnStyle, class=BtnClass, body = "0", postback = {keypad, "0"}, source = []},
                        #button{id = '*', style=BtnStyle, class=BtnClass, body = "*", postback = {keypad, "*"}, source = []}
                      ]},
                  #panel{id = status,
                    class=["panel-footer"], style="color: green;padding: 3px;width: 100px; margin: 0 auto;text-align: center;",
                    body="Not armed"
                  },
                  #panel{id = pinpanel}
            ]}
    %%#textbox{id=message},
    %%#button{id=send,body="Chat",postback=chat,source=[message]},ge]},
    %%wf:wire(#alert{text = "Hello!"})
  ].

event(init) ->
  wf:reg(pidev),
  wf:session(pin, undefined),
  wf:session(entry, undefined),
  wf:session(status, not_armed),
  case wf:config(vera_client, audio_player) of
    undefined -> set_default_player();
    Player -> wf:session(audio_player, Player ++ " ")
  end,
  os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_hello));
%%event(chat) -> wf:send(pidev,{client,{peer(),message()}});
%%event({client,{P,M}}) -> wf:insert_bottom(history,#panel{id=history,body=[P,": ",M,#br{}]});
event({keypad, Key}) ->
  Entry = case wf:session(entry) of
            undefined -> wf:session(entry, Key), Key;
            Prev when is_list(Prev) -> wf:session(entry, Prev ++ Key), Prev ++ Key
          end,
  %%wf:send(pidev,{client,{peer(), wf:session(pin)}});
  wf:update(pinpanel,#panel{id=pinpanel,body=[wf:session(entry)]}),
%%  n2o_log:info(?MODULE, "Entry: ~p",[Entry]),
%%  n2o_log:info(?MODULE, "Last key: ~p",[hd(lists:reverse(Entry))]),
  case hd(lists:reverse(Entry)) of
    $# -> set_status(Entry),
           wf:session(entry, ""),
           wf:update(pinpanel,#panel{id=pinpanel,body=[""]});
    _ -> ok
  end;
event(Event) -> wf:info(?MODULE,"Unknown Event: ~p~n",[Event]).


%%Internals
set_status(Entry) ->
  Pin = lists:reverse(tl(lists:reverse(Entry))),
  case wf:session(status) of
    not_armed -> arm(Pin);
    armed -> disarm(Pin)
  end.

disarm(Pin) ->
  case Pin =:= wf:session(pin) of
    true -> run_scene(security_off),
            wf:session(status, not_armed),
            wf:update(status,#panel{id=status,
                                    body="Not armed",
                                    class=["panel-footer"],
                                    style="color: green; padding: 3px;width: 100px; margin: 0 auto;text-align: center;"});
    _ -> os:cmd(wf:session(audio_player) ++ wf:config(vera_client, audio_wrongpin))
  end.

arm(Pin) ->
  wf:session(pin, Pin),
  wf:session(status, armed),
  run_scene(security_on),
  wf:update(status,#panel{id=status,body="ARMED", class=["panel-footer"],
    style="color: red; padding: 3px;width: 100px; margin: 0 auto;text-align: center;"}).

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

set_default_player() ->
  case os:type() of
    {unix,darwin} -> wf:session(audio_player, "afplay "); %%for testing
    {unix,linux} -> wf:session(audio_player, "omxplayer "); %% on RPi
    OS -> error(io:format("Cannot set audio player for OS type ~p. Please, define audio_player in the sys.config file!", [OS]))
end.