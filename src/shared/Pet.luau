--TODO:MAIN-VARIABLES
local MarketplaceService = game:GetService("MarketplaceService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Spring = require(ReplicatedStorage.Module:WaitForChild("Spring"))

local Module = {}

local zoomEffectThreshold = 50
local acceleration = 2
local defaultSpeed = 40
local defaultJump = 40

function Module.new(FakeChar)
	if FakeChar.Name == LocalPlayer.Name then
		local Character	= LocalPlayer.Character
		
		ReplicatedStorage.RemoteEvents.PetEvent:FireServer("bwue281ms")
		task.wait(0.25)
		local PetModel	= workspace.Ignore:WaitForChild(FakeChar.Name .. "Pet", 30)

		local charSpring	= Spring:Create(
			1, 
			10, 
			2, 
			5
		)

		local grounded	= false
		local floor	= Vector3.new(0, 1, 0)

		local orientation = CFrame.new()
		local wheelRotation	= 0

		local tilt = 0

		local lastVelocity	= Vector3.new()
		if PetModel == nil or not PetModel:FindFirstChild("Frame") then
			PetModel = workspace.Ignore:WaitForChild(FakeChar.Name .. "Pet")
		end
		local lastPosition	= PetModel.Frame.Seat.WorldPosition
		local lastGroundState = false
		local timeSinceGround = os.clock()
		
		local FORCE = FakeChar:WaitForChild("VectorForce")
		local targetVelocity = Vector3.new()
		
		local jumping = false
		local jumpQueued = false
		local maxJumps = 1
		local jumpCount = 0
		
		-- DOUBLE JUMP PASS
		if MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, 1193224513) then
			maxJumps = 2
		end
		
		UserInputService.JumpRequest:Connect(function()
			if not LocalPlayer.isAFK.Value then
				jumpQueued = true
			end
		end)

		local MasterControl = LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 1).ControlModule
		local GetMoveVector = nil
		if MasterControl then
			local ControlModule = require(MasterControl)
			GetMoveVector = function()
				return ControlModule:GetMoveVector()
			end
		end	
		
		
		RunService:BindToRenderStep(FakeChar.Name .. "Pet", Enum.RenderPriority.Character.Value, function(deltaTime)
			if workspace.Ignore:FindFirstChild(LocalPlayer.Name) and FakeChar == nil then
				FakeChar = workspace.Ignore:FindFirstChild(LocalPlayer.Name)
			end
			
			if FakeChar and Character then
				if not PetModel then
					PetModel = workspace.Ignore:WaitForChild(FakeChar.Name .. "Pet")
				end
				
				--workspace.CurrentCamera.CameraSubject = FakeChar
				--workspace.CurrentCamera.CFrame += Vector3.new(0, 3, 0)

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
							v.CanQuery = false
							v.CanTouch = false
						end
					else
						if v:IsA("BasePart") then
							v.CanCollide = false
							v.CanQuery = false
							v.CanTouch = false
						end
					end
				end

				-- zoom effect
				if FakeChar.Velocity.Magnitude >= zoomEffectThreshold then
					LocalPlayer.PlayerGui.AnimeZoom.Frame.TransparencyValue.Value -= (FakeChar.Velocity.Magnitude - zoomEffectThreshold) / 100
				end

				for i, v in pairs(LocalPlayer.PlayerGui.AnimeZoom.Frame:GetChildren()) do
					if v:IsA("ImageLabel") then
						v.ImageTransparency = LocalPlayer.PlayerGui.AnimeZoom.Frame.TransparencyValue.Value
					end
				end
				LocalPlayer.PlayerGui.AnimeZoom.Frame.TransparencyValue.Value = 1

				local floorRay = Ray.new(FakeChar.Position, -floor.Unit * 10)
				local hit, position, normal = workspace:FindPartOnRayWithIgnoreList(floorRay, {FakeChar, workspace.Ignore})
				local floorDistance = (position - FakeChar.Position).Magnitude

				if hit and floorDistance <= 1 then
					if not grounded then
						jumpCount = 0
					end
					grounded = true
				else
					grounded = false
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

				local floorCFrame	= CFrame.new()
				local localFloor	= floorCFrame:vectorToObjectSpace(floor)

				local x, y	= math.atan2(-localFloor.X, localFloor.Y), math.atan2(localFloor.Z, localFloor.Y)
				local cfA	= CFrame.Angles(y, 0, 0) * CFrame.Angles(0, 0, x)
				local cfB	= CFrame.Angles(0, 0, x) * CFrame.Angles(y, 0, 0)

				floorCFrame	= floorCFrame * cfA:Lerp(cfB, 0.5)

				local localVelocity	= floorCFrame:vectorToObjectSpace(FakeChar.Velocity)
				localVelocity		= Vector3.new(localVelocity.X, 0, localVelocity.Z)

				if localVelocity.Magnitude > 1 then
					orientation = orientation:Lerp(CFrame.new(Vector3.new(), localVelocity), math.min(deltaTime * 10, 1))
				end

				local CurrentCamera = workspace.CurrentCamera

				local lookVector = CurrentCamera.CFrame.lookVector
				lookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
				local DriverDirection	= CFrame.new(Vector3.new(), lookVector)
				local DrivingSpace	= DriverDirection:vectorToObjectSpace(floor)

				local x2, y2	= math.atan2(-DrivingSpace.X, localFloor.Y), math.atan2(DrivingSpace.Z, DrivingSpace.Y)
				local cfA2	= CFrame.Angles(y2, 0, 0) * CFrame.Angles(0, 0, x2)
				local cfB2	= CFrame.Angles(0, 0, x2) * CFrame.Angles(y2, 0, 0)

				DriverDirection	= DriverDirection * cfA2:Lerp(cfB2, 0.5)

				local input	= Vector3.new()
				local hasFireParticle = false
				local anyKeysDown = false
				local tweenInf = TweenInfo.new(0.15)

				local function handleMovementInput(keyVec)
					if LocalPlayer.isAFK.Value then return end
					input += keyVec
					anyKeysDown = true
					PetModel = workspace.Ignore:FindFirstChild(FakeChar.Name .. "Pet")
					if PetModel and PetModel:FindFirstChild("NormalFire") and not hasFireParticle then
						PetModel.NormalFire.ParticleEmitter:Emit(0.5)
						hasFireParticle = true
						if not PetModel.NormalFire.Sound.Playing then
							TweenService:Create(PetModel.NormalFire.Sound, tweenInf, {Volume = 0.03}):Play()
							PetModel.NormalFire.Sound:Play()
						end
					end
				end

				if not UserInputService:GetFocusedTextBox() then
					if UserInputService:IsKeyDown(Enum.KeyCode.W) then
						handleMovementInput(Vector3.new(0, 0, -1))
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.S) then
						handleMovementInput(Vector3.new(0, 0, 1))
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.A) then
						handleMovementInput(Vector3.new(-1, 0, 0))
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.D) then
						handleMovementInput(Vector3.new(1, 0, 0))
					end
				end

				if not anyKeysDown then
					--[[if not PetModel:FindFirstChild("NormalFire") then
						print(PetModel.Name)
						print("changed 2")
						PetModel = workspace.Ignore:FindFirstChild(Character.Name .. "Pet")
						print(PetModel.Name)
					end
					if PetModel:FindFirstChild("NormalFire") and PetModel:FindFirstChild("NormalFire"):FindFirstChild("Sound") then
						game:GetService("TweenService"):Create(PetModel:FindFirstChild("NormalFire").Sound, tweenInf, {Volume = 0}):Play()
						PetModel.NormalFire.Sound:Stop()
					end]]
				end

				if input.Magnitude > 0 then
					input = input.Unit
				end

				if UserInputService.TouchEnabled and GetMoveVector and not LocalPlayer.isAFK.Value then
					local MovementDirection = GetMoveVector()
					input = MovementDirection
				end
				
				local speedValue = PetModel:FindFirstChild("Speed")
				local speedPet = (speedValue and speedValue:IsA("NumberValue")) and speedValue.Value or defaultSpeed
				
				if ReplicatedStorage.ClientScripts.speedCoilOn.Value == true then
					speedPet *= 1.2
				end
				
				targetVelocity	= DriverDirection:vectorToWorldSpace(input * speedPet)

				FORCE.Force = (targetVelocity - FakeChar.Velocity) * FakeChar:GetMass() * acceleration
				
				local jumpValue = PetModel:FindFirstChild("Jump")
				local jumpPet = (jumpValue and jumpValue:IsA("NumberValue")) and jumpValue.Value or defaultJump
				
				if jumpQueued and jumpCount < maxJumps then
					FakeChar.Velocity = Vector3.new(FakeChar.Velocity.X, jumpPet, FakeChar.Velocity.Z)
					FakeChar.Jump:Play()

					jumpCount += 1
					jumping = true
				end

				jumpQueued = false

				local newCFrame	= floorCFrame * orientation
				local localVelocity	= newCFrame:vectorToObjectSpace(FakeChar.Velocity)
				local speed = FakeChar.Velocity.Magnitude

				if grounded then
					wheelRotation	= wheelRotation + ((speed * deltaTime) / 1.65) % (math.pi * 2)
					FakeChar.Sound.Volume = speed / 1000
					FakeChar.WindLoop.Volume = 0
					if lastGroundState == false then
						FakeChar.Hit.Volume = (os.clock() - timeSinceGround) / 3
						FakeChar.Hit:Play()
					end
					lastGroundState = true

				elseif not grounded then
					FakeChar.WindLoop.Volume = speed / 1250
					FakeChar.Sound.Volume = 0
					if lastGroundState == true then
						timeSinceGround = os.clock()
					end
					lastGroundState = false
				end

				local function Lerp(a, b, d) 
					return a + (b - a) * d 
				end

				tilt = Lerp(tilt, -localVelocity.X / 15, math.min(deltaTime * 5, 1))
				
				while not PetModel:FindFirstChild("Frame") do
					task.wait()
					if not PetModel:FindFirstChild("Frame") then
						PetModel = workspace.Ignore:FindFirstChild(FakeChar.Name .. "Pet")
					end
				end
				
				PetModel.Frame.CFrame = CFrame.new(FakeChar.Position) 
					* newCFrame 
					* CFrame.new(0, 1.3, 0)
					* CFrame.Angles(0, 0, tilt)
					
				if PetModel:FindFirstChild("Wheel1") then
					PetModel.Wheel1.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel1.CFrame * CFrame.Angles(-wheelRotation, 0, 0)
				end
					
				if PetModel:FindFirstChild("Wheel2") then
					PetModel.Wheel2.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel2.CFrame * CFrame.Angles(-wheelRotation, 0, 0)
				end
					
				if PetModel:FindFirstChild("Wheel3") then
					PetModel.Wheel3.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel3.CFrame * CFrame.Angles(-wheelRotation, 0, 0)
				end
					
				if PetModel:FindFirstChild("Wheel4") then
					PetModel.Wheel4.CFrame = PetModel.Frame.CFrame * PetModel.Frame.Wheel4.CFrame * CFrame.Angles(-wheelRotation, 0, 0)
				end

				Character.RightHand.CFrame = PetModel.Grips.CFrame * CFrame.new(0.5, 0, 0.5) * CFrame.Angles(math.pi / 4, 0, 0)
				Character.LeftHand.CFrame = PetModel.Grips.CFrame * CFrame.new(-0.5, 0, 0.5) * CFrame.Angles(math.pi / 4, 0, 0)

				Character.LeftFoot.CFrame = PetModel.Frame.LeftFoot.WorldCFrame * CFrame.new(0, 0.1, 0)
				Character.RightFoot.CFrame = PetModel.Frame.RightFoot.WorldCFrame * CFrame.new(0, 0.1, 0)
					
				local CurrentSpeed : number = localVelocity.Magnitude

				local DurationTransition : number = 0.5

				local BackPosRight = CFrame.new(0.191, 0.024, 0.136)
				local FrontPosRight = CFrame.new(0.967, -0.411, -1)

				local speedPositionMappings = {
					{ speedRange = {0, 10}, position = BackPosRight },
					{ speedRange = {10, 40}, position = FrontPosRight },
					{ speedRange = {40, 80}, position = BackPosRight },
					{ speedRange = {80, 120}, position = FrontPosRight },
					{ speedRange = {120, 160}, position = BackPosRight },
				}

				local CurrentFootPosition : CFrame

				for _, mapping in ipairs(speedPositionMappings) do
					local minSpeed, maxSpeed = unpack(mapping.speedRange)
					if CurrentSpeed >= minSpeed and CurrentSpeed < maxSpeed then
						local t = (CurrentSpeed - minSpeed) / (maxSpeed - minSpeed)
						CurrentFootPosition = mapping.position
						break
					end
				end

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
				Character.Head.CFrame = Character.UpperTorso.CFrame * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, tilt * 2, 0)
					
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

				lastVelocity	= seatVelocity
			else
				PetModel:Destroy()
				Character:Destroy()
				RunService:UnbindFromRenderStep(FakeChar.Name .. "Pet")
			end
		end)
	end
end

return Module