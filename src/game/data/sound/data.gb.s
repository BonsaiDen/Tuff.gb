; Songs -----------------------------------------------------------------------
SoundSongs:

; Sound Effects ---------------------------------------------------------------
SoundEffects:
SOUND_EFFECT_PLAYER_JUMP:
  DB 15
  DB 0
  DB $FF

SOUND_EFFECT_PLAYER_JUMP_DOUBLE:
  DB 15
  DB 1
  DB $FF

SOUND_EFFECT_PLAYER_LAND:
  DB 15
  DB 2
  DB $FF

SOUND_EFFECT_PLAYER_LAND_SOFT:
  DB 15
  DB 3
  DB $FF

SOUND_EFFECT_PLAYER_LAND_HARD:
  DB 15
  DB 4
  DB $FF

SOUND_EFFECT_PLAYER_WATER_ENTER:
  DB 15
  DB 5
  DB $FF

SOUND_EFFECT_PLAYER_WATER_LEAVE:
  DB 15
  DB 6
  DB $FF

SOUND_EFFECT_BG_WATERFALL:
  DB 143
  DB 7
  DB $FF

SOUND_EFFECT_PLAYER_DEATH_LAVA:
  DB 15
  DB 8
  DB $FF

SOUND_EFFECT_PLAYER_DEATH_ELECTRIC:
  DB 15
  DB 9
  DB $FF

SOUND_EFFECT_GAME_SAVE_FLASH:
  DB 15
  DB 10
  DB $FF

SOUND_EFFECT_GAME_SAVE_RESTORE_FLASH:
  DB 15
  DB 11
  DB $FF

SOUND_EFFECT_PLAYER_WALL_JUMP:
  DB 15
  DB 12
  DB $FF

SOUND_EFFECT_PLAYER_LAND_POUND:
  DB 15
  DB 13
  DB $FF

SOUND_EFFECT_PLAYER_POUND_UP_HIGH:
  DB 15
  DB 14
  DB $FF

SOUND_EFFECT_PLAYER_POUND_UP_MED:
  DB 15
  DB 15
  DB $FF

SOUND_EFFECT_PLAYER_POUND_UP_LOW:
  DB 15
  DB 16
  DB $FF

SOUND_EFFECT_GAME_LOGO:
  DB 15
  DB 17
  DB $FF

SOUND_EFFECT_GAME_MENU_SELECT:
  DB 15
  DB 18
  DB $FF

SOUND_EFFECT_PLAYER_POUND_BREAK:
  DB 15
  DB 19
  DB $FF

SOUND_EFFECT_PLAYER_POUND_CANCEL:
  DB 15
  DB 20
  DB $FF

SOUND_EFFECT_PLAYER_BOUNCE_WALL:
  DB 15
  DB 21
  DB $FF

SOUND_EFFECT_MAP_FALLING_BLOCK:
  DB 15
  DB 22
  DB $FF

SOUND_EFFECT_GAME_MENU:
  DB 15
  DB 23
  DB $FF

SOUND_EFFECT_SINE_WAVE:
  DB 15
  DB 24
  DB $FF


; Instruments -----------------------------------------------------------------
SoundInstrumentTable:
sound_instrument_player_jump_0:
  DB 64,54,140,179

sound_instrument_player_jump_double_1:
  DB 64,102,140,179

sound_instrument_player_land_2:
  DB 67,0,65,106

sound_instrument_player_land_soft_3:
  DB 67,0,49,106

sound_instrument_player_land_hard_4:
  DB 67,0,97,121

sound_instrument_player_water_enter_5:
  DB 67,0,66,52

sound_instrument_player_water_leave_6:
  DB 67,0,66,51

sound_instrument_bg_waterfall_7:
  DB 67,0,108,36

sound_instrument_player_death_lava_8:
  DB 67,0,181,139

sound_instrument_player_death_electric_9:
  DB 64,60,129,243

sound_instrument_game_save_flash_10:
  DB 64,117,0,247

sound_instrument_game_save_restore_flash_11:
  DB 64,53,194,242

sound_instrument_player_wall_jump_12:
  DB 64,54,128,179

sound_instrument_player_land_pound_13:
  DB 3,0,151,114

sound_instrument_player_pound_up_high_14:
  DB 64,52,135,244

sound_instrument_game_logo_15:
  DB 0,117,192,196

sound_instrument_game_menu_select_16:
  DB 64,51,128,193

sound_instrument_player_pound_break_17:
  DB 67,42,210,98

sound_instrument_player_pound_cancel_18:
  DB 64,107,128,243

sound_instrument_player_bounce_wall_19:
  DB 64,114,128,248

sound_instrument_map_falling_block_20:
  DB 64,37,144,241

sound_instrument_game_menu_21:
  DB 64,67,128,199


; Patterns --------------------------------------------------------------------
SoundPatternTable:
  DW sound_pattern_player_jump_0
  DW sound_pattern_player_jump_double_1
  DW sound_pattern_player_land_2
  DW sound_pattern_player_land_soft_3
  DW sound_pattern_player_land_hard_4
  DW sound_pattern_player_water_enter_5
  DW sound_pattern_player_water_leave_6
  DW sound_pattern_bg_waterfall_7
  DW sound_pattern_player_death_lava_8
  DW sound_pattern_player_death_electric_9
  DW sound_pattern_game_save_flash_10
  DW sound_pattern_game_save_restore_flash_11
  DW sound_pattern_player_wall_jump_12
  DW sound_pattern_player_land_pound_13
  DW sound_pattern_player_pound_up_high_14
  DW sound_pattern_player_pound_up_med_15
  DW sound_pattern_player_pound_up_low_16
  DW sound_pattern_game_logo_17
  DW sound_pattern_game_menu_select_18
  DW sound_pattern_player_pound_break_19
  DW sound_pattern_player_pound_cancel_20
  DW sound_pattern_player_bounce_wall_21
  DW sound_pattern_map_falling_block_22
  DW sound_pattern_game_menu_23

sound_pattern_player_jump_0:
  DB 24, 0
  DB $FF

sound_pattern_player_jump_double_1:
  DB 30, 1
  DB $FF

sound_pattern_player_land_2:
  DB 0, 2
  DB $FF

sound_pattern_player_land_soft_3:
  DB 0, 3
  DB $FF

sound_pattern_player_land_hard_4:
  DB 0, 4
  DB $FF

sound_pattern_player_water_enter_5:
  DB 0, 5
  DB $FF

sound_pattern_player_water_leave_6:
  DB 0, 6
  DB $FF

sound_pattern_bg_waterfall_7:
  DB 0, 7
  DB $FF

sound_pattern_player_death_lava_8:
  DB 0, 8
  DB $FF

sound_pattern_player_death_electric_9:
  DB 42, 9
  DB $FF

sound_pattern_game_save_flash_10:
  DB 27, 10
  DB $FF

sound_pattern_game_save_restore_flash_11:
  DB 13, 11
  DB $FF

sound_pattern_player_wall_jump_12:
  DB 25, 12
  DB $FF

sound_pattern_player_land_pound_13:
  DB 0, 13
  DB $FF

sound_pattern_player_pound_up_high_14:
  DB 10, 14
  DB $FF

sound_pattern_player_pound_up_med_15:
  DB 8, 14
  DB $FF

sound_pattern_player_pound_up_low_16:
  DB 5, 14
  DB $FF

sound_pattern_game_logo_17:
  DB 36, 15
  DB $FF

sound_pattern_game_menu_select_18:
  DB 17, 16
  DB $FF

sound_pattern_player_pound_break_19:
  DB 0, 17
  DB $FF

sound_pattern_player_pound_cancel_20:
  DB 24, 18
  DB $FF

sound_pattern_player_bounce_wall_21:
  DB 6, 19
  DB $FF

sound_pattern_map_falling_block_22:
  DB 10, 20
  DB $FF

sound_pattern_game_menu_23:
  DB 7, 21
  DB $FF


; Samples ---------------------------------------------------------------------
SoundSampleTable:

