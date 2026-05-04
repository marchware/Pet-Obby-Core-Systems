local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

local DataStore2 = require(ReplicatedStorage.Module.DataStore2)
local LeaderboardDataStore = DataStoreService:GetOrderedDataStore("leaderboard")
local LeaderboardDataStore2 = DataStoreService:GetOrderedDataStore("leaderboard2")
local ih = require(ServerScriptService.InventoryHandler)

DataStore2.Combine("DATA", "coins", "wins")

Players.PlayerAdded:Connect(function(player)
	local inventory = ih.GetInventory(player)
	local leaderstats = player:WaitForChild("leaderstats")

	local coinsStat = Instance.new("NumberValue", leaderstats)
	coinsStat.Name = "Coins"
	local coinStore = DataStore2("coins", player)
	coinsStat.Value = coinStore:Get(0)

	local winsStore = DataStore2("wins", player)
	local winsStat = Instance.new("NumberValue", leaderstats)
	winsStat.Name = "Wins"
	winsStat.Value = winsStore:Get(0)

	local totalWinsStore = DataStore2("totalWins", player)
	local totalWins = Instance.new("IntValue", player)
	totalWins.Name = "TotalWins"
	totalWins.Value = totalWinsStore:Get(0)

	local bestTimeStore = DataStore2("bestTime", player)
	local bestTime = Instance.new("IntValue", player)
	bestTime.Name = "bestTime"
	bestTime.Value = bestTimeStore:Get(10^30)

	if player.UserId > 0 then
		local function updateLeaderboard(store, dataStore)
			local total = store:Get(0)
			if total then
				pcall(function()
					dataStore:UpdateAsync(player.UserId, function() return tonumber(total) end)
				end)
			end
		end

		updateLeaderboard(totalWinsStore, LeaderboardDataStore)
		updateLeaderboard(bestTimeStore, LeaderboardDataStore2)
	end

	winsStore:OnUpdate(function(value)
		winsStat.Value = value
	end)
end)

script.GiveWin.Event:Connect(function(player)
	DataStore2("wins", player):Increment(1)
	DataStore2("totalWins", player):Increment(1)
end)

script.DeductWins.Event:Connect(function(player, amount)
	DataStore2("wins", player):Increment(amount)
end)
