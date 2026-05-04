local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local confirmation = player:WaitForChild("PlayerGui"):WaitForChild("Confirmation")

local mouse = player:GetMouse()
local yesConnection
local noConnection
local isConfirmation = false

-- IN GENERAL
local frameGUI = script.Parent
local sounds = frameGUI.Content.Sound
local visual = frameGUI.Content.Visual
local reset = frameGUI.Content.Reset.Background
local exitButton = frameGUI.Back

-- SOUND
local bgm = SoundService:WaitForChild("BGM"):GetChildren()
local bgmBar = sounds.BGM.Slider.Bar
local bgmFillBar = bgmBar.FillBar
local bgmKnob = bgmBar.Knob

local sfx = SoundService:WaitForChild("SFX"):GetChildren()
local sfxBar = sounds.SFX.Slider.Bar
local sfxFillBar = sfxBar.FillBar
local sfxKnob = sfxBar.Knob

local minVolume = 0
local maxVolume = 1

-- VISUAL
local globalShadowsToggle = visual.GlobalShadow.Toggle
local globalShadowSwitch = globalShadowsToggle.Button

local showCharToggle = visual.ShowCharacters.Toggle
local showCharSwitch = showCharToggle.Button

local showParticlesToggle = visual.ShowCharacters.Toggle
local showParticlesSwitch = showParticlesToggle.Button

-- RESET
local buttons = {reset.Stage, reset.Character}
local loadingFrame = reset.Character.Loading
local buttonText = reset.Character.Button.Label

-- MAIN FUNCTION
local function animateSize(object, targetSize, duration)
	TweenService:Create(object, TweenInfo.new(duration), {Size = targetSize}):Play()
end

local function handleHover(button)
	local originalSize = button.Size
	local hoverSize = originalSize + UDim2.new(0.02, 0, 0.02, 0)

	button.MouseEnter:Connect(function()
		animateSize(button, hoverSize, 0.1)
	end)

	button.MouseLeave:Connect(function()
		animateSize(button, originalSize, 0.1)
	end)
end

local function diconnecter()
	yesConnection:Disconnect()
	noConnection:Disconnect()
end

local function handleClick(button, action)
	local originalSize = button.Size
	local clickSize = originalSize - UDim2.new(0.02, 0, 0.02, 0)
	local cooldown = 15
	local isCoolingDown = false

	if button.Button:IsA("GuiButton") then
		button.Button.Activated:Connect(function()
			if action == "Character" and isCoolingDown then return end

			if action == "Character" then
				isCoolingDown = true
			end

			if SoundService.SFX:FindFirstChild("ClickSound") then
				SoundService.SFX.ClickSound:Play()
			end

			animateSize(button, clickSize, 0.1)
			task.wait(0.1)
			animateSize(button, originalSize, 0.1)

			TweenService:Create(frameGUI, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.5, 0, 2, 0)
			}):Play()
			frameGUI:SetAttribute("Up", false)

			if action == "Stage" then
				confirmation.BoxConfirmation.Message.Text = "Are you sure to restart this world's progress?"
				confirmation.Enabled = true
				isConfirmation = true

				yesConnection = confirmation.BoxConfirmation.Yes.Button.Activated:Connect(function()
					confirmation.Enabled = false
					isConfirmation = false
					ReplicatedStorage.RemoteEvents.resetPlayer:FireServer(action)
					task.wait(0.1)
					diconnecter()
				end)

				noConnection = confirmation.BoxConfirmation.No.Button.Activated:Connect(function()
					confirmation.Enabled = false
					isConfirmation = false
					diconnecter()
				end)

				return
			end

			ReplicatedStorage.RemoteEvents.resetPlayer:FireServer(action)
			
			if action == "Character" then
				loadingFrame.Size = UDim2.new(1, 0, 1, 0)
				loadingFrame.Visible = true
				button.Button.Active = false

				TweenService:Create(loadingFrame, TweenInfo.new(cooldown, Enum.EasingStyle.Linear), {
					Size = UDim2.new(0, 0, 1, 0)
				}):Play()

				task.delay(cooldown, function()
					button.Button.Active = true
					loadingFrame.Visible = false
					loadingFrame.Size = UDim2.new(1, 0, 1, 0)
					isCoolingDown = false
				end)
			end
		end)
	end
end

--EXIT FUNCTION
handleHover(exitButton)
exitButton.Button.Activated:Connect(function()
	local originalSize = exitButton.Size
	local clickSize = originalSize - UDim2.new(0.02, 0, 0.02, 0)

	animateSize(exitButton, clickSize, 0.1)
	TweenService:Create(frameGUI, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 2, 0)}):Play()
	frameGUI:SetAttribute("Up", false)

	if SoundService.SFX:FindFirstChild("ClickSound") then
		SoundService.SFX.ClickSound:Play()
	end

	task.wait(0.1)
	animateSize(exitButton, originalSize, 0.1)
end)

--SLIDER
local function UpdateSlider(bar, fillbar, knob, minValue, maxValue, applyFunction)
	local absPosition = bar.AbsolutePosition.X
	local absSize = bar.AbsoluteSize.X
	local mouseDelta = math.clamp(mouse.X - absPosition, 0, absSize)
	local value = minValue + ((mouseDelta / absSize) * (maxValue - minValue))
	local knobXScale = mouseDelta / absSize
	knob.Position = UDim2.new(knobXScale - 0.05, 0, knob.Position.Y.Scale, 0)
	fillbar.Size = UDim2.new(knobXScale, 0, fillbar.Size.Y.Scale, 0)
	if applyFunction then
		applyFunction(value)
	end
end

local function SetDefaultSliderPosition(bar, fillbar, knob, defaultValue, minValue, maxValue)
	local defaultXScale = (defaultValue - minValue) / (maxValue - minValue)
	knob.Position = UDim2.new(defaultXScale - 0.05, 0, knob.Position.Y.Scale, 0)
	fillbar.Size = UDim2.new(defaultXScale, 0, fillbar.Size.Y.Scale, 0)
end

local keepUpdatingBGM = false
local keepUpdatingSFX = false

local function Updater()
	while true do
		if keepUpdatingBGM then
			UpdateSlider(bgmBar, bgmFillBar, bgmKnob, minVolume, maxVolume, function(value)
				for _, sound in ipairs(bgm) do
					if sound:IsA("Sound") then
						sound.Volume = value
					end
				end
			end)
		end
		if keepUpdatingSFX then
			UpdateSlider(sfxBar, sfxFillBar, sfxKnob, minVolume, maxVolume, function(value)
				for _, sound in ipairs(sfx) do
					if sound:IsA("Sound") then
						sound.Volume = value
					end
				end
			end)
		end
		task.wait(0.01)
	end
end
coroutine.wrap(Updater)()

local function beginUpdating(kind)
	if kind == "BGM" then
		keepUpdatingBGM = true
	elseif kind == "SFX" then
		keepUpdatingSFX = true
	end
end

local function stopUpdating()
	keepUpdatingBGM = false
	keepUpdatingSFX = false
end

bgmKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginUpdating("BGM")
	end
end)

sfxKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginUpdating("SFX")
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		stopUpdating()
	end
end)

SetDefaultSliderPosition(bgmBar, bgmFillBar, bgmKnob, 0.5, minVolume, maxVolume)
SetDefaultSliderPosition(sfxBar, sfxFillBar, sfxKnob, 0.5, minVolume, maxVolume)

--TOGGLE SWITCH
local function ToggleSwitch(toggleFrame, toggleButton, state)
	local colorOn = Color3.fromRGB(255, 244, 92)
	local textColorOn = Color3.fromRGB(195, 149, 58)
	local positionOn = UDim2.new(0, 0, 0, 0)

	local colorOff = Color3.fromRGB(85, 210, 255)
	local textColorOff = Color3.fromRGB(71, 124, 221)
	local positionOff = UDim2.new(0.5, 0, 0, 0)

	local isActive = state or false

	local function UpdateToggle()
		local goal = {
			Position = isActive and positionOn or positionOff,
			BackgroundColor3 = isActive and colorOn or colorOff
		}

		local tween = TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), goal)
		tween:Play()

		toggleButton.Text = isActive and "ON" or "OFF"
		toggleButton.TextColor3 = isActive and textColorOn or textColorOff
	end

	toggleButton.MouseButton1Click:Connect(function()
		isActive = not isActive
		UpdateToggle()

		if toggleFrame == showParticlesToggle then
			
		elseif toggleFrame == globalShadowsToggle then
			game.Lighting.GlobalShadows = isActive
		elseif toggleFrame == showCharToggle then
			local localPlayer = Players.LocalPlayer
			local ignoreFolder = workspace:FindFirstChild("Ignore")

			for _, player in pairs(Players:GetPlayers()) do
				if player ~= localPlayer then
					if player.Character then
						player.Character.Parent = isActive and workspace or nil
					end

					if ignoreFolder then
						local playerVehicle = ignoreFolder:FindFirstChild(player.Name .. "Pet")
						if playerVehicle then
							for _, part in ipairs(playerVehicle:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") then
									part.Transparency = isActive and 0 or 1
								end
							end
						end
					end
				end
				task.wait(0.01)
			end
		end
	end)

	UpdateToggle()
end

ToggleSwitch(showParticlesToggle, showParticlesSwitch, true)
ToggleSwitch(globalShadowsToggle, globalShadowSwitch, true)
ToggleSwitch(showCharToggle, showCharSwitch, true)

for _, button in pairs(buttons) do
	handleHover(button)
	handleClick(button, button.Name)
end
