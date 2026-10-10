local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local SpawnConfig = require(ReplicatedStorage.Shared.Config.SpawnConfig)
local Make = require(script.Parent.Parent.UI.Make)

local VentController = {}

local FLAP_STIFFNESS = 38
local FLAP_DAMPING = 1.6
local FLAP_MAX_ANGLE = math.rad(110)
local FLAP_BURST_SPEED = 16
local CROSS_DISTANCE = 1.2

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local random = Random.new()

local remote: RemoteEvent
local fade: Frame
local controls: any = nil
local session = 0
local connections: { RBXScriptConnection } = {}
local loops: { Sound } = {}
local cameraTaken = false

local function disconnectAll()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function stopLoops(fadeTime: number)
	for _, sound in loops do
		local tween = TweenService:Create(sound, TweenInfo.new(fadeTime), { Volume = 0 })
		tween.Completed:Once(function()
			sound:Destroy()
		end)
		tween:Play()
	end
	table.clear(loops)
end

local function setControls(enabled: boolean)
	if not controls then
		return
	end
	pcall(function()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

local function restoreCamera()
	if not cameraTaken then
		return
	end
	cameraTaken = false
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function fadeTo(transparency: number, time: number)
	TweenService:Create(fade, TweenInfo.new(time), { BackgroundTransparency = transparency }):Play()
end

local function finish()
	session += 1
	disconnectAll()
	stopLoops(0.3)
	restoreCamera()
	setControls(true)
	fadeTo(1, 0.25)
end

local function cancelForTeleport()
	finish()
	local current = session
	fadeTo(0, 0.12)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local from = root and root.Position
	task.spawn(function()
		local started = os.clock()
		while session == current and os.clock() - started < 4 do
			if not root or not from or not root.Parent or (root.Position - from).Magnitude > 20 then
				break
			end
			task.wait(0.1)
		end
		if session == current then
			fadeTo(1, 0.35)
		end
	end)
end

local function prepare()
	session += 1
	local current = session
	disconnectAll()
	stopLoops(0.1)
	setControls(false)
	fade.BackgroundTransparency = 0

	for _, name in { "PipeRush", "PipeWater" } do
		local sound = SoundPlayer.Loop(name)
		if sound then
			table.insert(loops, sound)
		end
	end

	task.spawn(function()
		while session == current do
			task.wait(random:NextNumber(0.2, 0.55))
			if session == current then
				SoundPlayer.Play("PipeClank", nil, random:NextNumber(0.35, 1))
			end
		end
	end)

	task.spawn(function()
		local started = os.clock()
		workspace:WaitForChild("Lobby", 20)
		local remaining = SpawnConfig.BlackScreenTime - (os.clock() - started)
		if remaining > 0 then
			task.wait(remaining)
		end
		if session == current then
			remote:FireServer("Ready")
		end
	end)
end

local function bodyParts(character: Model): { BasePart }
	local parts = {}
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function randomUnit(): Vector3
	local vector = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1))
	if vector.Magnitude < 0.05 then
		return Vector3.xAxis
	end
	return vector.Unit
end

local function launch(character: Model, exitCFrame: CFrame)
	session += 1
	local current = session
	disconnectAll()
	stopLoops(0.4)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	local look = exitCFrame.LookVector
	local right = exitCFrame.RightVector
	local parts = bodyParts(character)
	local launchedAt = os.clock()
	local kickedAt: number? = nil
	local calmSince: number? = nil

	if SpawnConfig.CinematicCamera then
		cameraTaken = true
		local cameraPosition = exitCFrame.Position + look * 15 + right * 6 + Vector3.new(0, -2.5, 0)
		local focus = exitCFrame.Position + look * 5 + Vector3.new(0, -3, 0)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(cameraPosition, focus)
		table.insert(
			connections,
			RunService.RenderStepped:Connect(function(dt)
				if kickedAt and root.Parent then
					focus = focus:Lerp(root.Position, 1 - math.exp(-dt * 6))
				end
				camera.CFrame = CFrame.lookAt(cameraPosition, focus)
			end)
		)
	end
	fadeTo(1, 0.35)

	table.insert(
		connections,
		humanoid.Died:Connect(function()
			if session == current then
				finish()
			end
		end)
	)

	local drive: RBXScriptConnection
	drive = RunService.Heartbeat:Connect(function()
		if session ~= current or not root.Parent then
			drive:Disconnect()
			return
		end
		local now = os.clock()

		if not kickedAt then
			local along = (root.Position - exitCFrame.Position):Dot(look)
			if along < 0 and now - launchedAt < 2 then
				for _, part in parts do
					local velocity = part.AssemblyLinearVelocity
					local lateral = velocity - look * velocity:Dot(look)
					part.AssemblyLinearVelocity = look * SpawnConfig.PushSpeed + lateral * 0.25
				end
			else
				kickedAt = now
				local side = right * random:NextNumber(-5, 5)
				local kick = look * SpawnConfig.KickForward + Vector3.new(0, SpawnConfig.KickUp, 0) + side
				for _, part in parts do
					part.AssemblyLinearVelocity = kick
				end
				root.AssemblyAngularVelocity = randomUnit() * SpawnConfig.KickSpin
			end
			return
		end

		local elapsed = now - kickedAt
		if root.AssemblyLinearVelocity.Magnitude < 3 then
			calmSince = calmSince or now
		else
			calmSince = nil
		end
		local settled = calmSince ~= nil and now - calmSince > 0.35
		if (settled and elapsed >= SpawnConfig.MinLyingTime) or elapsed >= SpawnConfig.MaxLyingTime then
			drive:Disconnect()
			remote:FireServer("Landed")
		end
	end)
	table.insert(connections, drive)
end

local function watchVent()
	local lobby = workspace:WaitForChild("Lobby", 60)
	local vent = lobby and lobby:WaitForChild("Vent", 10)
	if not vent then
		return
	end
	local flap = vent:WaitForChild("Flap", 10) :: Model?
	local exit = vent:WaitForChild("Exit", 10) :: BasePart?
	local lamp = vent:WaitForChild("WarningLamp", 10) :: BasePart?
	if not flap or not exit or not lamp then
		return
	end
	local plate = flap:FindFirstChild("Plate") or flap
	local light = lamp:FindFirstChildOfClass("PointLight")
	local lampOff = lamp.Color
	local lampOn = Color3.fromRGB(255, 50, 35)
	local hinge = flap:GetPivot()

	local angle, speed = 0, 0
	local lastAlong: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
	local lampUntil = 0
	local lampLit = false

	RunService.Heartbeat:Connect(function(dt)
		dt = math.min(dt, 1 / 20)
		local exitCFrame = exit.CFrame
		local look = exitCFrame.LookVector
		local now = os.clock()

		for _, other in Players:GetPlayers() do
			local character = other.Character
			if not character then
				continue
			end
			if character:GetAttribute("VentFlight") then
				lampUntil = now + 1
				local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					local along = (root.Position - exitCFrame.Position):Dot(look)
					local previous = lastAlong[character]
					if previous and previous < -CROSS_DISTANCE and along >= -CROSS_DISTANCE then
						speed = math.max(speed, FLAP_BURST_SPEED)
						SoundPlayer.Play("VentBang", exit)
					end
					lastAlong[character] = along
				end
			else
				lastAlong[character] = nil
			end
		end

		if angle ~= 0 or speed ~= 0 then
			speed += (-FLAP_STIFFNESS * angle - FLAP_DAMPING * speed) * dt
			angle += speed * dt
			if angle < 0 then
				if speed < -2.5 then
					SoundPlayer.Play("VentFlapHit", plate, math.clamp(-speed / 10, 0.2, 1))
				end
				angle = 0
				speed = -speed * 0.3
				if speed < 0.5 then
					speed = 0
				end
			elseif angle > FLAP_MAX_ANGLE then
				angle = FLAP_MAX_ANGLE
				speed = -speed * 0.2
			end
			flap:PivotTo(hinge * CFrame.Angles(angle, 0, 0))
		end

		local lit = now < lampUntil and math.floor(now * 6) % 2 == 0
		if lit ~= lampLit then
			lampLit = lit
			lamp.Color = if lit then lampOn else lampOff
			if light then
				light.Brightness = if lit then 3 else 0
			end
		end
	end)
end

function VentController.Init()
	remote = Remotes.Get("VentSpawn")
	local screen = Make.Screen("ZMFade", 100)
	fade = Make.New("Frame", {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = screen,
	})
	task.spawn(function()
		local ok, module = pcall(function()
			local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 20)
			return require(playerModule :: ModuleScript) :: any
		end)
		if ok and module then
			controls = module:GetControls()
			if session > 0 and fade.BackgroundTransparency < 0.5 then
				setControls(false)
			end
		end
	end)
end

function VentController.Start()
	remote.OnClientEvent:Connect(function(action: string, character: Model?, _start: CFrame?, exitCFrame: CFrame?)
		if action == "Prepare" then
			prepare()
		elseif action == "Launch" and character and exitCFrame then
			launch(character, exitCFrame)
		elseif action == "Done" then
			finish()
		elseif action == "Cancel" then
			cancelForTeleport()
		end
	end)
	player.CharacterAdded:Connect(function()
		restoreCamera()
	end)
	task.spawn(watchVent)
end

return VentController
