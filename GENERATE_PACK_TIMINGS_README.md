# Pack Timing Generator for TrinketMenu

This Python script parses WoW combat logs and generates pack timing data for TrinketMenu raid profiles.

## Usage

```bash
python3 generate_pack_timings.py <combat_log.txt>
```

This will automatically create a `PackTimings.lua` file with the timing data.

## Example

```bash
python3 generate_pack_timings.py test_combat_log.txt
```

The script will create `PackTimings.lua` which you can then paste into TrinketMenu's Import Timings dialog.

## Input Format

The combat log should contain lines in this format:
```
1/2 19:59:20.782  PLAYER_REGEN_DISABLED
1/2 19:59:27.343  UNIT_DIED:Greater Gloomwing:0xF13000F1ED276B19
1/2 19:59:28.395  PLAYER_REGEN_ENABLED
```

## Output Format

The script outputs a Lua table with pack names mapped to engagement and death times:

```lua
local packTimings = {
    ["kara_entrance_1"] = {
        engageTime = "1/2 19:59:30.298",
        deathTimes = {"1/2 19:59:32.881", "1/2 19:59:35.797"},
    },
}

return packTimings
```

## How It Works

1. **Parses RaidPacks/*.lua** - Loads all GUID to pack name mappings from raid pack files
2. **Tracks Combat** - Uses `PLAYER_REGEN_DISABLED` as engage time
3. **Maps Deaths** - Matches UNIT_DIED GUIDs to pack names
4. **Groups by Pack** - Deaths in the same combat are grouped by pack name
5. **Outputs Lua** - Generates a Lua table with timing data

## Notes

- The script must be run from the TrinketMenu directory (where RaidPacks/ folder is located)
- GUIDs not found in raid pack files will generate warnings on stderr
- Multiple packs can be pulled in the same combat and will have the same engage time
- If the log ends without `PLAYER_REGEN_ENABLED`, the script still captures the last combat

## Warnings

Warnings are printed to stderr (not in the output file) when:
- A GUID is not found in any RaidPacks/*.lua file
- Usually means the mob is not part of any configured pack (e.g., pets, random mobs, adds)
