local MAX_SPEED = 0
local MAX_SPEED_FORWARD = 130
local MAX_SPEED_REVERSE = 30
local ACCELERATION = 8
local BRAKING = 4
local TURN_SPEED = 4
local RETARDATION = 0.05

--[[
transform velocity into new coord ???
  yaw: car yaw (radian engle)
    v: current speed
    y: y coord
    r: turn (0=straight, 1=right, -1=left)
    f: turn speed
]]--
local function get_new_velocity(v, yaw, y, r, f)
  local turn_deg = yaw + r * math.rad(105)
  local x = (math.cos(yaw) + math.abs(r) * math.cos(turn_deg) * f) * v
  local z = (math.sin(yaw) + math.abs(r) * math.sin(turn_deg) * f) * v
  -- print(tostring(math.deg(yaw) % 360))
  -- print("vertical:"..tostring(y))
  -- print("rotation:"..(r==1 and "right" or r==-1 and "left" or ""))
  -- print("current_speed:"..tostring(math.floor(v)))
  return {x=x, y=y, z=z}
end

local function get_sign(i) return (i==0) and 0 or (i / math.abs(i)) end

local function round(number, decimal)
  local multiplier = 10^(decimal or 0)
  return math.floor(number * multiplier + 0.5) / multiplier
end

-- CAR ENTITY
local car_f1 = {
  physical = true,
  collisionbox = {-1/2,-1/2,-1/2,1/2,1/2,1/2},
  visual = "mesh",
  visual_size = {x=2, y=2, z=2},
  mesh = "hawk_f1.x",
  textures = {"car_f11.png"},  
  driver = nil,
  v = 0,
  r = 0,
  f = 0,
  timer = 0,
  mouselook = true,
}

function car_f1:on_rightclick(clicker)
  if not clicker or not clicker:is_player() then return end
  if not self.driver then
    clicker:set_attach(self.object, "", {x=-2, y=-1, z=0}, {x=0, y=90, z=0})
    clicker:set_properties({visual_size={x=0.3, y=0.3, z=0.3}, eye_height=0.3})

    default.player_attached[clicker:get_player_name()] = true
    minetest.after(0.2, function() -- we must do this because of bug
      default.player_set_animation(clicker, "sit" , 1)
    end)

    self.object:set_yaw(clicker:get_look_horizontal() - math.rad(270))
    self.driver = clicker
  elseif clicker == self.driver then
    clicker:set_detach()
    clicker:set_properties({visual_size = {x=1, y=1, z=1}, eye_height=1.4700000286102})
    default.player_attached[clicker:get_player_name()] = false
	  default.player_set_animation(clicker, "stand" , 30)
    self.driver = nil
  end
end

function car_f1:on_activate(staticdata, dtime_s)
  self.object:set_armor_groups({immortal=1})
  -- if staticdata then self.v = tonumber(staticdata) end
end

function car_f1:get_staticdata() return tostring(self.v) end

function car_f1:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
  self.object:remove()
  if puncher and puncher:is_player() then
    puncher:get_inventory():add_item("main", "car_f1:car_f1")
    puncher:set_properties({visual_size = {x=1, y=1, z=1}, eye_height=1.4700000286102})
    default.player_attached[puncher:get_player_name()] = false
	  default.player_set_animation(puncher, "stand" , 30)
  end
end

function car_f1:on_step(dtime)
	-- Acelerating, braking, rotating and skidding
  self.v = math.sqrt(self.object:get_velocity().x^2 + self.object:get_velocity().z^2) * get_sign(self.v)
  self.f = (self.f > 0.5) and 0.5 or 0
  self.r = 0
  self.timer = (self.timer + dtime) % 2

  if self.driver then
    local ctrl = self.driver:get_player_control()
    if ctrl == nil then return end

    if ctrl.up then
      self.v = self.v + ((get_sign(self.v) >= 0) and ACCELERATION or BRAKING) / 10
    end

    if ctrl.down then
      self.v = self.v - ((get_sign(self.v) <= 0) and ACCELERATION or BRAKING) / 10
    end

    if ctrl.left and (self.v ~= 0) then
      self.object:set_yaw(self.object:get_yaw() + get_sign(self.v) * math.rad(1 + dtime) * TURN_SPEED)
      self.r = -1
      self.f = self.f + 0.01
    end

    if ctrl.right and (self.v ~= 0) then
      self.object:set_yaw(self.object:get_yaw() - get_sign(self.v) * math.rad(1 + dtime) * TURN_SPEED)
      self.r = 1
      self.f = self.f + 0.01
    end

    if not (ctrl.up or ctrl.down) then
      self.f = self.f - 0.02
    end

    if ctrl.jump then self.mouselook = not self.mouselook end

    if not self.mouselook then
      self.driver:set_look_horizontal(self.object:get_yaw() - math.pi / 2)
    end
  end

	-- Moving
  local p = self.object:get_pos()
  local a = self.object:get_yaw()
  local nx = p.x + math.cos(a) * get_sign(self.v)
  local nz = p.z + math.sin(a) * get_sign(self.v)
  local n1 = minetest.get_node({x=nx, y=p.y - 0.5, z=nz})
  local n2 = minetest.get_node({x=nx, y=p.y + 0.5, z=nz})

	-- Retardation (on different surfaces are not ready yet!)
  local nn = minetest.get_node({x=p.x, y=p.y-1, z=p.z}).name
  local s = get_sign(self.v)
  local m = 10

  self.v = (math.abs(self.v) < 0.5) and 0 or self.v - RETARDATION / 10 * s * m

	-- Speed limit forward and reverse (on different surfaces are not ready yet!)
  if get_sign(self.v) >= 0 then
    MAX_SPEED = MAX_SPEED_FORWARD / m
  else
    MAX_SPEED = MAX_SPEED_REVERSE / m
  end

  if math.abs(self.v) > MAX_SPEED then self.v = self.v - get_sign(self.v) end

  -- Setting position, velocity and acceleration  
  self.object:set_pos({x=p.x, y=p.y, z=p.z})
  self.object:set_velocity(get_new_velocity(self.v, self.object:get_yaw(), self.object:get_velocity().y, self.r, self.f))
  
  if n1.name ~= "air" and minetest.registered_nodes[n1.name].walkable and n2.name == "air" then
    self.object:set_acceleration({x=0, y=15, z=0})
	else
		self.object:set_acceleration({x=0, y=-30, z=0})
	end
end

minetest.register_entity("car_f1:car_f1", car_f1)

minetest.register_craftitem("car_f1:car_f1", {
  description = "Car: F1",
  inventory_image = "car_f1_inventory.png",
  wield_image = "car_f1_inventory.png",
  wield_scale = {x=1, y=1, z=1},
  
  on_place = function(itemstack, placer, pointed_thing)
    if pointed_thing.type ~= "node" then return end
    minetest.add_entity(pointed_thing.above, "car_f1:car_f1")
    itemstack:take_item()
    return itemstack
  end,
})
minetest.register_craft({
	output = "car_f1:car_f1",
	recipe = {
		{"", "", "default:glass"},
		{"default:steelblock", "default:steelblock", "default:steelblock"}
	},
})
--[[minetest.register_craft({
  output = "car_f1:car_f1",
  recipe = {
      {"technic:chromium_ingot", "technic:chromium_ingot", "technic:chromium_ingot"},
      {"farming:bottle_ethanol", "technic:carbon_steel_block", "farming:bottle_ethanol"},
      {"technic:rubber", "technic:carbon_steel_block", "technic:rubber"}
  },
}) ]]--

