-- Physics module for car_f1 mod
-- Handles all car movement, physics calculations, and collision detection

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

local physics = {}

--[[
Transform velocity into new coordinates based on car physics
  v: current speed
  yaw: car yaw (radian angle)
  y: y coordinate
  r: turn direction (0=straight, 1=right, -1=left)
  f: turn factor
]]--
function physics.get_new_velocity(v, yaw, y, r, f)
    local turn_deg = yaw + r * math.rad(105)
    local x = (math.cos(yaw) + math.abs(r) * math.cos(turn_deg) * f) * v
    local z = (math.sin(yaw) + math.abs(r) * math.sin(turn_deg) * f) * v
    return {x = x, y = y, z = z}
end

-- Get sign of a number
function physics.get_sign(i) 
    return (i == 0) and 0 or (i / math.abs(i)) 
end

-- Round number to specified decimal places
function physics.round(number, decimal)
    local multiplier = 10^(decimal or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

-- Calculate surface friction based on node type
function physics.get_surface_friction(node_name)
    local friction_multipliers = {
        ["default:stone"] = 0.8,
        ["default:dirt"] = 0.6,
        ["default:sand"] = 0.4,
        ["default:water_source"] = 0.2,
        ["default:ice"] = 0.1,
        ["default:snow"] = 0.3,
        ["default:grass"] = 0.7,
        ["default:wood"] = 0.9,
        ["default:steelblock"] = 1.0
    }
    
    return friction_multipliers[node_name] or 1.0
end

-- Check if car is on a slope and calculate slope angle
function physics.check_slope(car_pos, car_yaw)
    local front_pos = {
        x = car_pos.x + math.cos(car_yaw) * 2,
        y = car_pos.y,
        z = car_pos.z + math.sin(car_yaw) * 2
    }
    
    local back_pos = {
        x = car_pos.x - math.cos(car_yaw) * 2,
        y = car_pos.y,
        z = car_pos.z - math.sin(car_yaw) * 2
    }
    
    local front_height = physics.get_ground_height(front_pos)
    local back_height = physics.get_ground_height(back_pos)
    local current_height = physics.get_ground_height(car_pos)
    
    local slope_angle = math.atan2(front_height - back_height, 4)
    local slope_factor = math.abs(slope_angle) / math.pi * 2
    
    return slope_angle, slope_factor
end

-- Get ground height at a position
function physics.get_ground_height(pos)
    local y = pos.y
    while y > pos.y - 10 do
        local node = minetest.get_node({x = pos.x, y = y, z = pos.z})
        if node.name ~= "air" and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable then
            return y + 1
        end
        y = y - 1
    end
    return pos.y
end

-- Calculate acceleration based on surface and slope
function physics.calculate_acceleration(car_pos, car_yaw, current_speed, surface_friction)
    local slope_angle, slope_factor = physics.check_slope(car_pos, car_yaw)
    local slope_acceleration = math.sin(slope_angle) * 5
    
    -- Reduce acceleration on slopes to prevent unrealistic behavior
    local slope_multiplier = math.max(0.3, 1 - slope_factor)
    
    return slope_acceleration * slope_multiplier * surface_friction
end

-- Check for collisions ahead of the car
function physics.check_collision_ahead(car_pos, car_yaw, look_ahead_distance)
    local check_pos = {
        x = car_pos.x + math.cos(car_yaw) * look_ahead_distance,
        y = car_pos.y,
        z = car_pos.z + math.sin(car_yaw) * look_ahead_distance
    }
    
    local node = minetest.get_node(check_pos)
    if node.name ~= "air" and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable then
        return true, check_pos
    end
    
    return false, nil
end

-- Apply realistic physics constraints
function physics.apply_physics_constraints(speed, max_speed, acceleration, braking)
    local constrained_speed = speed
    
    -- Speed limits
    if math.abs(constrained_speed) > max_speed then
        constrained_speed = physics.get_sign(constrained_speed) * max_speed
    end
    
    -- Acceleration limits
    if acceleration > 0 and constrained_speed < max_speed then
        constrained_speed = math.min(constrained_speed + acceleration, max_speed)
    elseif acceleration < 0 and constrained_speed > -max_speed then
        constrained_speed = math.max(constrained_speed + acceleration, -max_speed)
    end
    
    return constrained_speed
end

return physics