-- Template for a new mount. Copy this file, rename it (files starting with _ are
-- ignored), change it and restart the game. Errors are written to
-- Win64\ue4ss\UE4SS.log, on lines starting with [MountFramework].
-- Distances are in centimetres (100 = 1 metre), speeds in cm per second.

return {
    id = "my_mount",          -- unique, letters/digits/_ only. Don't change it later:
                              -- it's how your equipped mount is remembered.
    name = "My Mount",
    description = "Shown in the Mounts tab.",
    icon = "/Game/Art/UI/Spellcasting/Mounts/T_Mount_Terrobird_02_03",  -- picture in the Mounts tab
    base = "Terrorbird",      -- the game mount whose data the Mounts tab entry is copied
                              -- from: "Terrorbird", "Carpet" or a full mount data path

    -- A custom mount changes your own equipped mount while you ride it. Carry
    -- weight and the base riding pose come from that mount.

    -- Optional stats (leave out to keep your mount's)
    speed = 1.2,              -- multiplier on running/sprinting speed
    jump = 900,               -- jump strength (Terrorbird 800)
    gravity = 0.97,           -- lower = floatier jumps (Terrorbird 0.97)
    airControl = 1.0,         -- steering in the air

    -- Optional: look like another creature. The base mount is hidden and this
    -- model is shown under you. Tune scale/offset until it sits right.
    -- creature = {
    --     mesh = "/Game/Art/Skeleton/NPC/Creatures/Wolf_01/SK_Wolf_01",
    --     scale = 1.9,
    --     offset = { X = 0, Y = 0, Z = -179 },   -- -179 puts its feet on the ground
    --     rotation = { Pitch = 0, Yaw = 0, Roll = 0 },
    --     idle = "/Game/Art/Animation/NPC_Wolf/Idle/A_NPC_Wolf_Idle_Breathe",
    --     walk = "/Game/Art/Animation/NPC_Wolf/Walk/A_NPC_Wolf_Walk_Fwd",
    --     run = "/Game/Art/Animation/NPC_Wolf/Run/A_NPC_Wolf_Run_Fwd",
    --     fly = nil, hover = nil,               -- used while flying
    --     walkSpeed = 300, walkAnimSpeed = 250, runAnimSpeed = 900,
    -- },

    -- Optional: make it fly (Space rises, Ctrl descends and lands, Shift is faster).
    -- flying = { speed = 1400, climb = 700, fastMultiplier = 1.75 },
}
