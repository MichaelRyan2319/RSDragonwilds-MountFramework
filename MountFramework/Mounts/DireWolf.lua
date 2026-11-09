-- Dire Wolf: a giant wolf that rides like the Terrorbird, a bit faster.
return {
    id = "dire_wolf",
    name = "Dire Wolf",
    description = "A wolf the size of a horse, bound to you by old magic. Faster than a Terrorbird and just as sure-footed.",
    icon = "/ScornedWilderness/UI/Icons/Icons/T_Icon_SM_Trophy_Plaque_Wolf",
    base = "Terrorbird",
    speed = 1.15,
    jump = 850,

    creature = {
        mesh = "/Game/Art/Skeleton/NPC/Creatures/Wolf_01/SK_Wolf_01",
        scale = 2.2,
        offset = { X = -50, Y = 0, Z = 0 },   -- moved back so you sit mid-back
        rotation = { Pitch = 0, Yaw = 0, Roll = 0 },
        idle = "/Game/Art/Animation/NPC_Wolf/Idle/A_NPC_Wolf_Idle_Breathe",
        walk = "/Game/Art/Animation/NPC_Wolf/Walk/A_NPC_Wolf_Walk_Fwd",
        run = "/Game/Art/Animation/NPC_Wolf/Run/A_NPC_Wolf_Run_Fwd",
        walkSpeed = 300,      -- faster than this uses the run animation
        walkAnimSpeed = 250,  -- speed the walk animation is made for
        runAnimSpeed = 900,   -- speed the run animation is made for
    },
}
