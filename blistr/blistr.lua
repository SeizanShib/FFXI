_addon.name = 'Blistr'
_addon.author = 'Seizan (Asura)'
_addon.version = '2.0'
_addon.commands = {'bl','blistr'}
--[[
A blacklist addon that wont blacklist anyone that u havnt added to the blacklist, this is to make sure that you wont miss any yells that 
could be interesting. To add new names to the blist, simply type "//bl add NameToAdd" in the party chat. It is easy to add difficult
names, like Kiimaeaeeaoooonic or something, just do a /sea all Kiim and hit /tell, now u can just replace /sea all with //bl add and hit enter.
]]

packets = require('packets')
local json = require('dkjson')
local blacklist_file = windower.addon_path .. 'blacklist.json'

local names = T{}


-- Function to load the blacklist from file
local function load_blacklist()
    local file = io.open(blacklist_file, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        local decoded = json.decode(content)
        if type(decoded) == 'table' then
            names = T(decoded)
        end
    else
    end
end

-- Call the load function when the addon is loaded
load_blacklist()

-- Function to save the blacklist to file
local function save_blacklist()
    table.sort(names, function(a, b) return a:lower() < b:lower() end)

    local file = io.open(blacklist_file, 'w')
    if file then
        file:write(json.encode(names))  -- Encode the sorted list to JSON and write it to the file
        file:close()
    else
        print("Error opening file for writing.")
    end
end

-- Modify your add_to_blacklist function to save the list after adding a new name
local function add_to_blacklist(name)
    print("Attempting to add name: " .. name) -- Debug print
    local formatted_name = name:sub(1,1):upper() .. name:sub(2):lower()
    if not names:contains(formatted_name) then
        names:append(formatted_name)
        save_blacklist()  -- Save the updated list to file
        windower.add_to_chat(207, 'Added ' .. formatted_name .. ' to blacklist.')
    else
        windower.add_to_chat(207, formatted_name .. ' is already on the blacklist.')
    end
end



windower.register_event('incoming chunk', function(id, data)
    if id == 0x017 then -- 0x017 Is incoming chat.
        local chat = packets.parse('incoming', data)
        local cleaned = windower.convert_auto_trans(chat['Message']):lower()

        if names:contains(chat['Sender Name']) then -- Blocks any message from sucker X user in any chat mode.
            return true
        end 
    end     
end)


-- Register a command handler
windower.register_event('addon command', function(command, ...)
    -- Debug prints
    local args = {...}
    if command == 'add' and args[1] then
        add_to_blacklist(args[1]) -- Pass the argument as is, without converting to lowercase
    end
end)






