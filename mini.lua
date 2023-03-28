
VERBOSE = false
INVENTORIES = nil
DB_PATH = "/monitor.db" -- TODO: test
TAB = "    "
-- TRANSMISSION DATA
MONITOR_NAME = nil
PROTOCOL_NAME = nil
HOST_NAME = nil

function printTable (t, key, value, indent)
    -- t : table | The table to print
    -- key : bool | If true, print the key
    -- value : bool | If true, print value
    for k,v in pairs(t) do
        if key and value then
            print(indent .. k .. " : " .. v)
        elseif key then
            print(indent .. k)
        elseif value then
            print(indent .. v)
        end
    end
end

function printNTable (t, key, value, indentLevel)
    -- t : table | The table to print
    -- key : bool | If true, print the key
    -- value : bool | If true, print value
    -- indentLevel : int | Level to start indentation, recommended is 1
    indentLevel = indentLevel or 1
    local indent = string.rep("-", indentLevel)

    for k,v in pairs(t) do
        if type(v) == "table" then
            printNTable(v, key, value, indentLevel+1)
        else
            if key and value then
                print(indent .. " " .. k .. " : " .. v)
            elseif key then
                print(indent .. " " .. k)
            elseif value then
                print(indent .. " " .. v)
            end
        end
    end
end

function myPrint(str, endLine, indent)
    endLine = endLine or "\n"
    indent = indent or TAB
    io.write(indent .. str .. endLine)
end

function myClearCursor(doClear, cursorX, cursorY)
    -- doClear = doClear or false
    cursorX = cursorX or 1
    cursorY = cursorY or 1

    term.setCursorPos(cursorX, cursorY)
    
    if doClear == "all" then
        term.clear()
    elseif doClear == "line" then
        term.clearLine()
    end
end

function verbosePrint(str)
    if VERBOSE then
        print(str)
    end
end

function setup ()
    local function doFileSetup()
        -- function constants
        PERIPHERAL_NAME = "PERIPHERAL_NAME"
        DISPLAY_NAME = "DISPLAY_NAME"

        local handle = fs.open(DB_PATH)

        MONITOR_NAME = handle.readLine()
        PROTOCOL_NAME = handle.readLine()
        HOST_NAME = handle.readLine()

        local isInventory = false
        local newInventory = nil
        while true do
            local line = handle.readLine()

            -- TODO: test
            if isInventory == false and line == nil then
                break
            elseif isInventory and line == nil then 
                error("File if corrupt!")
            end
            
            -- State Machine for reading database file
            if isInventory == false and line == "INVENTORY" then
                -- Begin reading inventory block -> read peripheral name
                verbosePrint("Found inventory block.")
                isInventory = PERIPHERAL_NAME
                newInventory = {}
            elseif isInventory == PERIPHERAL_NAME then
                -- Read peripheral name -> read custom name
                verbosePrint("Found peripheral name: " .. line)
                newInventory[PERIPHERAL_NAME] = line
                isInventory = DISPLAY_NAME
            elseif isInventory == DISPLAY_NAME then
                -- Read custom -> read item list
                verbosePrint("Found custom name: " .. line)
                newInventory[DISPLAY_NAME] = line
                isInventory = 1
            elseif line == "END INVENTORY" then
                -- End inventory -> begin reading next inventory block
                if newInventory[1] then
                    table.insert(INVENTORIES, newInventory)
                    verbosePrint("Inventory block added: " .. newInventory[PERIPHERAL_NAME])
                else
                    verbosePrint("Inventory block was empty.")
                end
                isInventory = false
                newInventory = {}
            elseif isInventory then
                -- read item list -> read item list
                newInventory[isInventory] = {["ITEM"] = line, ["COUNT"] = -1}
                verbosePrint("Added " .. line .. " to inventory " .. newInventory[PERIPHERAL_NAME])
                isInventory = isInventory + 1
            -- else
                -- Unknown line
            end

        end -- while true

    end -- doFileSetup

    local function setupModem ()
        
    end

    -- file setup -> done
    -- Modem detection
    -- Inventory setup
    
    -- check for file
    -- if found, prompt for file setup
    if pcall(doFileSetup) then
        return
    else
        myPrint("File is corrupt.")
    end
end

function main ()
    if arg[1] == "-verbose" then
        VERBOSE = true
        print(VERBOSE)
    end

    -- inventories = getPeripheralInventory()
    setup()


end

main()

print(string.format("Monitor: %s\nProtocol: %s\nHost: %s\nInventories:", MONITOR_NAME, PROTOCOL_NAME, HOST_NAME))
printNTable(INVENTORIES, true, true)
