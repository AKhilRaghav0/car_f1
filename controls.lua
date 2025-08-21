-- Controls module for car_f1 mod
-- Handles all player input, car controls, and driver management

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

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

-- Process player controls and update car state
function controls.process_controls(car, dtime)
    if not car.driver then
        return
    end
    
    local ctrl = car.driver:get_player_control()
    if not ctrl then 
        return 
    end
    
    -- Acceleration and braking
    if ctrl.up then
        car.v = car.v + ((physics.get_sign(car.v) >= 0) and config.ACCELERATION or config.BRAKING) / 10
    end
    
    if ctrl.down then
        car.v = car.v - ((physics.get_sign(car.v) <= 0) and config.ACCELERATION or config.BRAKING) / 10
    end
    
    -- Turning (only when moving)
    if ctrl.left and (car.v ~= 0) then
        car.object:set_yaw(car.object:get_yaw() + physics.get_sign(car.v) * math.rad(1 + dtime) * config.TURN_SPEED)
        car.r = -1
        car.f = math.min(car.f + config.TURN_FACTOR_INCREMENT, config.MAX_TURN_FACTOR)
    end
    
    if ctrl.right and (car.v ~= 0) then
        car.object:set_yaw(car.object:get_yaw() - physics.get_sign(car.v) * math.rad(1 + dtime) * config.TURN_SPEED)
        car.r = 1
        car.f = math.min(car.f + config.TURN_FACTOR_INCREMENT, config.MAX_TURN_FACTOR)
    end
    
    -- Natural turn factor decay
    if not (ctrl.left or ctrl.right) then
        car.f = math.max(car.f - config.TURN_FACTOR_DECREMENT, 0)
    end
    
    -- Toggle mouse look
    if ctrl.jump then 
        car.mouselook = not car.mouselook 
    end
    
    -- Handle mouse look
    if not car.mouselook then
        car.driver:set_look_horizontal(car.object:get_yaw() - math.pi / 2)
    end
    
    -- Handle handbrake (sneak key)
    if ctrl.sneak then
        car.v = car.v * 0.95 -- Apply handbrake effect
    end
end

-- Update driver camera and view
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
    
    return true, "OK"
end

-- Handle car damage from crashes
function controls.handle_crash(car, impact_force)
    if impact_force > 5 then
        -- Play crash sound
        if car.crash_sound then
            minetest.sound_play(car.crash_sound, {
                pos = car.object:get_pos(),
                gain = math.min(impact_force / 10, 1.0),
                max_hear_distance = 20
            })
        end
        
        -- Apply damage effects
        if car.driver then
            -- Shake camera
            car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
            minetest.after(0.1, function()
                if car.driver and car.driver:is_player() then
                    car.driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
                end
            end)
        end
    end
end

return controls