-- Enhanced car_f1 mod - Main initialization file
-- This mod provides an F1 racing car with improved physics, audio, and features

-- Load configuration
local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

-- Load modules
local physics = dofile(minetest.get_modpath("car_f1") .. "/physics.lua")
local controls = dofile(minetest.get_modpath("car_f1") .. "/controls.lua")
local audio = dofile(minetest.get_modpath("car_f1") .. "/audio.lua")
local car_entity = dofile(minetest.get_modpath("car_f1") .. "/car_entity.lua")
local crafting = dofile(minetest.get_modpath("car_f1") .. "/crafting.lua")

-- Initialize the mod
local function init_mod()
    -- Initialize audio system
    audio.init()
    
    -- Register all crafting recipes and items
    crafting.register_all()
    
    -- Log successful initialization
    minetest.log("info", "[car_f1] F1 Car mod initialized successfully!")
    minetest.log("info", "[car_f1] Features: Enhanced physics, 3D audio, fuel system, damage system")
end

-- Register on_mods_loaded to ensure all dependencies are available
minetest.register_on_mods_loaded(function()
    init_mod()
end)

-- Add chat commands for testing and debugging
minetest.register_chatcommand("car_info", {
    description = "Show information about the F1 car mod",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        minetest.chat_send_player(name, "=== F1 Car Mod Information ===")
        minetest.chat_system(name, "Version: 2.0 Enhanced")
        minetest.chat_system(name, "Features:")
        minetest.chat_system(name, "- Enhanced physics with slope handling")
        minetest.chat_system(name, "- 3D positional audio (4 node radius)")
        minetest.chat_system(name, "- Fuel system and damage system")
        minetest.chat_system(name, "- Improved collision detection")
        minetest.chat_system(name, "- Better player controls and camera")
        minetest.chat_system(name, "")
        minetest.chat_system(name, "Controls:")
        minetest.chat_system(name, "- WASD: Drive and turn")
        minetest.chat_system(name, "- Space: Toggle mouse look")
        minetest.chat_system(name, "- Shift: Handbrake")
        minetest.chat_system(name, "- Right-click: Enter/exit car")
        
        return true, "Information displayed in chat"
    end
})

minetest.register_chatcommand("car_spawn", {
    description = "Spawn an F1 car at your position",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local pos = player:get_pos()
        pos.y = pos.y + 1
        
        local car = minetest.add_entity(pos, "car_f1:car_f1")
        if car then
            -- Orient car towards player's look direction
            local yaw = player:get_look_horizontal()
            car:set_yaw(yaw)
            
            return true, "F1 car spawned successfully!"
        else
            return false, "Failed to spawn car"
        end
    end
})

-- Add HUD elements for car information
local function update_car_hud(player)
    if not player or not player:is_player() then
        return
    end
    
    local attached_to = player:get_attach()
    if attached_to then
        local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
        for _, obj in ipairs(car_entity) do
            if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                local car = obj:get_luaentity()
                
                -- Show car stats in chat (you could enhance this with proper HUD)
                if car.timer < 0.1 then -- Update every 2 seconds
                    local speed = math.abs(car.v or 0)
                    local speed_kmh = math.floor(speed * 36) -- Convert to km/h
                    
                    minetest.chat_send_player(player:get_player_name(), 
                        string.format("Speed: %d km/h | Fuel: %d%% | Damage: %d%%", 
                        speed_kmh, math.floor(car.fuel), math.floor(car.damage)))
                end
                break
            end
        end
    end
end

-- Register HUD update timer
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        update_car_hud(player)
    end
end)

-- Add particle effects for enhanced visuals
local function create_car_particles(car)
    if not car or not car.object then
        return
    end
    
    local pos = car.object:get_pos()
    local speed = math.abs(car.v or 0)
    
    -- Exhaust particles when engine is running
    if car.engine_running and speed > 0.1 then
        local exhaust_pos = {
            x = pos.x - math.cos(car.object:get_yaw()) * 1.5,
            y = pos.y + 0.3,
            z = pos.z - math.sin(car.object:get_yaw()) * 1.5
        }
        
        minetest.add_particlespawner({
            amount = 5,
            time = 0.5,
            minpos = exhaust_pos,
            maxpos = exhaust_pos,
            minvel = {x = -0.5, y = 0.5, z = -0.5},
            maxvel = {x = 0.5, y = 1.0, z = 0.5},
            minacc = {x = 0, y = 0.1, z = 0},
            maxacc = {x = 0, y = 0.2, z = 0},
            minexptime = 1,
            maxexptime = 2,
            minsize = 0.5,
            maxsize = 1.0,
            collisiondetection = false,
            texture = "default_smoke.png"
        })
    end
    
    -- Tire smoke when turning sharply
    if car.f and car.f > 0.4 and speed > 2 then
        local tire_pos = {
            x = pos.x + math.cos(car.object:get_yaw() + math.pi/2) * 1.0,
            y = pos.y + 0.1,
            z = pos.z + math.sin(car.object:get_yaw() + math.pi/2) * 1.0
        }
        
        minetest.add_particlespawner({
            amount = 3,
            time = 0.3,
            minpos = tire_pos,
            maxpos = tire_pos,
            minvel = {x = -0.3, y = 0.2, z = -0.3},
            maxvel = {x = 0.3, y = 0.5, z = 0.3},
            minacc = {x = 0, y = 0.05, z = 0},
            maxacc = {x = 0, y = 0.1, z = 0},
            minexptime = 0.5,
            maxexptime = 1.0,
            minsize = 0.3,
            maxsize = 0.8,
            collisiondetection = false,
            texture = "default_smoke.png"
        })
    end
end

-- Register particle effects
minetest.register_globalstep(function(dtime)
    for _, obj in ipairs(minetest.get_objects_inside_radius({x=0, y=0, z=0}, 1000)) do
        if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
            create_car_particles(obj:get_luaentity())
        end
    end
end)

-- Add API functions for other mods
car_f1 = car_f1 or {}
car_f1.api = {}

-- Function to get car stats
function car_f1.api.get_car_stats(car_entity)
    if not car_entity or car_entity.name ~= "car_f1:car_f1" then
        return nil
    end
    
    local car = car_entity:get_luaentity()
    if not car then
        return nil
    end
    
    return {
        speed = car.v or 0,
        fuel = car.fuel or 100,
        damage = car.damage or 0,
        driver = car.driver,
        engine_running = car.engine_running,
        surface_type = car.surface_type
    }
end

-- Function to modify car properties
function car_f1.api.modify_car(car_entity, properties)
    if not car_entity or car_entity.name ~= "car_f1:car_f1" then
        return false
    end
    
    local car = car_entity:get_luaentity()
    if not car then
        return false
    end
    
    for key, value in pairs(properties) do
        if car[key] ~= nil then
            car[key] = value
        end
    end
    
    return true
end

-- Log successful loading
minetest.log("info", "[car_f1] Enhanced F1 Car mod loaded successfully!")
minetest.log("info", "[car_f1] Use /car_info for more information")