# 🚀 Installation Guide for Enhanced F1 Car Mod

This guide will help you install and set up the enhanced F1 car mod for Minetest.

## 📋 **Prerequisites**

- **Minetest**: Version 5.0 or higher
- **Required Mods**: `default` mod (usually included with Minetest)
- **Optional Mods**: `technic`, `farming` (for advanced recipes)

## 🔧 **Installation Steps**

### **Step 1: Download the Mod**
1. **Clone** or **download** the mod files
2. **Extract** the ZIP file if downloaded
3. **Ensure** you have the complete mod structure

### **Step 2: Locate Minetest Mods Directory**
The location depends on your operating system:

#### **Windows**
```
C:\Users\[YourUsername]\AppData\Roaming\Minetest\mods\
```

#### **Linux**
```
~/.minetest/mods/
```

#### **macOS**
```
~/Library/Application Support/minetest/mods/
```

### **Step 3: Install the Mod**
1. **Copy** the entire `car_f1` folder to your mods directory
2. **Ensure** the folder structure looks like this:
```
mods/
└── car_f1/
    ├── init_new.lua
    ├── config.lua
    ├── physics.lua
    ├── controls.lua
    ├── audio.lua
    ├── car_entity.lua
    ├── crafting.lua
    ├── mod.conf
    ├── README.md
    ├── textures/
    ├── models/
    └── sounds/
```

### **Step 4: Enable the Mod**
1. **Launch** Minetest
2. **Go to** Settings → All Settings → Mods
3. **Find** `car_f1` in the mod list
4. **Check** the box to enable it
5. **Click** "Save" and restart Minetest

## 🎮 **First Time Setup**

### **Step 1: Join a World**
1. **Create** a new world or **join** an existing one
2. **Ensure** the world has the `default` mod enabled
3. **Wait** for the world to fully load

### **Step 2: Test the Mod**
1. **Use** the command `/car_info` to see mod information
2. **Use** the command `/car_spawn` to spawn a test car
3. **Right-click** the car to enter it
4. **Use** WASD keys to drive around

### **Step 3: Craft Your First Car**
1. **Gather** materials:
   - 6 Steel Blocks
   - 1 Glass
   - 1 Mese Crystal
2. **Open** crafting table
3. **Arrange** materials in the pattern shown in README
4. **Craft** your F1 car!

## 🔧 **Troubleshooting**

### **Mod Won't Load**
- **Check** that all required files are present
- **Verify** `mod.conf` syntax is correct
- **Ensure** Minetest version is 5.0+
- **Check** console for error messages

### **Car Won't Spawn**
- **Verify** the mod is enabled in world settings
- **Check** that `default` mod is enabled
- **Try** using `/car_spawn` command
- **Restart** the world

### **Sounds Not Working**
- **Rename** existing sound files:
  - `running.ogg` → `car_f1_engine_running.ogg`
  - `start.ogg` → `car_f1_start.ogg`
- **Create** missing sound files (see sounds/README.md)
- **Check** audio settings in Minetest

### **Textures Not Loading**
- **Verify** texture files are in the `textures/` folder
- **Check** file names match exactly
- **Ensure** PNG format with transparency support
- **Restart** Minetest after adding textures

### **Physics Issues**
- **Check** that all Lua files are present
- **Verify** no syntax errors in console
- **Ensure** `physics.lua` is loading correctly
- **Try** spawning a new car

## 📁 **File Structure Verification**

After installation, your mod folder should contain:

```
car_f1/
├── init_new.lua          # ✅ Main mod file
├── config.lua            # ✅ Configuration
├── physics.lua           # ✅ Physics system
├── controls.lua          # ✅ Control system
├── audio.lua             # ✅ Audio system
├── car_entity.lua        # ✅ Car entity
├── crafting.lua          # ✅ Crafting system
├── mod.conf              # ✅ Mod configuration
├── README.md             # ✅ Documentation
├── INSTALLATION.md       # ✅ This file
├── textures/             # ✅ Texture files
│   ├── car_f11.png
│   ├── car_f1_inventory.png
│   └── car_texture_template.png
├── models/               # ✅ 3D models
│   └── hawk_f1.x
└── sounds/               # ✅ Audio files
    ├── running.ogg
    └── start.ogg
```

## 🎯 **Quick Test Commands**

Once installed, test these commands in-game:

- `/car_info` - Show mod information
- `/car_spawn` - Spawn a test car
- **Right-click** car to enter/exit
- **WASD** to drive around
- **Space** to toggle mouse look
- **Shift** for handbrake

## 🔄 **Updating the Mod**

1. **Backup** your current mod folder
2. **Download** the new version
3. **Replace** old files with new ones
4. **Restart** Minetest
5. **Test** functionality

## 📞 **Getting Help**

If you encounter issues:

1. **Check** this installation guide
2. **Read** the README.md file
3. **Verify** file structure matches exactly
4. **Check** Minetest console for error messages
5. **Ensure** all dependencies are met

## 🎉 **Success!**

Once you see the F1 car working in-game, you've successfully installed the enhanced mod! Enjoy your improved racing experience with:

- ✅ Enhanced physics and slope handling
- ✅ 3D positional audio
- ✅ Fuel and damage systems
- ✅ Better controls and camera
- ✅ Particle effects and visual improvements

**Happy racing! 🏁**