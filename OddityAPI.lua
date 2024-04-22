--- STEAMODDED HEADER
--- MOD_NAME: OddityAPI
--- MOD_ID: OddityAPI
--- MOD_AUTHOR: [AutumnMood]
--- MOD_DESCRIPTION: Adds Oddities to the game as a concept. Doesn't add any content on its own.
--- PRIORITY: -25

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Oddities = {}
SMODS.Oddity = {
	name = "",
	slug = "",
	cost = 3,
	config = {},
	pos = {},
	loc_txt = {},
	discovered = false,
	consumeable = true,
	effect = "",
	cost_mult = 1.0,
}
SMODS.BUFFERS.Oddities = {}

function SMODS.Oddity:new(name, slug, config, pos, loc_txt, rarity, cost, cost_mult, effect, consumeable, discovered, atlas)
	o = {}
	setmetatable(o, self)
	self.__index = self

	if type(name) == 'string' then
		o.loc_txt = loc_txt
		o.name = name
		o.slug = "c_" .. slug
		o.config = config or {}
		o.pos = pos or {
			x = 0,
			y = 0
		}
		o.rarity = rarity or 1
		o.cost = cost
		o.unlocked = true
		o.discovered = discovered or false
		o.consumeable = not (consumeable == false)
		o.consumed_on_use = true
		o.effect = effect or ""
		o.cost_mult = cost_mult or 1.0
		o.atlas = atlas
	elseif type(name) == 'table' then
		local v = name -- literally just being lazy
		o.loc_txt = v.loc_txt
		o.name = v.name
		o.slug = "c_" .. v.slug
		o.config = v.config or {}
		o.pos = v.pos or {
			x = 0,
			y = 0
		}
		o.rarity = v.rarity or 1
		o.cost = v.cost
		o.unlocked = true
		o.discovered = v.discovered or false
		o.consumeable = not (v.consumeable == false)
		o.consumed_on_use = not (v.consumed_on_use == false)
		o.effect = v.effect or ""
		o.cost_mult = v.cost_mult or 1.0
		o.atlas = v.atlas
		o.loc_def = v.loc_def
		o.use = v.use
		o.can_use = v.can_use
		o.set_badges = v.set_badges
		o.yes_pool_flag = v.yes_pool_flag
		o.no_pool_flag = v.no_pool_flag
	end
	o.mod_name = SMODS._MOD_NAME
	o.badge_colour = SMODS._BADGE_COLOUR
	return o
end

function SMODS.Oddity:register()
	if not SMODS.Oddities[self.slug] then
		SMODS.Oddities[self.slug] = self
		SMODS.BUFFERS.Oddities[#SMODS.BUFFERS.Oddities + 1] = self.slug
	end
end

-- Not sure i need to do this like this, but it makes the loading timing consistent?
local alias__SMODS_injectTarots = SMODS.injectTarots;
function SMODS.injectTarots()
	alias__SMODS_injectTarots()
	SMODS.injectOddities()
end

local alias__Card_set_ability = Card.set_ability;
function Card:set_ability(center,initial,delay_sprites)
    alias__Card_set_ability(self,center,initial,delay_sprites)
	
	local oddity_obj = SMODS.Oddities[center.key]
	if oddity_obj and oddity_obj.pos then
        self.T.h = self.T.h * (oddity_obj.pos.scale_h or 1)
        self.T.w = self.T.w * (oddity_obj.pos.scale_w or 1)
	end
end

local alias__Card_load = Card.load;
function Card:load(cardTable, other_card)
    alias__Card_load(self,cardTable,other_card)
	
	local oddity_obj = SMODS.Oddity[self.config.center.key]
	if oddity_obj and oddity_obj.pos then
        self.T.h = G.CARD_H * (oddity_obj.pos.scale_h or 1)
        self.T.w = G.CARD_W * (oddity_obj.pos.scale_w or 1)
	end
end

local alias__Card_set_sprites = Card.set_sprites;
function Card:set_sprites(_center, _front)
	alias__Card_set_sprites(self, _center, _front)
    if _center then
        if _center.set then
            if (_center.set == 'Oddity') and _center.atlas then
                if self.params.bypass_discovery_center or (_center.unlocked and _center.discovered) then
                    self.children.center.atlas = G.ASSET_ATLAS[(_center.atlas or (_center.set == 'Oddity') and _center.set) or 'centers']
                    self.children.center:set_sprite_pos(_center.pos)
                    sendDebugMessage(inspect(self.children.center))
                elseif not _center.discovered then
					if _center.set == "Oddity" then
						self.children.center.atlas = G.ASSET_ATLAS["Oddity"]
						self.children.center:set_sprite_pos(G.o_undiscovered.pos)
					end
                end
                if _center.soul_pos then
                    self.children.floating_sprite.atlas = G.ASSET_ATLAS[_center.atlas or _center.set]
                    self.children.floating_sprite:set_sprite_pos(_center.soul_pos)
                end
            end
        end
		local oddity_obj = SMODS.Oddities[_center.key]
		if oddity_obj and oddity_obj.pos then
			self.children.center.scale.x = self.children.center.scale.x * (oddity_obj.pos.scale_w or 1)
			self.children.center.scale.y = self.children.center.scale.y * (oddity_obj.pos.scale_h or 1)
		end
    end
end

function SMODS.injectOddities()
	
	G.P_CENTER_POOLS['Oddity'] = G.P_CENTER_POOLS['Oddity'] or {}
	G.P_ODDITY_RARITY_POOLS = G.P_ODDITY_RARITY_POOLS or {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
	}
	local minId = table_length(G.P_CENTER_POOLS['Oddity']) + 1
	local id = 0
	local i = 0
	local oddity = nil
	for _, slug in ipairs(SMODS.BUFFERS.Oddities) do
		oddity = SMODS.Oddities[slug]
		i = i + 1
		-- Prepare some Datas
		id = i + minId
		local oddity_obj = {
			unlocked = oddity.unlocked,
			discovered = oddity.discovered,
			consumeable = oddity.consumeable,
			consumed_on_use = oddity.consumed_on_use,
			name = oddity.name,
			set = "Oddity",
			order = id,
			key = oddity.slug,
			pos = oddity.pos,
			rarity = oddity.rarity,
			config = oddity.config,
			effect = oddity.effect,
			cost = oddity.cost,
			cost_mult = oddity.cost_mult,
			atlas = oddity.atlas,
			mod_name = oddity.mod_name,
			badge_colour = oddity.badge_colour,
			no_pool_flag = oddity.no_pool_flag,
			yes_pool_flag = oddity.yes_pool_flag,
		}

		for _i, sprite in ipairs(SMODS.Sprites) do
			if sprite.name == oddity_obj.key then
				oddity_obj.atlas = sprite.name
			end
		end

		-- Now we replace the others
		G.P_CENTERS[oddity.slug] = oddity_obj
		table.insert(G.P_CENTER_POOLS['Oddity'], oddity_obj)
        table.insert(G.P_ODDITY_RARITY_POOLS[oddity_obj.rarity], oddity_obj)

        -- Setup Localize text
        G.localization.descriptions["Oddity"][oddity.slug] = oddity.loc_txt
        sendInfoMessage("Registered Oddity " .. oddity.name .. " with the slug " .. oddity.slug .. " at ID " .. id .. ".", 'ConsumableAPI')
	end
	SMODS.BUFFERS.Oddities = {}
end

-- EVERYTHING having to do with collections...
-- huge shout-outs to itayfeder for figuring this stuff out.
local create_UIBox_your_collectionref = create_UIBox_your_collection
function create_UIBox_your_collection()
    local retval = create_UIBox_your_collectionref()
    table.insert(retval.nodes[1].nodes[1].nodes[1].nodes[1].nodes[4].nodes[2].nodes, UIBox_button({
        button = 'your_collection_oddities', label = { "Oddities" }, count = G.DISCOVER_TALLIES.oddities, minw = 4, id = 'your_collection_oddities', colour = G.C.SECONDARY_SET.Oddity
    }))
    return retval
end

G.FUNCS.your_collection_oddities = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = create_UIBox_your_collection_oddities(),
  }
end

G.FUNCS.your_collection_oddities_page = function(args)
  if not args or not args.cycle_config then return end
  for j = 1, #G.your_collection do
    for i = #G.your_collection[j].cards,1, -1 do
      local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
      c:remove()
      c = nil
    end
  end
  
  for j = 1, #G.your_collection do
    for i = 1, 6 do
      local center = G.P_CENTER_POOLS["Oddity"][(j-1) * 6 + i + (12*(args.cycle_config.current_option - 1))]
      if not center then break end
      local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, center)
      card:start_materialize(nil, i>1 or j>1)
      G.your_collection[j]:emplace(card)
    end
  end
  INIT_COLLECTION_CARD_ALERTS()
end

function create_UIBox_your_collection_oddities()
    local deck_tables = {}
  
    G.your_collection = {}
    for j = 1, 2 do
      G.your_collection[j] = CardArea(
        G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
        (6.25)*G.CARD_W,
        1*G.CARD_H, 
        {card_limit = 6, type = 'title', highlight_limit = 0, collection = true})
      table.insert(deck_tables, 
      {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
        {n=G.UIT.O, config={object = G.your_collection[j]}}
      }}
      )
    end
  
    local oddity_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Oddity/12) do
      table.insert(oddity_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS.Oddity/12)))
    end
  
    for j = 1, #G.your_collection do
      for i = 1, 6 do
        local center = G.P_CENTER_POOLS["Oddity"][(j-1) * 6 + i]
        if type(center) == "table" then
          local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, nil, center)
          card:start_materialize(nil, i>1 or j>1)
          G.your_collection[j]:emplace(card)
        end
      end
    end
  
    INIT_COLLECTION_CARD_ALERTS()
    
    local t = create_UIBox_generic_options({ back_func = 'your_collection', contents = {
              {n=G.UIT.R, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables},
                    {n=G.UIT.R, config={align = "cm"}, nodes={
                      create_option_cycle({options = oddity_options, w = 6.5, cycle_shoulders = true, opt_callback = 'your_collection_oddities_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
                    }}
            }})
    return t
end

local set_discover_talliesref = set_discover_tallies
function set_discover_tallies()
  set_discover_talliesref()

  G.DISCOVER_TALLIES.oddities = {tally = 0, of = 0}

  for _, v in pairs(G.P_CENTERS) do
    if not v.omit then 
      if v.set and v.consumeable and v.set == 'Oddity' then
        G.DISCOVER_TALLIES.oddities.of = G.DISCOVER_TALLIES.oddities.of+1
          if v.discovered then 
              G.DISCOVER_TALLIES.oddities.tally = G.DISCOVER_TALLIES.oddities.tally+1
          end
      end
    end
  end
end

local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
	local original_full_UI_table = full_UI_table
	local original_main_end = main_end
	local first_pass = nil
	if not full_UI_table then
		first_pass = true
		full_UI_table = {
			main = {},
			info = {},
			type = {},
			name = nil,
			badges = badges or {}
		}
	end

	local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
	local name_override = nil
	local info_queue = {}

	local loc_vars = {}

	if not (card_type == 'Locked') and not hide_desc and not (specific_vars and specific_vars.debuffed) then
		local key = _c.key
		local center_obj = SMODS.Oddities[key]
		if center_obj and center_obj.loc_def and type(center_obj.loc_def) == 'function' then
			local o, m = center_obj.loc_def(_c, info_queue)
			if o and next(o) then loc_vars = o end
			if m then main_end = m end
		end
	end

	if next(loc_vars) or next(info_queue) or (_c.set == 'Booster' and _c.name:find("Oddity")) then
		if full_UI_table.name then
			full_UI_table.info[#full_UI_table.info + 1] = {}
			desc_nodes = full_UI_table.info[#full_UI_table.info]
		end
		if not full_UI_table.name then
			if specific_vars and specific_vars.no_name then
				full_UI_table.name = true
			elseif card_type == 'Locked' then
				full_UI_table.name = localize { type = 'name', set = 'Other', key = 'locked', nodes = {} }
			elseif card_type == 'Undiscovered' then
				full_UI_table.name = localize { type = 'name', set = 'Other', key = 'undiscovered_' .. (string.lower(_c.set)), name_nodes = {} }
			elseif specific_vars and (card_type == 'Default' or card_type == 'Enhanced') then
				if (_c.name == 'Stone Card') then full_UI_table.name = true end
				if (specific_vars.playing_card and (_c.name ~= 'Stone Card')) then
					full_UI_table.name = {}
					localize { type = 'other', key = 'playing_card', set = 'Other', nodes = full_UI_table.name, vars = { localize(specific_vars.value, 'ranks'), localize(specific_vars.suit, 'suits_plural'), colours = { specific_vars.colour } } }
					full_UI_table.name = full_UI_table.name[1]
				end
			elseif card_type == 'Booster' then
				if _c.name:find("Oddity") then
					local desc_override = 'p_oddity_normal'
					if _c.name == 'Oddity Pack' then desc_override = 'p_oddity_normal'; loc_vars = {_c.config.choose, _c.config.extra} end
					if _c.name == 'Jumbo Oddity Pack' then desc_override = 'p_oddity_jumbo'; loc_vars = {_c.config.choose, _c.config.extra} end
					if _c.name == 'Mega Oddity Pack' then desc_override = 'p_oddity_mega'; loc_vars = {_c.config.choose, _c.config.extra} end
					name_override = desc_override
					full_UI_table.name = localize{type = 'name', set = 'Other', key = name_override, nodes = full_UI_table.name}
				end
			else
				full_UI_table.name = localize { type = 'name', set = _c.set, key = _c.key, nodes = full_UI_table.name }
			end
			full_UI_table.card_type = card_type or _c.set
		end
		if main_start then
			desc_nodes[#desc_nodes + 1] = main_start
		end
		
		if next(loc_vars) then
			if card_type == 'Booster' and _c.name:find("Oddity") then
				localize{type = 'other', key = name_override, nodes = desc_nodes, vars = loc_vars}
			else
				localize { type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars }
			end
			if not ((specific_vars and not specific_vars.sticker) and (card_type == 'Default' or card_type == 'Enhanced')) then
				if desc_nodes == full_UI_table.main and not full_UI_table.name then
					localize { type = 'name', key = _c.key, set = _c.set, nodes = full_UI_table.name }
					if not full_UI_table.name then full_UI_table.name = {} end
				elseif desc_nodes ~= full_UI_table.main then
					desc_nodes.name = localize { type = 'name_text', key = name_override or _c.key, set = name_override and 'Other' or _c.set }
				end
			end
		end
		if main_end then
			desc_nodes[#desc_nodes + 1] = main_end
		end

		for _, v in ipairs(info_queue) do
			generate_card_ui(v, full_UI_table)
		end
		return full_UI_table
	end
	return generate_card_ui_ref(_c, original_full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
		original_main_end)
end

local card_use_consumeable_ref = Card.use_consumeable
function Card:use_consumeable(area, copier)
	local key = self.config.center.key
	local center_obj = SMODS.Oddities[key]
	if center_obj and center_obj.use and type(center_obj.use) == 'function' then
		stop_use()
		if not copier then set_consumeable_usage(self) end
		if self.debuff then return nil end
		if self.ability.consumeable.max_highlighted then
			update_hand_text({ immediate = true, nopulse = true, delay = 0 },
				{ mult = 0, chips = 0, level = '', handname = '' })
		end
		center_obj.use(self, area, copier)
	else
		card_use_consumeable_ref(self, area, copier)
	end
end

local card_can_use_consumeable_ref = Card.can_use_consumeable
function Card:can_use_consumeable(any_state, skip_check)
	if not skip_check and ((G.play and #G.play.cards > 0) or
			(G.CONTROLLER.locked) or
			(G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
	then
		return false
	end
	if (G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.PLAY_TAROT) and not any_state then
		return false
	end
	local t = nil
	local key = self.config.center.key
	local center_obj = SMODS.Oddities[key]
	if center_obj and center_obj.can_use and type(center_obj.can_use) == 'function' then
		t = center_obj.can_use(self) or t
	end
	if not (t == nil) then
		return t
	else
		return card_can_use_consumeable_ref(self, any_state, skip_check)
	end
end

local calculate_jokerref = Card.calculate_joker;
function Card:calculate_joker(context)
    if not self.debuff then
        local key = self.config.center.key
        local center_obj = SMODS.Oddities[key]
        if center_obj and center_obj.calculate and type(center_obj.calculate) == "function" then
            local o = center_obj.calculate(self, context)
            if o then return o end
        end
    end
    return calculate_jokerref(self, context)
end

local card_h_popup_ref = G.UIDEF.card_h_popup
function G.UIDEF.card_h_popup(card)
	local t = card_h_popup_ref(card)
	if not card.config.center then return t end
	local badges = t.nodes[1].nodes[1].nodes[1].nodes[3]
	badges = badges and badges.nodes or nil
	local key = card.config.center.key
	local center_obj = SMODS.Oddities[key]
	if center_obj then
		local rarity_names = {localize('k_common'), localize('k_uncommon'), localize('k_rare'), localize('k_legendary')}
		local rarity_name = rarity_names[card.config.center.rarity]
		local rarity_color = G.C.RARITY[card.config.center.rarity]
		table.insert(badges, create_badge(rarity_name, rarity_color, nil, 1.2))
		if center_obj.set_badges and type(center_obj.set_badges) == 'function' then
			center_obj.set_badges(card, badges)
		end
		if not G.SETTINGS.no_mod_tracking then
			local mod_name = string.sub(center_obj.mod_name, 1, 16)
			local len = string.len(mod_name)
			badges[#badges + 1] = create_badge(mod_name, center_obj.badge_colour or G.C.UI.BACKGROUND_INACTIVE, nil,
				len <= 6 and 0.9 or 0.9 - 0.02 * (len - 6))
		end
	end
	return t
end

local alias__get_type_colour = get_type_colour
function get_type_colour(_c, card)
  local ret = alias__get_type_colour(_c, card)

  if _c.set == "Oddity" then
    return G.C.SECONDARY_SET.Oddity
  end

  return ret
end

local card_openref = Card.open
function Card:open()
  G.ARGS.is_oddity_booster = false
  if self.ability.set == "Booster" and self.ability.name:find('Oddity') then
      stop_use()
      G.STATE_COMPLETE = false 
      self.opening = true

      if not self.config.center.discovered then
          discover_card(self.config.center)
      end
      self.states.hover.can = false

      G.ARGS.is_oddity_booster = true
      G.STATE = G.STATES.STANDARD_PACK
      G.GAME.pack_size = self.ability.extra

      G.GAME.pack_choices = self.config.center.config.choose or 1

      if self.cost > 0 then 
          G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
              inc_career_stat('c_shop_dollars_spent', self.cost)
              self:juice_up()
          return true end }))
          ease_dollars(-self.cost) 
     else
         delay(0.2)
     end

      G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
          self:explode()
          local pack_cards = {}

          G.E_MANAGER:add_event(Event({trigger = 'after', delay = 1.3*math.sqrt(G.SETTINGS.GAMESPEED), blockable = false, blocking = false, func = function()
              local _size = self.ability.extra
              
              for i = 1, _size do
                  local card = nil
                  card = create_card("Oddity", G.pack_cards, nil, nil, true, true, nil, 'odd')
                  card.T.x = self.T.x
                  card.T.y = self.T.y
                  card:start_materialize({G.C.WHITE, G.C.WHITE}, nil, 1.5*G.SETTINGS.GAMESPEED)
                  pack_cards[i] = card
              end
              return true
          end}))

          G.E_MANAGER:add_event(Event({trigger = 'after', delay = 1.3*math.sqrt(G.SETTINGS.GAMESPEED), blockable = false, blocking = false, func = function()
              if G.pack_cards then 
                  if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then 
                  for k, v in ipairs(pack_cards) do
                      G.pack_cards:emplace(v)
                  end
                  return true
                  end
              end
          end}))

          for i = 1, #G.jokers.cards do
              G.jokers.cards[i]:calculate_joker({open_booster = true, card = self})
          end

          if G.GAME.modifiers.inflation then 
              G.GAME.inflation = G.GAME.inflation + 1
              G.E_MANAGER:add_event(Event({func = function()
                for k, v in pairs(G.I.CARD) do
                    if v.set_cost then v:set_cost() end
                end
                return true end }))
          end

      return true end }))
  else
    card_openref(self)
  end
end

local alias__get_current_pool = get_current_pool;
function get_current_pool(_type, _rarity, _legendary, _append)
	if _type == 'Oddity' then 
        --create the pool
        G.ARGS.TEMP_POOL = EMPTY(G.ARGS.TEMP_POOL)
        local _pool, _starting_pool, _pool_key, _pool_size = G.ARGS.TEMP_POOL, nil, '', 0
    
		local rarity = _rarity or pseudorandom('rarity'..G.GAME.round_resets.ante..(_append or '')) 
		rarity = (_legendary and 4) or (rarity > 0.95 and 3) or (rarity > 0.7 and 2) or 1
		_starting_pool, _pool_key = G.P_ODDITY_RARITY_POOLS[rarity], 'Oddity'..rarity..((not _legendary and _append) or '')
    
        --cull the pool
        for k, v in ipairs(_starting_pool) do
            local add = nil
            if not (G.GAME.used_jokers[v.key] and not next(find_joker("Showman"))) and (v.unlocked ~= false or v.rarity == 4) then
                    add = true
            end

            if v.no_pool_flag and G.GAME.pool_flags[v.no_pool_flag] then add = nil end
            if v.yes_pool_flag and not G.GAME.pool_flags[v.yes_pool_flag] then add = nil end
            
            if add and not G.GAME.banned_keys[v.key] then 
                _pool[#_pool + 1] = v.key
                _pool_size = _pool_size + 1
            else
                _pool[#_pool + 1] = 'UNAVAILABLE'
            end
        end

        --if pool is empty
        if _pool_size == 0 then
            _pool = EMPTY(G.ARGS.TEMP_POOL)
            _pool[#_pool + 1] = "j_joker" --todo not this
        end

        return _pool, _pool_key..(not _legendary and G.GAME.round_resets.ante or '')
	else
		return alias__get_current_pool(_type, _rarity, _legendary, _append)
	end
end

local alias__Game_init_game_object = Game.init_game_object;
function Game:init_game_object()
	local ret = alias__Game_init_game_object(self)
	ret.oddity_rate = 4
	return ret
end

local create_UIBox_standard_packref = create_UIBox_standard_pack
function create_UIBox_standard_pack()
  if G.ARGS.is_oddity_booster then
    local _size = G.GAME.pack_size
    G.pack_cards = CardArea(
      G.ROOM.T.x + 9 + G.hand.T.x, G.hand.T.y,
      _size*G.CARD_W*1.1,
      1.05*G.CARD_H, 
      {card_limit = _size, type = 'consumeable', highlight_limit = 1})

      local t = {n=G.UIT.ROOT, config = {align = 'tm', r = 0.15, colour = G.C.CLEAR, padding = 0.15}, nodes={
        {n=G.UIT.R, config={align = "cl", colour = G.C.CLEAR,r=0.15, padding = 0.1, minh = 2, shadow = true}, nodes={
          {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cm", r=0.2, colour = G.C.CLEAR, shadow = true}, nodes={
              {n=G.UIT.O, config={object = G.pack_cards}},
            }}
          }}
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
        }},
        {n=G.UIT.R, config={align = "tm"}, nodes={
          {n=G.UIT.C,config={align = "tm", padding = 0.05, minw = 2.4}, nodes={}},
          {n=G.UIT.C,config={align = "tm", padding = 0.05}, nodes={
          UIBox_dyn_container({
            {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 4}, nodes={
              {n=G.UIT.R,config={align = "bm", padding = 0.05}, nodes={
                {n=G.UIT.O, config={object = DynaText({string = localize('k_oddity_pack'), colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.7, maxw = 4, pop_in = 0.5})}}
              }},
              {n=G.UIT.R,config={align = "bm", padding = 0.05}, nodes={
                {n=G.UIT.O, config={object = DynaText({string = {localize('k_choose')..' '}, colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.5, pop_in = 0.7})}},
                {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'pack_choices'}}, colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.5, pop_in = 0.7})}}
              }},
            }}
          }),
        }},
          {n=G.UIT.C,config={align = "tm", padding = 0.05, minw = 2.4}, nodes={
            {n=G.UIT.R,config={minh =0.2}, nodes={}},
            {n=G.UIT.R,config={align = "tm",padding = 0.2, minh = 1.2, minw = 1.8, r=0.15,colour = G.C.GREY, one_press = true, button = 'skip_booster', hover = true,shadow = true, func = 'can_skip_booster'}, nodes = {
              {n=G.UIT.T, config={text = localize('b_skip'), scale = 0.5, colour = G.C.WHITE, shadow = true, focus_args = {button = 'y', orientation = 'bm'}, func = 'set_button_pip'}}
            }}
          }}
        }}
      }}
    }}
    return t
  else
    return create_UIBox_standard_packref()
  end
end

-- choose your oddities
local alias__G_UIDEF_use_and_sell_buttons = G.UIDEF.use_and_sell_buttons;
function G.UIDEF.use_and_sell_buttons(card)
	local ret = alias__G_UIDEF_use_and_sell_buttons(card)
	
	if card.config.center.key and card.area then
		local center_obj = SMODS.Oddities[card.config.center.key]
		if center_obj and center_obj.consumed_on_use == false and center_obj.can_use and center_obj.use and type(center_obj.can_use) == 'function' and type(center_obj.use) == 'function' then
			local nodes_todo = {n=G.UIT.R, config={align = 'cl'}, nodes={
				{n=G.UIT.C, config={ref_table = card, align = "cr",maxw = 1.25, padding = 0.1, r=0.08, minw = 1.25, minh = (card.area and card.area.config.type == 'joker') and 0 or 1, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE, one_press = true, button = 'use_ncoddity', func = 'can_use_ncoddity'}, nodes={
					{n=G.UIT.B, config = {w=0.1,h=0.6}},
					{n=G.UIT.T, config={text = localize('b_use'),colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}}
				}}
			}}
			ret.nodes[1].nodes[2] = nodes_todo
		end
	end
	
	if card.config.center.key and (card.area == G.pack_cards and G.pack_cards) and card.ability.set == "Oddity" then
		return {
			n=G.UIT.ROOT, config = {padding = 0, colour = G.C.CLEAR}, nodes={
				{n=G.UIT.R, config={mid = true}, nodes={
				}},
				{n=G.UIT.R, config={ref_table = card, r = 0.08, padding = 0.1, align = "bm", minw = 0.5*card.T.w - 0.15, minh = 0.8*card.T.h, maxw = 0.7*card.T.w - 0.15, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE, one_press = true, button = 'select_oddity', func = 'can_select_oddity'}, nodes={
				{n=G.UIT.T, config={text = localize('b_select'),colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}}
			}},
		}}
	end
	
	return ret
end

G.FUNCS.can_use_ncoddity = function(e)
	if e.config.ref_table:can_use_consumeable() then 
		e.config.colour = G.C.RED
		e.config.button = 'use_ncoddity'
	else
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	end
end

G.FUNCS.use_ncoddity = function(e, mute, nosave)
	print("using a nonconsumeable oddity")
    e.config.button = nil
    local card = e.config.ref_table
    local area = card.area
    local prev_state = G.STATE
    local dont_dissolve = true
    local delay_fac = 1

    if card:check_use() then 
      G.E_MANAGER:add_event(Event({func = function()
        e.disable_button = nil
        e.config.button = 'use_ncoddity'
      return true end }))
      return
    end
    
	G.STATE = G.STATES.PLAY_TAROT
    G.CONTROLLER.locks.use = true
	if card.ability.usable and (not card.ability.usable == false) then
		if G.booster_pack and not G.booster_pack.alignment.offset.py and (card.ability.consumeable or not (G.GAME.pack_choices and G.GAME.pack_choices > 1)) then
		  G.booster_pack.alignment.offset.py = G.booster_pack.alignment.offset.y
		  G.booster_pack.alignment.offset.y = G.ROOM.T.y + 29
		end
		if G.shop and not G.shop.alignment.offset.py then
		  G.shop.alignment.offset.py = G.shop.alignment.offset.y
		  G.shop.alignment.offset.y = G.ROOM.T.y + 29
		end
		if G.blind_select and not G.blind_select.alignment.offset.py then
		  G.blind_select.alignment.offset.py = G.blind_select.alignment.offset.y
		  G.blind_select.alignment.offset.y = G.ROOM.T.y + 39
		end
		if G.round_eval and not G.round_eval.alignment.offset.py then
		  G.round_eval.alignment.offset.py = G.round_eval.alignment.offset.y
		  G.round_eval.alignment.offset.y = G.ROOM.T.y + 29
		end
	end
	
    G.TAROT_INTERRUPT = G.STATE
	local center_obj = SMODS.Oddities[card.config.center.key]
	if center_obj and center_obj.can_use and center_obj.use and type(center_obj.can_use) == 'function' and type(center_obj.use) == 'function' then
		--draw_card(G.hand, G.play, 1, 'up', true, card, nil, mute)
		--area:remove_card(card)
		area:remove_from_highlighted(card)
        play_sound('cardSlide2', nil, 0.3)
		delay(0.2)
		e.config.ref_table:use_consumeable(area)
		for i = 1, #G.jokers.cards do
			--THIS MIGHT BE BROKEN
			G.jokers.cards[i]:calculate_joker({using_consumeable = true, consumeable = card})
		end
	end
	G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.2,
        func = function()
            if not dont_dissolve then card:start_dissolve() end
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,
            func = function()
                G.STATE = prev_state
                G.TAROT_INTERRUPT=nil
                G.CONTROLLER.locks.use = false

				if card.ability.usable and (not card.ability.usable == false) then
                  if G.shop then 
                    G.shop.alignment.offset.y = G.shop.alignment.offset.py
                    G.shop.alignment.offset.py = nil
                  end
                  if G.blind_select then
                    G.blind_select.alignment.offset.y = G.blind_select.alignment.offset.py
                    G.blind_select.alignment.offset.py = nil
                  end
                  if G.round_eval then
                    G.round_eval.alignment.offset.y = G.round_eval.alignment.offset.py
                    G.round_eval.alignment.offset.py = nil
                  end
				end
				--draw_card(G.play, G.jokers, 1, 'up', true, card, nil, mute)
                  if area and area.cards[1] then 
                    G.E_MANAGER:add_event(Event({func = function()
                      G.E_MANAGER:add_event(Event({func = function()
                        G.CONTROLLER.interrupt.focus = nil
                        if area then
                          G.CONTROLLER:recall_cardarea_focus(area)
                        end
                      return true end }))
                    return true end }))
                  end
            return true
          end}))
        return true
	end}))
end

  G.FUNCS.can_select_oddity = function(e)
    if e.config.ref_table.ability.set ~= 'Oddity' or (e.config.ref_table.edition and e.config.ref_table.edition.negative) or #G.consumeables.cards < G.consumeables.config.card_limit then 
        e.config.colour = G.C.GREEN
        e.config.button = 'select_oddity'
    else
      e.config.colour = G.C.UI.BACKGROUND_INACTIVE
      e.config.button = nil
    end
  end
  
  -- a LOT of this is unnecessary and may be trimmed down in the future
  G.FUNCS.select_oddity = function(e, mute, nosave)
    e.config.button = nil
    local card = e.config.ref_table
    local area = card.area
    local prev_state = G.STATE
    local dont_dissolve = nil
    local delay_fac = 1

    G.TAROT_INTERRUPT = G.STATE
    if card.ability.set == 'Booster' then G.GAME.PACK_INTERRUPT = G.STATE end 
    G.STATE = (G.STATE == G.STATES.TAROT_PACK and G.STATES.TAROT_PACK) or
      (G.STATE == G.STATES.PLANET_PACK and G.STATES.PLANET_PACK) or
      (G.STATE == G.STATES.SPECTRAL_PACK and G.STATES.SPECTRAL_PACK) or
      (G.STATE == G.STATES.STANDARD_PACK and G.STATES.STANDARD_PACK) or
      (G.STATE == G.STATES.BUFFOON_PACK and G.STATES.BUFFOON_PACK) or
      G.STATES.PLAY_TAROT
      
    G.CONTROLLER.locks.use = true
    if G.booster_pack and not G.booster_pack.alignment.offset.py and (card.ability.consumeable or not (G.GAME.pack_choices and G.GAME.pack_choices > 1)) then
      G.booster_pack.alignment.offset.py = G.booster_pack.alignment.offset.y
      G.booster_pack.alignment.offset.y = G.ROOM.T.y + 29
    end
    if G.shop and not G.shop.alignment.offset.py then
      G.shop.alignment.offset.py = G.shop.alignment.offset.y
      G.shop.alignment.offset.y = G.ROOM.T.y + 29
    end
    if G.blind_select and not G.blind_select.alignment.offset.py then
      G.blind_select.alignment.offset.py = G.blind_select.alignment.offset.y
      G.blind_select.alignment.offset.y = G.ROOM.T.y + 39
    end
    if G.round_eval and not G.round_eval.alignment.offset.py then
      G.round_eval.alignment.offset.py = G.round_eval.alignment.offset.y
      G.round_eval.alignment.offset.y = G.ROOM.T.y + 29
    end

    if card.children.use_button then card.children.use_button:remove(); card.children.use_button = nil end
    if card.children.sell_button then card.children.sell_button:remove(); card.children.sell_button = nil end
    if card.children.price then card.children.price:remove(); card.children.price = nil end

    if card.area then card.area:remove_card(card) end
    
    if card.ability.set == 'Oddity' then
      card:add_to_deck()
      G.consumeables:emplace(card)
      play_sound('card1', 0.8, 0.6)
      play_sound('generic1')
      dont_dissolve = true
      delay_fac = 0.2
    end
	G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.2,
	func = function()
		if not dont_dissolve then card:start_dissolve() end
		G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,
		func = function()
			G.STATE = prev_state
			G.TAROT_INTERRUPT=nil
			G.CONTROLLER.locks.use = false

			if (prev_state == G.STATES.TAROT_PACK or prev_state == G.STATES.PLANET_PACK or
			  prev_state == G.STATES.SPECTRAL_PACK or prev_state == G.STATES.STANDARD_PACK or
			  prev_state == G.STATES.BUFFOON_PACK) and G.booster_pack then
			  if area == G.consumeables then
				G.booster_pack.alignment.offset.y = G.booster_pack.alignment.offset.py
				G.booster_pack.alignment.offset.py = nil
			  elseif G.GAME.pack_choices and G.GAME.pack_choices > 1 then
				if G.booster_pack.alignment.offset.py then 
				  G.booster_pack.alignment.offset.y = G.booster_pack.alignment.offset.py
				  G.booster_pack.alignment.offset.py = nil
				end
				G.GAME.pack_choices = G.GAME.pack_choices - 1
			  else
				  G.CONTROLLER.interrupt.focus = true
					G.ARGS.is_oddity_booster = false
				  G.FUNCS.end_consumeable(nil, delay_fac)
			  end
			else
			  if G.shop then 
				G.shop.alignment.offset.y = G.shop.alignment.offset.py
				G.shop.alignment.offset.py = nil
			  end
			  if G.blind_select then
				G.blind_select.alignment.offset.y = G.blind_select.alignment.offset.py
				G.blind_select.alignment.offset.py = nil
			  end
			  if G.round_eval then
				G.round_eval.alignment.offset.y = G.round_eval.alignment.offset.py
				G.round_eval.alignment.offset.py = nil
			  end
			  if area and area.cards[1] then 
				G.E_MANAGER:add_event(Event({func = function()
				  G.E_MANAGER:add_event(Event({func = function()
					G.CONTROLLER.interrupt.focus = nil
					if card.ability.set == 'Voucher' then 
					  G.CONTROLLER:snap_to({node = G.shop:get_UIE_by_ID('next_round_button')})
					elseif area then
					  G.CONTROLLER:recall_cardarea_focus(area)
					end
				  return true end }))
				return true end }))
			  end
			end
		return true
	  end}))
	return true
  end}))
end

function SMODS.INIT.OddityAPI()
    -- localization stuff
	G.localization.descriptions["Oddity"] = {}
	G.localization.misc.labels["oddity"] = "Oddity"
	G.localization.misc.dictionary["k_oddity"] = "Oddity"
	G.C.SECONDARY_SET.Oddity = HEX("826390")
	loc_colour("mult", nil)
	G.ARGS.LOC_COLOURS["oddity"] = G.C.SECONDARY_SET.Oddity
	G.localization.descriptions["Other"]["o_undiscovered"] = {
		name = "Not Discovered",
		text = {
			"Purchase or use",
			"this oddity in an",
			"unseeded run to",
			"learn what it does"
		}
	}
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

    local mod_id = 'OddityAPI'
    local this_mod = SMODS.findModByID(mod_id)
	G.P_CENTER_POOLS['Oddity'] = {}
	
	SMODS.Sprite:new("Oddity", this_mod.path, "Oddity.png", 71, 95, "asset_atli"):register();
	G.o_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=0,y=0}, set = "Oddity", cost_mult = 1.0, config = {}}
	--SMODS.Booster:new("Oddity Pack", "oddity_normal_1", {extra = 3, choose = 1}, { x = 1, y = 0 }, 4, false, 1, "Celestial", "Oddity"):register()
	do
		local minId = table_length(G.P_CENTER_POOLS['Booster']) + 1
		local id = 0
		local i = 0
		i = i + 1
		-- Prepare some Datas
		id = i + minId

		local booster_objs = {
			{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_1", pos = {x = 1, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_2", pos = {x = 2, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_3", pos = {x = 3, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Oddity Pack", set = "Booster", order = id, key = "p_oddity_normal_4", pos = {x = 4, y = 0}, cost = 4, config = {extra = 3, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Jumbo Oddity Pack", set = "Booster", order = id, key = "p_oddity_jumbo_1", pos = {x = 1, y = 1}, cost = 6, config = {extra = 5, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Jumbo Oddity Pack", set = "Booster", order = id, key = "p_oddity_jumbo_2", pos = {x = 2, y = 1}, cost = 6, config = {extra = 5, choose = 1}, weight = 1, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Mega Oddity Pack", set = "Booster", order = id, key = "p_oddity_mega_1", pos = {x = 3, y = 1}, cost = 8, config = {extra = 5, choose = 2}, weight = 0.25, kind = "Celestial",atlas = "Oddity"},
			{discovered = true, name = "Mega Oddity Pack", set = "Booster", order = id, key = "p_oddity_mega_2", pos = {x = 4, y = 1}, cost = 8, config = {extra = 5, choose = 2}, weight = 0.25, kind = "Celestial",atlas = "Oddity"},
		}
		for _, v in ipairs(booster_objs) do
			G.P_CENTERS[v.key] = v
			table.insert(G.P_CENTER_POOLS['Booster'], v)

			sendDebugMessage("The Booster named " .. v.name .. " with the slug " .. v.key .. " have been registered at the id " .. id .. ".")
			id = id + 1
		end
	end
	local alias__create_card_for_shop = create_card_for_shop;
	function create_card_for_shop(area)
		if not (G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.forced_shop) then
			--
			local forced_tag = nil
			for k, v in ipairs(G.GAME.tags) do
			  if not forced_tag then
				forced_tag = v:apply_to_run({type = 'store_joker_create', area = area})
				if forced_tag then
				  for kk, vv in ipairs(G.GAME.tags) do
					if vv:apply_to_run({type = 'store_joker_modify', card = forced_tag}) then break end
				  end
				  return forced_tag end
			  end
			end
			--
			G.GAME.spectral_rate = G.GAME.spectral_rate or 0
			local total_rate = G.GAME.joker_rate + G.GAME.tarot_rate + G.GAME.planet_rate + G.GAME.playing_card_rate + G.GAME.spectral_rate + G.GAME.oddity_rate
			local polled_rate = pseudorandom(pseudoseed('odditycdt'..G.GAME.round_resets.ante))*total_rate
			if polled_rate < G.GAME.oddity_rate then
				local card = create_card("Oddity", area, nil, nil, nil, nil, nil, 'sho')
				create_shop_card_ui(card, "Oddity", area)
				return card
			else
				return alias__create_card_for_shop(area)
			end
		else
			return alias__create_card_for_shop(area)
		end
	end
end

----------------------------------------------
------------MOD CODE END----------------------