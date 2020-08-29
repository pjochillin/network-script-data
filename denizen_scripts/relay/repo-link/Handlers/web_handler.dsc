web_handler:
  type: world
  debug: false
  Domains:
    Github: 140.82.115
    self: 0:0:0:0:0:0:0:1
  temp:
    - yaml id:movetohub create
    - define Bear <map.with[UUID].as[d82da59b-44fc-4a72-a20d-a7f7ae5ef382]>
    - define GitHub <map.with[login].as[BehrRiley]>
    - define GitHub <[GitHub].with[id].as[46008563]>
    - define GitHub <[GitHub].with[avatar_url].as[https://avatars3.githubusercontent.com/u/46008563?v=4]>
    - define GitHub <[GitHub].with[url].as[https://github.com/BehrRiley]>
    - define Bear <[Bear].with[GitHub].as[<[GitHub]>]>

    - define Discord <map.with[id].as[194619362223718400]>
    - define Discord <[Discord].with[username].as[Behr]>
    - define Discord <[Discord].with[avatar].as[dee7262dd67443aec6bb90920625b2ba]>
    - define Discord <[Discord].with[discriminator].as[5305]>
    - define Discord <[Discord].with[mfa_enabled].as[true]>
    - define Bear <[Bear].with[Discord].as[<[Discord]>]>
    
    - define Bear "<[Bear].with[Rank].as[rank: §x§f§f§0§c§0§0T§x§f§f§1§8§0§0h§x§f§f§2§4§0§0e§x§f§f§3§0§0§0 §x§f§f§3§c§0§0A§x§f§f§4§8§0§0n§x§f§f§5§4§0§0a§x§f§f§6§0§0§0r§x§f§f§6§c§0§0c§x§f§f§7§8§0§0h§x§f§f§8§4§0§0i§x§f§f§9§0§0§0c§x§f§f§9§c§0§0 §x§f§f§a§8§0§0A§x§f§f§b§4§0§0d§x§f§f§c§0§0§0m§x§f§f§c§c§0§0i§x§f§f§d§8§0§0n§x§f§f§e§4§0§0i§x§f§f§f§0§0§0s§x§f§f§f§c§0§0t§x§f§6§f§f§0§0r§x§e§a§f§f§0§0a§x§d§e§f§f§0§0t§x§d§2§f§f§0§0o§x§c§6§f§f§0§0r]>"
    - define Bear "<[Bear].with[Role].as[Lead Developer]>"
    - yaml id:movetohub set players:->:<[Bear]>
  events:
    on reload scripts:
      - if <yaml.list.contains[movetohub]>:
        - yaml id:movetohub unload
      - inject locally temp
    on server start:
      - web start port:25580
      - inject locally temp
    on get request:
      - if <context.request||invalid> == favicon.ico:
        - stop
      - announce to_console "<&c>--- get request ----------------------------------------------------------"
      - inject Web_Debug.Get_Response

      - choose <context.request>:
        - case /oAuth/GitHub:
        # % ██ [ Cache Data                      ] ██
          - define Code <context.query_map.get[code]>
          - define State <context.query_map.get[state]>
          - define Platform GitHub
          - define Headers <yaml[oAuth].read[Headers].include[<yaml[oAuth].read[GitHub.Token_Exchange.Headers]>]>

        # % ██ [ Token Exchange                  ] ██
          - define URL <yaml[oAuth].read[URL_Scopes.GitHub.Token_Exchange]>
          - define Data <list[oAuth_Parameters|GitHub.Application|GitHub.Token_Exchange.Parameters]>
          - define Data <[Data].parse_tag[<yaml[oAuth].parsed_key[<[Parse_Value]>]>].merge_maps>
          - define Data <[Data].to_list.parse_tag[<[Parse_Value].before[/]>=<[Parse_Value].after[/]>].separated_by[&]>

          - ~webget <[URL]> Headers:<[Headers]> Data:<[Data]> save:response
          - announce to_console "<&c>--- Token Exchange ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - stop
          - flag server Test.GitHub.TokenExchange:<util.parse_yaml[{"Data":<entry[Response].result>}].get[Data]>
        #| notable error: error=bad_verification_code&error_description=The+code+passed+is+incorrect+or+expired.&error_uri=https%3A%2F%2Fdocs.github.com%2Fapps%2Fmanaging-oauth-apps%2Ftroubleshooting-oauth-app-access-token-request-errors%2F%23bad-verification-code
        #| occurs when refreshing the page / using a bad token

        # % ██ [ Save Access Token Response Data ] ██
          - define oAuth_Data <entry[response].result.split[&].parse[split[=].limit[2].separated_by[/]].to_map>
          - define Access_Token <[oAuth_Data].get[access_token]>

        # % ██ [ Obtain User Info                ] ██
          - define Headers "<[Headers].include[Authorization/token <[Access_Token]>]>"
          - ~webget https://api.github.com/user Headers:<[Headers]> save:response
          - announce to_console "<&c>--- Obtain User Info ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - stop
          - flag server Test.GitHub.ObtainUserData:<util.parse_yaml[{"Data":<entry[Response].result>}].get[Data]>

        # % ██ [ Save User Data                  ] ██
          - define UserData <util.parse_yaml[{"Data":<entry[Response].result>}].get[Data]>
          - define Login <[UserData].get[login]>
          - define Avatar <[UserData].get[avatar_url]>
          - define ID <[UserData].get[id]>
          - define Creation_Data <time[<[UserData].get[created_at].replace[-].with[/].before[Z].split[T].separated_by[_]>]>

        # % ██ [ Obtain User Repository Data     ] ██
          - define Headers "<[Headers].include[Authorization/token <[Access_Token]>]>"
          - ~webget https://api.github.com/user/repos Headers:<[Headers]> save:response
          - announce to_console "<&c>--- Obtain User Repo Data ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - stop
          - flag server Test.GitHub.ObtainUserRepoData:<util.parse_yaml[{"Data":<entry[Response].result>}].get[Data]>

          - define Main_Repo <[Login]>/network-script-data
          - define From_Repo BehrRiley/network-script-data
          - define Repositories <util.parse_yaml[{"Data":<entry[Response].result>}].get[Data].parse_tag[<[Parse_Value].get[full_name]>]>

        # % ██ [ Manage Fork                   ] ██
          - if <[Login]||invalid> != Invalid && !<[Repositories].contains[<[Main_Repo]>]>:
            - announce to_console "<&c>-Fork Creation --------------------------------------------------------------"
            - ~webget https://api.github.com/repos/<[From_Repo]>/forks Headers:<[Headers]> method:POST save:response
            - announce to_console "<&c>--- Manage Fork ----------------------------------------------------------"
            - inject Web_Debug.Webget_Response
            - if <entry[response].failed>:
              - stop
          - else:
            - announce to_console "<&c>-No Fork Being Made ---------------------------------------------------------"

          # % ██ [ Obtain Branch Information     ] ██
          - ~webget https://api.github.com/repos/<[Main_Repo]>/branches headers:<[Headers]> save:response method:GET
          - announce to_console "<&c>--- Obtain Branch Information ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - stop
          - announce to_console '<&3>Branches<&6>: <&3><util.parse_yaml[{"Data":<entry[Response].result>}].get[Data].parse_tag[<[Parse_Value].get[name]>]>'

          # % ██ [ Obtain Webhook Information    ] ██
          - ~webget https://api.github.com/repos/<[Main_Repo]>/hooks headers:<[Headers]> save:response method:GET
          - announce to_console "<&c>--- Obtain Webhook Information ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - stop
          - announce to_console '<&3>Webhooks<&6>: <&3><util.parse_yaml[{"Data":<entry[Response].result>}].get[Data].parse_tag[<[Parse_Value].get[name]>]>'
          - define Webhook_Data <util.parse_yaml[{"Data":<entry[Response].result>}].get[Data]>
          - define Webhook_IDs <[Webhook_Data].parse_tag[<[Parse_Value].get[id]>]>
          - define Webhooks_Content_Types <[Webooks].parse_tag[<map.with[id].as[<[Parse_Value]>].with[content_type].as[<[Webhook_Data].filter[get[ID].is[==].to[<[Parse_Value]>]].first.get[config].get[content_type]>]>]>
        #| Notable Error: Mapped within each webhook list contains a previous response: {"last_response":[{"code":"200","status":"active","message": "OK"}]
        #| erroneous currently unknown but could use to re-verify DNS records as well as verify port stability

        # % ██ [ Create Webhook                   ] ██
          - if <[Webhooks].is_empty>:
            - announce to_console "<&c>-WebHook Creation --------------------------------------------------------------"
            - define Data '{"config": {"url": "http://76.119.243.194:25580/github/<[Main_Repo]>","content_type": "json"}}'
            - announce to_console "<&4>Connecting: https://api.github.com/repos/<[Main_Repo]>/hooks with a hook to: http://76.119.243.194:25580/github/<[Main_Repo]>"
            - ~webget https://api.github.com/repos/<[Main_Repo]>/hooks Headers:<[Headers]> method:POST data:<[Data]> save:response
            - announce to_console "<&c>--- Create Webhook ----------------------------------------------------------"
            - inject Web_Debug.Webget_Response
        #| Notable Error: Exists already: {"message":"Validation Failed","errors":[{"resource":"Hook","code":"custom","message":"Hook already exists on this repository"}],"documentation_url":"https://docs.github.com/rest/reference/repos#create-a-repository-webhook"}
        #| occurs when the webhook exists already
          

        - case /oAuth/Discord:
        # % ██ [ Cache Data                      ] ██
          - define Query <context.query_map>
          - if <[Query].contains[error]> && <[Query].get[error]> == acces_denied:
            - announce to_console "<&c>The resource owner or authorization server denied the request"
            - stop
          - if !<[Query].contains[code|state]>
            - announce to_console "<&c>This is likely URL engineered."
            - stop

          - define Code <context.query_map.get[code]>
          - define State <context.query_map.get[state]>
          - define Platform Discord

          - define Headers <yaml[oAuth].read[Headers].include[<yaml[oAuth].read[Discord.Token_Exchange.Headers]>]>
        
          - if !<proc[discord_oauth_validate_state].context[<[state]>]>:
            # | this should be replaced with a confirmation that they have already linked
            - determine passively FILE:../../../../web/pages/discord_linked.html
            - stop
          - run discord_oauth def:<[state]>|remove
          - determine passively FILE:../../../../web/pages/discord_linked.html

        # % ██ [ Token Exchange                  ] ██
          - define URL <yaml[oAuth].read[URL_Scopes.Discord.Token_Exchange]>
          - define Data <list[oAuth_Parameters|Discord.Application|Discord.Token_Exchange.Parameters]>
          - define Data <[Data].parse_tag[<yaml[oAuth].parsed_key[<[Parse_Value]>]>].merge_maps>
          - define Data <[Data].to_list.parse_tag[<[Parse_Value].before[/]>=<[Parse_Value].after[/]>].separated_by[&]>

          - ~webget <[URL]> Headers:<[Headers]> Data:<[Data]> save:response
          - announce to_console "<&c>--- Token Exchange ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - announce to_console "<&c>failure; ending queue."

        # % ██ [ Save Access Token Response Data ] ██
          - define access_token_response <util.parse_yaml[<entry[response].result>]>
          - define access_token <[access_token_response].get[access_token]>
          - define refresh_token <[access_token_response].get[refresh_token]>
          - define expires_in <[access_token_response].get[expires_in]>

        # % ██ [ Obtain User Info                ] ██
          - define URL <yaml[oAuth].read[URL_Scopes.Discord.Identify]>
          - define Headers <[Headers].include[<yaml[oAuth].parsed_key[Discord.Client_Credentials.Headers]>]>

          - ~webget <[URL]> headers:<[Headers]> save:response
          - announce to_console "<&c>--- Obtain User Info ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - announce to_console "<&c>failure; ending queue."

        # % ██ [ Save User Data                  ] ██
          - define User_Data <util.parse_yaml[<entry[response].result>]>
          - narrate "<&c>User_Data: <&2><[User_Data]>"
          - define User_ID <[User_Data].get[id]>
          - define Avatar https://cdn.discordapp.com/avatars/<[User_ID]>/<[User_Data].get[avatar]>

        # % ██ [ Send to The-Network             ] ██
          - define url http://76.119.243.194:25580
          - define request relay/discorduser
          - define query <map.with[uuid].as[<[state].after[_]>]>
          - define query <[query].with[refresh_token].as[<[refresh_token]>]>
          - define query <[query].with[expires_in].as[<[expires_in]>]>
          - define query <[query].with[id].as[<[User_Data].get[id]>]>
          - define query <[query].with[username].as[<[User_Data].get[username]>]>
          - define query <[query].with[avatar].as[https://cdn.discordapp.com/avatars/<[User_ID]>/<[User_Data].get[avatar]>]>
          - define query <[query].with[discriminator].as[<[User_Data].get[discriminator]>]>
          - define query <[query].with[mfa_enabled].as[<[User_Data].get[mfa_enabled]>]>
          - define query <[query].parse_value_tag[<[parse_key]>=<[parse_value]>].values.separated_by[&]>
          - ~webget <[url]>/<[request]>?<[query]>

        # % ██ [ Obtain User Connections         ] ██
          - define URL <yaml[oAuth].read[URL_Scopes.Discord.Connections]>
          - ~webget <[URL]> headers:<[Headers]> save:response
          - announce to_console "<&c>--- Obtain User Connections ----------------------------------------------------------"
          - inject Web_Debug.Webget_Response
          - if <entry[response].failed>:
            - announce to_console "<&c>failure; ending queue."

          - define User_Data <util.parse_yaml[{"Data":<entry[response].result>}].get[Data]>

        # % ██ [ WebGet Hosting         ] ██
        - case /webget:
          - if <server.has_file[../../../../web/webget/<context.query_map.get[name]||invalid>]>:
            - determine FILE:../../../../web/webget/<context.query_map.get[name]>
          - else:
            - determine CODE:404

        # % ██ [ FavIcon         ] ██
        - case /favicon.ico:
          - determine FILE:../../../../web/favicon.ico

        # % ██ [ CSS Hosting         ] ██
        - case /css:
          - if <server.has_file[../../../../web/css/<context.query_map.get[name]||invalid>.css]>:
            - determine FILE:../../../../web/css/<context.query_map.get[name]>.css

        # % ██ [ Webpages         ] ██
        - case /page:
          - if <server.has_file[../../../../web/pages/<context.query_map.get[name]||invalid>.html]>:
            - determine FILE:../../../../web/pages/<context.query_map.get[name]>.html

        # % ██ [ Images         ] ██
        - case /image:
          - if <server.has_file[../../../../web/images/<context.query_map.get[name]||invalid>]>:
            - determine FILE:../../../../web/images/<context.query_map.get[name]>

    on post request:
      - define Domain <context.address>
      - inject Web_Debug.Post_Request

      - if <[Domain].starts_with[<script.data_key[Domains.Github]>]>:
        - define Map <util.parse_yaml[{"Data":<context.query>}].get[Data]>
        - define Request <context.request.after[github/]>
        - define Script <yaml[shell].read[file.git_pull]>

        - flag server testindex:++
        - yaml id:testindex<server.flag[testindex]> create
        - yaml id:testindex<server.flag[testindex]> set data:<[Map]>
        - yaml id:testindex<server.flag[testindex]> savefile:testindex<server.flag[testindex]>.yml

        #| ACTION key: The action that was performed.
        - if <[Map].contains[action]>:
          #| pull requests can be any of:
          #| opened|edited|closed|assigned|unassigned|review_requested|review_request_removed|ready_for_review|labeled|unlabeled|synchronize|locked|unlocked|reopened
          #| If the action is closed and the pull_request.merged key is true, the pull request was merged.
          #| If the action is closed and the pull_request.merged key is false, the pull request was closed with unmerged commits.

          - if <[Map].contains[pull_request]>:
            - if <[Map].get[action]> == opened:
              - announce to_console "<&a>---- Pull request was created. ---------------------------------------"
              - stop
            - else if <[Map].get[action]> == closed && <[Map].get[pull_request].get[merged]> == true:
              - announce to_console "<&a>---- Pull request was closed with ummerged commits. ------------------"
              - stop
            - else if <[Map].get[action]> == closed && <[Map].get[pull_request].get[merged]> == true:
              - announce to_console "<&a>---- Pull request was merged. ----------------------------------------"
            #| pull request reviews:
            - else if <[Map].get[Action]> == submitted:
              - announce to_console "<&a>---- A pull request review is submitted into a non-pending state. ----"
              - stop
            - else if <[Map].get[Action]> == edited:
              - announce to_console "<&a>---- The body of a review has been edited. ---------------------------"
              - stop
            - else if <[Map].get[Action]> == dismissed:
              - announce to_console "<&a>---- A review has been dismissed. ------------------------------------"
              - stop

          #| Issues:
          #| opened|edited|deleted|pinned|unpinned|closed|reopened|assigned|unassigned|labeled|unlabeled|locked|unlocked|transferred|milestoned|demilestoned.
            - else if <[Map].contains[issue]>:
              - choose <[Map].get[action]>:
                - case opened:
                  - announce to_console "<&a>---- New issued was created. -------------------------------------"
                - case closed:
                  - announce to_console "<&a>---- New issued was closed. --------------------------------------"
              - stop

          - else if <[Map].contains[ref|ref_type]> && <[Map].get[ref_type]> == branch:
            - if <[Map].contains[master_branch]>:
              - announce to_console "<&a>---- New branch was created. -----------------------------------------"
            - else:
              - announce to_console "<&a>---- Branch was deleted. ---------------------------------------------"
            - stop

        - shell <[Script]> <[Request]>
        - if <[Map].contains[ref|commits]>:
          - define Author_Map <[Map].get[Sender]>
          - define GitHub_User_ID <[Author_Map].get[ID]>
          - define Player_Map <yaml[movetohub].filter[get[GitHub].get[id].is[==].to[<[GitHub_User_ID]>]].first>
          - define Role <[Player_Map].get[Role]>
  
          - define User_Name "<[Author_Map].get[login]> - <[Role]>"
          - define User_Link <[Author_Map].get[html_url]>
          - define User_Avatar <[Author_Map].get[avatar_url]>

          - define Body_Lines <list>
          - define Commit_Emoji <discordemoji[adriftusbot,custom,746943945929523252,icons8commitgit641,false].formatted>
          - foreach <[Map].get[commits]> as:Commit:
            - define ID <[Commit].get[id]>
            - define URL <[Commit].get[url]>
            - define Author <[Commit].get[author].get[username]>
            - define Message <[Commit].get[message].replace[`].with[']>
            - define Line "[<[Commit_Emoji]>`[<[ID].substring[1,8]>]`](<[URL]>)`[<[Author]>]` | <[Message]>"
            - define Body_Lines <[Body_Lines].include_single[<[Line]>]>

        #^- define Hook <script[DDTBCTY].data_key[WebHooks.650016499502940170.hook]>
        #^- define data
        #^- define headers <yaml[Saved_Headers].read[Discord.Webhook_Message]>
        #^- ~webget <[Hook]> data:<[Data]> headers:<[Headers]>

      - else if <[domain]> == <script.data_key[Domains.self]>:
        - bungee <bungee.list_servers.exclude[<bungee.server>]>:
          - reload
        - wait 1t
        - reload
      - else:
        - announce to_console "<&c>--- post request ----------------------------------------------------------"
        - announce to_console "Attempted request from <[Domain]>"

Web_Debug:
  type: task
  debug: false
  script:
    - debug record start
  Get_Response:
    - announce to_console "<&3>-- <queue.script.name> - Get_Response ---------"
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>address<&6><&gt> <&b>| <&3><context.address||<&4>Invalid> <&b>| <&a>Returns the IP address of the device that sent the request."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>request<&6><&gt> <&b>| <&3><context.request||<&4>Invalid> <&b>| <&a>Returns the path that was requested."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>query<&6><&gt> <&b>| <&3><context.query||<&4>Invalid> <&b>| <&a>Returns an ElementTag of the raw query included with the request."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>query_map<&6><&gt> <&b>| <&3><context.query_map||<&4>Invalid> <&b>| <&a>Returns a map of the query."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>user_info<&6><&gt> <&b>| <&3><context.user_info||<&4>Invalid> <&b>| <&a>Returns info about the authenticated user sending the request, if any."
    - announce to_console <&3>-----------------------------------------------
  Post_Request:
    - announce to_console "<&3>-- <queue.script.name> - Post_Request ---------"
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>address<&6><&gt> <&b>| <&3><context.address||<&c>Invalid> <&b>| <&a>Returns the IP address of the device that sent the request."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>request<&6><&gt> <&b>| <&3><context.request||<&c>Invalid> <&b>| <&a>Returns the path that was requested."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>query<&6><&gt> <&b>| <&3><context.query||<&c>Invalid> <&b>| <&a>Returns a ElementTag of the raw query included with the request."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>query_map<&6><&gt> <&b>| <&3><context.query_map||<&c>Invalid> <&b>| <&a>Returns a map of the query."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>user_info<&6><&gt> <&b>| <&3><context.user_info||<&c>Invalid> <&b>| <&a>Returns info about the authenticated user sending the request, if any."
    - announce to_console "<&6><&lt><&e>context<&6>.<&e>upload_name<&6><&gt> <&b>| <&3><context.upload_name||<&c>Invalid> <&b>| <&a>returns the name of the file posted."
  #^- announce to_console "<&6><&lt><&e>context<&6>.<&e>upload_size_mb<&6><&gt> <&b>| <&3><context.upload_size_mb||<&c>Invalid> <&b>| <&a>returns the size of the upload in MegaBytes (where 1 MegaByte = 1 000 000 Bytes)."
    - announce to_console <&3>-----------------------------------------------
  Webget_Response:
    - announce to_console "<&3>-- <queue.script.name> - WebGet_Response ------"
    - announce to_console "<&6><&lt><&e>entry<&6>[<&e>response<&6>].<&e>failed<&6><&gt> <&b>| <&3><entry[response].failed||<&c>Invalid> <&b>| <&a>returns whether the webget failed. A failure occurs when the status is no..."
    - announce to_console "<&6><&lt><&e>entry<&6>[<&e>response<&6>].<&e>result<&6><&gt> <&b>| <&3><entry[response].result||<&c>Invalid> <&b>| <&a>returns the result of the webget. This is null only if webget failed to connect to the url."
    - announce to_console "<&6><&lt><&e>entry<&6>[<&e>response<&6>].<&e>status<&6><&gt> <&b>| <proc[http_status_codes].context[<&3><entry[response].status||<&c>Invalid>]> <&b>| <&a>returns the HTTP status code of the webget. This is null only if webget failed to connect to the url."
    - announce to_console "<&6><&lt><&e>entry<&6>[<&e>response<&6>].<&e>time_ran<&6><&gt> <&b>| <&3><entry[response].time_ran||<&c>Invalid> <&b>| <&a>returns a DurationTag indicating how long the web connection processing took."
    - announce to_console "<&6><&lt><&e>entry<&6>[<&e>response<&6>].<&e>result_headers<&6><&gt> <&b>| <&3><entry[response].result_headers||<&c>Invalid> <&b>| <&a>returns a MapTag of the headers returned from the webserver. Every value in the result is a list."
    - announce to_console <&3>-----------------------------------------------
  Submit:
    - ~debug record submit save:mylog
    - announce to_console <entry[mylog].submitted||<&4>Debug_Failure>
