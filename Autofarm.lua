-- FINAL: cuenta escapes ayudados solo cuando la stat real sube mientras la GUI/autoEscape está activa
local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- PlaceId
local LOBBY_ID = 87141336196355
local PARTIDA_ID = 97210805647799

-- Coordenadas para Lobby
local LOBBY_COORD = Vector3.new(15,4,-57)

-- Persistencia (guardamos totalTime en segundos y guiEscapesHelped)
local filename = "AutoSystem_"..player.UserId..".json"
local state = { totalTime = 0, guiEscapesHelped = 0 }
pcall(function()
    if isfile and isfile(filename) then
        local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(filename)) end)
        if ok and type(dec) == "table" then
            state.totalTime = tonumber(dec.totalTime) or 0
            state.guiEscapesHelped = tonumber(dec.guiEscapesHelped) or 0
        end
    end
end)

local totalTime = state.totalTime
local guiEscapesHelped = state.guiEscapesHelped

local function saveState()
    pcall(function()
        if writefile then
            writefile(filename, HttpService:JSONEncode({ totalTime = totalTime, guiEscapesHelped = guiEscapesHelped }))
        end
    end)
end

-- Helpers jugador
local function getHRP()
    local c = player.Character
    return (c and c:FindFirstChild("HumanoidRootPart")) or nil
end

local function findEscapeDoor()
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = (v.Name or ""):lower()
            if n:find("escape") or n:find("exit") or n:find("finish") then
                return v
            end
        end
    end
    return nil
end

-- Variables para detectar asistencias
local AutoEscapeActive = false
local assistedUntil = 0 -- os.time() until which a stat increase counts as assisted
local ASSIST_WINDOW = 6 -- segundos de margen para que el stat update que sigue a un teleport se considere asistido

-- Detect/choose the player's "escape" stat (blue) and optionally another stat for GUI (but we use changed event)
local function findEscapeStatObject()
    local stats = player:FindFirstChild("leaderstats")
    if not stats then return nil end
    -- prefer exact "Escapes"
    local e = stats:FindFirstChild("Escapes") or stats:FindFirstChild("Escape") or stats:FindFirstChild("Escaped")
    if e and (e:IsA("NumberValue") or e:IsA("IntValue")) then return e end
    -- fallback: first numeric stat
    for _,v in ipairs(stats:GetChildren()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            return v
        end
    end
    return nil
end

local escapeStatObj = findEscapeStatObject()
local escapePrevValue = escapeStatObj and tonumber(escapeStatObj.Value) or 0

-- Conectar Changed para detectar aumentos reales
if escapeStatObj then
    escapeStatObj.Changed:Connect(function(newVal)
        local newNum = tonumber(newVal) or 0
        -- always update blue separately (UI loop will also refresh, but this reduces delay)
        -- If it increased and we had autoescape active recently, count as assisted
        if newNum > escapePrevValue then
            if AutoEscapeActive or os.time() <= assistedUntil then
                guiEscapesHelped = guiEscapesHelped + 1
                saveState()
            end
        end
        escapePrevValue = newNum
    end)
end

-- Auto actions (teleport/escape)
local function autoEscape()
    local hrp = getHRP()
    local door = findEscapeDoor()
    if hrp and door then
        -- mark active + window for assistance
        AutoEscapeActive = true
        assistedUntil = os.time() + ASSIST_WINDOW
        pcall(function()
            hrp.CFrame = CFrame.new(door.Position + Vector3.new(0,3,0))
        end)
        -- we DO NOT increment guiEscapesHelped here (we wait for the stat change)
        -- but keep state saved in case window triggers
        saveState()
        -- turn off AutoEscapeActive shortly after to avoid double counting
        task.delay(ASSIST_WINDOW, function() AutoEscapeActive = false end)
        return true
    end
    return false
end

local function tpToCoord()
    local hrp = getHRP()
    if hrp then
        -- teleporting in lobby might not give escape stat — but still mark window if you want
        AutoEscapeActive = true
        assistedUntil = os.time() + ASSIST_WINDOW
        pcall(function()
            hrp.CFrame = CFrame.new(LOBBY_COORD)
        end)
        saveState()
        task.delay(ASSIST_WINDOW, function() AutoEscapeActive = false end)
        return true
    end
    return false
end

-- get official total escapes (blue)
local function getEscapesStatValue()
    local stats = player:FindFirstChild("leaderstats")
    if not stats then return 0 end
    -- prefer "Escapes"
    local esc = stats:FindFirstChild("Escapes") or stats:FindFirstChild("Escape") or stats:FindFirstChild("Escaped")
    if esc and (esc:IsA("NumberValue") or esc:IsA("IntValue")) then
        return tonumber(esc.Value) or 0
    end
    -- fallback any numeric stat
    for _,v in ipairs(stats:GetChildren()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            return tonumber(v.Value) or 0
        end
    end
    return 0
end

-- === GUI (NO CAMBIOS de posición/colores) ===
local gui = Instance.new("ScreenGui", player.PlayerGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 420, 0, 240)
frame.Position = UDim2.new(0.5, -210, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 6
frame.Active = true
frame.Draggable = true

local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Size = UDim2.new(1,0,0,40)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.TextScaled = true
titleLabel.Text = "SISTEMA AUTO"

local idNameLabel = Instance.new("TextLabel", frame)
idNameLabel.Position = UDim2.new(0,0,0,40)
idNameLabel.Size = UDim2.new(1,0,0,30)
idNameLabel.BackgroundTransparency = 1
idNameLabel.TextColor3 = Color3.fromRGB(255,255,255)
idNameLabel.TextScaled = true
idNameLabel.Text = "ID: "..tostring(player.UserId).."   Nombre: "..tostring(player.Name)

-- keep TextButtons as indicators (same names/positions/colors)
local TiempoBtn = Instance.new("TextButton", frame)
TiempoBtn.Name = "TiempoBtn"
TiempoBtn.Size = UDim2.new(0.45,0,0,50)
TiempoBtn.Position = UDim2.new(0.05,0,0,80)
TiempoBtn.BackgroundColor3 = Color3.fromRGB(180,0,0)
TiempoBtn.TextColor3 = Color3.new(1,1,1)
TiempoBtn.TextScaled = true
TiempoBtn.Text = "Tiempo: 0d 0h 0m 0s"
TiempoBtn.AutoButtonColor = false

local EscapesBtn = Instance.new("TextButton", frame)
EscapesBtn.Name = "EscapesBtn"
EscapesBtn.Size = UDim2.new(0.45,0,0,50)
EscapesBtn.Position = UDim2.new(0.5,0,0,80)
EscapesBtn.BackgroundColor3 = Color3.fromRGB(0,110,255)
EscapesBtn.TextColor3 = Color3.new(1,1,1)
EscapesBtn.TextScaled = true
EscapesBtn.Text = "Escapes total: 0"
EscapesBtn.AutoButtonColor = false

local GUIEscapesBtn = Instance.new("TextButton", frame)
GUIEscapesBtn.Name = "GUIEscapesBtn"
GUIEscapesBtn.Size = UDim2.new(0.92,0,0,50)
GUIEscapesBtn.Position = UDim2.new(0.04,0,0,140)
GUIEscapesBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
GUIEscapesBtn.TextColor3 = Color3.new(1,1,1)
GUIEscapesBtn.TextScaled = true
GUIEscapesBtn.Text = "Escapes conseguidos: "..tostring(guiEscapesHelped)
GUIEscapesBtn.AutoButtonColor = false

-- robust loop: accumulate delta seconds so totalTime persists and never locks
local lastTick = tick()
local autosaveCounter = 0
task.spawn(function()
    while true do
        local ok, err = pcall(function()
            local now = tick()
            local dt = now - lastTick
            if dt < 0 then dt = 0 end
            -- clamp large dt (if app was suspended) to avoid giant jumps
            if dt > 10 then dt = 1 end
            totalTime = totalTime + dt
            lastTick = now

            -- auto actions: non-blocking
            local hrp = getHRP()
            if hrp then
                if game.PlaceId == LOBBY_ID then
                    pcall(tpToCoord)
                elseif game.PlaceId == PARTIDA_ID then
                    pcall(autoEscape)
                end
            end

            -- update UI
            local t = math.floor(totalTime)
            local days = math.floor(t / 86400)
            local hours = math.floor(t/3600) % 24
            local mins = math.floor(t/60) % 60
            local secs = t % 60
            pcall(function()
                TiempoBtn.Text = string.format("Tiempo: %dd %dh %dm %ds", days, hours, mins, secs)
                EscapesBtn.Text = "Escapes total: "..tostring(getEscapesStatValue())
                GUIEscapesBtn.Text = "Escapes conseguidos: "..tostring(guiEscapesHelped)
            end)

            autosaveCounter = autosaveCounter + 1
            if autosaveCounter >= 5 then
                -- persist values
                pcall(function()
                    state.totalTime = math.floor(totalTime)
                    state.guiEscapesHelped = guiEscapesHelped
                    if writefile then writefile(filename, HttpService:JSONEncode(state)) end
                end)
                autosaveCounter = 0
            end
        end)
        if not ok then
            -- don't crash; loop continues
            --print("AutoSystem loop error:", err)
        end
        task.wait(1)
    end
end)
