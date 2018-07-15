# TF2 Hot Hand Admin Slap for SourceMod
Slap Ability for Admins that is in the TF2 Theme of a Hot Hand, that can slap repeatively if desired to.

This plugin allows admins to slap users, but with the ability to have them be continously slapped for a specific amount of time.
Also plays the Hot Hand Slap sounds, for that extra TF2 feel!

I am still fairly new to writing SourceMod plugins so forgive if I am making basic mistakes.

# ConVars
### sm_hothand_slap_enable (Bool - 0/1) (Default: 1) 
- Enables/Disables the Plugins functions, although if you don't want this, should just unload it.

### sm_hothand_slap_mode (Int - 1/2) (Default: 2) 
- Determins the slap behaviour, 1 allows for single slaps only, while 2 enables repeative slaps.

### sm_hothand_slap_time (Float - 0.1) (Default: 0.2)
- Determins how many seconds should pass between each slap by default. Min is 0.1 seconds due to SM timer limit.

### sm_hothand_slap_damage (Float - 0.0) (Default: 10.0)
- Determins how much damage is dealt to the victim(s) per slap. Default is set to 10, min is 0.

### sm_hothand_min_force (Float - 0.0) (Default: 25.0)
- Determins the min amount of force to be applied to a player on each slap. Default is 25.0, min is 0.
- Applied force is skipped if min & max values match.

### sm_hothand_min_force (Float - 0.0) (Default: 500.0)
- Determins the min amount of force to be applied to a player on each slap. Default is 500.0, min is 0. 
- Applied force is skipped if min & max values match.

### sm_hothand_sound_volume (Float - 0.0 > 1.0) (Default: 0.25)
- Determins the volume of which to play the slap sounds at to the client. Default is 0.25 for 25%, min is 0 for 0%.
- Due to how loud the slap sounds are, it is ideal to adjust the volume of this without having to change the plugin.

### sm_hothand_slapme_enable (Bool - 0/1) (Default: 1)
- Enables/Disables the Ability for players to slap themselves. Because Science isn't about why?! It's about why not?!

### sm_hothand_slap_team (Int - 0/3) (Default: 0)
- Restricts the slapme command to a specific team, 0 for off, 2 for RED and 3 for BLUE.

### sm_hothand_slap_limit (Int - 0/100) (Default: 100)
- Limits the amount of times a player can self slap for. Set to 100 by Default.
- 0 for No Limit but if there's going to be a limit, no point in cheesing it.

# Commands
### sm_hotslap (target, damage, count, delay)
- Slaps a target, applies Damage, Repeat Counts & Delay between Slaps based on values inputted.
- Will use default Cvar Values if no values are given. However, if the time value is above 120, it will error on purpose.

### sm_hotslapme (damage, count, delay)
- Slaps yourself upon use, applies Damage, Repeat Counts & Delay Between slaps based on values inputted.
- Will use default Cvar Values if no values are given. However, if the time value is above 120, it will error on purpose.
- Can also be restricted to a specific team only and has a default count limit of 100. Which is Cvar Controlled.
