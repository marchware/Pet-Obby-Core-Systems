local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function playLocalSound(sound)
	if sound and sound:IsA("Sound") then
		local clone = sound:Clone()
		clone.Parent = LocalPlayer:WaitForChild("PlayerGui")
		clone:Play()
		clone.Ended:Connect(function()
			clone:Destroy()
		end)
	end
end

-- KILL
local killDebounce = false

local function touchedKill(killPart, otherPart)
	local player = Players:FindFirstChild(otherPart.Name) or Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local particle = killPart:FindFirstChild("Particle")

	if player then
		if otherPart.Parent == workspace.Ignore and not killDebounce then
			local stageObjects = {}
			for _, cp in pairs(CollectionService:GetTagged("Checkpoint")) do
				local stage = cp:GetAttribute("Stage")
				stageObjects[stage] = stageObjects[stage] or {}
				table.insert(stageObjects[stage], cp)
			end

			local hidden = player:FindFirstChild("hidden")
			if hidden then
				hidden.Deaths.Value = hidden.Deaths.Value + 1
			end

			if particle then
				particle.ParticleEmitter:Emit(1)
			end
			
			playLocalSound(SoundService.SFX:FindFirstChild("Kill"))
			
			game.ReplicatedStorage.BindableEvents.clientTPFromClient:Fire(player, stageObjects[player.leaderstats.Stage.Value])
			killDebounce = true
			task.wait(0.5)
			killDebounce = false
		end
	end
end

for _, killPart in ipairs(CollectionService:GetTagged("KillPart")) do
	killPart.Touched:Connect(function(otherPart)
		touchedKill(killPart, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("KillPart"):Connect(function(killPart)
	killPart.Touched:Connect(function(otherPart)
		touchedKill(killPart, otherPart)
	end)
end)

-- HITTER
local function touchedHitter(hitter, otherPart)
	local player = Players:FindFirstChild(otherPart.Name) or Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local ForceVector = hitter:GetAttribute("Force")
	local debounce = hitter:GetAttribute("Debounce")

	if player then
		if otherPart.Parent == workspace.Ignore and not debounce then
			if otherPart:FindFirstChild("CharForce") then
				playLocalSound(SoundService.SFX:FindFirstChild("Hit"))
				otherPart.CharForce.Force = ForceVector or Vector3.new(0, 0, -5000)
				hitter:SetAttribute("Debounce", true)
				task.wait(0.05)
				otherPart.CharForce.Force = Vector3.new(0, 0, 0)
				task.wait(0.95)
				hitter:SetAttribute("Debounce", false)
			end
		end
	end
end

for _, hitter in ipairs(CollectionService:GetTagged("Hitter")) do
	hitter.Touched:Connect(function(otherPart)
		touchedHitter(hitter, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("Hitter"):Connect(function(hitter)
	hitter.Touched:Connect(function(otherPart)
		touchedHitter(hitter, otherPart)
	end)
end)

-- SPEED
local function touchedSpeed(speedPart, otherPart)
	local player = Players:FindFirstChild(otherPart.Name) or Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local speed = speedPart:GetAttribute("Speed") or 50
	local debounce = speedPart:GetAttribute("Debounce")

	if player then
		if otherPart.Parent == workspace.Ignore and not debounce then
			playLocalSound(SoundService.SFX:FindFirstChild("Speed"))
			otherPart.Velocity += -speedPart.CFrame.LookVector * speed
			speedPart:SetAttribute("Debounce", true)
			task.wait(0.5)
			speedPart:SetAttribute("Debounce", false)
		end
	end
end

for _, speedPart in ipairs(CollectionService:GetTagged("SpeedPart")) do
	speedPart:WaitForChild("Collider")
	speedPart.Collider.Touched:Connect(function(otherPart)
		touchedSpeed(speedPart.Collider, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("SpeedPart"):Connect(function(speedPart)
	speedPart:WaitForChild("Collider")
	speedPart.Collider.Touched:Connect(function(otherPart)
		touchedSpeed(speedPart.Collider, otherPart)
	end)
end)

-- DISSOLVE
local function touchedDissolve(dissolvePart, otherPart)
	local player = game.Players:FindFirstChild(otherPart.Name) or game.Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local debounce = dissolvePart:GetAttribute("Debounce")
	local platform = dissolvePart.Parent:FindFirstChild("Stage")

	if player then
		if otherPart.Parent == workspace.Ignore and not debounce then
			dissolvePart:SetAttribute("Debounce", true)
			
			local animatedInstances = {}
			for _, instance in pairs(platform:GetDescendants()) do
				if instance:IsA("Texture") then
					animatedInstances[instance] = { Property = "Transparency", Original = instance.Transparency }
				end
			end
			
			playLocalSound(SoundService.SFX:FindFirstChild("Dissolve"))
			
			local animatePart = Instance.new("Part")
			animatePart.Anchored = true
			animatePart.Transparency = 0.5
			animatePart.Position = platform.Position
			animatePart.Size = platform.Size
			animatePart.Color = Color3.new(1, 0.290196, 0.227451)
			animatePart.Material = Enum.Material.SmoothPlastic
			animatePart.CanCollide = false
			animatePart.CastShadow = false
			animatePart.Parent = platform

			local expandTween = TweenService:Create(animatePart, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = animatePart.Size * 1.1})
			expandTween:Play()
			expandTween.Completed:Wait()

			animatePart:Destroy()

			for instance, data in pairs(animatedInstances) do
				local fadeOutTween = TweenService:Create(instance, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					[data.Property] = 1
				})
				fadeOutTween:Play()
			end

			local disappearTween = TweenService:Create(platform, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
			disappearTween:Play()
			disappearTween.Completed:Wait()

			platform.CanCollide = false

			task.wait(4)

			local regenTween = TweenService:Create(platform, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0})

			for instance, data in pairs(animatedInstances) do
				local fadeInTween = TweenService:Create(instance, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					[data.Property] = data.Original
				})
				fadeInTween:Play()
			end
			regenTween:Play()
			regenTween.Completed:Wait()

			platform.CanCollide = true
			dissolvePart:SetAttribute("Debounce", false)
		end
	end
end

for _, dissolvePart in ipairs(CollectionService:GetTagged("Dissolve")) do
	dissolvePart.Touched:Connect(function(otherPart)
		touchedDissolve(dissolvePart, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("Dissolve"):Connect(function(dissolvePart)
	dissolvePart.Touched:Connect(function(otherPart)
		touchedDissolve(dissolvePart, otherPart)
	end)
end)

-- SLOW
local function touchedSlow(slowPart, otherPart)
	local player = Players:FindFirstChild(otherPart.Name) or Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local slowness = slowPart:GetAttribute("Slowness") or 0.2

	if player then
		if otherPart.Parent == workspace.Ignore then
			local petModel = otherPart.Parent:FindFirstChild(otherPart.Name .. "Pet")

			if petModel and petModel:FindFirstChild("Speed") then
				local speedValue = petModel.Speed
				local originalSpeed = speedValue.Value
				
				playLocalSound(SoundService.SFX:FindFirstChild("Mud"))
				
				speedValue.Value = originalSpeed * slowness

				local connection
				connection = RunService.Heartbeat:Connect(function()
					if not otherPart or not otherPart.Parent or not slowPart:IsDescendantOf(workspace) then
						speedValue.Value = originalSpeed
						connection:Disconnect()
					end
				end)

				slowPart.TouchEnded:Connect(function(endedPart)
					if endedPart.Parent == otherPart.Parent then
						speedValue.Value = originalSpeed
						connection:Disconnect()
					end
				end)
			end
		end
	end
end

for _, slowPart in ipairs(CollectionService:GetTagged("Slow")) do
	slowPart.Touched:Connect(function(otherPart)
		touchedSlow(slowPart, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("Slow"):Connect(function(slowPart)
	slowPart.Touched:Connect(function(otherPart)
		touchedSlow(slowPart, otherPart)
	end)
end)

-- CONVEYOR
local function touchedConveyor(conveyorPart, otherPart)
	local player = Players:FindFirstChild(otherPart.Name) or Players:FindFirstChild(string.sub(otherPart.Name, 0, 7))
	local speed = conveyorPart:GetAttribute("Speed") or 30

	if player and otherPart.Parent == workspace.Ignore then
		local touching = true

		local connection
		connection = conveyorPart.TouchEnded:Connect(function(endedPart)
			if endedPart == otherPart then
				touching = false
				connection:Disconnect()
			end
		end)

		while touching and otherPart:IsDescendantOf(workspace) do
			otherPart.Velocity = -conveyorPart.CFrame.LookVector * speed
			task.wait(0.1)
		end
	end
end

for _, conveyorPart in ipairs(CollectionService:GetTagged("Conveyor")) do
	conveyorPart.Touched:Connect(function(otherPart)
		touchedConveyor(conveyorPart, otherPart)
	end)
end

CollectionService:GetInstanceAddedSignal("Conveyor"):Connect(function(conveyorPart)
	conveyorPart.Touched:Connect(function(otherPart)
		touchedConveyor(conveyorPart, otherPart)
	end)
end)

-- MOVING
local function movingPart(otherPart)
	local goal = otherPart.Parent:WaitForChild("Goal")
	local Time = otherPart:GetAttribute("Time") or 4
	if goal then
		TweenService:Create(otherPart, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {Position = goal.Position}):Play()
	end	
end

for _, movePart in ipairs(CollectionService:GetTagged("Moving")) do
	movingPart(movePart)
end

CollectionService:GetInstanceAddedSignal("Moving"):Connect(function(movePart)
	movingPart(movePart)
end)


--SPIN
local function spinningPart(spinPart)
	local speed = spinPart:GetAttribute("SpinSpeed") or 30
	RunService.RenderStepped:Connect(function(dt)
		spinPart.CFrame *= CFrame.Angles(0, math.rad(speed * dt), 0)
	end)	
end

for _, spinPart in ipairs(CollectionService:GetTagged("Spinning")) do
	spinningPart(spinPart)
end

CollectionService:GetInstanceAddedSignal("Spinning"):Connect(function(spinPart)
	spinningPart(spinPart)
end)

-- SWING
local function swingingPart(otherPart)
	local origin = otherPart:WaitForChild("Origin")
	local Time = otherPart:GetAttribute("Time") or 3
	if origin then
		local startCFrame = otherPart.Origin.CFrame
		local endCFrame = startCFrame * CFrame.Angles(0, 0, math.rad(180))
		TweenService:Create(otherPart.Origin, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {CFrame = endCFrame}):Play()
	end
end

for _, swingPart in ipairs(CollectionService:GetTagged("Swinging")) do
	swingingPart(swingPart)
end

CollectionService:GetInstanceAddedSignal("Swinging"):Connect(function(swingPart)
	swingingPart(swingPart)
end)
