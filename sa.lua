local passedApi = ...

local supportedPlaces = {
    [2753915549] = true,
    [4442272183] = true,
    [7449423635] = true
}

if not supportedPlaces[game.PlaceId] and game.GameId ~= 994732206 then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function SendNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local function InitExtension(api)
    if not api or not api.MainTab then return end

    local fruitFinderConn = nil
    local fruitAddedConn = nil
    local fruitFinderGuis = {}
    local activeFruits = {}
    local notifiedFruits = {}

    local chestEspConn = nil
    local chestGuis = {}

    local playerEspConn = nil
    local playerGuis = {}

    local questAssistConn = nil
    local questGuis = {}

    local bossTimerConn = nil
    local bossGuis = {}

    local fastAttackConn = nil
    local fastAttackEnabled = false
    local lastFastAttackTime = 0

    local infiniteJumpConn = nil
    local infiniteJumpEnabled = false

    local speedBoostCharConn = nil
    local speedBoostEnabled = false
    local originalWalkSpeed = 16

    local fruitLocationConn = nil
    local fruitLocationEnabled = false

    local chestInteractionConn = nil
    local chestInteractionGui = nil
    local chestInteractionTarget = nil

    local charInfoPanelFrame = nil
    local charInfoConn = nil

    local hakiDisplayFrame = nil
    local hakiDisplayConn = nil

    local seaEventConn = nil
    local seaEventAddedConn = nil
    local seaEventGuis = {}
    local activeSeaEvents = {}

    local islandButtons = {}

    local function ClearGuis(guiTable)
        for _, gui in pairs(guiTable) do
            if typeof(gui) == "Instance" and gui.Parent then
                gui:Destroy()
            end
        end
        table.clear(guiTable)
    end

    local function IsPlayerOwned(item)
        if not item then return true end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and (item:IsDescendantOf(p.Character) or item == p.Character) then
                return true
            end
            local bp = p:FindFirstChild("Backpack")
            if bp and item:IsDescendantOf(bp) then
                return true
            end
        end
        return false
    end

    local function CleanupFruitFinder()
        if fruitFinderConn then
            fruitFinderConn:Disconnect()
            fruitFinderConn = nil
        end
        if fruitAddedConn then
            fruitAddedConn:Disconnect()
            fruitAddedConn = nil
        end
        ClearGuis(fruitFinderGuis)
        table.clear(activeFruits)
        table.clear(notifiedFruits)
    end

    local function CleanupChestEsp()
        if chestEspConn then
            chestEspConn:Disconnect()
            chestEspConn = nil
        end
        ClearGuis(chestGuis)
    end

    local function CleanupPlayerEsp()
        if playerEspConn then
            playerEspConn:Disconnect()
            playerEspConn = nil
        end
        ClearGuis(playerGuis)
    end

    local function CleanupQuestAssist()
        if questAssistConn then
            questAssistConn:Disconnect()
            questAssistConn = nil
        end
        ClearGuis(questGuis)
    end

    local function CleanupBossTimer()
        if bossTimerConn then
            bossTimerConn:Disconnect()
            bossTimerConn = nil
        end
        ClearGuis(bossGuis)
    end

    local function CleanupFastAttack()
        fastAttackEnabled = false
        if fastAttackConn then
            fastAttackConn:Disconnect()
            fastAttackConn = nil
        end
        lastFastAttackTime = 0
    end

    local function CleanupInfiniteJump()
        infiniteJumpEnabled = false
        if infiniteJumpConn then
            infiniteJumpConn:Disconnect()
            infiniteJumpConn = nil
        end
    end

    local function CleanupSpeedBoost()
        speedBoostEnabled = false
        if speedBoostCharConn then
            speedBoostCharConn:Disconnect()
            speedBoostCharConn = nil
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = originalWalkSpeed
            end
        end
    end

    local function CleanupFruitLocationHelper()
        fruitLocationEnabled = false
        if fruitLocationConn then
            fruitLocationConn:Disconnect()
            fruitLocationConn = nil
        end
    end

    local function CleanupChestInteractionHelper()
        if chestInteractionConn then
            chestInteractionConn:Disconnect()
            chestInteractionConn = nil
        end
        if chestInteractionGui and chestInteractionGui.Parent then
            chestInteractionGui:Destroy()
            chestInteractionGui = nil
        end
        chestInteractionTarget = nil
    end

    local function CleanupCharInfoPanel()
        if charInfoConn then
            charInfoConn:Disconnect()
            charInfoConn = nil
        end
        if charInfoPanelFrame and charInfoPanelFrame.Parent then
            charInfoPanelFrame:Destroy()
            charInfoPanelFrame = nil
        end
    end

    local function CleanupHakiDisplay()
        if hakiDisplayConn then
            hakiDisplayConn:Disconnect()
            hakiDisplayConn = nil
        end
        if hakiDisplayFrame and hakiDisplayFrame.Parent then
            hakiDisplayFrame:Destroy()
            hakiDisplayFrame = nil
        end
    end

    local function CleanupSeaEventTracker()
        if seaEventConn then
            seaEventConn:Disconnect()
            seaEventConn = nil
        end
        if seaEventAddedConn then
            seaEventAddedConn:Disconnect()
            seaEventAddedConn = nil
        end
        ClearGuis(seaEventGuis)
        table.clear(activeSeaEvents)
    end

    api.CreateSection(api.MainTab, "BLOX FRUITS", 20)

    api.CreateToggle(api.MainTab, "Fruit Finder & Notifier", false, 21, function(state)
        if state then
            CleanupFruitFinder()

            local function ProcessFruit(item)
                if not (item:IsA("Tool") or item:IsA("Model")) then return end
                if IsPlayerOwned(item) then return end

                local itemName = item.Name:lower()
                if itemName:find("fruit") or item:FindFirstChild("Fruit") or item:GetAttribute("Fruit") then
                    local targetPart = item:FindFirstChild("Handle") or (item:IsA("BasePart") and item) or item:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        activeFruits[item] = targetPart

                        local myChar = LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local distText = ""
                        if myRoot then
                            local d = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                            distText = " (" .. tostring(d) .. "m)"
                        end

                        if not notifiedFruits[item] then
                            notifiedFruits[item] = true
                            SendNotification("Fruit Spawned!", item.Name .. distText, 6)
                        end

                        local bbg = fruitFinderGuis[item]
                        if not bbg or not bbg.Parent then
                            bbg = Instance.new("BillboardGui")
                            bbg.Name = "YARHM_FruitTag"
                            bbg.AlwaysOnTop = true
                            bbg.Size = UDim2.new(0, 140, 0, 38)
                            bbg.StudsOffset = Vector3.new(0, 2, 0)
                            bbg.Adornee = targetPart

                            local lbl = Instance.new("TextLabel")
                            lbl.Name = "FruitLabel"
                            lbl.Size = UDim2.new(1, 0, 0.5, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Text = item.Name
                            lbl.TextColor3 = Color3.fromRGB(255, 120, 60)
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            lbl.TextStrokeTransparency = 0
                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            lbl.Parent = bbg

                            local distLbl = Instance.new("TextLabel")
                            distLbl.Name = "DistLabel"
                            distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                            distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                            distLbl.BackgroundTransparency = 1
                            distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                            distLbl.Font = Enum.Font.GothamMedium
                            distLbl.TextSize = 11
                            distLbl.TextStrokeTransparency = 0
                            distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            distLbl.Parent = bbg

                            bbg.Parent = targetPart
                            fruitFinderGuis[item] = bbg
                        end
                        return true
                    end
                end
                return false
            end

            for _, child in ipairs(workspace:GetDescendants()) do
                ProcessFruit(child)
            end

            fruitAddedConn = workspace.DescendantAdded:Connect(function(child)
                task.wait(0.1)
                pcall(function()
                    ProcessFruit(child)
                end)
            end)

            fruitFinderConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    for item, targetPart in pairs(activeFruits) do
                        if not item.Parent or not targetPart.Parent or IsPlayerOwned(item) then
                            local gui = fruitFinderGuis[item]
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            fruitFinderGuis[item] = nil
                            activeFruits[item] = nil
                        else
                            local bbg = fruitFinderGuis[item]
                            if bbg and myRoot then
                                local distLbl = bbg:FindFirstChild("DistLabel")
                                if distLbl then
                                    local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                    distLbl.Text = tostring(dist) .. "m"
                                end
                            end
                        end
                    end
                end)
            end)
        else
            CleanupFruitFinder()
        end
    end)

    api.CreateToggle(api.MainTab, "Chest ESP", false, 22, function(state)
        if state then
            CleanupChestEsp()
            chestEspConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local activeChests = {}

                    local function ScanChests(parent)
                        if not parent then return end
                        for _, obj in ipairs(parent:GetChildren()) do
                            local name = obj.Name:lower()
                            if name:find("chest") then
                                local targetPart = (obj:IsA("BasePart") and obj) or obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("BasePart")
                                if targetPart then
                                    activeChests[obj] = true
                                    local bbg = chestGuis[obj]
                                    if not bbg or not bbg.Parent then
                                        bbg = Instance.new("BillboardGui")
                                        bbg.Name = "YARHM_ChestTag"
                                        bbg.AlwaysOnTop = true
                                        bbg.Size = UDim2.new(0, 110, 0, 32)
                                        bbg.StudsOffset = Vector3.new(0, 2, 0)
                                        bbg.Adornee = targetPart

                                        local lbl = Instance.new("TextLabel")
                                        lbl.Name = "ChestLabel"
                                        lbl.Size = UDim2.new(1, 0, 0.5, 0)
                                        lbl.BackgroundTransparency = 1
                                        lbl.Text = obj.Name
                                        lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                                        lbl.Font = Enum.Font.GothamBold
                                        lbl.TextSize = 11
                                        lbl.TextStrokeTransparency = 0
                                        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                        lbl.Parent = bbg

                                        local distLbl = Instance.new("TextLabel")
                                        distLbl.Name = "DistLabel"
                                        distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                                        distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                                        distLbl.BackgroundTransparency = 1
                                        distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                        distLbl.Font = Enum.Font.GothamMedium
                                        distLbl.TextSize = 10
                                        distLbl.TextStrokeTransparency = 0
                                        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                        distLbl.Parent = bbg

                                        bbg.Parent = targetPart
                                        chestGuis[obj] = bbg
                                    end

                                    local distLbl = bbg:FindFirstChild("DistLabel")
                                    if distLbl then
                                        local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                        distLbl.Text = tostring(dist) .. "m"
                                    end
                                end
                            end
                        end
                    end

                    ScanChests(workspace)
                    local chestFolder = workspace:FindFirstChild("Chests")
                    if chestFolder then
                        ScanChests(chestFolder)
                    end

                    for obj, gui in pairs(chestGuis) do
                        if not activeChests[obj] or not obj.Parent then
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            chestGuis[obj] = nil
                        end
                    end
                end)
            end)
        else
            CleanupChestEsp()
        end
    end)

    api.CreateToggle(api.MainTab, "Player ESP", false, 23, function(state)
        if state then
            CleanupPlayerEsp()
            playerEspConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local activePlayers = {}

                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local char = player.Character
                            local root = char:FindFirstChild("HumanoidRootPart")
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if root and hum and hum.Health > 0 then
                                activePlayers[player] = true
                                local bbg = playerGuis[player]
                                if not bbg or not bbg.Parent then
                                    bbg = Instance.new("BillboardGui")
                                    bbg.Name = "YARHM_PlayerTag"
                                    bbg.AlwaysOnTop = true
                                    bbg.Size = UDim2.new(0, 130, 0, 34)
                                    bbg.StudsOffset = Vector3.new(0, 2.5, 0)
                                    bbg.Adornee = root

                                    local nameLbl = Instance.new("TextLabel")
                                    nameLbl.Name = "NameLabel"
                                    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                                    nameLbl.BackgroundTransparency = 1
                                    nameLbl.Text = player.DisplayName
                                    nameLbl.TextColor3 = Color3.fromRGB(0, 200, 255)
                                    nameLbl.Font = Enum.Font.GothamBold
                                    nameLbl.TextSize = 11
                                    nameLbl.TextStrokeTransparency = 0
                                    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    nameLbl.Parent = bbg

                                    local infoLbl = Instance.new("TextLabel")
                                    infoLbl.Name = "InfoLabel"
                                    infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
                                    infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
                                    infoLbl.BackgroundTransparency = 1
                                    infoLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
                                    infoLbl.Font = Enum.Font.GothamMedium
                                    infoLbl.TextSize = 10
                                    infoLbl.TextStrokeTransparency = 0
                                    infoLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    infoLbl.Parent = bbg

                                    bbg.Parent = root
                                    playerGuis[player] = bbg
                                end

                                local infoLbl = bbg:FindFirstChild("InfoLabel")
                                if infoLbl then
                                    local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                                    infoLbl.Text = math.floor(hum.Health) .. " HP | " .. dist .. "m"
                                end
                            end
                        end
                    end

                    for player, gui in pairs(playerGuis) do
                        if not activePlayers[player] or not player.Parent then
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            playerGuis[player] = nil
                        end
                    end
                end)
            end)
        else
            CleanupPlayerEsp()
        end
    end)

    api.CreateToggle(api.MainTab, "Quest Assist", false, 24, function(state)
        if state then
            CleanupQuestAssist()
            questAssistConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local npcsFolder = workspace:FindFirstChild("NPCs")
                    local npcsToTrack = {}

                    local function ScanNpcs(container)
                        if not container then return end
                        for _, npc in ipairs(container:GetChildren()) do
                            if npc:IsA("Model") then
                                local name = npc.Name:lower()
                                if name:find("quest") or name:find("giver") or name:find("mission") then
                                    local targetPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head") or npc:FindFirstChildWhichIsA("BasePart")
                                    if targetPart then
                                        npcsToTrack[npc] = true
                                        local bbg = questGuis[npc]
                                        if not bbg or not bbg.Parent then
                                            bbg = Instance.new("BillboardGui")
                                            bbg.Name = "YARHM_QuestTag"
                                            bbg.AlwaysOnTop = true
                                            bbg.Size = UDim2.new(0, 140, 0, 36)
                                            bbg.StudsOffset = Vector3.new(0, 2.5, 0)
                                            bbg.Adornee = targetPart

                                            local lbl = Instance.new("TextLabel")
                                            lbl.Name = "QuestLabel"
                                            lbl.Size = UDim2.new(1, 0, 0.5, 0)
                                            lbl.BackgroundTransparency = 1
                                            lbl.Text = npc.Name
                                            lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                                            lbl.Font = Enum.Font.GothamBold
                                            lbl.TextSize = 12
                                            lbl.TextStrokeTransparency = 0
                                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                            lbl.Parent = bbg

                                            local distLbl = Instance.new("TextLabel")
                                            distLbl.Name = "DistLabel"
                                            distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                                            distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                                            distLbl.BackgroundTransparency = 1
                                            distLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
                                            distLbl.Font = Enum.Font.GothamMedium
                                            distLbl.TextSize = 11
                                            distLbl.TextStrokeTransparency = 0
                                            distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                            distLbl.Parent = bbg

                                            bbg.Parent = targetPart
                                            questGuis[npc] = bbg
                                        end

                                        local distLbl = bbg:FindFirstChild("DistLabel")
                                        if distLbl then
                                            local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                            distLbl.Text = tostring(dist) .. "m"
                                        end
                                    end
                                end
                            end
                        end
                    end

                    ScanNpcs(npcsFolder)
                    ScanNpcs(workspace)

                    for npc, gui in pairs(questGuis) do
                        if not npcsToTrack[npc] or not npc.Parent then
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            questGuis[npc] = nil
                        end
                    end
                end)
            end)
        else
            CleanupQuestAssist()
        end
    end)

    api.CreateToggle(api.MainTab, "Boss Timer", false, 25, function(state)
        if state then
            CleanupBossTimer()
            bossTimerConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then return end

                    local activeBosses = {}
                    local enemies = workspace:FindFirstChild("Enemies")

                    local function CheckBoss(mob)
                        if mob:IsA("Model") then
                            local hum = mob:FindFirstChildOfClass("Humanoid")
                            local root = mob:FindFirstChild("HumanoidRootPart")
                            if hum and root and hum.Health > 0 and hum.MaxHealth >= 5000 then
                                activeBosses[mob] = true
                                local bbg = bossGuis[mob]
                                if not bbg or not bbg.Parent then
                                    bbg = Instance.new("BillboardGui")
                                    bbg.Name = "YARHM_BossTag"
                                    bbg.AlwaysOnTop = true
                                    bbg.Size = UDim2.new(0, 160, 0, 40)
                                    bbg.StudsOffset = Vector3.new(0, 3, 0)
                                    bbg.Adornee = root

                                    local lbl = Instance.new("TextLabel")
                                    lbl.Name = "BossLabel"
                                    lbl.Size = UDim2.new(1, 0, 0.5, 0)
                                    lbl.BackgroundTransparency = 1
                                    lbl.Text = "BOSS: " .. mob.Name
                                    lbl.TextColor3 = Color3.fromRGB(255, 60, 60)
                                    lbl.Font = Enum.Font.GothamBold
                                    lbl.TextSize = 12
                                    lbl.TextStrokeTransparency = 0
                                    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    lbl.Parent = bbg

                                    local hpLbl = Instance.new("TextLabel")
                                    hpLbl.Name = "HpLabel"
                                    hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
                                    hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
                                    hpLbl.BackgroundTransparency = 1
                                    hpLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                                    hpLbl.Font = Enum.Font.GothamMedium
                                    hpLbl.TextSize = 11
                                    hpLbl.TextStrokeTransparency = 0
                                    hpLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    hpLbl.Parent = bbg

                                    bbg.Parent = root
                                    bossGuis[mob] = bbg
                                end

                                local hpLbl = bbg:FindFirstChild("HpLabel")
                                if hpLbl then
                                    local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                                    hpLbl.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) .. " (" .. dist .. "m)"
                                end
                            end
                        end
                    end

                    if enemies then
                        for _, mob in ipairs(enemies:GetChildren()) do
                            CheckBoss(mob)
                        end
                    end

                    for mob, gui in pairs(bossGuis) do
                        if not activeBosses[mob] or not mob.Parent then
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            bossGuis[mob] = nil
                        end
                    end
                end)
            end)
        else
            CleanupBossTimer()
        end
    end)

    api.CreateToggle(api.MainTab, "Island Teleport", false, 26, function(state)
        islandsVisible = state
        SetIslandsVisibility(state)
    end)

    api.CreateToggle(api.MainTab, "Fast Attack", false, 27, function(state)
        fastAttackEnabled = state
        if state then
            CleanupFastAttack()
            fastAttackEnabled = true
            fastAttackConn = RunService.RenderStepped:Connect(function()
                if not fastAttackEnabled then return end
                local currentTime = os.clock()
                if currentTime - lastFastAttackTime >= 0.1 then
                    lastFastAttackTime = currentTime
                    pcall(function()
                        local myChar = LocalPlayer.Character
                        if not myChar then return end
                        local tool = myChar:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate()
                        end
                    end)
                end
            end)
        else
            CleanupFastAttack()
        end
    end)

    api.CreateToggle(api.MainTab, "Infinite Jump", false, 28, function(state)
        infiniteJumpEnabled = state
        if state then
            CleanupInfiniteJump()
            infiniteJumpEnabled = true
            infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
                if infiniteJumpEnabled then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            CleanupInfiniteJump()
        end
    end)

    api.CreateToggle(api.MainTab, "Speed Boost", false, 29, function(state)
        speedBoostEnabled = state
        if state then
            CleanupSpeedBoost()
            speedBoostEnabled = true

            local function ApplySpeed(char)
                if not char then return end
                local hum = char:WaitForChild("Humanoid", 3)
                if hum then
                    originalWalkSpeed = hum.WalkSpeed
                    hum.WalkSpeed = 40
                end
            end

            ApplySpeed(LocalPlayer.Character)

            speedBoostCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if speedBoostEnabled then
                    ApplySpeed(newChar)
                end
            end)
        else
            CleanupSpeedBoost()
        end
    end)

    api.CreateToggle(api.MainTab, "Fruit Location Helper", false, 30, function(state)
        fruitLocationEnabled = state
        if state then
            CleanupFruitLocationHelper()
            fruitLocationEnabled = true
            fruitLocationConn = RunService.RenderStepped:Connect(function()
                if not fruitLocationEnabled then return end
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local camera = workspace.CurrentCamera
                    if not myRoot or not camera then return end

                    local closestPart = nil
                    local closestDist = math.huge

                    for item, targetPart in pairs(activeFruits) do
                        if item.Parent and targetPart.Parent and not IsPlayerOwned(item) then
                            local d = (myRoot.Position - targetPart.Position).Magnitude
                            if d < closestDist then
                                closestDist = d
                                closestPart = targetPart
                            end
                        end
                    end

                    if closestPart then
                        local currentLook = camera.CFrame.LookVector
                        local targetDir = (closestPart.Position - camera.CFrame.Position).Unit
                        local newLook = currentLook:Lerp(targetDir, 0.08)
                        camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
                    end
                end)
            end)
        else
            CleanupFruitLocationHelper()
        end
    end)

    api.CreateToggle(api.MainTab, "Chest Interaction Helper", false, 31, function(state)
        if state then
            CleanupChestInteractionHelper()
            chestInteractionConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then
                        if chestInteractionGui and chestInteractionGui.Parent then
                            chestInteractionGui:Destroy()
                            chestInteractionGui = nil
                        end
                        chestInteractionTarget = nil
                        return
                    end

                    local nearestChestPart = nil
                    local nearestDist = 25

                    local function CheckChests(container)
                        if not container then return end
                        for _, obj in ipairs(container:GetChildren()) do
                            local name = obj.Name:lower()
                            if name:find("chest") then
                                local targetPart = (obj:IsA("BasePart") and obj) or obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("BasePart")
                                if targetPart then
                                    local dist = (myRoot.Position - targetPart.Position).Magnitude
                                    if dist <= nearestDist then
                                        nearestDist = dist
                                        nearestChestPart = targetPart
                                    end
                                end
                            end
                        end
                    end

                    CheckChests(workspace)
                    local chestFolder = workspace:FindFirstChild("Chests")
                    if chestFolder then
                        CheckChests(chestFolder)
                    end

                    if nearestChestPart then
                        if chestInteractionTarget ~= nearestChestPart then
                            if chestInteractionGui and chestInteractionGui.Parent then
                                chestInteractionGui:Destroy()
                            end
                            chestInteractionTarget = nearestChestPart

                            local bbg = Instance.new("BillboardGui")
                            bbg.Name = "YARHM_ChestInteractionPrompt"
                            bbg.AlwaysOnTop = true
                            bbg.Size = UDim2.new(0, 150, 0, 42)
                            bbg.StudsOffset = Vector3.new(0, 3, 0)
                            bbg.Adornee = nearestChestPart

                            local promptFrame = Instance.new("Frame")
                            promptFrame.Size = UDim2.new(1, 0, 1, 0)
                            promptFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                            promptFrame.BorderSizePixel = 0
                            promptFrame.Parent = bbg

                            local pCorner = Instance.new("UICorner")
                            pCorner.CornerRadius = UDim.new(0, 6)
                            pCorner.Parent = promptFrame

                            local pStroke = Instance.new("UIStroke")
                            pStroke.Thickness = 1
                            pStroke.Color = Color3.fromRGB(255, 215, 0)
                            pStroke.Parent = promptFrame

                            local titleLbl = Instance.new("TextLabel")
                            titleLbl.Name = "PromptTitle"
                            titleLbl.Size = UDim2.new(1, 0, 0.5, 0)
                            titleLbl.BackgroundTransparency = 1
                            titleLbl.Text = "[CHEST NEARBY]"
                            titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                            titleLbl.Font = Enum.Font.GothamBold
                            titleLbl.TextSize = 11
                            titleLbl.Parent = promptFrame

                            local descLbl = Instance.new("TextLabel")
                            descLbl.Name = "PromptDesc"
                            descLbl.Size = UDim2.new(1, 0, 0.5, 0)
                            descLbl.Position = UDim2.new(0, 0, 0.5, 0)
                            descLbl.BackgroundTransparency = 1
                            descLbl.Text = "Walk close to touch"
                            descLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
                            descLbl.Font = Enum.Font.GothamMedium
                            descLbl.TextSize = 10
                            descLbl.Parent = promptFrame

                            bbg.Parent = nearestChestPart
                            chestInteractionGui = bbg
                        else
                            if chestInteractionGui and chestInteractionGui.Parent then
                                local promptFrame = chestInteractionGui:FindFirstChildOfClass("Frame")
                                local descLbl = promptFrame and promptFrame:FindFirstChild("PromptDesc")
                                if descLbl then
                                    descLbl.Text = "Touch chest (" .. math.floor(nearestDist) .. "m)"
                                end
                            end
                        end
                    else
                        if chestInteractionGui and chestInteractionGui.Parent then
                            chestInteractionGui:Destroy()
                            chestInteractionGui = nil
                        end
                        chestInteractionTarget = nil
                    end
                end)
            end)
        else
            CleanupChestInteractionHelper()
        end
    end)

    api.CreateToggle(api.MainTab, "Character Info Panel", false, 32, function(state)
        if state then
            CleanupCharInfoPanel()

            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local targetParent = playerGui and (playerGui:FindFirstChild("YARHM_Gui") or playerGui) or LocalPlayer:WaitForChild("PlayerGui")

            charInfoPanelFrame = Instance.new("Frame")
            charInfoPanelFrame.Name = "YARHM_CharInfoPanel"
            charInfoPanelFrame.Size = UDim2.new(0, 165, 0, 80)
            charInfoPanelFrame.Position = UDim2.new(1, -175, 0.72, 0)
            charInfoPanelFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            charInfoPanelFrame.BorderSizePixel = 0
            charInfoPanelFrame.Parent = targetParent

            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 8)
            cCorner.Parent = charInfoPanelFrame

            local cStroke = Instance.new("UIStroke")
            cStroke.Thickness = 1.2
            cStroke.Color = Color3.fromRGB(45, 45, 58)
            cStroke.Parent = charInfoPanelFrame

            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            layout.Parent = charInfoPanelFrame

            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 10)
            pad.PaddingRight = UDim.new(0, 10)
            pad.Parent = charInfoPanelFrame

            local hpLbl = Instance.new("TextLabel")
            hpLbl.Name = "HpLabel"
            hpLbl.Size = UDim2.new(1, 0, 0, 20)
            hpLbl.BackgroundTransparency = 1
            hpLbl.Text = "HP: -- / --"
            hpLbl.TextColor3 = Color3.fromRGB(60, 255, 120)
            hpLbl.Font = Enum.Font.GothamBold
            hpLbl.TextSize = 11
            hpLbl.TextXAlignment = Enum.TextXAlignment.Left
            hpLbl.LayoutOrder = 1
            hpLbl.Parent = charInfoPanelFrame

            local energyLbl = Instance.new("TextLabel")
            energyLbl.Name = "EnergyLabel"
            energyLbl.Size = UDim2.new(1, 0, 0, 20)
            energyLbl.BackgroundTransparency = 1
            energyLbl.Text = "Energy: N/A"
            energyLbl.TextColor3 = Color3.fromRGB(90, 160, 255)
            energyLbl.Font = Enum.Font.GothamBold
            energyLbl.TextSize = 11
            energyLbl.TextXAlignment = Enum.TextXAlignment.Left
            energyLbl.LayoutOrder = 2
            energyLbl.Parent = charInfoPanelFrame

            local levelLbl = Instance.new("TextLabel")
            levelLbl.Name = "LevelLabel"
            levelLbl.Size = UDim2.new(1, 0, 0, 20)
            levelLbl.BackgroundTransparency = 1
            levelLbl.Text = "Level: N/A"
            levelLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
            levelLbl.Font = Enum.Font.GothamBold
            levelLbl.TextSize = 11
            levelLbl.TextXAlignment = Enum.TextXAlignment.Left
            levelLbl.LayoutOrder = 3
            levelLbl.Parent = charInfoPanelFrame

            local function ReadEnergyFromUI()
                local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                if not pGui then return nil end

                local mainGui = pGui:FindFirstChild("Main")
                if mainGui then
                    local energyBar = mainGui:FindFirstChild("Energy", true)
                    if energyBar then
                        if energyBar:IsA("TextLabel") and energyBar.Text ~= "" and energyBar.Text:find("%d") then
                            return energyBar.Text
                        end
                        local subLbl = energyBar:FindFirstChildWhichIsA("TextLabel", true)
                        if subLbl and subLbl.Text ~= "" and subLbl.Text:find("%d") then
                            return subLbl.Text
                        end
                    end
                end

                for _, desc in ipairs(pGui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name:lower():find("energy") and desc.Text ~= "" and desc.Text:find("%d") then
                        return desc.Text
                    end
                end

                return nil
            end

            charInfoConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hpLbl.Text = "HP: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    else
                        hpLbl.Text = "HP: -- / --"
                    end

                    local uiEnergy = ReadEnergyFromUI()
                    if uiEnergy then
                        energyLbl.Text = "Energy: " .. uiEnergy
                    else
                        energyLbl.Text = "Energy: N/A"
                    end

                    local dataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("leaderstats")
                    local lvlVal = dataFolder and (dataFolder:FindFirstChild("Level") or dataFolder:FindFirstChild("Lv"))
                    if lvlVal and lvlVal:IsA("ValueBase") then
                        levelLbl.Text = "Level: " .. tostring(lvlVal.Value)
                    else
                        levelLbl.Text = "Level: N/A"
                    end
                end)
            end)
        else
            CleanupCharInfoPanel()
        end
    end)

    api.CreateToggle(api.MainTab, "Haki Status Display", false, 33, function(state)
        if state then
            CleanupHakiDisplay()

            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local targetParent = playerGui and (playerGui:FindFirstChild("YARHM_Gui") or playerGui) or LocalPlayer:WaitForChild("PlayerGui")

            hakiDisplayFrame = Instance.new("Frame")
            hakiDisplayFrame.Name = "YARHM_HakiDisplay"
            hakiDisplayFrame.Size = UDim2.new(0, 165, 0, 56)
            hakiDisplayFrame.Position = UDim2.new(1, -175, 0.62, 0)
            hakiDisplayFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            hakiDisplayFrame.BorderSizePixel = 0
            hakiDisplayFrame.Parent = targetParent

            local hCorner = Instance.new("UICorner")
            hCorner.CornerRadius = UDim.new(0, 8)
            hCorner.Parent = hakiDisplayFrame

            local hStroke = Instance.new("UIStroke")
            hStroke.Thickness = 1.2
            hStroke.Color = Color3.fromRGB(45, 45, 58)
            hStroke.Parent = hakiDisplayFrame

            local layout = Instance.new("UIListLayout")
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            layout.Parent = hakiDisplayFrame

            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 10)
            pad.PaddingRight = UDim.new(0, 10)
            pad.Parent = hakiDisplayFrame

            local busoLbl = Instance.new("TextLabel")
            busoLbl.Name = "BusoLabel"
            busoLbl.Size = UDim2.new(1, 0, 0, 20)
            busoLbl.BackgroundTransparency = 1
            busoLbl.Text = "Buso: Unknown"
            busoLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
            busoLbl.Font = Enum.Font.GothamBold
            busoLbl.TextSize = 11
            busoLbl.TextXAlignment = Enum.TextXAlignment.Left
            busoLbl.LayoutOrder = 1
            busoLbl.Parent = hakiDisplayFrame

            local kenLbl = Instance.new("TextLabel")
            kenLbl.Name = "KenLabel"
            kenLbl.Size = UDim2.new(1, 0, 0, 20)
            kenLbl.BackgroundTransparency = 1
            kenLbl.Text = "Ken: Unknown"
            kenLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
            kenLbl.Font = Enum.Font.GothamBold
            kenLbl.TextSize = 11
            kenLbl.TextXAlignment = Enum.TextXAlignment.Left
            kenLbl.LayoutOrder = 2
            kenLbl.Parent = hakiDisplayFrame

            hakiDisplayConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local data = LocalPlayer:FindFirstChild("Data")
                    local busoVal = data and data:FindFirstChild("Buso")
                    local kenVal = data and data:FindFirstChild("Ken")

                    if busoVal and busoVal:IsA("ValueBase") then
                        local val = busoVal.Value
                        local textStr = tostring(val)
                        if typeof(val) == "boolean" then
                            textStr = val and "Active" or "Inactive"
                        end
                        busoLbl.Text = "Buso: " .. textStr
                        if textStr == "Active" or textStr == "true" or (tonumber(textStr) and tonumber(textStr) > 0) then
                            busoLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                        else
                            busoLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
                        end
                    else
                        busoLbl.Text = "Buso: Unknown"
                        busoLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
                    end

                    if kenVal and kenVal:IsA("ValueBase") then
                        local val = kenVal.Value
                        local textStr = tostring(val)
                        if typeof(val) == "boolean" then
                            textStr = val and "Active" or "Inactive"
                        end
                        kenLbl.Text = "Ken: " .. textStr
                        if textStr == "Active" or textStr == "true" or (tonumber(textStr) and tonumber(textStr) > 0) then
                            kenLbl.TextColor3 = Color3.fromRGB(80, 200, 255)
                        else
                            kenLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
                        end
                    else
                        kenLbl.Text = "Ken: Unknown"
                        kenLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
                    end
                end)
            end)
        else
            CleanupHakiDisplay()
        end
    end)

    api.CreateToggle(api.MainTab, "Sea Event Tracker", false, 34, function(state)
        if state then
            CleanupSeaEventTracker()

            local function IsSeaEvent(item)
                if not (item:IsA("Model") or item:IsA("Folder") or item:IsA("BasePart")) then return false end
                if IsPlayerOwned(item) then return false end

                local name = item.Name:lower()
                local isNamedSeaEvent = name:find("sea beast") or name:find("seabeast") or name:find("sea_beast")
                    or name:find("terror shark") or name:find("terrorshark")
                    or name:find("ghost ship") or name:find("ghostship")
                    or name:find("pirate brigade") or name:find("piratebrigade")

                if not isNamedSeaEvent then return false end

                local hum = item:FindFirstChildOfClass("Humanoid") or item:FindFirstChildWhichIsA("Humanoid", true)
                if not hum or hum.MaxHealth < 50000 or hum.Health <= 0 then
                    return false
                end

                return true
            end

            local function ProcessSeaEvent(item)
                if not IsSeaEvent(item) then return false end

                local targetPart = (item:IsA("BasePart") and item) or item:FindFirstChild("HumanoidRootPart") or item:FindFirstChild("Root") or item:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    activeSeaEvents[item] = targetPart

                    local bbg = seaEventGuis[item]
                    if not bbg or not bbg.Parent then
                        bbg = Instance.new("BillboardGui")
                        bbg.Name = "YARHM_SeaEventTag"
                        bbg.AlwaysOnTop = true
                        bbg.Size = UDim2.new(0, 160, 0, 38)
                        bbg.StudsOffset = Vector3.new(0, 4, 0)
                        bbg.Adornee = targetPart

                        local lbl = Instance.new("TextLabel")
                        lbl.Name = "EventLabel"
                        lbl.Size = UDim2.new(1, 0, 0.5, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = "[EVENT] " .. item.Name
                        lbl.TextColor3 = Color3.fromRGB(0, 255, 220)
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 12
                        lbl.TextStrokeTransparency = 0
                        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        lbl.Parent = bbg

                        local distLbl = Instance.new("TextLabel")
                        distLbl.Name = "DistLabel"
                        distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                        distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                        distLbl.BackgroundTransparency = 1
                        distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        distLbl.Font = Enum.Font.GothamMedium
                        distLbl.TextSize = 11
                        distLbl.TextStrokeTransparency = 0
                        distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        distLbl.Parent = bbg

                        bbg.Parent = targetPart
                        seaEventGuis[item] = bbg
                    end
                    return true
                end
                return false
            end

            local function ScanContainer(container)
                if not container then return end
                for _, child in ipairs(container:GetChildren()) do
                    ProcessSeaEvent(child)
                    if child:IsA("Model") or child:IsA("Folder") then
                        for _, sub in ipairs(child:GetChildren()) do
                            ProcessSeaEvent(sub)
                        end
                    end
                end
            end

            ScanContainer(workspace)
            ScanContainer(workspace:FindFirstChild("Sea"))
            ScanContainer(workspace:FindFirstChild("Events"))

            seaEventAddedConn = workspace.DescendantAdded:Connect(function(child)
                task.wait(0.1)
                pcall(function()
                    ProcessSeaEvent(child)
                    local parent = child.Parent
                    if parent and parent ~= workspace then
                        ProcessSeaEvent(parent)
                    end
                end)
            end)

            seaEventConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    for item, targetPart in pairs(activeSeaEvents) do
                        local hum = item:FindFirstChildOfClass("Humanoid") or item:FindFirstChildWhichIsA("Humanoid", true)
                        if not item.Parent or not targetPart.Parent or not hum or hum.Health <= 0 or IsPlayerOwned(item) then
                            local gui = seaEventGuis[item]
                            if gui and gui.Parent then
                                gui:Destroy()
                            end
                            seaEventGuis[item] = nil
                            activeSeaEvents[item] = nil
                        else
                            local bbg = seaEventGuis[item]
                            if bbg and myRoot then
                                local distLbl = bbg:FindFirstChild("DistLabel")
                                if distLbl then
                                    local dist = math.floor((myRoot.Position - targetPart.Position).Magnitude)
                                    distLbl.Text = tostring(dist) .. "m"
                                end
                            end
                        end
                    end
                end)
            end)
        else
            CleanupSeaEventTracker()
        end
    end)

    local islands = {
        {"Pirate Starter", Vector3.new(1093, 17, 1426)},
        {"Marine Starter", Vector3.new(-2608, 17, 2049)},
        {"Jungle", Vector3.new(-1604, 37, 154)},
        {"Pirate Village", Vector3.new(-1147, 5, 3828)},
        {"Desert", Vector3.new(944, 7, 4373)},
        {"Middle Town", Vector3.new(-655, 8, 1582)},
        {"Frozen Village", Vector3.new(1143, 6, -1157)},
        {"Marine Fortress", Vector3.new(-4800, 21, 4360)},
        {"Skylands", Vector3.new(-4839, 718, -2620)},
        {"Prison", Vector3.new(4875, 6, 735)},
        {"Colosseum", Vector3.new(-1427, 8, -2982)},
        {"Magma Village", Vector3.new(-5245, 9, 8566)},
        {"Underwater City", Vector3.new(61163, 19, 1569)},
        {"Fountain City", Vector3.new(5127, 60, 4105)}
    }

    local islandsVisible = false

    local function SetIslandsVisibility(visible)
        for _, btn in ipairs(islandButtons) do
            btn.Visible = visible
        end
    end

    local currentIslandOrder = 35
    for _, island in ipairs(islands) do
        local name = island[1]
        local pos = island[2]
        local btn = api.CreateButton(api.MainTab, "TP: " .. name, currentIslandOrder, function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            end
        end)
        btn.Visible = false
        table.insert(islandButtons, btn)
        currentIslandOrder = currentIslandOrder + 1
    end
end

if passedApi then
    InitExtension(passedApi)
end

return function(api)
    InitExtension(api)
end
