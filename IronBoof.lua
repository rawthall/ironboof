local playerName = UnitName("player")
local IronBoof = CreateFrame("Frame")
IronBoof:RegisterEvent("PLAYER_DEAD")
IronBoof:RegisterEvent("ADDON_LOADED")
IronBoof:RegisterEvent("PLAYER_LOGIN")

local deathCount = 0
local totalGoldPaid = 0

local function FormatGold(value)
    return string.format("%.2f", value)
end

local function GetGoldPayable(level)
    if level < 10 then
        return 0
    end
    return (level^3) / 10000
end

local function SendMessage(message)
    if IsInGuild() then
        SendChatMessage(message, "GUILD")
    else
        print(message)
    end
end

local function OnPlayerDead()
    deathCount = deathCount + 1
    local payableGold = 0
    local inInstance = IsInInstance()

    if not inInstance then
        payableGold = GetGoldPayable(UnitLevel("player"))
        totalGoldPaid = totalGoldPaid + payableGold
    end

    local message
    if inInstance then
        message = string.format("%s has died. No gold is payable as this fool died inside an instance.", playerName)
    elseif payableGold > 0 then
        message = string.format("%s has died. %s gold is payable. %s has died a total of %d times and paid a total of %s gold.",
            playerName,
            FormatGold(payableGold),
            playerName,
            deathCount,
            FormatGold(totalGoldPaid))
    else
        message = string.format("%s has died. No gold is payable as they are too weak.", playerName)
    end

    SendMessage(message)

    IronBoof_SaveData()
end


local function OnAddonLoaded(name)
    if name ~= "IronBoof" then return end

    if not IronBoofDB then
        IronBoofDB = {}
    end

    if not IronBoofDB[playerName] then
        IronBoofDB[playerName] = {
            deathCount = 0,
            totalGoldPaid = 0
        }
    end

    deathCount = IronBoofDB[playerName].deathCount
    totalGoldPaid = IronBoofDB[playerName].totalGoldPaid
end

local function OnPlayerLogin()
    OnAddonLoaded("IronBoof")

    local welcomeMessage = string.format("Welcome, %s! IronBoof is currently tracking your deaths and gold paid. You have died a total of %d times and paid a total of %s gold. To report your stats, use the /ironboof command.",
        playerName,
        deathCount,
        FormatGold(totalGoldPaid))
    print(welcomeMessage)
end


function IronBoof_SaveData()
    IronBoofDB[playerName] = {
        deathCount = deathCount,
        totalGoldPaid = totalGoldPaid
    }
end

local function OnEvent(self, event, ...)
    if event == "PLAYER_DEAD" then
        OnPlayerDead()
    elseif event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin()
    end
end

IronBoof:SetScript("OnEvent", OnEvent)

SLASH_IRONBOOF1 = "/ironboof"
SlashCmdList["IRONBOOF"] = function(msg)
    local message = string.format("%s has died a total of %d times and paid a total of %s gold.",
        playerName,
        deathCount,
        FormatGold(totalGoldPaid))
    SendMessage(message)
end
