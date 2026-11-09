-- Young Dragon: a small dragon you can fly. Hold Space to rise, Ctrl to descend,
-- Shift to fly faster.
return {
    id = "young_dragon",
    name = "Young Dragon",
    description = "A lesser dragon, still small enough to ride. Hold Space to take off and climb, Ctrl to descend and land, Shift to fly faster.",
    icon = "/ScornedWilderness/UI/Icons/Icons/T_Icon_SM_Trophy_Plaque_GreenDragon",
    base = "Terrorbird",
    speed = 1.0,

    creature = {
        mesh = "/Game/Art/Skeleton/NPC/Reptilian/Dragon_Lesser_Green_01/SK_Dragon_Lesser_Green_01",
        scale = 0.6,
        offset = { X = 0, Y = 0, Z = 0 },
        rotation = { Pitch = 0, Yaw = 0, Roll = 0 },
        idle = "/FutureMajorVersion/Art/Animation/Animations/NPC_LesserDragon/Idle/A_NPC_LesserDragon_Idle",
        walk = "/FutureMajorVersion/Art/Animation/Animations/NPC_LesserDragon/Walk/A_NPC_LesserDragon_Walk",
        run = "/FutureMajorVersion/Art/Animation/Animations/NPC_LesserDragon/Run/A_NPC_LesserDragon_Run",
        hover = "/FutureMajorVersion/Art/Animation/Animations/NPC_LesserDragon/Abilities/A_NPC_LesserDragon_Hover",
        fly = "/FutureMajorVersion/Art/Animation/Animations/NPC_LesserDragon/Abilities/A_NPC_LesserDragon_Hover",
        walkSpeed = 300,
        walkAnimSpeed = 300,
        runAnimSpeed = 900,
    },

    flying = {
        speed = 1400,          -- cm/s level flight
        climb = 700,           -- cm/s up/down
        fastMultiplier = 1.75, -- with Shift held
    },
}
