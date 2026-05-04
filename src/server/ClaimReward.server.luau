local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local coinEvent = serverScriptService.Security.StageUpdater.CoinTake
local spinEvent = serverScriptService.Products.SpinWheel.GiveSpin
local skipHandler = require(serverScriptService.SkipHandler)
local notificationEvent = replicatedStorage.RemoteEvents:WaitForChild("anyNotification")

local rewards = {
	["1"] = {time = 300, action = function(p) coinEvent:Fire(p, 50); notificationEvent:FireClient(p, "+50 Coins!") end},
	["2"] = {time = 600, action = function(p) spinEvent:Fire(p, 1); notificationEvent:FireClient(p, "+1 Spin!") end},
	["3"] = {time = 900, action = function(p) coinEvent:Fire(p, 100); notificationEvent:FireClient(p, "+100 Coins!") end},
	["4"] = {time = 1200, action = function(p) skipHandler.AddSkips(p, 1); notificationEvent:FireClient(p, "+1 Skip!") end},
	["5"] = {time = 1500, action = function(p) spinEvent:Fire(p, 1); notificationEvent:FireClient(p, "+1 Spin!") end},
	["6"] = {time = 1800, action = function(p) coinEvent:Fire(p, 200); notificationEvent:FireClient(p, "+200 Coins!") end},
	["7"] = {time = 2100, action = function(p) skipHandler.AddSkips(p, 1); notificationEvent:FireClient(p, "+1 Skip!") end},
	["8"] = {time = 2400, action = function(p) coinEvent:Fire(p, 350); notificationEvent:FireClient(p, "+350 Coins!") end},
	["9"] = {time = 2700, action = function(p) skipHandler.AddSkips(p, 1); notificationEvent:FireClient(p, "+1 Skip!") end},
	["10"] = {time = 3000, action = function(p) coinEvent:Fire(p, 500); notificationEvent:FireClient(p, "+500 Coins!") end},
	["11"] = {time = 3300, action = function(p) spinEvent:Fire(p, 2); notificationEvent:FireClient(p, "+2 Spins!") end},
	["12"] = {
		time = 3600,
		action = function(p)
			coinEvent:Fire(p, 700)
			skipHandler.AddSkips(p, 1)
			spinEvent:Fire(p, 1)
			notificationEvent:FireClient(p, "+700 Coins!")
			task.wait(0.5)
			notificationEvent:FireClient(p, "+1 Skip!")
			task.wait(0.5)
			notificationEvent:FireClient(p, "+1 Spin!")
		end
	}
}

local function ensureClaimedFolder(player)
	local folder = player:FindFirstChild("ClaimedRewards")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ClaimedRewards"
		folder.Parent = player
	end
	return folder
end

replicatedStorage.RemoteEvents.claimPlaytimeReward.OnServerEvent:Connect(function(player, rewardID)
	local data = rewards[rewardID]
	if not data then return end

	local joinTime = player:GetAttribute("joinTime")
	if not joinTime then return end

	local currentTime = os.time()
	local requiredTime = joinTime + data.time

	if currentTime >= requiredTime then
		local claimedFolder = ensureClaimedFolder(player)
		if not claimedFolder:FindFirstChild(rewardID) then
			local claim = Instance.new("NumberValue")
			claim.Name = rewardID
			claim.Parent = claimedFolder
			data.action(player)
			replicatedStorage.RemoteEvents.claimPlaytimeReward:FireClient(player, rewardID)
		end
	end
end)
