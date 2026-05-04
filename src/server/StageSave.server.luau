local DataStore = game:GetService("DataStoreService")
local ds = DataStore:GetDataStore("LeaderStatSave")

game.Players.PlayerAdded:Connect(function(player)
	local leader = Instance.new("Folder")
	leader.Name = "leaderstats"
	leader.Parent = player

	local Data = Instance.new("IntValue")
	Data.Name = "Stage"
	Data.Parent = leader
	Data.Value = ds:GetAsync(player.UserId) or 0

	repeat task.wait() until player.Character

	local checkpoint = workspace:FindFirstChild(tostring(Data.Value))
	if checkpoint and checkpoint:FindFirstChild("Checkpoint") and checkpoint.Checkpoint:FindFirstChild("Part") then
		player.Character:MoveTo(checkpoint.Checkpoint.Part.Position + Vector3.new(0,2,0))
	end

	Data.Changed:Connect(function()
		ds:SetAsync(player.UserId, Data.Value)
	end)
end)

game.Players.PlayerRemoving:Connect(function(player)
	ds:SetAsync(player.UserId, player.leaderstats.Stage.Value)
end)
