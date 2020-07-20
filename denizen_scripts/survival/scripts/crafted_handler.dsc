send_to_crafted:
  type: command
  debug: false
  name: crafted_send
  permission: not.a.perm
  script:
    - adjust <queue> linked_player:<server.match_player[<context.args.get[1]>]>
    - if <yaml[crafted].read[whitelist].contains_any[<player.uuid>|<player.name>]>:
      - adjust <player> send_to:crafted
    - else:
      - narrate "<&c>You are not allowed to access this server."

crafted_hub_events:
  type: world
  debug: false
  events:
    on server start:
      - if <server.has_file[data/crafted.yml]>:
        - yaml id:crafted load:data/crafted.yml
      - waituntil <server.flag[crafted_npc].as_npc.is_spawned>
      - adjust <server.flag[crafted_npc]> hide_from_players
    on player join:
      - wait 2s
      - if <yaml[crafted].read[whitelist].contains_any[<player.uuid>|<player.name>]>:
        - adjust <player> show_entity:<server.flag[crafted_npc]>
    on script reload:
      - if <yaml.list.contains[crafted]>:
        - yaml unload id:crafted
      - if <server.has_file[data/crafted.yml]>:
        - yaml id:crafted load:data/crafted.yml