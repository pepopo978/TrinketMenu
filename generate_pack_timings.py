#!/usr/bin/env python3
"""
Parse WoW combat log and map deaths to TrinketMenu pack names.

Usage: python generate_pack_timings.py <combat_log.txt>
"""

import re
import sys
import glob
from collections import defaultdict
from datetime import datetime


def parse_raid_packs(raid_packs_dir):
    """Parse RaidPacks/*.lua files to build a GUID -> packName mapping."""
    guid_to_pack = {}

    # Find all .lua files in the RaidPacks directory
    lua_files = glob.glob(f"{raid_packs_dir}/*.lua")

    for filepath in lua_files:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Pattern to match pack entries in inline array format:
        # { packName = "...", mob_guids = { ... } },
        # Use non-greedy matching to handle optional fields like mob_names.
        pack_pattern = r'(?<!\[)\{\s*[^}]*?packName\s*=\s*"([^"]+)".*?mob_guids\s*=\s*\{([^}]+)\}\s*\}'

        for match in re.finditer(pack_pattern, content, re.DOTALL):
            pack_name = match.group(1)
            guids_block = match.group(2)

            # Extract individual GUIDs from the mob_guids array
            guid_pattern = r'"(0x[A-F0-9]+)"'
            for guid_match in re.finditer(guid_pattern, guids_block):
                guid = guid_match.group(1)
                guid_to_pack[guid] = pack_name

    return guid_to_pack


def parse_time_to_seconds(timestamp):
    """Convert timestamp 'M/D HH:MM:SS.mmm' to total seconds."""
    try:
        date_part, time_part = timestamp.split()
        month, day = map(int, date_part.split('/'))
        hours, minutes, seconds_ms = time_part.split(':')
        hours = int(hours)
        minutes = int(minutes)
        seconds = float(seconds_ms)

        # Convert to total seconds (ignoring date for now, assuming same day)
        total_seconds = hours * 3600 + minutes * 60 + seconds
        return total_seconds
    except:
        return None


def should_ignore_guid(guid):
    """Check if GUID should be ignored (players or summoned mobs)."""
    if guid == "0xF130016C95276DAF":
        return False
    # Ignore player GUIDs (0x00...) and summoned/temporary mobs
    ignored_prefixes = ['0x00', '0xF130016', '0xF14', '0xF13000EA9E27', '0xF130001', '0xF130000FEB', '0xF13000EA54276', '0xF13000F48B278']
    for prefix in ignored_prefixes:
        if guid.startswith(prefix):
            return True
    return False


def parse_combat_log(log_filepath, guid_to_pack):
    """Parse combat log and group deaths by pack."""

    # Store pack encounters: packName -> list of {engageTime, deaths: [timestamps], mob_data: [(name, guid)]}
    pack_encounters = defaultdict(lambda: {'engage_time': None, 'deaths': [], 'time_since_last_combat': None, 'mob_data': []})
    current_engage_time = None
    last_regen_enabled_time = None

    # Track deaths in current combat
    current_combat_deaths = {}  # packName -> [death_times]
    current_combat_mob_data = defaultdict(list)  # packName -> [(name, guid)]
    current_time_since_last_combat = None

    # Track player death to ignore false combat ends
    player_just_died = False

    # Track unknown GUIDs and assign them sequential names based on combat groups
    unknown_guid_counter = 1
    unknown_guid_map = {}  # GUID -> "unknown_N"

    # Track unknown GUIDs in current combat to group them together
    current_combat_unknown_guids = set()
    current_combat_unknown_pack_name = None
    current_combat_has_known_pack = False

    with open(log_filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Parse line format: "1/2 19:59:20.782  EVENT_NAME[:details]"
            parts = line.split(maxsplit=2)
            if len(parts) < 3:
                continue

            date_part = parts[0]  # e.g., "1/2"
            time_part = parts[1]  # e.g., "19:59:20.782"
            event_part = parts[2]  # e.g., "PLAYER_REGEN_DISABLED"

            timestamp = f"{date_part} {time_part}"
            self_end_combat = False  # Reset for each line

            # Handle combat start
            if event_part == "PLAYER_REGEN_DISABLED":
                current_engage_time = timestamp
                current_combat_deaths = defaultdict(list)
                current_combat_mob_data = defaultdict(list)
                current_combat_unknown_guids = set()
                current_combat_unknown_pack_name = None
                current_combat_has_known_pack = False

                # Calculate time since last combat
                if last_regen_enabled_time:
                    last_end_sec = parse_time_to_seconds(last_regen_enabled_time)
                    current_start_sec = parse_time_to_seconds(timestamp)
                    if last_end_sec is not None and current_start_sec is not None:
                        current_time_since_last_combat = current_start_sec - last_end_sec
                    else:
                        current_time_since_last_combat = None
                else:
                    current_time_since_last_combat = None

            # Handle player death (durability loss)
            elif "durability loss" in event_part:
                player_just_died = True

            # Handle raid-wide combat status
            elif event_part.startswith("PLAYERS_IN_COMBAT:"):
                # Parse "PLAYERS_IN_COMBAT: X/Y"
                match = re.match(r'PLAYERS_IN_COMBAT:\s*(\d+)/(\d+)', event_part)
                if match and current_engage_time:
                    in_combat = int(match.group(1))
                    total_players = int(match.group(2))

                    # End combat if less than 5% of players are in combat
                    if total_players > 0 and (in_combat / total_players) < 0.05:
                        # This is the real combat end - commit deaths
                        self_end_combat = True
                        player_just_died = False  # Reset the flag

            # Handle combat end
            elif event_part == "PLAYER_REGEN_ENABLED":
                # Ignore this if player just died - wait for PLAYERS_IN_COMBAT instead
                if player_just_died:
                    continue

                self_end_combat = True

            # Process combat end (triggered by either PLAYER_REGEN_ENABLED or PLAYERS_IN_COMBAT)
            if self_end_combat:
                # Print summary for unknown pack if created in this combat
                if current_combat_unknown_pack_name:
                    mob_data = current_combat_mob_data[current_combat_unknown_pack_name]
                    mob_names = sorted(set(name for name, guid in mob_data))
                    mob_names_str = ", ".join(mob_names)
                    if current_combat_has_known_pack:
                        print(f"# Skipping {current_combat_unknown_pack_name} ({mob_names_str}) because combat had known mobs", file=sys.stderr)
                    else:
                        print(f"# {current_combat_unknown_pack_name}: {mob_names_str}", file=sys.stderr)

                # Commit current combat deaths to pack encounters
                for pack_name, death_times in current_combat_deaths.items():
                    if death_times:
                        # Skip unknown packs if this combat had any known packs
                        if current_combat_has_known_pack and pack_name.startswith("unknown_"):
                            continue

                        pack_encounters[pack_name]['engage_time'] = current_engage_time
                        pack_encounters[pack_name]['deaths'].extend(death_times)
                        pack_encounters[pack_name]['mob_data'].extend(current_combat_mob_data[pack_name])
                        if pack_encounters[pack_name]['time_since_last_combat'] is None:
                            pack_encounters[pack_name]['time_since_last_combat'] = current_time_since_last_combat

                last_regen_enabled_time = timestamp
                current_engage_time = None
                current_combat_deaths = defaultdict(list)
                current_combat_mob_data = defaultdict(list)
                current_time_since_last_combat = None
                current_combat_unknown_guids = set()
                current_combat_unknown_pack_name = None
                current_combat_has_known_pack = False
                player_just_died = False

            # Handle deaths
            elif event_part.startswith("UNIT_DIED:"):
                # Parse UNIT_DIED:Name:GUID
                death_match = re.match(r'UNIT_DIED:([^:]+):(0x[A-F0-9]+)', event_part)
                if death_match:
                    mob_name = death_match.group(1)
                    guid = death_match.group(2)

                    # Skip player and summoned mob GUIDs
                    if should_ignore_guid(guid):
                        continue

                    # Look up pack name from GUID
                    pack_name = guid_to_pack.get(guid)

                    # Check if this is a known pack
                    if pack_name:
                        current_combat_has_known_pack = True

                    if not pack_name:
                        # GUID not found - group all unknowns in this combat together
                        if guid not in unknown_guid_map:
                            # Check if we've already created an unknown pack for this combat
                            if current_combat_unknown_pack_name is None:
                                # First unknown GUID in this combat - create new pack
                                current_combat_unknown_pack_name = f"unknown_{unknown_guid_counter}"
                                unknown_guid_counter += 1

                            # Map this GUID to the current combat's unknown pack
                            unknown_guid_map[guid] = current_combat_unknown_pack_name
                            current_combat_unknown_guids.add(guid)

                        pack_name = unknown_guid_map[guid]

                    # Record this death under current engage time
                    if current_engage_time:
                        current_combat_deaths[pack_name].append(timestamp)
                        # Track mob data (name, guid) pairs for this pack
                        # Only add if this specific GUID hasn't been added yet in this combat
                        if not any(data[1] == guid for data in current_combat_mob_data[pack_name]):
                            current_combat_mob_data[pack_name].append((mob_name, guid))

    # Handle any remaining deaths if log ends mid-combat
    if current_engage_time and current_combat_deaths:
        for pack_name, death_times in current_combat_deaths.items():
            if death_times:
                # Skip unknown packs if this combat had any known packs
                if current_combat_has_known_pack and pack_name.startswith("unknown_"):
                    print(f"# Skipping {pack_name} because combat had known mobs", file=sys.stderr)
                    continue

                pack_encounters[pack_name]['engage_time'] = current_engage_time
                pack_encounters[pack_name]['deaths'].extend(death_times)
                pack_encounters[pack_name]['mob_data'].extend(current_combat_mob_data[pack_name])
                if pack_encounters[pack_name]['time_since_last_combat'] is None:
                    pack_encounters[pack_name]['time_since_last_combat'] = current_time_since_last_combat

    return pack_encounters


def format_lua_output(pack_encounters):
    """Format pack encounters as a Lua table."""
    lines = ["-- Generated pack timing data"]
    lines.append("local packTimings = {")

    # Sort by first engage time
    sorted_packs = sorted(
        pack_encounters.items(),
        key=lambda x: x[1]['engage_time'] if x[1]['engage_time'] else ""
    )

    for pack_name, data in sorted_packs:
        if not data['engage_time'] or not data['deaths']:
            continue

        engage_time = data['engage_time']
        death_times = sorted(data['deaths'])
        time_since_last = data.get('time_since_last_combat')
        mob_data = data.get('mob_data', [])

        # Sort mob_data by GUID to ensure consistent ordering
        mob_data_sorted = sorted(mob_data, key=lambda x: x[1])

        # Extract parallel arrays
        mob_names = [name for name, guid in mob_data_sorted]
        mob_guids = [guid for name, guid in mob_data_sorted]

        # Format death times as Lua array
        deaths_str = ', '.join(f'"{dt}"' for dt in death_times)

        # Format mob names as Lua array
        mob_names_str = ', '.join(f'"{name}"' for name in mob_names)

        # Format mob GUIDs as Lua array
        mob_guids_str = ', '.join(f'"{guid}"' for guid in mob_guids)

        lines.append(f'    ["{pack_name}"] = {{')
        lines.append(f'        engageTime = "{engage_time}",')
        lines.append(f'        deathTimes = {{{deaths_str}}},')
        lines.append(f'        mob_names = {{{mob_names_str}}},')
        lines.append(f'        mob_guids = {{{mob_guids_str}}},')
        if time_since_last is not None:
            lines.append(f'        timeSinceLastCombat = {time_since_last:.3f},')
        lines.append(f'    }},')

    lines.append("}")
    lines.append("")
    lines.append("return packTimings")

    return '\n'.join(lines)


def main():
    if len(sys.argv) != 2:
        print("Usage: python generate_pack_timings.py <combat_log.txt>")
        sys.exit(1)

    log_filepath = sys.argv[1]
    output_filepath = "PackTimings.lua"

    # Parse RaidPacks/*.lua files
    raid_packs_dir = "RaidPacks"
    print(f"Parsing raid packs from: {raid_packs_dir}")
    guid_to_pack = parse_raid_packs(raid_packs_dir)
    print(f"Loaded {len(guid_to_pack)} GUID mappings from RaidPacks")

    print(f"Parsing combat log: {log_filepath}")
    pack_encounters = parse_combat_log(log_filepath, guid_to_pack)
    print(f"Found {len(pack_encounters)} pack encounters")

    # Write to PackTimings.lua
    print(f"Writing output to {output_filepath}")
    with open(output_filepath, 'w') as f:
        f.write(format_lua_output(pack_encounters))

    print(f"Success! Pack timings written to {output_filepath}")
    print("You can now paste the contents into TrinketMenu's Import Timings dialog.")


if __name__ == "__main__":
    main()
