local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local function handleCheckpoint(cp)
	cp:WaitForChild("Collider")
	cp:WaitForChild("CheckpointMarker")

	local part = cp.Collider
	local particleHost = cp.CheckpointMarker
	local debounce = false

	part.Touched:Connect(function(otherPart)
		if debounce then return end
		if otherPart.Parent == workspace.Ignore and player.Name == otherPart.Name then
			debounce = true
			local stageValue = cp:GetAttribute("Stage")
			if player.leaderstats.Stage.Value <= stageValue then
				player.leaderstats.Stage.Value = stageValue
				ReplicatedStorage.RemoteEvents.stageUpdate:FireServer(stageValue)
			end

			if cp:FindFirstChild("Flag") then
				local ti = TweenInfo.new(0.5)
				local CFrameOG = cp.Flag.CFrame
				TweenService:Create(cp.Flag, ti, {CFrame = CFrameOG * CFrame.Angles(0, 0, math.pi)}):Play()
				TweenService:Create(cp.Flag.Part, ti, {Color = Color3.new(0, 1, 0)}):Play()
			end
			
			game:GetService("SoundService").SFX.Checkpoint:Play()
			particleHost.NotChecked.Enabled = false
			particleHost.Checked:Emit(5)
			for i = 1, 6 do
				cp.CircleTex["Confetti" .. i]:Emit(10)
			end
			cp.CircleTex.Decal.Transparency = 0
		end
	end)

	player:WaitForChild("leaderstats")

	local event
	local function endEvent()
		if event then event:Disconnect() end
	end

	event = RunService.RenderStepped:Connect(function()
		local isCheckpointPassed = player.leaderstats.Stage.Value >= cp:GetAttribute("Stage")
		debounce = isCheckpointPassed
		if not particleHost:FindFirstChild("NotChecked") then
			endEvent()
			return
		end
		particleHost.NotChecked.Enabled = not isCheckpointPassed
		cp.CircleTex.Decal.Transparency = isCheckpointPassed and 0 or 1
	end)
end

local function initializeCheckpoints()
	for _, cp in pairs(CollectionService:GetTagged("Checkpoint")) do
		handleCheckpoint(cp)
	end
end

initializeCheckpoints()