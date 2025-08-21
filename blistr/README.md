# Blistr (Windower addon for FFXI)

Blistr is a small, modern Windower addon that hides chat messages **only** from names you explicitly add to your personal blacklist. It keeps useful yells visible while filtering the noise.

- Precise name filtering (case‑insensitive).
- Per‑channel control (Yell/Shout enabled by default).
- Quick commands: add, delete, list, last, addtarget, on/off.
- Optional text “pattern” filters for common spam phrases.
- No extra dependencies: uses Windower’s `config` (persists to `data/settings.xml`).
- Automatic one‑time migration from legacy `blacklist.json`.
- Export/Import for backups or sharing.

---

## Installation

1. Copy the folder `blistr` to `Windower4/addons/`.
2. Ensure `Windower4/addons/blistr/blistr.lua` exists (the new v3 file).
3. Optional: if you have an old `blacklist.json`, keep it in the same folder for the first load. Blistr will migrate names automatically.
4. Launch the game via Windower and load the addon:
5. Run `//bl help` to see the command list.

To autoload the addon, add this line to `Windower/scripts/init.txt`:

---

## Quick start

```text
//bl add <Name>          Add a name to your blacklist
//bl del <Name>          Remove a name
//bl list                Show all blacklisted names
//bl last [channel]      Add the last sender in that channel (default: yell)
//bl addtarget           Add the currently targeted player
//bl on | off            Enable/disable filtering
//bl chan <channel> <on|off>   Toggle filtering per channel
//bl pat add <text>      Add a substring pattern for content filtering
//bl pat del <text>      Remove a pattern
//bl pat list            List all patterns
//bl export              Export names to data/blistr-export-YYYYMMDD.json
//bl import              Import from data/blistr-import.json

---
Supported channel keys

yell, shout, say, tell, party, alliance, ls1, ls2, unity, bazaar, emote
By default, only yell and shout are enabled.
---
//bl chan yell on
//bl chan shout on
//bl chan say off



