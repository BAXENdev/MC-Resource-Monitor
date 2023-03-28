
RESOURCE_DISPLAY_PASTE = ""
RESOURCE_MONITOR_PASTE = "QPTY7zDZ"
SAMPLE_PASTE = "1EBnctQD"
FOLDER = "/rscMon/"
RESOURCE_DISPLAY_NAME = "resource_display.lua"
RESOURCE_MONITOR_NAME = "resource_monitor.lua"
SAMPLE_NAME = "monitor.db"
RESOURCE_DISPLAY_PATH = FOLDER .. RESOURCE_DISPLAY_NAME
RESOURCE_MONITOR_PATH = FOLDER .. RESOURCE_MONITOR_NAME
SAMPLE_PATH = FOLDER .. SAMPLE_NAME

function makeFolder ()
    if not fs.exists(FOLDER) then
        fs.makeDir(FOLDER)
    end
end

function download (paste, filepath)
    if fs.exists(filepath) then
        fs.delete(filepath)
    end
    shell.run("pastebin", "get", paste, filepath)
end

function run (folder, program, param)
    shell.setDir(folder)
    shell.run(program, param)
    shell.setDir("/")
end

makeFolder()
if arg[1] == "-m" then
    download(RESOURCE_MONITOR_PASTE, RESOURCE_MONITOR_PATH)
elseif arg[1] == "-d" then
    download(RESOURCE_DISPLAY_PASTE, RESOURCE_DISPLAY_PATH)
elseif arg[1] == "-rm" then
    run(FOLDER, RESOURCE_MONITOR_NAME, arg[2])
elseif arg[1] == "-rd" then
    run(FOLDER, RESOURCE_DISPLAY_NAME, arg[2])
elseif arg[1] == "-s" then
    download(SAMPLE_PASTE, SAMPLE_PATH)
elseif arg[1] == "-dm" then -- INSTALL BOTH
    download(RESOURCE_MONITOR_PASTE, RESOURCE_MONITOR_PATH)
    download(RESOURCE_DISPLAY_PASTE, RESOURCE_DISPLAY_PATH)
else
    print("-m : Install the resource monitor.")
    print("-d : Install the resource dispaly.")
    print("-dm : Instal the resource monitor and display.")
    print("-rm : Run the resource monitor.")
    print("-rd : Run the resource display.")
    print("When running this script with -rd or -rm, you can add -verbose to activate logging.")
    print("EX: setup.lua -rd -verbose")
    print("Rerun this program to get this prompt again.")
end
