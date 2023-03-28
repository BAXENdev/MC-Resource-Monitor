-- https://pastebin.com/QPTY7zDZ

-- computer display is 50 x 16 (width x height in characters)

-- GLOBAL VARIABLES ------------------------------------------------------

FOLDER = "/rscMon/"

VERBOSE = false
VERBOSE_FILE = nil
VERBOSE_FILE_PATH = FOLDER .. "log.txt"
DB_PATH = FOLDER .. "monitor.db" -- TODO: test
-- TAB DATA
CONSOLE_X = 50
TAB = "    "
-- TRANSMISSION DATA
MONITOR_NAME = nil
PROTOCOL_NAME = nil
MODEM_PERIPHERAL = nil
HOST_NAME = nil
HOST_ID = nil
-- Inventory Variables
INVENTORIES = {}
PERIPHERAL_NAME = "PERIPHERAL_NAME"
DISPLAY_NAME = "DISPLAY_NAME"
BEGIN_INVENTORY = "INVENTORY"
END_INVENTORY = "END INVENTORY"
READ_ITEMS = "READ_ITEMS"
ALL = "ALL"
ITEM = "ITEM"
COUNT = "COUNT"

-- END GLOBAL VARIABLES --------------------------------------------------

-- PRINT FUNCTIONS -------------------------------------------------------

function wrap(str, limit)
    limit = limit or 72
    local here = 1

    -- the "".. is there because :gsub returns multiple values
    return ""..str:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)
            if fi-here > limit then
                here = st
                return "\n"..word
            end
        end)
end -- wrap

function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end -- mysplit

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
end -- printTable

function printNTable (t, key, value, indentLevel)
    -- t : table | The table to print
    -- key : bool | If true, print the key
    -- value : bool | If true, print value
    -- indentLevel : int | Level to start indentation, recommended is 1
    indentLevel = indentLevel or 1
    local indent = string.rep("-", indentLevel)

    for k,v in pairs(t) do
        io.write(indent .. " ")
        if key then
            io.write(k .. ": ")
        end
        if value then
            if type(v) == "table" then
                io.write("\n")
                printNTable(v, key, value, indentLevel + 1)
            else
                io.write(v .. "\n")
            end
        end
    end
end -- printNTable

function myPrint(str, endLine, indent)
    endLine = endLine or "\n"
    indent = indent or TAB
    local strs = mysplit(wrap(str, CONSOLE_X - (#indent * 2)), "\n")
    for _,s in pairs(strs) do
        io.write(indent .. s .. endLine)
    end
end -- myPrint

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
end -- myClearCursor

function verbosePrint (str)
    if VERBOSE then
        VERBOSE_FILE.write(str)
    end
end -- verbosePrint

function printErrorMessage (err)
    _, indexEnd = string.find(err, ":%d*: ")
    errorMessage = string.sub(err, indexEnd + 1)
    print(errorMessage)
end -- printErrorMessage

-- END PRINT FUNCTIONS ---------------------------------------------------

-- HELPER FUNCTIONS ------------------------------------------------------

function doFileSetup ()
    -- Setup program variables
    local handle = fs.open(DB_PATH, "r")

    MONITOR_NAME = handle.readLine()
    PROTOCOL_NAME = handle.readLine()
    HOST_NAME = handle.readLine()
    MODEM_PERIPHERAL = handle.readLine()

    if not (MONITOR_NAME and PROTOCOL_NAME and HOST_NAME and MODEM_PERIPHERAL) then
        errMessage = ""
        if not MONITOR_NAME then
            errMessage = errMessage .. "File ended before MONITOR_NAME was read.\n"
        end
        if not PROTOCOL_NAME then
            errMessage = errMessage .. "File ended before PROTOCOL_NAME was read.\n"
        end
        if not HOST_NAME then
            errMessage = errMessage .. "File ended before HOST_NAME was read.\n"
        end
        if not MODEM_PERIPHERAL then
            errMessage = errMessage .. "File ended before MODEM_PERIPHERAL was read.\n"
        end
        error(errMessage)
    end

    verbosePrint(string.format("Monitor Name: %s\nProtocol Name: %s\nHost Name: %s\n" .. 
        "Modem Name: %s", MONITOR_NAME, PROTOCOL_NAME, HOST_NAME, modemName))

    -- Setup inventory
    local line = nil
    local isInventory = false
    local newInventory = nil
    while true do -- read file
        line = handle.readLine() -- returns nil (false) when end of file
        if not line and isInventory then -- break loop if end of file
            error("File ended in the middle of a inventory block.")
        elseif not line then
            break
        end

        -- the first if is line NOT EQUAL , marked below. The third if is EQUALS
        --                         -v-
        if (not isInventory) and line ~= BEGIN_INVENTORY then
            -- 
        elseif line == "" then
            -- do nothing.
        elseif not isInventory and line == BEGIN_INVENTORY then
            newInventory = {}
            isInventory = PERIPHERAL_NAME
        elseif isInventory == PERIPHERAL_NAME then
            newInventory[PERIPHERAL_NAME] = line
            isInventory = DISPLAY_NAME
        elseif isInventory == DISPLAY_NAME then
            newInventory[DISPLAY_NAME] = line
            isInventory = READ_ITEMS
        elseif line == END_INVENTORY then
            table.insert(INVENTORIES, newInventory)
            newInventory = nil
            isInventory = false
        elseif line == ALL then
            newInventory[ALL] = ALL
            table.insert(INVENTORIES, newInventory)
            newInventory = nil
            isInventory = false
        elseif isInventory == READ_ITEMS then
            table.insert(newInventory, {[ITEM]=line, [COUNT]=-1})
        end
    end -- while true (read file)

    -- setup modem

    -- Setup rednet
    if pcall(function () rednet.open(MODEM_PERIPHERAL) end) then
        HOST_ID = rednet.lookup(PROTOCOL_NAME, HOST_NAME)
        if not HOST_ID then
            myPrint("No host found. Press any key to continue setup.")
            verbosePrint(string.format("Host: %s & Protocol: %s  did not return a HostID when performing lookup."))
            io.input()
        end
    else
        ("Modem name " .. modemName .. " not found for rednet.")
    end
    
    -- test inventories
    local modem = peripheral.wrap(MODEM_PERIPHERAL)
    local errMessages = {}
    for _,inventory in ipairs(INVENTORIES) do
        local displayPeripheral = inventory[PERIPHERAL_NAME]
        if not modem.isPresent(displayPeripheral) then
            verbosePrint(string.format("Inventory %s was not found.", displayPeripheral))
        end
    end
end -- doFileSetup

-- END HELPER FUNCTIONS --------------------------------------------------

-- MAIN FUNCTIONS --------------------------------------------------------

function setup ()
    local status, response = pcall(doFileSetup)
    if not status then
        printErrorMessage(response)
    else
        return
    end
end

function commandLineArgs ()
    
end

function readItems()

end

function transmit ()

end

function main ()
    if arg[1] == "-verbose" then
        VERBOSE = true
        VERBOSE_FILE = fs.open(VERBOSE_FILE_PATH, "w")
        print("VERBOSE ACTIVE")
    end

    setup()
end

main()

print(string.format("Monitor: %s\nProtocol: %s\nHost: %s\nModem: %s\nInventories:", MONITOR_NAME, PROTOCOL_NAME, HOST_NAME, MODEM_PERIPHERAL))
printNTable(INVENTORIES, true, true)
