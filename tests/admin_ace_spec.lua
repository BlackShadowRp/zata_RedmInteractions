-- Testet die produktive Freigabefunktion isoliert von Datenbank und Spielnatives.
local function read(path)
    local f = assert(io.open(path, "r")); local text = f:read("*a"); f:close(); return text
end
local granted = {}
local env = setmetatable({
    ready = true, resourceReady = true,
    Smoking = {Enabled = function() return true end},
    Config = {Enabled = true, AdminAccess = {
        AllowAdminAce = true, AdminAce = "role.admin",
        AllowScriptAce = true, ScriptAce = "zata.redminteractions",
    }},
    IsPlayerAceAllowed = function(player, ace) assert(player == 7); return granted[ace] == true end,
    -- Diese alten Freigaben dürfen keine Rolle mehr spielen.
    GetPlayerIdentifiers = function() return {"steam:11000011389a5a4"} end,
    GetCharacter = function() return {group="admin"}, {group="superadmin"} end,
    getCharacter = function() return {group="admin"}, {group="superadmin"} end,
}, {__index = _G})
local source = read("server.lua")
local first = assert(source:find("function S.allowed(", 1, true))
local last = assert(source:find("\nend", first, true)) + 3
local code = source:sub(first, last):gsub("^function [%w_%.:]+", "function", 1)
local allowed = assert(load("return " .. code, "production admin gate", "t", env))()
local function check(expected, label) assert(allowed(7) == expected, label) end
check(false, "Keine ACE")
granted["role.admin"] = true; check(true, "Allgemeine Adminrolle")
env.Config.AdminAccess.AllowAdminAce = false; check(false, "Adminweg abgeschaltet")
granted["role.admin"] = nil; granted["zata.redminteractions"] = true
check(true, "Scriptrecht ohne allgemeine Adminrolle")
env.Config.AdminAccess.AllowScriptAce = false; check(false, "Scriptweg abgeschaltet")
env.Config.AdminAccess.AllowAdminAce = true; env.Config.AdminAccess.AllowScriptAce = true
granted = {["zata.admin"]=true, ["zata.redminteractions.admin"]=true}
local access = env.Config.AdminAccess
access.Steam64Whitelist = {"76561198288053668"}
access.VorpCharacterGroups = {"admin", "superadmin", "owner"}
access.VorpUserGroups = {"admin"}
env.Config.Permissions = {Ace="zata.admin", Groups={admin=true}}
env.Config.Admin = {Ace="zata.admin", Groups={admin=true}, RequiredGroup="admin"}
check(false, "Alte ACE, Steam- und VORP-Freigaben bleiben wirkungslos")
access.AdminAce = ""; access.ScriptAce = ""; granted[""] = true
check(false, "Leere ACE darf nicht freigeben")
access.AdminAce = "role.admin"; granted["role.admin"] = true
access.AllowAdminAce = "true"; check(false, "Nur echtes Boolean aktiviert den Weg")
assert(allowed(nil) == false and allowed(-1) == false, "Ungültige Spielerquelle")
assert(allowed(0) == false, "Konsolenverhalten erhalten")
env.Config.AdminAccess = nil; check(false, "Fehlende Konfiguration")
print("PASS: zata_RedmInteractions – zwei ACE-Wege, Schalter, Altrechte gesperrt und Konsole")
