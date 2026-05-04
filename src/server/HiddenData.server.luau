local DataStore = game:GetService("DataStoreService")
local rs = game:GetService("ReplicatedStorage")
local ds = DataStore:GetDataStore("HighStageSave")

game.Players.PlayerAdded:connect(function(player)
	local isAfk = Instance.new("BoolValue", player)
	isAfk.Name = "isAFK"
	isAfk.Value = false
	
	local leader = Instance.new("Folder", player)
	leader.Name = "hidden"
	
	local Data = Instance.new("IntValue",leader)
	Data.Name = "HighestStage"
	Data.Value = 0
	
	local Data2 = Instance.new("IntValue",leader)
	Data2.Name = "Deaths"
	Data2.Value = 0
	
	local Data3 = Instance.new("NumberValue", leader)
	Data3.Name = "Spins"
	Data3.Value = ds:GetAsync(player.UserId) or 0
	
	local Data4 = Instance.new("NumberValue", leader)
	Data4.Name = "WorldsFinished"
	Data4.Value = ds:GetAsync(player.UserId) or 0
	
	repeat
		task.wait()
	until player.Character ~= nil
	ds:SetAsync(player.UserId, Data.Value)
	Data.Changed:connect(function()
		ds:SetAsync(player.UserId, Data.Value)
	end)
	
	ds:SetAsync(player.UserId, Data3.Value)
	Data3.Changed:connect(function()
		ds:SetAsync(player.UserId, Data3.Value)
	end)
	
	ds:SetAsync(player.UserId, Data4.Value)
	Data4.Changed:connect(function()
		ds:SetAsync(player.UserId, Data4.Value)
	end)
end)

game.Players.PlayerRemoving:connect(function(player)
	--ds:SetAsync(player.UserId, player.hidden.HighestStage.Value) 
	ds:SetAsync(player.UserId, player.hidden.Spins.Value) 
end)
