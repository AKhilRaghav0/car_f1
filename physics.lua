-- Advanced physics module for car_f1 mod
-- Includes suspension, tire physics, aerodynamics, weight transfer, and collision systems

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

local physics = {}

-- Advanced physics constants
local suspension = {
    spring_constant = 50,    -- How stiff the suspension is
    damping = 0.7,          -- How much it bounces
    rest_height = 0.5,      -- Normal suspension height
    max_compression = 0.3,  -- How much it can compress
    max_extension = 0.2     -- How much it can extend
}

local tire_physics = {
    -- Tire properties
    tire_radius = 0.3,
    tire_width = 0.2,
    tire_pressure = 2.0,    -- Bar
    
    -- Traction coefficients
    dry_traction = 1.0,
    wet_traction = 0.6,
    ice_traction = 0.2,
    dirt_traction = 0.8,
    grass_traction = 0.5,
    
    -- Tire wear
    wear_rate = 0.001,
    max_wear = 1.0,
    min_wear = 0.1
}

local aerodynamics = {
    drag_coefficient = 0.3,
    frontal_area = 1.5,     -- m²
    air_density = 1.225,    -- kg/m³
    
    -- Downforce components
    front_wing_downforce = 0.8,
    rear_wing_downforce = 1.2,
    body_downforce = 0.5,
    
    -- Center of pressure
    center_of_pressure = {x=0, y=0.5, z=-1.0}
}

local transmission = {
    gears = {
        {ratio = 3.5, name = "1st"},
        {ratio = 2.2, name = "2nd"},
        {ratio = 1.5, name = "3rd"},
        {ratio = 1.1, name = "4th"},
        {ratio = 0.9, name = "5th"},
        {ratio = 0.7, name = "6th"}
    },
    final_drive = 3.9,
    clutch_slip = 0.1,
    current_gear = 1
}

local weather_effects = {
    clear = {
        traction_multiplier = 1.0,
        visibility_reduction = 0.0,
        hydroplaning_threshold = 999
    },
    rain = {
        traction_multiplier = 0.7,
        visibility_reduction = 0.3,
        hydroplaning_threshold = 15
    },
    snow = {
        traction_multiplier = 0.4,
        visibility_reduction = 0.5,
        snow_accumulation = 0.1
    },
    wind = {
        max_force = 2.0,
        direction = {x = 1, y = 0, z = 0}
    }
}

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
        ["default:grass"] = 0.5,
        ["default:wood"] = 0.9,
        ["default:steelblock"] = 1.0,
        ["default:asphalt"] = 0.95,
        ["default:concrete"] = 0.9
    }
    
    return friction_multipliers[node_name] or 1.0
end

-- Get traction coefficient based on surface and weather
function physics.get_traction_coefficient(surface_type, weather_condition)
    local base_traction = physics.get_surface_friction(surface_type)
    local weather_data = weather_effects[weather_condition or "clear"]
    
    return base_traction * weather_data.traction_multiplier
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

-- SUSPENSION SYSTEM
function physics.update_suspension(car, dtime)
    if not car.object then return end
    
    local pos = car.object:get_pos()
    local ground_height = physics.get_ground_height(pos)
    
    -- Initialize suspension if not exists
    car.suspension_velocity = car.suspension_velocity or 0
    car.suspension_compression = car.suspension_compression or 0
    
    -- Calculate suspension compression
    local target_height = ground_height + suspension.rest_height
    local current_height = pos.y
    local compression = target_height - current_height
    
    -- Clamp compression to limits
    compression = math.max(-suspension.max_compression, 
                          math.min(suspension.max_extension, compression))
    
    -- Apply spring force (Hooke's Law: F = -kx)
    local spring_force = -suspension.spring_constant * compression
    
    -- Apply damping force (F = -cv)
    local damping_force = -suspension.damping * car.suspension_velocity
    
    -- Update suspension velocity
    car.suspension_velocity = car.suspension_velocity + (spring_force + damping_force) * dtime
    
    -- Apply suspension force to car
    local suspension_accel = {x = 0, y = spring_force + damping_force, z = 0}
    car.object:set_acceleration(suspension_accel)
    
    -- Store suspension state
    car.suspension_compression = compression
end

-- TIRE PHYSICS & TRACTION
function physics.calculate_tire_forces(car, surface_type, speed, steering_angle, throttle_input, brake_input)
    local traction_coefficient = physics.get_traction_coefficient(surface_type, car.weather_condition)
    local tire_wear = car.tire_wear or 1.0
    
    -- Calculate available traction
    local max_traction = traction_coefficient * tire_wear * (car.mass or 1000)
    
    -- Calculate lateral force (turning)
    local lateral_force = steering_angle * speed * max_traction * 0.1
    
    -- Calculate longitudinal force (acceleration/braking)
    local longitudinal_force = (throttle_input - brake_input) * max_traction * 0.2
    
    -- Apply tire wear based on usage
    local wear_factor = (math.abs(steering_angle) + math.abs(throttle_input) + math.abs(brake_input)) * 0.1
    car.tire_wear = math.max(tire_physics.min_wear, 
                             car.tire_wear - tire_physics.wear_rate * speed * wear_factor * dtime)
    
    return lateral_force, longitudinal_force
end

-- WEIGHT TRANSFER SYSTEM
function physics.calculate_weight_transfer(car, acceleration, braking, turning)
    local wheelbase = 2.5  -- Distance between front and rear axles
    local track_width = 1.8 -- Distance between left and right wheels
    local cg_height = 0.4  -- Height of center of gravity
    local car_mass = car.mass or 1000
    
    -- Longitudinal weight transfer (front/back)
    local long_weight_transfer = (acceleration - braking) * cg_height / wheelbase
    
    -- Lateral weight transfer (left/right)
    local lat_weight_transfer = turning * cg_height / track_width
    
    -- Update wheel loads
    car.wheel_loads = {
        front_left = car_mass * 0.25 + long_weight_transfer * 0.5 + lat_weight_transfer * 0.5,
        front_right = car_mass * 0.25 + long_weight_transfer * 0.5 - lat_weight_transfer * 0.5,
        rear_left = car_mass * 0.25 - long_weight_transfer * 0.5 + lat_weight_transfer * 0.5,
        rear_right = car_mass * 0.25 - long_weight_transfer * 0.5 - lat_weight_transfer * 0.5
    }
    
    -- Ensure wheel loads are positive
    for wheel, load in pairs(car.wheel_loads) do
        car.wheel_loads[wheel] = math.max(0.1, load)
    end
    
    return car.wheel_loads
end

-- AERODYNAMICS SYSTEM
function physics.calculate_aerodynamic_forces(car, velocity, speed)
    if speed < 0.1 then return {x = 0, y = 0, z = 0} end
    
    local speed_squared = speed * speed
    
    -- Drag force (air resistance)
    local drag_force = 0.5 * aerodynamics.drag_coefficient * 
                      aerodynamics.frontal_area * 
                      aerodynamics.air_density * speed_squared
    
    -- Downforce (increases with speed)
    local total_downforce = (aerodynamics.front_wing_downforce + 
                            aerodynamics.rear_wing_downforce + 
                            aerodynamics.body_downforce) * speed_squared
    
    -- Apply forces at center of pressure
    local aero_force = {
        x = -drag_force * (velocity.x / speed),
        y = total_downforce,
        z = -drag_force * (velocity.z / speed)
    }
    
    return aero_force
end

-- TRANSMISSION SIMULATION
function physics.simulate_transmission(car, engine_rpm, throttle_input, dtime)
    local current_gear = car.current_gear or 1
    local gear_ratio = transmission.gears[current_gear].ratio
    
    -- Calculate wheel speed from engine RPM
    local wheel_speed = engine_rpm / (gear_ratio * transmission.final_drive)
    
    -- Simulate clutch engagement
    local clutch_engagement = math.min(1.0, (car.clutch_pedal or 1.0) + transmission.clutch_slip)
    
    -- Apply power to wheels
    local power_transfer = throttle_input * clutch_engagement
    local wheel_torque = power_transfer * engine_rpm * 0.001
    
    -- Update car velocity based on wheel torque
    local acceleration = wheel_torque / (car.mass or 1000)
    car.v = (car.v or 0) + acceleration * dtime
    
    -- Auto-shift logic
    if engine_rpm > 8000 and current_gear < #transmission.gears then
        car.current_gear = current_gear + 1
        car.engine_rpm = 4000
    elseif engine_rpm < 2000 and current_gear > 1 then
        car.current_gear = current_gear - 1
        car.engine_rpm = 6000
    end
    
    return wheel_speed, wheel_torque
end

-- ADVANCED COLLISION SYSTEM
function physics.handle_advanced_collision(car, impact_velocity, impact_point)
    -- Calculate impact energy
    local impact_energy = 0.5 * (car.mass or 1000) * vector.length(impact_velocity)^2
    
    -- Determine damage based on impact energy and location
    local damage_multipliers = {
        front_bumper = 1.0,
        hood = 0.8,
        windshield = 1.2,
        side_panel = 0.9,
        rear_bumper = 0.7,
        wheels = 1.5
    }
    
    local impact_location = physics.get_impact_location(impact_point, car)
    local damage = impact_energy * damage_multipliers[impact_location] / 1000
    
    -- Apply damage to specific components
    car.component_damage = car.component_damage or {}
    car.component_damage[impact_location] = (car.component_damage[impact_location] or 0) + damage
    
    -- Affect car performance based on damage
    physics.apply_damage_effects(car)
    
    -- Create realistic collision effects
    physics.create_collision_effects(car, impact_point, impact_energy)
    
    return damage, impact_location
end

-- Get impact location on car
function physics.get_impact_location(impact_point, car)
    local car_pos = car.object:get_pos()
    local car_yaw = car.object:get_yaw()
    
    -- Transform impact point to car-relative coordinates
    local relative_x = (impact_point.x - car_pos.x) * math.cos(-car_yaw) - 
                      (impact_point.z - car_pos.z) * math.sin(-car_yaw)
    local relative_z = (impact_point.x - car_pos.x) * math.sin(-car_yaw) + 
                      (impact_point.z - car_pos.z) * math.cos(-car_yaw)
    
    -- Determine impact location
    if relative_z > 1.0 then
        return "front_bumper"
    elseif relative_z < -1.0 then
        return "rear_bumper"
    elseif relative_x > 0.8 then
        return "side_panel"
    elseif relative_x < -0.8 then
        return "side_panel"
    else
        return "hood"
    end
end

-- Apply damage effects to car performance
function physics.apply_damage_effects(car)
    local total_damage = 0
    for _, damage in pairs(car.component_damage or {}) do
        total_damage = total_damage + damage
    end
    
    -- Reduce performance based on damage
    local damage_factor = math.max(0.3, 1 - (total_damage / 100))
    car.performance_multiplier = damage_factor
    
    -- Specific component effects
    if car.component_damage and car.component_damage.wheels then
        car.tire_wear = math.min(car.tire_wear or 1.0, 0.5)
    end
    
    if car.component_damage and car.component_damage.windshield then
        car.visibility_reduction = (car.component_damage.windshield or 0) / 100
    end
end

-- Create collision effects
function physics.create_collision_effects(car, impact_point, impact_energy)
    -- Create impact particles
    minetest.add_particlespawner({
        amount = math.floor(impact_energy / 10),
        time = 0.3,
        minpos = impact_point,
        maxpos = impact_point,
        minvel = {x = -2, y = 1, z = -2},
        maxvel = {x = 2, y = 3, z = 2},
        minacc = {x = 0, y = -5, z = 0},
        maxacc = {x = 0, y = -10, z = 0},
        minexptime = 0.5,
        maxexptime = 1.5,
        minsize = 0.2,
        maxsize = 0.8,
        collisiondetection = false,
        texture = "default_smoke.png"
    })
    
    -- Play collision sound
    if impact_energy > 5 then
        minetest.sound_play("car_f1_crash", {
            pos = impact_point,
            gain = math.min(impact_energy / 20, 1.0),
            max_hear_distance = 30
        })
    end
end

-- WEATHER EFFECTS SYSTEM
function physics.apply_weather_effects(car, weather_conditions)
    local current_weather = weather_conditions.current or "clear"
    local weather_data = weather_effects[current_weather] or weather_effects.clear
    
    -- Apply traction effects
    car.surface_traction = (car.surface_traction or 1.0) * weather_data.traction_multiplier
    
    -- Apply wind effects
    if weather_conditions.wind_strength then
        local wind_force = weather_conditions.wind_strength * weather_effects.wind.max_force
        local wind_vector = vector.multiply(weather_effects.wind.direction, wind_force)
        car.object:add_velocity(wind_vector)
    end
    
    -- Apply visibility effects
    if car.driver then
        local eye_offset = {x = 0, y = 0, z = weather_data.visibility_reduction}
        car.driver:set_eye_offset({x = 0, y = 0, z = 0}, eye_offset)
    end
    
    -- Store weather condition
    car.weather_condition = current_weather
end

-- TERRAIN DEFORMATION & TIRE MARKS
function physics.create_tire_marks(car, position, intensity)
    if intensity < 0.3 then return end
    
    -- Create tire mark particles
    minetest.add_particlespawner({
        amount = math.floor(intensity * 10),
        time = 0.5,
        minpos = position,
        maxpos = position,
        minvel = {x = -0.1, y = 0.05, z = -0.1},
        maxvel = {x = 0.1, y = 0.1, z = 0.1},
        minacc = {x = 0, y = 0.02, z = 0},
        maxacc = {x = 0, y = 0.05, z = 0},
        minexptime = 2,
        maxexptime = 5,
        minsize = 0.1,
        maxsize = 0.3,
        collisiondetection = false,
        texture = "car_f1_tire_mark.png"
    })
    
    -- Optionally deform terrain (advanced feature)
    if intensity > 0.7 then
        physics.deform_terrain(position, intensity)
    end
end

-- Deform terrain at position (placeholder for future implementation)
function physics.deform_terrain(position, intensity)
    -- This is a placeholder for future terrain deformation
    -- Could modify nearby nodes to create tire tracks
    -- For now, just log the deformation
    minetest.log("info", string.format("[car_f1] Terrain deformation at %s with intensity %.2f", 
                                      minetest.pos_to_string(position), intensity))
end

-- Initialize car physics state
function physics.initialize_car_physics(car)
    car.mass = car.mass or 1000
    car.tire_wear = car.tire_wear or 1.0
    car.performance_multiplier = car.performance_multiplier or 1.0
    car.current_gear = car.current_gear or 1
    car.engine_rpm = car.engine_rpm or 4000
    car.clutch_pedal = car.clutch_pedal or 1.0
    car.suspension_velocity = car.suspension_velocity or 0
    car.suspension_compression = car.suspension_compression or 0
    car.component_damage = car.component_damage or {}
    car.wheel_loads = car.wheel_loads or {}
    car.weather_condition = car.weather_condition or "clear"
    car.surface_traction = car.surface_traction or 1.0
    car.visibility_reduction = car.visibility_reduction or 0
end

return physics