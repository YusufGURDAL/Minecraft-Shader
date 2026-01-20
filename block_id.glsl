vec4 voxel_data[15];
   	voxel_data[0] = 
    mc_Entity.x == 1.0 ? tech_white : //brewing_stand 1
    mc_Entity.x == 2.0 ? organic_amber : //brown_mushroom 1
    mc_Entity.x == 3.0 ? portal_purple : //dragon_egg 1
    mc_Entity.x == 4.0 ? end_portal_black : //end_portal_frame 1
    mc_Entity.x == 5.0 ? soul_blue : //sculk_sensor calibrated_sculk_sensor 1
    mc_Entity.x == 6.0 ? amethyst_pink : //small_amethyst_bud 1
    mc_Entity.x == 7.0 ? redstone_red : //redstone_wire:power=1,2,3... 1
    vec4(0.0);
    voxel_data[1] =
    mc_Entity.x == 8.0 ? amethyst_pink : //medium_amethyst_bud 2
    mc_Entity.x == 9.0 ? organic_amber : //firefly_bush 2
    vec4(0.0);
    voxel_data[2] =
    mc_Entity.x == 10.0 ? lava_orange : //magma_block 3
    mc_Entity.x == 11.0 ? torch_yellow ://candle:lit=true:candles=1 candle_cake:lit=true 3
    mc_Entity.x == 12.0 ? portal_purple ://respawn_anchor:charges=1 3
    vec4(0.0);
    voxel_data[3] =
    mc_Entity.x == 13.0 ? amethyst_pink ://large_amethyst_bud 4
    mc_Entity.x == 14.0 ? torch_yellow ://minecraft:oxidized_copper_bulb:lit:true minecraft:trial_spawner:trial_spawner_state=waiting_for_players 4
    vec4(0.0);
    voxel_data[4] =
    mc_Entity.x == 15.0 ? amethyst_pink ://minecraft:amethyst_cluster 5
    vec4(0.0);
    voxel_data[5] = 
    mc_Entity.x == 16.0 ? underwater_turquoise ://minecraft:sea_pickle:pickles=1:waterlogged=true 6
    mc_Entity.x == 17.0 ? soul_blue ://minecraft:sculk_catalyst 6
    mc_Entity.x == 18.0 ? torch_yellow ://minecraft:vault:vault_state=inactive  minecraft:candle:lit=true:candles=2 6
    vec4(0.0);
    voxel_data[6] = 
    mc_Entity.x == 19.0 ? magic_blue ://minecraft:enchanting_table 7
    mc_Entity.x == 20.0 ? portal_purple ://minecraft:ender_chest 7
    mc_Entity.x == 21.0 ? organic_amber ://minecraft:glow_lichen 7
    mc_Entity.x == 22.0 ? redstone_red ://minecraft:redstone 7
    mc_Entity.x == 23.0 ? portal_purple ://respawn_anchor:charges=2 7
    vec4(0.0);
    voxel_data[7] = 
    mc_Entity.x == 24.0 ? torch_yellow ://minecraft:trial_spawner:trial_spawner_state=active minecraft:weathered_copper_bulb:lit=true 8
    vec4(0.0);
    voxel_data[8] = 
    mc_Entity.x == 25.0 ? torch_yellow ://candle:lit=true:candles=3 9
    mc_Entity.x == 26.0 ? redstone_red ://minecraft:redstone_block minecraft:redstone_ore:lit=true minecraft:deepslate_redstone_ore:lit=true 9
    mc_Entity.x == 27.0 ? underwater_turquoise ://minecraft:sea_pickle:pickles=2:waterlogged=true 9
    vec4(0.0);
    voxel_data[9] = 
    mc_Entity.x == 28.0 ? portal_purple ://minecraft:crying_obsidian 10
    mc_Entity.x == 29.0 ? soul_blue ://minecraft:soul_torch minecraft:soul_wall_torch minecraft:soul_fire minecraft:soul_campfire:lit=true minecraft:soul_campfire:signal_fire=true 10
    vec4(0.0);
    voxel_data[10] = 
    mc_Entity.x == 30.0 ? portal_purple ://minecraft:respawn_anchor:charges=3 minecraft:nether_portal 11
    vec4(0.0);
    voxel_data[11] = 
    mc_Entity.x == 31.0 ? torch_yellow ://minecraft:vault:vault_state=active minecraft:exposed_copper_bulb:lit=true minecraft:candle:lit=true:candles=4 12
    mc_Entity.x == 32.0 ? underwater_turquoise://minecraft:sea_pickle:pickles=3:waterlogged=true 12
    vec4(0.0);
    voxel_data[12] = 
    mc_Entity.x == 33.0 ? torch_yellow ://minecraft:furnace:lit=true minecraft:blast_furnace:lit=true minecraft:smoker:lit=true 13
    vec4(0.0);
    voxel_data[13] = 
    mc_Entity.x == 34.0 ? torch_yellow ://minecraft:torch minecraft:wall_torch 14
    mc_Entity.x == 35.0 ? organic_amber :// minecraft:cave_vines:berries=true minecraft:cave_vines_plant:berries=true 14
    mc_Entity.x == 36.0 ? tech_white ://minecraft:end_rod 14
    mc_Entity.x == 37.0 ? copper_green ://minecraft:copper_torch minecraft:copper_wall_torch 14
    vec4(0.0);
    voxel_data[14] = 
    mc_Entity.x == 38.0 ? torch_yellow ://minecraft:fire minecraft:jack_o_lantern minecraft:lantern minecraft:campfire:lit=true minecraft:campfire:signal_fire=true minecraft:copper_bulb:lit=true 15
    mc_Entity.x == 39.0 ? copper_green ://minecraft:copper_lantern 15
    mc_Entity.x == 40.0 ? organic_amber ://minecraft:shroomlight 15
    mc_Entity.x == 41.0 ? underwater_turquoise ://minecraft:sea_lantern minecraft:conduit minecraft:sea_pickle:pickles=4:waterlogged=true 15
    mc_Entity.x == 42.0 ? portal_purple ://minecraft:respawn_anchor:charges=4 15
    mc_Entity.x == 43.0 ? glowstone_beige ://minecraft:redstone_lamp:lit=true minecraft:glowstone 15
    mc_Entity.x == 44.0 ? lava_orange ://minecraft:lava minecraft:lava_cauldron 15
    mc_Entity.x == 45.0 ? frog_pink ://minecraft:pearlescent_froglight 15
    mc_Entity.x == 46.0 ? frog_green ://minecraft:vevrdant_froglight 15
    mc_Entity.x == 47.0 ? frog_yellow ://minecraft:ochre_froglight 15
    mc_Entity.x == 48.0 ? end_portal_black ://minecraft:end_gateway minecraft:end_portal 15
    mc_Entity.x == 49.0 ? magic_blue ://minecraft:beacon 15
    vec4(0.0);