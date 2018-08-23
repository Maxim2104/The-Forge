name = "The Forge - Mobs update"
version = "Future 3"
description = "Version: "..version
author = [[Be66ep, Adai & Babasta]]

forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = true 

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"The Forge","Forge", "the forge", "forge", "the forge", "the_forge", "The_forge", "The_Forge", "Be66ep", "ksaab", "babasta", "ADM", "CliffW", "GitSM", "Adai", "Work in Progress"}

game_modes =
{
	{
		name = "lavaarena",
		label = "The Forge",
		description = "",
		settings = {
			internal = true,
			level_type = "LAVAARENA",
        spawn_mode = "fixed",
        resource_renewal = false,
        ghost_sanity_drain = false,
        ghost_enabled = false,
        revivable_corpse = true, 
        spectator_corpse = true,
        portal_rez = false,
        reset_time = nil,
        invalid_recipes = nil,
        --
        override_item_slots = 0,
        drop_everything_on_despawn = true,
        no_air_attack = true,
        no_crafting = true,
        no_minimap = true,
        no_hunger = true,
        no_sanity = true,
        no_avatar_popup = true,
        no_morgue_record = true,
        override_normal_mix = "lavaarena_normal",
        override_lobby_music = "dontstarve/music/lava_arena/FE2",
        cloudcolour = { .4, .05, 0 },
        cameraoverridefn = function(camera)
            camera.mindist = 20
            camera.mindistpitch = 32
            camera.maxdist = 55
            camera.maxdistpitch = 60
            camera.distancetarget = 32
        end,
        lobbywaitforallplayers = true,
        hide_worldgen_loading_screen = true,
		skin_tag = "LAVA",
        hide_received_gifts = true,
		}
	}
}


local optionStrings = {}
optionStrings.boarrior_damage_mod = {}
optionStrings.boarrior_health = {}
optionStrings.boarrior_bonus_health = {}

configuration_options = {
	{
		name  = "PVP_MOD",
		label = "PvP mod",
		options = {
			{description = "Off", data = 0},
			{hover="Battles will be ... fast", description = "On", data = 0}
		},
		default = 0
	},
    {
        name = "boarrior_damage_mod",
        label = optionStrings.boarrior_damage_mod.label,
        options = 
        {
            {description = "25%", data = 0.25, hover = optionStrings.boarrior_damage_mod.h},
            {description = "50%", data = 0.5, hover = optionStrings.boarrior_damage_mod.h},
            {description = "75%", data = 0.75, hover = optionStrings.boarrior_damage_mod.h},
            {description = "100%", data = 1, hover = optionStrings.boarrior_damage_mod.h},
            {description = "125%", data = 1.25, hover = optionStrings.boarrior_damage_mod.h},
        },
        default = 1
    },
    {
        name = "boarrior_health",
        label = optionStrings.boarrior_health.label,
        options = 
        {
            {description = "5000", data = 5000, hover = optionStrings.boarrior_health.h},
            {description = "7500", data = 7500, hover = optionStrings.boarrior_health.h},
            {description = "10000", data = 10000, hover = optionStrings.boarrior_health.h},
            {description = "12500", data = 12500, hover = optionStrings.boarrior_health.h},
            {description = "15000", data = 15000, hover = optionStrings.boarrior_health.h},
            {description = "20000", data = 20000, hover = optionStrings.boarrior_health.h},
        },
        default = 15000
    },
    {
        name = "boarrior_bonus_health",
        label = optionStrings.boarrior_bonus_health.label,
        options = 
        {
            {description = "0", data = 0, hover = optionStrings.boarrior_bonus_health.h1},
            {description = "500", data = 500, hover = optionStrings.boarrior_bonus_health.h2},
            {description = "1000", data = 1000, hover = optionStrings.boarrior_bonus_health.h3},
            {description = "1500", data = 1500, hover = optionStrings.boarrior_bonus_health.h4},
            {description = "2000", data = 2000, hover = optionStrings.boarrior_bonus_health.h5},
        },
        default = 1000
    },
	-- Infernal Staff
	{
		name = "----- Infernal Staff -----",
		options = {
			{description = "---------", data = 0}
		},
		default = 0
	},
	{
		name = "INFERNALSTAFF_DURABILITY",
		label = "Durability",
		options = {
			{description = "Infinite", data = -1},
			{description = "500", data = 500},
			{description = "1000", data = 1000},
			{description = "1500", data = 1500},
			{description = "2000", data = 2000},
			{description = "2500", data = 2500},
			{description = "3000", data = 3000},
			{description = "3500", data = 3500},
			{description = "4000", data = 4000},
			{description = "4500", data = 4500},
			{description = "5000", data = 5000}
		},
		default = -1
	},
	{
		name = "INFERNALSTAFF_USES_NORMAL",
		label = "Normal attack consumption",
		hover = "The amount of lossed durability for normal attacks, require no Infinite durability",
		options = {
			{description = "5/use", data = 5},
			{description = "10/use", data = 10},
			{description = "20/use", data = 20},
			{description = "50/use", data = 50},
			{description = "100/use", data = 100},
			{description = "150/use", data = 150},
			{description = "200/use", data = 200},
			{description = "250/use", data = 250},
			{description = "300/use", data = 300}
		},
		default = 10
	},
	{
		name = "INFERNALSTAFF_USES_SECIAL",
		label = "Special attack consumption",
		hover = "The percentage of lossed durability for special attacks, require no Infinite durability",
		options = {
			{description = "5%/use", data = 5},
			{description = "10%/use", data = 10},
			{description = "15%/use", data = 15},
			{description = "20%/use", data = 20},
			{description = "25%/use", data = 25},
			{description = "30%/use", data = 30},
			{description = "35%/use", data = 35},
			{description = "40%/use", data = 40},
			{description = "45%/use", data = 45},
			{description = "50%/use", data = 50},
			{description = "55%/use", data = 55},
			{description = "60%/use", data = 60},
			{description = "65%/use", data = 65},
			{description = "70%/use", data = 70},
			{description = "75%/use", data = 75},
			{description = "80%/use", data = 80},
			{description = "85%/use", data = 85},
			{description = "90%/use", data = 90},
			{description = "95%/use", data = 95},
			{description = "100%/use", data = 100}
		},
		default = 5
	},
	{
		name = "INFERNALSTAFF_DAMAGES_NORMAL",
		label = "Normal attack damages",
		options = {
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
			{description = "35", data = 35},
			{description = "40", data = 40},
			{description = "45", data = 45},
			{description = "50", data = 50},
			{description = "55", data = 55},
			{description = "60", data = 60},
			{description = "65", data = 65},
			{description = "70", data = 70},
			{description = "75", data = 75},
			{description = "80", data = 80},
			{description = "85", data = 85},
			{description = "90", data = 90},
			{description = "95", data = 95},
			{description = "100", data = 100}
		},
		default = 25
	},
	{
		name = "INFERNALSTAFF_DAMAGES_SPECIAL",
		label = "Special attack range damages",
		options = {
			{description = "50 - 100", data = 0.5},
			{description = "100 - 200", data = 1},
			{description = "150 - 250", data = 1.5},
			{description = "200 - 300", data = 2},
			{description = "250 - 350", data = 2.5},
			{description = "300 - 400", data = 3},
			{description = "350 - 450", data = 3.5},
			{description = "400 - 500", data = 4}
		},
		default = 2
	},
	{
		name = "INFERNALSTAFF_RECHARGETIME",
		label = "Recharge time",
		options = {
			{description = "10s", data = 10},
			{description = "20s", data = 20},
			{description = "30s", data = 30},
			{description = "40s", data = 40},
			{description = "50s", data = 50},
			{description = "1min", data = 60},
			{description = "2min", data = 120},
			{description = "5min", data = 300}
		},
		default = 30
	},
	-- Healing Staff
	{
		name = "----- Healing Staff -----",
		options = {
			{description = "---------", data = 0}
		},
		default = 0
	},
	{
		name = "HEALINGSTAFF_DURABILITY",
		label = "Durability",
		options = {
			{description = "Infinite", data = -1},
			{description = "500 Uses", data = 500},
			{description = "1000 Uses", data = 1000},
			{description = "1500 Uses", data = 1500},
			{description = "2000 Uses", data = 2000},
			{description = "2500 Uses", data = 2500},
			{description = "3000 Uses", data = 3000},
			{description = "3500 Uses", data = 3500},
			{description = "4000 Uses", data = 4000},
			{description = "4500 Uses", data = 4500},
			{description = "5000 Uses", data = 5000}
		},
		default = -1
	},
	{
		name = "HEALINGSTAFF_USES_NORMAL",
		label = "Normal attack consumption",
		hover = "The amount of lossed durability for normal attacks, require no Infinite durability",
		options = {
			{description = "5/use", data = 5},
			{description = "10/use", data = 10},
			{description = "20/use", data = 20},
			{description = "50/use", data = 50},
			{description = "100/use", data = 100},
			{description = "150/use", data = 150},
			{description = "200/use", data = 200},
			{description = "250/use", data = 250},
			{description = "300/use", data = 300}
		},
		default = 10
	},
	{
		name = "HEALINGSTAFF_USES_SPECIAL",
		label = "Special attack consumption",
		hover = "The percentage of lossed durability for special attacks, require no Infinite durability",
		options = {
			{description = "5%/use", data = 5},
			{description = "10%/use", data = 10},
			{description = "15%/use", data = 15},
			{description = "20%/use", data = 20},
			{description = "25%/use", data = 25},
			{description = "30%/use", data = 30},
			{description = "35%/use", data = 35},
			{description = "40%/use", data = 40},
			{description = "45%/use", data = 45},
			{description = "50%/use", data = 50},
			{description = "55%/use", data = 55},
			{description = "60%/use", data = 60},
			{description = "65%/use", data = 65},
			{description = "70%/use", data = 70},
			{description = "75%/use", data = 75},
			{description = "80%/use", data = 80},
			{description = "85%/use", data = 85},
			{description = "90%/use", data = 90},
			{description = "95%/use", data = 95},
			{description = "100%/use", data = 100}
		},
		default = 5
	},
	{
		name = "HEALINGSTAFF_DAMAGES",
		label = "Attack damages",
		options = {
			{description = "10", data = 10},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
			{description = "35", data = 35},
			{description = "40", data = 40},
			{description = "45", data = 45},
			{description = "50", data = 50},
			{description = "55", data = 55},
			{description = "60", data = 60},
			{description = "65", data = 65},
			{description = "70", data = 70},
			{description = "75", data = 75},
			{description = "80", data = 80},
			{description = "85", data = 85},
			{description = "90", data = 90},
			{description = "95", data = 95},
			{description = "100", data = 100}
		},
		default = 10
	},
	{
		name = "HEALINGSTAFF_SPELLDURATION",
		label = "Spell duration",
		options = {
			{description = "5s", data = 5},
			{description = "10s", data = 10},
			{description = "15s", data = 15},
			{description = "20s", data = 20},
			{description = "25s", data = 25},
			{description = "30s", data = 30}
		},
		default = 10
	},
	{
		name = "HEALINGSTAFF_SLEEPTIME",
		label = "Sleeping duration",
		options = {
			{description = "5s", data = 5},
			{description = "10s", data = 10},
			{description = "15s", data = 15},
			{description = "20s", data = 20},
			{description = "25s", data = 25},
			{description = "30s", data = 30}
		},
		default = 10
	},
	{
		name = "HEALINGSTAFF_REGENVALUE",
		label = "Regeneration rate",
		options = {
			{description = "1HP/s", data = 1},
			{description = "2HP/s", data = 2},
			{description = "3HP/s", data = 3},
			{description = "4HP/s", data = 4},
			{description = "5HP/s", data = 5},
			{description = "6HP/s", data = 6},
			{description = "7HP/s", data = 7},
			{description = "8HP/s", data = 8},
			{description = "9HP/s", data = 9},
			{description = "10HP/s", data = 10}
		},
		default = 5
	},
	{
		name = "HEALINGSTAFF_RECHARGETIME",
		label = "Recharge time",
		options = {
			{description = "10s", data = 10},
			{description = "20s", data = 20},
			{description = "30s", data = 30},
			{description = "40s", data = 40},
			{description = "50s", data = 50},
			{description = "1min", data = 60},
			{description = "2min", data = 120},
			{description = "5min", data = 300}
		},
		default = 30
	},
	-- Tome of Beckoning
	{
		name = "----- Tome of Beckoning -----",
		options = {
			{description = "---------", data = 0}
		},
		default = 0
	},
	{
		name = "BOOK_ELEMENTAL_DURABILITY",
		label = "Durability",
		options = {
			{description = "Infinite", data = -1},
			{description = "500 Uses", data = 500},
			{description = "1000 Uses", data = 1000},
			{description = "1500 Uses", data = 1500},
			{description = "2000 Uses", data = 2000},
			{description = "2500 Uses", data = 2500},
			{description = "3000 Uses", data = 3000},
			{description = "3500 Uses", data = 3500},
			{description = "4000 Uses", data = 4000},
			{description = "4500 Uses", data = 4500},
			{description = "5000 Uses", data = 5000}
		},
		default = -1
	},
	{
		name = "BOOK_ELEMENTAL_USES_SECIAL",
		label = "Special attack consumption",
		hover = "The percentage of lossed durability for special attacks, require no Infinite durability",
		options = {
			{description = "5%/use", data = 5},
			{description = "10%/use", data = 10},
			{description = "15%/use", data = 15},
			{description = "20%/use", data = 20},
			{description = "25%/use", data = 25},
			{description = "30%/use", data = 30},
			{description = "35%/use", data = 35},
			{description = "40%/use", data = 40},
			{description = "45%/use", data = 45},
			{description = "50%/use", data = 50},
			{description = "55%/use", data = 55},
			{description = "60%/use", data = 60},
			{description = "65%/use", data = 65},
			{description = "70%/use", data = 70},
			{description = "75%/use", data = 75},
			{description = "80%/use", data = 80},
			{description = "85%/use", data = 85},
			{description = "90%/use", data = 90},
			{description = "95%/use", data = 95},
			{description = "100%/use", data = 100}
		},
		default = 5
	},
	{
		name = "BOOK_ELEMENTAL_SPELLDURATION",
		label = "Spell duration",
		options = {
			{description = "5s", data = 5},
			{description = "10s", data = 10},
			{description = "15s", data = 15},
			{description = "20s", data = 20},
			{description = "25s", data = 25},
			{description = "30s", data = 30}
		},
		default = 10
	},
	{
		name = "BOOK_ELEMENTAL_RECHARGETIME",
		label = "Recharge time",
		options = {
			{description = "10s", data = 10},
			{description = "20s", data = 20},
			{description = "30s", data = 30},
			{description = "40s", data = 40},
			{description = "50s", data = 50},
			{description = "1min", data = 60},
			{description = "2min", data = 120},
			{description = "5min", data = 300}
		},
		default = 30
	},
	-- Pith Pike
	{
		name = "----- Pith Pike -----",
		options = {
			{description = "---------", data = 0}
		},
		default = 0
	},
	{
		name = "SPEAR_GUNGNIR_DURABILITY",
		label = "Durability",
		options = {
			{description = "Infinite", data = -1},
			{description = "500", data = 500},
			{description = "1000", data = 1000},
			{description = "1500", data = 1500},
			{description = "2000", data = 2000},
			{description = "2500", data = 2500},
			{description = "3000", data = 3000},
			{description = "3500", data = 3500},
			{description = "4000", data = 4000},
			{description = "4500", data = 4500},
			{description = "5000", data = 5000}
		},
		default = -1
	},
	{
		name = "SPEAR_GUNGNIR_USES_NORMAL",
		label = "Normal attack consumption",
		hover = "The amount of lossed durability for normal attacks, require no Infinite durability",
		options = {
			{description = "5/use", data = 5},
			{description = "10/use", data = 10},
			{description = "20/use", data = 20},
			{description = "50/use", data = 50},
			{description = "100/use", data = 100},
			{description = "150/use", data = 150},
			{description = "200/use", data = 200},
			{description = "250/use", data = 250},
			{description = "300/use", data = 300}
		},
		default = 10
	},
	{
		name = "SPEAR_GUNGNIR_USES_SECIAL",
		label = "Special attack consumption",
		hover = "The percentage of lossed durability for special attacks, require no Infinite durability",
		options = {
			{description = "5%/use", data = 5},
			{description = "10%/use", data = 10},
			{description = "15%/use", data = 15},
			{description = "20%/use", data = 20},
			{description = "25%/use", data = 25},
			{description = "30%/use", data = 30},
			{description = "35%/use", data = 35},
			{description = "40%/use", data = 40},
			{description = "45%/use", data = 45},
			{description = "50%/use", data = 50},
			{description = "55%/use", data = 55},
			{description = "60%/use", data = 60},
			{description = "65%/use", data = 65},
			{description = "70%/use", data = 70},
			{description = "75%/use", data = 75},
			{description = "80%/use", data = 80},
			{description = "85%/use", data = 85},
			{description = "90%/use", data = 90},
			{description = "95%/use", data = 95},
			{description = "100%/use", data = 100}
		},
		default = 5
	},
	{
		name = "SPEAR_GUNGNIR_DAMAGES",
		label = "Normal attack damages",
		options = {
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
			{description = "35", data = 35},
			{description = "40", data = 40},
			{description = "45", data = 45},
			{description = "50", data = 50},
			{description = "55", data = 55},
			{description = "60", data = 60},
			{description = "65", data = 65},
			{description = "70", data = 70},
			{description = "75", data = 75},
			{description = "80", data = 80},
			{description = "85", data = 85},
			{description = "90", data = 90},
			{description = "95", data = 95},
			{description = "100", data = 100}
		},
		default = 25
	},
	{
		name = "SPEAR_GUNGNIR_RECHARGETIME",
		label = "Recharge time",
		options = {
			{description = "10s", data = 10},
			{description = "20s", data = 20},
			{description = "30s", data = 30},
			{description = "40s", data = 40},
			{description = "50s", data = 50},
			{description = "1min", data = 60},
			{description = "2min", data = 120},
			{description = "5min", data = 300}
		},
		default = 30
	}
}