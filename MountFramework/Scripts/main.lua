--[[
    Mount Framework - RuneScape: Dragonwilds (UE4SS Lua mod)

    Adds custom mounts, defined in Lua files in the Mounts folder. They appear in
    the Spellbook's Mounts tab (P, then the Mounts tab). Select one and press
    Equip, then summon your mount with the game's normal mount key.

    A custom mount changes how your own mount looks and moves while you ride it:
      * creature: your mount is hidden and another creature's model is shown under
        you, playing its idle/walk/run animations
      * flying: hold Space to rise, Ctrl to descend and land, Shift to fly faster
      * speed, jump and gravity

    Saves stay valid: the game never sees a custom mount equipped or unlocked (it
    refuses to save a character that has one). Your real mount stays equipped, and
    the framework remembers which custom mount you chose in its own file
    (saved_mount_<character>.txt). Pressing Equip on the custom mount again, or on
    any normal mount, switches back to your normal mount. Removing the mod just
    leaves you riding your normal mount.

    Only works in your own world (single player or as host).
]]

local UEHelpers = require("UEHelpers")
local U = require("mf.util")

------------------------------------------------------------------------ config

local Defaults = {
    AscendKey = "SpaceBar",
    DescendKey = "LeftControl",
    FastFlightKey = "LeftShift",
    DebugLogging = false,
}
local Config = {}
for k, v in pairs(Defaults) do Config[k] = v end
do
    local ok, user = pcall(require, "config")
    if ok and type(user) == "table" then
        for k, v in pairs(user) do Config[k] = v end
    elseif not ok then
        U.Log("config.lua could not be loaded, using defaults: %s", tostring(user))
    end
end
U.Debug = Config.DebugLogging == true

local MOD_FOLDER = U.ModFolder()
local TICK_MS = 33

local BASES = {
    Terrorbird = "/Game/Gameplay/Mounts/TerrorbirdVariants/DA_Mount_Terrorbird_01_01",
    Carpet = "/UmbralSands/Gameplay/Mounts/FlyingCarpetVariants/DA_Mount_FlyingCarpet_01_01",
}

-- EMovementMode
local MOVE_WALKING, MOVE_FALLING, MOVE_FLYING = 1, 3, 5

------------------------------------------------------------------------ toast

local toast = nil
local function Toast(message, seconds)
    U.Log("%s", message)
    pcall(function()
        if toast and U.Valid(toast.widget) then toast.widget:RemoveFromParent() end
        local function New(cls, outer, name)
            return StaticConstructObject(StaticFindObject(cls), outer, FName(U.UniqueName(name)))
        end
        local w = New("/Script/UMG.UserWidget", UEHelpers.GetGameInstance(), "MF_Toast")
        w.WidgetTree = New("/Script/UMG.WidgetTree", w, "WidgetTree")
        local canvas = New("/Script/UMG.CanvasPanel", w.WidgetTree, "Canvas")
        w.WidgetTree.RootWidget = canvas
        local box = New("/Script/UMG.Border", w.WidgetTree, "Box")
        box:SetBrushColor({ R = 0.03, G = 0.025, B = 0.02, A = 0.85 })
        box:SetPadding({ Left = 14, Top = 14, Right = 14, Bottom = 14 })
        local t = New("/Script/UMG.TextBlock", w.WidgetTree, "Text")
        t:SetText(FText(message))
        pcall(function() t:SetColorAndOpacity({ SpecifiedColor = { R = 0.93, G = 0.78, B = 0.45, A = 1 }, ColorUseRule = 0 }) end)
        pcall(function() local f = t.Font; f.Size = 20; t:SetFont(f) end)
        box:SetContent(t)
        local slot = canvas:AddChildToCanvas(box)
        slot:SetAnchors({ Minimum = { X = 0.5, Y = 0 }, Maximum = { X = 0.5, Y = 0 } })
        slot:SetAlignment({ X = 0.5, Y = 0 })
        slot:SetPosition({ X = 0, Y = 140 })
        slot:SetAutoSize(true)
        w:AddToViewport(950)
        toast = { widget = w, untilTime = os.clock() + (seconds or 3) }
    end)
end

------------------------------------------------------------------------ loading mount files

local Mounts = {}      -- id -> def
local MountList = {}

local function NormalizeDef(def, file)
    if type(def) ~= "table" then return nil, "the file must return a table" end
    if type(def.id) ~= "string" or not def.id:match("^[%w_]+$") then
        return nil, "missing or invalid id (letters, digits and _ only)"
    end
    def.file = file
    def.name = def.name or def.id
    def.description = def.description or ""
    def.base = def.base or "Terrorbird"
    def.speed = def.speed or 1.0
    if def.creature then
        local c = def.creature
        if type(c.mesh) ~= "string" then return nil, "creature.mesh is missing" end
        c.scale = c.scale or 1.0
        c.offset = c.offset or { X = 0, Y = 0, Z = 0 }
        c.rotation = c.rotation or { Pitch = 0, Yaw = 0, Roll = 0 }
        c.walkSpeed = c.walkSpeed or 250
        c.walkAnimSpeed = c.walkAnimSpeed or c.walkSpeed
        c.runAnimSpeed = c.runAnimSpeed or 700
    end
    if def.flying then
        def.flying.speed = def.flying.speed or 1200
        def.flying.climb = def.flying.climb or 600
        def.flying.fastMultiplier = def.flying.fastMultiplier or 1.75
    end
    return def
end

local function LoadMountFiles()
    local folder = MOD_FOLDER .. "Mounts/"
    local files = U.ListLuaFiles(folder)
    if not files then
        U.Log("Could not list %s; loading only the mounts named in Mounts/_list.txt.", folder)
        files = {}
        for line in (U.ReadFile(folder .. "_list.txt") or ""):gmatch("[^\r\n]+") do
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then files[#files + 1] = line end
        end
    end
    for _, name in ipairs(files) do
        if name:sub(1, 1) ~= "_" then
            local chunk, err = loadfile(folder .. name, "t", setmetatable({}, { __index = _G }))
            if not chunk then
                U.Log("Mount file %s has an error: %s", name, tostring(err))
            else
                local ok, def = pcall(chunk)
                local good, why
                if ok then good, why = NormalizeDef(def, name) else why = tostring(def) end
                if not good then
                    U.Log("Mount file %s skipped: %s", name, why)
                elseif Mounts[def.id] then
                    U.Log("Mount file %s skipped: id '%s' is already used by %s", name, def.id, Mounts[def.id].file)
                else
                    Mounts[def.id] = def
                    MountList[#MountList + 1] = def
                end
            end
        end
    end
    U.Log("%d custom mount(s) defined.", #MountList)
end

------------------------------------------------------------------------ mount data

-- Each custom mount gets a copy of its base mount's data. The copies are only
-- shown in the Mounts tab; they are never unlocked or equipped in the game.
local CloneOf = {}      -- id -> data object
local CloneDef = {}     -- address of a copy -> def
local ClonesMade = false

local function MountComponent()
    local pawn = U.Pawn()
    local mc = pawn and U.Get(pawn, "MountComponent")
    if U.Valid(mc) then return mc end
    return nil
end

local function ApplyStats(data, def)
    U.Set(data, "DisplayName", FText(def.name))
    U.Set(data, "Description", FText(def.description))
    if def.icon then
        local icon = U.Soft(def.icon)
        if icon then U.Set(data, "MountIcon", icon) end
    end
end

local function MakeClones()
    if ClonesMade then return end
    ClonesMade = true
    for _, def in ipairs(MountList) do
        local template = U.Load(BASES[def.base] or def.base)
        if template then
            local data = U.Clone(template, nil, "DA_MF_" .. def.id)
            if data then
                ApplyStats(data, def)
                CloneOf[def.id] = data
                CloneDef[U.Addr(data)] = def
            end
        else
            U.Log("Mount '%s': base mount %s not found.", def.id, tostring(def.base))
        end
    end
end

------------------------------------------------------------------------ the player's world

local World = { pawnAddr = nil, readyAt = nil, ready = false, file = nil, selected = nil }

local function CharacterKey()
    local pc = U.PlayerController()
    local ok, key = pcall(function()
        local g = pc:GetCharacterGuid().InnerGuid
        return string.format("%08X%08X%08X%08X", g.A & 0xFFFFFFFF, g.B & 0xFFFFFFFF, g.C & 0xFFFFFFFF, g.D & 0xFFFFFFFF)
    end)
    if ok and key and key ~= "00000000000000000000000000000000" then return key end
    local ps = U.Get(pc, "PlayerState")
    local okName, name = pcall(function() return ps:GetPlayerName():ToString() end)
    if okName and name and name ~= "" then return (name:gsub("[^%w_%-]", "_")) end
    return "default"
end

local function SaveSelection()
    if not World.file then return end
    U.WriteFile(World.file, "# Mount Framework: the custom mount you chose. Written by the mod.\nselected=" .. (World.selected or "") .. "\n")
end

local function SetupWorld(mc)
    MakeClones()
    -- Never leave a copy unlocked or equipped: the game can't save those.
    for _, data in pairs(CloneOf) do
        local ok, unlocked = U.Call(mc, "IsMountUnlocked", data)
        if ok and unlocked then U.Call(mc, "SetMountUnlocked", data, false) end
    end
    World.file = MOD_FOLDER .. "saved_mount_" .. CharacterKey() .. ".txt"
    local id = (U.ReadFile(World.file) or ""):match("selected=([%w_]+)")
    World.selected = (id and Mounts[id]) and id or nil
    return true
end

local function Select(id)
    World.selected = id
    SaveSelection()
    local mc = MountComponent()
    if id then
        Toast(Mounts[id].name .. " equipped. Summon your mount to ride it.", 4)
    else
        local eq = mc and U.Get(mc, "EquippedMountData")
        Toast("Back to " .. (U.Valid(eq) and U.Str(U.Get(eq, "DisplayName")) or "your normal mount") .. ".", 3)
    end
end

------------------------------------------------------------------------ mounts tab

local Tab = {}   -- screen address -> { entries }
local LOCK_EQUIPPABLE = 2   -- EMountLockState::UnlockedAndEquippable

local function IsTemplate(obj)
    local name = U.FullName(obj)
    return name:find("Default__", 1, true) ~= nil or name:find("^%S+ /Game/") ~= nil
end

local function VisibleSpellbook()
    for _, screen in ipairs(FindAllOf("SpellBookScreen") or {}) do
        if U.Valid(screen) and not IsTemplate(screen) then
            local ok, visible = pcall(function() return screen:IsVisible() end)
            if ok and visible then return screen end
        end
    end
    return nil
end

local function RefreshEntries(screen, entries)
    local changed = false
    for _, e in ipairs(entries) do
        local def = CloneDef[U.Addr(U.Get(e, "MountData"))]
        local isEq = def ~= nil and def.id == World.selected
        if U.Get(e, "bIsEquipped") ~= isEq then
            U.Set(e, "bIsEquipped", isEq)
            changed = true
        end
        -- The game sets every entry's lock state from the mounts you've unlocked
        -- whenever it refreshes the tab, which marks ours Locked. Undo that.
        if U.Get(e, "LockState") ~= LOCK_EQUIPPABLE then
            U.Set(e, "LockState", LOCK_EQUIPPABLE)
            changed = true
        end
    end
    if changed then U.Call(U.Get(screen, "MountsList"), "RegenerateAllEntries") end
end

local function UpdateMountsTab()
    local screen = VisibleSpellbook()
    if not screen then return end
    local list = U.Get(screen, "MountsList")
    if not U.Valid(list) then return end
    local okNum, num = U.Call(list, "GetNumItems")
    if not (okNum and type(num) == "number" and num > 0) then return end
    local key = U.Addr(screen)
    local mine = Tab[key]
    local present = false
    if mine and mine[1] and U.Valid(mine[1]) then
        for i = 0, num - 1 do
            local _, item = U.Call(list, "GetItemAt", i)
            if U.Same(item, mine[1]) then present = true break end
        end
    end
    if present then
        RefreshEntries(screen, mine)
        return
    end
    local entries = {}
    for _, def in ipairs(MountList) do
        local data = CloneOf[def.id]
        if data then
            local e = U.NewObject("/Script/Dominion.MountSlotEntryData", screen, "MF_" .. def.id, false)
            if e then
                U.Set(e, "MountData", data)
                U.Set(e, "LockState", LOCK_EQUIPPABLE)
                U.Set(e, "bIsEquipped", World.selected == def.id)
                U.Call(list, "AddItem", e)
                entries[#entries + 1] = e
            end
        end
    end
    Tab[key] = entries
end

-- The Equip button can't equip a custom mount (the game would refuse to save it),
-- so the framework watches for the click itself.
local function OnClick()
    if not World.ready then return end
    local screen = VisibleSpellbook()
    if not screen then return end
    local list = U.Get(screen, "MountsList")
    local okVis, listVisible = U.Call(list, "IsVisible")
    if not (okVis and listVisible) then return end
    local panel = U.Get(screen, "MountDetailsPanel")
    local button = U.Valid(panel) and U.Get(panel, "EquipButton")
    if not U.Valid(button) then return end
    local okHover, hovered = U.Call(button, "IsHovered")
    if not (okHover and hovered) then return end
    local entry = U.Get(screen, "SelectedMountEntryData")
    local def = U.Valid(entry) and CloneDef[U.Addr(U.Get(entry, "MountData"))] or nil
    if def then
        if World.selected == def.id then Select(nil) else Select(def.id) end
    elseif World.selected then
        Select(nil)   -- a normal mount was equipped
    end
    local mine = Tab[U.Addr(screen)]
    if mine then RefreshEntries(screen, mine) end
end

------------------------------------------------------------------------ riding

local Ride = nil   -- { def, comp, anim, flying, base, lastSet, upHeld, stuck, lastZ }
local skmClass = nil
local FKeys = {}

local function KeyDown(name)
    local pc = U.PlayerController()
    if not pc or not name or name == "" then return false end
    local k = FKeys[name]
    if not k then
        k = { KeyName = FName(name) }
        FKeys[name] = k
    end
    local ok, down = pcall(function() return pc:IsInputKeyDown(k) end)
    return ok and down == true
end

local function PlayAnim(anim, rate)
    if not (Ride and U.Valid(Ride.comp)) then return end
    if anim and Ride.anim ~= anim then
        local obj = U.Load(anim)
        if obj then
            U.Call(Ride.comp, "PlayAnimation", obj, true)
            Ride.anim = anim
        end
    end
    if rate and Ride.rate ~= rate then
        U.Call(Ride.comp, "SetPlayRate", rate)
        Ride.rate = rate
    end
end

local function SetMesh(comp, mesh)
    for _, fn in ipairs({ "SetSkeletalMeshAsset", "SetSkinnedAssetAndUpdate", "SetSkeletalMesh" }) do
        local ok = pcall(function()
            if fn == "SetSkeletalMeshAsset" then comp[fn](comp, mesh) else comp[fn](comp, mesh, true) end
        end)
        if ok then return true end
    end
    return false
end

local function CreateCreature(pawn, mc, c)
    if not U.Valid(skmClass) then skmClass = StaticFindObject("/Script/Engine.SkeletalMeshComponent") end
    local mesh = U.Load(c.mesh)
    if not (U.Valid(skmClass) and mesh) then return nil end
    local ok, comp = pcall(function()
        return pawn:AddComponentByClass(skmClass, true,
            { Rotation = { X = 0, Y = 0, Z = 0, W = 1 }, Translation = { X = 0, Y = 0, Z = 0 }, Scale3D = { X = 1, Y = 1, Z = 1 } }, false)
    end)
    if not ok or not U.Valid(comp) then
        U.Log("Could not add the creature model: %s", tostring(comp))
        return nil
    end
    U.Call(comp, "SetCollisionEnabled", 0)
    U.Call(comp, "SetGenerateOverlapEvents", false)
    U.Call(comp, "K2_AttachToComponent", mc, FName("None"), 0, 0, 0, false)
    if not SetMesh(comp, mesh) then U.Log("Could not set the creature model's mesh.") end
    for i, path in ipairs(c.materials or {}) do
        local m = U.Load(path)
        if m then U.Call(comp, "SetMaterial", i - 1, m) end
    end
    -- The mount's own mesh is turned like every character mesh: its +Y is forward and
    -- its -X is right. Offsets in mount files are forward/right/up, so convert them.
    local o = c.offset
    U.Call(comp, "K2_SetRelativeLocationAndRotation", { X = -(o.Y or 0), Y = o.X or 0, Z = o.Z or 0 }, c.rotation, false, {}, false)
    U.Call(comp, "SetRelativeScale3D", { X = c.scale, Y = c.scale, Z = c.scale })
    return comp
end

local function StartRide(def, pawn, mc)
    Ride = { def = def, mc = mc, flying = false, upHeld = 0, stuck = 0 }
    local cm = U.Get(pawn, "CharacterMovement")
    if U.Valid(cm) then
        if def.jump then U.Set(cm, "JumpZVelocity", def.jump) end
        if def.gravity then U.Set(cm, "GravityScale", def.gravity) end
        if def.airControl then U.Set(cm, "AirControl", def.airControl) end
    end
    if def.creature then
        Ride.comp = CreateCreature(pawn, mc, def.creature)
        if Ride.comp then U.Call(mc, "SetVisibility", false, false) end
    end
    if def.flying and not World.flightHintShown then
        World.flightHintShown = true
        Toast(string.format("%s can fly: hold %s to rise, %s to descend, %s to fly faster.",
            def.name, Config.AscendKey, Config.DescendKey, Config.FastFlightKey), 6)
    end
end

local function StopRide(pawn, mc)
    if not Ride then return end
    if U.Valid(Ride.comp) then U.Call(Ride.comp, "K2_DestroyComponent", Ride.comp) end
    if U.Valid(mc) then U.Call(mc, "SetVisibility", true, false) end
    local cm = pawn and U.Get(pawn, "CharacterMovement")
    if U.Valid(cm) then
        if Ride.flying and U.Get(cm, "MovementMode") == MOVE_FLYING then U.Call(cm, "SetMovementMode", MOVE_FALLING, 0) end
        if Ride.base then U.Set(cm, "MaxWalkSpeed", Ride.base) end
    end
    Ride = nil
end

local function UpdateFlight(def, pawn, cm, dt)
    local up = KeyDown(Config.AscendKey)
    local down = KeyDown(Config.DescendKey)
    local mode = U.Get(cm, "MovementMode")
    if not Ride.flying then
        Ride.upHeld = up and (Ride.upHeld + dt) or 0
        if up and (mode == MOVE_FALLING or Ride.upHeld > 0.3) then
            U.Call(cm, "SetMovementMode", MOVE_FLYING, 0)
            U.Set(cm, "BrakingDecelerationFlying", 2000)
            Ride.flying = true
            Ride.stuck = 0
        end
        return
    end
    if mode ~= MOVE_FLYING then U.Call(cm, "SetMovementMode", MOVE_FLYING, 0) end
    local speed = def.flying.speed * (KeyDown(Config.FastFlightKey) and def.flying.fastMultiplier or 1)
    if U.Get(cm, "MaxFlySpeed") ~= speed then U.Set(cm, "MaxFlySpeed", speed) end
    local v = U.Get(cm, "Velocity")
    local vz = up and def.flying.climb or (down and -def.flying.climb or 0)
    if v then U.Set(cm, "Velocity", { X = v.X, Y = v.Y, Z = vz }) end
    -- Land when descending and the ground stops us.
    local z = (U.Location(pawn) or {}).Z
    if down and z and Ride.lastZ and (Ride.lastZ - z) < 1 then
        Ride.stuck = Ride.stuck + dt
        if Ride.stuck > 0.25 then
            U.Call(cm, "SetMovementMode", MOVE_WALKING, 0)
            Ride.flying = false
            Ride.upHeld = 0
        end
    else
        Ride.stuck = 0
    end
    Ride.lastZ = z
end

local function UpdateSpeed(def, cm)
    if def.speed == 1.0 or Ride.flying then return end
    local cur = U.Get(cm, "MaxWalkSpeed")
    if type(cur) ~= "number" then return end
    if not Ride.lastSet or math.abs(cur - Ride.lastSet) > 0.5 then Ride.base = cur end
    local want = (Ride.base or cur) * def.speed
    if math.abs(cur - want) > 0.5 then
        U.Set(cm, "MaxWalkSpeed", want)
        Ride.lastSet = want
    end
end

local function UpdateCreatureAnim(def, cm)
    if not U.Valid(Ride.comp) then return end
    local c = def.creature
    local v = U.Get(cm, "Velocity")
    local speed = v and math.sqrt(v.X * v.X + v.Y * v.Y) or 0
    if Ride.flying then
        if speed > 150 and c.fly then
            PlayAnim(c.fly, 1.0)
        else
            PlayAnim(c.hover or c.fly or c.idle, 1.0)
        end
    elseif speed < 20 then
        PlayAnim(c.idle, 1.0)
    elseif speed < c.walkSpeed or not c.run then
        PlayAnim(c.walk or c.run or c.idle, math.max(0.5, math.min(2.0, speed / c.walkAnimSpeed)))
    else
        PlayAnim(c.run, math.max(0.6, math.min(2.0, speed / c.runAnimSpeed)))
    end
    -- The game may show its own mount mesh again (e.g. after a mount animation).
    local okVis, vis = U.Call(Ride.mc, "IsVisible")
    if okVis and vis then U.Call(Ride.mc, "SetVisibility", false, false) end
end

local function UpdateRide(dt)
    local pawn = U.Pawn()
    local mc = MountComponent()
    if not (pawn and mc) then
        if Ride then Ride = nil end
        return
    end
    local okM, mounted = U.Call(mc, "IsMounted")
    local def = (okM and mounted and World.selected) and Mounts[World.selected] or nil
    if Ride and (not def or Ride.def ~= def) then StopRide(pawn, mc) end
    if def and not Ride then StartRide(def, pawn, mc) end
    if not Ride then return end
    local cm = U.Get(pawn, "CharacterMovement")
    if not U.Valid(cm) then return end
    if def.flying then UpdateFlight(def, pawn, cm, dt) end
    UpdateSpeed(def, cm)
    if def.creature then UpdateCreatureAnim(def, cm) end
end

------------------------------------------------------------------------ driving

local tickCount = 0
local lastClock = os.clock()
local function Tick()
    tickCount = tickCount + 1
    local now = os.clock()
    local dt = math.min(0.2, now - lastClock)
    lastClock = now
    if toast and now >= toast.untilTime then
        if U.Valid(toast.widget) then pcall(function() toast.widget:RemoveFromParent() end) end
        toast = nil
    end
    local pawn = U.Pawn()
    local addr = pawn and U.Addr(pawn)
    if addr ~= World.pawnAddr then
        World.pawnAddr = addr
        World.ready = false
        World.readyAt = pawn and (now + 2.0) or nil
        Ride = nil
    end
    if not pawn or #MountList == 0 then return end
    local mc = MountComponent()
    if not mc then return end
    if not World.ready then
        if now >= (World.readyAt or 0) and tickCount % 30 == 0 then World.ready = SetupWorld(mc) end
        return
    end
    UpdateRide(dt)
    if tickCount % 8 == 0 then UpdateMountsTab() end
end

local SafeTick = function()
    local ok, err = pcall(Tick)
    if not ok then U.Log("Tick error: %s", tostring(err)) end
end

LoadMountFiles()

local queued = false
LoopAsync(TICK_MS, function()
    if not queued then
        queued = true
        ExecuteInGameThread(function()
            queued = false
            SafeTick()
        end)
    end
    return false
end)

RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, function()
    ExecuteInGameThread(function()
        local ok, err = pcall(OnClick)
        if not ok then U.Log("Click error: %s", tostring(err)) end
    end)
end)

MountFramework = { Mounts = Mounts, Config = Config, Toast = Toast, Select = function(id) Select(id) end }

U.Log("Loaded. Mounts are read from %sMounts/", MOD_FOLDER)
