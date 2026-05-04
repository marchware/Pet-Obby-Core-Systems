local ServerScriptService = game:GetService("ServerScriptService")
local InventoryHandler = require(ServerScriptService.InventoryHandler)
local SkipsManager = require(ServerScriptService.SkipHandler)
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local lastResponseTimes = {}

-- Reset player based on selection
ReplicatedStorage.RemoteEvents.resetPlayer.OnServerEvent:Connect(function(player, selection)
	if selection == "Stage" then
		player:WaitForChild("leaderstats")
		player.leaderstats.Stage.Value = 0
	elseif selection == "Character" then
		if player.Character then
			--[[player:LoadCharacter()
			task.wait(0.5)]]
		end
	end

	local playerInstance = game.Players:FindFirstChild(player.Name)
	if playerInstance then
		local stage = playerInstance.leaderstats.Stage.Value
		local stageObjects = {}

		for _, checkpoint in ipairs(CollectionService:GetTagged("Checkpoint")) do
			local stage = checkpoint:GetAttribute("Stage")
			stageObjects[stage] = stageObjects[stage] or {}
			table.insert(stageObjects[stage], checkpoint)
		end

		ReplicatedStorage.RemoteEvents.clientTP:FireClient(playerInstance, stageObjects[playerInstance.leaderstats.Stage.Value])
	end
end)

-- Teleport player
ReplicatedStorage.RemoteEvents.clientTP.OnServerEvent:Connect(function(player)
	ReplicatedStorage.RemoteEvents.clientTP:FireClient(player)
end)

-- Handle crate requests with cooldown
ReplicatedStorage.RemoteEvents.crateRequest.OnServerEvent:Connect(function(player, price, eggName)
	local coins = player:WaitForChild("leaderstats").Coins
	local currentTime = tick()
	local lastResponseTime = lastResponseTimes[player] or 0

	if currentTime - lastResponseTime < 1 then
		ReplicatedStorage.RemoteEvents.cooldownMessage:FireClient(player)
		return
	end

	if coins.Value >= price then
		local item, rarity, duplicate = InventoryHandler.HatchEgg(player, price, eggName)

		if duplicate and price then
			local halfprice = tonumber(price / 2)
			ServerScriptService.Security.StageUpdater.CoinTake:Fire(player, halfprice)
			ReplicatedStorage.RemoteEvents.cashNotification:FireClient(player, halfprice)
		end

		ReplicatedStorage.RemoteEvents.crateRequest:FireClient(player, item, rarity, duplicate, eggName)
		lastResponseTimes[player] = currentTime
	end
end)

-- Fetch inventory
ReplicatedStorage.RemoteFunctions.fetchInventory.OnServerInvoke = function(player)
	return InventoryHandler.GetInventory(player)
end

-- Fetch equipped item
ReplicatedStorage.RemoteFunctions.fetchEquipped.OnServerInvoke = function(player)
	return InventoryHandler.GetEquippedItem(player)
end

-- Update equipped item
ReplicatedStorage.RemoteEvents.updateEquip.OnServerEvent:Connect(function(player, item)
	InventoryHandler.EquipItem(player, item)
end)

-- Fetch skips
ReplicatedStorage.RemoteFunctions.fetchSkips.OnServerInvoke = function(player)
	return SkipsManager.GetSkips(player)
end

-- Skip stage
ReplicatedStorage.RemoteEvents.skipStage.OnServerEvent:Connect(function(player)
	SkipsManager.SkipStage(player)
end)

-- Donation
ReplicatedStorage.RemoteEvents.updateDonate.OnServerEvent:Connect(function(player, product)
	game:GetService("MarketplaceService"):PromptProductPurchase(player, tonumber(product))
end)

-- Teleport World
local worldPlaceIDs = {
	["RaceWorld"] = 86183422186409,
	["World1"] = 127803200816500,
	["World2"] = 71545282233092,
	["World3"] = 105986629569580,
	["World4"] = 4567890123,
}
ReplicatedStorage.RemoteEvents.teleportWorld.OnServerEvent:Connect(function(player, worldName)
	local placeId = worldPlaceIDs[worldName]
	if placeId then
		TeleportService:Teleport(placeId, player)
	end
end)