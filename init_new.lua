-- Enhanced car_f1 mod - Main initialization file with advanced physics
-- This mod provides an F1 racing car with professional-grade physics simulation

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
    minetest.log("info", "[car_f1] Enhanced F1 Car mod initialized successfully!")
    minetest.log("info", "[car_f1] Advanced physics features: Suspension, Tire Physics, Aerodynamics, Weight Transfer")
    minetest.log("info", "[car_f1] Driving assistance: ABS, TCS, ESC systems")
    minetest.log("info", "[car_f1] Weather simulation and damage system")
end

-- Register on_mods_loaded to ensure all dependencies are available
minetest.register_on_mods_loaded(function()
    init_mod()
end)

-- Enhanced chat commands for testing and debugging advanced physics
minetest.register_chatcommand("car_info", {
    description = "Show information about the enhanced F1 car mod",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        minetest.chat_send_player(name, "=== Enhanced F1 Car Mod v2.0 ===")
        minetest.chat_send_player(name, "🚗 Advanced Physics Features:")
        minetest.chat_send_player(name, "  • Realistic suspension system")
        minetest.chat_send_player(name, "  • Advanced tire physics & traction")
        minetest.chat_send_player(name, "  • Weight transfer simulation")
        minetest.chat_send_player(name, "  • Aerodynamics & downforce")
        minetest.chat_send_player(name, "  • 6-speed transmission")
        minetest.chat_send_player(name, "")
        minetest.chat_send_player(name, "🎮 Enhanced Controls:")
        minetest.chat_send_player(name, "  • WASD: Drive and turn")
        minetest.chat_send_player(name, "  • Space: Toggle mouse look")
        minetest.chat_send_player(name, "  • Shift: Clutch control")
        minetest.chat_send_player(name, "  • Right-click: Enter/exit car")
        minetest.chat_send_player(name, "")
        minetest.chat_send_player(name, "🔧 Advanced Systems:")
        minetest.chat_send_player(name, "  • ABS (Anti-lock Braking)")
        minetest.chat_send_player(name, "  • TCS (Traction Control)")
        minetest.chat_send_player(name, "  • ESC (Stability Control)")
        minetest.chat_send_player(name, "  • Weather effects")
        minetest.chat_send_player(name, "  • Component damage system")
        
        return true, "Enhanced mod information displayed"
    end
})

minetest.register_chatcommand("car_spawn", {
    description = "Spawn an enhanced F1 car at your position",
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
            
            return true, "Enhanced F1 car spawned successfully!"
        else
            return false, "Failed to spawn car"
        end
    end
})

-- New command for car diagnostics
minetest.register_chatcommand("car_diagnostics", {
    description = "Show detailed car diagnostics and physics data",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local attached_to = player:get_attach()
        if not attached_to then
            return false, "You must be in a car to use this command"
        end
        
        local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
        for _, obj in ipairs(car_entity) do
            if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                local car = obj:get_luaentity()
                controls.show_car_diagnostics(car, player)
                return true, "Car diagnostics displayed"
            end
        end
        
        return false, "No car found nearby"
    end
})

-- Weather control command
minetest.register_chatcommand("car_weather", {
    description = "Change weather conditions (clear/rain/snow)",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local attached_to = player:get_attach()
        if not attached_to then
            return false, "You must be in a car to use this command"
        end
        
        local weather_type = param:lower()
        if weather_type == "" then
            return false, "Usage: /car_weather <clear|rain|snow>"
        end
        
        local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
        for _, obj in ipairs(car_entity) do
            if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                local car = obj:get_luaentity()
                local success, message = controls.set_weather_condition(car, weather_type)
                return success, message
            end
        end
        
        return false, "No car found nearby"
    end
})

-- Physics testing command
minetest.register_chatcommand("car_physics", {
    description = "Test advanced physics features",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local attached_to = player:get_attach()
        if not attached_to then
            return false, "You must be in a car to use this command"
        end
        
        local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
        for _, obj in ipairs(car_entity) do
            if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                local car = obj:get_luaentity()
                
                -- Test suspension
                car.suspension_compression = 0.2
                minetest.chat_send_player(name, "Testing suspension system...")
                
                -- Test tire wear
                car.tire_wear = 0.5
                minetest.chat_send_player(name, "Testing tire wear effects...")
                
                -- Test damage system
                car.component_damage = {front_bumper = 25, hood = 15}
                physics.apply_damage_effects(car)
                minetest.chat_send_player(name, "Testing damage system...")
                
                return true, "Physics tests applied to car"
            end
        end
        
        return false, "No car found nearby"
    end
})

-- Performance testing command
minetest.register_chatcommand("car_performance", {
    description = "Test car performance and handling",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local attached_to = player:get_attach()
        if not attached_to then
            return false, "You must be in a car to use this command"
        end
        
        local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
        for _, obj in ipairs(car_entity) do
            if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                local car = obj:get_luaentity()
                
                -- Test different performance levels
                if param == "max" then
                    car.performance_multiplier = 1.0
                    car.tire_wear = 1.0
                    car.fuel = 100
                    minetest.chat_send_player(name, "Car set to maximum performance!")
                elseif param == "min" then
                    car.performance_multiplier = 0.3
                    car.tire_wear = 0.1
                    car.fuel = 10
                    minetest.chat_send_player(name, "Car set to minimum performance!")
                else
                    car.performance_multiplier = 0.7
                    car.tire_wear = 0.6
                    car.fuel = 50
                    minetest.chat_send_player(name, "Car set to medium performance!")
                end
                
                return true, "Performance test completed"
            end
        end
        
        return false, "No car found nearby"
    end
})

-- Enhanced HUD elements for car information
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
                
                -- Show enhanced car stats in chat
                if car.timer < 0.1 then -- Update every 2 seconds
                    local speed = math.abs(car.v or 0)
                    local speed_kmh = math.floor(speed * 36) -- Convert to km/h
                    local gear_name = physics.transmission.gears[car.current_gear or 1].name
                    
                    minetest.chat_send_player(player:get_player_name(), 
                        string.format("🏎️ Speed: %d km/h | Gear: %s | RPM: %d | Fuel: %d%% | Damage: %.1f%% | Tires: %.1f%%", 
                        speed_kmh, gear_name, car.engine_rpm or 0, 
                        math.floor(car.fuel), car.performance_multiplier * 100, car.tire_wear * 100))
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

-- Enhanced particle effects for advanced physics
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
    
    -- Tire smoke when turning sharply or braking hard
    local driving_intensity = math.abs(car.steering_input or 0) + math.abs(car.brake_input or 0)
    if driving_intensity > 0.4 and speed > 2 then
        local tire_pos = {
            x = pos.x + math.cos(car.object:get_yaw() + math.pi/2) * 1.0,
            y = pos.y + 0.1,
            z = pos.z + math.sin(car.object:get_yaw() + math.pi/2) * 1.0
        }
        
        minetest.add_particlespawner({
            amount = math.floor(driving_intensity * 8),
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
    
    -- Suspension particles when suspension is compressed
    if car.suspension_compression and math.abs(car.suspension_compression) > 0.1 then
        local suspension_pos = {
            x = pos.x,
            y = pos.y - 0.5,
            z = pos.z
        }
        
        minetest.add_particlespawner({
            amount = 2,
            time = 0.2,
            minpos = suspension_pos,
            maxpos = suspension_pos,
            minvel = {x = -0.1, y = 0.1, z = -0.1},
            maxvel = {x = 0.1, y = 0.3, z = 0.1},
            minacc = {x = 0, y = 0.02, z = 0},
            maxacc = {x = 0, y = 0.05, z = 0},
            minexptime = 0.3,
            maxexptime = 0.8,
            minsize = 0.2,
            maxsize = 0.5,
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
        surface_type = car.surface_type,
        -- Advanced physics data
        tire_wear = car.tire_wear or 1.0,
        performance_multiplier = car.performance_multiplier or 1.0,
        current_gear = car.current_gear or 1,
        engine_rpm = car.engine_rpm or 4000,
        suspension_compression = car.suspension_compression or 0,
        weather_condition = car.weather_condition or "clear",
        component_damage = car.component_damage or {}
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

-- Function to test advanced physics
function car_f1.api.test_physics(car_entity, test_type)
    if not car_entity or car_entity.name ~= "car_f1:car_f1" then
        return false
    end
    
    local car = car_entity:get_luaentity()
    if not car then
        return false
    end
    
    if test_type == "suspension" then
        car.suspension_compression = 0.3
        return true, "Suspension test applied"
    elseif test_type == "tires" then
        car.tire_wear = 0.2
        return true, "Tire wear test applied"
    elseif test_type == "damage" then
        car.component_damage = {front_bumper = 30, hood = 20}
        physics.apply_damage_effects(car)
        return true, "Damage test applied"
    end
    
    return false, "Unknown test type"
end

-- Log successful loading
minetest.log("info", "[car_f1] Enhanced F1 Car mod with advanced physics loaded successfully!")
minetest.log("info", "[car_f1] New commands: /car_diagnostics, /car_weather, /car_physics, /car_performance")
minetest.log("info", "[car_f1] Advanced physics: Suspension, Tire Physics, Aerodynamics, Weight Transfer")
minetest.log("info", "[car_f1] Driving assistance: ABS, TCS, ESC systems active")