﻿local VERSION = '1.2.0'

--[[
 | LuaRT - A Windows programming framework for Lua
 | Luart.org, Copyright (c) Tine Samir 2022.
 | See Copyright Notice in LICENSE.TXT
 |-------------------------------------------------
 | install.wlua | LuaRT setup script
--]]



local ui = require "ui"
local compression = require "compression"

local File = embed == nil and sys.File  or embed.File

local win = ui.Window("", "raw", 320, 240)
win.font = "Segoe UI"
win.installation = false

local x = ui.Label(win, "\xc3\x97", 378, -4)
x.fontsize = 16
x.fgcolor = 0x808080
x.cursor = "hand"

function x:onHover()
    x.fgcolor = 0x202020
end

function x:onLeave()
    x.fgcolor = 0x808080
end

function x:onClick()
    if not (win.installation and ui.confirm("Installation is in progress. Are you really want to quit ?", "LuaRT installation") ~= "yes" or false) then
        win.visible = false
    end
end

local img = ui.Picture(win, File("img/luaRT.png").fullpath, 0, 20)
win.width = img.width
win.bgcolor = 0xFFFFFF
win:center()

local button = ui.Button(win, "Install LuaRT "..VERSION)
button:loadicon(File("img/install.ico"))
button.cursor = "hand"
button:center()
button.y = win.height-40

local reg = {
    DisplayName = "LuaRT - Windows programming framework for Lua",
    DisplayVersion = VERSION,
    HelpLink = "https://www.luart.org",
    NoModify = 1,
    NoRepair = 1,
    Publisher = "Samir Tine"
}

local function shortcut(name, target, icon)
    local shell = sys.COM("WScript.Shell")
    local shortcut = shell:CreateShortcut(startmenu_dir.fullpath.."/"..name..".lnk")
    shortcut.TargetPath = target
    shortcut.IconLocation = icon or (target..",0")
    shortcut:Save()
end

function button:onClick()
    local dir = ui.dirdialog("Select a directory to install LuaRT")
    if dir ~= nil then
        win.installation = true
        local label = ui.Label(win, "", 40, 188)
        label.autosize = false        
        label.fontsize = 8
        label.width = 312
        label.textalign = "left"
        label.fgcolor = 0x002A5A
        local bar = ui.Progressbar(win, true, 40, 170, 312)
        bar.fgcolor = 0xEFB42C
        bar.bgcolor = 0xFFFFFF
        local archive = compression.Zip(File("luaRT.zip"))
        bar.range = {0, archive.count}
        local size = 0
        self:hide()
        for entry in each(archive) do
            local fname = entry:gsub('/', '\\')
            label.text = "Extracting "..fname:sub(1, 40).."..."
            local result = archive:extract(entry, dir)
            if not result then
                error("Error extracting "..fname.."\n"..(sys.error or ""))
            end
            bar:advance(1)
            ui.update()
        end
        archive:close()
        local user_path = sys.registry.read("HKEY_CURRENT_USER", "Environment", "Path", false) or ""
        user_path = user_path:gsub(dir.fullpath.."\\bin;", "")
        sys.registry.write("HKEY_CURRENT_USER", "Environment", "Path", user_path..";"..dir.fullpath.."\\bin", true)
        reg.InstallLocation = dir.fullpath;
        reg.DisplayIcon = dir.fullpath.."\\LuaRT-remove.exe,-103"
        reg.UninstallString = dir.fullpath.."\\LuaRT-remove.exe"
        for key, value in pairs(reg) do
            sys.registry.write("HKEY_CURRENT_USER", "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\LuaRT", key, value);
        end
        -- Register *.lua file association
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\.lua", nil, "lua");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\lua", nil, "Lua script");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\lua\\DefaultIcon", nil, dir.fullpath.."\\LuaRT-remove.exe,-102");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\lua\\shell\\open\\command", nil, '"'..dir.fullpath..'\\bin\\luart.exe" "%1"');
        
        -- Register *.wlua file association
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\.wlua", nil, "wlua");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\wlua", nil, "Lua script");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\wlua\\DefaultIcon", nil, dir.fullpath.."\\LuaRT-remove.exe,-102");
        sys.registry.write("HKEY_CURRENT_USER", "Software\\Classes\\wlua\\shell\\open\\command", nil, '"'..dir.fullpath..'\\bin\\wluart.exe" "%1"');

        -- Create shortcuts
        startmenu_dir = sys.Directory(sys.env.USERPROFILE.."\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\LuaRT")
        if not startmenu_dir.exists then
            startmenu_dir:make()
        end
        shortcut("QuickRT", dir.fullpath.."\\QuickRT\\QuickRT.exe")
        shortcut("LuaRT Studio", dir.fullpath.."\\LuaRT-Studio\\LuaRT Studio.exe")
        shortcut("LuaRT Documentation", "https://luart.org/doc/index.html", sys.env.windir.."\\system32\\shell32.dll, 13")
        win.installation = false
        label.textalign = "center"
        label.text = "LuaRT "..VERSION.." has been successfully installed"
    end
end

win:show()

while win.visible do
    ui.update()
end 
