--[[
Blistr - personlig svarteliste for FFXI/Windower
  - Blokkerer meldinger fra navn du selv har lagt inn (default: kun Yell/Shout)
  - Bevarer resten av chatten så du ikke mister nyttige rop
  - Enkle kommandoer: add/del/list, on/off, chan, last, addtarget, patterns, export/import

Installasjon:
  1) Legg denne fila som Windower/addons/blistr/blistr.lua
  2) /console lua l blistr
  3) Skriv //bl help for hjelp

Forfatter: Seizan (Asura) – modernisert
Versjon: 3.0
]]

_addon.name     = 'Blistr'
_addon.author   = 'Seizan (modernisert)'
_addon.version  = '3.0'
_addon.commands = {'bl','blistr'}

require('tables')
require('sets')
require('strings')
local logger   = require('logger')
local config   = require('config')
local packets  = require('packets')
local res      = require('resources')

-- ---------- Innstillinger (lagres automatisk til data/settings.xml) ----------
local defaults = {
    enabled  = true,

    -- Hvilke kanaler skal Blistr få lov å filtrere?
    -- (Default: bare yell/shout – så du mister minst mulig annet.)
    channels = {
        yell      = true,
        shout     = true,
        say       = false,
        tell      = false,
        party     = false,
        alliance  = false,
        ls1       = false,
        ls2       = false,
        unity     = false,
        bazaar    = false,
        emote     = false,
        shout_robust = true, -- noen server-meldinger bruker varianter; lar det stå her for fremtid
    },

    -- Navn og tekstmønstre lagres som vanlige lister (serialiserbare)
    names    = {},           -- lagres lowercase i fil
    patterns = {},           -- substrings (case-insensitive). Eks: "www", "gil", "discord.gg/"
    case_insensitive_patterns = true,
}

local settings = config.load(defaults)

-- Interne strukturer (sett for rask oppslagstid)
local name_set = S{}
for _, n in ipairs(settings.names or {}) do
    name_set:add(n:lower())
end

-- Sist observerte avsender pr kanal (for //bl last)
local last_sender = {}

-- ---------- Hjelpefunksjoner ----------

local function save_names()
    -- legg set -> sortert liste og lagre
    local tmp = T{}
    for n in name_set:it() do tmp:append(n) end
    table.sort(tmp)
    settings.names = tmp
    settings:save()
end

local function nice_name(raw)
    if not raw or raw == '' then return nil end
    raw = raw:lower()
    return raw:gsub("^%l", string.upper)
end

local function norm_channel_name(en)
    en = (en or ''):lower()
    -- normaliser kjente varianter
    if en == 'linkshell' then return 'ls1' end
    if en == 'linkshell 2' or en == 'linkshell2' then return 'ls2' end
    if en == 'yell' or en == 'shout' or en == 'say' or en == 'tell'
        or en == 'party' or en == 'alliance' or en == 'emote'
        or en == 'unity' or en == 'bazaar' then
        return en
    end
    -- fallback: bruk det som kom
    return en
end

local function channel_enabled(mode_id)
    local entry = res.chat[mode_id]
    local en    = entry and (entry.en or entry.english) or ''
    local key   = norm_channel_name(en)
    return settings.channels[key] == true, key
end

local function matches_pattern(msg)
    if not msg or #settings.patterns == 0 then return false end
    local hay = settings.case_insensitive_patterns and msg:lower() or msg
    for _, p in ipairs(settings.patterns) do
        local needle = settings.case_insensitive_patterns and tostring(p):lower() or tostring(p)
        if needle ~= '' and hay:find(needle, 1, true) then
            return true
        end
    end
    return false
end

local function color(msg) windower.add_to_chat(207, ('[Blistr] %s'):format(msg)) end
local function warn(msg)  windower.add_to_chat(123, ('[Blistr] %s'):format(msg)) end

-- ---------- Kjerne: filtrer innkommende chat (pkt 0x017) ----------
windower.register_event('incoming chunk', function(id, data)
    if id ~= 0x017 then return end
    local chat = packets.parse('incoming', data)
    if not chat then return end

    local sender = chat['Sender Name']
    local mode   = chat['Mode']
    local msg    = windower.convert_auto_trans(chat['Message'] or '')

    -- track siste avsender pr. kanal for //bl last
    local _, key = channel_enabled(mode)
    if key and sender and sender ~= '' then
        last_sender[key] = sender
    end

    -- Ikke filtrer hvis addon er av
    if not settings.enabled then return end

    local allowed, key2 = channel_enabled(mode)
    if not allowed then return end

    -- 1) Navnefilter (personlig svarteliste)
    if sender and name_set:contains(sender:lower()) then
        return true -- blokker
    end

    -- 2) Valgfritt innholdsfilter (enkle substrings)
    if matches_pattern(msg) then
        return true
    end
end)

-- ---------- Kommandoer ----------
local function print_help()
    color('Kommandoer:')
    color('//bl add <Navn>        – legg til i svartelista (case-insensitive)')
    color('//bl del <Navn>        – fjern fra svartelista')
    color('//bl last [kanal]      – legg til siste avsender i kanal (default: yell)')
    color('//bl addtarget         – legg til spilleren du har i target')
    color('//bl list              – list alle blokkerte navn')
    color('//bl on | off          – aktiver/deaktiver Blistr')
    color('//bl chan <kanal> <on|off>  – styr hvilke kanaler som filtreres (yell, shout, say, tell, party, alliance, ls1, ls2, unity, bazaar, emote)')
    color('//bl pat add <tekst>   – legg til tekstmønster (substreng) for innholdsfilter')
    color('//bl pat del <tekst>   – fjern tekstmønster')
    color('//bl pat list          – list alle mønstre')
    color('//bl export            – skriv backup til data/blistr-export-YYYYMMDD.json')
    color('//bl import            – les og merge fra data/blistr-import.json (en linje per navn)')
end

local function add_name(raw)
    if not raw or raw == '' then warn('Bruk: //bl add <Navn>'); return end
    local lc = raw:lower()
    if name_set:contains(lc) then
        color(('%s er allerede svartelistet.'):format(nice_name(raw)))
        return
    end
    name_set:add(lc); save_names()
    color(('La til %s i svartelista.'):format(nice_name(raw)))
end

local function del_name(raw)
    if not raw or raw == '' then warn('Bruk: //bl del <Navn>'); return end
    local lc = raw:lower()
    if name_set:contains(lc) then
        name_set:remove(lc); save_names()
        color(('Fjernet %s fra svartelista.'):format(nice_name(raw)))
    else
        color(('%s finnes ikke i lista.'):format(nice_name(raw)))
    end
end

local function list_names()
    local arr = T{}
    for n in name_set:it() do arr:append(nice_name(n)) end
    table.sort(arr)
    if #arr == 0 then color('Svartelista er tom.') return end
    color('Svartelistede navn ('..#arr..'):')
    local line = ''
    for i, n in ipairs(arr) do
        line = line .. n .. (i % 10 == 0 and '\n' or ', ')
    end
    windower.add_to_chat(207, line:gsub(', $',''))
end

local function add_last(which)
    which = (which or 'yell'):lower()
    local sender = last_sender[which]
    if not sender then warn('Ingen sistesender lagret for kanal: '..which) return end
    add_name(sender)
end

local function add_target()
    local t = windower.ffxi.get_mob_by_target('t')
    if t and t.name and not t.is_npc then
        add_name(t.name)
    else
        warn('Ingen spiller i target.')
    end
end

local function set_channel(chan, state)
    chan = (chan or ''):lower()
    if settings.channels[chan] == nil then
        warn('Ukjent kanal: '..chan)
        return
    end
    local on = (state == 'on' or state == 'true' or state == '1')
    settings.channels[chan] = on
    settings:save()
    color(('Filtrering for %s: %s'):format(chan, on and 'ON' or 'OFF'))
end

local function pat_add(txt)
    if not txt or txt == '' then warn('Bruk: //bl pat add <tekst>'); return end
    table.insert(settings.patterns, txt)
    settings:save()
    color(('La til mønster: "%s"'):format(txt))
end

local function pat_del(txt)
    if not txt or txt == '' then warn('Bruk: //bl pat del <tekst>'); return end
    local i = 1
    local removed = false
    while i <= #settings.patterns do
        if settings.patterns[i]:lower() == txt:lower() then
            table.remove(settings.patterns, i)
            removed = true
        else
            i = i + 1
        end
    end
    settings:save()
    color(removed and ('Fjernet "%s".'):format(txt) or ('Fant ikke "%s".'):format(txt))
end

local function pat_list()
    if #settings.patterns == 0 then color('Ingen mønstre.') return end
    color('Mønstre (substreng, '..(#settings.case_insensitive_patterns and 'case-insensitive' or 'case-sensitive')..') :')
    for i, p in ipairs(settings.patterns) do
        windower.add_to_chat(207, ('  %2d) %s'):format(i, p))
    end
end

local function export_list()
    local path = windower.addon_path..'data/blistr-export-'..os.date('%Y%m%d')..'.json'
    local f = io.open(path, 'w')
    if not f then warn('Kunne ikke skrive: '..path) return end
    local tmp = T{}
    for n in name_set:it() do tmp:append(n) end
    table.sort(tmp)
    f:write('{ "names": ['..table.concat(tmp:map(function(s) return ('"%s"'):format(s) end), ', ')..'] }')
    f:close()
    color('Eksportert til '..path)
end

local function import_list()
    local path = windower.addon_path..'data/blistr-import.json'
    local f = io.open(path, 'r')
    if not f then warn('Legg en fil på '..path..' (enten JSON { "names": [...] } eller ren tekst m/ ett navn per linje).') return end
    local content = f:read('*a'); f:close()
    local added = 0
    -- enkel parser: prøv JSON-array først, ellers linje for linje
    local names = T{}
    for n in content:gmatch('"([^"]+)"') do names:append(n) end
    if #names == 0 then
        for line in content:gmatch('[^\r\n]+') do
            if line:match('%S') then names:append(line:match('^%s*(.-)%s*$')) end
        end
    end
    for _, n in ipairs(names) do
        local lc = n:lower()
        if not name_set:contains(lc) then
            name_set:add(lc); added = added + 1
        end
    end
    if added > 0 then save_names() end
    color(('Import fullført. La til %d nye navn.'):format(added))
end

windower.register_event('addon command', function(cmd, ...)
    cmd = (cmd or 'help'):lower()
    local args = {...}

    if cmd == 'help' then
        print_help()

    elseif cmd == 'add' and args[1] then
        add_name(args[1])

    elseif (cmd == 'del' or cmd == 'remove' or cmd == 'rm') and args[1] then
        del_name(args[1])

    elseif cmd == 'list' then
        list_names()

    elseif cmd == 'last' then
        add_last(args[1])  -- default 'yell'

    elseif cmd == 'addtarget' or cmd == 'addt' then
        add_target()

    elseif cmd == 'on' or cmd == 'off' then
        settings.enabled = (cmd == 'on'); settings:save()
        color('Blistr: '..(settings.enabled and 'ON' or 'OFF'))

    elseif cmd == 'chan' and args[1] and args[2] then
        set_channel(args[1], args[2])

    elseif cmd == 'pat' and args[1] then
        local sub = args[1]:lower()
        if sub == 'add' then pat_add(args[2])
        elseif sub == 'del' then pat_del(args[2])
        elseif sub == 'list' then pat_list()
        else warn('Bruk: //bl pat add|del|list')
        end

    elseif cmd == 'export' then
        export_list()

    elseif cmd == 'import' then
        import_list()

    else
        print_help()
    end
end)

-- Ved lasting: enkel migrering fra gammel blacklist.json (om den finnes)
windower.register_event('load', function()
    local legacy = windower.addon_path..'blacklist.json'
    local f = io.open(legacy, 'r')
    if f then
        local c = f:read('*a'); f:close()
        local imported = 0
        for n in c:gmatch('"([^"]+)"') do
            local lc = n:lower()
            if not name_set:contains(lc) then name_set:add(lc); imported = imported + 1 end
        end
        if imported > 0 then
            save_names()
            color(('Migrerte %d navn fra blacklist.json → data/settings.xml. Du kan slette blacklist.json.'):format(imported))
        end
    end
end)
