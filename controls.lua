-- Enhanced controls module for car_f1 mod
-- Integrates with advanced physics system for realistic driving experience

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")
local physics = dofile(minetest.get_modpath("car_f1") .. "/physics.lua")

local controls = {}

-- Handle driver entry into the car
function controls.enter_car(car, player)
    if not player or not player:is_player() then 
        return false 
    end
    
    if car.driver then
        return false -- Car already has a driver
    end
    
    -- Attach player to car
    player:set_attach(car.object, "", config.DRIVER_OFFSET, config.DRIVER_ROTATION)
    player:set_properties({
        visual_size = config.PLAYER_SCALE,
        eye_height = config.PLAYER_ATTACHED_EYE_HEIGHT
    })
    
    -- Set player state
    default.player_attached[player:get_player_name()] = true
    minetest.after(0.2, function()
        default.player_set_animation(player, config.SIT_ANIMATION, 1)
    end)
    
    -- Set car orientation to match player's look direction
    car.object:set_yaw(player:get_look_horizontal() - math.rad(270))
    car.driver = player
    
    -- Initialize advanced physics
    physics.initialize_car_physics(car)
    
    -- Play enter sound
    if car.enter_sound then
        minetest.sound_play(car.enter_sound, {
            pos = car.object:get_pos(),
            gain = 0.5,
            max_hear_distance = 10
        })
    end
    
    return true
end

-- Handle driver exit from the car
function controls.exit_car(car, player)
    if not player or player ~= car.driver then
        return false
    end
    
    -- Detach player from car
    player:set_detach()
    player:set_properties({
        visual_size = config.PLAYER_NORMAL_SCALE,
        eye_height = config.PLAYER_EYE_HEIGHT
    })
    
    -- Reset player state
    default.player_attached[player:get_player_name()] = false
    default.player_set_animation(player, config.STAND_ANIMATION, config.ANIMATION_SPEED)
    
    -- Clear driver reference
    car.driver = nil
    
    -- Play exit sound
    if car.exit_sound then
        minetest.sound_play(car.exit_sound, {
            pos = car.object:get_pos(),
            gain = 0.5,
            max_hear_distance = 10
        })
    end
    
    return true
end

-- Process player controls and update car state with advanced physics
function controls.process_controls(car, dtime)
    if not car.driver then
        return
    end
    
    local ctrl = car.driver:get_player_control()
    if not ctrl then 
        return 
    end
    
    -- Initialize control inputs
    car.throttle_input = car.throttle_input or 0
    car.brake_input = car.brake_input or 0
    car.steering_input = car.steering_input or 0
    car.clutch_input = car.clutch_input or 0
    
    -- Throttle control (W key)
    if ctrl.up then
        car.throttle_input = math.min(1.0, car.throttle_input + 0.1)
    else
        car.throttle_input = math.max(0.0, car.throttle_input - 0.05)
    end
    
    -- Brake control (S key)
    if ctrl.down then
        car.brake_input = math.min(1.0, car.brake_input + 0.15)
    else
        car.brake_input = math.max(0.0, car.brake_input - 0.1)
    end
    
    -- Steering control (A/D keys)
    if ctrl.left then
        car.steering_input = math.max(-1.0, car.steering_input - 0.1)
    elseif ctrl.right then
        car.steering_input = math.min(1.0, car.steering_input + 0.1)
    else
        -- Natural steering return to center
        car.steering_input = car.steering_input * 0.9
    end
    
    -- Clutch control (Shift key for manual mode)
    if ctrl.sneak then
        car.clutch_input = math.min(1.0, car.clutch_input + 0.2)
    else
        car.clutch_input = math.max(0.0, car.clutch_input - 0.1)
    end
    
    -- Toggle mouse look (Space key)
    if ctrl.jump then 
        car.mouselook = not car.mouselook 
    end
    
    -- Handle mouse look
    if not car.mouselook then
        car.driver:set_look_horizontal(car.object:get_yaw() - math.pi / 2)
    end
    
    -- Apply advanced physics calculations
    controls.apply_advanced_physics(car, dtime)
    
    -- Create tire marks based on driving intensity
    local driving_intensity = math.abs(car.steering_input) + math.abs(car.throttle_input) + math.abs(car.brake_input)
    if driving_intensity > 0.3 then
        physics.create_tire_marks(car, car.object:get_pos(), driving_intensity)
    end
end

-- Apply advanced physics to car movement
function controls.apply_advanced_physics(car, dtime)
    local speed = math.abs(car.v or 0)
    local surface_type = car.surface_type or "default:stone"
    
    -- Calculate tire forces
    local lateral_force, longitudinal_force = physics.calculate_tire_forces(
        car, surface_type, speed, car.steering_input, car.throttle_input, car.brake_input
    )
    
    -- Calculate weight transfer
    local wheel_loads = physics.calculate_weight_transfer(
        car, car.throttle_input, car.brake_input, car.steering_input
    )
    
    -- Calculate aerodynamic forces
    local velocity = car.object:get_velocity()
    local aero_forces = physics.calculate_aerodynamic_forces(car, velocity, speed)
    
    -- Simulate transmission
    local wheel_speed, wheel_torque = physics.simulate_transmission(
        car, car.engine_rpm or 4000, car.throttle_input, dtime
    )
    
    -- Apply forces to car
    local total_force = {
        x = lateral_force + aero_forces.x,
        y = aero_forces.y,
        z = longitudinal_force + aero_forces.z
    }
    
    -- Apply performance multiplier from damage
    local performance_mult = car.performance_multiplier or 1.0
    total_force = vector.multiply(total_force, performance_mult)
    
    -- Update car velocity
    local acceleration = vector.divide(total_force, car.mass or 1000)
    car.v = (car.v or 0) + acceleration.z * dtime
    
    -- Apply steering (with realistic physics)
    if speed > 0.1 then
        local turn_rate = car.steering_input * config.TURN_SPEED * (1 / (1 + speed * 0.1))
        car.object:set_yaw(car.object:get_yaw() + turn_rate * dtime)
    end
    
    -- Update engine RPM based on speed and gear
    car.engine_rpm = math.max(800, math.min(9000, wheel_speed * 60))
    
    -- Apply weather effects
    local weather_conditions = {
        current = car.weather_condition or "clear",
        wind_strength = car.wind_strength or 0
    }
    physics.apply_weather_effects(car, weather_conditions)
end

-- Update driver camera and view with advanced physics feedback
function controls.update_driver_view(car)
    if not car.driver or not car.driver:is_player() then
        return
    end
    
    -- Update driver position to match car movement
    local car_pos = car.object:get_pos()
    local car_yaw = car.object:get_yaw()
    
    -- Calculate driver position relative to car
    local driver_offset = {
        x = math.cos(car_yaw) * config.DRIVER_OFFSET.x - math.sin(car_yaw) * config.DRIVER_OFFSET.z,
        y = config.DRIVER_OFFSET.y,
        z = math.sin(car_yaw) * config.DRIVER_OFFSET.x + math.cos(car_yaw) * config.DRIVER_OFFSET.z
    }
    
    -- Add suspension effects to driver view
    if car.suspension_compression then
        driver_offset.y = driver_offset.y + car.suspension_compression * 0.3
    end
    
    -- Add damage effects to visibility
    if car.visibility_reduction and car.visibility_reduction > 0 then
        car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = car.visibility_reduction})
    end
    
    -- Update driver attachment
    car.driver:set_attach(car.object, "", driver_offset, config.DRIVER_ROTATION)
end

-- Check if player can enter the car
function controls.can_enter_car(car, player)
    if not player or not player:is_player() then
        return false, "Invalid player"
    end
    
    if car.driver then
        return false, "Car already has a driver"
    end
    
    -- Check if car is moving too fast
    local speed = math.sqrt(car.object:get_velocity().x^2 + car.object:get_velocity().z^2)
    if speed > 2 then
        return false, "Car is moving too fast to enter"
    end
    
    -- Check if car is too damaged
    if car.component_damage and car.component_damage.total and car.component_damage.total > 80 then
        return false, "Car is too damaged to drive"
    end
    
    return true, "OK"
end

-- Handle car damage from crashes with advanced physics
function controls.handle_crash(car, impact_force)
    if impact_force > 2 then
        -- Calculate impact velocity for advanced collision system
        local impact_velocity = car.object:get_velocity()
        local impact_point = car.object:get_pos()
        
        -- Use advanced collision system
        local damage, location = physics.handle_advanced_collision(car, impact_force, impact_point)
        
        -- Apply damage effects
        if car.driver then
            -- Shake camera based on impact force
            local shake_intensity = math.min(impact_force / 10, 0.5)
            car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
            minetest.after(0.1, function()
                if car.driver and car.driver:is_player() then
                    car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                end
            end)
            
            -- Show damage information
            if damage > 5 then
                minetest.chat_send_player(car.driver:get_player_name(), 
                    string.format("Car damaged! %s took %.1f damage", location, damage))
            end
        end
    end
end

-- Advanced driving assistance systems
function controls.apply_driving_assistance(car, dtime)
    if not car.driver then return end
    
    local speed = math.abs(car.v or 0)
    
    -- Anti-lock braking system (ABS)
    if car.brake_input > 0.8 and speed > 5 then
        local wheel_slip = math.abs(car.steering_input) * speed
        if wheel_slip > 2.0 then
            -- Reduce brake force to prevent lockup
            car.brake_input = car.brake_input * 0.7
            -- Create ABS feedback
            if car.driver then
                car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                minetest.after(0.05, function()
                    if car.driver and car.driver:is_player() then
                        car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                    end
                end)
            end
        end
    end
    
    -- Traction control system (TCS)
    if car.throttle_input > 0.7 and speed > 3 then
        local wheel_spin = car.throttle_input * speed
        if wheel_spin > 8.0 then
            -- Reduce throttle to prevent wheelspin
            car.throttle_input = car.throttle_input * 0.8
            -- Create TCS feedback
            physics.create_tire_marks(car, car.object:get_pos(), 0.8)
        end
    end
    
    -- Electronic stability control (ESC)
    if math.abs(car.steering_input) > 0.8 and speed > 10 then
        local oversteer = car.steering_input * speed
        if math.abs(oversteer) > 12.0 then
            -- Apply counter-steering correction
            local correction = -oversteer * 0.1
            car.steering_input = car.steering_input + correction
            -- Create stability control feedback
            physics.create_tire_marks(car, car.object:get_pos(), 0.6)
        end
    end
end

-- Gear shifting controls
function controls.handle_gear_shifting(car, player)
    if not car.manual_transmission then return end
    
    -- Manual gear shifting with number keys
    if player:get_player_control().aux1 then -- Number 1 key
        car.current_gear = math.max(1, car.current_gear - 1)
        car.engine_rpm = 6000
        minetest.chat_send_player(player:get_player_name(), 
            string.format("Gear: %s", physics.transmission.gears[car.current_gear].name))
    elseif player:get_player_control().aux2 then -- Number 2 key
        car.current_gear = math.min(#physics.transmission.gears, car.current_gear + 1)
        car.engine_rpm = 4000
        minetest.chat_send_player(player:get_player_name(), 
            string.format("Gear: %s", physics.transmission.gears[car.current_gear].name))
    end
end

-- Weather control commands (for testing)
function controls.set_weather_condition(car, weather_type)
    local valid_weather = {"clear", "rain", "snow"}
    if not table.contains(valid_weather, weather_type) then
        return false, "Invalid weather type. Use: clear, rain, or snow"
    end
    
    car.weather_condition = weather_type
    local weather_data = physics.weather_effects[weather_type]
    
    -- Apply weather effects immediately
    physics.apply_weather_effects(car, {current = weather_type})
    
    return true, string.format("Weather changed to %s", weather_type)
end

-- Performance monitoring and diagnostics
function controls.show_car_diagnostics(car, player)
    if not player or not player:is_player() then return end
    
    local diagnostics = {
        string.format("=== Car Diagnostics ==="),
        string.format("Speed: %.1f km/h", math.abs(car.v or 0) * 36),
        string.format("Gear: %s", physics.transmission.gears[car.current_gear or 1].name),
        string.format("Engine RPM: %d", car.engine_rpm or 0),
        string.format("Tire Wear: %.1f%%", (car.tire_wear or 1.0) * 100),
        string.format("Performance: %.1f%%", (car.performance_multiplier or 1.0) * 100),
        string.format("Suspension: %.2f", car.suspension_compression or 0),
        string.format("Weather: %s", car.weather_condition or "clear"),
        string.format("Surface: %s", car.surface_type or "unknown")
    }
    
    for _, line in ipairs(diagnostics) do
        minetest.chat_send_player(player:get_player_name(), line)
    end
end

return controls