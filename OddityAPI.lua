--- STEAMODDED HEADER
--- MOD_NAME: OddityAPI
--- MOD_ID: OddityAPI
--- MOD_AUTHOR: [AutumnMood (it/she/they)]
--- MOD_DESCRIPTION: Adds Oddities to the game as a concept. Adds generic supplemental content.
--- PRIORITY: -25
--- BADGE_COLOUR: 826390
--- DISPLAY_NAME: OddityAPI
--- PREFIX: odd

-- 	TODO: select & use button from packs (e.g. how shops let you buy & use)
-- TODO: sprite size handling (may be coming to SMODS?)
-- TODO: oddity usage statistics (lazy)

OddityAPI = {
	config = {
		enable_packs = true,
		enable_tags = true,
		base_shop_rate = 3,
		
		-- rate of common oddities - default: 65
		base_common_rate = 65,
		-- rate of uncommon oddities - default: 30
		base_uncommon_rate = 30,
		-- rate of rare oddities - default: 5
		base_rare_rate = 5,
		-- rate of legendary oddities - default: 0
		base_legendary_rate = 0,
	}
}

G.C.SET.Oddity = HEX("826390")
G.C.SECONDARY_SET.Oddity = HEX("826390")
loc_colour("mult", nil)
G.ARGS.LOC_COLOURS["oddity"] = G.C.SECONDARY_SET.Oddity

SMODS.Atlas {
	key = "Oddity",
	path = "Oddity.png",
	px = 71,
	py = 95,
}

SMODS.Atlas {
	key = "modicon",
	path = "OddityTag.png",
	px = 34,
	py = 34,
}

SMODS.ConsumableType {
	key = 'Oddity',
	collection_rows = { 5, 5, 5 },
	primary_colour = G.C.SET.Oddity,
	secondary_colour = G.C.SECONDARY_SET.Oddity,
	loc_txt = {
		name = "Oddity",
		collection = "Oddities",
		label = "Oddity",
		undiscovered = {
			name = "Not Discovered",
			text = {
				"Purchase or use",
				"this oddity in an",
				"unseeded run to",
				"learn what it does"
			},
		},
	},
	inject_card = function(self, center)
		if not self.default then self.default = center.key end
		center.rarity = center.rarity and math.min(center.rarity, center.rarity*-1) or -1
		--SMODS.ConsumableType.inject_card(self, center)
		table.insert(self.rarity_pools[center.rarity], center)
	end,
	set_card_type_badge = function(self,_c,card,badges)
		table.insert(badges, create_badge(localize('k_oddity'), G.C.SECONDARY_SET.Oddity, nil, 1.2))
		if _c.discovered then
			local rarity_names = {localize('k_common'), localize('k_uncommon'), localize('k_rare'), localize('k_legendary')}
			local rarity_name = rarity_names[-1*_c.rarity]
			local rarity_color = G.C.RARITY[-1*_c.rarity]
			table.insert(badges, create_badge(rarity_name, rarity_color, nil, 1.0))
		end
	end,
	rarities = {{key = -1, rate = OddityAPI.config.base_common_rate}, {key = -2, rate = OddityAPI.config.base_uncommon_rate}, {key = -3, rate = OddityAPI.config.base_rare_rate}, {key = -4, rate = OddityAPI.config.base_legendary_rate}},
	shop_rate = OddityAPI.config.base_shop_rate,
}

SMODS.UndiscoveredSprite {
	key = "Oddity",
	atlas = "Oddity",
	pos = {
		x = 0,
		y = 1,
	}
}

if OddityAPI.config.enable_tags then
	SMODS.Tag {
		name = "Oddity Tag",
		key = "oddity",
		set = "Tag",
		config = {type = "new_blind_choice"},
		pos = {x = 0, y = 0},
		atlas = "modicon",
		loc_txt = {
			name = "Oddity Tag",
			text = {
				"Gives a free",
				"{C:oddity}Mega Oddity Pack",
			}
		},
		discovered = false,
		apply = function(self, context)
			--print("yo")
			--if context.type == 'new_blind_choice' then
				local lock = self.ID
				G.CONTROLLER.locks[lock] = true
				self:yep('+', G.C.SECONDARY_SET.Oddity, function() 
					local key = 'p_oddity_mega_'..(math.random(1,2))
					local card = Card(G.play.T.x + G.play.T.w/2 - G.CARD_W*1.27/2,
					G.play.T.y + G.play.T.h/2-G.CARD_H*1.27/2, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[key], {bypass_discovery_center = true, bypass_discovery_ui = true})
					card.cost = 0
					card.from_tag = true
					G.FUNCS.use_card({config = {ref_table = card}})
					card:start_materialize()
					G.CONTROLLER.locks[lock] = nil
					return true
				end)
				self.triggered = true
				return true
			--end
		end,
		loc_vars = function(_c, info_queue)
			info_queue[#info_queue+1] = G.P_CENTERS.p_oddity_mega_1
			return {vars = {}}
		end,
	}

	SMODS.Tag {
		name = "Heirloom Tag",
		key = "heirloom",
		set = "Tag",
		config = {type = "immediate", spawn_oddities = 1},
		pos = {x = 1, y = 0},
		atlas = "modicon",
		loc_txt = {
			name = "Heirloom Tag",
			text = {
				"Create a",
				"{C:legendary,E:1}Legendary{} {C:oddity}Oddity{}",
				"{C:inactive}(Must have room)"
			}
		},
		discovered = false,
		apply = function(self, context)
			--print("yo")
			--if context.type == 'immediate' then
				local lock = self.ID
				G.CONTROLLER.locks[lock] = true
				self:yep('+', G.C.PURPLE,function() 
					for i = 1, self.config.spawn_oddities do
						if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
							local card = create_card('Oddity', G.consumeables, true, nil, nil, nil, nil, 'heirloomtag')
							card:add_to_deck()
							G.consumeables:emplace(card)
						end
					end
					G.CONTROLLER.locks[lock] = nil
					return true
				end)
				self.triggered = true
				return true
			--end
		end,
		loc_vars = function() return {vars = {}} end,
	}

	
end

SMODS.current_mod.process_loc_text = function()
	G.localization.misc.dictionary["k_oddity_pack"] = "Oddity Pack"

	G.localization.descriptions["Other"]["p_oddity_normal"] = {
		name = "Oddity Pack",
		text = {
			"Choose {C:attention}1{} of up to",
			"{C:attention}3{C:oddity} Oddities{} to add",
			"to your consumables"
		}
	}
	G.localization.descriptions["Other"]["p_oddity_jumbo"] = {
		name = "Jumbo Oddity Pack",
		text = {
			"Choose {C:attention}1{} of up to",
			"{C:attention}5{C:oddity} Oddities{} to add",
			"to your consumables"
		}
	}
	G.localization.descriptions["Other"]["p_oddity_mega"] = {
		name = "Mega Oddity Pack",
		text = {
			"Choose {C:attention}2{} of up to",
			"{C:attention}5{C:oddity} Oddities{} to add",
			"to your consumables"
		}
	}
end

-- REPLACE THIS WHEN AND IF A REAL PACK API IS MADE
if OddityAPI.config.enable_packs then
	local minId = table_length(G.P_CENTER_POOLS['Booster']) + 1
	local id = 0
	local i = 0
	i = i + 1
	-- Prepare some Datas
	id = i + minId

	local booster_objs = {
		{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_1", pos = {x = 1, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_2", pos = {x = 2, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_3", pos = {x = 3, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_4", pos = {x = 4, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Jumbo Oddity Pack", set = "Booster", order = id, key = "p_oddity_jumbo_1", pos = {x = 1, y = 1}, cost = 6, config = {extra = 5, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Jumbo Oddity Pack", set = "Booster", order = id, key = "p_oddity_jumbo_2", pos = {x = 2, y = 1}, cost = 6, config = {extra = 5, choose = 1}, weight = 1, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Mega Oddity Pack", set = "Booster", order = id, key = "p_oddity_mega_1", pos = {x = 3, y = 1}, cost = 8, config = {extra = 5, choose = 2}, weight = 0.25, kind = "Celestial",atlas = "odd_Oddity"},
		{discovered = true, name = "Mega Oddity Pack", set = "Booster", order = id, key = "p_oddity_mega_2", pos = {x = 4, y = 1}, cost = 8, config = {extra = 5, choose = 2}, weight = 0.25, kind = "Celestial",atlas = "odd_Oddity"},
	}
	for _, v in ipairs(booster_objs) do
		G.P_CENTERS[v.key] = v
		table.insert(G.P_CENTER_POOLS['Booster'], v)

		sendDebugMessage("The Booster named " .. v.name .. " with the slug " .. v.key .. " have been registered at the id " .. id .. ".")
		id = id + 1
	end
end

function Game:update_oddity_pack(dt)
    if self.buttons then self.buttons:remove(); self.buttons = nil end
    if self.shop then G.shop.alignment.offset.y = G.ROOM.T.y+11 end

    if not G.STATE_COMPLETE then
        G.STATE_COMPLETE = true
        G.CONTROLLER.interrupt.focus = true
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                G.booster_pack_sparkles = Particles(1, 1, 0,0, {
                    timer = 0.015,
                    scale = 0.3,
                    initialize = true,
                    lifespan = 3,
                    speed = 0.2,
                    padding = -1,
                    attach = G.ROOM_ATTACH,
                    colours = {G.C.ORANGE, G.C.PURPLE, G.C.GREEN, G.C.YELLOW, G.C.BLUE, G.C.RED},
                    fill = true
                })
                G.booster_pack_sparkles.fade_alpha = 1
                G.booster_pack_sparkles:fade(1, 0)
                G.booster_pack = UIBox{
                    definition = create_UIBox_standard_pack(),
                    config = {align="tmi", offset = {x=0,y=G.ROOM.T.y + 9},major = G.hand, bond = 'Weak'}
                }
                G.booster_pack.alignment.offset.y = -2.2
                        G.ROOM.jiggle = G.ROOM.jiggle + 3
                ease_background_colour_blind(G.STATES.STANDARD_PACK)
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.5,
                            func = function()
                                G.CONTROLLER:recall_cardarea_focus('pack_cards')
                                return true
                            end}))
                        return true
                    end
                }))  
                return true
            end
        }))  
    end
end

local alias__Game_update_standard_pack = Game.update_standard_pack;
function Game:update_standard_pack(dt)
	if G.ARGS.is_oddity_booster then
		Game:update_oddity_pack(dt)
	else
		alias__Game_update_standard_pack(self, dt)
	end
end