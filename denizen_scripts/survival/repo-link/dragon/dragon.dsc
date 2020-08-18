dragon_prespawn_handler:
    type: world
    events:
        on player right clicks block with:randomtestitemscript in:dragon_area:
        - narrate "<&a>COW TIME!"
        - repeat 50:
            - spawn cow <cuboid[dragon_area].spawnable_blocks.random>
        - flag server killingPhase:0b
        on cow death by:player in:dragon_area:
        - if <server.has_flag[killingPhase]>:
            - flag server killingPhase:++
            - if <server.flag[killledPhase]> == 50:
                - flag server kilingPhase:!
                - narrate "Dragon stuff"
                - flag server purple_crystal:->:<empty>
                - flag server red_crystal
        on entity death in:dragon_area:
        - if <context.entity.entity_type> != ender_dragon:
            - determine <context.drops.parse[with[nbt=dragon_loot/true]]>
        on delta time secondly every:12:
        - if <server.has_flag[purple_crystal]>:
            - repeat 15:
                - spawn ENDERMAN1 <cuboid[dragon_area].spawnable_blocks.random>
        on ENDERMAN1 dies in:dragon_area:
        - flag server purple_crystal:->:<context.entity.location>
        - showfake brown_mushroom_block[faces=east|south|west|up] <context.entity.location.find.blocks.within[2].filter[material.is[!=].to[air]]> players:<world[End_dimension].players> d:30s
        - wait 30s
        - flag server purple_crystal:<-:<context.entity.location>
        on delta time secondly:
        - if <server.has_flag[purple_crystal]>:
            - playeffect effect:SPELL_WITCH at:<server.flag[purple_crystal]> quantity:10
        - if <server.has_flag[green_crystal]>:
            - playeffect effect:falling_dust special_data:<script[dragon_crystal_data].data_key[green.particle_cloud_mat]> at:<script[dragon_crystal_data].parsed_key[green.particle_cuboid].blocks> quantity:500
        on player enters dragon_area:
        - flag player arrow:<map>
        - flag player green_crystal_gas:0
        on player exits dragon_area:
        - flag player arrow:!
        - flag player green_crystal_gas:!
        on player shoots bow in:dragon_area:
        - flag player arrow:<player.flag[arrow].as_map.with[<context.entity>].as[<player.location>]>
        on entity damaged by projectile in:dragon_area:
        - if <context.damager.is_player> && <context.projectile.entity_type> == ARROW:
            - flag <context.damager> arrow:<player.flag[arrow].as_map.exclude[<context.projectile>]>
        on projectile hits block:
        - if <context.shooter.is_player> && <context.projectile.entity_type> == ARROW:
            - flag <context.damager> arrow:<player.flag[arrow].as_map.exclude[<context.projectile>]>
        on custom_crystal_purple damaged by player priority:-5:
        - define loc <context.damager.flag[arrow].as_map.get[<context.projectile>]||null>
        - if <context.projectile.entity_type||null> != ARROW || <context.projectile.potion.potion_base.contains[INSTANT_DAMAGE].not||false> || <server.has_flag[purple_crystal].not>:
            - determine 0
        - foreach <server.flag[purple_crystal]>:
            - if <[loc].distance[<[value]>]> <= 2:
                - stop
        - determine 0
        on custom_crystal_red damaged by player priority:-5:
        - if <context.projectile.potion.potion_base.contains[INSTANT_DAMAGE].not||false> || <context.projectile.entity_type||null> != SPLASH_POTION || <server.has_flag[red_crystal].not>:
            - determine 0
        on custom_crystal_green damaged by player priority:-5:
        - if <list[ENTITY_ATTACK|ENTITY_SWEEP_ATTACK].contains[<context.cause>].not>:
            - determine 0
        on player enters green_crystal_gas:
        - while <cuboid[green_crystal_gas].contains_location[<player.location>]> && <player.flag[green_crystal_gas]> < 100:
            - flag player green_crystal_gas:++
            - actionbar <&a><player.flag[green_crystal_gas]><&pc>
            - wait 4t
        - if <player.flag[green_crystal_gas]> == 100:
            - while <player.flag[green_crystal_gas]> == 100 && <player.has_flag[temptations_defeat].not>:
                # insert stuff here for full gas meter
                - hurt 2
                - wait 1s
        on player exits green_crystal_area:
        - while <cuboid[green_crystal_has].contains_location[<player.location>].not> && <player.flag[green_crystal_gas]> >= 0:
            - flag player green_crystal_gas:--
            - actionbar <&a><player.flag[green_crystal_gas]><&pc>
            - wait 4t
        on custom_crystal_yellow damaged by player priority:-5:
        - if <context.projectile.entity_type||null> != SPECTRAL_ARROW || <server.has_flag[yellow_crystal].not>:
            - determine 0

        on player damaged by dragon_purple_fire:
        - hurt <player.health.mul[0.75]>
        # mark stare into the void debuff
        - flag player stare_into_the_void

        on player damaged by dragon_green_fire:
        # - flag player temptations_benefit

        
        on player damaged by dragon_golden_fire:
        - flag player spectral_teleport_loc:<player.location>
        - teleport <location[dragon_spectral_plane]>
        - narrate "<&a>In order to return to the battle, you must kill 10 mobs"
        - flag player spectral_mobs:0
        
        on entity death in:spectral_plane:
        - flag player spectral_mobs:++
        - if <player.flag[spectral_mobs]> == 10:
            - teleport <player.flag[spectral_teleport_loc].as_location>
            - narrate "<&a>You have returned to the fight!"
            - flag player spectral_mobs:!
            - flag player spectral_teleport_loc:!
        
        on player damaged by dragon_red_fire:
        - while <server.has_flag[red_crystal]>:
            - burn <player> duration:2s
            - wait 1s
        
dragon_crystal_data:
    type: data
    green:
        particle_cloud_mat: pink_stained_glass
        location: <location[green_crystal]>
        particle_cuboid: <cuboid[green_crystal_gas]>
        # <location[green_crystal].add[-1,-1,-1].to_cuboid[<location[green_crystal].add[1,1,1]>]>
    purple:
        location: <location[purple_crystal]>
    red:
        location: <location[red_crystal]>
    yellow:
        location: <location[yellow_crystal]>
    


dragon_purple_fire:
    type: entity
    entity_type: ender_dragon

dragon_red_fire:
    type: entity
    entity_type: ender_dragon

dragon_golden_fire:
    type: entity
    entity_type: ender_dragon

dragon_green_fire:
    type: entity
    entity_type: ender_dragon

custom_crystal_purple:
    type: entity
    entity_type: ender_crystal

custom_crystal_green:
    type: entity
    entity_type: ender_crystal

custom_crystal_red:
    type: entity
    entity_type: ender_crystal

randomtestitemscript:
    type: item
    material: gold_ingot
    display name: <&a>Test
