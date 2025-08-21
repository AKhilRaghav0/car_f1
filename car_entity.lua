-- Enhanced car entity for car_f1 mod with advanced physics
-- Main car entity with suspension, tire physics, aerodynamics, and damage systems

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")
local physics = dofile(minetest.get_modpath("car_f1") .. "/physics.lua")
local controls = dofile(minetest.get_modpath("car_f1") .. "/controls.lua")
local audio = dofile(minetest.get_modpath("car_f1") .. "/audio.lua")

-- Enhanced F1 Car Entity
local car_f1 = {
    physical = true,
    collisionbox = config.COLLISION_BOX,
    visual = "mesh",
    visual_size = config.CAR_SCALE,
    mesh = "hawk_f1.x",
    textures = {"car_f11.png"},
    
    -- Driver and control state
    driver = nil,
    v = 0, -- velocity
    r = 0, -- turn direction (legacy)
    f = 0, -- turn factor (legacy)
    timer = 0,
    mouselook = true,
    
    -- Enhanced features
    fuel = 100, -- fuel level (0-100)
    damage = 0, -- damage level (0-100)
    engine_running = false,
    lights_on = false,
    horn_cooldown = 0,
    
    -- Advanced physics properties
    mass = 1000, -- kg
    tire_wear = 1.0, -- 0.1 to 1.0
    performance_multiplier = 1.0, -- 0.3 to 1.0
    current_gear = 1,
    engine_rpm = 4000,
    clutch_pedal = 1.0,
    
    -- Suspension system
    suspension_velocity = 0,
    suspension_compression = 0,
    
    -- Component damage system
    component_damage = {},
    
    -- Wheel loads for weight transfer
    wheel_loads = {},
    
    -- Weather and environmental
    weather_condition = "clear",
    surface_type = "default:stone",
    surface_traction = 1.0,
    visibility_reduction = 0,
    wind_strength = 0,
    
    -- Control inputs
    throttle_input = 0,
    brake_input = 0,
    steering_input = 0,
    clutch_input = 0,
    
    -- Audio handles
    engine_sound_handle = nil,
    enter_sound = "car_f1_enter",
    exit_sound = "car_f1_exit",
    crash_sound = "car_f1_crash",
    
    -- Physics state
    last_pos = nil,
    last_velocity = nil,
    on_ground = true,
    
    -- Advanced features
    manual_transmission = false, -- Set to true for manual shifting
    driving_assistance = true, -- ABS, TCS, ESC
    weather_simulation = true, -- Dynamic weather effects
}

-- Handle right-click to enter/exit car
function car_f1:on_rightclick(clicker)
    if not clicker or not clicker:is_player() then 
        return 
    end
    
    if not self.driver then
        -- Try to enter car
        local can_enter, message = controls.can_enter_car(self, clicker)
        if can_enter then
            if controls.enter_car(self, clicker) then
                audio.play_enter_sound(self)
                self.engine_running = true
                audio.update_engine_sound(self)
                
                -- Show welcome message with controls
                minetest.chat_send_player(clicker:get_player_name(), 
                    "Welcome to your F1 car! Use WASD to drive, Space for mouse look, Shift for clutch.")
            end
        else
            -- Show message to player
            minetest.chat_send_player(clicker:get_player_name(), "Cannot enter car: " .. message)
        end
    elseif clicker == self.driver then
        -- Exit car
        if controls.exit_car(self, clicker) then
            audio.play_exit_sound(self)
            self.engine_running = false
            audio.stop_engine_sound(self)
        end
    end
end

-- Handle car activation
function car_f1:on_activate(staticdata, dtime_s)
    self.object:set_armor_groups({immortal = 1})
    
    -- Restore saved state
    if staticdata then
        local data = minetest.deserialize(staticdata)
        if data then
            self.v = data.v or 0
            self.fuel = data.fuel or 100
            self.damage = data.damage or 0
            self.engine_running = data.engine_running or false
            self.tire_wear = data.tire_wear or 1.0
            self.performance_multiplier = data.performance_multiplier or 1.0
            self.component_damage = data.component_damage or {}
            self.current_gear = data.current_gear or 1
            self.weather_condition = data.weather_condition or "clear"
        end
    end
    
    -- Initialize advanced physics
    physics.initialize_car_physics(self)
    
    -- Initialize physics
    self.last_pos = self.object:get_pos()
    self.last_velocity = self.object:get_velocity()
    
    -- Set initial surface type
    local ground_node = minetest.get_node({x = self.last_pos.x, y = self.last_pos.y - 1, z = self.last_pos.z})
    self.surface_type = ground_node.name
end

-- Save car state
function car_f1:get_staticdata()
    local data = {
        v = self.v,
        fuel = self.fuel,
        damage = self.damage,
        engine_running = self.engine_running,
        tire_wear = self.tire_wear,
        performance_multiplier = self.performance_multiplier,
        component_damage = self.component_damage,
        current_gear = self.current_gear,
        weather_condition = self.weather_condition
    }
    return minetest.serialize(data)
end

-- Handle car destruction with advanced collision
function car_f1:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    -- Calculate impact force
    local impact_force = 0
    if self.last_velocity then
        local current_velocity = self.object:get_velocity()
        impact_force = vector.distance(self.last_velocity, current_velocity)
    end
    
    -- Handle crash effects with advanced collision system
    if impact_force > 2 then
        controls.handle_crash(self, impact_force)
        
        -- Calculate total component damage
        local total_damage = 0
        for _, damage in pairs(self.component_damage or {}) do
            total_damage = total_damage + damage
        end
        
        -- Destroy car if too damaged
        if total_damage >= 100 then
            self.object:remove()
            if puncher and puncher:is_player() then
                puncher:get_inventory():add_item("main", "car_f1:car_f1")
                if puncher == self.driver then
                    controls.exit_car(self, puncher)
                end
            end
            return
        end
    end
    
    -- Normal punch behavior
    if puncher and puncher:is_player() then
        self.object:remove()
        puncher:get_inventory():add_item("main", "car_f1:car_f1")
        if puncher == self.driver then
            controls.exit_car(self, puncher)
        end
    end
end

-- Main physics and control update with advanced systems
function car_f1:on_step(dtime)
    -- Update timer
    self.timer = (self.timer + dtime) % 2
    
    -- Store previous state for physics calculations
    self.last_pos = self.object:get_pos()
    self.last_velocity = self.object:get_velocity()
    
    -- Update surface type detection
    local ground_node = minetest.get_node({x = self.last_pos.x, y = self.last_pos.y - 1, z = self.last_pos.z})
    self.surface_type = ground_node.name
    
    -- Process player controls with advanced physics
    controls.process_controls(self, dtime)
    
    -- Update suspension system
    physics.update_suspension(self, dtime)
    
    -- Apply driving assistance systems
    if self.driving_assistance then
        controls.apply_driving_assistance(self, dtime)
    end
    
    -- Handle manual gear shifting
    if self.manual_transmission and self.driver then
        controls.handle_gear_shifting(self, self.driver)
    end
    
    -- Update audio
    if self.engine_running then
        audio.update_engine_sound(self)
        audio.update_3d_audio(self)
    end
    
    -- Update driver view with physics feedback
    controls.update_driver_view(self)
    
    -- Handle fuel consumption
    if self.engine_running and math.abs(self.v) > 0.1 then
        local fuel_consumption = dtime * 0.1 * (1 + math.abs(self.throttle_input) * 0.5)
        self.fuel = math.max(0, self.fuel - fuel_consumption)
        
        if self.fuel <= 0 then
            self.engine_running = false
            audio.stop_engine_sound(self)
            if self.driver then
                minetest.chat_send_player(self.driver:get_player_name(), "Car is out of fuel!")
            end
        end
    end
    
    -- Handle horn cooldown
    if self.horn_cooldown > 0 then
        self.horn_cooldown = self.horn_cooldown - dtime
    end
    
    -- Check for collisions ahead
    local collision_ahead, collision_pos = physics.check_collision_ahead(
        self.object:get_pos(), 
        self.object:get_yaw(), 
        3
    )
    
    if collision_ahead and math.abs(self.v) > 5 then
        -- Apply emergency braking
        self.brake_input = math.min(1.0, self.brake_input + 0.3)
        audio.play_tire_screech(self, 0.8)
    end
    
    -- Update weather effects
    if self.weather_simulation then
        -- Simulate dynamic weather changes (simplified)
        if self.timer < 0.1 and math.random() < 0.01 then
            local weather_types = {"clear", "rain", "snow"}
            local new_weather = weather_types[math.random(1, #weather_types)]
            controls.set_weather_condition(self, new_weather)
        end
    end
    
    -- Performance monitoring
    if self.driver and self.timer < 0.1 then
        -- Show performance info every 2 seconds
        local speed_kmh = math.floor(math.abs(self.v) * 36)
        if speed_kmh > 10 then -- Only show when moving
            minetest.chat_send_player(self.driver:get_player_name(), 
                string.format("Speed: %d km/h | Gear: %s | RPM: %d | Fuel: %d%% | Damage: %.1f%%", 
                speed_kmh, 
                physics.transmission.gears[self.current_gear].name,
                self.engine_rpm,
                math.floor(self.fuel),
                self.performance_multiplier * 100))
        end
    end
end

-- Update car physics with advanced systems
function car_f1:update_physics(dtime)
    local p = self.object:get_pos()
    local a = self.object:get_yaw()
    
    -- Calculate new position
    local nx = p.x + math.cos(a) * physics.get_sign(self.v)
    local nz = p.z + math.sin(a) * math.sin(a) * physics.get_sign(self.v)
    
    -- Check ground nodes
    local n1 = minetest.get_node({x = nx, y = p.y - 0.5, z = nz})
    local n2 = minetest.get_node({x = nx, y = p.y + 0.5, z = nz})
    
    -- Get surface type and friction
    local ground_node = minetest.get_node({x = p.x, y = p.y - 1, z = p.z})
    self.surface_type = ground_node.name
    local surface_friction = physics.get_surface_friction(self.surface_type)
    
    -- Apply surface-based retardation with advanced physics
    local s = physics.get_sign(self.v)
    local m = config.SURFACE_MULTIPLIER * surface_friction * self.surface_traction
    
    self.v = (math.abs(self.v) < config.MIN_SPEED_THRESHOLD) and 0 or 
              self.v - config.RETARDATION / 10 * s * m
    
    -- Apply speed limits based on surface and performance
    local max_speed = (physics.get_sign(self.v) >= 0) and 
                      config.MAX_SPEED_FORWARD / m or 
                      config.MAX_SPEED_REVERSE / m
    
    -- Apply performance multiplier to speed limits
    max_speed = max_speed * self.performance_multiplier
    
    if math.abs(self.v) > max_speed then 
        self.v = self.v - physics.get_sign(self.v) 
    end
    
    -- Calculate slope effects with advanced physics
    local slope_angle, slope_factor = physics.check_slope(p, a)
    local slope_acceleration = physics.calculate_acceleration(p, a, self.v, surface_friction)
    
    -- Update position and velocity
    self.object:set_pos({x = p.x, y = p.y, z = p.z})
    local new_velocity = physics.get_new_velocity(self.v, a, self.object:get_velocity().y, self.r, self.f)
    
    -- Apply slope acceleration
    new_velocity.y = new_velocity.y + slope_acceleration
    
    -- Apply suspension effects to velocity
    if self.suspension_compression then
        new_velocity.y = new_velocity.y + self.suspension_compression * 0.1
    end
    
    self.object:set_velocity(new_velocity)
    
    -- Handle ground collision and gravity with suspension
    if n1.name ~= "air" and minetest.registered_nodes[n1.name].walkable and n2.name == "air" then
        -- Suspension handles most of the ground interaction
        self.on_ground = true
    else
        self.object:set_acceleration({x = 0, y = config.GRAVITY, z = 0})
        self.on_ground = false
    end
end

-- Handle car removal
function car_f1:on_remove()
    -- Clean up audio
    audio.cleanup(self)
    
    -- Detach driver if present
    if self.driver then
        controls.exit_car(self, self.driver)
    end
end

-- Advanced car functions
function car_f1:toggle_lights()
    self.lights_on = not self.lights_on
    if self.driver then
        local status = self.lights_on and "ON" or "OFF"
        minetest.chat_send_player(self.driver:get_player_name(), "Lights: " .. status)
    end
end

function car_f1:honk_horn()
    if self.horn_cooldown <= 0 then
        audio.play_horn(self)
        self.horn_cooldown = 1.0 -- 1 second cooldown
    end
end

function car_f1:show_diagnostics()
    if self.driver then
        controls.show_car_diagnostics(self, self.driver)
    end
end

-- Register the enhanced entity
minetest.register_entity("car_f1:car_f1", car_f1)

return car_f1