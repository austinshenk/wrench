local supported_nodes = {
["default:chest"] = {name="wrench:default_chest", lists={"main"}},
["default:furnace"] = {name="wrench:default_furnace", lists={"fuel", "src", "dst"}},
["default:furnace_active"] = {name="wrench:default_furnace", lists={"fuel", "src", "dst"}},
}

local function convert_to_original_name(name)
	for key,value in pairs(supported_nodes) do
		if name == value.name then return key end
	end
end

for name,_ in pairs(supported_nodes) do
	local olddef = minetest.registered_nodes[name]
	if olddef ~= nil then
		local newdef = {}
		for key,value in pairs(olddef) do
			newdef[key] = value
		end
		name = supported_nodes[name].name
		newdef.stack_max = 1
		newdef.description = newdef.description.." with items"
		newdef.groups.not_in_creative_inventory = 1
		newdef.after_place_node = function(pos, placer, itemstack)
			if olddef.after_place_node ~= nil then olddef.after_place_node(pos, placer, itemstack) end
			if not placer:is_player() then return end
			local node = minetest.get_node(pos)
			local item = convert_to_original_name(itemstack:get_name())
			minetest.set_node(pos, {name = item, param2 = node.param2})
			local inv = minetest.get_meta(pos):get_inventory()
			local data = minetest.deserialize(itemstack:get_metadata())
			for listname,list in pairs(data) do
				inv:set_list(listname, list)
			end
		end
		minetest.register_node(name, newdef)
	end
end


minetest.register_tool("wrench:wrench", {
	description = "Wrench",
	inventory_image = "wrench_wrench.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps = {
			crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
			snappy = {times={[3]=0.40}, uses=0, maxlevel=1},
			oddly_breakable_by_hand = {times={[1]=7.00,[2]=4.00,[3]=1.40}, uses=0, maxlevel=3}
		},
		damage_groups = {fleshy=1},
	},
	on_place = function(itemstack, placer, pointed_thing)
		if not placer:is_player() then return end
		local pos = pointed_thing.under
		if pos == nil then return end
		local name = minetest.get_node(pos).name
		local support = supported_nodes[name]
		if support == nil then return end
		local lists = support.lists
		local inv = minetest.get_meta(pos):get_inventory()
		local empty = true
		local list_str = {}
		for i=1,#lists,1 do
			if not inv:is_empty(lists[i]) then empty = false end
			local list = inv:get_list(lists[i])
			for j=1,#list,1 do
				list[j] = list[j]:to_string()
			end
			list_str[lists[i]] = list
		end
		inv = placer:get_inventory()
		local stack = {}
		stack.name = name
		if inv:room_for_item("main", stack) then
			minetest.remove_node(pos)
			itemstack:add_wear(65535/20)
			if empty then
				inv:add_item("main", stack)
			else
				stack.name = supported_nodes[name].name
				stack.metadata = minetest.serialize(list_str)
				inv:add_item("main", stack)
			end
		end
		return itemstack
	end,
})

minetest.register_craft({
	output = "wrench:wrench",
	recipe = {
	{"default:iron_lump","","default:iron_lump"},
	{"","default:iron_lump",""},
	{"","default:iron_lump",""},
	},
})