-- Enhanced car entity for car_f1 mod
-- Main car entity with improved physics, audio, and controls

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
    r = 0, -- turn direction
    f = 0, -- turn factor
    timer = 0,
    mouselook = true,
    
    -- Enhanced features
    fuel = 100, -- fuel level (0-100)
    damage = 0, -- damage level (0-100)
    engine_running = false,
    lights_on = false,
    horn_cooldown = 0,
    
    -- Audio handles
    engine_sound_handle = nil,
    enter_sound = "car_f1_enter",
    exit_sound = "car_f1_exit",
    crash_sound = "car_f1_crash",
    
    -- Physics state
    last_pos = nil,
    last_velocity = nil,
    on_ground = true,
    surface_type = "default:stone"
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
        end
    end
    
    -- Initialize physics
    self.last_pos = self.object:get_pos()
    self.last_velocity = self.object:get_velocity()
end

-- Save car state
function car_f1:get_staticdata()
    local data = {
        v = self.v,
        fuel = self.fuel,
        damage = self.damage,
        engine_running = self.engine_running
    }
    return minetest.serialize(data)
end

-- Handle car destruction
function car_f1:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    -- Calculate impact force
    local impact_force = 0
    if self.last_velocity then
        local current_velocity = self.object:get_velocity()
        impact_force = vector.distance(self.last_velocity, current_velocity)
    end
    
    -- Handle crash effects
    if impact_force > 2 then
        controls.handle_crash(self, impact_force)
        audio.play_crash_sound(self, impact_force)
        
        -- Apply damage
        self.damage = math.min(100, self.damage + impact_force * 2)
        
        -- Destroy car if too damaged
        if self.damage >= 100 then
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

-- Main physics and control update
function car_f1:on_step(dtime)
    -- Update timer
    self.timer = (self.timer + dtime) % 2
    
    -- Store previous state for physics calculations
    self.last_pos = self.object:get_pos()
    self.last_velocity = self.object:get_velocity()
    
    -- Process player controls
    controls.process_controls(self, dtime)
    
    -- Update physics
    self:update_physics(dtime)
    
    -- Update audio
    if self.engine_running then
        audio.update_engine_sound(self)
        audio.update_3d_audio(self)
    end
    
    -- Update driver view
    controls.update_driver_view(self)
    
    -- Handle fuel consumption
    if self.engine_running and math.abs(self.v) > 0.1 then
        self.fuel = math.max(0, self.fuel - dtime * 0.1)
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
        self.v = self.v * 0.8
        audio.play_tire_screech(self, 0.8)
    end
end

-- Update car physics
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
    
    -- Apply surface-based retardation
    local s = physics.get_sign(self.v)
    local m = config.SURFACE_MULTIPLIER * surface_friction
    
    self.v = (math.abs(self.v) < config.MIN_SPEED_THRESHOLD) and 0 or 
              self.v - config.RETARDATION / 10 * s * m
    
    -- Apply speed limits based on surface
    local max_speed = (physics.get_sign(self.v) >= 0) and 
                      config.MAX_SPEED_FORWARD / m or 
                      config.MAX_SPEED_REVERSE / m
    
    if math.abs(self.v) > max_speed then 
        self.v = self.v - physics.get_sign(self.v) 
    end
    
    -- Calculate slope effects
    local slope_angle, slope_factor = physics.check_slope(p, a)
    local slope_acceleration = physics.calculate_acceleration(p, a, self.v, surface_friction)
    
    -- Update position and velocity
    self.object:set_pos({x = p.x, y = p.y, z = p.z})
    local new_velocity = physics.get_new_velocity(self.v, a, self.object:get_velocity().y, self.r, self.f)
    
    -- Apply slope acceleration
    new_velocity.y = new_velocity.y + slope_acceleration
    
    self.object:set_velocity(new_velocity)
    
    -- Handle ground collision and gravity
    if n1.name ~= "air" and minetest.registered_nodes[n1.name].walkable and n2.name == "air" then
        self.object:set_acceleration({x = 0, y = config.JUMP_ACCELERATION, z = 0})
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

-- Register the enhanced entity
minetest.register_entity("car_f1:car_f1", car_f1)

return car_f1