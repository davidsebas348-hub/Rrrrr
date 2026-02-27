-- Evitar doble ejecución
if getgenv().AUTO_SYSTEM_LOADED then return end
getgenv().AUTO_SYSTEM_LOADED = true

-- Guardar URL UNA SOLA VEZ
local SCRIPT_URL = "https://raw.githubusercontent.com/davidsebas348-hub/Rrrrr/main/Autofarm.lua"

-- Auto execute al teleport
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet("'..SCRIPT_URL..'"))()')
end

-- FINAL AUTO SYSTEM (FIXED FULL)

local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------
-- SAFE REMOTE
--------------------------------------------------
local function fireLobbyRemote()
    local remote = ReplicatedStorage:FindFirstChild("TPToLobby")
    if remote then
        pcall(function()
            remote:FireServer()
        end)
    end
end

--------------------------------------------------
-- PLACE IDS
--------------------------------------------------
local LOBBY_ID = 87141336196355
local PARTIDA_ID = 97210805647799

local LOBBY_COORD = Vector3.new(15,4,-57)

--------------------------------------------------
-- SAVE SYSTEM
--------------------------------------------------
local filename = "AutoSystem_"..player.UserId..".json"

local state = {
    totalTime = 0,
    guiEscapesHelped = 0
}

pcall(function()
    if isfile and isfile(filename) then
        local data = HttpService:JSONDecode(readfile(filename))
        if type(data) == "table" then
            state.totalTime = tonumber(data.totalTime) or 0
            state.guiEscapesHelped = tonumber(data.guiEscapesHelped) or 0
        end
    end
end)

local totalTime = state.totalTime
local guiEscapesHelped = state.guiEscapesHelped

local function saveState()
    pcall(function()
        if writefile then
            writefile(filename, HttpService:JSONEncode({
                totalTime = totalTime,
                guiEscapesHelped = guiEscapesHelped
            }))
        end
    end)
end

--------------------------------------------------
-- PLAYER HELPERS
--------------------------------------------------
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function findEscapeDoor()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("escape") or n:find("exit") or n:find("finish") then
                return v
            end
        end
    end
end

--------------------------------------------------
-- ESCAPE STAT DETECTOR
--------------------------------------------------
local AutoEscapeActive = false
local assistedUntil = 0
local ASSIST_WINDOW = 6

local escapeStatObj
local escapePrevValue = 0
local statConnection
local lastTP = 0
local TP_COOLDOWN = 5

local function findEscapeStatObject()
    local stats = player:FindFirstChild("leaderstats")
    if not stats then return end

    local e =
        stats:FindFirstChild("Escapes")
        or stats:FindFirstChild("Escape")
        or stats:FindFirstChild("Escaped")

    if e and (e:IsA("IntValue") or e:IsA("NumberValue")) then
        return e
    end

    for _,v in ipairs(stats:GetChildren()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            return v
        end
    end
end

local function connectEscapeStat()

    if statConnection then
        statConnection:Disconnect()
        statConnection = nil
    end

    escapeStatObj = findEscapeStatObject()
    if not escapeStatObj then return end

    escapePrevValue = tonumber(escapeStatObj.Value) or 0

    statConnection = escapeStatObj.Changed:Connect(function(newVal)

        local newNum = tonumber(newVal) or 0

        if newNum > escapePrevValue then

            if AutoEscapeActive or os.time() <= assistedUntil then
                guiEscapesHelped += 1
                saveState()
            end

            if game.PlaceId == PARTIDA_ID then
                if tick() - lastTP > TP_COOLDOWN then
                    lastTP = tick()
                    fireLobbyRemote()
                end
            end
        end

        escapePrevValue = newNum
    end)
end

connectEscapeStat()

player.ChildAdded:Connect(function(c)
    if c.Name == "leaderstats" then
        task.wait(1)
        connectEscapeStat()
    end
end)

--------------------------------------------------
-- AUTO ACTIONS
--------------------------------------------------
local function autoEscape()
    local hrp = getHRP()
    local door = findEscapeDoor()

    if hrp and door then
        AutoEscapeActive = true
        assistedUntil = os.time() + ASSIST_WINDOW

        hrp.CFrame = CFrame.new(door.Position + Vector3.new(0,3,0))

        saveState()

        task.delay(ASSIST_WINDOW,function()
            AutoEscapeActive = false
        end)
    end
end

local function tpToCoord()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(LOBBY_COORD)
    end
end

--------------------------------------------------
-- GET ESCAPES VALUE
--------------------------------------------------
local function getEscapesStatValue()
    local stat = findEscapeStatObject()
    return stat and tonumber(stat.Value) or 0
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = Instance.new("ScreenGui", player.PlayerGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,420,0,240)
frame.Position = UDim2.new(0.5,-210,0.1,0)
frame.BackgroundColor3 = Color3.fromRGB(0,100,200)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 6
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.Text = "SISTEMA AUTO"

local TiempoBtn = Instance.new("TextButton", frame)
TiempoBtn.Size = UDim2.new(0.45,0,0,50)
TiempoBtn.Position = UDim2.new(0.05,0,0,80)
TiempoBtn.BackgroundColor3 = Color3.fromRGB(180,0,0)
TiempoBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- blanco
TiempoBtn.TextScaled = true
TiempoBtn.AutoButtonColor = false

local EscapesBtn = Instance.new("TextButton", frame)
EscapesBtn.Size = UDim2.new(0.45,0,0,50)
EscapesBtn.Position = UDim2.new(0.5,0,0,80)
EscapesBtn.BackgroundColor3 = Color3.fromRGB(0,110,255)
EscapesBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- blanco
EscapesBtn.TextScaled = true
EscapesBtn.AutoButtonColor = false

local GUIEscapesBtn = Instance.new("TextButton", frame)
GUIEscapesBtn.Size = UDim2.new(0.92,0,0,50)
GUIEscapesBtn.Position = UDim2.new(0.04,0,0,140)
GUIEscapesBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
GUIEscapesBtn.TextColor3 = Color3.fromRGB(255, 255, 255) -- blanco
GUIEscapesBtn.TextScaled = true
GUIEscapesBtn.AutoButtonColor = false

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------
local lastTick = tick()
local lastLobbyTP = 0
local autosave = 0

task.spawn(function()
    while true do
        local now = tick()
        local dt = math.clamp(now - lastTick,0,10)
        lastTick = now

        totalTime += dt

        local hrp = getHRP()
        if hrp then
            if game.PlaceId == LOBBY_ID then
                if tick() - lastLobbyTP > 5 then
                    lastLobbyTP = tick()
                    tpToCoord()
                end
            elseif game.PlaceId == PARTIDA_ID then
                autoEscape()
            end
        end

        local t = math.floor(totalTime)
        local d = math.floor(t/86400)
        local h = math.floor(t/3600)%24
        local m = math.floor(t/60)%60
        local s = t%60

        TiempoBtn.Text =
            string.format("Tiempo: %dd %dh %dm %ds",d,h,m,s)

        EscapesBtn.Text =
            "Escapes total: "..getEscapesStatValue()

        GUIEscapesBtn.Text =
            "Escapes conseguidos: "..guiEscapesHelped

        autosave += 1
        if autosave >= 5 then
            autosave = 0
            saveState()
        end

        task.wait(1)
    end
end)
