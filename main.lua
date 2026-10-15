-- <w> : by wleo : yoruka.id
-- Mark Menu | LocalScript (StarterPlayerScripts)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Settings
local FLING_RANGE = 4.5
local FLY_SPEED = 60

local state = {fling = false, fly = false, noclip = false, aim = false, ijump = false}
local aimPartName = "Kepala"
local aimOrder = {"Kepala", "Badan", "Kaki"}
local upHeld, downHeld = false, false

------------------------------------------------ Helpers
local function getParts()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if hum and root and hum.Health > 0 then
		return char, hum, root
	end
end

local function getAimPart(char)
	if aimPartName == "Kepala" then
		return char:FindFirstChild("Head")
	elseif aimPartName == "Badan" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	else
		return char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg") or char:FindFirstChild("LowerTorso")
	end
end

------------------------------------------------ GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MarkMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 190, 0, 262)
main.Position = UDim2.new(0.5, -95, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.BackgroundTransparency = 1
title.Text = "  Mark Menu"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = main

local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0, 28, 0, 22)
mini.Position = UDim2.new(1, -34, 0, 4)
mini.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
mini.Text = "-"
mini.TextColor3 = Color3.new(1, 1, 1)
mini.Font = Enum.Font.GothamBold
mini.TextSize = 16
mini.Parent = main
Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 6)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -16, 1, -38)
body.Position = UDim2.new(0, 8, 0, 34)
body.BackgroundTransparency = 1
body.Parent = main

local layout = Instance.new("UIListLayout", body)
layout.Padding = UDim.new(0, 6)

mini.MouseButton1Click:Connect(function()
	body.Visible = not body.Visible
	main.Size = body.Visible and UDim2.new(0, 190, 0, 262) or UDim2.new(0, 190, 0, 34)
	mini.Text = body.Visible and "-" or "+"
end)

-- Drag (mouse + touch) lewat judul
do
	local dragging, dragStart, startPos
	title.Active = true
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function makeButton(text)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.Text = text
	b.AutoButtonColor = false
	b.Parent = body
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local function makeToggle(label, key, onChange)
	local b = makeButton(label .. ": OFF")
	b.MouseButton1Click:Connect(function()
		state[key] = not state[key]
		b.Text = label .. (state[key] and ": ON" or ": OFF")
		b.BackgroundColor3 = state[key] and Color3.fromRGB(40, 170, 70) or Color3.fromRGB(170, 40, 40)
		if onChange then onChange(state[key]) end
	end)
	return b
end

------------------------------------------------ Fly
local bv, bg

local function stopFly()
	if bv then bv:Destroy() bv = nil end
	if bg then bg:Destroy() bg = nil end
	local _, hum = getParts()
	if hum then hum.PlatformStand = false end
end

makeToggle("Walk Fling", "fling")
makeToggle("Fly", "fly", function(on) if not on then stopFly() end end)
makeToggle("Noclip", "noclip")
makeToggle("Aim Kamera", "aim")
makeToggle("Infinite Jump", "ijump")

local partBtn = makeButton("Target: " .. aimPartName)
partBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 170)
partBtn.MouseButton1Click:Connect(function()
	local i = table.find(aimOrder, aimPartName) or 1
	aimPartName = aimOrder[(i % #aimOrder) + 1]
	partBtn.Text = "Target: " .. aimPartName
end)

-- Tombol naik/turun fly (untuk HP)
local function holdBtn(text, posY, setter)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 50, 0, 50)
	b.Position = UDim2.new(1, -70, 0.5, posY)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	b.BackgroundTransparency = 0.2
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 20
	b.Visible = false
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			setter(true)
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			setter(false)
		end
	end)
	return b
end

local upBtn = holdBtn("▲", -60, function(v) upHeld = v end)
local downBtn = holdBtn("▼", 0, function(v) downHeld = v end)

------------------------------------------------ Infinite jump
UserInputService.JumpRequest:Connect(function()
	if not state.ijump then return end
	local _, hum = getParts()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

------------------------------------------------ Noclip
RunService.Stepped:Connect(function()
	if not state.noclip then return end
	local char = getParts()
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
end)

------------------------------------------------ Fly loop
RunService.RenderStepped:Connect(function()
	upBtn.Visible = state.fly
	downBtn.Visible = state.fly

	if not state.fly then return end
	local _, hum, root = getParts()
	if not root then return end

	if not bv or bv.Parent ~= root then
		stopFly()
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.Velocity = Vector3.zero
		bv.Parent = root
		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bg.P = 9e4
		bg.Parent = root
		hum.PlatformStand = true
	end

	local dir = hum.MoveDirection
	local move = Vector3.zero
	if dir.Magnitude > 0 then
		-- ikut arah kamera (termasuk naik/turun saat lihat atas/bawah)
		local look = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector
		local f = dir:Dot(Vector3.new(look.X, 0, look.Z).Unit)
		local r = dir:Dot(Vector3.new(right.X, 0, right.Z).Unit)
		move = look * f + right * r
	end
	local vert = 0
	if upHeld or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert += 1 end
	if downHeld or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vert -= 1 end
	move += Vector3.new(0, vert, 0)

	bv.Velocity = move * FLY_SPEED
	bg.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
end)

------------------------------------------------ Aim kamera
local function getTarget()
	local best, bestDist = nil, math.huge
	local center = camera.ViewportSize / 2
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local part = getAimPart(plr.Character)
			if hum and hum.Health > 0 and part then
				local pos, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
					if d < bestDist then
						bestDist, best = d, part
					end
				end
			end
		end
	end
	return best
end

RunService.RenderStepped:Connect(function()
	if not state.aim then return end
	local target = getTarget()
	if target then
		camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
	end
end)

------------------------------------------------ Walk Fling (hanya saat sudah dekat target)
local busy = false

RunService.Heartbeat:Connect(function()
	if not state.fling or busy then return end
	local _, _, root = getParts()
	if not root then return end

	local near = false
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			local tr = plr.Character:FindFirstChild("HumanoidRootPart")
			if tr and (tr.Position - root.Position).Magnitude <= FLING_RANGE then
				near = true
				break
			end
		end
	end
	if not near then return end

	busy = true
	local oldVel = root.AssemblyLinearVelocity
	local oldAng = root.AssemblyAngularVelocity

	root.AssemblyLinearVelocity = Vector3.new(0, 30000, 0)
	root.AssemblyAngularVelocity = Vector3.new(0, 40000, 0)

	RunService.RenderStepped:Wait()
	if root.Parent then
		root.AssemblyLinearVelocity = oldVel
		root.AssemblyAngularVelocity = oldAng
	end
	busy = false
end)
-- <w> : by wleo : yoruka.id
-- Part Ring | tempel di PALING BAWAH script Mark Menu

state.ring = false

local RING_RADIUS = 14
local RING_SPEED = 2.5
local RING_MAX = 80
local ringParts, ringBlocks = {}, {}
local ringAngle, ringScan, lastChar = 0, 0, nil

local function isCharPart(p)
	local m = p:FindFirstAncestorOfClass("Model")
	return m and m:FindFirstChildOfClass("Humanoid") ~= nil
end

local function clearBlocks()
	for _, c in ipairs(ringBlocks) do c:Destroy() end
	table.clear(ringBlocks)
end

local function bindPart(part, char)
	for _, cp in ipairs(char:GetDescendants()) do
		if cp:IsA("BasePart") then
			local n = Instance.new("NoCollisionConstraint")
			n.Part0, n.Part1 = part, cp
			n.Parent = part
			table.insert(ringBlocks, n)
		end
	end
end

local function flingTouched(part)
	part.Touched:Connect(function(hit)
		if not state.ring then return end
		local model = hit:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if plr and plr ~= player then
			local r = model:FindFirstChild("HumanoidRootPart")
			if r then
				r.AssemblyLinearVelocity = Vector3.new(
					math.random(-1, 1) * 9000, 9000, math.random(-1, 1) * 9000)
				r.AssemblyAngularVelocity = Vector3.new(0, 9000, 0)
			end
		end
	end)
end

local touchBound = setmetatable({}, {__mode = "k"})

local function scanParts(char)
	table.clear(ringParts)
	for _, p in ipairs(Workspace:GetDescendants()) do
		if #ringParts >= RING_MAX then break end
		if p:IsA("BasePart") and not p.Anchored and not isCharPart(p)
			and p.Size.Magnitude < 30 then
			table.insert(ringParts, p)
			bindPart(p, char)
			if not touchBound[p] then
				touchBound[p] = true
				flingTouched(p)
			end
		end
	end
end

makeToggle("Part Ring", "ring", function(on)
	if not on then
		clearBlocks()
		table.clear(ringParts)
		lastChar = nil
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if not state.ring then return end
	local char, _, root = getParts()
	if not root then return end

	-- scan ulang tiap 3 detik atau saat respawn
	ringScan += dt
	if char ~= lastChar or ringScan > 3 then
		lastChar, ringScan = char, 0
		clearBlocks()
		scanParts(char)
	end

	ringAngle += dt * RING_SPEED
	local n = #ringParts
	for i, p in ipairs(ringParts) do
		if p.Parent then
			local a = ringAngle + (i / n) * math.pi * 2
			local layer = (i % 3) * 4 - 2
			local target = root.Position + Vector3.new(
				math.cos(a) * RING_RADIUS, layer + 3, math.sin(a) * RING_RADIUS)
			local v = (target - p.Position) * 12
			if v.Magnitude > 250 then v = v.Unit * 250 end
			p.AssemblyLinearVelocity = v
			p.AssemblyAngularVelocity = Vector3.new(0, 40, 0)
		end
	end
end)
-- <w> : by wleo : yoruka.id
-- Tambahan Mark Menu | tempel di PALING BAWAH script (di bawah Part Ring)

state.speed, state.lowgrav, state.esp = false, false, false
state.antifling, state.clicktp, state.clickfling = false, false, false

local speedVals = {50, 100, 200}
local speedVal = 100
local origGravity = Workspace.Gravity
local LOW_GRAVITY = 60

-- Menu jadi bisa di-scroll biar muat banyak tombol
do
	local old = body
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = old.Size
	scroll.Position = old.Position
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = main
	for _, c in ipairs(old:GetChildren()) do c.Parent = scroll end
	old:Destroy()
	body = scroll
end

------------------------------------------------ Super Speed & Low Gravity
makeToggle("Super Speed", "speed", function(on)
	if not on then
		local _, hum = getParts()
		if hum then hum.WalkSpeed = 16 end
	end
end)

local speedBtn = makeButton("Kecepatan: " .. speedVal)
speedBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 170)
speedBtn.MouseButton1Click:Connect(function()
	local i = table.find(speedVals, speedVal) or 1
	speedVal = speedVals[(i % #speedVals) + 1]
	speedBtn.Text = "Kecepatan: " .. speedVal
end)

makeToggle("Low Gravity", "lowgrav", function(on)
	Workspace.Gravity = on and LOW_GRAVITY or origGravity
end)

RunService.Heartbeat:Connect(function()
	if state.speed then
		local _, hum = getParts()
		if hum then hum.WalkSpeed = speedVal end
	end
end)

------------------------------------------------ ESP (tembus tembok)
local espObjs = {}

local function clearESP()
	for _, o in pairs(espObjs) do
		o.hl:Destroy()
		o.bb:Destroy()
	end
	table.clear(espObjs)
end

makeToggle("ESP", "esp", function(on)
	if not on then clearESP() end
end)

local espTimer = 0
RunService.Heartbeat:Connect(function(dt)
	if not state.esp then return end
	espTimer += dt
	if espTimer < 0.15 then return end
	espTimer = 0

	local _, _, myRoot = getParts()

	for plr, o in pairs(espObjs) do
		if not plr.Parent then
			o.hl:Destroy()
			o.bb:Destroy()
			espObjs[plr] = nil
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if plr ~= player and char then
			local head = char:FindFirstChild("Head")
			local o = espObjs[plr]
			if not o then
				local hl = Instance.new("Highlight")
				hl.FillColor = Color3.fromRGB(255, 60, 60)
				hl.FillTransparency = 0.6
				hl.OutlineColor = Color3.new(1, 1, 1)
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = gui

				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 120, 0, 20)
				bb.StudsOffset = Vector3.new(0, 2.5, 0)
				bb.AlwaysOnTop = true
				bb.Parent = gui
				local tl = Instance.new("TextLabel")
				tl.Size = UDim2.new(1, 0, 1, 0)
				tl.BackgroundTransparency = 1
				tl.TextColor3 = Color3.new(1, 1, 1)
				tl.TextStrokeTransparency = 0
				tl.Font = Enum.Font.GothamBold
				tl.TextSize = 13
				tl.Parent = bb

				o = {hl = hl, bb = bb, tl = tl}
				espObjs[plr] = o
			end
			o.hl.Adornee = char
			if head then
				o.bb.Adornee = head
				local dist = myRoot and math.floor((head.Position - myRoot.Position).Magnitude) or 0
				o.tl.Text = plr.DisplayName .. " [" .. dist .. "m]"
			end
		end
	end
end)

------------------------------------------------ Anti Fling
makeToggle("Anti Fling", "antifling")

RunService.Stepped:Connect(function()
	if not state.antifling then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character then
			for _, p in ipairs(plr.Character:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not state.antifling or busy then return end
	local _, _, root = getParts()
	if not root then return end
	if root.AssemblyLinearVelocity.Magnitude > 300 or root.AssemblyAngularVelocity.Magnitude > 100 then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end)

------------------------------------------------ Click TP & Click Fling
makeToggle("Click TP", "clicktp")
makeToggle("Click Fling", "clickfling")

local function clickFling(targetChar)
	if busy then return end
	local _, _, root = getParts()
	local tr = targetChar:FindFirstChild("HumanoidRootPart")
	if not root or not tr then return end
	busy = true
	local origCF = root.CFrame
	local t0 = tick()
	while tick() - t0 < 0.6 and tr.Parent and root.Parent do
		root.CFrame = tr.CFrame
		root.AssemblyLinearVelocity = Vector3.new(0, 20000, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 40000, 0)
		RunService.Heartbeat:Wait()
	end
	if root.Parent then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = origCF
	end
	busy = false
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if not (state.clicktp or state.clickfling) then return end

	local char, _, root = getParts()
	if not char then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}

	local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if not result then return end

	if state.clickfling then
		-- Lanjutan: ganti baris yang terpotong (FindFirstAncest...) dengan kode ini sampai akhir

		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		if plr and plr ~= player then
			task.spawn(clickFling, model)
			return
		end
	end

	if state.clicktp and not busy then
		root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
	end
end)
