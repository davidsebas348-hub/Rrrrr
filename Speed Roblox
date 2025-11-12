--// Script RAW de Velocidad (compatible con teléfono)
local player = game.Players.LocalPlayer

-- Crear GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Crear botón
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 120, 0, 50)
button.Position = UDim2.new(0.85, 0, 0.85, 0)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
button.Text = "Velocidad"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.SourceSansBold
button.Parent = gui
button.Active = true
button.Draggable = true

-- Variables
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
local boosted = false

-- Actualizar humanoid cuando el personaje reaparece
player.CharacterAdded:Connect(function(char)
	humanoid = char:WaitForChild("Humanoid")
end)

-- Configurar velocidades
local normalSpeed = 16
local boostSpeed = 50

-- Función al presionar el botón
button.MouseButton1Click:Connect(function()
	if humanoid then
		boosted = not boosted
		if boosted then
			humanoid.WalkSpeed = boostSpeed
			button.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
			button.Text = "Normal"
		else
			humanoid.WalkSpeed = normalSpeed
			button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			button.Text = "Velocidad"
		end
	end
end)
