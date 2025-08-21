
```markdown
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
```

//lua l blistr

```
5. Run `//bl help` to see the command list.

To autoload the addon, add this line to `Windower/scripts/init.txt`:
```

lua l blistr

````

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
````

### Supported channel keys

`yell`, `shout`, `say`, `tell`, `party`, `alliance`, `ls1`, `ls2`, `unity`, `bazaar`, `emote`
By default, only `yell` and `shout` are enabled.

Examples:

```text
//bl chan yell on
//bl chan shout on
//bl chan say off
```

---

## How it works

Blistr intercepts incoming chat (packet `0x017`) and, if enabled, filters messages in the channels you have allowed it to manage:

1. Name filter: if the sender’s name is in your blacklist set, the message is hidden.
2. Optional pattern filter: if any configured substring matches the message text (case‑insensitive by default), the message is hidden.

Everything else is displayed normally.

---

## Configuration and storage

* Settings are saved to: `Windower4/addons/blistr/data/settings.xml` (created automatically).
* Defaults:

  * `enabled: true`
  * `channels`: `yell=true`, `shout=true`; all others `false`
  * `patterns`: empty list
  * `case_insensitive_patterns: true`

You can change `case_insensitive_patterns` directly in `settings.xml` if you prefer case‑sensitive pattern matching.

---

## Migration from older versions

If `blacklist.json` exists next to `blistr.lua` on first load, Blistr v3 will import names and store them in `data/settings.xml`.
After you see the migration message in chat, you can delete `blacklist.json` and any old files such as `dkjson.lua` or `dkjson-master/`.

---

## Export / Import

* **Export**: `//bl export` creates `data/blistr-export-YYYYMMDD.json` with your names.
* **Import**: place `data/blistr-import.json` and run `//bl import`.

The import file can be either:

* JSON:

  ```json
  { "names": ["name1", "name2"] }
  ```
* Plain text: one name per line.

---

## Troubleshooting

* **“Unknown command //bl …”**
  The addon is not loaded. Run `//lua l blistr` and verify `blistr.lua` is in `addons/blistr/`.

* **No migration message**
  Ensure `blacklist.json` is in `addons/blistr/` and that Windows shows file extensions (the file must truly be `blacklist.json`).

* **Too much or too little filtering**
  Adjust per‑channel toggles with `//bl chan <channel> <on|off>` and review patterns with `//bl pat list`.

---

## Performance and scope

Blistr filters client‑side only. It does not report users or alter server traffic. Name lookups use set structures for O(1) performance; the CPU cost is negligible.

---

## Repository structure

```
addons/
  blistr/
    blistr.lua                 # addon source (v3)
    data/
      settings.xml             # created automatically on first load
    blacklist.json             # legacy import (optional, first load only)
```

---

## Changelog

**v3.0**

* Switched to Windower `config` storage (`data/settings.xml`)
* Per‑channel enable/disable
* `last` and `addtarget` helpers
* Optional substring pattern filter
* Export/Import
* Automatic migration from `blacklist.json`
* Removed `dkjson` dependency and legacy files

---

## License and credits

* Original idea/code: Seizan (Asura)
* Modernized: same author, 2025
* Suggested license: MIT (add a `LICENSE` file if you want to formalize this)

```
