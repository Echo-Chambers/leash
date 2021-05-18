local proto = leash.proto

function proto:add_hud_indicator()
    if(not self.hud)then
        local obj = self:get_entity()
        if(obj and obj:is_player())then
            local hud_def = self.hud_def
            self.hud = obj:hud_add(hud_def)
        end
    end
end
function proto:numtrun(n)
    n = n < 1 and n or 1
    n = n > 0 and n or 0
    return n
end
function proto:hud_update()
    if(self.hud)then
        local ldir = self:compare_angles()
        ldir.y = ldir.z
        ldir.z = nil
        ldir.x = 1-self:numtrun(ldir.x + 0.5)
        ldir.y = 1-self:numtrun(ldir.y + 0.5)
        self:get_entity():hud_change(self.hud, "position", ldir)
    else self:add_hud_indicator() end
end

function proto:get_entity_dir()
    local ent_pos = self:check_pos()
    local pos = self.origin
    return ent_pos and vector.direction(ent_pos,pos)
end

function proto:compare_angles()
    local dir = self:get_entity_dir()
    if(self:get_entity())then
    local look_yaw = self:get_entity():get_look_horizontal()
    local dir_yaw = minetest.dir_to_yaw(dir)
    local desired_yaw, difference;
    if(look_yaw)then
        if(dir_yaw < 0)then
            dir_yaw = math.pi+(math.pi+dir_yaw)
        end
        --local offset = (dir_yaw >= math.pi) and math.pi or -math.pi
        desired_yaw = dir_yaw--+offset
        --dir_yaw = dir_yaw > math.pi and 
        difference = look_yaw-desired_yaw
    end
    return minetest.yaw_to_dir(difference)
end
end

function proto:say_diff()
    say(self:compare_angles())
    minetest.set_node(self.origin, {name = "littoral_tech:hal1"})
end