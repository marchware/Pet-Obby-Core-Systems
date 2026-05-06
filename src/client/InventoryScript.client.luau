local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("RemoteEvents")
local Functions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local inventoryFunc = Functions:WaitForChild("fetchInventory")
local equipEvent = Events:WaitForChild("updateEquip")
local callUpdate = Events:WaitForChild("callForUpdate")

local ItemData = require(ReplicatedStorage.Module.PetsList)

-- In General
local inventoryGui = script.Parent
local exitButton = inventoryGui.Back
local currentEquip = inventoryGui.currentEquip
local currentSelect = inventoryGui.currentSelect

-- Left Side UI
local leftGui = inventoryGui.Content.LeftSide
local imageHolder = leftGui.ViewportFrame.WorldModel
local equipButton = leftGui.EquipButton
local rarityTitle = leftGui.Stats.Frame.Rarity
local jumpPower = leftGui.Stats.Frame.JumpPower
local topSpeed = leftGui.Stats.Frame.TopSpeed

-- Right Side UI
local rightGui = inventoryGui.Content.RightSide
local itemsFrame = rightGui.ScrollingFrame.Items
local template = rightGui.ScrollingFrame.Items.Template

local rarityColors = {
	Common = Color3.fromRGB(186, 176, 151),
	Rare = Color3.fromRGB(142, 255, 111),
	Epic = Color3.fromRGB(0, 255, 213),
	Mythic = Color3.fromRGB(129, 0, 209),
	Legendary = Color3.fromRGB(255, 213, 0),
	Godly = Color3.fromRGB(226, 0, 0),
	Mysterious = Color3.fromRGB(38, 38, 38)
}

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

local function handleClick(button, action)
	local originalSize = button.Size
	local clickSize = originalSize - UDim2.new(0.02, 0, 0.02, 0)

	if game:GetService("SoundService").SFX:FindFirstChild("ClickSound") then
		game:GetService("SoundService").SFX.ClickSound:Play()
	end

	animateSize(button, clickSize, 0.1)
	task.wait(0.1)
	animateSize(button, originalSize, 0.1)
end

handleHover(exitButton)
exitButton.Button.Activated:Connect(function()
	handleClick(exitButton)
	TweenService:Create(inventoryGui, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 2, 0)}):Play()
	inventoryGui:SetAttribute("Up", false)
end)

handleHover(equipButton)
equipButton.Button.Activated:Connect(function()
	handleClick(equipButton)
	local selectedItem = currentSelect.Value
	local equippedItem = currentEquip.Value

	if selectedItem ~= equippedItem then
		equipButton.Button.Label.Text = "Equipped"
		equipEvent:FireServer(selectedItem == "Pet" and "default" or selectedItem)
	end
end)

local function updateInventory()
	local inventory = inventoryFunc:InvokeServer()

	for _, item in pairs(itemsFrame:GetChildren()) do
		if item:IsA("CanvasGroup") and item ~= template then
			item:Destroy()
		end
	end

	local sortedInventory = {"default"}

	for _, itemID in pairs(inventory) do
		for rarity, items in pairs(ItemData) do
			for _, itemName in pairs(items) do
				if itemName == itemID then
					table.insert(sortedInventory, itemName)
				end
			end
		end
	end
	
	for _, itemName in pairs(sortedInventory) do
		local itemIcon = template:Clone()
		itemIcon.Name = itemName
		itemIcon.Parent = itemsFrame
		itemIcon.Visible = true
		
		for rarity, items in pairs(ItemData) do
			for _, rarityItem in pairs(items) do
				if rarityItem == itemName then
					itemIcon.Status.Label.Text = rarityItem or "Common"
					itemIcon.Status.Label.TextColor3 = rarityColors[rarity] or Color3.fromRGB(255, 255, 255)
				end
			end
		end
		
		itemIcon.ItemName.Text = itemName or "Unknown"
		if currentEquip.Value == itemName then
			itemIcon.Status.Label.Text = "Equipped"
		else
			itemIcon.Status.Label.Text = "Equip"
		end
		itemIcon.Status.Label.Visible = true

		local model = itemName == "default" and ReplicatedStorage.Resource.Pet:Clone()
			or ReplicatedStorage.Resource.ItemPets:FindFirstChild(itemName) and ReplicatedStorage.Resource.ItemPets[itemName]:Clone()

		if model then
			model.Parent = itemIcon.ViewportFrame.WorldModel
			model:SetPrimaryPartCFrame(CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.rad(150), 0))
		end
		
		itemIcon.Button.Activated:Connect(function()
			if game:GetService("SoundService").SFX:FindFirstChild("ClickSound") then
				game:GetService("SoundService").SFX.ClickSound:Play()
			end
			currentSelect.Value = itemName
			if currentEquip.Value ~= currentSelect.Value then
				equipButton.Button.Label.Text = "Equip"
			else
				equipButton.Button.Label.Text = "Equipped"
			end
		end)
	end
end

callUpdate.OnClientEvent:Connect(function()
	task.wait(1)
	updateInventory()
end)

currentSelect.Changed:Connect(function()
	local selectedItem = currentSelect.Value

	if selectedItem then
		leftGui.Title.Text = selectedItem or "Unknown"
		if selectedItem == "default" then
			leftGui.Title.Text = "Default"
			rarityTitle.Text = "Common"
			rarityTitle.TextColor3 = Color3.fromRGB(186, 176, 151)
		end
	end
	
	if currentSelect == currentEquip then
		equipButton.Button.Label.Text = "Equipped"
	else
		equipButton.Button.Label.Text = "Equip"
	end

	for _, child in ipairs(imageHolder:GetChildren()) do
		if not child:IsA("Camera") then
			child:Destroy()
		end
	end

	local newModel = (selectedItem == "Pet" or selectedItem == "default") 
		and ReplicatedStorage.Resource.Pet:Clone()
		or ReplicatedStorage.Resource.ItemPets[selectedItem]:Clone()

	if newModel then
		newModel.Parent = imageHolder
		newModel:SetPrimaryPartCFrame(CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.rad(150), 0))
		
		for rarity, items in pairs(ItemData) do
			for _, rarityItem in pairs(items) do
				if rarityItem == newModel.Name then
					rarityTitle.Text = rarity
					rarityTitle.TextColor3 = rarityColors[rarity] or Color3.fromRGB(255, 255, 255)
				end
			end
		end
		
		local speedValue = newModel:FindFirstChild("Speed") and newModel.Speed.Value or 0
		local jumpValue = newModel:FindFirstChild("Jump") and newModel.Jump.Value or 0
		
		jumpPower.Title.Text = "Jump Power: " .. jumpValue
		topSpeed.Title.Text = "Top Speed: " .. speedValue
		
		local function tweenFillbar(bar, value, maxValue)
			local goal = {Size = UDim2.new(math.clamp(value / maxValue, 0, 1), 0, 1, 0)}
			local tween = TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), goal)
			tween:Play()
		end

		tweenFillbar(jumpPower.Bar.Fillbar, jumpValue, 100)
		tweenFillbar(topSpeed.Bar.Fillbar, speedValue, 120)
	end
end)

local equippedOnJoin = Functions.fetchEquipped:InvokeServer()
currentSelect.Value = equippedOnJoin
currentEquip.Value = equippedOnJoin

equipEvent.OnClientEvent:Connect(function(item)
	currentEquip.Value = item
	equipButton.Button.Label.Text = (currentSelect.Value == item) and "Equipped" or "Equip"
end)

updateInventory()