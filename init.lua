local thismod = minetest.get_current_modname()
local modpath = minetest.get_modpath(thismod)


-- Global
leash = {}
leash.leashes = {}
leash.leashed_entities = {}
leash.leashed_playernames = {}

-- Leash object prototype
leash.proto = {}
local proto = leash.proto

proto.entity_ref = ""
proto.origin = {x = 0, y = 100, z = 0}
proto.limits = {}
proto.buffer_distance = 0.01
proto.show_effect = true
proto.effect = {}
proto.hud_def = {
    hud_elem_type = "image",
    position = {x = 0, y = 0},
    name = "leash_hud",
    scale = {x = 2, y = 2},
    number = 1,
    z_index = -302,
    size = {x = 100, y = 100},
    text = "lens.png"
}

function proto:new(def) -- Creates new leash object and places reference in global leash table
    def = def or {}
    setmetatable(def, proto)
    proto.__index = self
    local num = #leash.leashes
    def.id = num
    leash.leashes[num+1] = def
end

function proto:get_entity()
    local ref = self.entity_ref
    if(type(ref) == "string")then
        return minetest.get_player_by_name(ref)
    elseif(type(ref) == "table")then
        return ref:get_pos() and ref or nil
    end
end

function proto:check_pos()
    local ent = self:get_entity()
    return ent and ent:get_pos()
end

function proto:is_trespassing()
    local pos = self:check_pos()
    local origin = self.origin
    local limit = self.limits
    local magsort = function(n,n2)
        local sorted = {n > n2 and n or n2}
        sorted[2] = n == sorted[1] and n2 or n -- First entry always higher, second entry always lower
        return sorted
    end

    local dist = {}
    for k,v in pairs(limit) do

        local origin_axis_value = origin[k]
        local position_axis_value = pos[k]

        if(origin_axis_value and position_axis_value)then

            local oav, pav = origin_axis_value, position_axis_value
            local vals = magsort(oav,pav)
            local axis_dist = vals[1] - vals[2]

            if(axis_dist > math.abs(limit[k]))then
                return k
            end
        end
    end
end

function proto:restrain(axis)
    local ent = self:get_entity()
    local ori = self.origin[axis]

    local pos = self:check_pos()
    local lim = self.limits[axis]
    local pt = pos[axis]

    local dist = math.abs(pt)-math.abs(lim)
    local is_pos = pt > lim
    local offset = lim-self.buffer_distance

    pos[axis] = is_pos and ori + offset or ori - offset
    
    ent:set_pos(pos)
end

-- HUD STUFF
dofile(modpath .. "/hud.lua")


minetest.register_on_joinplayer(function(ObjectRef, last_login)
    local name = ObjectRef:get_player_name()
    local g = {}
    g.entity_ref = name
    g.limits = {x = 50, y = 50, z = 50}
    proto:new(g)
end)

leash.process_leashes = function()
    local leashes = leash.leashes
    for n = 1, #leashes do
        local leash = leashes[n]
        local is_trespassing = leash:is_trespassing()
        if(is_trespassing)then
            leash:restrain(is_trespassing)
        end
        leash:say_diff()
        leash:hud_update()
    end
end

minetest.register_globalstep(function(dtime)
    leash.process_leashes()
end)
