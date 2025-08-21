-- Audio module for car_f1 mod
-- Handles all car sounds, engine audio, and 3D positional audio

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

local audio = {}

-- Sound definitions
local sounds = {
    engine_idle = "car_f1_engine_idle",
    engine_running = "car_f1_engine_running",
    engine_start = "car_f1_start",
    engine_stop = "car_f1_stop",
    crash = "car_f1_crash",
    enter = "car_f1_enter",
    exit = "car_f1_exit",
    horn = "car_f1_horn",
    tire_screech = "car_f1_tire_screech"
}

-- Initialize audio system
function audio.init()
    -- Register sound definitions
    for sound_name, sound_id in pairs(sounds) do
        minetest.register_sound(sound_id, {
            filename = minetest.get_modpath("car_f1") .. "/sounds/" .. sound_name .. ".ogg",
            gain = 1.0,
            max_hear_distance = config.ENGINE_SOUND_RADIUS * 16, -- Convert to blocks
            fade_in = 0.1,
            fade_out = 0.1
        })
    end
end

-- Play engine sound with 3D positioning and radius
function audio.play_engine_sound(car, sound_type, volume_multiplier)
    if not car or not car.object then
        return
    end
    
    local car_pos = car.object:get_pos()
    local sound_id = sounds[sound_type] or sounds.engine_idle
    local volume = (volume_multiplier or 1.0) * config.ENGINE_SOUND_GAIN
    
    -- Calculate volume based on distance from car
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local player_pos = player:get_pos()
        local distance = vector.distance(car_pos, player_pos)
        
        if distance <= config.ENGINE_SOUND_RADIUS * 16 then
            local gain = volume * (1 - (distance / (config.ENGINE_SOUND_RADIUS * 16)))
            gain = math.max(0.1, math.min(1.0, gain)) -- Clamp between 0.1 and 1.0
            
            minetest.sound_play(sound_id, {
                pos = car_pos,
                gain = gain,
                max_hear_distance = config.ENGINE_SOUND_RADIUS * 16,
                loop = (sound_type == "engine_idle" or sound_type == "engine_running")
            })
        end
    end
end

-- Stop engine sound
function audio.stop_engine_sound(car)
    if not car or not car.object then
        return
    end
    
    -- Stop all engine sounds for this car
    minetest.sound_stop(car.engine_sound_handle)
    car.engine_sound_handle = nil
end

-- Play car enter sound
function audio.play_enter_sound(car)
    if not car or not car.object then
        return
    end
    
    minetest.sound_play(sounds.enter, {
        pos = car.object:get_pos(),
        gain = 0.8,
        max_hear_distance = 20
    })
end

-- Play car exit sound
function audio.play_exit_sound(car)
    if not car or not car.object then
        return
    end
    
    minetest.sound_play(sounds.exit, {
        pos = car.object:get_pos(),
        gain = 0.8,
        max_hear_distance = 20
    })
end

-- Play crash sound based on impact force
function audio.play_crash_sound(car, impact_force)
    if not car or not car.object then
        return
    end
    
    local volume = math.min(impact_force / 10, 1.0)
    minetest.sound_play(sounds.crash, {
        pos = car.object:get_pos(),
        gain = volume,
        max_hear_distance = 30
    })
end

-- Play tire screech sound when turning sharply
function audio.play_tire_screech(car, turn_intensity)
    if not car or not car.object or turn_intensity < 0.3 then
        return
    end
    
    local volume = math.min(turn_intensity, 1.0) * 0.7
    minetest.sound_play(sounds.tire_screech, {
        pos = car.object:get_pos(),
        gain = volume,
        max_hear_distance = 25
    })
end

-- Play horn sound
function audio.play_horn(car)
    if not car or not car.object then
        return
    end
    
    minetest.sound_play(sounds.horn, {
        pos = car.object:get_pos(),
        gain = 1.0,
        max_hear_distance = 50
    })
end

-- Update engine sound based on car state
function audio.update_engine_sound(car)
    if not car or not car.object then
        return
    end
    
    local speed = math.abs(car.v or 0)
    local car_pos = car.object:get_pos()
    
    -- Stop previous engine sound
    if car.engine_sound_handle then
        minetest.sound_stop(car.engine_sound_handle)
    end
    
    -- Play appropriate engine sound based on speed
    if speed < 0.5 then
        -- Idle sound
        car.engine_sound_handle = minetest.sound_play(sounds.engine_idle, {
            pos = car_pos,
            gain = config.ENGINE_SOUND_GAIN,
            max_hear_distance = config.ENGINE_SOUND_RADIUS * 16,
            loop = true
        })
    else
        -- Running sound with volume based on speed
        local volume = math.min(0.5 + (speed / 10), 1.0)
        car.engine_sound_handle = minetest.sound_play(sounds.engine_running, {
            pos = car_pos,
            gain = volume * config.ENGINE_SOUND_GAIN,
            max_hear_distance = config.ENGINE_SOUND_RADIUS * 16,
            loop = true
        })
    end
end

-- Handle audio for all nearby players
function audio.update_3d_audio(car)
    if not car or not car.object then
        return
    end
    
    local car_pos = car.object:get_pos()
    local players = minetest.get_connected_players()
    
    for _, player in ipairs(players) do
        local player_pos = player:get_pos()
        local distance = vector.distance(car_pos, player_pos)
        
        -- Only play sounds for players within hearing range
        if distance <= config.ENGINE_SOUND_RADIUS * 16 then
            -- Calculate 3D audio positioning
            local direction = vector.direction(player_pos, car_pos)
            local gain = 1 - (distance / (config.ENGINE_SOUND_RADIUS * 16))
            gain = math.max(0.1, math.min(1.0, gain))
            
            -- Update engine sound for this player
            if car.engine_sound_handle then
                -- The sound system will automatically handle 3D positioning
                -- based on the car's position and the player's position
            end
        end
    end
end

-- Clean up audio when car is removed
function audio.cleanup(car)
    if car and car.engine_sound_handle then
        minetest.sound_stop(car.engine_sound_handle)
        car.engine_sound_handle = nil
    end
end

return audio