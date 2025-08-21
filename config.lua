-- Configuration file for car_f1 mod
-- All mod settings and constants are defined here

local config = {
    -- Physics constants
    MAX_SPEED_FORWARD = 130,
    MAX_SPEED_REVERSE = 30,
    ACCELERATION = 8,
    BRAKING = 4,
    TURN_SPEED = 4,
    RETARDATION = 0.05,
    
    -- Car properties
    CAR_SCALE = {x = 2, y = 2, z = 2},
    PLAYER_SCALE = {x = 0.3, y = 0.3, z = 0.3},
    PLAYER_NORMAL_SCALE = {x = 1, y = 1, z = 1},
    PLAYER_EYE_HEIGHT = 1.47,
    PLAYER_ATTACHED_EYE_HEIGHT = 0.3,
    
    -- Collision and positioning
    COLLISION_BOX = {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2},
    DRIVER_OFFSET = {x = -2, y = -1, z = 0},
    DRIVER_ROTATION = {x = 0, y = 90, z = 0},
    
    -- Audio settings
    ENGINE_SOUND_RADIUS = 4,
    ENGINE_SOUND_GAIN = 1.0,
    
    -- Physics multipliers
    SURFACE_MULTIPLIER = 10,
    GRAVITY = -30,
    JUMP_ACCELERATION = 15,
    
    -- Animation settings
    SIT_ANIMATION = "sit",
    STAND_ANIMATION = "stand",
    ANIMATION_SPEED = 30,
    
    -- Turn handling
    MAX_TURN_FACTOR = 0.5,
    TURN_FACTOR_INCREMENT = 0.01,
    TURN_FACTOR_DECREMENT = 0.02,
    
    -- Speed thresholds
    MIN_SPEED_THRESHOLD = 0.5,
    TURN_SPEED_THRESHOLD = 0.5
}

return config