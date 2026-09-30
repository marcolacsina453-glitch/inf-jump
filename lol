-- =================================================== -- QUAN SCRIPT - FULL ENGLISH VERSION (OPTIMIZED) -- =================================================== local Players = game:GetService("Players") local ReplicatedStorage = game:GetService("ReplicatedStorage") local RunService = game:GetService("RunService") local UserInputService = game:GetService("UserInputService") local Workspace = game:GetService("Workspace") local TextChatService = game:GetService("TextChatService") local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer local ProtectedPlayers = {}

-- Notification function local function Notification(title, text) pcall(function() StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 }) end) end

-- Chat output function local function sayInChat(message) pcall(function() if TextChatService and TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral") if generalChannel then generalChannel:SendAsync("[QUAN SCRIPT] " .. message) return end end ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") :FindFirstChild("SayMessageRequest") :FireServer("[QUAN SCRIPT] " .. message, "All") end) end

-- =================================================== -- IMMUNE / PROTECT SYSTEM (METATABLE HOOK) -- =================================================== pcall(function() if getrawmetatable and setreadonly and newcclosure and getnamecallmethod then local gmt = getrawmetatable(game) setreadonly(gmt, false)

    local oldNamecall = gmt.__namecall

    gmt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" or method == "InvokeServer" then
            for _, p in pairs(ProtectedPlayers) do
                if p and p.Character then
                    for _, arg in pairs(args) do
                        if arg == p
                        or arg == p.Character
                        or (type(arg) == "table" and rawget(arg, "Instance") == p.Character) then
                            return nil
                        end
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(gmt, true)
end
end)

-- Configurations & States local AUTO_ATTACK_ENABLED = false -- Mặc định TẮT khi vào script local BLOCK_ENABLED = false local RESPAWN_NEAR_TARGET = true

local Config = { HitboxExpand = true, Noclip = false, InfJump = false, SpeedEnabled = false, SpeedValue = 50, TargetHeightAbove = 3, -- Y Offset TargetDistanceBehind = 2, -- Z Offset (+ is backward, - is forward) TargetSideOffset = 0, -- X Offset (+ is right, - is left) TargetChaseSpeed = 200, -- Chase / Hover speed ExpandedHitboxSize = Vector3.new(100, 100, 100) }

local CurrentMode = "idle" local TargetPlayer = nil local targetThread = nil

-- Virtual Input Manager local VirtualInputManager = nil pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local function sendKey(keyCode) pcall(function() if VirtualInputManager then VirtualInputManager:SendKeyEvent(true, keyCode, false, game) task.wait(0.05) VirtualInputManager:SendKeyEvent(false, keyCode, false, game) end end) end

local function getHRP(plr) local p = plr or LocalPlayer return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end

local function getHumanoid(plr) local p = plr or LocalPlayer return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end

local function isImmune(plr) if not plr then return false end for _, p in ipairs(ProtectedPlayers) do if p == plr then return true end end return false end

local function getPlayerByFuzzy(name) name = tostring(name):lower() if name == "" then return nil end for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and (p.Name:lower():find(name, 1, true) or p.DisplayName:lower():find(name, 1, true)) then return p end end return nil end

-- Teleport directly to target 1 time local function teleportToTarget() if not TargetPlayer then return end local tHRP = getHRP(TargetPlayer) local myHRP = getHRP(LocalPlayer) if tHRP and myHRP then myHRP.CFrame = tHRP.CFrame * CFrame.new(Config.TargetSideOffset, Config.TargetHeightAbove, Config.TargetDistanceBehind) end end

local function handleRespawnPosition() if not TargetPlayer then return end local tHRP = getHRP(TargetPlayer) local myHRP = getHRP(LocalPlayer) if not tHRP or not myHRP then return end

local nearestSpawn = nil
local minDistance = math.huge

if RESPAWN_NEAR_TARGET then
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            local dist = (obj.Position - tHRP.Position).Magnitude
            if dist < minDistance then
                minDistance = dist
                nearestSpawn = obj
            end
        end
    end
end

if nearestSpawn and minDistance <= 150 then
    myHRP.CFrame = nearestSpawn.CFrame + Vector3.new(0, 4, 0)
else
    teleportToTarget()
end

task.wait(0.1)
teleportToTarget()
end

local function forceResetAndRespawn() pcall(function() local char = LocalPlayer.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.Health = 0 end end end) LocalPlayer.CharacterAdded:Wait() local newChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() newChar:WaitForChild("HumanoidRootPart", 5) task.wait(0.2) handleRespawnPosition() end

-- Tự động Teleport đến target mỗi khi nhân vật mình chết/respawn lại LocalPlayer.CharacterAdded:Connect(function(newChar) if CurrentMode == "target" and TargetPlayer then newChar:WaitForChild("HumanoidRootPart", 5) task.wait(0.2) teleportToTarget() end end)

local cachedCombatRemote = nil local function getCombatRemote() if cachedCombatRemote and cachedCombatRemote.Parent then return cachedCombatRemote end for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do if obj:IsA("RemoteEvent") then local n = obj.Name:lower() if n:find("combat") or n:find("attack") or n:find("m1") or n:find("punch") or n:find("block") then cachedCombatRemote = obj return obj end end end return nil end

-- Smooth 2x M1 Loop task.spawn(function() while true do task.wait(0.03) if AUTO_ATTACK_ENABLED or CurrentMode == "target" then pcall(function() local remote = getCombatRemote() if remote then remote:FireServer("M1") task.wait(0.01) remote:FireServer("M1") end end) end end end)

-- Auto Block Loop task.spawn(function() while true do task.wait(0.05) if BLOCK_ENABLED then pcall(function() local remote = getCombatRemote() if remote then remote:FireServer("Block", true) else sendKey(Enum.KeyCode.F) end end) end end end)

-- Press F key during Target mode task.spawn(function() while true do task.wait(1) if CurrentMode == "target" then sendKey(Enum.KeyCode.F) end end end)

local function stopTargeting() if CurrentMode == "target" then CurrentMode = "idle" TargetPlayer = nil AUTO_ATTACK_ENABLED = false if targetThread then task.cancel(targetThread); targetThread = nil end sayInChat("Targeting stopped!") end end

local function startTargetingLogic(plr) if not plr or not plr.Parent then sayInChat("Error: Target not found!") return end

stopTargeting()
CurrentMode = "target"
TargetPlayer = plr
AUTO_ATTACK_ENABLED = true -- Tự động BẬT 2x M1 khi target

sayInChat("Targeting: " .. plr.DisplayName .. " (@" .. plr.Name .. ")")

-- 1. Reset lần đầu
forceResetAndRespawn()

targetThread = task.spawn(function()
    local lastBTime = 0

    while CurrentMode == "target" and TargetPlayer and TargetPlayer.Parent do
        local tHum = getHumanoid(TargetPlayer)

        -- 2. Khi Target chết: Reset + Teleport 1 lần + Bám đuổi
        if not tHum or tHum.Health <= 0 then
            forceResetAndRespawn()
        end

        if tHum and tHum.Health <= 4 then
            if tick() - lastBTime >= 4 then
                lastBTime = tick()
                sendKey(Enum.KeyCode.B)
            end
        end
        task.wait(0.05)
    end
end)
end

-- Movement Loop (Hovering & Smooth Following) RunService.RenderStepped:Connect(function(dt) pcall(function() local myHum = getHumanoid() local myHRP = getHRP(LocalPlayer)

    if CurrentMode ~= "idle" and TargetPlayer and TargetPlayer.Character then
        local tHRP = getHRP(TargetPlayer)
        local tHum = getHumanoid(TargetPlayer)

        if myHRP and tHRP and tHum and tHum.Health > 0 then
            myHRP.AssemblyLinearVelocity = Vector3.zero
            myHRP.AssemblyAngularVelocity = Vector3.zero

            local targetGoalPos = (tHRP.CFrame * CFrame.new(Config.TargetSideOffset, Config.TargetHeightAbove, Config.TargetDistanceBehind)).Position
            local currentPos = myHRP.Position
            local distance = (targetGoalPos - currentPos).Magnitude

            local nextPos = currentPos
            if distance > 0.2 then
                local moveDir = (targetGoalPos - currentPos).Unit
                local step = math.min(distance, Config.TargetChaseSpeed * dt)
                nextPos = currentPos + (moveDir * step)
            else
                nextPos = targetGoalPos
            end

            myHRP.CFrame = CFrame.new(nextPos, tHRP.Position)
        end
    end

    if Config.SpeedEnabled and CurrentMode == "idle" then
        if myHum and myHRP and myHum.MoveDirection.Magnitude > 0 then
            myHRP.CFrame = myHRP.CFrame + (myHum.MoveDirection * (Config.SpeedValue * dt))
        end
    end
end)
end)

-- Noclip RunService.Stepped:Connect(function() if Config.Noclip or CurrentMode ~= "idle" then pcall(function() if LocalPlayer.Character then for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end end) end end)

-- Infinite Jump UserInputService.JumpRequest:Connect(function() if Config.InfJump then pcall(function() local hum = getHumanoid() if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end)

-- Hitbox Expander RunService.Heartbeat:Connect(function() if not Config.HitboxExpand then return end pcall(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then local hrp = getHRP(p) if hrp then if isImmune(p) then hrp.Size = Vector3.new(2, 2, 1) hrp.Transparency = 0 hrp.CanCollide = true else hrp.Size = Config.ExpandedHitboxSize hrp.Transparency = 1 hrp.CanCollide = false end end end end end) end)

-- =================================================== -- CHAT COMMANDS HANDLER -- =================================================== LocalPlayer.Chatted:Connect(function(msg) local args = msg:split(" ") local cmd = args[1] and args[1]:lower() local val = args[2]

-- 1. Safe / Immune System
if (cmd == ";safe" or cmd == ";immune") and val then
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower()) then
            if not table.find(ProtectedPlayers, p) then
                table.insert(ProtectedPlayers, p)
                Notification("IMMUNE SYSTEM", "Protected: " .. p.DisplayName)
                sayInChat("Added " .. p.DisplayName .. " to Safe List!")
            end
            break
        end
    end

elseif (cmd == ";unsafe" or cmd == ";unimmune") and val then
    for i, p in pairs(ProtectedPlayers) do
        if p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower()) then
            table.remove(ProtectedPlayers, i)
            Notification("IMMUNE SYSTEM", "Unprotected: " .. p.DisplayName)
            sayInChat("Removed " .. p.DisplayName .. " from Safe List!")
            break
        end
    end

-- 2. Position Controls
elseif cmd == ";w" and val and tonumber(val) then
    Config.TargetDistanceBehind = -tonumber(val) -- Forward
    sayInChat("Offset Forward: " .. tonumber(val))

elseif cmd == ";s" and val and tonumber(val) then
    Config.TargetDistanceBehind = tonumber(val) -- Backward
    sayInChat("Offset Backward: " .. tonumber(val))

elseif cmd == ";a" and val and tonumber(val) then
    Config.TargetSideOffset = -tonumber(val) -- Left
    sayInChat("Offset Left: " .. tonumber(val))

elseif cmd == ";d" and val and tonumber(val) then
    Config.TargetSideOffset = tonumber(val) -- Right
    sayInChat("Offset Right: " .. tonumber(val))

elseif cmd == ";height" and val and tonumber(val) then
    Config.TargetHeightAbove = tonumber(val) -- Height
    sayInChat("Offset Height: " .. Config.TargetHeightAbove)

elseif cmd == ";cspeed" and val and tonumber(val) then
    Config.TargetChaseSpeed = tonumber(val)
    sayInChat("Chase Speed set to: " .. Config.TargetChaseSpeed)

-- 3. Target Commands
elseif cmd == ";target" or cmd == "!target" or cmd == "/target" then
    if val then
        local p = getPlayerByFuzzy(val)
        if p then startTargetingLogic(p) else sayInChat("Player not found: " .. val) end
    else
        sayInChat("Please enter a player name! Example: ;target username")
    end

elseif cmd == ";untarget" or cmd == "!untarget" or cmd == ";stop" then
    stopTargeting()

-- 4. Combat & Movement Hacks
elseif cmd == ";m1" or cmd == ";attack" then
    AUTO_ATTACK_ENABLED = not AUTO_ATTACK_ENABLED
    sayInChat("Auto 2x M1: " .. (AUTO_ATTACK_ENABLED and "ENABLED" or "DISABLED"))

elseif cmd == ";block" then
    BLOCK_ENABLED = not BLOCK_ENABLED
    sayInChat("Auto Block: " .. (BLOCK_ENABLED and "ENABLED" or "DISABLED"))

elseif cmd == ";hitbox" then
    Config.HitboxExpand = not Config.HitboxExpand
    sayInChat("Hitbox Expander: " .. (Config.HitboxExpand and "ENABLED" or "DISABLED"))

elseif cmd == ";speed" then
    if val and tonumber(val) then
        Config.SpeedValue = tonumber(val)
        Config.SpeedEnabled = true
        sayInChat("Speed Hack: ENABLED (Speed: " .. Config.SpeedValue .. ")")
    else
        Config.SpeedEnabled = not Config.SpeedEnabled
        sayInChat("Speed Hack: " .. (Config.SpeedEnabled and "ENABLED" or "DISABLED"))
    end

elseif cmd == ";noclip" then
    Config.Noclip = not Config.Noclip
    sayInChat("Noclip: " .. (Config.Noclip and "ENABLED" or "DISABLED"))

elseif cmd == ";infjump" then
    Config.InfJump = not Config.InfJump
    sayInChat("Inf Jump: " .. (Config.InfJump and "ENABLED" or "DISABLED"))

-- 5. Full Command List (Chia làm 2 dòng Chat)
elseif cmd == ";help" or cmd == ";cmds" then
    sayInChat("[PART 1] Target: ;target [name] | ;stop | ;w [num] | ;s [num] | ;a [num] | ;d [num] | ;height [num] | ;cspeed [num]")
    task.wait(1)
    sayInChat("[PART 2] Hacks: ;m1 | ;block | ;hitbox | ;speed [num] | ;noclip | ;infjump | ;safe [name] | ;unsafe [name]")
end
end)

-- Loaded Message task.wait(0.5) sayInChat("Script loaded successfully! Type ;help for full command list.")
