local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/QP-Offcial/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func)
	func()
end
local btext = function(text)
	return text..' '
end

local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local vapeConnections
if shared.vapeConnections and type(shared.vapeConnections) == "table" then vapeConnections = shared.vapeConnections else vapeConnections = {}; shared.vapeConnections = vapeConnections; end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local collectionService = cloneref(game:GetService("CollectionService"))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local GuiLibrary = shared.GuiLibrary
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local activeTweens = {}
local activeAnimationTrack = nil
local activeModel = nil
local emoteActive = false
 
local XStore = {
	bedtable = {},
	Tweening = false
}

local function getrandomvalue(tab)
	return #tab > 0 and tab[math.random(1, #tab)] or ''
end

local function GetEnumItems(enum)
	local fonts = {}
	for i,v in next, Enum[enum]:GetEnumItems() do 
		table.insert(fonts, v.Name) 
	end
	return fonts
end

local isAlive = function(plr, healthblacklist)
	plr = plr or lplr
	local alive = false 
	if plr.Character and plr.Character.PrimaryPart and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character:FindFirstChild("Head") then 
		alive = true
	end
	if not healthblacklist and alive and plr.Character.Humanoid.Health and plr.Character.Humanoid.Health <= 0 then 
		alive = false
	end
	return alive
end
local function GetMagnitudeOf2Objects(part, part2, bypass)
	local magnitude, partcount = 0, 0
	if not bypass then 
		local suc, res = pcall(function() return part.Position end)
		partcount = suc and partcount + 1 or partcount
		suc, res = pcall(function() return part2.Position end)
		partcount = suc and partcount + 1 or partcount
	end
	if partcount > 1 or bypass then 
		magnitude = bypass and (part - part2).magnitude or (part.Position - part2.Position).magnitude
	end
	return magnitude
end
local function createSequence(args)
    local seq =
        ColorSequence.new(
        {
            ColorSequenceKeypoint.new(0, args.c1),
            ColorSequenceKeypoint.new(1, args.c2)
        }
    )
    return seq
end
local function GetTopBlock(position, smart, raycast, customvector)
	position = position or isAlive(lplr, true) and lplr.Character:WaitForChild("HumanoidRootPart").Position
	if not position then 
		return nil 
	end
	if raycast and not game.Workspace:Raycast(position, Vector3.new(0, -2000, 0), store.blockRaycast) then
	    return nil
    end
	local lastblock = nil
	for i = 1, 500 do 
		local newray = game.Workspace:Raycast(lastblock and lastblock.Position or position, customvector or Vector3.new(0.55, 999999, 0.55), store.blockRaycast)
		local smartest = newray and smart and game.Workspace:Raycast(lastblock and lastblock.Position or position, Vector3.new(0, 5.5, 0), store.blockRaycast) or not smart
		if newray and smartest then
			lastblock = newray
		else
			break
		end
	end
	return lastblock
end
local function FindEnemyBed(maxdistance, highest)
	local target = nil
	local distance = maxdistance or math.huge
	local whitelistuserteams = {}
	local badbeds = {}
	if not lplr:GetAttribute("Team") then return nil end
	for i,v in pairs(playersService:GetPlayers()) do
		if v ~= lplr then
			local type, attackable = vape.Libraries.whitelist:get(v)
			if not attackable then
				whitelistuserteams[v:GetAttribute("Team")] = true
			end
		end
	end
	for i,v in pairs(collectionService:GetTagged("bed")) do
			local bedteamstring = string.split(v:GetAttribute("id"), "_")[1]
			if whitelistuserteams[bedteamstring] ~= nil then
			   badbeds[v] = true
		    end
	    end
	for i,v in pairs(collectionService:GetTagged("bed")) do
		if v:GetAttribute("id") and v:GetAttribute("id") ~= lplr:GetAttribute("Team").."_bed" and badbeds[v] == nil and lplr.Character and lplr.Character.PrimaryPart then
			if v:GetAttribute("NoBreak") or v:GetAttribute("PlacedByUserId") and v:GetAttribute("PlacedByUserId") ~= 0 then continue end
			local magdist = GetMagnitudeOf2Objects(lplr.Character.PrimaryPart, v)
			if magdist < distance then
				target = v
				distance = magdist
			end
		end
	end
	local coveredblock = highest and target and GetTopBlock(target.Position, true)
	if coveredblock then
		target = coveredblock.Instance
	end
	for i,v in pairs(game:GetService("Teams"):GetTeams()) do
		if target and v.TeamColor == target.Bed.BrickColor then
			XStore.bedtable[target] = v.Name
		end
	end
	return target
end
local function FindTeamBed()
	local bedstate, res = pcall(function()
		return lplr.leaderstats.Bed.Value
	end)
	return bedstate and res and res ~= nil and res == "✅"
end
local function FindItemDrop(item)
	local itemdist = nil
	local dist = math.huge
	local function abletocalculate() return lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") end
    for i,v in pairs(collectionService:GetTagged("ItemDrop")) do
		if v and v.Name == item and abletocalculate() then
			local itemdistance = GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v)
			if itemdistance < dist then
			itemdist = v
			dist = itemdistance
		end
		end
	end
	return itemdist
end
local function FindTarget(dist, blockRaycast, includemobs, healthmethod)
	local whitelist = vape.Libraries.whitelist
	local sort, entity = healthmethod and math.huge or dist or math.huge, {}
	local function abletocalculate() return lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") end
	local sortmethods = {Normal = function(entityroot, entityhealth) return abletocalculate() and GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), entityroot) < sort end, Health = function(entityroot, entityhealth) return abletocalculate() and entityhealth < sort end}
	local sortmethod = healthmethod and "Health" or "Normal"
	local function raycasted(entityroot) return abletocalculate() and blockRaycast and game.Workspace:Raycast(entityroot.Position, Vector3.new(0, -2000, 0), store.blockRaycast) or not blockRaycast and true or false end
	for i,v in pairs(playersService:GetPlayers()) do
		if v ~= lplr and abletocalculate() and isAlive(v) and v.Team ~= lplr.Team then
			if not ({whitelist:get(v)})[2] then 
				continue
			end
			if sortmethods[sortmethod](v.Character.HumanoidRootPart, v.Character:GetAttribute("Health") or v.Character.Humanoid.Health) and raycasted(v.Character.HumanoidRootPart) then
				sort = healthmethod and v.Character.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.Character.HumanoidRootPart)
				entity.Player = v
				entity.Human = true 
				entity.RootPart = v.Character.HumanoidRootPart
				entity.Humanoid = v.Character.Humanoid
			end
		end
	end
	if includemobs then
		local maxdistance = dist or math.huge
		for i,v in pairs(store.pots) do
			if abletocalculate() and v.PrimaryPart and GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart) < maxdistance then
			entity.Player = {Character = v, Name = "PotEntity", DisplayName = "PotEntity", UserId = 1}
			entity.Human = false
			entity.RootPart = v.PrimaryPart
			entity.Humanoid = {Health = 1, MaxHealth = 1}
			end
		end
		for i,v in pairs(collectionService:GetTagged("DiamondGuardian")) do 
			if v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health and abletocalculate() then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "DiamondGuardian", DisplayName = "DiamondGuardian", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("GolemBoss")) do
			if v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health and abletocalculate() then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "Titan", DisplayName = "Titan", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("Drone")) do
			local plr = playersService:GetPlayerByUserId(v:GetAttribute("PlayerUserId"))
			if plr and plr ~= lplr and plr.Team and lplr.Team and plr.Team ~= lplr.Team and ({VoidwareFunctions:GetPlayerType(plr)})[2] and abletocalculate() and v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
					sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
					entity.Player = {Character = v, Name = "Drone", DisplayName = "Drone", UserId = 1}
					entity.Human = false
					entity.RootPart = v.PrimaryPart
					entity.Humanoid = v.Humanoid
				end
			end
		end
		for i,v in pairs(collectionService:GetTagged("Monster")) do
			if v:GetAttribute("Team") ~= lplr:GetAttribute("Team") and abletocalculate() and v.PrimaryPart and v:FindFirstChild("Humanoid") and v.Humanoid.Health then
				if sortmethods[sortmethod](v.PrimaryPart, v.Humanoid.Health) and raycasted(v.PrimaryPart) then
				sort = healthmethod and v.Humanoid.Health or GetMagnitudeOf2Objects(lplr.Character:WaitForChild("HumanoidRootPart"), v.PrimaryPart)
				entity.Player = {Character = v, Name = "Monster", DisplayName = "Monster", UserId = 1}
				entity.Human = false
				entity.RootPart = v.PrimaryPart
				entity.Humanoid = v.Humanoid
			end
		end
	end
    end
    return entity
end

local vapeAssert = function(argument, title, text, duration, hault, moduledisable, module) 
	if not argument then
    local suc, res = pcall(function()
    local notification = GuiLibrary:CreateNotification(title or "Voidware", text or "Failed to call function.", duration or 20, "assets/WarningNotification.png")
    notification.IconLabel.ImageColor3 = Color3.new(220, 0, 0)
    notification.Frame.Frame.ImageColor3 = Color3.new(220, 0, 0)
    if moduledisable and (module and vape.Modules[module].Enabled) then vape.Modules[module]:Toggle(false) end
    end)
    if hault then while true do task.wait() end end end
end

local function spinParts(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "Middle" or part.Name == "Outer") then
            local tweenInfo, goal
            if part.Name == "Middle" then
                tweenInfo = TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
                goal = { Orientation = part.Orientation + Vector3.new(0, -360, 0) }
            elseif part.Name == "Outer" then
                tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0)
                goal = { Orientation = part.Orientation + Vector3.new(0, 360, 0) }
            end
 
            local tween = tweenService:Create(part, tweenInfo, goal)
            tween:Play()
            table.insert(activeTweens, tween)
        end
    end
end
 
local function placeModelUnderLeg()
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
 
    if humanoidRootPart then
        local assetsFolder = replicatedStorage:FindFirstChild("Assets")
        if assetsFolder then
            local effectsFolder = assetsFolder:FindFirstChild("Effects")
            if effectsFolder then
                local modelTemplate = effectsFolder:FindFirstChild("NightmareEmote")
                if modelTemplate and modelTemplate:IsA("Model") then
                    local clonedModel = modelTemplate:Clone()
                    clonedModel.Parent = workspace
 
                    if clonedModel.PrimaryPart then
                        clonedModel:SetPrimaryPartCFrame(humanoidRootPart.CFrame - Vector3.new(0, 3, 0))
                    else
                        warn("PrimaryPart not set for NightmareEmote model!")
                        return
                    end
 
                    spinParts(clonedModel)
                    activeModel = clonedModel
                else
                    warn("NightmareEmote model not found or is not a valid model!")
                end
            else
                warn("Effects folder not found in Assets!")
            end
        else
            warn("Assets folder not found in ReplicatedStorage!")
        end
    else
        warn("HumanoidRootPart not found in character!")
    end
end
 
local function playAnimation(animationId)
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
 
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        activeAnimationTrack = animator:LoadAnimation(animation)
        activeAnimationTrack:Play()
    else
        warn("Humanoid not found in character!")
    end
end
 
local function stopEffects()
    for _, tween in ipairs(activeTweens) do
        tween:Cancel()
    end
    activeTweens = {}
 
    if activeAnimationTrack then
        activeAnimationTrack:Stop()
        activeAnimationTrack = nil
    end
 
    if activeModel then
        activeModel:Destroy()
        activeModel = nil
    end
 
    emoteActive = false
end
 
local function monitorWalking()
    local player = playersService.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
 
    if humanoid then
        humanoid.Running:Connect(function(speed)
            if speed > 0 and emoteActive then
                stopEffects()
            end
        end)
    else
        warn("Humanoid not found in character!")
    end
end
 
local function activateNightmareEmote()
    if emoteActive then
        return
    end
 
    emoteActive = true
    local success, err = pcall(function()
        monitorWalking()
        placeModelUnderLeg()
        playAnimation("rbxassetid://9191822700")
    end)
 
    if not success then
        warn("Error occurred: " .. tostring(err))
        emoteActive = false
    end
end

local function GetTarget()
	return entitylib.EntityPosition({
		Part = 'RootPart',
		Range = 1000,
		Players = true,
		NPCs = false,
		Wallcheck = false
	})
end

local GodMode = {Enabled = false}
run(function()
    local antiDeath = {}
    local antiDeathConfig = {
        Mode = {},
        BoostMode = {},
        SongId = {},
        Health = {},
        Velocity = {},
        CFrame = {},
        TweenPower = {},
        TweenDuration = {},
        SkyPosition = {},
        AutoDisable = {},
        Sound = {},
        Notify = {}
    }
    local antiDeathState = {}
    local handlers = {}

    function handlers.new()
        local self = {
			godmode = false,
            boost = false,
            inf = false,
            notify = false,
            id = false,
            hrp = entitylib.character.HumanoidRootPart,
            hasNotified = false
        }
        setmetatable(self, { __index = handlers })
        return self
    end

    function handlers:enable()
		antiDeath:Clean(runService.Heartbeat:Connect(function()
			if not isAlive(lplr, true) then
                handlers:disable()
                return
            end

            if getHealth() <= antiDeathConfig.Health.Value and getHealth() > 0 then
                if not handlers.boost then
                    handlers:activateMode()
                    if not shandlers.hasNotified and antiDeathConfig.Notify.Enabled then
                        handlers:sendNotification()
                    end
                    handlers:playNotificationSound()
                    handlers.boost = true
                end
            else
                handlers:resetMode()
				pcall(function()
					handlers.hrp = entitylib.character.HumanoidRootPart
					handlers.hrp.Anchored = false
				end)
                handlers.boost = false

                if handlers.hasNotified then
                    handlers.hasNotified = false
                end
            end
		end))
    end

    function handlers:disable()
        --RunLoops:UnbindFromHeartbeat('antiDeath')
    end

    function handlers:activateMode()
        local modeActions = {
            Infinite = function() self:enableInfiniteMode() end,
            Boost = function() self:applyBoost() end,
            Sky = function() self:moveToSky() end,
			AntiHit = function() self:enableAntiHitMode() end
        }
        modeActions[antiDeathConfig.Mode.Value]()
    end

	function handlers:enableAntiHitMode()
		if not GodMode.Enabled then
			GodMode:Toggle(false)
			self.godmode = true
		end
	end

    function handlers:enableInfiniteMode()
        if not vape.Modules.InfiniteFly.Enabled then
            vape.Modules.InfiniteFly:Toggle(true)
            self.inf = true
        end
    end

    function handlers:applyBoost()
        local boostActions = {
            Velocity = function() self.hrp.Velocity += Vector3.new(0, antiDeathConfig.Velocity.Value, 0) end,
            CFrame = function() self.hrp.CFrame += Vector3.new(0, antiDeathConfig.CFrame.Value, 0) end,
            Tween = function()
                tweenService:Create(self.hrp, twinfo(antiDeathConfig.TweenDuration.Value / 10), {
                    CFrame = self.hrp.CFrame + Vector3.new(0, antiDeathConfig.TweenPower.Value, 0)
                }):Play()
            end
        }
        boostActions[antiDeathConfig.BoostMode.Value]()
    end

    function handlers:moveToSky()
        self.hrp.CFrame += Vector3.new(0, antiDeathConfig.SkyPosition.Value, 0)
        self.hrp.Anchored = true
    end

    function handlers:sendNotification()
        InfoNotification('AntiDeath', 'Prevented death. Health is lower than ' .. antiDeathConfig.Health.Value ..
            '. (Current health: ' .. math.floor(getHealth() + 0.5) .. ')', 5)
        self.hasNotified = true
    end

    function handlers:playNotificationSound()
        if antiDeathConfig.Sound.Enabled then
            local soundId = antiDeathConfig.SongId.Value ~= '' and antiDeathConfig.SongId.Value or '7396762708'
            playSound(soundId, false)
        end
    end

    function handlers:resetMode()
        if self.inf then
            if antiDeathConfig.AutoDisable.Enabled then
                if vape.Modules.InfiniteFly.Enabled then
                    vape.Modules.InfiniteFly:Toggle(false)
                end
            end
            self.inf = false
            self.hasNotified = false
        elseif self.godmode then
			if antiDeathConfig.AutoDisable.Enabled then
                if GodMode.Enabled then
                    GodMode:Toggle(false)
                end
            end
            self.godmode = false
            self.hasNotified = false
		end
    end

    local antiDeathStatus = handlers.new()

    antiDeath = vape.Categories.Modules:CreateModule({
        Name = 'AntiDeath',
        Function = function(callback)
            if callback then
                coroutine.wrap(function()
                    antiDeathStatus:enable()
                end)()
            else
                pcall(function()
                    antiDeathStatus:disable()
                end)
            end
        end,
        Default = false,
        Tooltip = btext('Prevents you from dying.'),
        ExtraText = function()
            return antiDeathConfig.Mode.Value
        end
    })

    antiDeathConfig.Mode = antiDeath:CreateDropdown({
        Name = 'Mode',
        List = {'Infinite', 'Boost', 'Sky', 'AntiHit'},
        Default = 'AntiHit',
        Tooltip = btext('Mode to prevent death.'),
        Function = function(val)
            antiDeathConfig.BoostMode.Object.Visible = val == 'Boost'
            antiDeathConfig.SkyPosition.Object.Visible = val == 'Sky'
            antiDeathConfig.AutoDisable.Object.Visible = (val == 'Infinite' or val == 'AntiHit')
            antiDeathConfig.Velocity.Object.Visible = false
            antiDeathConfig.CFrame.Object.Visible = false
            antiDeathConfig.TweenPower.Object.Visible = false
            antiDeathConfig.TweenDuration.Object.Visible = false
        end
    })

    antiDeathConfig.BoostMode = antiDeath:CreateDropdown({
        Name = 'Boost',
        List = { 'Velocity', 'CFrame', 'Tween' },
        Default = 'Velocity',
        Tooltip = btext('Mode to boost your character.'),
        Function = function(val)
            antiDeathConfig.Velocity.Object.Visible = val == 'Velocity'
            antiDeathConfig.CFrame.Object.Visible = val == 'CFrame'
            antiDeathConfig.TweenPower.Object.Visible = val == 'Tween'
            antiDeathConfig.TweenDuration.Object.Visible = val == 'Tween'
        end
    })
    antiDeathConfig.BoostMode.Object.Visible = false

    antiDeathConfig.SongId = antiDeath:CreateTextBox({
        Name = 'SongID',
        TempText = 'Song ID',
        Tooltip = 'ID to play the song.',
        FocusLost = function()
            if antiDeath.Enabled then
                antiDeath:Toggle()
                antiDeath:Toggle()
            end
        end
    })
    antiDeathConfig.SongId.Object.Visible = false

    antiDeathConfig.Health = antiDeath:CreateSlider({
        Name = 'Health Trigger',
        Min = 10,
        Max = 90,
        Tooltip = btext('Health at which AntiDeath will perform its actions.'),
        Default = 50,
        Function = function(val) end
    })

    antiDeathConfig.Velocity = antiDeath:CreateSlider({
        Name = 'Velocity Boost',
        Min = 100,
        Max = 600,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 600,
        Function = function(val) end
    })
    antiDeathConfig.Velocity.Object.Visible = false

    antiDeathConfig.CFrame = antiDeath:CreateSlider({
        Name = 'CFrame Boost',
        Min = 100,
        Max = 1000,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.CFrame.Object.Visible = false

    antiDeathConfig.TweenPower = antiDeath:CreateSlider({
        Name = 'Tween Boost',
        Min = 100,
        Max = 1300,
        Tooltip = btext('Power to get boosted in the air.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.TweenPower.Object.Visible = false

    antiDeathConfig.TweenDuration = antiDeath:CreateSlider({
        Name = 'Tween Duration',
        Min = 1,
        Max = 10,
        Tooltip = btext('Duration of the tweening process.'),
        Default = 4,
        Function = function(val) end
    })
    antiDeathConfig.TweenDuration.Object.Visible = false

    antiDeathConfig.SkyPosition = antiDeath:CreateSlider({
        Name = 'Sky Position',
        Min = 100,
        Max = 1000,
        Tooltip = btext('Position to TP in the sky.'),
        Default = 1000,
        Function = function(val) end
    })
    antiDeathConfig.SkyPosition.Object.Visible = false

    antiDeathConfig.AutoDisable = antiDeath:CreateToggle({
        Name = 'Auto Disable',
        Tooltip = btext('Automatically disables InfiniteFly after healing.'),
        Function = function(val) end,
        Default = true
    })
    antiDeathConfig.AutoDisable.Object.Visible = false

    antiDeathConfig.Sound = antiDeath:CreateToggle({
        Name = 'Sound',
        Tooltip = btext('Plays a sound after preventing death.'),
        Function = function(callback)
            antiDeathConfig.SongId.Object.Visible = callback
        end,
        Default = true
    })

    antiDeathConfig.Notify = antiDeath:CreateToggle({
        Name = 'Notification',
        Tooltip = btext('Notifies you when AntiDeath actioned.'),
        Default = true,
        Function = function(callback) end
    })
end)

run(function()
	function IsAlive(plr)
		plr = plr or lplr
		if not plr.Character then return false end
		if not plr.Character:FindFirstChild("Head") then return false end
		if not plr.Character:FindFirstChild("Humanoid") then return false end
		if plr.Character:FindFirstChild("Humanoid").Health < 0.11 then return false end
		return true
	end
	local Slowmode = {Value = 2}
	GodMode = vape.Categories.Modules:CreateModule({
		Name = "AntiHit",
		Function = function(callback)
			if callback then
				task.spawn(function()
					repeat task.wait()
						local res, msg = pcall(function()
							if (not vape.Modules.Fly.Enabled) and (not vape.Modules.InfiniteFly.Enabled) then
								for i, v in pairs(game:GetService("Players"):GetChildren()) do
									if v.Team ~= lplr.Team and IsAlive(v) and IsAlive(lplr) then
										if v and v ~= lplr then
											local TargetDistance = lplr:DistanceFromCharacter(v.Character:FindFirstChild("HumanoidRootPart").CFrame.p)
											if TargetDistance < 25 then
												if not lplr.Character:WaitForChild("HumanoidRootPart"):FindFirstChildOfClass("BodyVelocity") then
													repeat task.wait() until store.matchState ~= 0
													if not (v.Character.HumanoidRootPart.Velocity.Y < -10*5) then
														lplr.Character.Archivable = true
				
														local Clone = lplr.Character:Clone()
														Clone.Parent = game.Workspace
														Clone.Head:ClearAllChildren()
														gameCamera.CameraSubject = Clone:FindFirstChild("Humanoid")
					
														for i,v in pairs(Clone:GetChildren()) do
															if string.lower(v.ClassName):find("part") and v.Name ~= "HumanoidRootPart" then
																v.Transparency = 1
															end
															if v:IsA("Accessory") then
																v:FindFirstChild("Handle").Transparency = 1
															end
														end
					
														lplr.Character:WaitForChild("HumanoidRootPart").CFrame = lplr.Character:WaitForChild("HumanoidRootPart").CFrame + Vector3.new(0,100,0)
					
														GodMode:Clean(game:GetService("RunService").RenderStepped:Connect(function()
															if Clone ~= nil and Clone:FindFirstChild("HumanoidRootPart") then
																Clone.HumanoidRootPart.Position = Vector3.new(lplr.Character:WaitForChild("HumanoidRootPart").Position.X, Clone.HumanoidRootPart.Position.Y, lplr.Character:WaitForChild("HumanoidRootPart").Position.Z)
															end
														end))
					
														task.wait(Slowmode.Value/10)
														lplr.Character:WaitForChild("HumanoidRootPart").Velocity = Vector3.new(lplr.Character:WaitForChild("HumanoidRootPart").Velocity.X, -1, lplr.Character:WaitForChild("HumanoidRootPart").Velocity.Z)
														lplr.Character:WaitForChild("HumanoidRootPart").CFrame = Clone.HumanoidRootPart.CFrame
														gameCamera.CameraSubject = lplr.Character:FindFirstChild("Humanoid")
														Clone:Destroy()
														task.wait(0.15)
													end
												end
											end
										end
									end
								end
							end
						end)
						if not res then warn(msg) end
					until (not GodMode.Enabled)
				end)
			end
		end
	})
	Slowmode = GodMode:CreateSlider({
		Name = "Slowmode",
		Function = function() end,
		Default = 2,
		Min = 1,
		Max = 25
	})
end)

run(function()
    local InfiniteJump
    local Velocity
    InfiniteJump = vape.Categories.Modules:CreateModule({
        Name = "InfiniteJump",
        Function = function(callback)
            if callback then
                local UserInputService = game:GetService("UserInputService")
                local player = playersService.LocalPlayer
                local function setupInfiniteJump()
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    InfiniteJump:Clean(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
                            while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
                                humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, Velocity.Value, humanoidRootPart.Velocity.Z)
                                wait()
                            end
                        end
                    end))
					if UserInputService.TouchEnabled then
						local Jumping = false
						local JumpButton: ImageButton = lplr.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
						
						InfiniteJump:Clean(JumpButton.MouseButton1Down:Connect(function()
							Jumping = true
						end))

						InfiniteJump:Clean(JumpButton.MouseButton1Up:Connect(function()
							Jumping = false
						end))

						InfiniteJump:Clean(runService.RenderStepped:Connect(function()
							if Jumping then
								humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, Velocity.Value, humanoidRootPart.Velocity.Z)
							end
						end))
					end
                end
                player.CharacterAdded:Connect(setupInfiniteJump)
                if player.Character then
                    setupInfiniteJump()
                end
            end
        end,
        Tooltip = "Allows infinite jumping"
    })
    Velocity = InfiniteJump:CreateSlider({
        Name = 'Velocity',
        Min = 50,
        Max = 300,
        Default = 50
    })
end)

run(function()
	local InfernalKill = {Enabled = false}
	InfernalKill = vape.Categories.Modules:CreateModule({
		["Name"] = "EmberExploit",
		["Function"] = function(callback)
			if callback then
				repeat
				wait(0.001)
				function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v;end end end
				local args = {
					[1] = {
						["chargeTime"] = 0.9,
						["player"] = game:GetService("Players").LocalPlayer,
						["weapon"] = getNil("infernal_saber", "Accessory")
					}
				}
	
				game:GetService("ReplicatedStorage"):WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):WaitForChild("HellBladeRelease"):FireServer(unpack(args))
			until not InfernalKill["Enabled"]
		end
			end,
			["Description"] = "Amber Exploit"
		})
	end)

run(function()
    local NightmareEventButton
    NightmareEventButton = vape.Categories.Modules:CreateModule({
        Name = "Nightmare Emote",
        Description = "Play Nightmare Emote",
        Function = function(callback)
            if callback then
                NightmareEventButton:Toggle(false)
                activateNightmareEmote()
            end
        end
    })
end)

run(function()
    local AdetundeExploit
    local AdetundeExploit_List

    local adetunde_remotes = {
        ["Shield"] = function()
            local args = { [1] = "shield" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Speed"] = function()
            local args = { [1] = "speed" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end,

        ["Strength"] = function()
            local args = { [1] = "strength" }
            local returning = game:GetService("ReplicatedStorage")
                :WaitForChild("rbxts_include")
                :WaitForChild("node_modules")
                :WaitForChild("@rbxts")
                :WaitForChild("net")
                :WaitForChild("out")
                :WaitForChild("_NetManaged")
                :WaitForChild("UpgradeFrostyHammer")
                :InvokeServer(unpack(args))
            return returning
        end
    }

    local current_upgrador = "Shield"
    local hasnt_upgraded_everything = true
    local testing = 1

    AdetundeExploit = vape.Categories.Modules:CreateModule({
        Name = 'AdetundeExploit',
        Function = function(calling)
            if calling then 
                -- Check if in testing mode or equipped kit
                -- if tostring(shared.store.queueType) == "training_room" or shared.store.equippedKit == "adetunde" then
                --     AdetundeExploit["ToggleButton"](false) 
                --     current_upgrador = AdetundeExploit_List.Value
                task.spawn(function()
                    repeat
                        local returning_table = adetunde_remotes[current_upgrador]()
                        
                        if type(returning_table) == "table" then
                            local Speed = returning_table["speed"]
                            local Strength = returning_table["strength"]
                            local Shield = returning_table["shield"]

                            print("Speed: " .. tostring(Speed))
                            print("Strength: " .. tostring(Strength))
                            print("Shield: " .. tostring(Shield))
                            print("Current Upgrador: " .. tostring(current_upgrador))

                            if returning_table[string.lower(current_upgrador)] == 3 then
                                if Strength and Shield and Speed then
                                    if Strength == 3 or Speed == 3 or Shield == 3 then
                                        if (Strength == 3 and Speed == 2 and Shield == 2) or
                                           (Strength == 2 and Speed == 3 and Shield == 2) or
                                           (Strength == 2 and Speed == 2 and Shield == 3) then
                                            -- warningNotification("AdetundeExploit", "Fully upgraded everything possible!", 7)
                                            hasnt_upgraded_everything = false
                                        else
                                            local things = {}
                                            for i, v in pairs(adetunde_remotes) do
                                                table.insert(things, i)
                                            end
                                            for i, v in pairs(things) do
                                                if things[i] == current_upgrador then
                                                    table.remove(things, i)
                                                end
                                            end
                                            local random = things[math.random(1, #things)]
                                            current_upgrador = random
                                        end
                                    end
                                end
                            end
                        else
                            local things = {}
                            for i, v in pairs(adetunde_remotes) do
                                table.insert(things, i)
                            end
                            for i, v in pairs(things) do
                                if things[i] == current_upgrador then
                                    table.remove(things, i)
                                end
                            end
                            local random = things[math.random(1, #things)]
                            current_upgrador = random
                        end
                        task.wait(0.1)
                    until not AdetundeExploit.Enabled or not hasnt_upgraded_everything
                end)
                -- else
                --     AdetundeExploit["ToggleButton"](false)
                --     warningNotification("AdetundeExploit", "Kit required or you need to be in testing mode", 5)
                -- end
            end
        end
    })

    local real_list = {}
    for i, v in pairs(adetunde_remotes) do
        table.insert(real_list, i)
    end

    AdetundeExploit_List = AdetundeExploit:CreateDropdown({
        Name = 'Preferred Upgrade',
        List = real_list,
        Function = function() end,
        Default = "Shield"
    })
end)

run(function()
	local NoNameTag
	NoNameTag = vape.Categories.Modules:CreateModule({
		PerformanceModeBlacklisted = true,
		Name = 'NoNameTag',
        Tooltip = 'Removes your NameTag.',
		Function = function(callback)
			if callback then
				NoNameTag:Clean(runService.RenderStepped:Connect(function()
					pcall(function()
						lplr.Character.Head.Nametag:Destroy()
					end)
				end))
			end
		end,
        Default = false
	})
end)

run(function()
	local DamageIndicator = {}
	local DamageIndicatorColorToggle = {}
	local DamageIndicatorColor = {Hue = 0, Sat = 0, Value = 0}
	local DamageIndicatorTextToggle = {}
	local DamageIndicatorText = {ObjectList = {}}
	local DamageIndicatorFontToggle = {}
	local DamageIndicatorFont = {Value = 'GothamBlack'}
	local DamageIndicatorTextObjects = {}
    local DamageIndicatorMode1
    local DamageMessages = {
		'Pow!',
		'Pop!',
		'Hit!',
		'Smack!',
		'Bang!',
		'Boom!',
		'Whoop!',
		'Damage!',
		'-9e9!',
		'Whack!',
		'Crash!',
		'Slam!',
		'Zap!',
		'Snap!',
		'Thump!'
	}
	local RGBColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 127, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(148, 0, 211)
	}
	local orgI, mz, vz = 1, 5, 10
    local DamageIndicatorMode = {Value = 'Rainbow'}
	local DamageIndicatorMode2 = {Value = 'Gradient'}
	DamageIndicator = vape.Categories.Modules:CreateModule({
        PerformanceModeBlacklisted = true,
		Name = 'DamageIndicator',
		Function = function(calling)
			if calling then
				task.spawn(function()
					table.insert(DamageIndicator.Connections, workspace.DescendantAdded:Connect(function(v)
						pcall(function()
                            if v.Name ~= 'DamageIndicatorPart' then return end
							local indicatorobj = v:FindFirstChildWhichIsA('BillboardGui'):FindFirstChildWhichIsA('Frame'):FindFirstChildWhichIsA('TextLabel')
							if indicatorobj then
                                if DamageIndicatorColorToggle.Enabled then
                                    -- indicatorobj.TextColor3 = Color3.fromHSV(DamageIndicatorColor.Hue, DamageIndicatorColor.Sat, DamageIndicatorColor.Value)
                                    if DamageIndicatorMode.Value == 'Rainbow' then
                                        if DamageIndicatorMode2.Value == 'Gradient' then
                                            indicatorobj.TextColor3 = Color3.fromHSV(tick() % mz / mz, orgI, orgI)
                                        else
                                            runService.Stepped:Connect(function()
                                                orgI = (orgI % #RGBColors) + 1
                                                indicatorobj.TextColor3 = RGBColors[orgI]
                                            end)
                                        end
                                    elseif DamageIndicatorMode.Value == 'Custom' then
                                        indicatorobj.TextColor3 = Color3.fromHSV(
                                            DamageIndicatorColor.Hue, 
                                            DamageIndicatorColor.Sat, 
                                            DamageIndicatorColor.Value
                                        )
                                    else
                                        indicatorobj.TextColor3 = Color3.fromRGB(127, 0, 255)
                                    end
                                end
                                if DamageIndicatorTextToggle.Enabled then
                                    if DamageIndicatorMode1.Value == 'Custom' then
                                        print(getrandomvalue(DamageIndicatorText.ListEnabled))
                                        local o = getrandomvalue(DamageIndicatorText.ListEnabled)
                                        indicatorobj.Text = o ~= '' and o or indicatorobj.Text
									elseif DamageIndicatorMode1.Value == 'Multiple' then
										indicatorobj.Text = DamageMessages[math.random(orgI, #DamageMessages)]
									else
										indicatorobj.Text = 'Render Intents on top!'
									end
								end
								indicatorobj.Font = DamageIndicatorFontToggle.Enabled and Enum.Font[DamageIndicatorFont.Value] or indicatorobject.Font
							end
						end)
					end))
				end)
			end
		end
	})
    DamageIndicatorMode = DamageIndicator:CreateDropdown({
		Name = 'Color Mode',
		List = {
			'Rainbow',
			'Custom',
			'Lunar'
		},
		HoverText = 'Mode to color the Damage Indicator',
		Value = 'Rainbow',
		Function = function() end
	})
	DamageIndicatorMode2 = DamageIndicator:CreateDropdown({
		Name = 'Rainbow Mode',
		List = {
			'Gradient',
			'Paint'
		},
		HoverText = 'Mode to color the Damage Indicator\nwith Rainbow Color Mode',
		Value = 'Gradient',
		Function = function() end
	})
    DamageIndicatorMode1 = DamageIndicator:CreateDropdown({
		Name = 'Text Mode',
		List = {
            'Custom',
			'Multiple',
			'Lunar'
		},
		HoverText = 'Mode to change the Damage Indicator Text',
		Value = 'Custom',
		Function = function() end
	})
	DamageIndicatorColorToggle = DamageIndicator:CreateToggle({
		Name = 'Custom Color',
		Function = function(calling) pcall(function() DamageIndicatorColor.Object.Visible = calling end) end
	})
	DamageIndicatorColor = DamageIndicator:CreateColorSlider({
		Name = 'Text Color',
		Function = function() end
	})
	DamageIndicatorTextToggle = DamageIndicator:CreateToggle({
		Name = 'Custom Text',
		HoverText = 'random messages for the indicator',
		Function = function(calling) pcall(function() DamageIndicatorText.Object.Visible = calling end) end
	})
	DamageIndicatorText = DamageIndicator:CreateTextList({
		Name = 'Text',
		TempText = 'Indicator Text',
		AddFunction = function() end
	})
	DamageIndicatorFontToggle = DamageIndicator:CreateToggle({
		Name = 'Custom Font',
		Function = function(calling) pcall(function() DamageIndicatorFont.Object.Visible = calling end) end
	})
	DamageIndicatorFont = DamageIndicator:CreateDropdown({
		Name = 'Font',
		List = GetEnumItems('Font'),
		Function = function() end
	})
	DamageIndicatorColor.Object.Visible = DamageIndicatorColorToggle.Enabled
	DamageIndicatorText.Object.Visible = DamageIndicatorTextToggle.Enabled
	DamageIndicatorFont.Object.Visible = DamageIndicatorFontToggle.Enabled
end)

run(function()
    local RH
    RH = vape.Categories.Modules:CreateModule({
        Name = "Rainbow Health",
        PerformanceModeBlacklisted = true,
        Function = function(bool)
            if bool then
                RH:Clean(runService.RenderStepped:Connect(function()
                    if lplr.PlayerGui:FindFirstChild('hotbar') and lplr.PlayerGui.hotbar:FindFirstChild('1') and lplr.PlayerGui.hotbar['1']:FindFirstChild('HotbarHealthbarContainer') then
                        for _,v in next, lplr.PlayerGui.hotbar['1'].HotbarHealthbarContainer.HealthbarProgressWrapper:GetChildren()do
                            if not v:IsA('UIListLayout') then
                                v.BackgroundColor3 = Color3.fromHSV(tick()%5/5,1,1)
                            end
                        end
                    end
                end))
            end
        end
    })

    local RA
    RA = vape.Categories.Modules:CreateModule({
        Name = "Rainbow Armor",
        PerformanceModeBlacklisted = true,
        Function = function(bool)
            if bool then
                RA:Clean(runService.RenderStepped:Connect(function()
                    pcall(function()
                        for _,v in next, game.Players.LocalPlayer.Character:GetChildren() do
                            if string.find(string.lower(v.Name), 'boots') or string.find(string.lower(v.Name), 'chestplate') or string.find(string.lower(v.Name), 'helmet') then
                                v.Handle.Material = "ForceField"
                                v.Handle.TextureID = ""
                                v.Handle.Color = Color3.fromHSV(tick()%5/5,1,1)
                            end
                        end
                    end)
                end))
            end
        end
    })

    local RI
    local RIW = false
    RI = vape.Categories.Modules:CreateModule({
        Name = "Rainbow Hotbar",
        PerformanceModeBlacklisted = true,
        Function = function(bool)
            if bool then
                RI:Clean(runService.RenderStepped:Connect(function()
                    if RIW then return end
                    RIW = true
                    pcall(function()
                        for i = 0.1, 0.4, 0.001 do
                            local r = math.clamp(1 - i, 0, 1)
                            local l = math.clamp(0.9 - i, 0, 1)
            
                            local hsvColor1, hsvColor2 = Color3.fromHSV(r, 0.5, 1), Color3.fromHSV(l, 0.5, 1)
                            for _,v in next, game.Players.LocalPlayer.PlayerGui.hotbar:GetDescendants() do
                                if v:IsA('Frame') then
                                    if v:FindFirstChildOfClass('ImageButton') then
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('UICorner') then
                                            Instance.new('UICorner', v:FindFirstChildOfClass('ImageButton'))
                                        end
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('UIGradient') then
                                            Instance.new('UIGradient', v:FindFirstChildOfClass('ImageButton'))
                                        end
                                        if v:FindFirstChildOfClass('ImageButton'):FindFirstChild("1") then
                                            v:FindFirstChildOfClass('ImageButton')["1"]:Destroy()
                                        end
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('GradientStroke') then
                                            local stroke = Instance.new('UIStroke',v:FindFirstChildOfClass('ImageButton'))
                                            stroke.Thickness = 1
                                            stroke.Color = Color3.fromRGB(255,255,255)
                                            stroke.Transparency = 0.5
                                            stroke.Name = "GradientStroke"
                                            local grad = Instance.new('UIGradient', stroke)
                                            grad.Rotation = 0
                                        end
                                        v:FindFirstChildOfClass('ImageButton').BackgroundColor3 = Color3.fromRGB(255,255,255)
                                        v:FindFirstChildOfClass('ImageButton').ImageColor3 = Color3.fromRGB(255,255,255)
                                        
                                        if v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient') ~= nil then
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient').Rotation = 0
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient').Color = createSequence({c1 = hsvColor1, c2 = hsvColor2})
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChild('GradientStroke'):FindFirstChildOfClass('UIGradient').Color = createSequence({c1 = hsvColor1, c2 = hsvColor2})
                                        end
                                    end
                                end
                            end
                            task.wait()
                        end
                        for i = 0.6, 0.9, 0.001 do
                            local r = math.clamp(i, 0, 1)
                            local l = math.clamp(i - 0.1, 0, 1)
            
                            local hsvColor1, hsvColor2 = Color3.fromHSV(r, 0.5, 1), Color3.fromHSV(l, 0.5, 1)
                            for _,v in next, game.Players.LocalPlayer.PlayerGui.hotbar:GetDescendants() do
                                if v:IsA('Frame') then
                                    if v:FindFirstChildOfClass('ImageButton') then
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('UICorner') then
                                            Instance.new('UICorner', v:FindFirstChildOfClass('ImageButton'))
                                        end
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('UIGradient') then
                                            Instance.new('UIGradient', v:FindFirstChildOfClass('ImageButton'))
                                        end
                                        if v:FindFirstChildOfClass('ImageButton'):FindFirstChild("1") then
                                            v:FindFirstChildOfClass('ImageButton')["1"]:Destroy()
                                        end
                                        if not v:FindFirstChildOfClass('ImageButton'):FindFirstChild('GradientStroke') then
                                            local stroke = Instance.new('UIStroke',v:FindFirstChildOfClass('ImageButton'))
                                            stroke.Thickness = 1
                                            stroke.Color = Color3.fromRGB(255,255,255)
                                            stroke.Transparency = 0.5
                                            stroke.Name = "GradientStroke"
                                            local grad = Instance.new('UIGradient', stroke)
                                            grad.Rotation = 0
                                        end
                                        v:FindFirstChildOfClass('ImageButton').BackgroundColor3 = Color3.fromRGB(255,255,255)
                                        v:FindFirstChildOfClass('ImageButton').ImageColor3 = Color3.fromRGB(255,255,255)
                                        
                                        if v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient') ~= nil then
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient').Rotation = 0
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChildOfClass('UIGradient').Color = createSequence({c1 = hsvColor1, c2 = hsvColor2})
                                            v:FindFirstChildOfClass('ImageButton'):FindFirstChild('GradientStroke'):FindFirstChildOfClass('UIGradient').Color = createSequence({c1 = hsvColor1, c2 = hsvColor2})
                                        end
                                    end
                                end
                            end
                            task.wait()
                        end
                    end)
                    RIW = false
                end))
            end
        end
    })
end)