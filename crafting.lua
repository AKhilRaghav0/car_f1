-- Crafting module for car_f1 mod
-- Handles all recipes, crafting logic, and item definitions

local config = dofile(minetest.get_modpath("car_f1") .. "/config.lua")

local crafting = {}

-- Register the F1 car as a craftitem
function crafting.register_car_item()
    minetest.register_craftitem("car_f1:car_f1", {
        description = "F1 Racing Car",
        inventory_image = "car_f1_inventory.png",
        wield_image = "car_f1_inventory.png",
        wield_scale = {x = 1, y = 1, z = 1},
        
        -- Place car in world
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then 
                return itemstack 
            end
            
            -- Check if there's enough space
            local pos = pointed_thing.above
            local car_size = {x = 2, y = 2, z = 2}
            
            -- Check for obstacles
            for x = -1, 1 do
                for y = 0, 2 do
                    for z = -1, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name ~= "air" and minetest.registered_nodes[node.name].walkable then
                            if placer and placer:is_player() then
                                minetest.chat_send_player(placer:get_player_name(), "Not enough space to place the car!")
                            end
                            return itemstack
                        end
                    end
                end
            end
            
            -- Place the car
            local car = minetest.add_entity(pos, "car_f1:car_f1")
            if car then
                -- Orient car towards placer
                if placer then
                    local placer_pos = placer:get_pos()
                    local direction = vector.direction(pos, placer_pos)
                    local yaw = math.atan2(direction.z, direction.x)
                    car:set_yaw(yaw)
                end
                
                itemstack:take_item()
                return itemstack
            else
                if placer and placer:is_player() then
                    minetest.chat_send_player(placer:get_player_name(), "Failed to place the car!")
                end
            end
            
            return itemstack
        end,
        
        -- Show car info when examining
        on_use = function(itemstack, user, pointed_thing)
            if user and user:is_player() then
                minetest.chat_send_player(user:get_player_name(), 
                    "F1 Racing Car - A high-performance racing vehicle!")
                minetest.chat_send_player(user:get_player_name(), 
                    "Right-click to place, then right-click again to enter!")
            end
            return itemstack
        end
    })
end

-- Register basic crafting recipe
function crafting.register_basic_recipe()
    minetest.register_craft({
        output = "car_f1:car_f1",
        recipe = {
            {"", "", "default:glass"},
            {"default:steelblock", "default:steelblock", "default:steelblock"},
            {"default:steelblock", "default:mese", "default:steelblock"}
        }
    })
end

-- Register advanced crafting recipe (if technic mod is available)
function crafting.register_advanced_recipe()
    if minetest.get_modpath("technic") then
        minetest.register_craft({
            output = "car_f1:car_f1",
            recipe = {
                {"technic:chromium_ingot", "technic:chromium_ingot", "technic:chromium_ingot"},
                {"farming:bottle_ethanol", "technic:carbon_steel_block", "farming:bottle_ethanol"},
                {"technic:rubber", "technic:carbon_steel_block", "technic:rubber"}
            }
        })
        
        -- Add fuel recipe
        minetest.register_craft({
            output = "car_f1:fuel_can",
            recipe = {
                {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
                {"default:steel_ingot", "farming:bottle_ethanol", "default:steel_ingot"},
                {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
            }
        })
    end
end

-- Register fuel can item
function crafting.register_fuel_item()
    minetest.register_craftitem("car_f1:fuel_can", {
        description = "Fuel Can - Refuels your F1 car",
        inventory_image = "car_f1_fuel_can.png",
        wield_image = "car_f1_fuel_can.png",
        
        on_use = function(itemstack, user, pointed_thing)
            if not user or not user:is_player() then
                return itemstack
            end
            
            -- Check if player is in a car
            local attached_to = user:get_attach()
            if attached_to then
                local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
                for _, obj in ipairs(car_entity) do
                    if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                        local car = obj:get_luaentity()
                        if car.fuel < 100 then
                            car.fuel = math.min(100, car.fuel + 25)
                            itemstack:take_item()
                            
                            minetest.chat_send_player(user:get_player_name(), 
                                "Car refueled! Fuel level: " .. math.floor(car.fuel) .. "%")
                            
                            -- Play refuel sound
                            minetest.sound_play("car_f1_refuel", {
                                pos = car.object:get_pos(),
                                gain = 0.8,
                                max_hear_distance = 15
                            })
                            
                            return itemstack
                        else
                            minetest.chat_send_player(user:get_player_name(), "Car is already full of fuel!")
                            return itemstack
                        end
                    end
                end
            end
            
            minetest.chat_send_player(user:get_player_name(), "You must be in a car to use fuel!")
            return itemstack
        end
    })
end

-- Register repair kit item
function crafting.register_repair_item()
    minetest.register_craftitem("car_f1:repair_kit", {
        description = "Repair Kit - Repairs your damaged F1 car",
        inventory_image = "car_f1_repair_kit.png",
        wield_image = "car_f1_repair_kit.png",
        
        on_use = function(itemstack, user, pointed_thing)
            if not user or not user:is_player() then
                return itemstack
            end
            
            -- Check if player is in a car
            local attached_to = user:get_attach()
            if attached_to then
                local car_entity = minetest.get_objects_inside_radius(attached_to:get_pos(), 1)
                for _, obj in ipairs(car_entity) do
                    if obj:get_luaentity() and obj:get_luaentity().name == "car_f1:car_f1" then
                        local car = obj:get_luaentity()
                        if car.damage > 0 then
                            car.damage = math.max(0, car.damage - 25)
                            itemstack:take_item()
                            
                            minetest.chat_send_player(user:get_player_name(), 
                                "Car repaired! Damage level: " .. math.floor(car.damage) .. "%")
                            
                            -- Play repair sound
                            minetest.sound_play("car_f1_repair", {
                                pos = car.object:get_pos(),
                                gain = 0.8,
                                max_hear_distance = 15
                            })
                            
                            return itemstack
                        else
                            minetest.chat_send_player(user:get_player_name(), "Car is already in perfect condition!")
                            return itemstack
                        end
                    end
                end
            end
            
            minetest.chat_send_player(user:get_player_name(), "You must be in a car to use the repair kit!")
            return itemstack
        end
    })
    
    -- Repair kit recipe
    minetest.register_craft({
        output = "car_f1:repair_kit",
        recipe = {
            {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
            {"default:steel_ingot", "default:mese", "default:steel_ingot"},
            {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
        }
    })
end

-- Register all crafting components
function crafting.register_all()
    crafting.register_car_item()
    crafting.register_basic_recipe()
    crafting.register_advanced_recipe()
    crafting.register_fuel_item()
    crafting.register_repair_item()
end

return crafting