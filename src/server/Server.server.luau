local ServerStorage	= game:GetService("ServerStorage")
local Players		= game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Spring = require(ReplicatedStorage.Module.Spring)
local ds2 = require(ReplicatedStorage.Module.DataStore2)
local ih = require(game.ServerScriptService.InventoryHandler)
local justSpawned

Players.PlayerAdded:Connect(function(player)
	justSpawned = true
	local character	= game.ReplicatedStorage.Resource.Character:Clone()
	character.Name		= player.Name
	character.Parent	= workspace.Ignore

	character:SetNetworkOwner(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local character	= workspace.Ignore:FindFirstChild(player.Name)
	local Pet = workspace.Ignore:FindFirstChild(player.Name .. "Pet")
	if character then
		character:Destroy()
	end
	if Pet then
		Pet:Destroy()
	end
end)

ReplicatedStorage.RemoteEvents.PetEvent.OnServerEvent:Connect(function(LocalPlayer, EventName)
	if EventName == "bwue281ms" then
		local Character	= LocalPlayer.Character
		for i, v in pairs(Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Character"
			end
		end
		
		local FakeChar = workspace.Ignore:WaitForChild(Character.Name)
		local equipped = ih.GetEquippedItem(LocalPlayer)
		
		repeat
			if workspace.Ignore:FindFirstChild(FakeChar.Name .. "Pet") then
				workspace.Ignore:FindFirstChild(FakeChar.Name .. "Pet"):Destroy()
			end
			task.wait(0.01)
		until not workspace.Ignore:FindFirstChild(FakeChar.Name .. "Pet")
		
		local PetModel
		
		for _, v in pairs(workspace.Ignore:GetChildren()) do
			if v.Name == FakeChar.Name .. "Pet" then
				v:Destroy()
			end
		end
		
		if equipped == "default" then
			PetModel = ReplicatedStorage.Resource.Pet:Clone()
		else
			PetModel = ReplicatedStorage.Resource.ItemPets[equipped]:Clone()
		end
		PetModel.Name = FakeChar.Name .. "Pet"
		PetModel.Parent = workspace.Ignore
		PetModel.Frame.CFrame = FakeChar.CFrame
		PetModel.Frame.Anchored = true

		for i = 1, 4 do
			local wheel = PetModel:FindFirstChild("Wheel" .. i)
			if wheel then
				wheel.Anchored = true
			end
		end
		
		local floor	= Vector3.new(0, 1, 0)
		local orientation = CFrame.new()
		local grounded = false

		local lastVelocity	= Vector3.new()
		local lastPosition	= PetModel.Frame.Seat.WorldPosition

		local charSpring = Spring:Create(
			1, 
			10, 
			2, 
			5
		)

		local tilt = 0
		script.PetServer2Server.Event:Connect(function(player, arg1)
			equipped = arg1
			if player.Name == FakeChar.Name then
				if equipped == "default" then
					PetModel = ReplicatedStorage.Resource.Pet:Clone()
				else
					PetModel = ReplicatedStorage.Resource.ItemPets[equipped]:Clone()
				end
				
				for _, v in pairs(workspace.Ignore:GetChildren()) do
					if v.Name == FakeChar.Name .. "Pet" then
						v:Destroy()
					end
				end
				
				PetModel.Name = FakeChar.Name .. "Pet"
				PetModel.Parent = workspace.Ignore
				PetModel.Frame.CFrame = FakeChar.CFrame
				PetModel.Frame.Anchored = true

				for i = 1, 4 do
					local wheel = PetModel:FindFirstChild("Wheel" .. i)
					if wheel then
						wheel.Anchored = true
					end
				end
			end
		end)
		
		--RunService:BindToRenderStep(FakeChar.Name .. "Pet", Enum.RenderPriority.Character.Value, function(deltaTime)
		local connection

		local function endConnection(event)
			event:Disconnect(connection)
		end

		game.Players.PlayerRemoving:Connect(function(plr)
			if plr == LocalPlayer then
				endConnection(connection)
			end
		end)

		connection = RunService.Heartbeat:Connect(function(deltaTime)
			if not PetModel then
				if workspace.Ignore:FindFirstChild(LocalPlayer.Name .. "Pet") then
					PetModel = workspace.Ignore:FindFirstChild(LocalPlayer.Name .. "Pet")
				else
					return
				end
			end
			local Humanoid: Humanoid = Character.Humanoid
			Humanoid.PlatformStand = true
			for i, v in pairs(Character:GetDescendants()) do
				if v.Name ~= "LowerTorso" then
					if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") or v:IsA("BasePart") then
						v.EnableFluidForces = false
						if not v.Parent:IsA("Accessory") then
							v.Anchored = true
						end
						v.CanCollide = false
						v.CanTouch = false
						v.CanQuery = false
					end
				else
					if v:IsA("BasePart") then
						v.CanCollide = false
						v.CanTouch = false
						v.CanQuery = false
					end
				end
			end
			
			local floorRay = Ray.new(FakeChar.Position, -floor.Unit * 10)
			local hit, position, normal	= workspace:FindPartOnRayWithIgnoreList(floorRay, {FakeChar, workspace.Ignore})
			local floorDistance = (position - FakeChar.Position).Magnitude

			if floorDistance <= 1 then
				grounded = true
			else
				grounded	= false
			end

			if hit then
				if grounded then
					floor	= floor:Lerp(normal, math.min(deltaTime * 20, 1))
				else
					floor	= floor:Lerp(normal, math.min(deltaTime * 5, 1))
				end
			else
				floor	= floor:Lerp(Vector3.new(0, 1, 0), math.min(deltaTime, 1))
			end
			
			local floorCFrame = CFrame.new()
			local localFloor = floorCFrame:vectorToObjectSpace(floor)

			local x, y = math.atan2(-localFloor.X, localFloor.Y), math.atan2(localFloor.Z, localFloor.Y)
			local cfA = CFrame.Angles(y, 0, 0) * CFrame.Angles(0, 0, x)
			local cfB = CFrame.Angles(0, 0, x) * CFrame.Angles(y, 0, 0)

			floorCFrame = floorCFrame * cfA:Lerp(cfB, 0.5)

			local localVelocity = floorCFrame:vectorToObjectSpace(FakeChar.Velocity)
			localVelocity = Vector3.new(localVelocity.X, 0, localVelocity.Z)

			if localVelocity.Magnitude > 1 then
				orientation = orientation:Lerp(CFrame.new(Vector3.new(), localVelocity), math.min(deltaTime * 10, 1))
			end
			
			local newCFrame	= floorCFrame * orientation
			if not PetModel:FindFirstChild("Frame") then
				PetModel = workspace.Ignore:FindFirstChild(Character.Name .. "Pet")
			end
			if PetModel == nil then
				return
			end
			if not LocalPlayer.Character then
				endConnection()
			end
			
			local function Lerp(a, b, d) 
				return a + (b - a) * d 
			end

			tilt = Lerp(tilt, -localVelocity.X / 60, math.min(deltaTime * 5, 1))
			
			PetModel.Frame.CFrame = CFrame.new(FakeChar.Position) 
				* newCFrame 
				* CFrame.new(0, 1.3, 0)
				
			if PetModel.Frame:FindFirstChild("Wheel1") then
				PetModel.Wheel1.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel1.CFrame * CFrame.Angles(0, 0, 0)
			end

			if PetModel.Frame:FindFirstChild("Wheel2") then
				PetModel.Wheel2.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel2.CFrame * CFrame.Angles(0, 0, 0)
			end

			if PetModel.Frame:FindFirstChild("Wheel3") then
				PetModel.Wheel3.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel3.CFrame * CFrame.Angles(0, 0, 0)
			end

			if PetModel.Frame:FindFirstChild("Wheel4") then
				PetModel.Wheel4.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel4.CFrame * CFrame.Angles(0, 0, 0)
			end
				
			Character.RightHand.CFrame	= PetModel.Grips.CFrame * CFrame.new(0.5, 0, 0.5) * CFrame.Angles(math.pi / 4, 0, 0)
			Character.LeftHand.CFrame	= PetModel.Grips.CFrame * CFrame.new(-0.5, 0, 0.5) * CFrame.Angles(math.pi / 4, 0, 0)

			Character.LeftFoot.CFrame = PetModel.Frame.LeftFoot.WorldCFrame * CFrame.new(0, 0.1, 0)
			Character.RightFoot.CFrame = PetModel.Frame.RightFoot.WorldCFrame * CFrame.new(0, 0.1, 0)

			local isMoving = PetModel and PetModel.Frame.Velocity.Magnitude > 0.1

			local seatVelocity = (PetModel.Frame.Seat.WorldPosition - lastPosition) / deltaTime
			local acceleration = (seatVelocity - lastVelocity)
			lastPosition = PetModel.Frame.Seat.WorldPosition

			charSpring:Shove(-acceleration)
			charSpring:Update(deltaTime)

			if charSpring.Velocity.Magnitude >= 100 then
				charSpring:Shove(-(charSpring.Velocity))
			end

			local position = PetModel.Frame.Seat.WorldCFrame:vectorToObjectSpace(charSpring.Position)

			local desiredPosition = Vector3.new(-position.X, math.max(position.Y, -0.8 / 0.1), position.Z) * 0.1			

			Character.LowerTorso.CFrame = PetModel.Frame.Seat.WorldCFrame * CFrame.new(desiredPosition)
			Character.UpperTorso.CFrame = Character.LowerTorso.CFrame * CFrame.new(0, Character.LowerTorso.Size.Y / 2, 0) * CFrame.Angles(-math.pi / 16 - position.Z * 0.05, 0, tilt * 0.2) * CFrame.new(0, Character.UpperTorso.Size.Y / 2, 0)
			Character.Head.CFrame = Character.UpperTorso.CFrame * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, tilt, 0)

			do 
				local leg, foreleg, foot = Character.RightUpperLeg, Character.RightLowerLeg, Character.RightFoot
				local hipCFrame = Character.LowerTorso.CFrame * CFrame.new(0.6, -0.3, 0)
				local footCFrame = foot.CFrame * CFrame.new(0, 0.1, 0.2)

				local distance = math.max((hipCFrame.p - foot.Position).Magnitude, 1)

				local a, b, c = foreleg.Size.Y, leg.Size.Y, math.min(distance, leg.Size.Y + foreleg.Size.Y)
				local A = math.acos((-a^2 + b^2 + c^2) / (2 * b * c))
				local C = math.acos((a^2 + b^2 - c^2) / (2 * a * b))

				if not A then A = 0 end
				if not C then C = 0 end

				local offsetA = hipCFrame:toObjectSpace(footCFrame)
				local x = math.atan2(offsetA.X, -offsetA.Y)
				hipCFrame = hipCFrame * CFrame.Angles(0, 0, x)
				local offsetB = hipCFrame:toObjectSpace(footCFrame)
				local y = math.atan2(-offsetB.Z, -offsetB.Y)
				hipCFrame = hipCFrame * CFrame.Angles(y, 0, 0)

				leg.CFrame = hipCFrame * CFrame.Angles(A, math.rad(-30), math.rad(30)) * CFrame.new(0, -leg.Size.Y / 2, 0)
				foreleg.CFrame = leg.CFrame * CFrame.new(0, -leg.Size.Y / 2, 0) * CFrame.Angles(C - math.pi, 0, 0) * CFrame.new(0, -foreleg.Size.Y / 2, 0)
				foot.CFrame = foreleg.CFrame * CFrame.new(0, -foreleg.Size.Y / 2, 0)
			end

			do
				local leg, foreleg, foot = Character.LeftUpperLeg, Character.LeftLowerLeg, Character.LeftFoot
				local hipCFrame = Character.LowerTorso.CFrame * CFrame.new(-0.6, -0.3, 0)
				local footCFrame = foot.CFrame * CFrame.new(0, 0.1, 0.2)
				
				local distance = math.max((hipCFrame.p - foot.Position).Magnitude, 1)

				local a, b, c = foreleg.Size.Y, leg.Size.Y, math.min(distance, leg.Size.Y + foreleg.Size.Y)
				local A = math.acos((-a^2 + b^2 + c^2) / (2 * b * c))
				local C = math.acos((a^2 + b^2 - c^2) / (2 * a * b))

				if not A then A = 0 end
				if not C then C = 0 end
				
				local offsetA = hipCFrame:toObjectSpace(footCFrame)
				local x = math.atan2(offsetA.X, -offsetA.Y)
				hipCFrame = hipCFrame * CFrame.Angles(0, 0, x)
				local offsetB = hipCFrame:toObjectSpace(footCFrame)
				local y = math.atan2(-offsetB.Z, -offsetB.Y)
				hipCFrame = hipCFrame * CFrame.Angles(y, 0, 0)

				leg.CFrame = hipCFrame * CFrame.Angles(A, math.rad(30), math.rad(-30)) * CFrame.new(0, -leg.Size.Y / 2, 0)
				foreleg.CFrame = leg.CFrame * CFrame.new(0, -leg.Size.Y / 2, 0) * CFrame.Angles(C - math.pi, 0, 0) * CFrame.new(0, -foreleg.Size.Y / 2, 0)
				foot.CFrame = foreleg.CFrame * CFrame.new(0, -foreleg.Size.Y / 2, 0)
			end

			do
				local arm, forearm, hand	= Character.RightUpperArm, Character.RightLowerArm, Character.RightHand
				local shoulderCFrame	= Character.UpperTorso.CFrame * CFrame.new(0.9, 0.45, 0)
				local handCFrame		= hand.CFrame * CFrame.new(0, hand.Size.Y / 2, 0)

				local distance = math.max((shoulderCFrame.p - hand.Position).Magnitude, 1)

				local a, b, c	= forearm.Size.Y, arm.Size.Y, math.min(distance, arm.Size.Y + forearm.Size.Y)
				local A			= math.acos((-a^2 + b^2 + c^2) / (2 * b * c))
				local C			= math.acos((a^2 + b^2 - c^2) / (2 * a * b))

				if not A then A = 0 end
				if not C then C = 0 end

				local offsetB	= shoulderCFrame:toObjectSpace(handCFrame)
				local y			= math.atan2(-offsetB.Z, -offsetB.Y)
				shoulderCFrame		= shoulderCFrame * CFrame.Angles(y, 0, 0)
				local offsetA	= shoulderCFrame:toObjectSpace(handCFrame)
				local x			= math.atan2(offsetA.X, -offsetA.Y)
				shoulderCFrame		= shoulderCFrame * CFrame.Angles(0, 0, x)

				shoulderCFrame	= shoulderCFrame * CFrame.Angles(0, math.abs(position.X * 0.1), 0)

				arm.CFrame		= shoulderCFrame * CFrame.Angles(-A, 0, 0) * CFrame.new(0, -arm.Size.Y / 2, 0)
				forearm.CFrame	= arm.CFrame  
					* CFrame.Angles(math.pi - C,  0, -51) 
					* CFrame.new(0.6, -forearm.Size.Y / 2, 0.1)
			end

			do
				local arm, forearm, hand	= Character.LeftUpperArm, Character.LeftLowerArm, Character.LeftHand
				local shoulderCFrame	= Character.UpperTorso.CFrame * CFrame.new(-0.9, 0.45, 0)
				local handCFrame		= hand.CFrame * CFrame.new(0, hand.Size.Y / 2, 0)

				local distance = math.max((shoulderCFrame.p - hand.Position).Magnitude, 1)

				local a, b, c	= forearm.Size.Y, arm.Size.Y, math.min(distance, arm.Size.Y + forearm.Size.Y)
				local A			= math.acos((-a^2 + b^2 + c^2) / (2 * b * c))
				local C			= math.acos((a^2 + b^2 - c^2) / (2 * a * b))

				if not A then A = 0 end
				if not C then C = 0 end

				local offsetB	= shoulderCFrame:toObjectSpace(handCFrame)
				local y			= math.atan2(-offsetB.Z, -offsetB.Y)
				shoulderCFrame		= shoulderCFrame * CFrame.Angles(y, 0, 0)
				local offsetA	= shoulderCFrame:toObjectSpace(handCFrame)
				local x			= math.atan2(offsetA.X, -offsetA.Y)
				shoulderCFrame		= shoulderCFrame * CFrame.Angles(0, 0, x)

				shoulderCFrame	= shoulderCFrame * CFrame.Angles(0, -math.abs(position.X * 0.1), 0)

				arm.CFrame		= shoulderCFrame * CFrame.Angles(-A, 0, 0) * CFrame.new(0, -arm.Size.Y / 2, 0)
				forearm.CFrame = arm.CFrame 
					* CFrame.Angles(math.pi - C, 0, 51) 
					* CFrame.new(-0.6, -forearm.Size.Y / 2, 0.1)
			end
			
			lastVelocity = seatVelocity
			
		end)
	end
end)

ReplicatedStorage.RemoteEvents.InvEvent.OnServerEvent:Connect(function(localPlr, inv)
	local pet = workspace.Ignore:FindFirstChild(localPlr.Name .. "Pet")
	local char = workspace:FindFirstChild(localPlr.Name)

	if char then
		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = inv and 1 or 0
			elseif obj:IsA("Decal") then
				obj.Transparency = inv and 1 or 0
			end
		end
	end

	if pet then
		for _, part in ipairs(pet:GetDescendants()) do
			if (part:IsA("MeshPart") or part.Name == "WheelCylinder") and part:IsA("BasePart") then
				part.Transparency = inv and 1 or 0
			end
		end
	end
end)


local debounce = {}

task.spawn(function()
	while true do
		task.wait(0.1)
		for _, character in pairs(workspace.Ignore:GetChildren()) do
			if not character:IsA("Model") then
				local player = Players:FindFirstChild(character.Name)
				if player and not debounce[player] then
					local currentStage = player.leaderstats.Stage.Value
					local stageObjects = {}
					local stageModel

					if currentStage == ReplicatedStorage.Info.TotalStages.Value + 1 then
						stageModel = workspace.EndTile:FindFirstChild("Checkpoint")
					elseif currentStage == 0 then
						stageModel = workspace.Lobby:FindFirstChild("Checkpoint")
					else
						stageModel = workspace.Stages:FindFirstChild("Stage" .. currentStage)
					end

					for _, cp in pairs(CollectionService:GetTagged("Checkpoint")) do
						local stage = cp:GetAttribute("Stage")
						stageObjects[stage] = stageObjects[stage] or {}
						table.insert(stageObjects[stage], cp)
					end

					if stageModel then
						local cf, size = stageModel:GetBoundingBox()
						local stageBottomY = cf.Position.Y - (size.Y / 2)
						local threshold = stageBottomY - 100
						if character.Position.Y < threshold then
							debounce[player] = true
							task.delay(1, function()
								debounce[player] = nil
							end)

							local hidden = player:FindFirstChild("hidden")
							if hidden and not justSpawned then
								hidden.Deaths.Value = hidden.Deaths.Value + 1
							end

							if justSpawned then
								justSpawned = nil
							end

							player:SetAttribute("Safe", true)
							player:SetAttribute("Safe2", 0.5)
							ReplicatedStorage.RemoteEvents.clientTP:FireClient(player, stageObjects[currentStage])
						end
					end
				end
			end
		end
	end
end)
