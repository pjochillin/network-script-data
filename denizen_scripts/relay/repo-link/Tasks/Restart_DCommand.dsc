Restart_DCommand:
    type: task
    PermissionRoles:
# - ██ [ Staff Roles  ] ██
        - Lead Developer
        - External Developer
        - Developer

# - ██ [ Public Roles ] ██
        - Lead Developer
        - Developer
    definitions: Message|Channel|Author|Group
    debug: false
    Context: Color
    script:
# - ██ [ Clean Definitions & Inject Dependencies ] ██
    - inject Role_Verification
    - inject Command_Arg_Registry
        
# - ██ [ Verify Arguments                        ] ██
    - if <[Args].is_empty>:
        - define Args relay
    - else if <[Args].size> == 1:
        - if <[Args].first> == all:
            - foreach <bungee.list_servers> as:s:
                - bungee <[s]>:
                    - adjust server restart
            - define Embeds "<list_single[<map.with[color].as[<[Color]>].with[description].as[All servers were successfully restarted!]>]>"
        - else if <bungee.list_servers.contans[<[Args].first>].not>:
            - stop
        - else:
            - define Embeds "<list_single[<map.with[color].as[<[Color]>].with[description].as[<[Args].first.to_titlecase> was successfully restarted!]>]>"
    - else:
        - if <list[l|log].contains_any[<[Args].parse[after[-]]>]>:
            # log stuff
        - if <list[c|conf|confirmation].contains_any[<[Args].parse[after[-]]>]>:
            # conf stuff
        - if <list[d|delay|w|wait].contains_any[<[Args].parse[before[:]]>]>:
            - if <[Args].filter_tag[<list[d|delay|w|wait].contains[<[filter_value].before[:]>]>].size> > 1:
                - stop
            - define wait_time <[Args].filter_tag[<list[d|delay|w|wait].contains[<[filter_value].before[:]>]>]||null>
            - if <[wait_time].size> > 1:
                - stop
            - if <duration[<[wait_time].first.after[:]>]||null> == null:
                - stop
            - if <duration[<[wait_time].first.after[:]>].in_seconds> > 5:
                - define wait_time 5s


    # webhook creation
    - define color Code
    - inject Embedded_Color_Formatting
    # - define Embeds "<list_single[<map.with[color].as[<[Color]>].with[description].as[<[Args].first.to_titlecase> was successfully restarted!]>]>"
    - define Data <map.with[username].as[<[Server]><&sp>Server].with[avatar_url].as[https://cdn.discordapp.com/attachments/625076684558958638/739228903700168734/icons8-code-96.png].with[embeds].as[<[Embeds]>].to_json>

    - define Hook <script[DDTBCTY].data_key[WebHooks.<[Channel]>.hook]>
    - define Headers <list[User-Agent/really|Content-Type/application/json]>
    - ~webget <[Hook]> data:<[Data]> headers:<[Headers]>
    # run restart command
    - bungee <[Args].first>:
        - if <[wait_time]> != null:
            - wait <[wait_time]>
        - flag server Queue.Restart.Discord_Log_Response
        - adjust server restart
