init()
{
    setdvarifuninitialized( "bot_custom_loadout", 1 );
    setdvarifuninitialized( "bot_full_auto", 1 );
    setdvarifuninitialized( "bot_jump_shoot", 1 );
    setdvarifuninitialized( "aggressive_bots", 1 );
    setdvarifuninitialized( "aggressive_interval", 0 );
    setdvarifuninitialized( "bot_caution", 0);
    
    level thread onplayerconnected_botlogic();
    level thread watch_bot_full_auto();
    level thread watch_for_endgame();
    level thread DidYouKnow();
}

onplayerconnected_botlogic()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "connected", player );
        player thread watch_regular_spawns();
        player thread watch_infil_jumps();
    }
}

watch_regular_spawns()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( isbot( self ) )
        {
            self thread apply_armor_delayed();
            self thread apply_loadout_delayed();
            self thread bot_regen_tracker(); 
            self thread bot_jump_shoot_tracker();
            self thread bot_aggro_tracker();
            self thread bot_caution_on_respawn();
        }
    }
}

watch_infil_jumps()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "infil_jump_done" );
        
        if ( isbot( self ) )
        {
            wait 0.5;
            self apply_full_armor();
            self thread apply_loadout_delayed();
            self thread bot_jump_shoot_tracker();
            self thread bot_aggro_tracker();
        }
    }
}

apply_loadout_delayed()
{
    self endon( "death" );
    self endon( "disconnect" );

    if ( getdvarint( "bot_custom_loadout" ) == 0 )
        return;

    wait 2.0;

    var_class = "class0";
    if ( isdefined( self.pers["class"] ) )
        var_class = self.pers["class"];

    self scripts\mp\class::giveloadout( self.team, var_class, 0, 1 );

    self.allowlaststand = 1;
    self.br_selftorevive = 1;
    self.hasselfrevive = 1;
    
    self notify( "loadout_given" );
}

apply_armor_delayed()
{
    self endon( "death" );
    self endon( "disconnect" );

    wait 1.5;
    self apply_full_armor();
    wait 3.5;
    self apply_full_armor();
}

apply_full_armor()
{
    if ( iswarzone() )
    {
        self.br_armorhealth = 150;
        self _encstr_B89622B91BE42DE0E8DC976B0779EC0BB695E8973856B9CBC427FA2CE4DADB93173B9B1B::scriptablescurid( self.br_armorhealth );
        
        if ( !isdefined( self.br_maxarmorhealth ) )
            self.br_maxarmorhealth = 150;

        var_0 = float( self.br_armorhealth ) / float( self.br_maxarmorhealth );
        var_1 = int( var_0 * 100 );
        
        self setclientomnvar( "ui_br_armor_percent", var_1 );
        self setclientomnvar( "ui_br_armor_health", int( self.br_armorhealth ) );
    }
}

DidYouKnow()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );
    
    for(;;)
    {
        iprintln( "^3| A GSC dedicated to making IW8 bots realistic! |" );
        iprintln( "^2Credit to Vanguard, AKAJay, and eeffoc for testing" );      
        iprintln( "^&IW10 ^7v1.6.2 || ^2Developed by cilism" );
        wait 120;
    }
}

bot_regen_tracker()
{
    self notify( "bot_regen_tracker_started" );
    self endon( "bot_regen_tracker_started" );
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );

    wait 1.0;

    var_last_health = self.health;
    var_last_armor = self.br_armorhealth;
    
    if ( !isdefined( var_last_armor ) )
        var_last_armor = 0;

    var_last_damage_time = gettime();

    for (;;)
    {
        wait 0.1;

        var_curr_health = self.health;
        var_curr_armor = self.br_armorhealth;
        
        if ( !isdefined( var_curr_armor ) )
            var_curr_armor = 0;

        if ( var_curr_health < var_last_health || var_curr_armor < var_last_armor )
        {
            var_last_damage_time = gettime();
        }

        var_last_health = var_curr_health;
        var_last_armor = var_curr_armor;

        if ( gettime() - var_last_damage_time >= 5000 )
        {
            if ( !isdefined( self.br_armorhealth ) || self.br_armorhealth < 150 )
            {
                self apply_full_armor();
                self playsound( "eqp_armor_plate_insert" );
                var_last_armor = 150;
                var_last_health = self.health;
            }
        }
    }
}

bot_jump_shoot_tracker()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "weapon_fired" );

        if ( getdvarint( "bot_jump_shoot", 0 ) == 1 )
        {
            if ( randomint( 100 ) < 10 )
            {
                self botpressbutton( "jump" );
                
                wait randomfloatrange( 0.5, 1.5 );
            }
        }
    }
}

watch_bot_full_auto()
{
    level endon( "game_ended" );

    for (;;)
    {
        if ( getdvarint( "bot_full_auto", 0 ) == 1 )
        {
            foreach ( var_1 in level.players )
            {
                if ( !isdefined( var_1 ) || !isbot( var_1 ) || !isalive( var_1 ) )
                    continue;

                if ( isdefined( var_1.enemy ) && var_1 botcanseeentity( var_1.enemy ) )
                {
                    var_1 botpressbutton( "attack" );
                }
            }
        }
        
        wait 0.05;
    }
}

bot_aggro_tracker()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );

    self.is_currently_tracking = 0;

    for (;;)
    {
        if ( isdefined( self.bot_is_cautious ) && self.bot_is_cautious )
        {
            wait 1.0;
            continue;
        }

        if ( getdvarint( "aggressive_bots", 1 ) == 1 )
        {
            var_0 = get_nearest_human_player();

            if ( isdefined( var_0 ) && isalive( var_0 ) )
            {
                var_1 = 1;

                if ( getdvarint( "aggressive_interval", 1 ) == 1 )
                {
                    var_2 = int( gettime() / 1000 ) % 25;
                    
                    if ( var_2 >= 15 )
                    {
                        var_1 = 0; 
                    }
                }

                if ( var_1 )
                {
                    if ( !self.is_currently_tracking )
                    {
                        self.is_currently_tracking = 1;
                        if ( getdvarint( "aggro_debug", 1 ) == 1 )
                        {
                            if ( !isdefined( level.last_track_print ) || gettime() - level.last_track_print > 5000 )
                            {
                                var_0 iprintln( "Bots have retracked your position" );
                                level.last_track_print = gettime();
                            }
                        }
                    }

                    self botsetflag( "force_sprint", 1 );
                    self botsetflag( "frozen", 0 );
                    self freezecontrols( 0 );
                    self.ignoreall = 0;
                    
                    self getenemyinfo( var_0 );
                    self botgetimperfectenemyinfo( var_0, var_0.origin );
                    self botsetscriptgoal( var_0.origin, 64, "critical" );
                    self botsetattacker( var_0 );
                    

                }
                else
                {
                    if ( self.is_currently_tracking )
                    {
                        self.is_currently_tracking = 0;
                        if ( getdvarint( "aggro_debug", 1 ) == 1 )
                        {
                            if ( !isdefined( level.last_lost_print ) || gettime() - level.last_lost_print > 5000 )
                            {
                                var_0 iprintln( "Bots lost track of your position" );
                                level.last_lost_print = gettime();
                            }
                        }
                    }

                    self bot_aggro_turn_off();
                }
            }
        }
        else
        {
            self.is_currently_tracking = 0;
            self bot_aggro_turn_off();
        }

        wait 1.0;
    }
}

bot_aggro_turn_off()
{
    self botsetflag( "force_sprint", 0 );
    self botclearscriptgoal();
    self botclearscriptenemy();
    
    if ( isdefined( self.enemy ) )
        self.enemy = undefined;
        
    self.attacker = undefined;
    
}

get_nearest_human_player()
{
    var_0 = undefined;
    var_1 = 999999;

    foreach ( var_3 in level.players )
    {
        if ( !isdefined( var_3 ) || isbot( var_3 ) )
            continue;

        if ( !isalive( var_3 ) )
            continue;

        if ( !isdefined( var_0 ) )
        {
            var_0 = var_3;
            continue;
        }

        var_4 = distance( self.origin, var_3.origin );

        if ( var_4 < var_1 )
        {
            var_0 = var_3;
            var_1 = var_4;
        }
    }

    return var_0;
}

bot_caution_on_respawn()
{
    self endon( "death" );
    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( getdvarint( "bot_caution", 1 ) == 0 )
        return;

    if ( isdefined( level.endgame_has_started ) && level.endgame_has_started )
        return;

    self notify( "caution_behavior_start" );
    self endon( "caution_behavior_start" );

    self.bot_is_cautious = 1;
    self.ignoreall = 1; 
    self botsetflag( "force_sprint", 1 );

    var_end_time = gettime() + 40000; 

    while ( gettime() < var_end_time )
    {
        if ( isdefined( level.endgame_has_started ) && level.endgame_has_started )
            break;

        var_threat = self get_nearest_entity_to_avoid();

        if ( isdefined( var_threat ) )
        {
            var_distance = distance( self.origin, var_threat.origin );

            if ( var_distance < 3000 ) 
            {
                var_dir_away = vectornormalize( self.origin - var_threat.origin );
                var_run_target = self.origin + ( var_dir_away * 1500 ); 
                var_safe_point = botgetclosestnavigablepoint( var_run_target, 500 );
                
                if ( isdefined( var_safe_point ) )
                    self botsetscriptgoal( var_safe_point, 128, "critical" );
            }
        }
        wait 1.0; 
    }

    self.bot_is_cautious = 0;
    self.ignoreall = 0;
    self botsetflag( "force_sprint", 0 );
    self botclearscriptgoal();
}

get_nearest_entity_to_avoid()
{
    var_nearest = undefined;
    var_min_dist = 999999;

    foreach ( var_player in level.players )
    {
        if ( var_player == self ) 
            continue;
            
        if ( !isalive( var_player ) ) 
            continue;

        var_dist = distance( self.origin, var_player.origin );

        if ( var_dist < var_min_dist )
        {
            var_min_dist = var_dist;
            var_nearest = var_player;
        }
    }

    return var_nearest;
}

watch_for_endgame()
{
    level endon( "game_ended" );
    
    level waittill( "respawn_disabled" );
    
    level.endgame_has_started = 1; 
}

iswarzone()
{
    return level.gametype == "br" || level.gametype == "dmz" || level.gametype == "rebirth" || level.gametype == "rebirth_reverse";
}