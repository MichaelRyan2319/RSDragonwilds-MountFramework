# Mount Framework for RuneScape: Dragonwilds

A UE4SS Lua mod for RuneScape: Dragonwilds that adds custom mounts. Each mount is
a small Lua file in the `Mounts` folder. Custom mounts are listed in the
Spellbook's **Mounts** tab next to the game's own mounts. A custom mount can:

- **look like another creature**: your mount is hidden and that creature's model
  is shown under you, with its own idle, walk and run animations;
- **fly**: hold Space to rise, Ctrl to descend and land, Shift to fly faster;
- change **speed, jump height and gravity**.

The framework has no mounts of its own. Each mount is a separate mod that needs
the framework:

| Mount mod | What it is |
| --- | --- |
| [Dire Wolf](https://github.com/MichaelRyan2319/RSDragonwilds-DireWolfMount) | A wolf the size of a horse. 15% faster than the Terrorbird and jumps higher. |
| [Young Dragon](https://github.com/MichaelRyan2319/RSDragonwilds-YoungDragonMount) | A small green dragon you can fly. |

- You need a mount of your own (e.g. the Terrorbird) to summon. A custom mount
  changes how that mount looks and moves while you ride it.
- Works in your own world (single player, or as the host).
- Your saves stay valid with or without the mod (see "Saves" below).
- Doesn't change any world settings, so achievements keep working.

This is an early version: creature riding is still being tuned, and flying
hasn't been tested much yet.

Built for game build 26162923 (Unreal Engine 5.6) with UE4SS v3.0.1.

## Requirements

- [UE4SS for RuneScape: Dragonwilds](https://github.com/MichaelRyan2319/RSDragonwilds-UE4SS).
  Any other UE4SS v3 install works too.

## Install with Mod Loader

[Mod Loader](https://github.com/MichaelRyan2319/ModLoader) installs the mod and
keeps it up to date.

1. **Add game** and pick RuneScape: Dragonwilds. Mod Loader 1.0.1 or later sets
   the mods folder to the game's inner `RSDragonwilds` folder (the one with
   `Binaries` and `Content` in it). If you added the game with an older version,
   edit it and choose that folder.
2. **Add mod** `MichaelRyan2319/RSDragonwilds-MountFramework`. The mod needs
   UE4SS, so Mod Loader 1.1.0 or later offers to add
   `MichaelRyan2319/RSDragonwilds-UE4SS` as well; click **Yes**. With an older
   Mod Loader, add `MichaelRyan2319/RSDragonwilds-UE4SS` yourself first.
3. Add the mount mods you want (e.g. `MichaelRyan2319/RSDragonwilds-DireWolfMount`).
   Adding a mount mod first also works: Mod Loader 1.1.0 or later then offers to
   add the framework and UE4SS.
4. Start the game and load your world.

## Install by hand

1. Install UE4SS (see Requirements).
2. Download `MountFramework.zip` from the [Releases](../../releases) page.
   In Steam, right-click RuneScape: Dragonwilds > Manage > Browse local files,
   then open the `RSDragonwilds` folder (the one with `Binaries` and `Content`
   in it) and extract the zip there. The mod ends up in
   `Binaries\Win64\ue4ss\Mods\MountFramework`.
3. Install the mount mods you want the same way. Their files go into
   `MountFramework\Mounts`.
4. Start the game and load your world.

The mod folder contains `enabled.txt`, so UE4SS loads it without any change to
`mods.txt`. To install from this repo instead of a release, copy the
`MountFramework` folder into `Win64\ue4ss\Mods\`.

## Using it

1. Press **P** to open the Spellbook and go to the **Mounts** tab. The custom
   mounts are at the end of the list.
2. Select one and press **Equip**. A message confirms it.
3. Summon your mount with the game's usual mount key and ride.

To go back to your normal mount, press Equip on the custom mount again, or equip
any of the game's mounts.

Flying mounts: while riding, hold **Space** to take off and climb, **Ctrl** to
descend (you land when you reach the ground), and **Shift** to fly faster.

## Making your own mounts

Copy `Mounts\_Template.lua`, rename the copy (files starting with `_` are
ignored), edit it and restart the game. The template explains every field. The
[Dire Wolf](https://github.com/MichaelRyan2319/RSDragonwilds-DireWolfMount) and
[Young Dragon](https://github.com/MichaelRyan2319/RSDragonwilds-YoungDragonMount)
mods are complete examples.

For a creature look, give the path of one of the game's creature models and its
animations. Then adjust `scale` and `offset` until it sits right under you.
Offsets are in centimetres: X is forward, Y is right, Z is up, and 0, 0, 0 is
the ground right under you.

To share a mount as its own mod, copy the Dire Wolf mod's layout:
- put the file at `MountFramework/Mounts/<Name>.lua` in the zip;
- add a `modloader.json` that requires this framework, so Mod Loader offers it.

If UE4SS can't list the folder, the log says so, and the framework loads only
the files named in `Mounts\_list.txt` (one file name per line; create it
yourself).

## Settings

Edit `Win64\ue4ss\Mods\MountFramework\Scripts\config.lua` in Notepad, then
restart the game.

| Setting | Default | What it does |
| --- | --- | --- |
| `AscendKey` | `"SpaceBar"` | Rise while flying |
| `DescendKey` | `"LeftControl"` | Descend and land while flying |
| `FastFlightKey` | `"LeftShift"` | Fly faster while held |
| `DebugLogging` | `false` | More detail in the log |

Key names are Unreal key names (`SpaceBar`, `LeftControl`, `E`, ...).

## Saves

The game won't save a character whose equipped or unlocked mount it doesn't
know, so the mod never equips a custom mount in the game. Your real mount stays
equipped. The mod remembers your chosen custom mount in its own file,
`saved_mount_<character>.txt`, in the mod folder, and changes how your mount
looks and moves while you ride.

If you remove the framework or the mount mod you chose, you just ride your
normal mount again.

## Achievements

The game skips achievement unlocks only in Creative and Custom worlds. This mod
never touches the world's mode or settings. The game's mod check (`CheckForMods`)
only logs a warning and marks the world as modded for people joining; it doesn't
block achievements.

## Troubleshooting

The log is `Win64\ue4ss\UE4SS.log`. Lines from this mod start with
`[MountFramework]`, including errors in mount files. Set `DebugLogging = true`
in `config.lua` for more detail.

## Uninstall

Delete `Win64\ue4ss\Mods\MountFramework`, or remove it in Mod Loader.

## Credits

UE4SS is made by the UE4SS team ([RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS),
MIT licence).
