local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local cam = workspace.CurrentCamera
local plr = Players.LocalPlayer

-- GUI Setup
local PlayerGui = plr:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpectateControlsGui"
ScreenGui.Parent = PlayerGui
ScreenGui.Enabled = false -- start hidden

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0.3, 0, 0, 100)
Frame.Position = UDim2.new(0.5, 0, 0, 10) -- centered horizontally at top with 10 px offset
Frame.AnchorPoint = Vector2.new(0.5, 0)
Frame.BackgroundColor3 = Color3.new(0, 0, 0)
Frame.BackgroundTransparency = 1
Frame.Parent = ScreenGui

local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(2, 0, 2, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.TextSize = 18
TextLabel.TextWrapped = true
TextLabel.Text = [[
CONTROLS:
W/A/S/D = Move block
Right Mouse Hold = Rotate camera
E = Toggle spectate mode
Space = Move block UP
Left Shift = Move block DOWN
]]
TextLabel.Parent = Frame

-- Variables
local block = nil
local controlling = false
local rotating = false
local speed = 50
local rotationSpeed = 0.005
local yaw = 0
local pitch = 0
local humanoid = nil

local function createBlock()
	local p = Instance.new("Part")
	p.Size = Vector3.new(3, 3, 3)
	p.Color = Color3.fromRGB(255, 50, 50)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	local pos = Vector3.new(0, 10, 0)
	if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
		pos = plr.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
	end
	p.Position = pos
	p.Name = "ControlBlock"
	p.Parent = workspace
	return p
end

local function updateCamera()
	if block then
		local distance = 10
		local height = 3
		local focus = block.Position
		local horizontal = CFrame.new(focus) * CFrame.Angles(0, yaw, 0)
		local vertical = CFrame.Angles(pitch, 0, 0)
		local offset = vertical * CFrame.new(0, 0, distance)
		local finalPos = (horizontal * offset).Position + Vector3.new(0, height, 0)
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.new(finalPos, focus)
	else
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function moveBlock(dt)
	if not block then return end
	local moveDir = Vector3.new()

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Vector3.new(0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir += Vector3.new(0, 0, 1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir += Vector3.new(-1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Vector3.new(1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir += Vector3.new(0, -1, 0) end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
		-- Move relative to current yaw only (horizontal rotation)
		local moveCFrame = CFrame.Angles(0, yaw, 0)
		local worldMove = moveCFrame:VectorToWorldSpace(moveDir)
		block.Position += worldMove * speed * dt
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotating = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end

	if input.KeyCode == Enum.KeyCode.E then
		if not controlling then
			if not block or not block.Parent then
				block = createBlock()
			end
			controlling = true
			ScreenGui.Enabled = true
			if plr.Character and plr.Character:FindFirstChild("Humanoid") then
				humanoid = plr.Character.Humanoid
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
			end
		else
			controlling = false
			ScreenGui.Enabled = false
			if block and block.Parent then
				block:Destroy()
				block = nil
			end
			cam.CameraType = Enum.CameraType.Custom
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			rotating = false
			if humanoid then
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rotating = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if controlling and rotating and input.UserInputType == Enum.UserInputType.MouseMovement then
		yaw = yaw - input.Delta.X * rotationSpeed
		pitch = math.clamp(pitch - input.Delta.Y * rotationSpeed, -math.rad(85), math.rad(85))
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if controlling and block then
		-- Make block face camera rotation (yaw and pitch)
		block.CFrame = CFrame.new(block.Position) * CFrame.Angles(pitch, yaw, 0)
		moveBlock(dt)
		updateCamera()
	else
		if cam.CameraType ~= Enum.CameraType.Custom then
			cam.CameraType = Enum.CameraType.Custom
		end
	end
end)
