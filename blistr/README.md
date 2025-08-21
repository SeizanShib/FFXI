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
