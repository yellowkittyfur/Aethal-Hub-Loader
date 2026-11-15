-- ============================================================
-- AETHEL HUB — Arcade Basketball + Basketball Legends + Hoopz + Football Fusion 3 + Blade Ball + Murder Mystery 2
-- ============================================================

local _print, _warn = print, warn
print = function() end
warn = function() end

local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
Airflow:LoadFont({Name = "ValleySans"})

Airflow.Themes.AethelDusk = {
    Background  = Color3.fromRGB(0,   0,   0),
    Surface     = Color3.fromRGB(0,   0,   0),
    Surface2    = Color3.fromRGB(6,   6,   6),
    Surface3    = Color3.fromRGB(12,  12,  12),
    Stroke      = Color3.fromRGB(28,  28,  28),
    StrokeHover = Color3.fromRGB(60,  60,  60),
    Accent      = Color3.fromRGB(235, 235, 235),
    AccentDark  = Color3.fromRGB(0,   0,   0),
    Text        = Color3.fromRGB(240, 240, 240),
    Muted       = Color3.fromRGB(130, 130, 130),
    Glow        = Color3.fromRGB(0,   0,   0),
    Warning     = Color3.fromRGB(240, 176, 108),
    Success     = Color3.fromRGB(150, 220, 170),
    Error       = Color3.fromRGB(240, 120, 120),
}

Airflow.Assets.Logo = "rbxassetid://78202721367770"

-- ============================================================
-- GAME ID WHITELIST
-- ============================================================
local ARCADE_IDS = {
    [134558434771720] = true,
    [130736793665498] = true,
    [92216849541624]  = true,
    [95439417741900]  = true,
}

local BL_IDS = {
    [14259168147]    = true,
    [14386691987]    = true,
    [71832465156084] = true,
    [17652855195]    = true,
}

local PRACTICAL_IDS = {
    [80681221431821] = true,
    [118669925076970] = true,
    [119587547774646] = true,
}

-- Universe (game-wide) IDs: covers every place inside the game (gym, plaza, park, rec...).
-- Fill this in once and the PlaceId list above is no longer needed.
local PRACTICAL_UNIVERSES = {
    [7529591378] = true,
}

local HOOPZ_IDS = {
    [6229116934] = true,
}

-- Football Fusion 3 (main place + practice place)
local FF3_IDS = {
    [82866880824588] = true,
    [81310542478972] = true,
}

-- Blade Ball
local BB_IDS = {
    [16044264830] = true,
}
local BB_UNIVERSES = {
    [4777817887] = true,
}

-- Murder Mystery 2 (universe ID covers every place in the game)
local MM2_UNIVERSES = {
    [66654135] = true,
}

local isHoopz = HOOPZ_IDS[game.PlaceId] == true
local isFF3   = FF3_IDS[game.PlaceId] == true
local isBladeBall = BB_IDS[game.PlaceId] == true or BB_UNIVERSES[game.GameId] == true
local isArcade = ARCADE_IDS[game.PlaceId] == true
local isPractical = PRACTICAL_IDS[game.PlaceId] == true or PRACTICAL_UNIVERSES[game.GameId] == true
local isBL     = BL_IDS[game.PlaceId] == true
local isMM2    = MM2_UNIVERSES[game.GameId] == true

-- ============================================================
-- SHARED THEME
-- ============================================================


-- ============================================================
-- SHARED SERVICES
-- ============================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInput        = game:GetService("VirtualInputManager")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local isMobile    = UserInputService.TouchEnabled

-- ============================================================
-- SHARED HVH ENGINE (HipHeight + Swim + Speed + InfJump)
-- ============================================================
local HVH = {
    active = false,
    conn = nil,
    swimEngaged = false,
    infJumpState = {
        conn = nil,
        charBind = nil,
    },
    cfg = nil,
}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char,
        char:FindFirstChild("Humanoid"),
        char:FindFirstChild("HumanoidRootPart")
end

local function infJumpDisconnect()
    local st = HVH.infJumpState
    if st.conn then st.conn:Disconnect(); st.conn = nil end
    if st.charBind then st.charBind:Disconnect(); st.charBind = nil end
end

-- One extra jump per key press (no continuous lift while Space is held).
local function infJumpDo()
    local cfg = HVH.cfg
    if not cfg or not cfg.InfiniteJump.Enabled then return end
    local _, hum, hrp = getChar()
    if not hum or not hrp then return end
    local st = hum:GetState()
    if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then return end
    local base = hum.UseJumpPower and hum.JumpPower or math.sqrt(2 * workspace.Gravity * hum.JumpHeight)
    local v = hrp.AssemblyLinearVelocity
    hrp.AssemblyLinearVelocity = Vector3.new(v.X, base * (cfg.InfiniteJump.Power or 1), v.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function infJumpConnect()
    infJumpDisconnect()
    local st = HVH.infJumpState
    if isMobile then
        st.conn = UserInputService.JumpRequest:Connect(infJumpDo)
    else
        st.conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
                infJumpDo()
            end
        end)
    end
end

local function hvhStart()
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if not HVH.cfg then return end
    infJumpConnect()

    HVH.active = true
    HVH.swimEngaged = false

    HVH.conn = RunService.Heartbeat:Connect(function()
        local cfg = HVH.cfg
        if not cfg then return end

        local char, hum, hrp = getChar()

        if cfg.HipHeight.Enabled and hum then
            if hum.HipHeight ~= cfg.HipHeight.Value then
                hum.HipHeight = cfg.HipHeight.Value
            end
        end

        if not hum then return end

        if cfg.Swim.Enabled then
            if hum.FloorMaterial ~= Enum.Material.Air then
                HVH.swimEngaged = false
            else
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Swimming then
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    if not HVH.swimEngaged and hrp then
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                        HVH.swimEngaged = true
                    end
                end
                if hrp then
                    local v = hrp.AssemblyLinearVelocity
                    local cap = 20 * (cfg.Swim.Power or 1)
                    if v.Y > cap then
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, cap, v.Z)
                    end
                end
            end
        else
            HVH.swimEngaged = false
        end

        if cfg.Speed.Enabled and hrp and hum.MoveDirection.Magnitude > 0.05 then
            local mult = cfg.Speed.Multiplier or 1.35
            local targetVel = hum.MoveDirection.Unit * (16 * mult)
            local y = hrp.AssemblyLinearVelocity.Y
            hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, y, targetVel.Z)
        end
    end)
end

local function hvhStop()
    HVH.active = false
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    infJumpDisconnect()
    HVH.swimEngaged = false
end

local function hvhResetAll()
    local cfg = HVH.cfg
    if not cfg then return end
    cfg.HipHeight.Enabled = false
    cfg.Swim.Enabled = false
    cfg.InfiniteJump.Enabled = false
    cfg.Speed.Enabled = false
    local char, hum = getChar()
    if hum then
        hum.HipHeight = cfg.HipHeight.Default
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

local function buildHVHTab(tab, cfg)
    tab:CreateSection("HipHeight")
    tab:CreateToggle({
        Name = "HipHeight changer",
        Desc = "Overrides your Humanoid.HipHeight each frame.",
        Flag = "hvh_hipheight",
        CurrentValue = cfg.HipHeight.Enabled,
        Callback = function(v) cfg.HipHeight.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "HipHeight value",
        Range = { -5, 20 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = cfg.HipHeight.Value, Flag = "hvh_hipheight_val",
        Callback = function(v)
            cfg.HipHeight.Value = v
            local _, hum = getChar()
            if hum and cfg.HipHeight.Enabled then hum.HipHeight = v end
        end,
    })

    tab:CreateSection("Swim")
    tab:CreateToggle({
        Name = "Swim",
        Desc = "Forces swimming while airborne. Velocity is clamped to prevent launch.",
        Flag = "hvh_swim",
        CurrentValue = cfg.Swim.Enabled,
        Callback = function(v) cfg.Swim.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Swim power",
        Desc = "Caps upward velocity while swimming (lower = less launch).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.Swim.Power, Flag = "hvh_swim_power",
        Callback = function(v) cfg.Swim.Power = v end,
    })

    tab:CreateSection("Speed")
    tab:CreateToggle({
        Name = "Speed boost",
        Flag = "hvh_ws",
        CurrentValue = cfg.Speed.Enabled,
        Callback = function(v) cfg.Speed.Enabled = v end,
    })
    tab:CreateKeybind({
        Name = "Speed keybind",
        Flag = "hvh_ws_key",
        CurrentValue = cfg.Speed.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then cfg.Speed.Keybind = key end
        end,
    })
    tab:CreateSlider({
        Name = "Speed multiplier",
        Range = { 1, 3 }, Increment = 0.05,
        CurrentValue = cfg.Speed.Multiplier, Flag = "hvh_ws_val",
        Callback = function(v) cfg.Speed.Multiplier = v end,
    })

    tab:CreateSection("Infinite Jump")
    tab:CreateToggle({
        Name = "Infinite Jump",
        Desc = "Hold space to keep jumping (yields jump cooldown).",
        Flag = "hvh_infjump",
        CurrentValue = cfg.InfiniteJump.Enabled,
        Callback = function(v) cfg.InfiniteJump.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Infinite Jump power",
        Desc = "Caps upward velocity after re-jumping.",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.InfiniteJump.Power, Flag = "hvh_infjump_power",
        Callback = function(v) cfg.InfiniteJump.Power = v end,
    })
end

-- ============================================================
-- BRANCH: ARCADE BASKETBALL
-- ============================================================
if isArcade then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        AntiContest = {
            Enabled = false,
            Keybind = Enum.KeyCode.E,
            Height = 25,
        },
        BallSize = {
            Enabled = false,
            Size = 6,
            Transparency = 0.5,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Events = ReplicatedStorage:FindFirstChild("Events")
            ShootRemote = Events and Events:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        local ok = pcall(function()
            remote:FireServer(true, 100, false)
        end)
        pcall(function()
            remote:FireServer(false, -1, true)
        end)
        return ok
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local ballResizeConn = nil
    local trackedBalls = {}
    local origData     = {}

    local function isBallPart(inst)
        if not inst:IsA("BasePart") then return false end
        return string.lower(inst.Name):find("ball", 1, true) ~= nil
    end

    local function addTrackedBall(inst)
        if not isBallPart(inst) or trackedBalls[inst] then return end
        trackedBalls[inst] = true
        origData[inst] = { Size = inst.Size, Transparency = inst.Transparency }
        if s.BallSize.Enabled then
            local size = tonumber(s.BallSize.Size) or 6
            local trans = tonumber(s.BallSize.Transparency) or 0.5
            pcall(function()
                inst.Size = Vector3.new(size, size, size)
                inst.Transparency = trans
            end)
        end
    end

    local function removeTrackedBall(inst)
        trackedBalls[inst] = nil
        origData[inst] = nil
    end

    local function applyBallSize()
        local size = tonumber(s.BallSize.Size) or 6
        local trans = tonumber(s.BallSize.Transparency) or 0.5
        for part in pairs(trackedBalls) do
            if part.Parent then
                pcall(function()
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = trans
                end)
            else
                removeTrackedBall(part)
            end
        end
    end

    local function restoreBallSize()
        for part, data in pairs(origData) do
            if part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                end)
            end
        end
        table.clear(origData)
        table.clear(trackedBalls)
    end

    local ballAddedConn, ballRemovedConn = nil, nil
    local function enableBallResizer()
        for _, inst in ipairs(workspace:GetDescendants()) do addTrackedBall(inst) end
        ballAddedConn = workspace.DescendantAdded:Connect(function(inst)
            if isBallPart(inst) then
                task.defer(function() addTrackedBall(inst) end)
            end
        end)
        ballRemovedConn = workspace.DescendantRemoving:Connect(function(inst)
            if isBallPart(inst) then removeTrackedBall(inst) end
        end)
        applyBallSize()
        if ballResizeConn then ballResizeConn:Disconnect() end
        ballResizeConn = RunService.Heartbeat:Connect(function()
            if s.BallSize.Enabled then applyBallSize() end
        end)
        Track(ballResizeConn)
    end

    local function disableBallResizer()
        if ballAddedConn then ballAddedConn:Disconnect(); ballAddedConn = nil end
        if ballRemovedConn then ballRemovedConn:Disconnect(); ballRemovedConn = nil end
        if ballResizeConn then ballResizeConn:Disconnect(); ballResizeConn = nil end
        restoreBallSize()
    end

    local antiContestLock = false
    local function doAntiContest()
        if antiContestLock then return end
        antiContestLock = true
        task.delay(0.1, function() antiContestLock = false end)
        local _, _, hrp = getChar()
        if not hrp then return end
        local height = tonumber(s.AntiContest.Height) or 25
        hrp.CFrame = hrp.CFrame + Vector3.new(0, height, 0)
    end

    local Window = Airflow:CreateWindow({Name = "Aethel Hub", LoadingSubtitle = "Aethel Hub basketball suite", Theme = "AethelDusk", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "AethelHub", FileName = "AethelHub"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Main", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires Events.Shoot with the perfect-shot sequence.",
        Flag = "ab_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "ab_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "ab_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    CombatTab:CreateSection("Anti Contest")
    CombatTab:CreateToggle({
        Name = "Anti Contest",
        Desc = "Press E to teleport straight up (dodges contests).",
        Flag = "ab_ac",
        CurrentValue = s.AntiContest.Enabled,
        Callback = function(v) s.AntiContest.Enabled = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Anti Contest keybind",
        Desc = "Press this key to jump straight up.",
        Flag = "ab_ac_key",
        CurrentValue = s.AntiContest.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.AntiContest.Keybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Anti Contest height",
        Range = { 1, 25 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.AntiContest.Height, Flag = "ab_ac_h",
        Callback = function(v) s.AntiContest.Height = v end,
    })

    BallTab:CreateSection("Ball Resizer")
    BallTab:CreateToggle({
        Name = "Ball Resizer",
        Desc = "Scales every ball part and sets its transparency to 0.5.",
        Flag = "ab_ballsize",
        CurrentValue = s.BallSize.Enabled,
        Callback = function(v)
            s.BallSize.Enabled = v
            if v then enableBallResizer() else disableBallResizer() end
        end,
    })
    BallTab:CreateSlider({
        Name = "Ball size",
        Range = { 1, 12 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.BallSize.Size, Flag = "ab_ballsize_val",
        Callback = function(v)
            s.BallSize.Size = v
            if s.BallSize.Enabled then applyBallSize() end
        end,
    })

    buildHVHTab(HVHTab, s.HVH)

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] then return end
            if not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local hvhCfg = s.HVH

        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            if s.AntiContest.Enabled then
                local acBind = s.AntiContest.Keybind
                local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
                if input.KeyCode == acKey then doAntiContest() end
            end
            return
        end

        local acBind = s.AntiContest.Keybind
        local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
        if input.KeyCode == acKey and s.AntiContest.Enabled then
            doAntiContest(); return
        end

        local speedBind = hvhCfg.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            hvhCfg.Speed.Enabled = not hvhCfg.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableBallResizer)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: BASKETBALL LEGENDS
-- ============================================================
elseif isBL then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnJump = false,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        Mag = {
            Enabled = false,
            BallName = "Ball",
            Reach = 20,
            Keybind = Enum.KeyCode.L,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Packages = ReplicatedStorage:FindFirstChild("Packages")
            local Knit = Packages and Packages:FindFirstChild("Knit")
            local Services = Knit and Knit:FindFirstChild("Services")
            local ControlService = Services and Services:FindFirstChild("ControlService")
            local RE = ControlService and ControlService:FindFirstChild("RE")
            ShootRemote = RE and RE:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        return pcall(function() remote:FireServer(1) end)
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local magConnection = nil
    local magRefreshThread = nil
    local magCache = {}

    local function rebuildMagCache()
        table.clear(magCache)
        local targetName = s.Mag.BallName
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Name == targetName then
                if inst:FindFirstChildWhichIsA("TouchTransmitter")
                    or inst:FindFirstChild("TouchInterest") then
                    magCache[#magCache + 1] = inst
                end
            end
        end
    end

    local function magTick()
        if not s.Mag.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        if character:FindFirstChild("Basketball") then return end
        local reach = tonumber(s.Mag.Reach) or 20
        local reachSq = reach * reach
        local origin = touchPart.Position
        for i = #magCache, 1, -1 do
            local part = magCache[i]
            if not part or not part.Parent then
                table.remove(magCache, i)
            else
                local d = origin - part.Position
                if (d.X*d.X + d.Y*d.Y + d.Z*d.Z) <= reachSq then
                    pcall(function()
                        firetouchinterest(touchPart, part, 0)
                        firetouchinterest(touchPart, part, 1)
                    end)
                    if not part.Anchored then
                        part.AssemblyLinearVelocity = (touchPart.Position - part.Position) * 30
                    end
                end
            end
        end
    end

    local function enableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        rebuildMagCache()
        magRefreshThread = task.spawn(function()
            while s.Mag.Enabled do
                task.wait(0.5)
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end)
        magConnection = RunService.Heartbeat:Connect(function() pcall(magTick) end)
        Track(magConnection)
    end

    local function disableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        table.clear(magCache)
    end

    local Window = Airflow:CreateWindow({Name = "Aethel Hub", LoadingSubtitle = "Aethel Hub basketball suite", Theme = "AethelDusk", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "AethelHub", FileName = "AethelHub"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Main", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires ControlService.RE.Shoot with argument 1 (perfect shot).",
        Flag = "bl_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "bl_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Jump",
        Desc = "Fires the remote automatically after you jump-shot.",
        Flag = "bl_autogreen_jump",
        CurrentValue = s.Shooting.AutoGreenOnJump,
        Callback = function(v) s.Shooting.AutoGreenOnJump = v end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "bl_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    BallTab:CreateSection("Mag")
    BallTab:CreateToggle({
        Name = "Mag",
        Desc = "Fast cached magnet. Auto firetouchinterest on nearby balls.",
        Flag = "bl_mag",
        CurrentValue = s.Mag.Enabled,
        Callback = function(v)
            s.Mag.Enabled = v
            if v then enableMag() else disableMag() end
        end,
    })
    BallTab:CreateKeybind({
        Name = "Mag keybind",
        Desc = "Press this key to toggle Mag on/off.",
        Flag = "bl_mag_key",
        CurrentValue = s.Mag.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Mag.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Ball name",
        Desc = "Name of the part to magnet (default: Ball).",
        Placeholder = "Ball",
        CurrentValue = s.Mag.BallName,
        Flag = "bl_mag_name",
        Callback = function(text)
            if text ~= "" then
                s.Mag.BallName = text
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach (studs)",
        Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.Mag.Reach, Flag = "bl_mag_reach",
        Callback = function(v) s.Mag.Reach = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    local function setupAutoGreenChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        Track(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnJump then return end
            if not char:FindFirstChild("Basketball") then return end
            fireAutoGreenSafe()
        end))
    end
    if LocalPlayer.Character then setupAutoGreenChar(LocalPlayer.Character) end
    Track(LocalPlayer.CharacterAdded:Connect(setupAutoGreenChar))

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] or not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            return
        end

        local magBind = s.Mag.Keybind
        local magKey = (type(magBind) == "string") and Enum.KeyCode[magBind] or magBind
        if input.KeyCode == magKey then
            s.Mag.Enabled = not s.Mag.Enabled
            if s.Mag.Enabled then enableMag() else disableMag() end
            return
        end

        local speedBind = s.HVH.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableMag)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: PRACTICAL BASKETBALL
-- ============================================================
elseif isPractical then
    -- // Config
    local Aural = {
        Shooting = {
            PerfectTiming = true,
            ReleasePoint  = 97,
        },
        Dribbling = {
            DribbleGlide = false,
            GlideSpeed   = 25,
        },
        Defense = {
            AutoBlock       = false,
            BlockRange      = 12,
            BlockDelay      = 150,
            BlockTeamCheck  = true,
            AutoGuard       = false,
            GuardSprint     = false,
            TeamCheck       = true,
            BallHandlerOnly = true,
            GuardDistance   = 4,
            GuardStrength   = 70,
            GuardRange      = 45,
        },
        Player = {
            CframeSpeed      = false,
            CframeSpeedValue = 8,
            AutoSprint       = false,
            InfiniteStamina  = false,
        },
        Effects = {
            GoalEffect     = false,
            GoalEffectName = "Fire",
            IncludeTrail   = true,
        },
    }

    -- // Shared state
    local Running     = true
    local Connections = {}
    local Characters  = nil
    local Remotes     = {}
    local Hoops       = {}

    local FireServer = Instance.new("RemoteEvent").FireServer
    local function Fire(Remote, ...)
        if Remote then FireServer(Remote, ...) end
    end

    local function Connect(Signal, Callback)
        local C = Signal:Connect(Callback)
        table.insert(Connections, C)
        return C
    end

    -- // Helpers
    local function Flat(v) return Vector3.new(v.X, 0, v.Z) end

    local function GetCharacter()
        return Characters and LocalPlayer and Characters:FindFirstChild(LocalPlayer.Name)
    end

    local function GetRoot(m) return m and m:FindFirstChild("HumanoidRootPart") end

    local function GetProxy()
        local P = workspace:FindFirstChild("ProxyCharacter")
        if P and P:FindFirstChild("MovementVelocity") then
            return P, P.MovementVelocity, P:FindFirstChild("MovementGyro")
        end
        return nil
    end

    local function HasBall(Model)
        if not Model then return false end
        if Model:GetAttribute("Basketball") then return true end
        local Root = Model:FindFirstChild("HumanoidRootPart")
        local Weld = Root and Root:FindFirstChild("Basketball")
        return Weld ~= nil and Weld:IsA("Motor6D") and Weld.Part1 ~= nil
    end

    local function IsOpponent(Model, Mine, TeamCheck)
        if not TeamCheck then return true end
        local MyTeam = Mine:GetAttribute("Team")
        return MyTeam == nil or MyTeam == 0 or Model:GetAttribute("Team") ~= MyTeam
    end

    local function GetOthers(Mine)
        local List = {}
        if not Characters then return List end
        for _, Model in Characters:GetChildren() do
            local Root = Model ~= Mine and Model.Name ~= "InvisCharacter" and GetRoot(Model)
            if Root then table.insert(List, { Model = Model, Root = Root }) end
        end
        return List
    end

    local function GetGoal(Model)
        local G = Model and Model:GetAttribute("Goal")
        if typeof(G) == "CFrame"  then return G.Position end
        if typeof(G) == "Vector3" then return G end
        local Root = GetRoot(Model)
        if not Root then return nil end
        local Closest, CD = nil, math.huge
        for Hoop in Hoops do
            if Hoop.Parent then
                local D = (Hoop.Position - Root.Position).Magnitude
                if D < CD then Closest, CD = Hoop.Position, D end
            else Hoops[Hoop] = nil end
        end
        return Closest
    end

    local function GetMoveDirection()
        local Cam   = workspace.CurrentCamera
        local Look  = Flat(Cam.CFrame.LookVector)
        local Right = Flat(Cam.CFrame.RightVector)
        local Dir   = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir += Look  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir -= Look  end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir += Right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir -= Right end
        if Dir.Magnitude > 0.01 then return Dir.Unit end
        local Proxy = GetProxy()
        local Vel   = Proxy and Flat(Proxy.AssemblyLinearVelocity)
        if Vel and Vel.Magnitude > 2 then return Vel.Unit end
        return Vector3.zero
    end

    local MeterTypes   = { "Vertical", "Rocket", "Bat", "Funnel", "Hoop", "Roblox", "None" }
    local BlockActions = { Shooting = true, Dunking = true, ContactLayup = true }

    -- // Effect list
    local EffectAssets, EffectOptions = nil, {}
    pcall(function()
        EffectAssets = ReplicatedStorage
            :WaitForChild("Assets", 5)
            :WaitForChild("Models", 5)
            :WaitForChild("GreenEffects", 5)
        for _, E in (EffectAssets:FindFirstChild("Goal") or EffectAssets):GetChildren() do
            table.insert(EffectOptions, E.Name)
        end
        table.sort(EffectOptions)
    end)

    local ApplyEffects = function() end

    -- ═══════════════════════════════════════════════════
    --  WINDOW
    -- ═══════════════════════════════════════════════════

    local Window = Airflow:CreateWindow({
        Name              = "Aethel Hub",
        LoadingSubtitle   = "Practical Basketball",
        Theme             = "AethelDusk",
        ToggleUIKeybind   = "F5",
        ConfigurationSaving = {
            Enabled    = true,
            FolderName = "AethelHub",
            FileName   = "PracticalBasketball",
        },
    })

    local function Notify(title, content, duration)
        pcall(function() Window:Notify({ title = title, content = content, duration = duration or 4 }) end)
    end

    -- // Tabs
    local ShootingTab = Window:CreateTab({ Name = "Shooting", Icon = "crosshair" })
    local OffenseTab  = Window:CreateTab({ Name = "Offense",  Icon = "activity"  })
    local DefenseTab  = Window:CreateTab({ Name = "Defense",  Icon = "shield"    })
    local VisualsTab  = Window:CreateTab({ Name = "Visuals",  Icon = "eye"       })
    local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings"  })

    -- ── SHOOTING ──────────────────────────────────────

    ShootingTab:CreateSection("Auto Time")
    local PerfTimingToggle = ShootingTab:CreateToggle({
        Name = "Auto Time", Desc = "Releases every shot at the top of the meter",
        Flag = "PerfectTiming", CurrentValue = Aural.Shooting.PerfectTiming,
        Callback = function(v) Aural.Shooting.PerfectTiming = v end,
    })
    ShootingTab:CreateKeybind({
        Name = "Auto Time keybind", Flag = "PerfectTimingKey",
        Callback = function()
            local v = not Aural.Shooting.PerfectTiming
            pcall(function() PerfTimingToggle:Set(v) end)
            Aural.Shooting.PerfectTiming = v
        end,
    })
    ShootingTab:CreateSlider({
        Name = "Release Point", Desc = "How full the meter is when the release lands",
        Range = { 90, 100 }, Increment = 0.5, Suffix = "%",
        CurrentValue = Aural.Shooting.ReleasePoint, Flag = "ReleasePoint",
        Callback = function(v) Aural.Shooting.ReleasePoint = v end,
    })

    ShootingTab:CreateSection("Shot Meter")
    ShootingTab:CreateDropdown({
        Name = "Change Meter", Desc = "Switches your shot meter type",
        Options = MeterTypes, CurrentValue = "Vertical", Flag = "MeterType",
        Callback = function(v)
            if not v then return end
            Fire(Remotes.UpdateSetting, { "Meter" }, "Type", v)
            Notify("Meter", "Set to " .. v)
        end,
    })

    -- ── OFFENSE ───────────────────────────────────────

    OffenseTab:CreateSection("Dribble Glide")
    local GlideToggle = OffenseTab:CreateToggle({
        Name = "Glide", Desc = "Dribble moves travel further",
        Flag = "DribbleGlide", CurrentValue = Aural.Dribbling.DribbleGlide,
        Callback = function(v) Aural.Dribbling.DribbleGlide = v end,
    })
    OffenseTab:CreateKeybind({
        Name = "Glide keybind", Flag = "DribbleGlideKey",
        Callback = function()
            local v = not Aural.Dribbling.DribbleGlide
            pcall(function() GlideToggle:Set(v) end)
            Aural.Dribbling.DribbleGlide = v
        end,
    })
    OffenseTab:CreateSlider({
        Name = "Glide Speed", Desc = "Extra speed on every dribble move",
        Range = { 0, 100 }, Increment = 1, Suffix = "%",
        CurrentValue = Aural.Dribbling.GlideSpeed, Flag = "GlideSpeed",
        Callback = function(v) Aural.Dribbling.GlideSpeed = v end,
    })

    OffenseTab:CreateSection("Movement")
    local CFrameToggle = OffenseTab:CreateToggle({
        Name = "CFrame Speed", Desc = "Moves you forward each frame on top of normal movement",
        Flag = "CframeSpeed", CurrentValue = Aural.Player.CframeSpeed,
        Callback = function(v) Aural.Player.CframeSpeed = v end,
    })
    OffenseTab:CreateKeybind({
        Name = "CFrame Speed keybind", Flag = "CframeSpeedKey",
        Callback = function()
            local v = not Aural.Player.CframeSpeed
            pcall(function() CFrameToggle:Set(v) end)
            Aural.Player.CframeSpeed = v
        end,
    })
    OffenseTab:CreateSlider({
        Name = "CFrame Amount", Desc = "Extra studs added per frame while moving",
        Range = { 1, 30 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = Aural.Player.CframeSpeedValue, Flag = "CframeSpeedValue",
        Callback = function(v) Aural.Player.CframeSpeedValue = v end,
    })
    OffenseTab:CreateToggle({
        Name = "Auto Sprint", Desc = "Holds sprint automatically so you never slow down",
        Flag = "AutoSprint", CurrentValue = Aural.Player.AutoSprint,
        Callback = function(v) Aural.Player.AutoSprint = v end,
    })
    OffenseTab:CreateToggle({
        Name = "Infinite Stamina", Desc = "Stops stamina from ever running out",
        Flag = "InfiniteStamina", CurrentValue = Aural.Player.InfiniteStamina,
        Callback = function(v) Aural.Player.InfiniteStamina = v end,
    })

    -- ── DEFENSE ───────────────────────────────────────

    DefenseTab:CreateSection("Block")
    local BlockToggle = DefenseTab:CreateToggle({
        Name = "Auto Block", Desc = "Jumps at nearby shots, layups and dunks",
        Flag = "AutoBlock", CurrentValue = Aural.Defense.AutoBlock,
        Callback = function(v) Aural.Defense.AutoBlock = v end,
    })
    DefenseTab:CreateKeybind({
        Name = "Block keybind", Flag = "AutoBlockKey",
        Callback = function()
            local v = not Aural.Defense.AutoBlock
            pcall(function() BlockToggle:Set(v) end)
            Aural.Defense.AutoBlock = v
        end,
    })
    DefenseTab:CreateSlider({
        Name = "Block Range", Desc = "How far away a shot triggers the block",
        Range = { 3, 30 }, Increment = 1, Suffix = " studs",
        CurrentValue = Aural.Defense.BlockRange, Flag = "BlockRange",
        Callback = function(v) Aural.Defense.BlockRange = v end,
    })
    DefenseTab:CreateSlider({
        Name = "Block Delay", Desc = "Waits before jumping — filters pump fakes",
        Range = { 0, 500 }, Increment = 10, Suffix = "ms",
        CurrentValue = Aural.Defense.BlockDelay, Flag = "BlockDelay",
        Callback = function(v) Aural.Defense.BlockDelay = v end,
    })
    DefenseTab:CreateToggle({
        Name = "Team Check", Desc = "Never blocks a teammate",
        Flag = "BlockTeamCheck", CurrentValue = Aural.Defense.BlockTeamCheck,
        Callback = function(v) Aural.Defense.BlockTeamCheck = v end,
    })

    DefenseTab:CreateSection("Guard")
    local GuardToggle = DefenseTab:CreateToggle({
        Name = "Auto Guard", Desc = "Stays between your man and the hoop",
        Flag = "AutoGuard", CurrentValue = Aural.Defense.AutoGuard,
        Callback = function(v) Aural.Defense.AutoGuard = v end,
    })
    DefenseTab:CreateKeybind({
        Name = "Guard keybind", Flag = "AutoGuardKey",
        Callback = function()
            local v = not Aural.Defense.AutoGuard
            pcall(function() GuardToggle:Set(v) end)
            Aural.Defense.AutoGuard = v
        end,
    })
    DefenseTab:CreateToggle({
        Name = "Guard Sprint", Desc = "Sprints to keep up when your man gets ahead",
        Flag = "GuardSprint", CurrentValue = Aural.Defense.GuardSprint,
        Callback = function(v) Aural.Defense.GuardSprint = v end,
    })
    DefenseTab:CreateToggle({
        Name = "Team Check", Desc = "Never guards your own teammates",
        Flag = "GuardTeamCheck", CurrentValue = Aural.Defense.TeamCheck,
        Callback = function(v) Aural.Defense.TeamCheck = v end,
    })
    DefenseTab:CreateToggle({
        Name = "Ball Handler Only", Desc = "Only guards the player with the ball",
        Flag = "BallHandlerOnly", CurrentValue = Aural.Defense.BallHandlerOnly,
        Callback = function(v) Aural.Defense.BallHandlerOnly = v end,
    })
    DefenseTab:CreateSlider({
        Name = "Guard Distance", Desc = "How tight to play your man",
        Range = { 1, 10 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = Aural.Defense.GuardDistance, Flag = "GuardDistance",
        Callback = function(v) Aural.Defense.GuardDistance = v end,
    })
    DefenseTab:CreateSlider({
        Name = "Guard Strength", Desc = "How aggressively it corrects your position",
        Range = { 10, 100 }, Increment = 1, Suffix = "%",
        CurrentValue = Aural.Defense.GuardStrength, Flag = "GuardStrength",
        Callback = function(v) Aural.Defense.GuardStrength = v end,
    })
    DefenseTab:CreateSlider({
        Name = "Guard Range", Desc = "Max distance before guard kicks in",
        Range = { 10, 80 }, Increment = 1, Suffix = " studs",
        CurrentValue = Aural.Defense.GuardRange, Flag = "GuardRange",
        Callback = function(v) Aural.Defense.GuardRange = v end,
    })
    local GuardStatus = DefenseTab:CreateLabel("guarding: none")

    -- ── VISUALS ───────────────────────────────────────

    VisualsTab:CreateSection("Goal Effect")
    VisualsTab:CreateToggle({
        Name = "Goal Effect Changer", Desc = "Every green plays this effect at the rim",
        Flag = "GoalEffect", CurrentValue = Aural.Effects.GoalEffect,
        Callback = function(v) Aural.Effects.GoalEffect = v; ApplyEffects() end,
    })
    VisualsTab:CreateDropdown({
        Name = "Effect",
        Options = #EffectOptions > 0 and EffectOptions or { "Fire" },
        CurrentValue = Aural.Effects.GoalEffectName, Flag = "GoalEffectName",
        Callback = function(v)
            Aural.Effects.GoalEffectName = v or Aural.Effects.GoalEffectName
            ApplyEffects()
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Ball Trail Too", Desc = "Also applies the effect to the ball trail",
        Flag = "GoalEffectTrail", CurrentValue = Aural.Effects.IncludeTrail,
        Callback = function(v) Aural.Effects.IncludeTrail = v; ApplyEffects() end,
    })

    -- ── SETTINGS ──────────────────────────────────────

    SettingsTab:CreateSection("Configs")
    local ConfigName = "default"
    SettingsTab:CreateInput({
        Name = "Config name", Placeholder = "default",
        CurrentValue = "default", Flag = "ConfigName",
        Callback = function(v) ConfigName = (v ~= "") and v or "default" end,
    })
    SettingsTab:CreateButton({
        Name = "Save config",
        Callback = function()
            pcall(function() Window:SaveConfig(ConfigName) end)
            Notify("Config", "Saved: " .. ConfigName)
        end,
    })
    SettingsTab:CreateButton({
        Name = "Load config",
        Callback = function()
            pcall(function() Window:LoadConfig(ConfigName) end)
            Notify("Config", "Loaded: " .. ConfigName)
        end,
    })

    pcall(function() Window:LoadConfig() end)

    -- ═══════════════════════════════════════════════════
    --  FEATURE LOGIC
    -- ═══════════════════════════════════════════════════

    task.spawn(function()
        if not LocalPlayer then
            repeat task.wait() until Players.LocalPlayer
            LocalPlayer = Players.LocalPlayer
        end

        while game.PlaceId == 0 do task.wait() end

        local ok, RS = pcall(function()
            return ReplicatedStorage
                :WaitForChild("Aero", 30)
                :WaitForChild("AeroRemoteServices", 30)
        end)
        if not ok or not RS then
            Notify("Aethel Hub", "Remotes not found — game not supported.", 5)
            return
        end

        Characters = workspace:WaitForChild("Characters", 30)

        local function GetRemote(svc, name)
            return RS:WaitForChild(svc):WaitForChild(name)
        end

        Remotes.Shoot         = GetRemote("InputService",     "Shoot")
        Remotes.Jump          = GetRemote("InputService",     "Jump")
        Remotes.Sprint        = GetRemote("InputService",     "Sprint")
        Remotes.HoldG         = GetRemote("InputService",     "HoldG")
        Remotes.UpdateSetting = GetRemote("PlayerService",    "UpdateSetting")
        Remotes.MeterRegister = GetRemote("MeterService",     "RegisterPacket")
        Remotes.MeterUnregister = GetRemote("MeterService",   "UnregisterPacket")
        Remotes.RunGreenEffect  = GetRemote("InterfaceService", "RunGreenEffect")

        -- Hoop tracker
        local function TrackHoop(O)
            if O.Name == "Goal" and O:IsA("BasePart") and O.Parent
                and O.Parent:FindFirstChild("PaintZone") then
                Hoops[O] = true
            end
        end
        for _, O in workspace:GetDescendants() do TrackHoop(O) end
        Connect(workspace.DescendantAdded, TrackHoop)

        -- ── SHOT TRACKING + AUTO TIME ──────────────────
        do
            local MeterMaps = {
                Vertical = function(O) return (-O.Y - 0.25) / 1.25 end,
                Rocket   = function(O) return -O.Y end,
                Bat      = function(O) return -O.Y end,
                None     = function(O) return -O.Y end,
                Hoop     = function(O) return  O.Y end,
                Roblox   = function(O) return  O.X end,
            }
            local DefaultFill = 0.38

            local Shot = {
                Active   = false,
                Start    = 0,
                Meter    = "Vertical",
                Samples  = {},
                Slope    = nil,
                Released = false,
            }

            local Bound, BoundConnections = nil, {}

            local function BeginShot(MeterType)
                Shot.Active   = true
                Shot.Start    = os.clock()
                Shot.Meter    = MeterType or Shot.Meter
                Shot.Samples  = {}
                Shot.Slope    = nil
                Shot.Released = false
            end

            local function Release()
                Shot.Released = true
                Fire(Remotes.Shoot, { Shoot = false })
            end

            local function Fit()
                local N = #Shot.Samples
                local SX, SY, SXX, SXY = 0, 0, 0, 0
                for _, S in Shot.Samples do
                    local X = S[1] - Shot.Start
                    SX += X; SY += S[2]; SXX += X*X; SXY += X*S[2]
                end
                local D = N * SXX - SX * SX
                if D == 0 then return nil end
                local Slope = (N * SXY - SX * SY) / D
                return Slope, (SY - Slope * SX) / N
            end

            local function GetReleaseTime()
                local Target = Aural.Shooting.ReleasePoint / 100
                if MeterMaps[Shot.Meter] then
                    if #Shot.Samples < 3 then return nil end
                    local Slope, Intercept = Fit()
                    if not Slope or Slope < 0.5 then return nil end
                    Shot.Slope = Slope
                    return Shot.Start + (Target - Intercept) / Slope
                end
                return Shot.Start + DefaultFill * Target
            end

            local function Bind(Character)
                for _, C in BoundConnections do C:Disconnect() end
                BoundConnections = {}
                Bound = Character
                if not Character then return end

                table.insert(BoundConnections,
                    Character:GetAttributeChangedSignal("meterOffset"):Connect(function()
                        local Offset = Character:GetAttribute("meterOffset")
                        local Map    = MeterMaps[Shot.Meter]
                        if not Shot.Active or typeof(Offset) ~= "Vector2" or not Map then return end
                        if not Shot.Released then
                            table.insert(Shot.Samples, { os.clock(), Map(Offset) })
                        end
                    end))

                table.insert(BoundConnections,
                    Character:GetAttributeChangedSignal("Action"):Connect(function()
                        if Character:GetAttribute("Action") == "Shooting"
                            and (not Shot.Active or os.clock() - Shot.Start > 0.3) then
                            BeginShot(nil)
                        end
                    end))
            end

            Connect(Remotes.MeterRegister.OnClientEvent, function(Model, MeterType)
                if Model ~= Bound then return end
                if not Shot.Active or os.clock() - Shot.Start > 0.3 then
                    BeginShot(MeterType)
                else
                    Shot.Meter = MeterType or Shot.Meter
                end
            end)

            Connect(Remotes.MeterUnregister.OnClientEvent, function(Model)
                if Model == Bound then Shot.Active = false end
            end)

            Connect(RunService.Heartbeat, function()
                local Character = GetCharacter()
                if Character ~= Bound then Bind(Character) end
                if not Character then return end

                if Shot.Active and not Shot.Released and Aural.Shooting.PerfectTiming then
                    if Character:GetAttribute("ReleasedShot") == true
                        and os.clock() - Shot.Start > 0.1 then
                        Shot.Released = true
                    else
                        local RT = GetReleaseTime()
                        if (RT and os.clock() >= RT) or os.clock() - Shot.Start > 1.2 then
                            Release()
                        end
                    end
                end
                if Shot.Active and os.clock() - Shot.Start > 3 then Shot.Active = false end
            end)
        end

        -- ── AUTO BLOCK ─────────────────────────────────
        do
            local Blocked   = setmetatable({}, { __mode = "k" })
            local LastBlock = 0

            local function Jump(Toward)
                local Proxy, _, Gyro = GetProxy()
                if not Proxy then return end
                if Gyro and Toward then
                    Gyro.CFrame = CFrame.lookAt(Proxy.Position,
                        Vector3.new(Toward.X, Proxy.Position.Y, Toward.Z))
                end
                Fire(Remotes.Shoot, { Shoot = true, Input = "E", UseSpace = true })
                Fire(Remotes.Jump)
                task.delay(0.3, function() Fire(Remotes.Shoot, { Shoot = false }) end)
            end

            Connect(RunService.Heartbeat, function()
                if not Aural.Defense.AutoBlock or os.clock() - LastBlock < 0.8 then return end
                local Character = GetCharacter()
                local Root      = GetRoot(Character)
                if not Root or HasBall(Character) or Character:GetAttribute("Action") ~= "" then return end
                for _, Other in GetOthers(Character) do
                    local Action = Other.Model:GetAttribute("Action")
                    if BlockActions[Action]
                        and IsOpponent(Other.Model, Character, Aural.Defense.BlockTeamCheck)
                        and not (Blocked[Other.Model] and os.clock() - Blocked[Other.Model] < 1.5) then
                        if (Other.Root.Position - Root.Position).Magnitude <= Aural.Defense.BlockRange then
                            Blocked[Other.Model] = os.clock()
                            LastBlock = os.clock()
                            task.delay(Aural.Defense.BlockDelay / 1000, function()
                                if Running and BlockActions[Other.Model:GetAttribute("Action")]
                                    and (Other.Root.Position - Root.Position).Magnitude
                                        <= Aural.Defense.BlockRange + 4 then
                                    Jump(Other.Root.Position)
                                end
                            end)
                            return
                        end
                    end
                end
            end)
        end

        -- ── GUARD · GLIDE · CFRAME · STAMINA ──────────
        do
            local Guarding, Sprinting = false, false
            local LastGuard   = 0
            local ShownTarget = nil

            local function ShowTarget(Model)
                if Model ~= ShownTarget then
                    ShownTarget = Model
                    pcall(function()
                        GuardStatus:Set("guarding: " .. (Model and Model.Name or "none"))
                    end)
                end
            end

            local function StopGuard()
                ShowTarget(nil)
                if Guarding  then Guarding  = false; Fire(Remotes.HoldG, { HoldingG = false }) end
                if Sprinting then Sprinting = false; Fire(Remotes.Sprint, false) end
            end

            local function FindGuardTarget(Character, Root)
                local Closest, CD = nil, Aural.Defense.GuardRange
                for _, Other in GetOthers(Character) do
                    if IsOpponent(Other.Model, Character, Aural.Defense.TeamCheck)
                        and (not Aural.Defense.BallHandlerOnly or HasBall(Other.Model)) then
                        local D = (Other.Root.Position - Root.Position).Magnitude
                        if D < CD then Closest, CD = Other, D end
                    end
                end
                return Closest
            end

            Connect(RunService.Stepped, function(_, DeltaTime)
                local Character = GetCharacter()
                local Root      = GetRoot(Character)
                local Proxy, Velocity, Gyro = GetProxy()
                if not Root or not Proxy then StopGuard(); return end

                local Action  = Character:GetAttribute("Action")
                local Current = Velocity.Velocity
                local CanMove = Character:GetAttribute("CanMove")

                if Aural.Player.InfiniteStamina then
                    Character:SetAttribute("Stamina", Character:GetAttribute("MaxStamina") or 100)
                end

                local Target = Aural.Defense.AutoGuard and CanMove
                    and not HasBall(Character) and FindGuardTarget(Character, Root)

                if Target then
                    local Goal   = GetGoal(Target.Model) or Root.Position
                    local ToGoal = Flat(Goal - Target.Root.Position)
                    ToGoal       = ToGoal.Magnitude > 0.01 and ToGoal.Unit or Vector3.zero
                    local Offset = Flat(Target.Root.Position
                        + ToGoal * Aural.Defense.GuardDistance - Proxy.Position)
                    local Limit  = Aural.Defense.GuardSprint and 17.35 or 14
                    local Speed  = math.min(Offset.Magnitude * Aural.Defense.GuardStrength / 10, Limit)
                    Velocity.Velocity = (Offset.Magnitude > 0.25 and Offset.Unit * Speed or Vector3.zero)
                        + Vector3.new(0, Current.Y, 0)
                    if Gyro then
                        Gyro.CFrame = CFrame.lookAt(Proxy.Position,
                            Vector3.new(Target.Root.Position.X, Proxy.Position.Y, Target.Root.Position.Z))
                    end
                    if not Guarding then Guarding = true; Fire(Remotes.HoldG, { HoldingG = true }) end
                    if Aural.Defense.GuardSprint ~= Sprinting then
                        Sprinting = Aural.Defense.GuardSprint
                        Fire(Remotes.Sprint, Sprinting)
                    end
                    ShowTarget(Target.Model)
                    LastGuard = os.clock()
                    return
                end
                if os.clock() - LastGuard > 0.4 then StopGuard() end

                if Aural.Dribbling.DribbleGlide and Action == "Dribbling" then
                    local Moving = Flat(Proxy.AssemblyLinearVelocity)
                    if Moving.Magnitude > 1 then
                        Proxy.CFrame += Moving.Unit * (Aural.Dribbling.GlideSpeed / 100 * 16) * DeltaTime
                    end
                    return
                end

                if Aural.Player.CframeSpeed and CanMove then
                    local Direction = GetMoveDirection()
                    if Direction.Magnitude > 0 then
                        Proxy.CFrame += Direction * Aural.Player.CframeSpeedValue * DeltaTime
                    end
                end
            end)

            table.insert(Connections, { Disconnect = StopGuard })
        end

        -- ── AUTO SPRINT ────────────────────────────────
        do
            local AutoSprinting = false
            local LastSprint    = 0

            Connect(RunService.Heartbeat, function()
                local Character = GetCharacter()
                if not Aural.Player.AutoSprint or not Character then
                    if AutoSprinting then AutoSprinting = false; Fire(Remotes.Sprint, false) end
                    return
                end
                local Moving = GetMoveDirection().Magnitude > 0
                if Moving and not Character:GetAttribute("Sprinting")
                    and os.clock() - LastSprint > 0.3 then
                    LastSprint = os.clock(); AutoSprinting = true; Fire(Remotes.Sprint, true)
                elseif not Moving and AutoSprinting
                    and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    AutoSprinting = false; Fire(Remotes.Sprint, false)
                end
            end)
        end

        -- ── GOAL EFFECT ────────────────────────────────
        do
            local Swapped = {}

            local function Restore()
                for i = #Swapped, 1, -1 do
                    local E = Swapped[i]; E.Copy:Destroy()
                    if E.Original then E.Original.Parent = E.Folder end
                end
                table.clear(Swapped)
            end

            local function Swap(Kind, Choice)
                if not EffectAssets then return end
                local Folder = EffectAssets:FindFirstChild(Kind)
                local Source = Folder and Folder:FindFirstChild(Choice)
                if not Source then return end
                for _, Entry in Folder:GetChildren() do
                    if Entry ~= Source then
                        local Copy = Source:Clone()
                        Copy.Name = Entry.Name; Entry.Parent = nil; Copy.Parent = Folder
                        table.insert(Swapped, { Folder = Folder, Original = Entry, Copy = Copy })
                    end
                end
            end

            ApplyEffects = function()
                Restore()
                if not Aural.Effects.GoalEffect then return end
                Swap("Goal", Aural.Effects.GoalEffectName)
                if Aural.Effects.IncludeTrail then Swap("Trail", Aural.Effects.GoalEffectName) end
            end

            Connect(Remotes.RunGreenEffect.OnClientEvent, function(_, _, _, _, Name)
                if not Aural.Effects.GoalEffect or type(Name) ~= "string" or not EffectAssets then return end
                for _, Kind in { "Goal", "Trail" } do
                    local Folder = EffectAssets:FindFirstChild(Kind)
                    local Source = Folder and Folder:FindFirstChild(Aural.Effects.GoalEffectName)
                    if Source and not Folder:FindFirstChild(Name)
                        and (Kind == "Goal" or Aural.Effects.IncludeTrail) then
                        local Copy = Source:Clone(); Copy.Name = Name; Copy.Parent = Folder
                        table.insert(Swapped, { Folder = Folder, Copy = Copy })
                    end
                end
            end)

            table.insert(Connections, { Disconnect = Restore })
        end

        Notify("Aethel Hub", "Ready. Press F5 to toggle.")
    end)

    local function practicalCleanup()
        Running = false
        for _, C in Connections do pcall(function() C:Disconnect() end) end
    end
    LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then practicalCleanup() end
    end)


-- ============================================================
-- BRANCH: HOOPZ
-- ============================================================
elseif isHoopz then
    local TweenService = game:GetService("TweenService")
    local HttpService  = game:GetService("HttpService")
    local DeviceEvent  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("deviceEvent")

    local Settings = {
        Shooting = {
            AuralEnabled = false, AuralKeybind = Enum.KeyCode.X,
            ShotYAxis = 0, ShotDelay = 0.32, EBLHop = false,
            HumanizeAim = false, HumanizeStrength = 1.2, MissChance = 0,
            RandomizeShotDelay = false, ShotDelayMin = 0.25, ShotDelayMax = 0.38,
        },
        Defending = {
            AutoGuard = false, AutoGuardButton = false, AutoGuardNearest = false,
            AutoGuardMode = "Balanced", AutoGuardRange = 33, GuardPrediction = 0.58,
            GuardKeybind = Enum.KeyCode.K,
        },
        Ball = {
            BallMags = false, BallMagRange = 15, BallMagVisualizer = false, MagnetKeybind = "M",
            BallReach = false, BallReachRange = 10, BallReachVisualizer = false, ReachKeybind = "N",
        },
        MagV2 = { Enabled = false, BallName = "Ball", Reach = 20, Keybind = Enum.KeyCode.U },
        TPWalk = { Enabled = false, Speed = 0.01, Keybind = Enum.KeyCode.P },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1 },
        },
        Misc = { AntiModerator = false, DeviceSpoofer = false, Device = "PC", MobilePanel = true },
        Visuals = {
            ShotIndicator = false, IndicatorColor = "Purple",
            CustomName = false, CustomNameText = "",
            CustomRecord = false, CustomRecordText = "",
            CustomTitle = false, CustomTitleText = "",
            HideOwnNameplate = false,
        },
        Goal = { Enabled = false, SelectedEffect = "LightRay", CurrentEffect = "LightRay" },
        CourtSpoofer = { Enabled = false, SelectedCourt = "None", CurrentCourt = "None" },
        BallChanger = { Enabled = false, SelectedBall = "ForceField", CurrentBall = "ForceField" },
        TrailSpoofer = { Enabled = false, SelectedTrail = "None", CurrentTrail = "None" },
        BallAura = { Enabled = false, SelectedAura = "None", CurrentAura = "None" },
        BodyAura = { Enabled = false, Selected = "" },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {}, fns = {} }
    local function Track(c) table.insert(Cleanup.conns, c); return c end
    local function OnCleanup(fn) table.insert(Cleanup.fns, fn) end

    local setAural, setGuard, setMagnet, setReach, setTPWalk, setMagV2
    local MobileRefresh = function() end

    local IndicatorColors = {
        Blue = Color3.fromRGB(60, 150, 255),
        Purple = Color3.fromRGB(150, 80, 220),
        Green = Color3.fromRGB(0, 255, 128),
        Red = Color3.fromRGB(255, 60, 60),
        Yellow = Color3.fromRGB(255, 220, 0),
    }

    local function hasball(char) return char and char:FindFirstChild("Basketball") ~= nil end

    local fieldGoals = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst.Name == "FieldGoal" and inst:IsA("BasePart") then
            table.insert(fieldGoals, inst)
        end
    end

    local goals = {}
    local goalsDirty = true

    local function validgoal(o)
        if not o:IsA("BasePart") then return false end
        local n = string.lower(o.Name)
        if n ~= "goal" and n ~= "goalhome" and n ~= "goalaway" then return false end
        local p = o.Parent
        for _ = 1, 5 do
            if not p then break end
            local pn = string.lower(p.Name)
            if string.find(pn, "hitbox", 1, true) or string.find(pn, "fieldgoal", 1, true) then return true end
            p = p.Parent
        end
        return false
    end

    local function rebuildGoals()
        table.clear(goals)
        for _, o in workspace:GetDescendants() do
            if validgoal(o) then table.insert(goals, o) end
        end
        goalsDirty = false
    end
    rebuildGoals()

    Track(workspace.DescendantAdded:Connect(function(o)
        if validgoal(o) then
            table.insert(goals, o)
        elseif o:IsA("BasePart") and string.find(string.lower(o.Name), "goal", 1, true) then
            goalsDirty = true
        end
    end))

    local courtPlayerCache = {}
    local function rebuildCourtCache()
        table.clear(courtPlayerCache)
        for _, inst in next, workspace:GetChildren() do
            if inst.Name == "Courts" then
                for _, court in next, inst:GetChildren() do
                    local cp = court:FindFirstChild("_CourtPlayers")
                    if cp then table.insert(courtPlayerCache, cp) end
                end
            end
        end
    end
    rebuildCourtCache()

    Track(workspace.DescendantAdded:Connect(function(o)
        if o.Name == "_CourtPlayers" then
            table.insert(courtPlayerCache, o)
        end
    end))

    local function nearestgoal(root)
        if goalsDirty then rebuildGoals() end
        local rootPos = root.Position
        local best, bestDist = nil, math.huge
        for i = #goals, 1, -1 do
            local goal = goals[i]
            if not goal or not goal.Parent then table.remove(goals, i); continue end
            local delta = goal.Position - rootPos
            local flat = delta.X * delta.X + delta.Z * delta.Z
            if flat < bestDist then best, bestDist = goal, flat end
        end
        if best then return best, math.sqrt(bestDist) end
        return nil, math.huge
    end

    local function teamOf(nm)
        if nm:find("^Home") then return "Home" end
        if nm:find("^Away") then return "Away" end
        return nil
    end

    local function getTeammates()
        local tms = {}
        for _, cp in next, courtPlayerCache do
            if not cp.Parent then continue end
            local myTeam = nil
            for _, v in next, cp:GetChildren() do
                if v:IsA("ObjectValue") and v.Value == LocalPlayer then
                    myTeam = teamOf(v.Name)
                    break
                end
            end
            if not myTeam then continue end
            for _, tm in next, cp:GetChildren() do
                if tm:IsA("ObjectValue") and typeof(tm.Value) == "Instance"
                    and tm.Value:IsA("Player") and tm.Value ~= LocalPlayer
                    and teamOf(tm.Name) == myTeam then
                    table.insert(tms, tm.Value)
                end
            end
            break
        end
        return tms
    end

    local teammatesCache = { list = nil }
    local lastTeammateRefresh = 0

    local function isTeammatePlayer(player)
        local now = os.clock()
        if now - lastTeammateRefresh > 0.5 or not teammatesCache.list then
            teammatesCache.list = getTeammates()
            lastTeammateRefresh = now
        end
        for _, tm in ipairs(teammatesCache.list) do
            if tm == player then return true end
        end
        return false
    end

    local function getClosestDribbler()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        for _, part in workspace:GetPartBoundsInRadius(root.Position, s.Defending.AutoGuardRange) do
            if part:IsA("BasePart") and part.Name == "Ball" and part.Parent:IsA("Folder") then
                local holder = part.Parent.Parent
                local holderRoot = holder and holder:FindFirstChild("HumanoidRootPart")
                if holderRoot then
                    local distance = (holderRoot.Position - root.Position).Magnitude
                    if distance < closestDistance then
                        local holderPlayer = Players:GetPlayerFromCharacter(holder)
                        if holderPlayer and not isTeammatePlayer(holderPlayer) then
                            closestDistance = distance
                            closestPlayer = holderPlayer
                        end
                    end
                end
            end
        end
        return closestPlayer
    end

    local function getClosestPlayer()
        local char, _, root = getChar()
        if not root then return nil end
        local closestPlayer, closestDistance = nil, math.huge
        local rootPos = root.Position
        local range = s.Defending.AutoGuardRange
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local c = player.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - rootPos).Magnitude
                if dist < range and dist < closestDistance and not isTeammatePlayer(player) then
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
        return closestPlayer
    end

    local function getGuardMode()
        local lowered = tostring(s.Defending.AutoGuardMode or "Balanced"):lower()
        if lowered == "reactive" then return "legit" end
        if lowered == "aggressive" then return "blatant" end
        return "prediction"
    end

    local function getGuardPosition(target)
        if not target then return nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Basketball") then return nil end
        local targetChar = target.Character
        if not targetChar then return nil end
        local targetBall = targetChar:FindFirstChild("Basketball") and targetChar.Basketball:FindFirstChild("Ball")
        if not targetBall then return nil end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar:FindFirstChild("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not targetHrp or not targetHum or not myHrp or not myHum then return nil end
        local mode = getGuardMode()
        local ballPos = targetBall.Position
        local vel = targetHrp.AssemblyLinearVelocity
        local speed = targetHum.WalkSpeed
        local moveDir = targetHum.MoveDirection
        local myPos = myHrp.Position
        local mySpeed = myHum.WalkSpeed
        local distance = (ballPos - myPos).Magnitude
        local timeToReach = distance / (mySpeed + 10)
        local predictionScale = s.Defending.GuardPrediction or 0.58
        if mode == "legit" then
            predictionScale = predictionScale * 0.7
            timeToReach = distance / (mySpeed + 12)
        elseif mode == "blatant" then
            predictionScale = predictionScale * 1.75
            timeToReach = distance / (mySpeed + 18)
        end
        local predictedMove = moveDir * speed * predictionScale + Vector3.new(vel.X, 0, vel.Z) * 0.5
        local interceptPos = targetHrp.Position + predictedMove * timeToReach
        local offsetDir = (moveDir.Magnitude > 0 and moveDir.Unit or Vector3.new(0, 0, 1)) * ((mode == "blatant") and 4 or 2)
        return Vector3.new(interceptPos.X + offsetDir.X, ballPos.Y, interceptPos.Z + offsetDir.Z)
    end

    local function getNearestGuardPosition(target)
        if not target then return nil end
        local targetChar = target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHrp or not targetHum or not myHrp then return nil end
        local moveDir = targetHum.MoveDirection
        local vel = Vector3.new(targetHrp.AssemblyLinearVelocity.X, 0, targetHrp.AssemblyLinearVelocity.Z)
        local dist = (targetHrp.Position - myHrp.Position).Magnitude
        local timeToReach = dist / (targetHum.WalkSpeed + 10)
        local predictionScale = (getGuardMode() == "blatant") and (s.Defending.GuardPrediction * 1.5) or s.Defending.GuardPrediction
        local predicted = targetHrp.Position + (moveDir * targetHum.WalkSpeed * predictionScale + vel * 0.5) * timeToReach
        local facing = (moveDir.Magnitude > 0) and moveDir.Unit or (targetHrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
        local offset = facing * ((getGuardMode() == "blatant") and 4 or 2)
        return Vector3.new(predicted.X + offset.X, targetHrp.Position.Y, predicted.Z + offset.Z)
    end

    local guardConnection = nil

    local function enableAutoGuard()
        if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
        local frameSkip = 0
        guardConnection = RunService.Stepped:Connect(function()
            if not s.Defending.AutoGuard then return end
            frameSkip += 1
            if frameSkip < 3 then return end
            frameSkip = 0
            local char, myHum = getChar()
            if not myHum or hasball(char) then return end
            local mode = getGuardMode()
            local closestDribbler = getClosestDribbler()
            if closestDribbler then
                local guardPos
                if mode == "legit" then
                    guardPos = getNearestGuardPosition(closestDribbler)
                elseif mode == "blatant" then
                    guardPos = getGuardPosition(closestDribbler)
                    if guardPos and closestDribbler.Character and closestDribbler.Character:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = closestDribbler.Character.HumanoidRootPart
                        local myRoot = char:FindFirstChild("HumanoidRootPart")
                        if myRoot and (targetRoot.Position - myRoot.Position).Magnitude < 18 then
                            guardPos = targetRoot.Position + (targetRoot.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 3
                        end
                    end
                else
                    guardPos = getGuardPosition(closestDribbler)
                end
                if guardPos then myHum:MoveTo(guardPos) end
                return
            end
            if s.Defending.AutoGuardNearest then
                local nearest = getClosestPlayer()
                if nearest then
                    local guardPos
                    if mode == "legit" then
                        guardPos = getNearestGuardPosition(nearest)
                    elseif mode == "blatant" then
                        guardPos = getNearestGuardPosition(nearest)
                        if guardPos then
                            local myRoot = char:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local targetRoot = nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart")
                                if targetRoot and (targetRoot.Position - myRoot.Position).Magnitude < 20 then
                                    guardPos = targetRoot.Position + targetRoot.CFrame.LookVector * 4
                                end
                            end
                        end
                    else
                        guardPos = getNearestGuardPosition(nearest)
                    end
                end
            end
        end)
    end
    Track(guardConnection)

    local function disableAutoGuard()
        if guardConnection then guardConnection:Disconnect(); guardConnection = nil end
    end

    local magnetHitbox, magnetConnection = nil, nil

    local function createMagnetHitbox(character)
        if magnetHitbox then magnetHitbox:Destroy(); magnetHitbox = nil end
        if character:FindFirstChild("AethelMagnet") then character.AethelMagnet:Destroy() end
        local head = character:FindFirstChild("Head")
        if not head then return end
        magnetHitbox = Instance.new("Part")
        magnetHitbox.Name = "AethelMagnet"
        magnetHitbox.Shape = Enum.PartType.Ball
        magnetHitbox.Size = Vector3.new(s.Ball.BallMagRange, s.Ball.BallMagRange, s.Ball.BallMagRange)
        magnetHitbox.Transparency = 1
        magnetHitbox.CanCollide = false
        magnetHitbox.CanQuery = false
        magnetHitbox.Massless = true
        magnetHitbox.Parent = character
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = magnetHitbox
        weld.Parent = magnetHitbox
        local magnetBox = Instance.new("SelectionSphere")
        magnetBox.Name = "AethelMagnetBox"
        magnetBox.Adornee = magnetHitbox
        magnetBox.Color3 = Color3.fromRGB(242, 140, 62)
        magnetBox.Transparency = s.Ball.BallMagVisualizer and 0.2 or 1
        magnetBox.SurfaceTransparency = 1
        magnetBox.Parent = magnetHitbox
        magnetHitbox.Touched:Connect(function(part)
            if not s.Ball.BallMags or hasball(LocalPlayer.Character) then return end
            if part.Name == "Ball" or (part.Parent and part.Parent.Name == "Basketball") then
                firetouchinterest(head, part, 0)
                task.wait()
                firetouchinterest(head, part, 1)
            end
        end)
    end

    local function enableMagnet()
        local char = LocalPlayer.Character
        if not char then return end
        createMagnetHitbox(char)
        if magnetConnection then magnetConnection:Disconnect(); magnetConnection = nil end
        magnetConnection = RunService.Heartbeat:Connect(function()
            if not s.Ball.BallMags then return end
            local character = LocalPlayer.Character
            if character and not character:FindFirstChild("AethelMagnet") then
                createMagnetHitbox(character)
            end
        end)
        Track(magnetConnection)
    end

    local function disableMagnet()
        if magnetConnection then magnetConnection:Disconnect(); magnetConnection = nil end
        if magnetHitbox then magnetHitbox:Destroy(); magnetHitbox = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("AethelMagnet") then
            LocalPlayer.Character.AethelMagnet:Destroy()
        end
    end

    local reachVisualizer, reachConnection = nil, nil

    local function removeReachVisualizer()
        if reachVisualizer then reachVisualizer:Destroy(); reachVisualizer = nil end
    end

    local function performReachSteal()
        if not s.Ball.BallReach then return end
        local char = LocalPlayer.Character
        if not char or char:FindFirstChild("Basketball") then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local range = s.Ball.BallReachRange or 10
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local pChar = player.Character
            if pChar then
                local basketball = pChar:FindFirstChild("Basketball")
                if basketball then
                    local ballPart = basketball:FindFirstChild("Ball") or basketball:FindFirstChildOfClass("BasePart")
                    if ballPart and (head.Position - ballPart.Position).Magnitude <= range then
                        firetouchinterest(head, ballPart, 0)
                        task.wait()
                        firetouchinterest(head, ballPart, 1)
                        return
                    end
                end
            end
        end
    end

    local function updateReachVisualizer()
        if not s.Ball.BallReachVisualizer then removeReachVisualizer(); return end
        local closest, closestDist = nil, math.huge
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                local c = p.Character
                local b = c and c:FindFirstChild("Basketball")
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if b and r then
                    local d = (myRoot.Position - r.Position).Magnitude
                    if d < closestDist then closestDist = d; closest = p end
                end
            end
        end
        local ballPart = nil
        if closest and closest.Character then
            local oppBall = closest.Character:FindFirstChild("Basketball")
            if oppBall then ballPart = oppBall:FindFirstChild("Ball") end
        end
        if not ballPart then removeReachVisualizer(); return end
        local range = s.Ball.BallReachRange or 10
        if not reachVisualizer or not reachVisualizer.Parent then
            reachVisualizer = Instance.new("Part")
            reachVisualizer.Name = "ReachBallVisualizer"
            reachVisualizer.Shape = Enum.PartType.Ball
            reachVisualizer.Size = Vector3.new(range, range, range)
            reachVisualizer.Transparency = 1
            reachVisualizer.CanCollide = false
            reachVisualizer.CanTouch = false
            reachVisualizer.CanQuery = false
            reachVisualizer.CastShadow = false
            reachVisualizer.Massless = true
            reachVisualizer.Anchored = true
            reachVisualizer.Color = Color3.fromRGB(242, 140, 62)
            reachVisualizer.Parent = workspace
            local sphereBox = Instance.new("SelectionSphere")
            sphereBox.Name = "AethelReachSphere"
            sphereBox.Adornee = reachVisualizer
            sphereBox.Transparency = 0.75
            sphereBox.SurfaceTransparency = 1
            sphereBox.Color3 = Color3.fromRGB(242, 140, 62)
            sphereBox.Parent = reachVisualizer
        end
        reachVisualizer.Size = Vector3.new(range, range, range)
        reachVisualizer.CFrame = ballPart.CFrame
    end

    local function enableReach()
        local char = LocalPlayer.Character
        if not char then return end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("AethelReach") then
            LocalPlayer.Character.AethelReach:Destroy()
        end
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        reachConnection = RunService.Heartbeat:Connect(function()
            if not s.Ball.BallReach and not s.Ball.BallReachVisualizer then return end
            if s.Ball.BallReach then performReachSteal() end
            if s.Ball.BallReachVisualizer then updateReachVisualizer() else removeReachVisualizer() end
        end)
        Track(reachConnection)
    end

    local function disableReach()
        if reachConnection then reachConnection:Disconnect(); reachConnection = nil end
        removeReachVisualizer()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("AethelReach") then
            LocalPlayer.Character.AethelReach:Destroy()
        end
    end

    local tpWalkConnection = nil

    local function enableTPWalk()
        if tpWalkConnection then tpWalkConnection:Disconnect(); tpWalkConnection = nil end
        tpWalkConnection = RunService.Heartbeat:Connect(function()
            if not s.TPWalk.Enabled then return end
            local character = LocalPlayer.Character
            if not character then return end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                rootPart.CFrame = rootPart.CFrame + humanoid.MoveDirection * s.TPWalk.Speed
            end
        end)
        Track(tpWalkConnection)
    end

    local function disableTPWalk()
        if tpWalkConnection then tpWalkConnection:Disconnect(); tpWalkConnection = nil end
    end

    local magV2Connection = nil

    local function magV2Tick()
        if not s.MagV2.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        local ballName = s.MagV2.BallName
        local reach = tonumber(s.MagV2.Reach) or 20
        for _, object in pairs(workspace:GetDescendants()) do
            if object.Name == ballName and object:IsA("BasePart") then
                if object:FindFirstChildWhichIsA("TouchTransmitter") or object:FindFirstChild("TouchInterest") then
                    if (touchPart.Position - object.Position).Magnitude <= reach then
                        firetouchinterest(touchPart, object, 0)
                        task.wait()
                        firetouchinterest(touchPart, object, 1)
                    end
                end
            end
        end
    end

    local function enableMagV2()
        if magV2Connection then magV2Connection:Disconnect(); magV2Connection = nil end
        magV2Connection = RunService.Heartbeat:Connect(function() pcall(magV2Tick) end)
        Track(magV2Connection)
    end

    local function disableMagV2()
        if magV2Connection then magV2Connection:Disconnect(); magV2Connection = nil end
    end

    local Effects = {}
    local function loadEffects()
        pcall(function()
            local folder = ReplicatedStorage.ShopItems.Effect
            for _, eff in folder:GetChildren() do
                Effects[eff.Name:gsub("Effect_", "")] = eff
            end
        end)
    end
    loadEffects()

    local goalEventHook = nil

    local function applyGoalEffect()
        if not Effects[s.Goal.CurrentEffect] then return end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["Effect"] = Effects[s.Goal.CurrentEffect].Name
            PlayerData.storedData["Inventory"][Effects[s.Goal.CurrentEffect].Name] = 1
        end)
        if goalEventHook then return end
        pcall(function()
            local connections = getconnections(ReplicatedStorage.Remotes.goalEvent.OnClientEvent)
            if connections and connections[1] then
                local old
                old = hookfunction(connections[1].Function, function(Player, Court, Goal, XYZ, GoalEffect, Unknown)
                    if Player == LocalPlayer and s.Goal.Enabled then
                        GoalEffect = Effects[s.Goal.CurrentEffect].Value
                    end
                    return old(Player, Court, Goal, XYZ, GoalEffect, Unknown)
                end)
                goalEventHook = old
            end
        end)
    end

    local function resetGoalEffect()
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["Effect"] = Effects["LightRay"].Name
            PlayerData.storedData["Inventory"][Effects["LightRay"].Name] = 1
        end)
    end

    local function SpoofDevice()
        if not s.Misc.DeviceSpoofer then return end
        local device = s.Misc.Device
        if device == "PC" then DeviceEvent:FireServer("Desktop")
        elseif device == "Mobile" then DeviceEvent:FireServer("Mobile")
        elseif device == "Gamepad" then DeviceEvent:FireServer("Gamepad") end
    end

    local Moderators = {
        "izzran", "wistfulmikk", "Bibliogical", "aepione", "kyraizo",
        "ar1sxm", "westline60s", "Iukejdjd", "Ninja215215"
    }
    local antiModTask = nil
    local Notify

    local function startAntiMod()
        if antiModTask then return end
        antiModTask = task.spawn(function()
            local detected = {}
            while s.Misc.AntiModerator do
                task.wait(1)
                for _, moderator in next, Players:GetPlayers() do
                    if table.find(Moderators, moderator.Name) and not detected[moderator.UserId] then
                        detected[moderator.UserId] = true
                        if Notify then
                            Notify({ title = "Moderator Detected", content = moderator.Name .. " is in the server.", duration = 5 })
                        end 
                    end
                end
            end
        end)
    end

    local function stopAntiMod()
        s.Misc.AntiModerator = false
        if antiModTask then task.cancel(antiModTask); antiModTask = nil end
    end

    local Balls, BallNames = {}, {}
    local Trails, TrailNames = {}, {}
    local Auras, AuraNames = {}, {}
    local Courts, CourtNames = {}, {}
    local OriginalReplicateBall, Replicator = nil, nil
    local OriginalReplicateTrail = nil
    local OriginalReplicateAura = nil
    local OriginalReplicateCourt = nil

    pcall(function()
        Replicator = require(ReplicatedStorage.Util.Replicator)
        OriginalReplicateBall = Replicator["ReplicateBall"]
        OriginalReplicateTrail = Replicator["ReplicateTrail"]
        OriginalReplicateAura = Replicator["ReplicateAura"]
        OriginalReplicateCourt = Replicator["ReplicateCourt"]

        for _, ballItem in ReplicatedStorage.ShopItems.Ball:GetChildren() do
            local name = ballItem.Name:gsub("Ball_", "")
            Balls[name] = ballItem.Name
            table.insert(BallNames, name)
        end
        table.sort(BallNames)

        local trailFolder = ReplicatedStorage.ShopItems:FindFirstChild("Trail")
        if trailFolder then
            for _, item in trailFolder:GetChildren() do
                local name = item.Name:gsub("Trail_", "")
                Trails[name] = item.Name
                table.insert(TrailNames, name)
            end
            table.sort(TrailNames)
        end

        local auraFolder = ReplicatedStorage.ShopItems:FindFirstChild("Aura")
        if auraFolder then
            for _, item in auraFolder:GetChildren() do
                local name = item.Name:gsub("Aura_", "")
                Auras[name] = item.Name
                table.insert(AuraNames, name)
            end
            table.sort(AuraNames)
        end

        -- Court skin list: try multiple known folder names
        local function addCourtFolder(folder)
            if not folder then return end
            for _, item in folder:GetChildren() do
                local name = item.Name:gsub("^CourtSkin_", ""):gsub("^Court_", ""):gsub("^Skin_", "")
                if not Courts[name] then
                    Courts[name] = item.Name
                    table.insert(CourtNames, name)
                end
            end
        end
        local shop = ReplicatedStorage:FindFirstChild("ShopItems")
        if shop then
            addCourtFolder(shop:FindFirstChild("CourtSkin"))
            addCourtFolder(shop:FindFirstChild("Courts"))
            addCourtFolder(shop:FindFirstChild("Court"))
        end
        -- Fallback: scan any folder named Court* under ReplicatedStorage
        if #CourtNames == 0 then
            for _, inst in ReplicatedStorage:GetDescendants() do
                if inst:IsA("Folder") and inst.Name:lower():find("court", 1, true) and inst.Parent then
                    addCourtFolder(inst)
                end
            end
        end
        table.sort(CourtNames)
        if #CourtNames > 0 and (s.CourtSpoofer.SelectedCourt == "None" or s.CourtSpoofer.CurrentCourt == "None") then
            s.CourtSpoofer.SelectedCourt = CourtNames[1]
            s.CourtSpoofer.CurrentCourt = CourtNames[1]
        end
    end)

    local function ownerOfParent(parent)
        local node = parent
        for _ = 1, 6 do
            if not node then break end
            if node:IsA("Model") then
                local plr = Players:GetPlayerFromCharacter(node)
                if plr then return plr end
            end
            node = node.Parent
        end
        return nil
    end

    local function applyBallChanger()
        if not Replicator or not OriginalReplicateBall then return end
        Replicator["ReplicateBall"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Balls[s.BallChanger.CurrentBall]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateBall(Parent, Name)
        end
    end

    local function resetBallChanger()
        if not Replicator or not OriginalReplicateBall then return end
        Replicator["ReplicateBall"] = OriginalReplicateBall
    end

    local function applyTrailSpoofer()
        if not Replicator or not OriginalReplicateTrail then return end
        Replicator["ReplicateTrail"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Trails[s.TrailSpoofer.CurrentTrail]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateTrail(Parent, Name)
        end
    end

    local function resetTrailSpoofer()
        if not Replicator or not OriginalReplicateTrail then return end
        Replicator["ReplicateTrail"] = OriginalReplicateTrail
    end

    local function applyBallAura()
        if not Replicator or not OriginalReplicateAura then return end
        Replicator["ReplicateAura"] = function(Parent, Name)
            if ownerOfParent(Parent) == LocalPlayer then
                local spoofed = Auras[s.BallAura.CurrentAura]
                if spoofed then Name = spoofed end
            end
            return OriginalReplicateAura(Parent, Name)
        end
    end

    local function resetBallAura()
        if not Replicator or not OriginalReplicateAura then return end
        Replicator["ReplicateAura"] = OriginalReplicateAura
    end

    -- ============================================================
    -- COURT SKIN SPOOFER (Replicator hook + PlayerData fallback)
    -- ============================================================
    local function applyCourtSpoofer()
        local target = Courts[s.CourtSpoofer.CurrentCourt]
        if not target then
            Notify({ title = "Court Spoofer", content = "Selected court not found.", duration = 3 })
            return
        end
        if Replicator and OriginalReplicateCourt then
            Replicator["ReplicateCourt"] = function(Parent, Name)
                if ownerOfParent(Parent) == LocalPlayer then
                    local spoofed = Courts[s.CourtSpoofer.CurrentCourt]
                    if spoofed then Name = spoofed end
                end
                return OriginalReplicateCourt(Parent, Name)
            end
        end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["CourtSkin"] = target
            PlayerData.storedData["Inventory"][target] = 1
        end)
        Notify({ title = "Court Spoofer", content = "Applied: " .. s.CourtSpoofer.CurrentCourt, duration = 2.5 })
    end

    local function resetCourtSpoofer()
        if Replicator and OriginalReplicateCourt then
            Replicator["ReplicateCourt"] = OriginalReplicateCourt
        end
        pcall(function()
            local PlayerData = require(ReplicatedStorage.Util.PlayerData)
            PlayerData.storedData["Equipping"]["CourtSkin"] = nil
        end)
    end

    local indicator = Instance.new("BillboardGui")
    indicator.Name = "RangeIndicator"
    indicator.Size = UDim2.fromOffset(90, 90)
    indicator.AlwaysOnTop = true
    indicator.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)

    local indicatorRing = Instance.new("ImageLabel")
    indicatorRing.Name = "Ring"
    indicatorRing.Size = UDim2.fromScale(1, 1)
    indicatorRing.BackgroundTransparency = 1
    indicatorRing.Image = "rbxassetid://3570695787"
    indicatorRing.ImageColor3 = Color3.fromRGB(242, 140, 62)
    indicatorRing.ImageTransparency = 0.15
    indicatorRing.ScaleType = Enum.ScaleType.Fit
    indicatorRing.Parent = indicator

    local indicatorDot = Instance.new("Frame")
    indicatorDot.Name = "Dot"
    indicatorDot.Size = UDim2.fromOffset(6, 6)
    indicatorDot.AnchorPoint = Vector2.new(0.5, 0.5)
    indicatorDot.Position = UDim2.fromScale(0.5, 0.5)
    indicatorDot.BackgroundColor3 = Color3.fromRGB(242, 140, 62)
    indicatorDot.BorderSizePixel = 0
    indicatorDot.Parent = indicator
    local indicatorDotCorner = Instance.new("UICorner")
    indicatorDotCorner.CornerRadius = UDim.new(1, 0)
    indicatorDotCorner.Parent = indicatorDot

    local rangeConnection = nil

    local function applyIndicatorColor()
        local col = IndicatorColors[s.Visuals.IndicatorColor] or Color3.fromRGB(242, 140, 62)
        indicatorRing.ImageColor3 = col
        indicatorDot.BackgroundColor3 = col
    end

    local function setShotIndicator(value)
        s.Visuals.ShotIndicator = value
        if rangeConnection then rangeConnection:Disconnect(); rangeConnection = nil end
        indicator.Parent = nil
        if not value then return end
        local throttle = 0
        rangeConnection = RunService.Heartbeat:Connect(function(dt)
            throttle += dt
            if throttle < 0.05 then return end
            throttle = 0
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root or not hasball(character) then indicator.Parent = nil; return end
            local goal, distance = nearestgoal(root)
            if goal and distance >= 12 and distance <= 73 then
                applyIndicatorColor()
                if indicator.Parent ~= character then
                    indicator.Adornee = character
                    indicator.Parent = character
                end
            else
                indicator.Parent = nil
            end
        end)
        Track(rangeConnection)
    end

    local AURAL_MIN_DIST = 12
    local AURAL_MAX_DIST = 73

    local shot_data = {
        [59]=83,[60]=81,[61]=82,[62]=79,[63]=78.8,[64]=75,[65]=74.8,[66]=71,
        [67]=70.8,[68]=66,[69]=62,[70]=59,[71]=51,[72]=51,[73]=51
    }

    local inner_arc_data = {
        [7]=123,[8]=122,[9]=121,[10]=120,[11]=119,[12]=118,[13]=117,[14]=116,[15]=115,[16]=114,
        [17]=113,[18]=112,[19]=111,[20]=110,[21]=109,[22]=108,[23]=107,[24]=106,[25]=105,
        [26]=105,
        [27]=106,[28]=106,[29]=107,[30]=107,[31]=106,[32]=105,[33]=105,[34]=104,[35]=103,
        [36]=103,
        [37]=102,[38]=102,[39]=101,[40]=101,[41]=100,[42]=99,[43]=99,[44]=98,[45]=97,[46]=96,
        [47]=95,[48]=95,[49]=94,[50]=93,[51]=91,[52]=90,[53]=88,[54]=87,[55]=85,[56]=84,[57]=82,
        [58]=81
    }

    local mobileArcs = {
        [30]=38,[31]=38,[32]=38,[33]=38,[34]=38,[35]=38,[36]=38,[37]=38,[38]=38,[39]=38,
        [40]=39,[41]=38,[42]=38,[43]=38,[44]=38,[45]=38,[46]=38,[47]=38,[48]=38,[49]=38,
        [50]=38,[51]=37,[52]=37,[53]=37,[54]=36,[55]=34,[56]=34,[57]=34,[58]=34,[59]=31,
        [60]=31,[61]=31,[62]=31,[63]=29,[64]=29,[65]=29,[66]=26,[67]=26,[68]=24,[69]=24,
        [70]=21,[71]=21,[72]=19,[73]=19
    }

    local function getArcOffset(dist)
        if isMobile then
            local d = math.floor(dist + 0.5)
            if d < 30 then d = 30 end
            if d > 73 then d = 73 end
            return mobileArcs[d] or 37
        end
        if inner_arc_data[dist] then return inner_arc_data[dist] end
        if shot_data[dist] then return shot_data[dist] end
        if dist < 7 then return 122 end
        if dist > 73 then return math.max(20, 50 - (dist - 73) * 1.5) end
        local lower, upper
        for d in pairs(inner_arc_data) do
            if d <= dist and (not lower or d > lower) then lower = d end
            if d >= dist and (not upper or d < upper) then upper = d end
        end
        for d in pairs(shot_data) do
            if d <= dist and (not lower or d > lower) then lower = d end
            if d >= dist and (not upper or d < upper) then upper = d end
        end
        if lower and upper and lower ~= upper then
            local lowerVal = inner_arc_data[lower] or shot_data[lower] or 0
            local upperVal = inner_arc_data[upper] or shot_data[upper] or 0
            return lowerVal + (upperVal - lowerVal) * ((dist - lower) / (upper - lower))
        elseif lower then
            return inner_arc_data[lower] or shot_data[lower] or 0
        elseif upper then
            return inner_arc_data[upper] or shot_data[upper] or 0
        end
        return 100
    end

    local Icon = nil
    local IconCenter = nil
    do
        pcall(function()
            local PowerUI = LocalPlayer.PlayerGui:WaitForChild("PowerUI")
            Icon = PowerUI:WaitForChild("CursorIcon")
            local CursorIcon2 = PowerUI:WaitForChild("CursorIcon2")
            task.delay(5, function()
                if Icon then
                    IconCenter = Vector2.new(Icon.AbsolutePosition.X + Icon.AbsoluteSize.X / 2, Icon.AbsolutePosition.Y + Icon.AbsoluteSize.Y / 2)
                    Icon:Destroy()
                end
                if CursorIcon2 then CursorIcon2.Visible = false end
            end)
        end)
    end

    local state = {
        target = nil, connections = {}, actorst = nil, actorname = nil,
        actors = {}, oldnewindex = nil, active = true, clicking = false
    }
    local function addconnection(c) table.insert(state.connections, c); return c end

    local function settarget(target)
        state.target = target
        if state.actorst then pcall(function() state.actorst.t = target end) end
    end

    local function doClick()
        if state.clicking then return end
        state.clicking = true
        getgenv().__aethel_aiming = true
        if isMobile then
            if Icon then
                local pos = Vector2.new(Icon.AbsolutePosition.X + Icon.AbsoluteSize.X / 2, Icon.AbsolutePosition.Y + Icon.AbsoluteSize.Y / 2)
                VirtualInput:SendTouchEvent(1, 0, pos.X, pos.Y)
                VirtualInput:SendTouchEvent(1, 2, pos.X, pos.Y)
            elseif IconCenter then
                VirtualInput:SendTouchEvent(1, 0, IconCenter.X, IconCenter.Y)
                VirtualInput:SendTouchEvent(1, 2, IconCenter.X, IconCenter.Y)
            end
        else
            local vp = Camera.ViewportSize
            VirtualInput:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 1)
            VirtualInput:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 1)
        end
        task.delay(0.35, function()
            state.clicking = false
            getgenv().__aethel_aiming = false
        end)
    end

    local function velocify(target, dist)
        local _, _, hrp = getChar()
        if not hrp then return target end
        local v = hrp.AssemblyLinearVelocity
        local prediction = (dist / 50) * 0.06
        return target + Vector3.new(v.X * prediction, 0, v.Z * prediction)
    end

    local auralTick = 0
    local function updateAuralTarget(dt)
        if not state.active or not s.Shooting.AuralEnabled then
            if state.target ~= nil then settarget(nil) end
            return
        end
        auralTick += dt
        if auralTick < 0.05 then return end
        auralTick = 0
        local char, hum = getChar()
        if not char or not hum or not hasball(char) then
            if state.target ~= nil then settarget(nil) end
            return
        end
        if hum.FloorMaterial ~= Enum.Material.Air and not hum.Jump then
            if state.target ~= nil then settarget(nil) end
            return
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then settarget(nil); return end
        local goal, distance = nearestgoal(root)
        if not goal or distance < AURAL_MIN_DIST or distance > AURAL_MAX_DIST then
            if state.target ~= nil then settarget(nil) end
            return
        end
        local offset = getArcOffset(distance) + s.Shooting.ShotYAxis
        if s.Shooting.HumanizeAim then
            local strength = s.Shooting.HumanizeStrength or 1.2
            local missChance = (s.Shooting.MissChance or 12) / 100
            if math.random() < missChance then
                if math.random() < 0.5 then
                    offset += strength * 3 + math.random() * strength * 2
                else
                    offset -= strength * 3 + math.random() * strength * 2
                end
            else
                offset += (math.random() * 2 - 1) * strength
            end
        end
        settarget(velocify(goal.Position + Vector3.new(0, offset, 0), distance))
    end

    local actorcode = [==[
local registry = game:GetService("SharedTableRegistry")
local players = game:GetService("Players")
local st = registry:GetSharedTable(__aethelaimtable)
local camera = workspace.CurrentCamera
local function target() local v = st.t return typeof(v) == "Vector3" and v or nil end
local function aimcframe()
    local v = target()
    local char = players.LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if v and head then return CFrame.new(head.Position, v) end
end
pcall(function()
    local oldrender
    oldrender = hookfunction(camera.GetRenderCFrame, function(self, ...) return aimcframe() or oldrender(self, ...) end)
    local oldscreen
    oldscreen = hookfunction(camera.ScreenPointToRay, function(self, ...)
        local v = aimcframe()
        if v then return Ray.new(v.Position, v.LookVector) end
        return oldscreen(self, ...)
    end)
    local oldviewport
    oldviewport = hookfunction(camera.ViewportPointToRay, function(self, ...)
        local v = aimcframe()
        if v then return Ray.new(v.Position, v.LookVector) end
        return oldviewport(self, ...)
    end)
    local cameradata = registry:GetSharedTable("CameraData")
    local history = cameradata.CameraHistory
    local meta = getrawmetatable(cameradata)
    local oldnewindex
    oldnewindex = hookfunction(meta.__newindex, newcclosure(function(tab, key, value)
        local current = tab == cameradata and key == "CameraCFrame"
        local previous = history ~= nil and tab == history and type(key) == "number"
        local aimed = aimcframe()
        if aimed and (current or previous) then return oldnewindex(tab, key, aimed) end
        return oldnewindex(tab, key, value)
    end))
end)
]==]

    local function hookmain()
        pcall(function()
            state.actorname = "sa" .. tostring(math.floor(os.clock() * 100000)) .. tostring(math.random(10000, 99999))
            state.actorst = SharedTableRegistry:GetSharedTable(state.actorname)
            state.actorst.t = nil
            local cameradata = SharedTableRegistry:GetSharedTable("CameraData")
            local history = cameradata.CameraHistory
            local meta = getrawmetatable(cameradata)
            state.oldnewindex = hookfunction(meta.__newindex, newcclosure(function(tab, key, value)
                local current = tab == cameradata and key == "CameraCFrame"
                local previous = history ~= nil and tab == history and type(key) == "number"
                local tgt = state.target
                if tgt and (current or previous) and typeof(value) == "CFrame" then
                    local char = LocalPlayer.Character
                    local head = char and char:FindFirstChild("Head")
                    if head then
                        return state.oldnewindex(tab, key, CFrame.new(head.Position, tgt))
                    end
                end
                return state.oldnewindex(tab, key, value)
            end))
        end)
    end

    local function hookactors()
        if type(getactors) ~= "function" or type(run_on_actor) ~= "function" or not state.actorname then return end
        local ok, actors = pcall(getactors)
        if not ok or type(actors) ~= "table" then return end
        local code = "local __aethelaimtable = " .. string.format("%q", state.actorname) .. " " .. actorcode
        for _, actor in actors do
            if not state.actors[actor] then
                if pcall(run_on_actor, actor, code) then
                    state.actors[actor] = true
                end
            end
        end
    end

    hookmain()
    hookactors()

    addconnection(Players.PlayerAdded:Connect(function() task.defer(hookactors) end))
    addconnection(RunService.Heartbeat:Connect(updateAuralTarget))

    local function setupCharacterAural(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local jumps = 0
        addconnection(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AuralEnabled or not hasball(char) then return end
            if s.Shooting.EBLHop then
                jumps += 1
                if jumps < 2 then return end
                jumps = 0
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local goal, distance = nearestgoal(root)
            local minDist = isMobile and 30 or AURAL_MIN_DIST
            if not goal or distance < minDist or distance > AURAL_MAX_DIST then return end
            local arc = getArcOffset(distance) + s.Shooting.ShotYAxis
            local targetPos = nil
            if s.Shooting.HumanizeAim then
                local strength = s.Shooting.HumanizeStrength or 1.2
                local missChance = (s.Shooting.MissChance or 12) / 100
                if math.random() < missChance then
                    local mode = math.random(1, 3)
                    if mode == 1 then
                        arc += strength * 3 + math.random() * strength * 2
                    elseif mode == 2 then
                        arc -= strength * 3 + math.random() * strength * 2
                    else
                        local side = (math.random() < 0.5) and -1 or 1
                        targetPos = goal.Position
                            + Vector3.new(0, getArcOffset(distance) + s.Shooting.ShotYAxis, 0)
                            + Camera.CFrame.RightVector * (side * (strength * 2 + math.random() * 2))
                    end
                else
                    arc += (math.random() * 2 - 1) * strength
                end
            end
            targetPos = targetPos or goal.Position + Vector3.new(0, arc, 0)
            settarget(targetPos)
            task.wait(0.05)
            LocalPlayer:SetAttribute("Power", 85)
            local shotdelay = s.Shooting.ShotDelay or 0.25
            if s.Shooting.RandomizeShotDelay then
                local mn = s.Shooting.ShotDelayMin or 0.15
                local mx = s.Shooting.ShotDelayMax or 0.35
                if mx < mn then mx = mn end
                shotdelay = mn + math.random() * (mx - mn)
            end
            task.wait(shotdelay)
            doClick()
            task.wait(0.1)
            updateAuralTarget(0.1)
        end))
    end

    if LocalPlayer.Character then setupCharacterAural(LocalPlayer.Character) end
    addconnection(LocalPlayer.CharacterAdded:Connect(setupCharacterAural))

    local textListeners = {}
    local originalNameTexts, originalRecordTexts, originalTitleTexts = {}, {}, {}

    local function formatStrokeText(orig, custom)
        if not custom or custom == "" then return orig end
        if orig and orig:match("^<stroke>") and orig:match("</stroke>$") then
            return "<stroke>" .. custom .. "</stroke>"
        end
        return custom
    end

    local function applyOwnNameplate()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local nameTag = hrp:FindFirstChild("NameTag")
        if not nameTag or not nameTag:IsA("BillboardGui") then return end
        for _, tagName in ipairs({"NameTag", "CreatorTag", "TeamSpot"}) do
            local tag = hrp:FindFirstChild(tagName)
            if tag and tag:IsA("BillboardGui") then
                tag.Enabled = not s.Visuals.HideOwnNameplate
            end
        end
        local mainFrame = nameTag:FindFirstChild("MainFrame")
        local gameFrame = nameTag:FindFirstChild("GameFrame")
        local subFrame = mainFrame and mainFrame:FindFirstChild("Frame")
        local nameLabels = {}
        if mainFrame and mainFrame:FindFirstChild("NameLabel") then table.insert(nameLabels, mainFrame.NameLabel) end
        if gameFrame and gameFrame:FindFirstChild("NameLabel") then table.insert(nameLabels, gameFrame.NameLabel) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "NameLabel" and not table.find(nameLabels, obj) then
                table.insert(nameLabels, obj)
            end
        end
        for _, obj in ipairs(nameLabels) do
            if not originalNameTexts[obj] then originalNameTexts[obj] = obj.Text end
            local target = (s.Visuals.CustomNameText ~= "") and s.Visuals.CustomNameText or originalNameTexts[obj]
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomNameText ~= "" and obj.Text ~= s.Visuals.CustomNameText then
                        obj.Text = s.Visuals.CustomNameText
                    end
                end)
            end
        end
        local recordLabels = {}
        if subFrame and subFrame:FindFirstChild("RecordLabel") then table.insert(recordLabels, subFrame.RecordLabel) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "RecordLabel" and not table.find(recordLabels, obj) then
                table.insert(recordLabels, obj)
            end
        end
        for _, obj in ipairs(recordLabels) do
            if not originalRecordTexts[obj] then originalRecordTexts[obj] = obj.Text end
            local target = formatStrokeText(originalRecordTexts[obj], s.Visuals.CustomRecordText)
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomRecordText ~= "" then
                        local expected = formatStrokeText(originalRecordTexts[obj], s.Visuals.CustomRecordText)
                        if obj.Text ~= expected then obj.Text = expected end
                    end
                end)
            end
        end
        local titleLabels = {}
        if subFrame and subFrame:FindFirstChild("AchievementName") then table.insert(titleLabels, subFrame.AchievementName) end
        for _, obj in ipairs(nameTag:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Name == "AchievementName" or obj.Name == "TitleLabel") and not table.find(titleLabels, obj) then
                table.insert(titleLabels, obj)
            end
        end
        for _, obj in ipairs(titleLabels) do
            if not originalTitleTexts[obj] then originalTitleTexts[obj] = obj.Text end
            local target = formatStrokeText(originalTitleTexts[obj], s.Visuals.CustomTitleText)
            if obj.Text ~= target then obj.Text = target end
            if not textListeners[obj] then
                textListeners[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
                    if s.Visuals.CustomTitleText ~= "" then
                        local expected = formatStrokeText(originalTitleTexts[obj], s.Visuals.CustomTitleText)
                        if obj.Text ~= expected then obj.Text = expected end
                    end
                end)
            end
        end
    end

    local ownNameplateConnection = nil

    local function setupOwnNameplateListener()
        if ownNameplateConnection then return end
        local function onChar(char)
            task.wait(0.2)
            applyOwnNameplate()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                hrp.ChildAdded:Connect(function(child)
                    if child:IsA("BillboardGui") then
                        task.wait(0.05)
                        applyOwnNameplate()
                    end
                end)
                local nameTag = hrp:WaitForChild("NameTag", 5)
                if nameTag then
                    nameTag.DescendantAdded:Connect(function()
                        task.wait(0.05)
                        applyOwnNameplate()
                    end)
                end
            end
        end
        if LocalPlayer.Character then task.spawn(onChar, LocalPlayer.Character) end
        ownNameplateConnection = LocalPlayer.CharacterAdded:Connect(onChar)
        Track(ownNameplateConnection)
    end
    setupOwnNameplateListener()

    -- ============================================================
    -- BODY AURA CHANGER (cosmetic, client-side)
    -- ============================================================
    local baScan, baApply, baEnable, baDisable
    local BodyAuraList = {}
    do
        local BodyAura = {
            active = false,
            selected = nil,
            container = nil,
            charAddedConn = nil,
            list = {},
            lookup = {},
        }

        local function ba_hidePlastic(container)
            if not container then return end
            local hideList, hasReal = {}, false
            for _, child in pairs(container:GetDescendants()) do
                if child:IsA("BasePart") then
                    local plastic = child.Material == Enum.Material.Plastic
                    local placeholder = child.Name:lower() == "aura"
                    if plastic or placeholder then
                        table.insert(hideList, child)
                    elseif child.Transparency < 1 then
                        hasReal = true
                    end
                elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
                    hasReal = true
                end
            end
            -- If everything is plastic, those parts ARE the aura, so keep them.
            if not hasReal then return end
            for _, part in ipairs(hideList) do
                part.Transparency = 1; part.CanCollide = false
            end
        end

        local function ba_cleanCharacter(char)
            if not char then return end
            local realHead = char:FindFirstChild("Head")
            for _, child in pairs(char:GetChildren()) do
                if child:IsA("Part") or child:IsA("MeshPart") then
                    if child.Name:lower():find("head") and child ~= realHead then
                        child.Transparency = 1; child.CanCollide = false
                    end
                    if child.Name:lower() == "aura" then
                        child.Transparency = 1; child.CanCollide = false
                    end
                end
            end
            local realHum = char:FindFirstChildOfClass("Humanoid")
            for _, child in pairs(char:GetChildren()) do
                if child:IsA("Humanoid") and child ~= realHum then child:Destroy() end
            end
        end

        local function ba_findRig(auraModel)
            for _, child in pairs(auraModel:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then return child end
            end
            if auraModel:FindFirstChildOfClass("Humanoid") then return auraModel end
            local hum = auraModel:FindFirstChildWhichIsA("Humanoid", true)
            if hum and hum.Parent then return hum.Parent end
            return nil
        end

        local function ba_rigParts(rigModel)
            local parts = {}
            for _, name in pairs({"Head","LeftArm","RightArm","Torso","LeftLeg","RightLeg","HumanoidRootPart"}) do
                local part = rigModel:FindFirstChild(name)
                if part and part:IsA("BasePart") then parts[name] = part end
            end
            return parts
        end

        local function ba_charParts(char)
            local parts = {}
            for _, name in pairs({"Head","LeftArm","RightArm","Torso","UpperTorso","LeftLeg","RightLeg","HumanoidRootPart"}) do
                local part = char:FindFirstChild(name)
                if part and part:IsA("BasePart") then parts[name] = part end
            end
            return parts
        end

        local function ba_stripFace(part)
            if not part then return end
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
            if part:FindFirstChild("face") then part.face:Destroy() end
        end

        local function ba_destroyContainer()
            BodyAura.container = nil
            local char = LocalPlayer.Character
            if char then
                local c = char:FindFirstChild("AuraVisuals")
                if c then c:Destroy() end
            end
        end

        local function ba_norm(name)
            return (name:lower():gsub("[%s_]", ""))
        end

        local function ba_isHeadish(name)
            local n = name:lower()
            return n:find("head") or n:find("hair") or n:find("hat")
        end

        -- Builds the aura on your character. Returns true, or false plus the reason.
        local function ba_build(auraModel)
            local char = LocalPlayer.Character
            if not char or not char.Parent then return false, "no character" end
            local native = char:FindFirstChild("bodyaura")
            if native and native:IsA("LocalScript") then native.Disabled = true end
            ba_destroyContainer()
            ba_cleanCharacter(char)

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false, "no HumanoidRootPart" end

            local rig = ba_findRig(auraModel)
            local source = rig or auraModel

            -- every visual part of the aura (skip parts nested inside another part)
            local items = {}
            local function collect(inst)
                if inst:IsA("BasePart") then
                    local p, nested = inst.Parent, false
                    while p and p ~= source do
                        if p:IsA("BasePart") then nested = true; break end
                        p = p.Parent
                    end
                    if not nested then table.insert(items, inst) end
                end
            end
            collect(source)
            for _, d in ipairs(source:GetDescendants()) do collect(d) end
            if #items == 0 then return false, "aura has no parts" end

            -- reference point of the aura model
            local rigRoot = rig and (rig:FindFirstChild("HumanoidRootPart") or rig.PrimaryPart
                or rig:FindFirstChild("Torso") or rig:FindFirstChild("UpperTorso"))
            local pivot
            if rigRoot and rigRoot:IsA("BasePart") then
                pivot = rigRoot.CFrame
            else
                local sum = Vector3.zero
                for _, p in ipairs(items) do sum += p.Position end
                pivot = CFrame.new(sum / #items)
            end

            -- your character's parts, by normalised name ("Left Arm" == "LeftArm")
            local charByName = {}
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then charByName[ba_norm(p.Name)] = p end
            end
            local rigHead = rig and rig:FindFirstChild("Head")
            local charHead = char:FindFirstChild("Head")

            local container = Instance.new("Model")
            container.Name = "AuraVisuals"
            container.Parent = char
            BodyAura.container = container

            local built = 0
            for _, auraPart in ipairs(items) do
                local newPart = auraPart:Clone()
                -- drop anything that could fight your character
                for _, d in ipairs(newPart:GetDescendants()) do
                    if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Humanoid")
                        or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                        d:Destroy()
                    end
                end
                newPart.Anchored = false
                newPart.CanCollide = false
                newPart.CanTouch = false
                newPart.CanQuery = false
                newPart.Massless = true
                newPart.Parent = container

                local isRoot = auraPart == rigRoot or auraPart.Name == "HumanoidRootPart"
                if isRoot then newPart.Transparency = 1 end
                if ba_isHeadish(auraPart.Name) then ba_stripFace(newPart) end

                local weld = Instance.new("Weld")
                weld.Part1 = newPart
                local direct = (auraPart.Parent == source) and charByName[ba_norm(auraPart.Name)]
                if direct then
                    -- same body part on both sides: sit exactly on it
                    weld.Part0 = direct
                    weld.C0 = CFrame.new()
                elseif ba_isHeadish(auraPart.Name) and charHead then
                    -- hair / hat style parts follow your head
                    weld.Part0 = charHead
                    local ref = rigHead and rigHead.CFrame or pivot
                    weld.C0 = ref:ToObjectSpace(auraPart.CFrame)
                else
                    -- everything else keeps its place relative to the aura's centre
                    weld.Part0 = hrp
                    weld.C0 = pivot:ToObjectSpace(auraPart.CFrame)
                end
                weld.Parent = newPart
                built += 1
            end

            ba_hidePlastic(container)
            if built == 0 then return false, "nothing built" end
            return true
        end

        local function ba_scanList()
            table.clear(BodyAura.list)
            table.clear(BodyAura.lookup)
            local ShopItems = ReplicatedStorage:FindFirstChild("ShopItems") or ReplicatedStorage:WaitForChild("ShopItems", 5)
            if not ShopItems then return end
            local folder = ShopItems:FindFirstChild("Aura") or ShopItems:WaitForChild("Aura", 5)
            if not folder then return end
            for _, child in pairs(folder:GetChildren()) do
                local name = child.Name:gsub("^Aura_", "")
                BodyAura.lookup[name] = child
                table.insert(BodyAura.list, name)
            end
            table.sort(BodyAura.list)
        end

        local function ba_applyByName(name)
            local model = BodyAura.lookup[name]
            if not model then return false, "aura not found" end
            BodyAura.selected = name
            if not BodyAura.active then return false, "disabled" end
            return ba_build(model)
        end

        local function ba_enable(name)
            ba_scanList()
            BodyAura.active = true
            if name and BodyAura.lookup[name] then
                BodyAura.selected = name
            elseif not BodyAura.selected and #BodyAura.list > 0 then
                BodyAura.selected = BodyAura.list[1]
            end
            local ok, why = true, nil
            if BodyAura.selected then ok, why = ba_applyByName(BodyAura.selected) end
            if not BodyAura.charAddedConn then
                BodyAura.charAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
                    char:WaitForChild("HumanoidRootPart", 5)
                    task.wait(1)
                    if BodyAura.active and BodyAura.selected then ba_applyByName(BodyAura.selected) end
                end)
            end
            return ok, why
        end

        local function ba_disable()
            BodyAura.active = false
            if BodyAura.charAddedConn then
                BodyAura.charAddedConn:Disconnect(); BodyAura.charAddedConn = nil
            end
            ba_destroyContainer()
        end

        baScan, baApply, baEnable, baDisable = ba_scanList, ba_applyByName, ba_enable, ba_disable
        BodyAuraList = BodyAura.list
    end
    baScan()

    -- ============================================================
    -- NAMETAG LOGO CHANGER (client-side only: edits your own CreatorTag icons)
    -- ============================================================
    local LogoNames = { "Booster", "Staff", "Tester", "Twitch", "VIP", "Youtuber" }
    local LogoOriginal, LogoWanted = {}, {}
    local applyLogo, resetLogos, logoDefault

    do
        local function getCreatorTag()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and hrp:FindFirstChild("CreatorTag")
        end

        local function setIcon(name, on)
            local tag = getCreatorTag()
            if not tag then return end
            for _, v in ipairs(tag:GetChildren()) do
                if v:IsA("ImageLabel") and v.Name == name then v.Visible = on end
            end
        end

        local function snapshot()
            local tag = getCreatorTag()
            if not tag then return end
            for _, n in ipairs(LogoNames) do
                if LogoOriginal[n] == nil then
                    local lbl = tag:FindFirstChild(n)
                    LogoOriginal[n] = (lbl and lbl:IsA("ImageLabel")) and lbl.Visible or false
                end
            end
        end
        snapshot()

        logoDefault = function(name) return LogoOriginal[name] == true end

        applyLogo = function(name, on)
            snapshot()
            LogoWanted[name] = on
            pcall(function() LocalPlayer:SetAttribute(name, on) end)
            setIcon(name, on)
        end

        resetLogos = function()
            for _, n in ipairs(LogoNames) do
                local orig = LogoOriginal[n] == true
                LogoWanted[n] = nil
                pcall(function() LocalPlayer:SetAttribute(n, orig) end)
                setIcon(n, orig)
            end
        end

        -- Re-apply chosen icons after respawn (the tag is rebuilt each life).
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            local tag = hrp and hrp:WaitForChild("CreatorTag", 5)
            if not tag then return end
            task.wait(0.3)
            for n, on in pairs(LogoWanted) do setIcon(n, on) end
        end))
    end

    local Window = Airflow:CreateWindow({Name = "Aethel Hub", LoadingSubtitle = "Aethel Hub basketball suite", Theme = "AethelDusk", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "AethelHub", FileName = "AethelHub"}})

    Notify = function(props) Window:Notify(props) end

    local CombatTab = Window:CreateTab({ Name = "Main", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })
    local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "eye" })
    local PrivacyTab = Window:CreateTab({ Name = "Privacy", Icon = "user" })
    local UtilityTab = Window:CreateTab({ Name = "Utility", Icon = "list" })

    CombatTab:CreateSection("Silent Aim")
    CombatTab:CreateToggle({
        Name = "Enable Silent Aim",
        Desc = "Automatically Shoots when you Jump",
        Flag = "aethel_aural",
        CurrentValue = s.Shooting.AuralEnabled,
        Callback = function(v) setAural(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Aimbot keybind",
        Flag = "aethel_aural_key",
        CurrentValue = s.Shooting.AuralKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AuralKeybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Shot delay",
        Range = { 0.15, 0.42 }, Increment = 0.01, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelay, Flag = "aethel_delay",
        Callback = function(v) s.Shooting.ShotDelay = v end,
    })
    CombatTab:CreateToggle({
        Name = "Randomize shot delay", Flag = "aethel_randdelay",
        CurrentValue = s.Shooting.RandomizeShotDelay,
        Callback = function(v) s.Shooting.RandomizeShotDelay = v end,
    })
    CombatTab:CreateSlider({
        Name = "Min delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMin, Flag = "aethel_mindelay",
        Callback = function(v) s.Shooting.ShotDelayMin = v end,
    })
    CombatTab:CreateSlider({
        Name = "Max delay", Range = { 0, 1 }, Increment = 0.05, Suffix = "s",
        CurrentValue = s.Shooting.ShotDelayMax, Flag = "aethel_maxdelay",
        Callback = function(v) s.Shooting.ShotDelayMax = v end,
    })
    CombatTab:CreateToggle({
        Name = "EBL Hop", Desc = "Require second jump before firing.",
        Flag = "aethel_ebl", CurrentValue = s.Shooting.EBLHop,
        Callback = function(v) s.Shooting.EBLHop = v end,
    })
    CombatTab:CreateToggle({
        Name = "Humanize aim", Flag = "aethel_human",
        CurrentValue = s.Shooting.HumanizeAim,
        Callback = function(v) s.Shooting.HumanizeAim = v end,
    })
    CombatTab:CreateSlider({
        Name = "Humanize strength", Range = { 0.2, 5 }, Increment = 0.1,
        CurrentValue = s.Shooting.HumanizeStrength, Flag = "aethel_hstr",
        Callback = function(v) s.Shooting.HumanizeStrength = v end,
    })
    CombatTab:CreateSlider({
        Name = "Miss chance", Range = { 0, 80 }, Increment = 1, Suffix = "%",
        CurrentValue = s.Shooting.MissChance, Flag = "aethel_miss",
        Callback = function(v) s.Shooting.MissChance = v end,
    })
    CombatTab:CreateSection("Auto Guard")
    CombatTab:CreateToggle({
        Name = "Auto guard", Flag = "aethel_guard", CurrentValue = s.Defending.AutoGuard,
        Callback = function(v) setGuard(v) end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto guard keybind", Flag = "aethel_guard_key",
        CurrentValue = s.Defending.GuardKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Defending.GuardKeybind = key end
        end,
    })
    CombatTab:CreateDropdown({
        Name = "Guard mode", Options = { "Reactive", "Balanced", "Aggressive" },
        CurrentValue = s.Defending.AutoGuardMode, Flag = "aethel_guard_mode",
        Callback = function(v) s.Defending.AutoGuardMode = v end,
    })
    CombatTab:CreateToggle({
        Name = "Guard nearest if no dribbler", Flag = "aethel_guard_near",
        CurrentValue = s.Defending.AutoGuardNearest,
        Callback = function(v) s.Defending.AutoGuardNearest = v end,
    })
    CombatTab:CreateSlider({
        Name = "Guard range", Range = { 10, 60 }, Increment = 1,
        CurrentValue = s.Defending.AutoGuardRange, Flag = "aethel_guard_range",
        Callback = function(v) s.Defending.AutoGuardRange = v end,
    })
    CombatTab:CreateSlider({
        Name = "Prediction strength", Range = { 0.1, 1 }, Increment = 0.05,
        CurrentValue = s.Defending.GuardPrediction, Flag = "aethel_guard_pred",
        Callback = function(v) s.Defending.GuardPrediction = v end,
    })

    BallTab:CreateSection("Ball Magnet")
    BallTab:CreateToggle({
        Name = "Ball magnet", Flag = "aethel_mag", CurrentValue = s.Ball.BallMags,
        Callback = function(v) setMagnet(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Magnet keybind", Flag = "aethel_mag_key", CurrentValue = Enum.KeyCode.M,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.MagnetKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Magnet size", Range = { 1, 50 }, Increment = 1,
        CurrentValue = s.Ball.BallMagRange, Flag = "aethel_mag_size",
        Callback = function(v)
            s.Ball.BallMagRange = v
            if magnetHitbox then magnetHitbox.Size = Vector3.new(v, v, v) end
        end,
    })
    BallTab:CreateToggle({
        Name = "Show magnet visualizer", Flag = "aethel_mag_vis",
        CurrentValue = s.Ball.BallMagVisualizer,
        Callback = function(v)
            s.Ball.BallMagVisualizer = v
            if magnetHitbox then
                local box = magnetHitbox:FindFirstChild("AethelMagnetBox")
                if box then box.Transparency = v and 0.2 or 1 end
            end
        end,
    })

    BallTab:CreateSection("Mag V2")
    BallTab:CreateToggle({
        Name = "Mag V2",
        Desc = "Standalone touch-magnet. Uses its own ball name & reach.",
        Flag = "aethel_magv2", CurrentValue = s.MagV2.Enabled,
        Callback = function(v) setMagV2(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Mag V2 keybind", Desc = "Default U. Toggle Mag V2 on/off.",
        Flag = "aethel_magv2_key", CurrentValue = s.MagV2.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.MagV2.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Mag V2 ball name", Placeholder = "Ball",
        CurrentValue = s.MagV2.BallName, Flag = "aethel_magv2_name",
        Callback = function(text)
            if text ~= "" then s.MagV2.BallName = text end
        end,
    })
    BallTab:CreateSlider({
        Name = "Mag V2 reach", Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.MagV2.Reach, Flag = "aethel_magv2_reach",
        Callback = function(v) s.MagV2.Reach = v end,
    })

    BallTab:CreateSection("Ball Reach")
    BallTab:CreateToggle({
        Name = "Ball reach", Flag = "aethel_reach", CurrentValue = s.Ball.BallReach,
        Callback = function(v) setReach(v) end,
    })
    BallTab:CreateKeybind({
        Name = "Reach keybind", Flag = "aethel_reach_key", CurrentValue = Enum.KeyCode.N,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Ball.ReachKeybind = key.Name end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach size", Range = { 1, 30 }, Increment = 1,
        CurrentValue = s.Ball.BallReachRange, Flag = "aethel_reach_size",
        Callback = function(v) s.Ball.BallReachRange = v end,
    })
    BallTab:CreateToggle({
        Name = "Show reach visualizer", Flag = "aethel_reach_vis",
        CurrentValue = s.Ball.BallReachVisualizer,
        Callback = function(v)
            s.Ball.BallReachVisualizer = v
            if v then
                enableReach()
            else
                removeReachVisualizer()
                if not s.Ball.BallReach then disableReach() end
            end
        end,
    })

    BallTab:CreateSection("TPWalk")
    BallTab:CreateToggle({
        Name = "tpwalk",
        Desc = "Teleport-walk; nudges your root part each frame for a smooth glide.",
        Flag = "aethel_tpwalk", CurrentValue = s.TPWalk.Enabled,
        Callback = function(v) setTPWalk(v) end,
    })
    BallTab:CreateKeybind({
        Name = "tpwalk keybind", Flag = "aethel_tpwalk_key",
        CurrentValue = s.TPWalk.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.TPWalk.Keybind = key end
        end,
    })
    BallTab:CreateSlider({
        Name = "tpwalk speed", Desc = "Step distance per frame (0.001 – 0.06).",
        Range = { 0.001, 0.06 }, Increment = 0.001,
        CurrentValue = s.TPWalk.Speed, Flag = "aethel_tpwalk_speed",
        Callback = function(v) s.TPWalk.Speed = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    VisualsTab:CreateSection("Aimbot Range Indicator")
    VisualsTab:CreateToggle({
        Name = "Aimbot range indicator", Flag = "aethel_ind",
        CurrentValue = s.Visuals.ShotIndicator,
        Callback = setShotIndicator,
    })
    VisualsTab:CreateDropdown({
        Name = "Indicator color",
        Options = { "Blue", "Purple", "Green", "Red", "Yellow" },
        CurrentValue = s.Visuals.IndicatorColor, Flag = "aethel_ind_col",
        Callback = function(v) s.Visuals.IndicatorColor = v; applyIndicatorColor() end,
    })

    VisualsTab:CreateSection("Goal Effect")
    local function getEffectNames()
        local names = {}
        for k in pairs(Effects) do table.insert(names, k) end
        table.sort(names)
        return names
    end
    VisualsTab:CreateDropdown({
        Name = "Select effect", Options = getEffectNames(),
        CurrentValue = s.Goal.SelectedEffect, Flag = "aethel_goal_sel",
        Callback = function(v)
            s.Goal.SelectedEffect = v
            s.Goal.CurrentEffect = v
            if s.Goal.Enabled then pcall(applyGoalEffect) end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable goal effect changer", Flag = "aethel_goal",
        CurrentValue = s.Goal.Enabled,
        Callback = function(v)
            s.Goal.Enabled = v
            if v then pcall(applyGoalEffect) else pcall(resetGoalEffect) end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset goal effect",
        Callback = function()
            s.Goal.Enabled = false
            s.Goal.SelectedEffect = "LightRay"
            s.Goal.CurrentEffect = "LightRay"
            pcall(resetGoalEffect)
        end,
    })

    VisualsTab:CreateSection("Body Aura")
    VisualsTab:CreateDropdown({
        Name = "Aura", Options = #BodyAuraList > 0 and BodyAuraList or { "None" },
        CurrentValue = s.BodyAura.Selected ~= "" and s.BodyAura.Selected or nil, Flag = "aethel_bodyaura_sel",
        Callback = function(v)
            s.BodyAura.Selected = v
            if s.BodyAura.Enabled then
                local ok, why = baApply(v)
                if not ok then Notify({ title = "Body Aura", content = "Could not apply " .. tostring(v) .. ": " .. tostring(why), duration = 4 }) end
            end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable body aura", Flag = "aethel_bodyaura", CurrentValue = s.BodyAura.Enabled,
        Callback = function(v)
            s.BodyAura.Enabled = v
            if v then
                local ok, why = baEnable(s.BodyAura.Selected ~= "" and s.BodyAura.Selected or nil)
                if not ok then Notify({ title = "Body Aura", content = "Could not apply: " .. tostring(why), duration = 4 }) end
            else
                baDisable()
            end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset body aura",
        Callback = function()
            s.BodyAura.Enabled = false
            s.BodyAura.Selected = ""
            baDisable()
        end,
    })

    VisualsTab:CreateSection("Court Spoofer")
    VisualsTab:CreateDropdown({
        Name = "Select court", Options = #CourtNames > 0 and CourtNames or { "None" },
        CurrentValue = s.CourtSpoofer.SelectedCourt, Flag = "aethel_court_sel",
        Callback = function(v)
            s.CourtSpoofer.SelectedCourt = v
            s.CourtSpoofer.CurrentCourt = v
            if s.CourtSpoofer.Enabled then pcall(applyCourtSpoofer) end
        end,
    })
    VisualsTab:CreateToggle({
        Name = "Enable court spoofer", Flag = "aethel_court",
        CurrentValue = s.CourtSpoofer.Enabled,
        Callback = function(v)
            s.CourtSpoofer.Enabled = v
            if v then pcall(applyCourtSpoofer) else pcall(resetCourtSpoofer) end
        end,
    })
    VisualsTab:CreateButton({
        Name = "Reset court",
        Callback = function()
            s.CourtSpoofer.Enabled = false
            s.CourtSpoofer.SelectedCourt = "None"
            s.CourtSpoofer.CurrentCourt = "None"
            pcall(resetCourtSpoofer)
        end,
    })

    VisualsTab:CreateSection("Nameplate & Title")
    VisualsTab:CreateToggle({
        Name = "Hide my nameplate & tags", Flag = "aethel_np_hide",
        CurrentValue = s.Visuals.HideOwnNameplate,
        Callback = function(v) s.Visuals.HideOwnNameplate = v; applyOwnNameplate() end,
    })
    VisualsTab:CreateInput({
        Name = "Custom username", Placeholder = "e.g. Aethel",
        CurrentValue = s.Visuals.CustomNameText, Flag = "aethel_np_name",
        Callback = function(text)
            s.Visuals.CustomNameText = text
            s.Visuals.CustomName = (text ~= "")
            applyOwnNameplate()
        end,
    })
    VisualsTab:CreateInput({
        Name = "Custom record", Placeholder = "e.g. 99-0",
        CurrentValue = s.Visuals.CustomRecordText, Flag = "aethel_np_rec",
        Callback = function(text)
            s.Visuals.CustomRecordText = text
            s.Visuals.CustomRecord = (text ~= "")
            applyOwnNameplate()
        end,
    })
    VisualsTab:CreateInput({
        Name = "Custom title", Placeholder = "e.g. Aethel Elite",
        CurrentValue = s.Visuals.CustomTitleText, Flag = "aethel_np_title",
        Callback = function(text)
            s.Visuals.CustomTitleText = text
            s.Visuals.CustomTitle = (text ~= "")
            applyOwnNameplate()
        end,
    })

    PrivacyTab:CreateSection("Device Spoofer")
    PrivacyTab:CreateToggle({
        Name = "Device spoofer", Flag = "aethel_dev", CurrentValue = s.Misc.DeviceSpoofer,
        Callback = function(v) s.Misc.DeviceSpoofer = v; SpoofDevice() end,
    })
    PrivacyTab:CreateDropdown({
        Name = "Device", Options = { "PC", "Mobile", "Gamepad" },
        CurrentValue = s.Misc.Device, Flag = "aethel_dev_sel",
        Callback = function(v) s.Misc.Device = v; SpoofDevice() end,
    })

    PrivacyTab:CreateSection("Logo Changer")
    for _, n in ipairs(LogoNames) do
        PrivacyTab:CreateToggle({
            Name = n .. " logo", Desc = "Shows the " .. n .. " icon on your own nametag (only you see it).",
            Flag = "aethel_logo_" .. n:lower(), CurrentValue = logoDefault(n),
            Callback = function(v) applyLogo(n, v) end,
        })
    end
    PrivacyTab:CreateButton({
        Name = "Reset logos",
        Callback = function() resetLogos() end,
    })

    PrivacyTab:CreateSection("Ball Changer")
    PrivacyTab:CreateDropdown({
        Name = "Select ball", Options = #BallNames > 0 and BallNames or { "None" },
        CurrentValue = s.BallChanger.SelectedBall, Flag = "aethel_ball_sel",
        Callback = function(v)
            s.BallChanger.SelectedBall = v
            s.BallChanger.CurrentBall = v
            if s.BallChanger.Enabled then pcall(applyBallChanger) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable ball changer", Flag = "aethel_ball",
        CurrentValue = s.BallChanger.Enabled,
        Callback = function(v)
            s.BallChanger.Enabled = v
            if v then pcall(applyBallChanger) else pcall(resetBallChanger) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset ball",
        Callback = function()
            s.BallChanger.Enabled = false
            s.BallChanger.SelectedBall = "ForceField"
            s.BallChanger.CurrentBall = "ForceField"
            pcall(resetBallChanger)
        end,
    })

    PrivacyTab:CreateSection("Trail Spoofer")
    PrivacyTab:CreateDropdown({
        Name = "Select trail", Options = #TrailNames > 0 and TrailNames or { "None" },
        CurrentValue = s.TrailSpoofer.SelectedTrail, Flag = "aethel_trail_sel",
        Callback = function(v)
            s.TrailSpoofer.SelectedTrail = v
            s.TrailSpoofer.CurrentTrail = v
            if s.TrailSpoofer.Enabled then pcall(applyTrailSpoofer) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable trail spoofer", Flag = "aethel_trail",
        CurrentValue = s.TrailSpoofer.Enabled,
        Callback = function(v)
            s.TrailSpoofer.Enabled = v
            if v then pcall(applyTrailSpoofer) else pcall(resetTrailSpoofer) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset trail",
        Callback = function()
            s.TrailSpoofer.Enabled = false
            s.TrailSpoofer.SelectedTrail = "None"
            s.TrailSpoofer.CurrentTrail = "None"
            pcall(resetTrailSpoofer)
        end,
    })

    PrivacyTab:CreateSection("Ball Aura Spoofer")
    PrivacyTab:CreateDropdown({
        Name = "Select aura", Options = #AuraNames > 0 and AuraNames or { "None" },
        CurrentValue = s.BallAura.SelectedAura, Flag = "aethel_aura_sel",
        Callback = function(v)
            s.BallAura.SelectedAura = v
            s.BallAura.CurrentAura = v
            if s.BallAura.Enabled then pcall(applyBallAura) end
        end,
    })
    PrivacyTab:CreateToggle({
        Name = "Enable ball aura spoofer", Flag = "aethel_aura",
        CurrentValue = s.BallAura.Enabled,
        Callback = function(v)
            s.BallAura.Enabled = v
            if v then pcall(applyBallAura) else pcall(resetBallAura) end
        end,
    })
    PrivacyTab:CreateButton({
        Name = "Reset ball aura",
        Callback = function()
            s.BallAura.Enabled = false
            s.BallAura.SelectedAura = "None"
            s.BallAura.CurrentAura = "None"
            pcall(resetBallAura)
        end,
    })

    UtilityTab:CreateSection("Anti Moderator")
    UtilityTab:CreateToggle({
        Name = "Anti moderator", Desc = "Notifies when a moderator is in the server.",
        Flag = "aethel_mod", CurrentValue = s.Misc.AntiModerator,
        Callback = function(v)
            s.Misc.AntiModerator = v
            if v then startAntiMod() else stopAntiMod() end
        end,
    })

    UtilityTab:CreateSection("Config Saver")
    local ConfigName = "default"
    UtilityTab:CreateInput({
        Name = "Config name", Placeholder = "default",
        CurrentValue = "default", Flag = "aethel_cfg_name",
        Callback = function(v) ConfigName = (v ~= "") and v or "default" end,
    })
    UtilityTab:CreateButton({
        Name = "Save config",
        Callback = function()
            local ok = pcall(function() Window:SaveConfig(ConfigName) end)
            Notify({ title = "Config", content = ok and ("Saved: " .. ConfigName) or "Save failed.", duration = 3 })
        end,
    })
    UtilityTab:CreateButton({
        Name = "Load config",
        Callback = function()
            local ok = pcall(function() Window:LoadConfig(ConfigName) end)
            Notify({ title = "Config", content = ok and ("Loaded: " .. ConfigName) or "Load failed.", duration = 3 })
        end,
    })

    setAural = function(on)
        s.Shooting.AuralEnabled = (on == nil) and (not s.Shooting.AuralEnabled) or on
        MobileRefresh()
    end
    setGuard = function(on)
        s.Defending.AutoGuard = (on == nil) and (not s.Defending.AutoGuard) or on
        if s.Defending.AutoGuard then enableAutoGuard() else disableAutoGuard() end
        MobileRefresh()
    end
    setMagnet = function(on)
        s.Ball.BallMags = (on == nil) and (not s.Ball.BallMags) or on
        if s.Ball.BallMags then enableMagnet() else disableMagnet() end
        MobileRefresh()
    end
    setReach = function(on)
        s.Ball.BallReach = (on == nil) and (not s.Ball.BallReach) or on
        if s.Ball.BallReach then enableReach() else disableReach() end
        MobileRefresh()
    end
    setTPWalk = function(on)
        s.TPWalk.Enabled = (on == nil) and (not s.TPWalk.Enabled) or on
        if s.TPWalk.Enabled then enableTPWalk() else disableTPWalk() end
        MobileRefresh()
    end
    setMagV2 = function(on)
        s.MagV2.Enabled = (on == nil) and (not s.MagV2.Enabled) or on
        if s.MagV2.Enabled then enableMagV2() else disableMagV2() end
        MobileRefresh()
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local magKey = s.Ball.MagnetKeybind
        if magKey and input.KeyCode == Enum.KeyCode[magKey] then setMagnet() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.Shooting.AuralKeybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then setAural() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.Defending.GuardKeybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then setGuard() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local bind = s.HVH.Speed.Keybind
        local targetKey = (type(bind) == "string") and Enum.KeyCode[bind] or bind
        if input.KeyCode == targetKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == s.TPWalk.Keybind then setTPWalk() end
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == s.MagV2.Keybind then setMagV2() end
    end)

    if isMobile then
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "AethelHubMobile"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.DisplayOrder = 200
        pcall(function()
            if gethui then ScreenGui.Parent = gethui()
            else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        end)

        local Panel = Instance.new("Frame")
        Panel.Name = "Panel"
        Panel.Size = UDim2.fromOffset(52, 320)
        Panel.Position = UDim2.new(1, -64, 0.5, -160)
        Panel.BackgroundTransparency = 1
        Panel.Parent = ScreenGui

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 5)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Panel

        local function makeButton(label, order, onClick, isOn)
            local Button = Instance.new("TextButton")
            Button.Name = label
            Button.Size = UDim2.fromOffset(52, 40)
            Button.BackgroundColor3 = isOn and Color3.fromRGB(242, 140, 62) or Color3.fromRGB(22, 14, 36)
            Button.BackgroundTransparency = 0.05
            Button.Text = label
            Button.TextColor3 = isOn and Color3.fromRGB(24, 10, 40) or Color3.fromRGB(242, 232, 255)
            Button.TextSize = 12
            Button.Font = Enum.Font.GothamBold
            Button.AutoButtonColor = false
            Button.LayoutOrder = order
            Button.Parent = Panel
            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(1, 0)
            Corner.Parent = Button
            local Stroke = Instance.new("UIStroke")
            Stroke.Color = isOn and Color3.fromRGB(255, 185, 115) or Color3.fromRGB(92, 52, 132)
            Stroke.Thickness = 1.2
            Stroke.Transparency = 0.15
            Stroke.Parent = Button
            Button.MouseButton1Click:Connect(onClick)
            return Button, Stroke
        end

        local Aim, AimS = makeButton("Aim", 1, function() setAural() end, s.Shooting.AuralEnabled)
        local Guard, GuardS = makeButton("Guard", 2, function() setGuard() end, s.Defending.AutoGuard)
        local Mag, MagS = makeButton("Mag", 3, function() setMagnet() end, s.Ball.BallMags)
        local MagV2, MagV2S = makeButton("MagV2", 4, function() setMagV2() end, s.MagV2.Enabled)
        local Reach, ReachS = makeButton("Reach", 5, function() setReach() end, s.Ball.BallReach)
        local TPW, TPWS = makeButton("TPWalk", 6, function() setTPWalk() end, s.TPWalk.Enabled)

        local function paint(btn, stroke, on)
            btn.BackgroundColor3 = on and Color3.fromRGB(242, 140, 62) or Color3.fromRGB(22, 14, 36)
            btn.TextColor3 = on and Color3.fromRGB(24, 10, 40) or Color3.fromRGB(242, 232, 255)
            stroke.Color = on and Color3.fromRGB(255, 185, 115) or Color3.fromRGB(92, 52, 132)
        end

        MobileRefresh = function()
            paint(Aim, AimS, s.Shooting.AuralEnabled)
            paint(Guard, GuardS, s.Defending.AutoGuard)
            paint(Mag, MagS, s.Ball.BallMags)
            paint(MagV2, MagV2S, s.MagV2.Enabled)
            paint(Reach, ReachS, s.Ball.BallReach)
            paint(TPW, TPWS, s.TPWalk.Enabled)
        end

        local dragging = false
        local dragStart, startPos
        Panel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Panel.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        OnCleanup(function()
            pcall(function() ScreenGui:Destroy() end)
        end)
    end

    hvhStart()

    OnCleanup(function()
        pcall(disableAutoGuard)
        pcall(disableMagnet)
        pcall(disableMagV2)
        pcall(disableReach)
        pcall(disableTPWalk)
        pcall(hvhResetAll)
        pcall(hvhStop)
        pcall(resetBallChanger)
        pcall(resetTrailSpoofer)
        pcall(resetBallAura)
        pcall(resetGoalEffect)
        pcall(resetCourtSpoofer)
        pcall(stopAntiMod)
        pcall(baDisable)
        pcall(resetLogos)
        pcall(function() setShotIndicator(false) end)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end)
elseif isFF3 then
    -- ========================================================
    -- BRANCH: FOOTBALL FUSION 3  (Aethel UI + Aethel branding)
    -- Feature code below was written for another UI library; the small
    -- adapter right here maps it onto the Aethel (Airflow) UI.
    -- ========================================================
    local ff3ok, ff3err = pcall(function()
        local RealWindow = Airflow:CreateWindow({
            Name = "Aethel Hub",
            LoadingSubtitle = "Football Fusion 3",
            Theme = "AethelDusk",
            ToggleUIKeybind = "RightControl",
            ConfigurationSaving = { Enabled = true, FolderName = "AethelHub", FileName = "FootballFusion3" },
        })

        local TabIcons = {
            ["QB Aimbot"] = "crosshair", ["Catching"] = "circle", ["Player"] = "user",
            ["Physics"] = "activity", ["Visual"] = "eye", ["Defense"] = "shield",
            ["Automatics"] = "list", ["Misc"] = "settings",
        }
        local flagCount = 0
        local function nextFlag(name)
            flagCount += 1
            return "ff3_" .. tostring(flagCount) .. "_" .. tostring(name):gsub("[^%w]", "")
        end

        -- Element object: .Value reads the current value; writing .Value updates the UI too.
        local function makeElement(state, real)
            return setmetatable({}, {
                __index = function(_, k)
                    if k == "Value" then return state.v end
                    if k == "Set" or k == "SetValue" then
                        return function(_, v) state.v = v; if real[1] then pcall(function() real[1]:Set(v) end) end end
                    end
                    return nil
                end,
                __newindex = function(_, k, v)
                    if k == "Value" then
                        state.v = v
                        if real[1] then pcall(function() real[1]:Set(v) end) end
                    end
                end,
            })
        end

        local function wrapTab(tab)
            local T = {}
            function T:CreateToggle(o)
                local state, real = { v = o.Default == true }, {}
                real[1] = tab:CreateToggle({
                    Name = o.Name, Desc = o.Tip, Flag = nextFlag(o.Name), CurrentValue = state.v,
                    Callback = function(v) state.v = v and true or false; if o.Callback then pcall(o.Callback, state.v) end end,
                })
                return makeElement(state, real)
            end
            function T:CreateSlider(o)
                local state, real = { v = o.Default or o.Min or 0 }, {}
                real[1] = tab:CreateSlider({
                    Name = o.Name, Desc = o.Tip, Flag = nextFlag(o.Name),
                    Range = { o.Min or 0, o.Max or 100 }, Increment = o.Increment or 1,
                    Suffix = (o.Suffix ~= nil and o.Suffix ~= "") and (" " .. o.Suffix) or "",
                    CurrentValue = state.v,
                    Callback = function(v) state.v = tonumber(v) or state.v; if o.Callback then pcall(o.Callback, state.v) end end,
                })
                return makeElement(state, real)
            end
            function T:CreateDropdown(o)
                local state, real = { v = o.Default or (o.Options and o.Options[1]) }, {}
                real[1] = tab:CreateDropdown({
                    Name = o.Name, Desc = o.Tip, Flag = nextFlag(o.Name),
                    Options = o.Options, CurrentValue = state.v,
                    Callback = function(v)
                        if type(v) == "table" then v = v[1] end
                        if v ~= nil then state.v = v end
                        if o.Callback then pcall(o.Callback, state.v) end
                    end,
                })
                return makeElement(state, real)
            end
            function T:CreateKeybind(o)
                local state, real = { v = o.Default }, {}
                real[1] = tab:CreateKeybind({
                    Name = o.Name, Desc = o.Tip, Flag = nextFlag(o.Name), CurrentValue = state.v,
                    Callback = function(key)
                        if typeof(key) == "EnumItem" then state.v = key end
                        if o.Callback then pcall(o.Callback, state.v) end
                    end,
                })
                return makeElement(state, real)
            end
            function T:CreateButton(o)
                tab:CreateButton({ Name = o.Name, Desc = o.Tip, Callback = function() if o.Callback then o.Callback() end end })
            end
            function T:CreateDivider() end
            return T
        end

        local Window = {}
        function Window:CreateTab(o)
            return wrapTab(RealWindow:CreateTab({ Name = o.Name, Icon = TabIcons[o.Name] or "settings" }))
        end

        -- ---------------- Football Fusion 3 features ----------------
local ThrowingTab = Window:CreateTab({ Name = 'QB Aimbot', Icon = 'rbxassetid://6034684949' })

enableQbAimbot = ThrowingTab:CreateToggle({
    Name = 'Enable QB Aimbot',
    Default = false,
    Tip = 'Automatically aims passes at the best target for more accurate throws.',
})

throwAimbot = ThrowingTab:CreateToggle({
    Name = 'Throw To Mouse Aimbot',
    Default = false,
    Tip = 'Automatically aims passes toward your mouse position.',
})

autoChooseWr = ThrowingTab:CreateToggle({
    Name = 'Auto Choose Open Reciever',
    Default = false,
    Tip = 'Automatically selects the most open receiver for each throw.',
})

autoSelectThrowMode = ThrowingTab:CreateToggle({
    Name = 'Auto Select Throw Type',
    Default = false,
    Tip = 'Automatically chooses the best throw type for each pass.',
})

autoPower = ThrowingTab:CreateToggle({
    Name = 'Auto Power',
    Default = false,
    Tip = 'Automatically sets the optimal throw power.',
})

autoAngle = ThrowingTab:CreateToggle({
    Name = 'Auto Angle',
    Default = false,
    Tip = 'Automatically adjusts throw angle for better accuracy.',
})

highPowerOnly = ThrowingTab:CreateToggle({
    Name = 'High Power Only',
    Default = false,
    Tip = 'Only uses high-power throws when passing.',
})

antiDB = ThrowingTab:CreateToggle({
    Name = 'Anti DB',
    Default = false,
    Tip = 'Avoids throws that defenders can easily intercept.',
})

antiDBThreshold = ThrowingTab:CreateSlider({
    Name = 'Anti DB Threshold',
    Min = 0,
    Max = 15,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how aggressively defender coverage is avoided.',
})

antiOOB = ThrowingTab:CreateToggle({
    Name = 'Anti OOB',
    Default = false,
    Tip = 'Prevents throws that may lead receivers out of bounds.',
})

antiOOBThreshold = ThrowingTab:CreateSlider({
    Name = 'Anti OOB Threshold',
    Min = 0,
    Max = 15,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how close targets can be to the sideline.',
})

throwLeadOffset = ThrowingTab:CreateSlider({
    Name = 'Throw Lead Offset',
    Min = -10,
    Max = 10,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Adjusts how far ahead passes are led.',
})

throwHeightOffset = ThrowingTab:CreateSlider({
    Name = 'Throw Height Offset',
    Min = -10,
    Max = 10,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Adjusts the height of targeted throws.',
})

smartAim = ThrowingTab:CreateToggle({
    Name = 'Smart Aimbot',
    Default = true,
    Tip = 'Tracks real receiver speed and leads left/right cuts, beams crossing routes, and arcs dimes over defenders. Turn off for the old aimbot.',
})

smartLeadTune = ThrowingTab:CreateSlider({
    Name = 'Smart Lead Tuning',
    Min = 0.5,
    Max = 1.5,
    Default = 1,
    Increment = 0.01,
    Suffix = '',
    Tip = '1.00 = exact. Raise it if passes land behind receivers, lower it if they land in front.',
})

smartDBReach = ThrowingTab:CreateSlider({
    Name = 'Smart DB Reach',
    Min = 6,
    Max = 16,
    Default = 10,
    Increment = 0.5,
    Suffix = '',
    Tip = 'How high above a defender the ball must pass to clear him. Raise it if defenders still get hands on dimes.',
})

autoJuke = ThrowingTab:CreateToggle({
    Name = 'Auto Juke Rusher',
    Default = false,
    Tip = 'Automatically jukes nearby rushers before throwing.',
})

hideCards = ThrowingTab:CreateToggle({
    Name = 'Hide QB Aimbot Cards',
    Default = false,
    Tip = 'Hides QB Aimbot visual cards from the screen.',
})

autoChangePowerUI = ThrowingTab:CreateToggle({
    Name = 'Auto Change Power UI',
    Default = false,
    Tip = 'Automatically updates the power UI to match throws.',
})

autoJumpWhenThrow = ThrowingTab:CreateToggle({
    Name = 'Auto Jump Before Throw',
    Default = false,
    Tip = 'Automatically jumps before releasing the ball.',
})

autoThrowAfterSack = ThrowingTab:CreateToggle({
    Name = 'Auto Throw Before Getting Sacked',
    Default = false,
    Tip = 'Automatically throws the ball when a sack is imminent.',
})

dimeKeybind = ThrowingTab:CreateKeybind({
    Name = 'Dime Mode Keybind',
    Default = Enum.KeyCode.One,
    Tip = 'Switches to Dime throw mode.',
})

magKeybind = ThrowingTab:CreateKeybind({
    Name = 'Mag Mode Keybind',
    Default = Enum.KeyCode.Two,
    Tip = 'Switches to Mag throw mode.',
})

diveKeybind = ThrowingTab:CreateKeybind({
    Name = 'Dive Mode Keybind',
    Default = Enum.KeyCode.Three,
    Tip = 'Switches to Dive throw mode.',
})

jumpKeybind = ThrowingTab:CreateKeybind({
    Name = 'Jump Mode Keybind',
    Default = Enum.KeyCode.Four,
    Tip = 'Switches to Jump throw mode.',
})

bulletKeybind = ThrowingTab:CreateKeybind({
    Name = 'Bullet Mode Keybind',
    Default = Enum.KeyCode.Five,
    Tip = 'Switches to Bullet throw mode.',
})

throwBallAwayKeybind = ThrowingTab:CreateKeybind({
    Name = 'Throw Ball Away Keybind',
    Default = Enum.KeyCode.T,
    Tip = 'Instantly throws the ball away.',
})

increaseAngleKeybind = ThrowingTab:CreateKeybind({
    Name = 'Increase Angle Keybind',
    Default = Enum.KeyCode.R,
    Tip = 'Increases the current throw angle.',
})

decreaseAngleKeybind = ThrowingTab:CreateKeybind({
    Name = 'Decrease Angle Keybind',
    Default = Enum.KeyCode.F,
    Tip = 'Decreases the current throw angle.',
})

lockKeybind = ThrowingTab:CreateKeybind({
    Name = 'Lock To Target Keybind',
    Default = Enum.KeyCode.Z,
    Tip = 'Locks passes onto the current target.',
})

local players = game:GetService('Players')
local replicatedStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local userInputService = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local stats = game:GetService('Stats')
local camera = workspace.CurrentCamera
local lp = players.LocalPlayer
if not lp then
    players:GetPropertyChangedSignal('LocalPlayer'):Wait()
    lp = players.LocalPlayer
end
local mouse = lp:GetMouse()

local isPractice = (game.PlaceId == 81310542478972)
if isPractice then
    autoJuke.Value = false
end

local targetLocked = false
local lockedTarget = nil

local RouteData = {}
local HUDCards = {}
local rusherHighlights = {}
local numCards = 0

local leadDime = 8.5
local leadMag = 8.6
local leadDive = 8.5
local leadJump = 8.4
local leadBullet = 2.5 

local yLeadDime = 1.2
local yLeadMag = 1.0
local yLeadDive = 1.5
local yLeadJump = 2.0
local yLeadBullet = -0.8

local ModeOrder = {'Bullet', 'Dime', 'Dive', 'Jump', 'Mag'}

local QBKeybinds = {
    [dimeKeybind.Value] = 'Dime',
    [magKeybind.Value] = 'Mag',
    [diveKeybind.Value] = 'Dive',
    [jumpKeybind.Value] = 'Jump',
    [bulletKeybind.Value] = 'Bullet'
}

local customHeight = { Value = 0 }

local target = nil
local lastValidTarget = nil
local targetLeadPos = nil
local highlight = nil
local direction = Vector3.new(0, 1, 0)
local power = 60
local angle = 45
local airtime = 0
local isThrowing = false
local isThrowingAway = false
local firedRemote = false
local modeIndex = 1
local smoothedJukeDir = Vector3.zero

local lockedMousePos = nil

local LockToggleBtn = nil
local LockedLabel = nil

local attach0 = Instance.new('Attachment', workspace.Terrain)
local attach1 = Instance.new('Attachment', workspace.Terrain)

local beam = Instance.new('Beam')
beam.Attachment0 = attach0
beam.Attachment1 = attach1
beam.Segments = 7500
beam.Width0 = 1
beam.Width1 = 1
beam.FaceCamera = true
beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
beam.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.01, 0),
    NumberSequenceKeypoint.new(1, 0)
})
beam.Enabled = true
beam.Parent = workspace.Terrain

local posPart = Instance.new('Part', workspace.Terrain)
posPart.Anchored = true
posPart.CanCollide = false
posPart.CastShadow = false
posPart.Size = Vector3.new(3, 3, 3)
posPart.Shape = Enum.PartType.Ball
posPart.Color = Color3.fromRGB(0, 0, 0)

local hudFolder = nil
pcall(function()
    hudFolder = (gethui and gethui()) or game:GetService('CoreGui')
end)
if not hudFolder or (hudFolder.Name == 'CoreGui' and not pcall(function() Instance.new('Folder', hudFolder):Destroy() end)) then
    hudFolder = lp:WaitForChild('PlayerGui', 10)
end

local sg = Instance.new('ScreenGui')
sg.ResetOnSpawn = false
sg.Parent = hudFolder
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local container = Instance.new('CanvasGroup')
container.Size = UDim2.new(1, 0, 0, 100)
container.Position = UDim2.new(0.5, 0, 0.05, 0)
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundTransparency = 1
container.GroupTransparency = 1
container.Visible = true
container.Parent = sg

local hudVisible = false
local updateHUDVisibility = function(show)
    if show and not hudVisible then
        hudVisible = true
        tweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    elseif not show and hudVisible then
        hudVisible = false
        tweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 1}):Play()
    end
end

local containerScale = Instance.new('UIScale', container)

local updateScale = function()
    local vp = camera.ViewportSize
    local scale = (vp.X / 1100)
    containerScale.Scale = math.clamp(scale, 0.5, 1.2)
end

camera:GetPropertyChangedSignal('ViewportSize'):Connect(updateScale)
updateScale()

local layout = Instance.new('UIListLayout')
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = container

local assignFont = function(instance, font)
    pcall(function()
        instance.Font = font
    end)
end

local createCard = function(titleTxt)
    local card = Instance.new('Frame')
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0
    card.BorderSizePixel = 0
    
    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 18))
    })
    gradient.Rotation = 90
    gradient.Parent = card
    
    if titleTxt == 'Throw Type' then
        card.Size = UDim2.new(0, 110, 0, 80)
    else
        card.Size = UDim2.new(0, 95, 0, 80)
    end
    
    card.LayoutOrder = numCards
    card.Parent = container

    local corner = Instance.new('UICorner', card)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new('UIStroke', card)
    stroke.Color = Color3.fromRGB(80, 80, 85)
    stroke.Thickness = 1.000

    local padding = Instance.new('UIPadding', card)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)

    local title = Instance.new('TextLabel')
    title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1.000
    title.BorderSizePixel = 0
    title.Position = UDim2.new(0, 0, 0.70, 0)
    title.Size = UDim2.new(1, 0, 0, 15)
    assignFont(title, Enum.Font.GothamBold)
    title.Text = titleTxt
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Parent = card

    local valBtn = Instance.new('TextButton')
    valBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    valBtn.BackgroundTransparency = 1.000
    valBtn.BorderSizePixel = 0
    valBtn.Position = UDim2.new(0, 0, 0.15, 0)
    valBtn.Size = UDim2.new(1, 0, 0.5, 0)
    assignFont(valBtn, Enum.Font.GothamBold)
    valBtn.Text = '-'
    valBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    valBtn.TextScaled = true
    valBtn.AutoButtonColor = false
    valBtn.Parent = card

    if titleTxt == 'Throw Type' then
        local uiScale = Instance.new('UIScale', card)
        valBtn.MouseButton1Down:Connect(function()
            local c = lp.Character
            if not c or not c:FindFirstChild('Football') then return end
            tweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.9}):Play()
        end)
        valBtn.MouseButton1Up:Connect(function()
            local c = lp.Character
            if not c or not c:FindFirstChild('Football') then return end
            tweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
            modeIndex = modeIndex + 1
            if modeIndex > #ModeOrder then modeIndex = 1 end
        end)
    end

    if titleTxt == 'Player' then
        local lockedLbl = Instance.new('TextLabel')
        lockedLbl.Size = UDim2.new(1, 0, 0.25, 0)
        lockedLbl.Position = UDim2.new(0, 0, 0.05, 0)
        lockedLbl.BackgroundTransparency = 1
        lockedLbl.Text = 'LOCKED'
        lockedLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
        assignFont(lockedLbl, Enum.Font.GothamBold)
        lockedLbl.TextSize = 12
        lockedLbl.Visible = false
        lockedLbl.ZIndex = 2
        lockedLbl.Parent = card

        LockedLabel = lockedLbl

        local lockOverlay = Instance.new('TextButton')
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundTransparency = 1
        lockOverlay.Text = ''
        lockOverlay.ZIndex = 5
        lockOverlay.Parent = card

        lockOverlay.MouseButton1Click:Connect(function()
            local c = lp.Character
            if not c or not c:FindFirstChild('Football') then return end
            if target or targetLocked then
                targetLocked = not targetLocked
                if targetLocked then
                    lockedTarget = target
                    if LockedLabel then LockedLabel.Visible = true end
                else
                    lockedTarget = nil
                    if LockedLabel then LockedLabel.Visible = false end
                end
            end
        end)
        
        LockToggleBtn = valBtn
    end

    HUDCards[titleTxt] = valBtn
    numCards = numCards + 1
end

createCard('Angle')
createCard('Throw Type')
createCard('Player')
createCard('Airtime')
createCard('Power')

local getActiveBots = function()
    local bots = {}
    local npcwr = workspace:FindFirstChild('npcwr')
    if npcwr then
        local a = npcwr:FindFirstChild('a')
        if a then
            local bot1 = a:FindFirstChild('bot 1')
            if bot1 and bot1:IsA('Model') then table.insert(bots, bot1) end
        end
        local b = npcwr:FindFirstChild('b')
        if b then
            local bot3 = b:FindFirstChild('bot 3')
            if bot3 and bot3:IsA('Model') then table.insert(bots, bot3) end
        end
    end
    return bots
end

local performThrow = function()
    if not enableQbAimbot.Value then return end

    local character = lp.Character
    if not character then return end

    local football = character:FindFirstChildOfClass('Tool')
    if not football then return end

    local handle = football:FindFirstChild('Handle')
    if not handle then return end

    local remote = handle:FindFirstChild('RemoteEvent')
    if not remote then return end

    local head = character:FindFirstChild('Head')
    if not head then return end

    local root = character:FindFirstChild('HumanoidRootPart')
    if not root then return end

    local finalDirection = direction or Vector3.new(0, 1, 0)

    if isPractice then
        local arg = 'Clicked'
        local arg1 = head.Position
        local arg2 = head.Position + finalDirection * 10000
        local arg3 = tonumber(power) or 0
        remote:FireServer(arg, arg1, arg2, arg3)
    else
        local arg = 'Clicked'
        local arg1 = (root.CFrame * CFrame.new(0, 1.5, 0)).Position + Vector3.new(70000000)
        local arg2 = head.Position + finalDirection * 10000
        local arg3 = tonumber(power) or 0
        remote:FireServer(arg, arg1, arg2, arg3, 1)
    end
end

local findRoute = function(character)
    if not character then return 'stationary', Vector3.zero end
    local isPlayer = players:GetPlayerFromCharacter(character)
    local humanoid = character:FindFirstChild('Humanoid')
    local targetHRP = character:FindFirstChild('HumanoidRootPart')
    local qbChar = lp.Character
    local qbHRP = qbChar and qbChar:FindFirstChild('HumanoidRootPart')
    
    if not humanoid or not targetHRP or not qbHRP then 
        return 'stationary', Vector3.zero 
    end
    
    local moveDirection = Vector3.zero
    if isPlayer then
        moveDirection = humanoid.MoveDirection
    else
        local wtpDiff = humanoid.WalkToPoint - targetHRP.Position
        moveDirection = wtpDiff.Magnitude > 0.01 and wtpDiff.Unit or Vector3.zero
    end
    
    local toWR = targetHRP.Position - qbHRP.Position
    local distance = tonumber(toWR.Magnitude) or 0

    local toWRDir = Vector3.new(toWR.X, 0, toWR.Z)
    if toWRDir.Magnitude > 0.01 then
        toWRDir = toWRDir.Unit
    else
        toWRDir = Vector3.new(0, 0, 1)
    end

    local mdFlat = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    if mdFlat.Magnitude < 0.01 then
        return 'stationary', moveDirection
    end
    mdFlat = mdFlat.Unit

    local dot = tonumber(mdFlat:Dot(toWRDir)) or 0

    if dot > 0.75 then
        return 'go/fade', moveDirection
    elseif dot >= 0.25 and dot <= 0.75 then
        if distance <= 120 then return 'slant', moveDirection
        elseif distance <= 160 then return 'seam', moveDirection
        else return 'post/corner', moveDirection end
    elseif dot > -0.25 and dot < 0.25 then
        if distance <= 60 then return 'drag', moveDirection
        elseif distance <= 130 then return 'in/out', moveDirection
        else return 'flat', moveDirection end
    else
        if distance <= 50 then return 'hitch', moveDirection
        else return 'curl/comeback', moveDirection end
    end
end

local isWROpen = function(wrChar)
    if not wrChar then return false end
    local hrp = wrChar:FindFirstChild('HumanoidRootPart')
    if not hrp then return false end

    local isCovered = false
    local _, moveDir = findRoute(wrChar)
    
    local teamCount = 0
    pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)
    
    local checkDB = function(dbHRP)
        local toDB = dbHRP.Position - hrp.Position
        local dist = tonumber(toDB.Magnitude) or 0
        if dist < 5 then
            local routeDirXZ = Vector3.new(moveDir.X, 0, moveDir.Z)
            if (tonumber(routeDirXZ.Magnitude) or 0) > 0.01 then
                routeDirXZ = routeDirXZ.Unit
                local dot = tonumber(toDB.Unit:Dot(routeDirXZ)) or 0
                if dot > -0.7 then 
                    return true
                end
            else
                return true
            end
        end
        return false
    end

    local checkPR = function(dbHRP)
        local qbChar = lp.Character
        if not qbChar then return false end
        local qbHRP = qbChar:FindFirstChild('HumanoidRootPart')
        if not qbHRP then return false end
        
        local toPR = dbHRP.Position - qbHRP.Position
        local toWR = hrp.Position - qbHRP.Position
        local wrDist = tonumber(toWR.Magnitude) or 0
        local wrDir = toWR.Unit
        
        local proj = tonumber(toPR:Dot(wrDir)) or 0
        if proj > 2 and proj < (wrDist * 0.6) then
            local distToLine = tonumber((toPR - (wrDir * proj)).Magnitude) or 0
            if distToLine < 5.5 then
                return true
            end
        end
        return false
    end

    local plrs = players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= lp and plr.Character then
            local isEnemy = true
            if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team == plr.Team then
                isEnemy = false
            end
            if isEnemy then
                local dbHRP = plr.Character:FindFirstChild('HumanoidRootPart')
                if dbHRP and (checkDB(dbHRP) or checkPR(dbHRP)) then
                    isCovered = true
                    break
                end
            end
        end
    end

    if not isCovered then
        local bots = getActiveBots()
        for i = 1, #bots do
            local bot = bots[i]
            if bot ~= wrChar then
                local dbHRP = bot:FindFirstChild('HumanoidRootPart')
                if dbHRP and (checkDB(dbHRP) or checkPR(dbHRP)) then
                    isCovered = true
                    break
                end
            end
        end
    end

    return not isCovered
end

local getTarget = function()
    if isThrowing and target then return target end
    
    if targetLocked and lockedTarget and lockedTarget:FindFirstChild('HumanoidRootPart') then
        return lockedTarget
    elseif targetLocked then
        targetLocked = false
        lockedTarget = nil
    end

    local potentialTargets = {}
    local teamCount = 0
    pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)

    local plrs = players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
            local isTeammate = true
            if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team ~= plr.Team then
                isTeammate = false
            end
            
            if isTeammate then
                local eHum = plr.Character:FindFirstChildOfClass('Humanoid')
                if not eHum or not eHum.Sit then
                    table.insert(potentialTargets, plr.Character)
                end
            end
        end
    end

    local bots = getActiveBots()
    for i = 1, #bots do
        local bot = bots[i]
        if bot:FindFirstChild('HumanoidRootPart') then
            local eHum = bot:FindFirstChildOfClass('Humanoid')
            if not eHum or not eHum.Sit then
                table.insert(potentialTargets, bot)
            end
        end
    end

    if #potentialTargets == 0 then return nil end

    if autoChooseWr.Value then
        local bestAutoTarget = nil
        local bestAutoDist = math.huge
        local qbHRP = lp.Character and lp.Character:FindFirstChild('HumanoidRootPart')
        local qbPos = qbHRP and qbHRP.Position or Vector3.zero

        for i = 1, #potentialTargets do
            local char = potentialTargets[i]
            local hrp = char:FindFirstChild('HumanoidRootPart')
            if hrp then
                local _, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen and isWROpen(char) then
                    local dist = tonumber((hrp.Position - qbPos).Magnitude) or 0
                    if dist < bestAutoDist then
                        bestAutoDist = dist
                        bestAutoTarget = char
                    end
                end
            end
        end
        
        if bestAutoTarget then
            return bestAutoTarget
        end
    end

    local mousePos2D = userInputService:GetMouseLocation()
    local bestManualTarget = nil
    local bestMouseDist = math.huge

    for i = 1, #potentialTargets do
        local char = potentialTargets[i]
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if hrp then
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist = tonumber((Vector2.new(screenPos.X, screenPos.Y) - mousePos2D).Magnitude) or 0
                if dist < bestMouseDist then
                    bestMouseDist = dist
                    bestManualTarget = char
                end
            end
        end
    end

    return bestManualTarget
end

local calculateRouteDirection = function(targetChar)
    if not targetChar then return 'Mag' end
    local targetHRP = targetChar:FindFirstChild('HumanoidRootPart')
    if not targetHRP then return 'Mag' end
    
    local lpChar = lp.Character
    local lpHRP = lpChar and lpChar:FindFirstChild('HumanoidRootPart')
    if not lpHRP then return 'Mag' end

    local route, moveDir = findRoute(targetChar)
    local dist = tonumber((targetHRP.Position - lpHRP.Position).Magnitude) or 0
    if dist < 40 then return 'Bullet' end
    
    local dbDistance = math.huge
    local teamCount = 0
    pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)

    local plrs = players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= lp and plr.Character then
            local eHRP = plr.Character:FindFirstChild('HumanoidRootPart')
            if eHRP and eHRP ~= targetHRP then
                local isEnemy = true
                if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team == plr.Team then
                    isEnemy = false
                end
                if isEnemy then
                    local d = tonumber((eHRP.Position - targetHRP.Position).Magnitude) or 0
                    if d < dbDistance then dbDistance = d end
                end
            end
        end
    end

    local bots = getActiveBots()
    for i = 1, #bots do
        local bot = bots[i]
        local bHRP = bot:FindFirstChild('HumanoidRootPart')
        if bHRP and bHRP ~= targetHRP then
            local d = tonumber((bHRP.Position - targetHRP.Position).Magnitude) or 0
            if d < dbDistance then dbDistance = d end
        end
    end

    local within = function(tbl, val)
        for i = 1, #tbl do
            if tbl[i] == val then return true end
        end
        return false
    end

    local forwardRoutes = {'go/fade', 'post/corner', 'seam', 'curl/comeback', 'stationary'}
    local sidewayRoutes = {'in/out', 'flat', 'wheel'}
    
    if route == 'slant' or route == 'hitch' or route == 'drag' or route == 'in/out' or route == 'flat' then
        return 'Bullet'
    elseif within(forwardRoutes, route) then
        if dbDistance > 5 then return ((tonumber(angle) or 45) < 40) and 'Jump' or 'Dime'
        elseif dbDistance > 2 then return 'Dive' end
        return 'Mag'
    elseif within(sidewayRoutes, route) then
        if dbDistance > 4 then return 'Dime' end
        return 'Jump'
    end
    return 'Dime'
end

local getModeLead = function(modeName)
    if modeName == 'Dime' then return leadDime
    elseif modeName == 'Mag' then return leadMag
    elseif modeName == 'Dive' then return leadDive
    elseif modeName == 'Jump' then return leadJump
    elseif modeName == 'Bullet' then return leadBullet
    end
    return 8.6
end

local getModeYLead = function(modeName)
    if modeName == 'Dime' then return yLeadDime
    elseif modeName == 'Mag' then return yLeadMag
    elseif modeName == 'Dive' then return yLeadDive
    elseif modeName == 'Jump' then return yLeadJump
    elseif modeName == 'Bullet' then return yLeadBullet
    end
    return 0
end

local getPing = function()
    local networkPing = 0
    pcall(function() networkPing = tonumber(lp:GetNetworkPing()) or 0 end)
    local dataPing = 0
    pcall(function() dataPing = (tonumber(stats.Network.ServerStatsItem['Data Ping']:GetValue()) or 0) / 1000 end)
    if dataPing == 0 then dataPing = networkPing end
    return networkPing + dataPing
end

local solveKinematics = function(origin, targetPos, gravityMag)
    local g = tonumber(gravityMag) or 28
    local displacement = targetPos - origin
    local x = tonumber(Vector3.new(displacement.X, 0, displacement.Z).Magnitude) or 0
    local y = tonumber(displacement.Y) or 0
    
    local inner = (x^2) + (y^2)
    local root = tonumber(math.sqrt(math.max(inner, 0))) or 0
    
    local baseAngleRad = math.rad(45)
    if x > 0.01 then
        local atanRes = tonumber(math.atan((y + root) / x)) or baseAngleRad
        if atanRes and atanRes == atanRes then
            baseAngleRad = atanRes
        end
    end
    
    local angleRad = tonumber(math.clamp(baseAngleRad * 0.85, math.rad(-15), math.rad(65))) or 0
    
    local cosA = tonumber(math.cos(angleRad)) or 1
    local tanA = tonumber(math.tan(angleRad)) or 0
    
    local v0 = 95
    local denom = 2 * (cosA^2) * (x * tanA - y)
    
    if denom > 0.001 then
        local num = g * (x^2)
        local res = tonumber(math.sqrt(num / denom)) or v0
        if res and res == res and res ~= math.huge then
            v0 = res
        end
    end
    
    local angleDeg = tonumber(math.deg(angleRad)) or 45
    return v0, angleDeg
end

-- ============================================================
-- SMART AIMBOT: measured-velocity intercept, beam for crossing
-- routes, and arcs that clear defenders.
-- ============================================================
local SMART_G = 28
local velTrack = setmetatable({}, { __mode = 'k' })

local flatDist = function(a, b)
    return Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
end

local trackVel = function(hrp)
    local now = os.clock()
    local pos = hrp.Position
    local e = velTrack[hrp]
    if not e or (now - e.t) > 0.5 then
        local seed = Vector3.zero
        local hum = hrp.Parent and hrp.Parent:FindFirstChildOfClass('Humanoid')
        if hum then
            local md = hum.MoveDirection
            if players:GetPlayerFromCharacter(hrp.Parent) == nil then
                local w = hum.WalkToPoint - hrp.Position
                md = Vector3.new(w.X, 0, w.Z)
                md = md.Magnitude > 0.5 and md.Unit or Vector3.zero
            end
            local flat = Vector3.new(md.X, 0, md.Z)
            if flat.Magnitude > 0.01 then seed = flat.Unit * hum.WalkSpeed end
        end
        e = { pos = pos, t = now, vel = seed, speed = seed.Magnitude, acc = 0 }
        velTrack[hrp] = e
        return e
    end
    local dt = now - e.t
    if dt < 1 / 240 then return e end
    local inst = (pos - e.pos) / dt
    inst = Vector3.new(inst.X, 0, inst.Z)
    if inst.Magnitude > 80 then
        e.vel, e.speed, e.acc = Vector3.zero, 0, 0
    else
        local newVel = e.vel:Lerp(inst, 1 - math.exp(-dt / 0.07))
        local newSpeed = newVel.Magnitude
        local accInst = (newSpeed - e.speed) / dt
        e.acc = e.acc + (accInst - e.acc) * (1 - math.exp(-dt / 0.12))
        e.vel, e.speed = newVel, newSpeed
    end
    e.pos, e.t = pos, now
    return e
end

local getDefenders = function(excludeChar)
    local list = {}
    local teamCount = 0
    pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)
    local plrs = players:GetPlayers()
    for i = 1, #plrs do
        local plr = plrs[i]
        if plr ~= lp and plr.Character and plr.Character ~= excludeChar then
            local isEnemy = true
            if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team == plr.Team then
                isEnemy = false
            end
            if isEnemy then
                local h = plr.Character:FindFirstChild('HumanoidRootPart')
                local hum = plr.Character:FindFirstChildOfClass('Humanoid')
                if h and (not hum or hum.Health > 0) then
                    trackVel(h)
                    table.insert(list, h)
                end
            end
        end
    end
    return list
end

-- Where the receiver will be after Tt seconds (handles hard stops / cuts).
local predictDisp = function(e, Tt, tune)
    if e.speed < 1.5 then return Vector3.zero end
    local dir = e.vel.Unit
    local acc = math.clamp(e.acc, -120, 0)
    local dist
    if acc < -25 then
        local ts = e.speed / -acc
        local tt = math.min(Tt, ts)
        dist = e.speed * tt + 0.5 * acc * tt * tt
    else
        dist = e.speed * Tt
    end
    return dir * dist * tune
end

local bulletAngleFor = function(origin, pos)
    local h = flatDist(origin, pos)
    local v = pos.Y - origin.Y
    local t = h / 95
    local drop = 0.5 * SMART_G * t * t
    return math.clamp(math.deg(math.atan2(v + drop, h)), -15, 45)
end

local flightTime = function(origin, pos, isBullet)
    local h = flatDist(origin, pos)
    if isBullet then
        local hv = 95 * math.cos(math.rad(bulletAngleFor(origin, pos)))
        return h / math.max(hv, 1)
    end
    local v0, aDeg = solveKinematics(origin, pos, SMART_G)
    return h / math.max(v0 * math.cos(math.rad(aDeg)), 1)
end

local powerForAngle = function(origin, pos, aDeg)
    local x = flatDist(origin, pos)
    local y = pos.Y - origin.Y
    local a = math.rad(aDeg)
    local c, tn = math.cos(a), math.tan(a)
    local denom = 2 * c * c * (x * tn - y)
    if denom <= 0.001 then return nil end
    local p = math.sqrt(SMART_G * x * x / denom)
    if p ~= p or p == math.huge then return nil end
    return p
end

-- Intercept point: iterates flight time so the ball lands where the receiver will be.
local smartLead = function(origin, targetHRP, e, headY, isBullet, modeName, fixedArc, defs)
    local tune = tonumber(smartLeadTune.Value) or 1
    local ping = tonumber(getPing()) or 0
    local pos = targetHRP.Position
    local baseY = headY + (isBullet and 0 or getModeYLead(modeName)) + (tonumber(throwHeightOffset.Value) or 0)
    local lead = Vector3.new(pos.X, baseY, pos.Z)
    local T = 0.6
    for _ = 1, 5 do
        local disp = predictDisp(e, T + ping, tune)
        lead = Vector3.new(pos.X + disp.X, baseY, pos.Z + disp.Z)
        if fixedArc then
            T = flatDist(origin, lead) / math.max(fixedArc.p * math.cos(math.rad(fixedArc.a)), 1)
        else
            T = flightTime(origin, lead, isBullet)
        end
    end

    -- Contested: lead the catch point away from the nearest defender.
    if defs then
        local nearest, nd = nil, 7
        for i = 1, #defs do
            local d = defs[i]
            local de = velTrack[d]
            local dv = de and de.vel or Vector3.zero
            local dp = d.Position + Vector3.new(dv.X, 0, dv.Z) * (T + ping * 0.5)
            local dd = Vector3.new(lead.X - dp.X, 0, lead.Z - dp.Z).Magnitude
            if dd < nd then nearest, nd = dp, dd end
        end
        if nearest then
            local away = Vector3.new(lead.X - nearest.X, 0, lead.Z - nearest.Z)
            if away.Magnitude < 0.1 then
                away = Vector3.new(-(lead.Z - origin.Z), 0, lead.X - origin.X)
            end
            if away.Magnitude > 0.01 then
                lead = lead + away.Unit * math.min(3.5, 7 - nd)
            end
        end
    end

    if e.speed >= 1.5 then
        lead = lead + e.vel.Unit * (tonumber(throwLeadOffset.Value) or 0)
    end
    return lead, T
end

-- Best throw type for the situation (only used when Auto Select Throw Type is on).
local smartMode = function(origin, targetHRP, e, defs)
    local toT = Vector3.new(targetHRP.Position.X - origin.X, 0, targetHRP.Position.Z - origin.Z)
    local dist = toT.Magnitude
    if dist < 40 then return 'Bullet' end
    if e.speed >= 6 and toT.Magnitude > 0.01 then
        local dot = e.vel.Unit:Dot(toT.Unit)
        if math.abs(dot) < 0.6 or dot <= -0.6 then
            return 'Bullet' -- crossing / coming back: beam it
        end
    end
    for i = 1, #defs do
        if flatDist(targetHRP.Position, defs[i].Position) < 4.5 then return 'Jump' end
    end
    return 'Dime'
end

-- Counts how often the ball is inside a defender's reach on the way to the receiver.
local arcThreat = function(origin, lead, p, aDeg, T, defs, ping, reach)
    local hv = Vector3.new(lead.X - origin.X, 0, lead.Z - origin.Z)
    if hv.Magnitude < 0.01 then return 0 end
    local hDir = hv.Unit
    local a = math.rad(aDeg)
    local vh, vy = p * math.cos(a), p * math.sin(a)
    local threats = 0
    local N = 18
    for i = 3, N do
        if i / N > 0.9 then break end
        local t = T * (i / N)
        local bp = origin + hDir * (vh * t) + Vector3.new(0, vy * t - 0.5 * SMART_G * t * t, 0)
        if flatDist(origin, bp) > 15 then
            for j = 1, #defs do
                local d = defs[j]
                local de = velTrack[d]
                local dv = de and de.vel or Vector3.zero
                local dp = d.Position + Vector3.new(dv.X, 0, dv.Z) * (t + ping * 0.5)
                local hd = Vector3.new(bp.X - dp.X, 0, bp.Z - dp.Z).Magnitude
                if hd < 6 and bp.Y < d.Position.Y + reach then threats = threats + 1 end
            end
        end
    end
    return threats
end

-- Picks the lowest (fastest) arc that still clears every defender.
local smartArc = function(origin, targetHRP, e, headY, modeName, defs, baseAngle)
    local ping = tonumber(getPing()) or 0
    local reach = tonumber(smartDBReach.Value) or 10
    local far = {}
    for i = 1, #defs do
        if flatDist(origin, defs[i].Position) > 22 then far[#far + 1] = defs[i] end
    end
    local best = nil
    local a = math.clamp(tonumber(baseAngle) or 35, 12, 60)
    while a <= 75 do
        local lead, T = smartLead(origin, targetHRP, e, headY, false, modeName, nil, defs)
        local p
        for _ = 1, 3 do
            p = powerForAngle(origin, lead, a)
            if not p or p > 95 then break end
            lead, T = smartLead(origin, targetHRP, e, headY, false, modeName, { p = p, a = a }, defs)
        end
        if p then p = powerForAngle(origin, lead, a) end
        if p and p <= 95 and p >= 10 then
            local th = (#far > 0) and arcThreat(origin, lead, p, a, T, far, ping, reach) or 0
            if not best or th < best.th then
                best = { p = p, a = a, lead = lead, th = th }
            end
            if th == 0 then break end
        end
        a = a + 5
    end
    return best
end


local autoAim = function(targetHRP)
    local head = lp.Character:FindFirstChild('Head')
    local origin = head and head.Position or lp.Character.HumanoidRootPart.Position
    
    local targetChar = targetHRP.Parent
    local targetHeadObj = targetChar and targetChar:FindFirstChild('Head')
    local targetHead = targetHeadObj and targetHeadObj.Position or targetHRP.Position + Vector3.new(0, 1.5, 0)

    local smartOn = (smartAim and smartAim.Value == true) or false
    local smartE, smartDefs
    if smartOn then
        local okS = pcall(function()
            smartE = trackVel(targetHRP)
            smartDefs = getDefenders(targetChar)
            if autoSelectThrowMode.Value then
                local m = smartMode(origin, targetHRP, smartE, smartDefs)
                for i = 1, #ModeOrder do
                    if ModeOrder[i] == m then modeIndex = i break end
                end
            end
        end)
        if not okS or not smartE then smartOn = false end
    end

    local moveDir = Vector3.zero
    local targetHum = targetChar and targetChar:FindFirstChildOfClass('Humanoid')
    if targetHum then
        local isBot = targetChar:FindFirstAncestor('npcwr') ~= nil
        if isBot then
            local wtpDiff = targetHum.WalkToPoint - targetHRP.Position
            local dir = Vector3.new(wtpDiff.X, 0, wtpDiff.Z)
            moveDir = dir.Magnitude > 0.1 and dir.Unit or Vector3.zero
        else
            local md = targetHum.MoveDirection
            local flatMd = Vector3.new(md.X, 0, md.Z)
            moveDir = flatMd.Magnitude > 0.01 and flatMd.Unit or Vector3.zero
        end
    end
    
    local ping = tonumber(getPing()) or 0
    local speed = 20
    
    local modeName = ModeOrder[modeIndex]
    local isChestPass = (modeName == 'Bullet' or target and (findRoute(target) == 'slant' or findRoute(target) == 'drag' or findRoute(target) == 'in/out' or findRoute(target) == 'flat' or findRoute(target) == 'hitch' or findRoute(target) == 'curl/comeback'))
    local routeStr = target and findRoute(target) or 'go/fade'
    if smartOn then isChestPass = (modeName == 'Bullet') end
    
    local activePower = tonumber(power) or 60
    if modeName == 'Bullet' or (autoPower.Value and isChestPass) or highPowerOnly.Value then
        activePower = 95
    end
    
    local lDivisor = 60
    if activePower > 75 then
        lDivisor = 60 + ((activePower - 75) * 1.5)
    end
    
    local distToTarget = tonumber((targetHRP.Position - origin).Magnitude) or 0
    local estFlightTime = distToTarget / (tonumber(lDivisor) or 60)
    
    local currentHVel = activePower * (tonumber(math.cos(math.rad(tonumber(angle) or 45))) or 1)
    if currentHVel < 30 then currentHVel = 55 end
    
    local estHVel = (modeName == 'Bullet' or isChestPass) and 90 or currentHVel
    
    local modeLeadScale = (tonumber(getModeLead(modeName)) or 8.6) * 3.05
    local selectedModeYLead = tonumber(getModeYLead(modeName)) or 0
    
    local routeMultipliers = {
        ['slant'] = 0.45,
        ['drag'] = 0.6,
        ['in/out'] = 0.65,
        ['flat'] = 0.65,
        ['wheel'] = 0.9,
        ['go/fade'] = 1.0,
        ['post/corner'] = 0.85,
        ['seam'] = 0.85,
        ['hitch'] = 0.1,
        ['curl/comeback'] = 0.1,
        ['stationary'] = 0.0
    }
    local rMult = tonumber(routeMultipliers[routeStr]) or 1.0
    
    local dirUnit = moveDir.Magnitude > 0.01 and moveDir.Unit or Vector3.zero
    
    local targetBase = (isChestPass or modeName == 'Bullet') and targetHRP.Position or targetHead
    
    local standingStill = (routeStr == 'stationary')

    local smartActive = false
    if smartOn then
        local okL, sLead = pcall(smartLead, origin, targetHRP, smartE, targetHead.Y, modeName == 'Bullet', modeName, nil, smartDefs)
        if okL and sLead then
            leadPos = sLead
            smartActive = true
            standingStill = false
        end
    end

    if smartActive then
        -- lead already computed by the smart aimbot
    elseif standingStill then
        leadPos = targetHead
    else
        leadPos = targetBase + (moveDir * speed * estFlightTime * rMult) + (moveDir * speed * ping * rMult) + (dirUnit * modeLeadScale * rMult)
        leadPos = leadPos + (dirUnit * (tonumber(throwLeadOffset.Value) or 0))
        
        if isChestPass or modeName == 'Bullet' then
            leadPos = Vector3.new(leadPos.X, targetHead.Y, leadPos.Z)
            selectedModeYLead = 0
        end
        
        leadPos = leadPos + Vector3.new(0, selectedModeYLead, 0)
        leadPos = leadPos + Vector3.new(0, tonumber(throwHeightOffset.Value) or 0, 0)
        
        if routeStr == 'curl/comeback' or routeStr == 'hitch' then
            leadPos = leadPos + Vector3.new(0, -5, 0)
        end
    end
    
    local forceAutoAngle = (modeName == 'Bullet' or isChestPass or (tonumber(power) or 60) == 95 or highPowerOnly.Value)
    if not autoAngle.Value and not forceAutoAngle then
        leadPos = leadPos + Vector3.new(0, tonumber(customHeight.Value) or 0, 0)
    end
    
    if antiDB.Value then
        local pushVec = Vector3.zero
        local plrs = players:GetPlayers()
        local teamCount = 0
        pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)

        for i = 1, #plrs do
            local plr = plrs[i]
            if plr ~= lp and plr.Character then
                local isEnemy = true
                if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team == plr.Team then
                    isEnemy = false
                end
                if isEnemy then
                    local eHRP = plr.Character:FindFirstChild('HumanoidRootPart')
                    if eHRP then
                        local dist = tonumber(Vector3.new(eHRP.Position.X - leadPos.X, 0, eHRP.Position.Z - leadPos.Z).Magnitude) or 0
                        if dist < (tonumber(antiDBThreshold.Value) or 15) then
                            local away = (leadPos - eHRP.Position)
                            away = Vector3.new(away.X, 0, away.Z)
                            if away.Magnitude > 0 then
                                pushVec = pushVec + (away.Unit * ((tonumber(antiDBThreshold.Value) or 15) - dist))
                            end
                        end
                    end
                end
            end
        end
        leadPos = pushVec + leadPos
    end

    local fPos = Vector3.zero
    local field = workspace:FindFirstChild('Models')
    if field then field = field:FindFirstChild('Field') end
    if field then field = field:FindFirstChild('Ground') end
    if field then fPos = field.Position end

    if antiOOB.Value and fPos ~= Vector3.zero then
        local halfWidth = 75 - (tonumber(antiOOBThreshold.Value) or 5)
        local halfLength = 175 - (tonumber(antiOOBThreshold.Value) or 5)
        leadPos = Vector3.new(
            math.clamp(leadPos.X, fPos.X - halfWidth, fPos.X + halfWidth),
            leadPos.Y,
            math.clamp(leadPos.Z, fPos.Z - halfLength, fPos.Z + halfLength)
        )
    end
    
    targetLeadPos = leadPos
    
    local gMag = 28 
    local calcPower, calcAngle = solveKinematics(origin, leadPos, gMag)
    calcPower = tonumber(calcPower) or 95
    calcAngle = tonumber(calcAngle) or 45
    
    if standingStill and modeName ~= 'Bullet' and not highPowerOnly.Value then
        local dynamicThreshold = tonumber(math.clamp(4 + (distToTarget * 0.08), 5, 14)) or 10
        if calcAngle > dynamicThreshold then
            local displacement = leadPos - origin
            local x = tonumber(Vector3.new(displacement.X, 0, displacement.Z).Magnitude) or 0
            local y = tonumber(displacement.Y) or 0
            local aRad = tonumber(math.rad(dynamicThreshold)) or 0.1
            local denom = 2 * (math.cos(aRad)^2) * (x * math.tan(aRad) - y)
            
            if denom > 0.001 then
                local newPwr = tonumber(math.sqrt((gMag * x^2) / denom)) or calcPower
                if newPwr == newPwr and newPwr ~= math.huge then
                    calcAngle = dynamicThreshold
                    calcPower = newPwr
                end
            end
        end
    end
    
    if highPowerOnly.Value then
        power = 95
        local displacement = leadPos - origin
        local x = tonumber(Vector3.new(displacement.X, 0, displacement.Z).Magnitude) or 0
        local y = tonumber(displacement.Y) or 0
        
        local v2 = 95^2
        local v4 = 95^4
        local gx = gMag * x
        local discriminant = v4 - gMag * (gMag * x^2 + 2 * y * v2)
        
        if discriminant >= 0 then
            angle = tonumber(math.clamp(math.deg(math.atan((v2 - math.sqrt(discriminant)) / gx)) * 0.94, -15, 85)) or 45
        else
            angle = 45
        end
    elseif modeName == 'Bullet' or (autoPower.Value and isChestPass) then
        power = 95
        local displacement = leadPos - origin
        local h = tonumber(Vector3.new(displacement.X, 0, displacement.Z).Magnitude) or 0
        local v = tonumber(displacement.Y) or 0
        local t_est = h / 95
        local drop = 0.5 * 28 * t_est * t_est
        angle = tonumber(math.clamp(math.deg(math.atan2(v + drop, h)), -15, 45)) or 15
    else
        if autoPower.Value then
            power = tonumber(math.clamp(calcPower, 0, 95)) or 60
        end
        if autoAngle.Value then
            angle = tonumber(math.clamp(calcAngle, -15, 90)) or 45
        end
    end
    
    if not autoAngle.Value and not forceAutoAngle then
        angle = tonumber(math.clamp(calcAngle, -15, 90)) or 45
    end

    -- Smart arc: lowest arc that clears the defenders, with the lead re-solved for that flight time.
    if smartActive and modeName ~= 'Bullet' and not highPowerOnly.Value then
        local okA, arc = pcall(smartArc, origin, targetHRP, smartE, targetHead.Y, modeName, smartDefs, angle)
        if okA and arc then
            power = arc.p
            angle = arc.a
            leadPos = arc.lead
            if antiOOB.Value and fPos ~= Vector3.zero then
                local halfWidth = 75 - (tonumber(antiOOBThreshold.Value) or 5)
                local halfLength = 175 - (tonumber(antiOOBThreshold.Value) or 5)
                leadPos = Vector3.new(
                    math.clamp(leadPos.X, fPos.X - halfWidth, fPos.X + halfWidth),
                    leadPos.Y,
                    math.clamp(leadPos.Z, fPos.Z - halfLength, fPos.Z + halfLength)
                )
            end
            targetLeadPos = leadPos
        end
    end

    local safePower = tonumber(power) or 60
    local safeAngle = tonumber(angle) or 45
    local angleRad = tonumber(math.rad(safeAngle)) or 0
    
    local hDirRaw = Vector3.new(leadPos.X - origin.X, 0, leadPos.Z - origin.Z)
    local hDir = hDirRaw.Magnitude > 0.01 and hDirRaw.Unit or head.CFrame.LookVector
    local dirVelocity = (hDir * (tonumber(math.cos(angleRad)) or 1) + Vector3.new(0, tonumber(math.sin(angleRad)) or 0, 0)) * safePower
    
    direction = dirVelocity.Unit * safePower
    
    local hVel = safePower * (tonumber(math.cos(angleRad)) or 1)
    if hVel > 0.1 then
        local xDist = tonumber(Vector3.new(leadPos.X - origin.X, 0, leadPos.Z - origin.Z).Magnitude) or 0
        airtime = xDist / hVel
    else
        airtime = 0
    end
    
    return safeAngle
end

local beamProjectile = function(g, v0, x0, t1)
    local c = 0.5 * 0.5 * 0.5
    local safeT1 = tonumber(t1) or 0.1
    local p3 = 0.5 * g * safeT1 * safeT1 + v0 * safeT1 + x0
    local p2 = p3 - (g * safeT1 * safeT1 + v0 * safeT1) / 3
    local p1 = (c * g * safeT1 * safeT1 + 0.5 * v0 * safeT1 + x0 - c * (x0 + p3)) / (3 * c) - p2

    local curve0 = tonumber((p1 - x0).Magnitude) or 0
    local curve1 = tonumber((p2 - p3).Magnitude) or 0

    local b = (x0 - p3).Unit
    local r1 = (p1 - x0).Unit
    local u1 = r1:Cross(b).Unit
    local r2 = (p2 - p3).Unit
    local u2 = r2:Cross(b).Unit
    b = u1:Cross(r1).Unit

    local cf1 = CFrame.new(
        x0.X, x0.Y, x0.Z,
        r1.X, u1.X, b.X,
        r1.Y, u1.Y, b.Y,
        r1.Z, u1.Z, b.Z
    )

    local cf2 = CFrame.new(
        p3.X, p3.Y, p3.Z,
        r2.X, u2.X, b.X,
        r2.Y, u2.Y, b.Y,
        r2.Z, u2.Z, b.Z
    )

    return curve0, -curve1, cf1, cf2
end

userInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local char = lp.Character
    if not char or not char:FindFirstChild('Football') then return end
    
    if input.KeyCode == throwBallAwayKeybind.Value then
        local fPos = Vector3.zero
        local field = workspace:FindFirstChild('Models')
        if field then field = field:FindFirstChild('Field') end
        if field then field = field:FindFirstChild('Ground') end
        if field then fPos = field.Position end
        
        local side = math.random(1, 2) == 1 and -1 or 1
        local throwTarget = fPos + Vector3.new(side * 120, 0, math.random(-100, 100))
        
        local head = char:FindFirstChild('Head')
        local origin = head and head.Position or char.HumanoidRootPart.Position
        
        isThrowingAway = true
        power = 95
        angle = 25
        
        local angleRad = tonumber(math.rad(angle)) or 0
        local hDir = Vector3.new(throwTarget.X - origin.X, 0, throwTarget.Z - origin.Z).Unit
        local dirVelocity = (hDir * (tonumber(math.cos(angleRad)) or 1) + Vector3.new(0, tonumber(math.sin(angleRad)) or 0, 0)) * 95
        direction = dirVelocity.Unit * 95
        
        local hVel = 95 * (tonumber(math.cos(angleRad)) or 1)
        airtime = hVel > 0.1 and ((tonumber(Vector3.new(throwTarget.X - origin.X, 0, throwTarget.Z - origin.Z).Magnitude) or 0) / hVel) or 1
        
        local hum = char:FindFirstChildOfClass('Humanoid')
        local throwAnim = replicatedStorage:FindFirstChild('Animations') and replicatedStorage.Animations:FindFirstChild('Throw')
        if hum and throwAnim then
            local animator = hum:FindFirstChild('Animator')
            if animator then
                local track = animator:LoadAnimation(throwAnim)
                track:Play()
            end
        end
        return
    end

    if input.KeyCode == increaseAngleKeybind.Value then
        customHeight.Value = (tonumber(customHeight.Value) or 0) + 5
    elseif input.KeyCode == decreaseAngleKeybind.Value then
        customHeight.Value = (tonumber(customHeight.Value) or 0) - 5
    end
    
    if not autoSelectThrowMode.Value and QBKeybinds[input.KeyCode] then
        local desiredMode = QBKeybinds[input.KeyCode]
        for i = 1, #ModeOrder do
            if ModeOrder[i] == desiredMode then
                modeIndex = i
                break
            end
        end
    end

    if input.KeyCode == lockKeybind.Value then
        if target or targetLocked then
            targetLocked = not targetLocked
            if targetLocked then
                lockedTarget = target
                if LockToggleBtn then LockToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50) end
                if LockedLabel then LockedLabel.Visible = true end
            else
                lockedTarget = nil
                if LockToggleBtn then LockToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end
                if LockedLabel then LockedLabel.Visible = false end
            end
        end
    end
end)

local triggerThrowJump = function()
    if autoJumpWhenThrow.Value then
        task.delay(0.05, function()
            local char = lp.Character
            if char then
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
end

task.spawn(function()
    local bindAnimation = function(char)
        local humanoid = char:WaitForChild('Humanoid', 5)
        if not humanoid then return end
        local animator = humanoid:WaitForChild('Animator', 5)
        if not animator then return end
        
        animator.AnimationPlayed:Connect(function(track)
            local throwAnim = replicatedStorage:FindFirstChild('Animations') and replicatedStorage.Animations:FindFirstChild('Throw')
            if throwAnim and track.Animation and (track.Animation == throwAnim or track.Animation.AnimationId == throwAnim.AnimationId) then
                track:GetPropertyChangedSignal('IsPlaying'):Connect(function()
                    if track.IsPlaying then
                        if not isThrowing then
                            isThrowing = true
                            triggerThrowJump()
                            task.delay(0.12, function()
                                firedRemote = true
                                performThrow()
                            end)
                        end
                    else
                        isThrowing = false
                        firedRemote = false
                        isThrowingAway = false
                    end
                end)
                
                if track.IsPlaying and not isThrowing then
                    isThrowing = true
                    triggerThrowJump()
                    task.delay(0.12, function()
                        firedRemote = true
                        performThrow()
                    end)
                end
            end
        end)
    end

    if lp.Character then
        bindAnimation(lp.Character)
    end
    lp.CharacterAdded:Connect(function(char)
        bindAnimation(char)
    end)
end)

-- Aimbot throw triggers: RT (controller), right click (keyboard + mouse),
-- and an on-screen THROW button on mobile.
local lastInputThrow = 0
local aimbotThrow = function(playAnim)
    if not enableQbAimbot.Value then return end

    local char = lp.Character
    if not char or not char:FindFirstChild('Football') then return end
    if isThrowing or isThrowingAway then return end
    if os.clock() - lastInputThrow < 0.5 then return end

    lastInputThrow = os.clock()
    isThrowing = true

    if playAnim then
        local hum = char:FindFirstChildOfClass('Humanoid')
        local throwAnim = replicatedStorage:FindFirstChild('Animations') and replicatedStorage.Animations:FindFirstChild('Throw')
        local animator = hum and hum:FindFirstChild('Animator')
        if animator and throwAnim then
            pcall(function() animator:LoadAnimation(throwAnim):Play() end)
        end
    end

    triggerThrowJump()
    task.delay(0.12, function()
        firedRemote = true
        performThrow()
    end)
    -- Safety reset in case the throw animation never plays.
    task.delay(0.8, function()
        if os.clock() - lastInputThrow >= 0.75 then
            isThrowing = false
            firedRemote = false
        end
    end)
end

userInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2
        or input.KeyCode == Enum.KeyCode.ButtonR2 then
        aimbotThrow(false)
    end
end)

if userInputService.TouchEnabled then
    local throwBtn = Instance.new('TextButton')
    throwBtn.Name = 'AethelThrow'
    throwBtn.Size = UDim2.new(0, 84, 0, 84)
    throwBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    throwBtn.Position = UDim2.new(0.85, 0, 0.55, 0)
    throwBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    throwBtn.BackgroundTransparency = 0.15
    throwBtn.AutoButtonColor = false
    throwBtn.Text = 'THROW'
    throwBtn.Font = Enum.Font.GothamBold
    throwBtn.TextSize = 16
    throwBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    throwBtn.Visible = false
    throwBtn.ZIndex = 50
    throwBtn.Parent = sg
    Instance.new('UICorner', throwBtn).CornerRadius = UDim.new(1, 0)
    local btnStroke = Instance.new('UIStroke', throwBtn)
    btnStroke.Color = Color3.fromRGB(240, 240, 240)
    btnStroke.Transparency = 0.4
    btnStroke.Thickness = 2

    -- Tap = throw, drag = move the button.
    local dragging, dragMoved, dragStart, startPos = false, false, nil, nil
    throwBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragMoved = true, false
            dragStart, startPos = input.Position, throwBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not dragMoved then aimbotThrow(true) end
                end
            end)
        end
    end)
    userInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then dragMoved = true end
            if dragMoved then
                throwBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)

    -- Only show it while the aimbot is on and you're holding the football.
    task.spawn(function()
        while true do
            task.wait(0.1)
            local char = lp.Character
            throwBtn.Visible = enableQbAimbot.Value and char ~= nil and char:FindFirstChild('Football') ~= nil
        end
    end)
end

local setupSackHandler = function(character)
    character.ChildAdded:Connect(function(v)
        if not autoThrowAfterSack.Value then return end
        if not v:IsA('LocalScript') then return end
        if not v.Name:lower():find('tackle') then return end

        task.wait()

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then return end

        if autoChooseWr.Value then
            local openWR = nil
            local bestDist = math.huge
            local mousePos2D = userInputService:GetMouseLocation()
            
            local teamCount = 0
            pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)
            
            local plrs = players:GetPlayers()
            for i = 1, #plrs do
                local plr = plrs[i]
                if plr ~= lp and plr.Character then
                    local isTeammate = true
                    if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team ~= plr.Team then
                        isTeammate = false
                    end
                    
                    if isTeammate then
                        local eHrp = plr.Character:FindFirstChild('HumanoidRootPart')
                        local eHum = plr.Character:FindFirstChildOfClass('Humanoid')
                        if eHrp and (not eHum or not eHum.Sit) and isWROpen(plr.Character) then
                            local screenPos, onScreen = camera:WorldToViewportPoint(eHrp.Position)
                            if onScreen then
                                local dist = tonumber((Vector2.new(screenPos.X, screenPos.Y) - mousePos2D).Magnitude) or 0
                                if dist < bestDist then
                                    bestDist = dist
                                    openWR = plr.Character
                                end
                            end
                        end
                    end
                end
            end

            if openWR then
                target = openWR
                targetLocked = true
                lockedTarget = openWR
            end
        end

        if target then
            local throwAnim = replicatedStorage:FindFirstChild('Animations') and replicatedStorage.Animations:FindFirstChild('Throw')
            if throwAnim then
                local animator = humanoid:FindFirstChild('Animator')
                if animator then
                    local track = animator:LoadAnimation(throwAnim)
                    track:Play()
                end
            end
        end
    end)
end

if lp.Character then
    setupSackHandler(lp.Character)
end
lp.CharacterAdded:Connect(setupSackHandler)

local updateHighlights = function(isActive)
    if not isActive then
        if highlight then highlight:Destroy(); highlight = nil end
        return
    end

    if target then
        if not highlight then
            highlight = Instance.new('Highlight')
        end
        highlight.Adornee = target
        highlight.Parent = target
        highlight.FillTransparency = 1
        highlight.OutlineColor = targetLocked and Color3.new(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
    elseif highlight then
        highlight:Destroy()
        highlight = nil
    end
end

workspace.ChildAdded:Connect(function(v)
    if not enableQbAimbot.Value then return end
    if v:IsA('BasePart') and v.Name == 'Football' then
        task.wait()
        local lpChar = lp.Character
        local lpHead = lpChar and lpChar:FindFirstChild('Head')
        if not lpHead then return end
        
        if v:GetAttribute('LocalAimbotBall') or (v.Position - lpHead.Position).Magnitude < 15 then
            local tAttach0 = Instance.new('Attachment', workspace.Terrain)
            local tAttach1 = Instance.new('Attachment', workspace.Terrain)
            
            local tBeam = Instance.new('Beam')
            tBeam.Attachment0 = tAttach0
            tBeam.Attachment1 = tAttach1
            tBeam.Segments = 7500
            tBeam.Width0 = 1
            tBeam.Width1 = 1
            tBeam.FaceCamera = true
            tBeam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
            tBeam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.01, 0),
                NumberSequenceKeypoint.new(1, 0)
            })
            tBeam.Parent = workspace.Terrain
            
            local tPosPart = Instance.new('Part', workspace.Terrain)
            tPosPart.Anchored = true
            tPosPart.CanCollide = false
            tPosPart.CastShadow = false
            tPosPart.Size = Vector3.new(3, 3, 3)
            tPosPart.Shape = Enum.PartType.Ball
            tPosPart.Color = Color3.fromRGB(0, 0, 0)
            
            local safeDirection = direction or Vector3.new(0, 1, 0)
            local safeAirtime = math.max(tonumber(airtime) or 0.1, 0.1)
            local curve0, curve1, cf1, cf2 = beamProjectile(Vector3.new(0, -28, 0), safeDirection, lpHead.Position + (safeDirection.Unit * 5), safeAirtime)
            
            tBeam.CurveSize0 = curve0
            tBeam.CurveSize1 = curve1
            
            tAttach0.WorldCFrame = cf1
            tAttach1.WorldCFrame = cf2
            
            tPosPart.Position = Vector3.new(cf2.X, cf2.Y, cf2.Z)
            
            task.delay(safeAirtime, function()
                tBeam:Destroy()
                tAttach0:Destroy()
                tAttach1:Destroy()
                tPosPart:Destroy()
            end)
        end
    end
end)

runService.RenderStepped:Connect(function()
    if not enableQbAimbot.Value then
        updateHUDVisibility(false)
        updateHighlights(false)
        if beam then beam.Enabled = false end
        if posPart then posPart.Position = Vector3.new(0, -9999, 0) end
        if attach0 then attach0.WorldPosition = Vector3.new(0, -9999, 0) end
        if attach1 then attach1.WorldPosition = Vector3.new(0, -9999, 0) end
        target = nil
        return
    end

    if not sg or not sg.Parent then return end

    local char = lp.Character
    if not char then return end
    
    local head = char:FindFirstChild('Head')
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not head or not hrp then return end

    local football = char:FindFirstChild('Football')
    local hasFootball = (football ~= nil)
    
    if hasFootball then
        football:SetAttribute('LocalAimbotBall', true)
        local fHandle = football:FindFirstChild('Handle')
        if fHandle then fHandle:SetAttribute('LocalAimbotBall', true) end
    end
    
    local playerGui = lp:WaitForChild('PlayerGui', 10)
    local ballGui = playerGui and playerGui:FindFirstChild('BallGui')
    
    if autoJuke.Value and hasFootball and ballGui then
        local fPos = Vector3.zero
        local field = workspace:FindFirstChild('Models')
        if field then field = field:FindFirstChild('Field') end
        if field then field = field:FindFirstChild('Ground') end
        if field then fPos = field.Position end
        
        local minX = fPos.X - (155 / 2)
        local maxX = fPos.X + (155 / 2)
        local minZ = fPos.Z - (355 / 2)
        local maxZ = fPos.Z + (355 / 2)

        local dodgeVec = Vector3.zero
        local threatCount = 0

        local plrs = players:GetPlayers()
        local teamCount = 0
        pcall(function() teamCount = tonumber(#game:GetService('Teams'):GetTeams()) or 0 end)
        
        for i = 1, #plrs do
            local plr = plrs[i]
            if plr ~= lp and plr.Character then
                local isEnemy = true
                if teamCount > 1 and lp.Team ~= nil and plr.Team ~= nil and lp.Team == plr.Team then
                    isEnemy = false
                end
                
                if isEnemy then
                    local eHrp = plr.Character:FindFirstChild('HumanoidRootPart')
                    if eHrp then
                        local distToMe = tonumber((eHrp.Position - hrp.Position).Magnitude) or 0
                        if distToMe < 45 then
                            local eVel = eHrp.AssemblyLinearVelocity or eHrp.Velocity or Vector3.zero
                            local eSpeed = tonumber(Vector3.new(eVel.X, 0, eVel.Z).Magnitude) or 0
                            local tta = distToMe / math.max(eSpeed, 1)
                            
                            local futureTime = math.min(tta, 1)
                            local eFuture = eHrp.Position + (eVel * futureTime)
                            local myVel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
                            local myFuture = hrp.Position + (myVel * futureTime)
                            
                            local toThreat = eFuture - myFuture
                            local futureDist = tonumber(Vector3.new(toThreat.X, 0, toThreat.Z).Magnitude) or 0
                            
                            if futureDist < 20 or distToMe < 25 then
                                threatCount = threatCount + 1
                                local awayDir = myFuture - eFuture
                                awayDir = Vector3.new(awayDir.X, 0, awayDir.Z)
                                if awayDir.Magnitude < 0.1 then
                                    awayDir = hrp.CFrame.RightVector
                                end
                                awayDir = awayDir.Unit
                                
                                local weight = math.clamp(45 - distToMe, 0, 45)
                                dodgeVec = dodgeVec + (awayDir * weight)
                            end
                        end
                    end
                end
            end
        end

        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then
            local checkPos = hrp.Position
            local outOfBoundsPush = Vector3.zero
            
            if checkPos.X < minX + 5 then outOfBoundsPush = outOfBoundsPush + Vector3.new(1, 0, 0) end
            if checkPos.X > maxX - 5 then outOfBoundsPush = outOfBoundsPush + Vector3.new(-1, 0, 0) end
            if checkPos.Z < minZ + 5 then outOfBoundsPush = outOfBoundsPush + Vector3.new(0, 0, 1) end
            if checkPos.Z > maxZ - 5 then outOfBoundsPush = outOfBoundsPush + Vector3.new(0, 0, -1) end
            
            local targetJukeDir = Vector3.zero
            if threatCount > 0 then
                targetJukeDir = dodgeVec.Unit
                if outOfBoundsPush.Magnitude > 0 then
                    targetJukeDir = (targetJukeDir + outOfBoundsPush * 2).Unit
                end
            elseif outOfBoundsPush.Magnitude > 0 then
                targetJukeDir = outOfBoundsPush.Unit
            end
            
            if targetJukeDir.Magnitude > 0 then
                smoothedJukeDir = smoothedJukeDir:Lerp(targetJukeDir, 0.25)
                hum:Move(smoothedJukeDir, false)
            else
                smoothedJukeDir = Vector3.zero
            end
        end
    end

    local isTracking = hasFootball and (ballGui ~= nil)

    if isTracking then
        if not hideCards.Value then
            updateHUDVisibility(true)
        else
            updateHUDVisibility(false)
        end
        
        if not isThrowingAway then
            local newTarget = getTarget()
            if newTarget then
                lastValidTarget = newTarget
            elseif lastValidTarget and not lastValidTarget:FindFirstChild('HumanoidRootPart') then
                lastValidTarget = nil
            end
            
            if throwAimbot.Value then
                target = lastValidTarget
                updateHighlights(false)
                
                local targetPos
                if isThrowing and lockedMousePos then
                    targetPos = lockedMousePos
                else
                    targetPos = mouse.Hit.Position
                    lockedMousePos = targetPos
                end
                
                local headPos = head.Position
                local gMag = 28
                local calcPower, calcAngle = solveKinematics(headPos, targetPos, gMag)
                calcPower = tonumber(calcPower) or 95
                calcAngle = tonumber(calcAngle) or 45
                
                if autoPower.Value then
                    power = math.clamp(calcPower, 0, 95)
                end
                
                if autoAngle.Value then
                    angle = math.clamp(calcAngle, -15, 90)
                else
                    angle = math.clamp(tonumber(customHeight.Value) or 0, -15, 90)
                end
                
                local safePower = tonumber(power) or 60
                local safeAngle = tonumber(angle) or 45
                local angleRad = tonumber(math.rad(safeAngle)) or 0
                
                local hDirRaw = Vector3.new(targetPos.X - headPos.X, 0, targetPos.Z - headPos.Z)
                local hDir = hDirRaw.Magnitude > 0.01 and hDirRaw.Unit or hrp.CFrame.LookVector
                
                local dirVelocity = (hDir * (tonumber(math.cos(angleRad)) or 1) + Vector3.new(0, tonumber(math.sin(angleRad)) or 0, 0)) * safePower
                direction = dirVelocity.Unit * safePower
                
                local hVel = safePower * (tonumber(math.cos(angleRad)) or 1)
                if hVel > 0.1 then
                    local xDist = tonumber(Vector3.new(targetPos.X - headPos.X, 0, targetPos.Z - headPos.Z).Magnitude) or 0
                    airtime = xDist / hVel
                else
                    airtime = 0
                end
                
                targetLeadPos = targetPos
            else
                target = newTarget or lastValidTarget
                updateHighlights(true)
                if target and hrp then
                    local tHRP = target:FindFirstChild('HumanoidRootPart')
                    if tHRP then
                        if autoSelectThrowMode.Value then
                            local m = calculateRouteDirection(target)
                            for i = 1, #ModeOrder do
                                if ModeOrder[i] == m then
                                    modeIndex = i
                                    break
                                end
                            end
                            
                            local targetCurrentRoute = select(1, findRoute(target))
                            if ModeOrder[modeIndex] == 'Bullet' and (targetCurrentRoute == 'go/fade' or targetCurrentRoute == 'post/corner') then
                                for i = 1, #ModeOrder do
                                    if ModeOrder[i] == 'Mag' then
                                        modeIndex = i
                                        break
                                    end
                                end
                            end
                        end
                        
                        autoAim(tHRP)
                    end
                end
            end
        else
            target = nil
            updateHighlights(false)
        end
        
        if autoChangePowerUI.Value then
            if ballGui and ballGui:FindFirstChild('Frame0') then
                local frame0 = ballGui.Frame0
                local safePower = tonumber(power) or 60
                if safePower ~= safePower then safePower = 60 end
                
                local displayPower = math.round(safePower / 5) * 5
                
                local txt = frame0:FindFirstChildOfClass('TextLabel')
                if txt then txt.Text = tostring(math.floor(displayPower)) end
                
                local frames = frame0:GetChildren()
                for i = 1, #frames do
                    local frame = frames[i]
                    if frame.Name ~= 'Disp' then
                        local frameNum = tonumber(frame.Name) or 0
                        frame.BackgroundTransparency = ((tonumber(frameNum) or 0) <= (tonumber(displayPower) or 0)) and 0 or 0.9
                    end
                end
            end
        end
        
        local safePowForCard = tonumber(power) or 60
        if safePowForCard ~= safePowForCard then safePowForCard = 60 end
        
        if HUDCards['Angle'] then 
            local forceAutoAngle = (ModeOrder[modeIndex] == 'Bullet' or (target and findRoute(target) == 'slant' or findRoute(target) == 'drag' or findRoute(target) == 'in/out' or findRoute(target) == 'flat' or findRoute(target) == 'hitch' or findRoute(target) == 'curl/comeback') or (tonumber(power) or 60) == 95 or highPowerOnly.Value)
            if not autoAngle.Value and not forceAutoAngle then
                HUDCards['Angle'].Text = tostring(math.floor(tonumber(customHeight.Value) or 0))
            else
                HUDCards['Angle'].Text = tostring(math.floor(tonumber(angle) or 45)) 
            end
        end
        
        if HUDCards['Power'] then HUDCards['Power'].Text = string.format('%.0f', safePowForCard) end
        if HUDCards['Airtime'] then HUDCards['Airtime'].Text = string.format('%.1fs', tonumber(airtime) or 0) end
        if HUDCards['Throw Type'] then HUDCards['Throw Type'].Text = tostring(ModeOrder[modeIndex] or 'N/A') end
        
        if HUDCards['Player'] then
            if throwAimbot.Value then
                HUDCards['Player'].Text = 'MOUSE'
            else
                HUDCards['Player'].Text = tostring((target and target.Name) or 'NONE')
            end
        end
    else
        updateHUDVisibility(false)
        updateHighlights(false)
        target = nil
        lastValidTarget = nil
    end

    if beam and isTracking then
        beam.Enabled = true
        local startOrigin = head.Position
        local safePowerForBeam = tonumber(power) or 60
        local drawDir = direction or Vector3.new(0, 1, 0)
        
        if throwAimbot.Value then
            if (tonumber(drawDir.Magnitude) or 0) < 0.1 then
                drawDir = Vector3.new(0, 1, 0) * safePowerForBeam
            end
        elseif not target or not targetLeadPos then
            local mouseRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
            drawDir = mouseRay.Direction.Unit * safePowerForBeam
            direction = drawDir
        else
            if (tonumber(drawDir.Magnitude) or 0) < 0.1 then
                drawDir = Vector3.new(0, 1, 0) * safePowerForBeam
            end
        end
        
        local safeAirtime = math.max(tonumber(airtime) or 0.1, 0.1)
        
        local curve0, curve1, cf1, cf2 = beamProjectile(Vector3.new(0,-28,0), drawDir, startOrigin + (drawDir.Unit * 5), safeAirtime)
        
        beam.CurveSize0 = curve0
        beam.CurveSize1 = curve1
        
        if attach0 and attach1 then
            attach0.WorldCFrame = cf1
            attach1.WorldCFrame = cf2
            
            attach0.WorldPosition = Vector3.new(cf1.X, cf1.Y, cf1.Z)
            attach1.WorldPosition = Vector3.new(cf2.X, cf2.Y, cf2.Z)
            
            if posPart then posPart.Position = Vector3.new(attach1.WorldPosition.X, attach1.WorldPosition.Y, attach1.WorldPosition.Z) end
        end
    else
        if beam then beam.Enabled = false end
        if posPart then posPart.Position = Vector3.new(0, -9999, 0) end
        if attach0 then attach0.WorldPosition = Vector3.new(0, -9999, 0) end
        if attach1 then attach1.WorldPosition = Vector3.new(0, -9999, 0) end
    end
end)

local CatchingTab = Window:CreateTab({ Name = 'Catching', Icon = 'rbxassetid://6034227067' })

footballMagnets = CatchingTab:CreateToggle({
    Name = 'Enable Football Magnets',
    Default = false,
    Tip = 'Automatically pulls nearby footballs into catch range.',
})

freeFallCheck = CatchingTab:CreateToggle({
    Name = 'Magnets Freefall Check',
    Default = false,
    Tip = 'Only activates football magnets while the ball is airborne.',
})

showCatchHitbox = CatchingTab:CreateToggle({
    Name = 'Show Magnets Radius',
    Default = false,
    Tip = 'Displays the football magnets catch radius.',
})

magnetsRadius = CatchingTab:CreateSlider({
    Name = 'Magnets Catch Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum distance footballs can be caught from.',
})

magnetsDelay = CatchingTab:CreateSlider({
    Name = 'Magnets Catch Delay',
    Min = 0,
    Max = 1,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the delay before football magnets activate.',
})

magsType = CatchingTab:CreateDropdown({
    Name = 'Magnets Type',
    Options = {'Custom', 'Blatant', 'League', 'Legit'},
    Default = 'Custom',
    Tip = 'Selects the football magnets behavior preset.',
})

local player = game:GetService('Players').LocalPlayer

local part = Instance.new('Part')
part.Color = Color3.fromRGB(255, 255, 255)
part.Shape = Enum.PartType.Ball
part.Material = Enum.Material.ForceField
part.CastShadow = false
part.Anchored = true
part.CanCollide = false

local findClosestBall = function()
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
    if not humanoidRootPart then return end

    local dist = math.huge
    local ball = nil

    for _, v in next, workspace:GetChildren() do
        if not v:IsA('BasePart') then continue end
        if v.Name ~= 'Football' then continue end

        local distance = (v.Position - humanoidRootPart.Position).Magnitude

        if distance < dist then
            dist = distance
            ball = v
        end
    end

    return ball
end

local selectedRange = function()
	local range = tonumber(magnetsRadius.Value) or 0
	local mode = tostring(magsType.Value or 'Custom'):lower()

	if mode == 'legit' then
		return range / 2
	elseif mode == 'league' then
		return range / 1.4
	elseif mode == 'blatant' then
		return range * 1.5
	end

	return range
end

task.spawn(function()
    while true do
        task.wait()

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local range = selectedRange()

        part.Size = Vector3.new(range, range, range)
        part.CFrame = CFrame.new(ball.Position)
        part.Parent = (footballMagnets.Value and showCatchHitbox.Value) and workspace.Terrain or nil

        for _, v in next, character:GetChildren() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('catch') then continue end

            local distance = (ball.Position - v.Position).Magnitude

            if freeFallCheck.Value and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then continue end

            if footballMagnets.Value and distance < range then
                tweenService:Create(v, TweenInfo.new(magnetsDelay.Value), {Position = ball.Position}):Play()

                pcall(function()
                    firetouchinterest(v, ball, 0)
                    firetouchinterest(v, ball, 1)
                end)
            end
        end
    end
end)

CatchingTab:CreateDivider()

magEnhancer = CatchingTab:CreateToggle({
    Name = 'Enable Mag Enhancer',
    Default = false,
    Tip = 'Enhances catches on footballs already within range.',
})

magEnhancerRadius = CatchingTab:CreateSlider({
    Name = 'Mag Catch Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum distance the enhancer can assist catches.',
})

magEnhancerMaxAngle = CatchingTab:CreateSlider({
    Name = 'Mag Max Angle',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum catch angle the enhancer can assist.',
})

task.spawn(function()
    while true do
        task.wait(0.1)

        if not magEnhancer.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local verticalDistance = ball.Position.Y - humanoidRootPart.Position.Y

        if verticalDistance > magEnhancerMaxAngle.Value then
            continue
        end

        local lookVector = humanoidRootPart.CFrame.LookVector
        local direction = (ball.Position - humanoidRootPart.Position).Unit
        local dot = lookVector:Dot(direction)

        for _, v in next, character:GetChildren() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('catch') then continue end

            local distance = (ball.Position - v.Position).Magnitude

            if dot > 0 and distance <= magEnhancerRadius.Value then
                tweenService:Create(v, TweenInfo.new(0), {Position = ball.Position}):Play()

                pcall(function()
                    firetouchinterest(v, ball, 0)
                    firetouchinterest(v, ball, 1)
                end)
            end
        end
    end
end)
    
CatchingTab:CreateDivider()

pullVector = CatchingTab:CreateToggle({
    Name = 'Enable Pull Vector',
    Default = false,
    Tip = 'Pulls nearby footballs toward your catch position.',
})

pullVectorRadius = CatchingTab:CreateSlider({
    Name = 'Pull Vector Radius',
    Min = 0,
    Max = 45,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum distance footballs can be pulled from.',
})

pullVectorPower = CatchingTab:CreateSlider({
    Name = 'Pull Vector Power',
    Min = 0,
    Max = 5,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Controls how strongly footballs are pulled toward you.',
})

task.spawn(function()
    while true do
        task.wait()

        if not pullVector.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local distance = (ball.Position - humanoidRootPart.Position).Magnitude
        if distance > pullVectorRadius.Value then continue end

        local direction = (ball.Position - humanoidRootPart.Position).Unit
        humanoidRootPart.AssemblyLinearVelocity = direction * (pullVectorPower.Value * 25)
    end
end)

CatchingTab:CreateDivider()

increaseArmSize = CatchingTab:CreateToggle({
    Name = 'Increase Arm Size',
    Default = false,
    Tip = 'Increases arm size to improve catch reach.',
})

armSizeValue = CatchingTab:CreateSlider({
    Name = 'Arm Size Value',
    Min = 2,
    Max = 25,
    Default = 2,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the size applied to both arms.',
})

task.spawn(function()
    while true do
        task.wait()

        local character = player.Character
        if not character then continue end

        for _, v in next, character:GetChildren() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('t arm') then continue end

            v.Size = Vector3.new(v.Size.X, increaseArmSize.Value and armSizeValue.Value or 2, v.Size.Z)
        end
    end
end)
    
local PlayerTab = Window:CreateTab({ Name = 'Player', Icon = 'rbxassetid://103807548355126' })

customWalkSpeed = PlayerTab:CreateToggle({
    Name = 'Custom WalkSpeed',
    Default = false,
    Tip = 'Overrides your character movement speed.',
})

walkSpeedValue = PlayerTab:CreateSlider({
    Name = 'WalkSpeed Value',
    Min = 20,
    Max = 23,
    Default = 20,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the movement speed value.',
})

walkspeedType = PlayerTab:CreateDropdown({
    Name = 'WalkSpeed Type',
    Options = {'Normal', 'CFrame'},
    Default = 'Normal',
    Tip = 'Selects how movement speed is applied.',
})

task.spawn(function()
    while true do
        task.wait()
        
        if not customWalkSpeed.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end
        if humanoid.PlatformStand then continue end
        if humanoid.WalkSpeed == 0 then continue end

        local root = character:FindFirstChild('HumanoidRootPart')
        if not root then continue end

        local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
        if direction.Magnitude <= 0 then continue end

        local velocity = direction.Unit * (walkspeedType.Value == 'CFrame' and (walkSpeedValue.Value / 75) or walkSpeedValue.Value)

        if humanoid:GetState() == Enum.HumanoidStateType.Running then
            local scale = walkSpeedValue.Value / math.max(humanoid.WalkSpeed, 1)

            local animator = humanoid:FindFirstChildOfClass('Animator')
            if animator then
                for _, track in next, animator:GetPlayingAnimationTracks() do
                    track:AdjustSpeed(scale)
                end
            end
        end

        if walkspeedType.Value ~= 'CFrame' then
            root.AssemblyLinearVelocity = Vector3.new(velocity.X, root.AssemblyLinearVelocity.Y, velocity.Z)
        else
            root.CFrame = root.CFrame + velocity
        end
    end
end)

PlayerTab:CreateDivider()

customJumpPower = PlayerTab:CreateToggle({
    Name = 'Custom JumpPower',
    Default = false,
    Tip = 'Overrides your character jump power.',
})

jumpPowerValue = PlayerTab:CreateSlider({
    Name = 'JumpPower Value',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the custom jump power.',
})

task.spawn(function()
    while true do
        task.wait()

        if not customJumpPower.Value then continue end
        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end

        local root = character:FindFirstChild('HumanoidRootPart')
        if not root then continue end

        if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then continue end
        
        task.wait()
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, jumpPowerValue.Value, root.AssemblyLinearVelocity.Z)
    end
end)
    
PlayerTab:CreateDivider()

angleEnhancer = PlayerTab:CreateToggle({
    Name = 'Angle Enhancer',
    Default = false,
    Tip = 'Boosts jump height when directional look changes while jumping.',
})

angleEnhancerIndicator = PlayerTab:CreateToggle({
    Name = 'Angle Enhancer Indicator',
    Default = false,
    Tip = 'Showsa notification when an angle boost is triggered.',
})
    
    autoFlip = PlayerTab:CreateToggle({
    Name = 'Auto Flip Before Landing',
    Default = false,
    Tip = 'Automatically adjusts player orientation before landing.',
})

angleEnhanceBoost = PlayerTab:CreateSlider({
    Name = 'Angle Boost Value',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the vertical velocity applied during angle boost.',
})
    
local lastTick = 0
local oldLookVector = nil

task.spawn(function()
    while true do
        task.wait()

        if not angleEnhancer.Value then continue end

        local character = player.Character
        if not character then oldLookVector = nil continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not humanoid or not hrp then oldLookVector = nil continue end

        if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            continue
        end

        local currentTime = tick()
        local newLookVector = hrp.CFrame.LookVector

        if not oldLookVector then
            oldLookVector = newLookVector
            lastTick = currentTime
            continue
        end

        local angleChange = math.acos(math.clamp(oldLookVector:Dot(newLookVector), -1, 1))
        local shiftLockEnabled = userInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

        if currentTime - lastTick >= 0.2 and angleChange > math.rad(5) then
            lastTick = currentTime
            oldLookVector = newLookVector
        end

        if angleChange > math.rad(25) and currentTime - lastTick <= 2.5 then
            lastTick = currentTime
            oldLookVector = newLookVector

            task.wait()

            local vel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(vel.X, angleEnhanceBoost.Value, vel.Z)

            if angleEnhancerIndicator.Value and (shiftLockEnabled or true) then
                local hint = Instance.new('Hint')
                hint.Text = 'Angled!'
                hint.Parent = workspace.Terrain

                task.delay(2.5, function()
                    if hint then
                        hint:Destroy()
                    end
                end)
            end
        end
    end
end)
    
local runtime, jumptime, hittime = 0, 0, 0
local arm, vLine, used, prevPs = false, nil, false, false
local seq = 0
local pack = nil

local xz = function(v: Vector3)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.001 and f.Unit or nil
end

local reset = function()
	if not pack then return end
	for _, o in next, { pack.spin, pack.ra, pack.pivot, pack.ha } do
		if o then o:Destroy() end
	end
	pack = nil
end

local flip = function(root: BasePart, head: BasePart)
	reset()

	local m = math.max(root.AssemblyMass, 1)

	local ha = Instance.new("Attachment")
	ha.Parent = head

	local pivot = Instance.new("AlignPosition")
	pivot.Mode = Enum.PositionAlignmentMode.OneAttachment
	pivot.Attachment0 = ha
	pivot.Position = head.Position + Vector3.new(0, 0.15, 0)
	pivot.MaxForce = 180000
	pivot.Responsiveness = 120
	pivot.RigidityEnabled = false
	pivot.ApplyAtCenterOfMass = false
	pivot.Parent = head

	local ra = Instance.new("Attachment")
	ra.Parent = root

	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = ra
	spin.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	spin.AngularVelocity = Vector3.new(-9, 0, 0)
	spin.MaxTorque = 50000
	spin.Parent = root

	root:ApplyAngularImpulse(root.CFrame.RightVector * (-16 * m))

	pack = { ha = ha, pivot = pivot, ra = ra, spin = spin }
end

task.spawn(function()
	while true do
		task.wait()
	    
	    if not autoFlip.Value then continue end
	    
		local char = player.Character
		if not char then
			reset()
			arm, vLine, used, prevPs = false, nil, false, false
			continue
		end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		if not hum or not hrp or not head then continue end

		local now = tick()

		if hum:GetState() == Enum.HumanoidStateType.Running then runtime = now end
		if hum:GetState() == Enum.HumanoidStateType.Jumping then jumptime = now end

		local ps = hum.PlatformStand
		if ps ~= prevPs then
			if ps then
				arm = (now - runtime <= 0.5) and (now - jumptime <= 0.7)
				vLine = xz(hrp.AssemblyLinearVelocity) or xz(hrp.CFrame.LookVector)
				used = false
			else
				arm, vLine, used = false, nil, false
				seq += 1
				reset()
			end
			prevPs = ps
		end

		if not ps or not arm or pack then continue end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local result = workspace:Raycast(head.Position, Vector3.new(0, -3, 0), params)
		local ground = result and result.Instance ~= nil

		if used or not ground or now - hittime < 0.12 then continue end

		local dist = result and (head.Position - result.Position).Magnitude or math.huge
		if dist > 1.6 then continue end

		local move = xz(hrp.AssemblyLinearVelocity) or vLine
		local face = xz(hrp.CFrame.LookVector)

		if not move or not face or face:Dot(move) < 0.78 then continue end

		hittime = now
		used = true
		seq += 1
		local k = seq

		flip(hrp, head)

		task.delay(0.24, function()
			if k == seq then
				reset()
			end
		end)
	end
end)

PlayerTab:CreateDivider()

PlayerTab:CreateButton({
    Name = 'Unlock All Gamepass',
    Tip = 'Enables all gamepass-related checks locally.',
    Callback = function()
        local replicatedFirst = game:GetService('ReplicatedFirst')

        local module
        local success = pcall(function()
            module = require(replicatedFirst:FindFirstChild('LocalSave'))
        end)

        if not success or not module then
            return
        end

        module.PlayerOwnsPass = function(a, b)
            return true
        end
    end
})

local PhysicsTab = Window:CreateTab({ Name = 'Physics', Icon = 'rbxassetid://11537490966' })
    
local boundaries = {}

if not isPractice then
    for i, v in next, workspace.Models.Boundaries:GetChildren() do
        boundaries[#boundaries + 1] = v
    end
end

antiBoundaries = PhysicsTab:CreateToggle({
    Name = 'Anti OOB',
    Default = false,
    Tip = 'Prevents players from triggering out-of-bounds zones.',
    Callback = function(v)
        for i, b in next, boundaries do
            if b then
                b.Parent = not v and workspace.Models.Boundaries or nil
            end
        end
    end
})
    
    antiBench = PhysicsTab:CreateToggle({
    Name = 'Anti Bench',
    Default = false,
    Tip = 'Prevents automatic benching.',
})

task.spawn(function()
    while true do
        task.wait()

        if not antiBench.Value then continue end

        local playerGui = player:FindFirstChild('PlayerGui')
        if not playerGui then continue end

        local benchButton = playerGui:FindFirstChild('Benched', true)
        if not benchButton then continue end

        if benchButton.BackgroundColor3 == Color3.fromRGB(120, 120, 120) then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'ToggleBench')
        end
    end
end)
--[[
local scrambleWall = workspace:FindFirstChild('ScrambleWall')

antiQbBoundaries = PhysicsTab:CreateToggle({
    Name = 'Anti QB Boundaries',
    Default = false,
    Tip = 'Disables invisible QB boundary walls.',
    Callback = function(v)
        if not scrambleWall then return end
        scrambleWall.Parent = v and nil or workspace
    end
})
    ]]
PhysicsTab:CreateDivider()

antiJam = PhysicsTab:CreateToggle({
    Name = 'Anti Jam',
    Default = false,
    Tip = 'Reduces player collision while moving.',
})

antiJumpCooldown = PhysicsTab:CreateToggle({
    Name = 'Anti Jump Cooldown',
    Default = false,
    Tip = 'Removes the delay between jumps.',
})

antiFreeze = PhysicsTab:CreateToggle({
    Name = 'Anti Freeze',
    Default = false,
    Tip = 'Prevents movement speed from being reduced.',
})

task.spawn(function()
    while true do
        task.wait()
        
        if antiJumpCooldown.Value then
            player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
        
        if antiFreeze.Value then
            if player.Character.Humanoid.WalkSpeed ~= 20 then
                player.Character.Humanoid.WalkSpeed = 20
            end
        end

        for _, v in next, players:GetPlayers() do
            if v == player then continue end

            local character = v.Character
            if not character then continue end

            local hum = character:FindFirstChildOfClass('Humanoid')
            if not hum then continue end

            for _, part in next, character:GetChildren() do
                if not part:IsA('BasePart') then continue end
                if part.Name == 'Head' or part.Name == 'Torso' then
                    if hum:GetState() == Enum.HumanoidStateType.Running then
                        part.CanCollide = not antiJam.Value
                    else
                        part.CanCollide = true
                    end
                end
            end
        end
    end
end)

antiBlock = PhysicsTab:CreateToggle({
    Name = 'Anti Block',
    Default = false,
    Tip = 'Reduces player collision while moving.',
})
    
task.spawn(function()
    while true do
        task.wait()

        if not antiBlock.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end

        for _, v in next, character:GetDescendants() do
            if not v:IsA('BodyVelocity') then continue end
            -- if not v.Name:lower():find('ffmover') then continue end

            v.Velocity = Vector3.zero
            v.MaxForce = Vector3.zero
            humanoid.WalkSpeed = 20

            pcall(function()
                v:Destroy()
            end)
        end
    end
end)

PhysicsTab:CreateDivider()

quickTP = PhysicsTab:CreateToggle({
    Name = 'Quick TP',
    Default = false,
    Tip = 'Teleports forward in the direction you are facing.',
})

quickTPPower = PhysicsTab:CreateSlider({
    Name = 'Quick TP Power',
    Min = 0,
    Max = 5,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the teleport distance.',
})

HideKeybind = PhysicsTab:CreateKeybind({
    Name = 'Quick TP Keybind',
    Default = Enum.KeyCode.Q,
    Tip = 'Key used to activate Quick TP.',
})

userInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not quickTP.Value then return end
    if input.KeyCode ~= HideKeybind.Value and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    hrp.CFrame += hrp.CFrame.LookVector * quickTPPower.Value
end)
    
PhysicsTab:CreateDivider()

bigHead = PhysicsTab:CreateToggle({
    Name = 'Big Head Players',
    Default = false,
    Tip = 'Increases the size of other players heads.',
})

bigHeadSize = PhysicsTab:CreateSlider({
    Name = 'Big Head Size',
    Min = 1,
    Max = 6,
    Default = 1,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the size applied to player heads.',
})

task.spawn(function()
    while true do
        task.wait()

        for _, v in next, players:GetPlayers() do
            if v == player then continue end

            local character = v.Character
            if not character then continue end

            local head = character:FindFirstChild('Head')
            if not head then continue end

            head.Size = Vector3.new(bigHead.Value and bigHeadSize.Value or 1, bigHead.Value and bigHeadSize.Value or 1, bigHead.Value and bigHeadSize.Value or 1)
        end
    end
end)
    
local VisualTab = Window:CreateTab({ Name = 'Visual', Icon = 'rbxassetid://88610077537468' })

jumpSpot = VisualTab:CreateToggle({
    Name = 'Visualise Football Jump Spot',
    Default = false,
    Tip = 'Displays the predicted jump location of incoming footballs.',
})

workspace.ChildAdded:Connect(function(v)
    if not jumpSpot.Value then return end
    if not v:IsA('BasePart') or v.Name ~= 'Football' then return end

    task.wait()

    local position = v.Position
    local velocity = v.AssemblyLinearVelocity
    local gravity = Vector3.new(0, -28, 0)
    local deltaTime = 1 / 30

    local positions = {position}

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {v}
    raycastParams.IgnoreWater = true

    for _ = 1, 300 do
        local nextPosition = position + velocity * deltaTime + 0.5 * gravity * deltaTime ^ 2
        velocity += gravity * deltaTime

        if velocity.Y < 0 then
            local direction = nextPosition - position
            local result = workspace:Raycast(position, direction + Vector3.new(0, -14.4, 0), raycastParams)

            if result then
                nextPosition = result.Position
                table.insert(positions, nextPosition)
                break
            end
        end

        table.insert(positions, nextPosition)
        position = nextPosition
    end

    local optimalPoint = positions[#positions]
    
    local model = Instance.new('Model')
    model.Parent = workspace

    local baseY = optimalPoint.Y - 1.5
    local undergroundY = baseY - 6

    local gradientCylinder = Instance.new('MeshPart')
    gradientCylinder.MeshId = 'rbxassetid://8091779363'
    gradientCylinder.Material = Enum.Material.Plastic
    gradientCylinder.Size = Vector3.new(2, 4, 2)
    gradientCylinder.Rotation = Vector3.new(180, 0, 180)
    gradientCylinder.Transparency = 1
    gradientCylinder.Anchored = true
    gradientCylinder.CanCollide = false
    gradientCylinder.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    gradientCylinder.Parent = model

    local faces = {
        Enum.NormalId.Front,
        Enum.NormalId.Back,
        Enum.NormalId.Left,
        Enum.NormalId.Right
    }

    for _, face in next, faces do
        local decal = Instance.new('Decal')
        decal.Face = face
        decal.Texture = 'rbxassetid://8097185954'
        decal.Transparency = 0
        decal.Color3 = Color3.fromRGB(255, 255, 255)
        decal.Parent = gradientCylinder
    end

    local glowCircle = Instance.new('MeshPart')
    glowCircle.MeshId = 'rbxassetid://8091848285'
    glowCircle.Material = Enum.Material.Neon
    glowCircle.Color = Color3.fromRGB(255, 255, 255)
    glowCircle.Size = Vector3.new(3.731, 0.031, 3.731)
    glowCircle.Rotation = Vector3.new(180, 0, 180)
    glowCircle.Transparency = 1
    glowCircle.Anchored = true
    glowCircle.CanCollide = false
    glowCircle.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    glowCircle.Parent = model

    local emitter = Instance.new('ParticleEmitter')
    emitter.Texture = 'rbxasset://textures/particles/sparkles_main.dds'
    emitter.Rate = 5
    emitter.Speed = NumberRange.new(5, 5)
    emitter.Lifetime = NumberRange.new(0.5, 0.5)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.TimeScale = 0.3
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    emitter.Parent = gradientCylinder

    local bottomPart = Instance.new('Part')
    bottomPart.Size = Vector3.new(0.311, 0.311, 0.311)
    bottomPart.Transparency = 1
    bottomPart.Material = Enum.Material.Plastic
    bottomPart.Anchored = true
    bottomPart.CanCollide = false
    bottomPart.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    bottomPart.Parent = model

    local pointLight = Instance.new('PointLight')
    pointLight.Color = Color3.fromRGB(255, 255, 255)
    pointLight.Range = 12
    pointLight.Brightness = 2
    pointLight.Parent = bottomPart

    local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local upGoal = {
        Position = Vector3.new(optimalPoint.X, baseY, optimalPoint.Z)
    }

    local downGoal = {
        Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    }

    local upTweens = {
        tweenService:Create(gradientCylinder, tweenInfo, upGoal),
        tweenService:Create(glowCircle, tweenInfo, upGoal),
        tweenService:Create(bottomPart, tweenInfo, upGoal)
    }

    for _, t in next, upTweens do
        t:Play()
    end

    task.spawn(function()
        while v and v.Parent and v.AssemblyLinearVelocity.Magnitude > 1 do
            task.wait()
        end

        local downTweens = {
            tweenService:Create(gradientCylinder, tweenInfo, downGoal),
            tweenService:Create(glowCircle, tweenInfo, downGoal),
            tweenService:Create(bottomPart, tweenInfo, downGoal)
        }

        for _, t in next, downTweens do
            t:Play()
        end

        task.wait(0.4)

        if model.Parent then
            model:Destroy()
        end
    end)
end)
    
    throwSpot = VisualTab:CreateToggle({
    Name = 'Visualise Football Throw Spot',
    Default = false,
    Tip = 'Shows the predicted landing point of thrown footballs.',
})
    
    workspace.ChildAdded:Connect(function(v)
        if not throwSpot.Value then return end
    if not v:IsA('BasePart') or v.Name ~= 'Football' then return end

    task.wait()

    local pos = v.Position
    local vel = v.AssemblyLinearVelocity
    local gravity = Vector3.new(0, -28, 0)

    local positions = {}
    local parts = {}

    local dt = 0.05
    local maxTime = 8

    local lastPos = pos
    local spawnY = pos.Y

    for t = 0, maxTime, dt do
        local projectilePos = pos + (vel * t) + (0.5 * gravity * t * t)

        table.insert(positions, projectilePos)

        if projectilePos.Y < spawnY then
            break
        end

        local ray = workspace:Raycast(lastPos, projectilePos - lastPos)
        if ray then
            positions[#positions] = ray.Position
            break
        end

        lastPos = projectilePos
    end

    local endPos = positions[#positions]
    if not endPos then return end

    local posPart = Instance.new('Part', workspace.Terrain)
    posPart.Anchored = true
    posPart.CanCollide = false
    posPart.CastShadow = false
    posPart.Size = Vector3.new(3, 3, 3)
    posPart.Shape = Enum.PartType.Ball
    posPart.Color = Color3.fromRGB(0, 0, 0)
    posPart.Position = endPos

    for i = 1, #positions - 1 do
        local p0 = positions[i]
        local p1 = positions[i + 1]

        local beamPart = Instance.new('Part', workspace.Terrain)
        beamPart.Anchored = true
        beamPart.CanCollide = false
        beamPart.CastShadow = false
        beamPart.Material = Enum.Material.Neon
        beamPart.Color = Color3.fromRGB(255, 255, 255)

        local dist = (p1 - p0).Magnitude

        beamPart.Size = Vector3.new(0.4, 0.4, dist)
        beamPart.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)

        table.insert(parts, beamPart)
    end

    task.spawn(function()
        local speed = math.max(vel.Magnitude, 1)
        local delayTime = math.clamp(300 / speed, 0.01, 0.04)

        for _, part in next, parts do
            task.wait(delayTime)

            if part.Parent then
                part:Destroy()
            end
        end

        if posPart.Parent then
            posPart:Destroy()
        end
    end)
end)
    
VisualTab:CreateDivider()
    
enableGloves = VisualTab:CreateToggle({
    Name = 'Enable Uniform Gloves',
    Default = true,
    Tip = 'Toggles visibility of uniform gloves.',
})

task.spawn(function()
    while true do
        task.wait()

        local character = player.Character
        if not character then continue end

        local uniform = character:FindFirstChild('Uniform')
        if not uniform then continue end

        local gloveVisible

        for _, v in next, uniform:GetDescendants() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('glove') then continue end

            gloveVisible = v.Transparency == 0
            break
        end

        if gloveVisible == nil then continue end

        if enableGloves.Value and not gloveVisible then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'LeftGlove')
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'RightGlove')
        elseif not enableGloves.Value and gloveVisible then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'LeftGlove')
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'RightGlove')
        end
    end
end)

VisualTab:CreateDivider()
    
noBallTrail = VisualTab:CreateToggle({
    Name = 'No Ball Trail',
    Default = false,
    Tip = 'Removes football trail effects.',
})

workspace.ChildAdded:Connect(function(v)
    if not noBallTrail.Value then return end

    if v:IsA('BasePart') and v.Name == 'Football' then
        local trail = v:FindFirstChildOfClass('Trail')
        if trail then
            trail:Destroy()
        end
    end
end)

local stadiumParts = {}

for _, v in next, workspace.Models.Stadium:GetDescendants() do
    if not v:IsA('BasePart') then continue end

    stadiumParts[#stadiumParts + 1] = {
        Part = v,
        Transparency = v.Transparency,
        CanCollide = v.CanCollide
    }
end

hideStadium = VisualTab:CreateToggle({
    Name = 'Hide Stadium',
    Default = false,
    Tip = 'Hides visible stadium structures.',
    Callback = function(v)
        for _, p in next, stadiumParts do
            p.Part.Transparency = v and 1 or p.Transparency
            p.Part.CanCollide = v and false or p.CanCollide
        end
    end
})

VisualTab:CreateDivider()

local lighting = game:GetService('Lighting')

local function ApplySkyBox(name)
    for _, v in next, lighting:GetChildren() do
        if v:IsA("Sky") or v:IsA("PostEffect") or v:IsA("Atmosphere") then
            v:Destroy()
        end
    end

    if name == "Golden Twilight" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.SkyboxBk = "rbxassetid://541743453"
        Sky.SkyboxDn = "rbxassetid://541743443"
        Sky.SkyboxFt = "rbxassetid://541743446"
        Sky.SkyboxLf = "rbxassetid://541743436"
        Sky.SkyboxRt = "rbxassetid://541743435"
        Sky.SkyboxUp = "rbxassetid://541743441"

    elseif name == "Infernal Horizon" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=169210090"
        Sky.SkyboxDn = "http://www.roblox.com/asset/?id=169210108"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=169210121"
        Sky.SkyboxLf = "http://www.roblox.com/asset/?id=169210133"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=169210143"
        Sky.SkyboxUp = "http://www.roblox.com/asset/?id=169210149"
        Sky.StarCount = 100
        Sky.SunTextureId = " "

        local BlurEffect = Instance.new("BlurEffect")
        BlurEffect.Parent = lighting
        BlurEffect.Size = 6

        local ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
        ColorCorrectionEffect.Parent = lighting
        ColorCorrectionEffect.Brightness = 0.01
        ColorCorrectionEffect.Contrast = 0.15
        ColorCorrectionEffect.Saturation = 0.4
        ColorCorrectionEffect.TintColor = Color3.new(0.815686, 0.776471, 0.690196)

    elseif name == "Nebula Peaks" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.CelestialBodiesShown = false
        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=17124357467"
        Sky.SkyboxDn = "http://www.roblox.com/asset/?id=17124359797"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=17124362093"
        Sky.SkyboxLf = "http://www.roblox.com/asset/?id=17124365127"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=17124367200"
        Sky.SkyboxUp = "http://www.roblox.com/asset/?id=17124369657"

        local cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = lighting
        cc.Brightness = 0.1
        cc.Contrast = 0.3
        cc.Saturation = 0.2
        cc.TintColor = Color3.fromRGB(140, 190, 255)

        local bloom = Instance.new("BloomEffect")
        bloom.Parent = lighting
        bloom.Intensity = 1.2
        bloom.Threshold = 0.8
        bloom.Size = 56

        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = lighting
        atmosphere.Density = 0.25
        atmosphere.Offset = 0.2
        atmosphere.Glare = 0.3
        atmosphere.Haze = 1
        atmosphere.Color = Color3.fromRGB(80, 110, 150)
        atmosphere.Decay = Color3.fromRGB(25, 30, 35)

    elseif name == "Rose Glow" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.CelestialBodiesShown = false
        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=109305193"
        Sky.SkyboxDn = "http://www.roblox.com/asset?id=58372722"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=109305200"
        Sky.SkyboxLf = "http://www.roblox.com/asset/?id=109305185"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=109305189"
        Sky.SkyboxUp = "http://www.roblox.com/asset/?id=109305207"

    elseif name == "Night Sky" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.CelestialBodiesShown = false
        Sky.SkyboxBk = "http://www.roblox.com/Asset/?ID=12064107"
        Sky.SkyboxDn = "http://www.roblox.com/Asset/?ID=12064152"
        Sky.SkyboxFt = "http://www.roblox.com/Asset/?ID=12064121"
        Sky.SkyboxLf = "http://www.roblox.com/Asset/?ID=12063984"
        Sky.SkyboxRt = "http://www.roblox.com/Asset/?ID=12064115"
        Sky.SkyboxUp = "http://www.roblox.com/Asset/?ID=12064131"
        Sky.StarCount = 0

    elseif name == "Northern Lights" then
        local Sky = Instance.new("Sky")
        Sky.Name = name
        Sky.Parent = lighting
        Sky.CelestialBodiesShown = false
        Sky.SkyboxBk = "http://www.roblox.com/asset/?id=16563478983"
        Sky.SkyboxDn = "http://www.roblox.com/asset/?id=16563481302"
        Sky.SkyboxFt = "http://www.roblox.com/asset/?id=16563484084"
        Sky.SkyboxLf = "http://www.roblox.com/asset/?id=16563485362"
        Sky.SkyboxRt = "http://www.roblox.com/asset/?id=16563487078"
        Sky.SkyboxUp = "http://www.roblox.com/asset/?id=16563489821"
    end
end

local skyNames = {'Golden Twilight', 'Infernal Horizon', 'Nebula Peaks', 'Rose Glow', 'Night Sky', 'Northern Lights'}

for _, skyName in next, skyNames do
    VisualTab:CreateButton({
        Name = skyName,
        Tip = 'Applies the ' .. skyName .. ' skybox.',
        Callback = function()
            ApplySkyBox(skyName)
        end
    })
end

local DefenseTab = Window:CreateTab({ Name = 'Defense', Icon = 'rbxassetid://14939023862' })

swatReach = DefenseTab:CreateToggle({
    Name = 'Swat Reach',
    Default = false,
    Tip = 'Extends swat range on nearby footballs.',
})

swatReachDistance = DefenseTab:CreateSlider({
    Name = 'Swat Reach Radius',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum swat distance.',
})

task.spawn(function()
    while true do
        task.wait()

        if not swatReach.Value then continue end

        local character = player.Character
        if not character then continue end

        local ball = findClosestBall()
        if not ball then continue end

        for _, v in next, character:GetChildren() do
            if v:IsA('BasePart') and v.Name:lower():find('catch') then
                local distance = (ball.Position - v.Position).Magnitude
                if distance < swatReachDistance.Value then
                    if v.Size.X > 2 then
                        firetouchinterest(v, ball, 0)
                        firetouchinterest(v, ball, 1)
                    end
                end
            end
        end
    end
end)

DefenseTab:CreateDivider()

tackleReach = DefenseTab:CreateToggle({
    Name = 'Extend Tackle Reach',
    Default = false,
    Tip = 'Extends tackle range against ball carriers.',
})

tackleAimbot = DefenseTab:CreateToggle({
    Name = 'Tackle Aimbot',
    Default = false,
    Tip = 'Automatically targets nearby ball carriers.',
})

tackleAimbotRange = DefenseTab:CreateSlider({
    Name = 'Tackle Aimbot Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum targeting distance.',
})

task.spawn(function()
    while true do
        task.wait()

        local character = player.Character
        if not character then continue end

        if tackleReach.Value then
            for _, v in next, players:GetPlayers() do
                if v ~= player and v.Team ~= player.Team and v.Character and v.Character:FindFirstChild('Football') then
                    local bodyParts = {'Torso', 'Head', 'HumanoidRootPart', 'Left Arm', 'Left Leg', 'Right Arm', 'Right Leg'}
                    local randomPart = bodyParts[math.random(1, #bodyParts)]

                    replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'TackleTouch', randomPart, randomPart)
                end
            end
        end

        if tackleAimbot.Value then
            for _, v in next, players:GetPlayers() do
                if v ~= player and v.Team ~= player.Team and v.Character and v.Character.Humanoid.WalkSpeed > 0 and v.Character:FindFirstChild('Football') then
                    local distance = (v.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                    if distance < tackleAimbotRange.Value then
                        character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                        character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    end
                end
            end
        end
    end
end)

local AutomaticsTab = Window:CreateTab({ Name = 'Automatics', Icon = 'rbxassetid://86084882582277' })

autoRush = AutomaticsTab:CreateToggle({
    Name = 'Auto Rush',
    Default = false,
    Tip = 'Automatically moves toward the opposing ball carrier in range.',
})

walkToLine = AutomaticsTab:CreateToggle({
    Name = 'Walk To Line',
    Default = false,
    Tip = 'Moves the player to the line before play starts.',
})

autoRushReactionTime = AutomaticsTab:CreateSlider({
    Name = 'Reaction Time',
    Min = 0,
    Max = 1,
    Default = 0.15,
    Increment = 0.01,
    Suffix = '',
    Tip = 'Adjusts how quickly the feature responds.',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoRush.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end

        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end

        if walkToLine.Value then
            if replicatedStorage:FindFirstChild('Flags')
                and replicatedStorage.Flags:FindFirstChild('PossessionTag')
                and replicatedStorage.Flags:FindFirstChild('Status')
                and replicatedStorage.Flags.PossessionTag.Value ~= player.Team.Name
                and replicatedStorage.Flags.Status.Value == 'PrePlay' then

                local line = workspace:FindFirstChild('LineDown')
                if line then
                    humanoid:MoveTo(line.Position)
                end
            end
        end

        for _, v in next, players:GetPlayers() do
            if v == player then continue end
            if v.Team == player.Team then continue end
            if not v.Character then continue end

            local enemyChar = v.Character
            local enemyHumanoid = enemyChar:FindFirstChildOfClass('Humanoid')
            local enemyHrp = enemyChar:FindFirstChild('HumanoidRootPart')
            if not enemyHumanoid or not enemyHrp then continue end

            local football = enemyChar:FindFirstChild('Football')
            if not football then continue end

            local footballPart = football:FindFirstChildWhichIsA('BasePart')
            if not footballPart then continue end

            if enemyHumanoid.WalkSpeed <= 0 then continue end
            if enemyHumanoid.PlatformStand then continue end

            local ping = 0
            if stats and stats:FindFirstChild('Network') 
                and stats.Network:FindFirstChild('ServerStatsItem')
                and stats.Network.ServerStatsItem:FindFirstChild('Data Ping') then
                ping = stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000
            end

            local speed = enemyHumanoid.MoveDirection.Magnitude > 0 and enemyHumanoid.WalkSpeed or 0
            local predictionTime = ping + autoRushReactionTime.Value

            local pos = footballPart.Position + (enemyHumanoid.MoveDirection * speed * predictionTime * 20)

            local direction = pos - enemyHrp.Position
            if direction.Magnitude > 0 then
                pos += direction.Unit * ((hrp.Position - pos).Magnitude / 20)
            end

            humanoid:MoveTo(pos)
        end
    end
end)

AutomaticsTab:CreateDivider()

autoCatch = AutomaticsTab:CreateToggle({
    Name = 'Auto Catch',
    Default = false,
    Tip = 'Automatically moves toward nearby catch opportunities.',
})

autoCatchRadius = AutomaticsTab:CreateSlider({
    Name = 'Auto Catch Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how far the auto catch detection can reach.',
})
    
AutomaticsTab:CreateDivider()

autoSwat = AutomaticsTab:CreateToggle({
    Name = 'Auto Swat',
    Default = false,
    Tip = 'Automatically reacts to nearby incoming balls.',
})

autoSwatRadius = AutomaticsTab:CreateSlider({
    Name = 'Auto Swat Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how far the auto swat detection can reach.',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoCatch.Value and not autoSwat.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local distance = (ball.Position - humanoidRootPart.Position).Magnitude

        if autoCatch.Value and distance <= autoCatchRadius.Value then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('PlayerActions', isPractice and 'catch ' or 'catch')
        end

        if autoSwat.Value and distance <= autoSwatRadius.Value then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('PlayerActions', 'swat')
        end
    end
end)
    
AutomaticsTab:CreateDivider()
    
autoCaptain = AutomaticsTab:CreateToggle({
    Name = 'Auto Win Captain',
    Default = false,
    Tip = 'Automatically moves toward the finish line during captain selection.',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoCaptain.Value then continue end

        local character = player.Character
        if not character then continue end

        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end

        for _, v in next, workspace.Models.LockerRoomA:GetChildren() do
            if v.Name:lower():find('finishline') and not player.Team then
                v:GetPropertyChangedSignal('CFrame'):Connect(function()
                    for i = 1, 4 do
                        task.wait()

                        hrp.CFrame = v.CFrame
                    end
                end)
            end
        end
    end
end)
    
AutomaticsTab:CreateDivider()
    
autoFreeze = AutomaticsTab:CreateToggle({
    Name = 'Auto Freeze',
    Default = false,
    Tip = 'Temporarily anchors your character on input.',
})

freezeDuration = AutomaticsTab:CreateSlider({
    Name = 'Freeze Duration',
    Min = 0,
    Max = 3,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Duration the freeze state lasts.',
})

freezeKeybind = AutomaticsTab:CreateKeybind({
    Name = 'Freeze Keybind',
    Default = nil,
    Tip = 'Key used to trigger freeze.',
})

userInputService.InputBegan:Connect(function(input)
    if not autoFreeze.Value then return end
    if freezeKeybind.Value and input.KeyCode ~= freezeKeybind.Value then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    hrp.Anchored = true

    task.delay(freezeDuration.Value, function()
        if hrp then
            hrp.Anchored = false
        end
    end)
end)

AutomaticsTab:CreateDivider()

autoQb = AutomaticsTab:CreateToggle({
    Name = 'Auto QB',
    Default = false,
    Tip = 'Automatically positions your character for quarterback play.',
})

autoQbMethod = AutomaticsTab:CreateDropdown({
    Name = 'Auto QB Method',
    Options = {'Walk', 'Teleport'},
    Default = 'Walk',
    Tip = 'Selects how automatic positioning is performed.',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoQb.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoid or not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        if replicatedStorage:FindFirstChild('Flags')
            and replicatedStorage.Flags:FindFirstChild('PossessionTag')
            and replicatedStorage.Flags:FindFirstChild('Status')
            and replicatedStorage.Flags.PossessionTag.Value == player.Team.Name
            and replicatedStorage.Flags.Status.Value == 'PrePlay' then

            if autoQbMethod.Value == 'Walk' then
                humanoid:MoveTo(ball.Position)
            elseif autoQbMethod.Value == 'Teleport' then
                humanoidRootPart.CFrame = ball.CFrame
            end
        else
            pcall(function()
                ball.CFrame = humanoidRootPart.CFrame
            end)
        end
    end
end)
    
AutomaticsTab:CreateDivider()
    
    autoBoost = AutomaticsTab:CreateToggle({
    Name = 'Auto Boost',
    Default = false,
    Tip = 'Automatically assists aerial movement near incoming footballs.',
})

targetClosestPlayer = AutomaticsTab:CreateToggle({
    Name = 'Target Player Closer To The Ball',
    Default = false,
    Tip = 'Prioritizes players closest to the football.',
})

boostStrength = AutomaticsTab:CreateSlider({
    Name = 'Boost Strength',
    Min = 0,
    Max = 3,
    Default = 1.5,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Adjusts the strength of the boost effect.',
})

boostRadius = AutomaticsTab:CreateSlider({
    Name = 'Boost Radius',
    Min = 0,
    Max = 15,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the activation distance for boosting.',
})

boostPower = AutomaticsTab:CreateSlider({
    Name = 'Boost Power',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Controls the upward force applied during a boost.',
})

task.spawn(function()
    local activeTween

    while true do
        task.wait()

        if not autoBoost.Value then
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            continue
        end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum then continue end

        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end

        if hum:GetState() == Enum.HumanoidStateType.Landed then
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            continue
        end

        local myHead = char:FindFirstChild('Head')
        if not myHead then continue end

        local targetPlayer

        if targetClosestPlayer.Value then
            local nearestBall
            local nearestBallDist = math.huge

            for _, ball in next, workspace:GetChildren() do
                if not ball:IsA('BasePart') then continue end
                if not ball.Name:lower():find('ball') then continue end

                local dist = (ball.Position - myHead.Position).Magnitude

                if dist < nearestBallDist then
                    nearestBallDist = dist
                    nearestBall = ball
                end
            end

            if not nearestBall then continue end

            local closestDist = math.huge

            for _, v in next, players:GetPlayers() do
                if v == player then continue end

                local character = v.Character
                if not character then continue end

                local head = character:FindFirstChild('Head')
                if not head then continue end

                local dist = (head.Position - nearestBall.Position).Magnitude

                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = v
                end
            end
        else
            local closestDist = math.huge

            for _, v in next, players:GetPlayers() do
                if v == player then continue end

                local character = v.Character
                if not character then continue end

                local head = character:FindFirstChild('Head')
                if not head then continue end

                local dist = (head.Position - myHead.Position).Magnitude

                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = v
                end
            end
        end

        if not targetPlayer then continue end

        local character = targetPlayer.Character
        if not character then continue end

        local head = character:FindFirstChild('Head')
        if not head then continue end

        local targetHumanoid = character:FindFirstChildOfClass('Humanoid')
        if not targetHumanoid then continue end

        local myState = hum:GetState()
        local targetState = targetHumanoid:GetState()

        local distance = (head.Position - myHead.Position).Magnitude

        if distance > boostRadius.Value then
            continue
        end

        if myState ~= Enum.HumanoidStateType.Jumping
            and myState ~= Enum.HumanoidStateType.Freefall then
            continue
        end

        if targetState ~= Enum.HumanoidStateType.Jumping
            and targetState ~= Enum.HumanoidStateType.Freefall then
            continue
        end

        local speed = math.max(hum.WalkSpeed * boostStrength.Value, 1)
        local targetPos = head.Position

        local duration = math.max((hrp.Position - targetPos).Magnitude / speed, 0.01)

        if activeTween then
            activeTween:Cancel()
        end

        activeTween = tweenService:Create(
            hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {
                CFrame = CFrame.new(targetPos)
            }
        )

        activeTween:Play()

        activeTween.Completed:Once(function(state)
            if state ~= Enum.PlaybackState.Completed then
                return
            end

            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                boostPower.Value,
                hrp.AssemblyLinearVelocity.Z
            )
        end)
    end
end)

local MiscTab = Window:CreateTab({ Name = 'Misc', Icon = 'rbxassetid://129082556946713' })

fpsCap = MiscTab:CreateSlider({
    Name = 'Uncap FPS Amount',
    Min = 30,
    Max = 240,
    Default = 240,
    Increment = 1,
    Suffix = '',
    Tip = 'Sets the maximum FPS limit.',
})

task.spawn(function()
    while true do
        task.wait()

        setfpscap(fpsCap.Value)
    end
end)

antiAdmin = MiscTab:CreateToggle({
    Name = 'Anti Admin',
    Default = false,
    Tip = 'Automatically reacts when administrators are detected.',
    Keybind = nil,
})

task.spawn(function()
    while task.wait() do
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then continue end
        
        local miscText = playerGui:FindFirstChild("MiscText")
        if not miscText then continue end
        
        local isVIP = miscText:FindFirstChild("IsVIP")
        if not isVIP then continue end
        
        if isVIP.Visible == true then continue end
        
        for _, admin in next, players:GetPlayers() do
            if admin == player then continue end
            
            local swagData = admin:FindFirstChild("SwagData")
            if not swagData then continue end
            
            local adminTag = swagData:FindFirstChild("Admin")
            if not adminTag then continue end
            
            if adminTag.Value ~= "" and antiAdmin.Value then
                player:Kick("[Aethel Hub] Detected AdminName: " .. admin.Name .. "ID: " .. admin.UserId)
            end
        end
    end
end)

smoothReplay = MiscTab:CreateToggle({
		Name = 'Smooth Replay',
		Default = false,
		Tip = 'Smooths replay playback for improved visual quality.',
		Keybind = nil,
	})

	replayFPS = MiscTab:CreateSlider({
		Name = 'Replay Frame Per Second',
		Min = 9,
		Max = 120,
		Default = 9,
		Increment = 1,
		Tip = 'Sets the replay playback frame rate.',
	})
    
if not isPractice then

	local player = game:GetService('Players').LocalPlayer
	local replicatedStorage = game:GetService('ReplicatedStorage')
	local runService = game:GetService('RunService')

	local remote = replicatedStorage:WaitForChild('Remotes'):WaitForChild('CharacterSoundEvent')
	local heartbeat = runService.Heartbeat

	local transition = player:WaitForChild('PlayerGui'):WaitForChild('MainGui'):WaitForChild('Transition')

	local homeCamera = CFrame.Angles(-0.2617993877991494, 0, 0)
	local awayCamera = CFrame.Angles(0.2617993877991494, math.pi, 0)

	local cameraOffset = CFrame.new(0, 0, 19)

	local limbs = {
		'Torso',
		'Left Arm',
		'Right Arm',
		'Left Leg',
		'Right Leg',
		'Head'
	}

	task.spawn(function()
		while true do
			task.wait()

			local replayScript = player.PlayerScripts:FindFirstChild('ClientReplay')
			if replayScript then
				replayScript.Enabled = not smoothReplay.Value
			end
		end
	end)

	local replay = function(data, characters)
		local replayBall = workspace:WaitForChild('ReplayBall')
		local camera = workspace.CurrentCamera

		camera.CameraType = Enum.CameraType.Scriptable
		camera.CameraSubject = replayBall

		local cameraRotation = data.changes[1].poss == 'h' and homeCamera or awayCamera

		local currentChange = 1
		local highestY = 18
		local cameraTilt = true

		local playback = 1
		local recordedFPS = data.fps

		local accumulator = 0
		local last = tick()

		local getFrame = function(index)
			local maxFrames = #data.ball
			if index < 1 then return 1 end
			if index > maxFrames then return maxFrames end
			return index
		end

		local interpolate = function(a, b, alpha)
			return a:Lerp(b, alpha)
		end

		while playback < #data.ball do
			if replicatedStorage.Flags.StatusTag.Value ~= 'REPLAY' then
				break
			end

			if camera.CameraType ~= Enum.CameraType.Scriptable then
				break
			end

			local replayFPSValue = replayFPS.Value
			local replayDelta = 1 / replayFPSValue

			local now = tick()
			accumulator += now - last
			last = now

			while accumulator >= replayDelta do
				playback += recordedFPS / replayFPSValue
				accumulator -= replayDelta
			end

			local frame1 = getFrame(math.floor(playback))
			local frame2 = getFrame(math.ceil(playback))
			local alpha = playback - frame1

			for _, character in next, characters do
				local characterData = data.limbs[character.Name]
				if not characterData then character.Parent = nil continue end

				local limbData = characterData[1]
				local accessoryData = characterData[2]

				if not limbData[1] then
					character.Parent = nil
					continue
				end

				local torso1 = limbData[1][2][frame1]
				local torso2 = limbData[1][2][frame2]

				if not torso1 or not torso2 then
					character.Parent = nil
					continue
				end

				local torso = interpolate(torso1, torso2, alpha)

				for i = 1, #limbs do
					local limbName = limbs[i]
					local limb = character:FindFirstChild(limbName)
					if not limb then continue end

					local replayLimb = limbData[i]
					if not replayLimb then continue end

					local cf1 = replayLimb[2][frame1]
					local cf2 = replayLimb[2][frame2]

					if i == 4 then
						if cf1 and cf2 then
							local angle = cf1 + ((cf2 - cf1) * alpha)

							limb.CFrame =
								torso *
								CFrame.new(-0.5, -1, 0) *
								CFrame.fromOrientation(angle, 0, 0) *
								CFrame.new(0, -1, 0)
						end
					elseif i == 5 then
						if cf1 and cf2 then
							local angle = cf1 + ((cf2 - cf1) * alpha)

							limb.CFrame =
								torso *
								CFrame.new(0.5, -1, 0) *
								CFrame.fromOrientation(angle, 0, 0) *
								CFrame.new(0, -1, 0)
						end
					else
						if cf1 and cf2 then
							limb.CFrame = interpolate(cf1, cf2, alpha)
						elseif i == 6 then
							limb.CFrame = torso * CFrame.new(0, 1.5, 0)
						end
					end
				end

				local uniform = character:FindFirstChild('Uniform')
				if accessoryData and uniform then
					for name, info in next, accessoryData do
						if uniform:FindFirstChild(name) and character:FindFirstChild(info[1]) then
							uniform[name].CFrame =
								character[info[1]].CFrame * info[2]
						end
					end
				end
			end

			local ball1 = data.ball[frame1]
			local ball2 = data.ball[frame2]

			if ball1 and ball2 then
				replayBall.CFrame = interpolate(ball1, ball2, alpha)
			end

			if highestY < replayBall.Position.Y then
				highestY = replayBall.Position.Y
			elseif highestY > 49 and cameraTilt then
				local x = select(1, cameraRotation:ToOrientation())

				cameraRotation *= CFrame.Angles(
					x * 3 * math.clamp((highestY - 50) / 99, 0, 1),
					0,
					0
				)

				cameraTilt = false
			end

			local targetCamera

			if highestY > 49 and cameraTilt then
				local x = select(1, cameraRotation:ToOrientation())

				targetCamera =
					CFrame.new(replayBall.Position) *
					cameraRotation *
					CFrame.Angles(
						x * 3 * math.clamp((highestY - 50) / 99, 0, 1),
						0,
						0
					) *
					cameraOffset
			else
				targetCamera =
					CFrame.new(replayBall.Position) *
					cameraRotation *
					cameraOffset
			end

			camera.CFrame = targetCamera

			local change = data.changes[currentChange]

			if change and change.frame <= frame1 then
				currentChange += 1

				if change.frame == frame1 then
					if change.poss and (frame1 > 9 and (change.turnover or highestY > 49)) then
						local nextRotation =
							change.poss == 'h' and homeCamera or awayCamera

						local duration =
							(change.turnover == true or replayBall.Position.Y >= 13)
							and 0.5
							or (highestY / 500)

						local elapsed = 0
						local startRotation = cameraRotation

						while elapsed < duration do
							elapsed += heartbeat:Wait()

							cameraRotation = startRotation:Lerp(
								nextRotation,
								math.clamp(elapsed / duration, 0, 1)
							)

							camera.CFrame =
								CFrame.new(replayBall.Position) *
								cameraRotation *
								cameraOffset
						end

						cameraRotation = nextRotation

					elseif change.freeze then
						task.wait(change.freeze)
					end
				end
			end

			heartbeat:Wait()
		end

		remote:FireServer('ReplayFinished')

		if replicatedStorage.Flags.StatusTag.Value == 'REPLAY' then
			replicatedStorage.Flags.StatusTag.Value = ''
		end

		task.wait(0.2)

		replayBall:Destroy()

		for _, character in next, characters do
			character:Destroy()
		end

		data.t = nil
		data.limbs = nil
		data.ball = nil

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = player.Character.Humanoid
	end

	remote.OnClientEvent:Connect(function(action, ...)
		if action == 'ClientReplay' then
			while transition.Position.X.Scale > -2 and transition.Position.X.Scale < -0.5 do
				task.wait()
			end

			replay(...)
		end
	end)

end
        pcall(function() RealWindow:Notify({ title = "Aethel Hub", content = "Football Fusion 3 loaded.", duration = 4 }) end)
    end)
    if not ff3ok then
        pcall(function() _print("[Aethel Hub] Football Fusion 3 failed to load:", ff3err) end)
    end
elseif isBladeBall then
    -- ========================================================
    -- BRANCH: BLADE BALL
    -- ========================================================
    local bbOk, bbErr = pcall(function()
        local Window = Airflow:CreateWindow({
            Name = "Aethel Hub",
            LoadingSubtitle = "Blade Ball",
            Theme = "AethelDusk",
            ToggleUIKeybind = "RightControl",
            ConfigurationSaving = { Enabled = true, FolderName = "AethelHub", FileName = "BladeBall" },
        })
        local MainTab = Window:CreateTab({ Name = "Main", Icon = "swords" })

        local S = {
            AutoParry = false, ManualSpam = false, FollowBall = false,
            Mult = 0.5, Visualizer = false, SpamAbility = false,
            SpamOn = false, -- on-screen SpamParry button state
        }

        -- // Helpers
        local function click()
            VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, false)
            VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, false)
        end

        local function getBall()
            local balls = workspace:FindFirstChild("Balls")
            if not balls then return nil end
            for _, b in ipairs(balls:GetChildren()) do
                if b:GetAttribute("realBall") then return b end
            end
            return nil
        end

        local function getRoot()
            local c = LocalPlayer.Character
            return c and c:FindFirstChild("HumanoidRootPart")
        end

        local function ballSpeed(ball)
            local ok, v = pcall(function() return ball.zoomies.VectorVelocity.Magnitude end)
            return (ok and tonumber(v)) or 0
        end

        -- // UI
        MainTab:CreateSection("Parry")
        MainTab:CreateToggle({
            Name = "Auto Parry",
            Desc = "Parries automatically when the ball is targeting you and gets close.",
            Flag = "bb_autoparry", CurrentValue = false,
            Callback = function(v) S.AutoParry = v end,
        })
        MainTab:CreateSlider({
            Name = "Parry Distance Multiplier",
            Desc = "Higher = parries earlier (from further away).",
            Range = { 0.1, 3 }, Increment = 0.01, Suffix = "",
            CurrentValue = 0.5, Flag = "bb_mult",
            Callback = function(v) S.Mult = tonumber(v) or S.Mult end,
        })
        MainTab:CreateToggle({
            Name = "Manual Spam",
            Desc = "Shows a draggable SpamParry button on screen.",
            Flag = "bb_manualspam", CurrentValue = false,
            Callback = function(v) S.ManualSpam = v end,
        })
        MainTab:CreateSection("Extras")
        MainTab:CreateToggle({
            Name = "Follow Ball",
            Desc = "Walks your character toward the ball.",
            Flag = "bb_follow", CurrentValue = false,
            Callback = function(v) S.FollowBall = v end,
        })
        MainTab:CreateToggle({
            Name = "Show Visualizer",
            Desc = "Shows your parry range and the ball's speed.",
            Flag = "bb_visualizer", CurrentValue = false,
            Callback = function(v) S.Visualizer = v end,
        })
        MainTab:CreateToggle({
            Name = "Spam Ability",
            Desc = "Presses Q (your ability) every half second.",
            Flag = "bb_spamability", CurrentValue = false,
            Callback = function(v) S.SpamAbility = v end,
        })

        -- // On-screen SpamParry button (draggable)
        local hudParent = nil
        pcall(function() hudParent = (gethui and gethui()) or CoreGui end)
        if not hudParent or (hudParent == CoreGui and not pcall(function() Instance.new("Folder", CoreGui):Destroy() end)) then
            hudParent = LocalPlayer:WaitForChild("PlayerGui", 10)
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "AethelBladeBall"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = hudParent

        local spamBtn = Instance.new("TextButton")
        spamBtn.Size = UDim2.new(0, 170, 0, 44)
        spamBtn.Position = UDim2.new(0.5, -85, 0.15, 0)
        spamBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        spamBtn.BackgroundTransparency = 0.1
        spamBtn.AutoButtonColor = false
        spamBtn.Font = Enum.Font.GothamBold
        spamBtn.TextSize = 16
        spamBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        spamBtn.Text = "SpamParry [OFF]"
        spamBtn.Visible = false
        spamBtn.Parent = gui
        Instance.new("UICorner", spamBtn).CornerRadius = UDim.new(0, 8)
        local spamStroke = Instance.new("UIStroke", spamBtn)
        spamStroke.Color = Color3.fromRGB(240, 240, 240)
        spamStroke.Transparency = 0.5

        local dragging, dragMoved, dragStart, startPos = false, false, nil, nil
        spamBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging, dragMoved = true, false
                dragStart, startPos = input.Position, spamBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if not dragMoved then
                            S.SpamOn = not S.SpamOn
                            spamBtn.Text = S.SpamOn and "SpamParry [ON]" or "SpamParry [OFF]"
                        end
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                if delta.Magnitude > 10 then dragMoved = true end
                if dragMoved then
                    spamBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end)

        -- // Visualizer (range circles + speed label)
        local circle, circleFollow, speedGui, speedLabel = nil, nil, nil, nil

        local function makeCircle(name)
            local part = Instance.new("Part")
            part.Name = name
            part.Color = Color3.fromRGB(0, 0, 255)
            part.Material = Enum.Material.Plastic
            part.Transparency = 0.75
            part.Size = Vector3.new(10, 0.4, 10)
            part.CanCollide = false
            part.Anchored = true
            local mesh = Instance.new("SpecialMesh", part)
            mesh.MeshId = "rbxassetid://471124075"
            mesh.MeshType = Enum.MeshType.FileMesh
            part.Parent = workspace
            return part, mesh
        end

        local circleMesh, followMesh
        local function destroyVisualizer()
            if circle then circle:Destroy(); circle = nil end
            if circleFollow then circleFollow:Destroy(); circleFollow = nil end
            if speedGui then speedGui:Destroy(); speedGui = nil; speedLabel = nil end
        end

        local function createSpeedGui()
            local char = LocalPlayer.Character
            local head = char and char:FindFirstChild("Head")
            if not head then return end
            speedGui = Instance.new("BillboardGui")
            speedGui.Name = "AethelBallSpeed"
            speedGui.Size = UDim2.new(6, 0, 1.5, 0)
            speedGui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
            speedGui.AlwaysOnTop = false
            speedGui.MaxDistance = 100
            speedGui.Parent = head
            speedLabel = Instance.new("TextLabel", speedGui)
            speedLabel.Size = UDim2.new(1, 0, 1, 0)
            speedLabel.BackgroundTransparency = 1
            speedLabel.TextScaled = true
            speedLabel.Font = Enum.Font.GothamBold
            speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UIStroke", speedLabel).Thickness = 2
        end

        -- // Auto parry state: one parry per target change (re-armed after 1s if still targeted)
        local parried, lastParry = false, 0
        local watched = setmetatable({}, { __mode = "k" })
        local function watchBall(ball)
            if watched[ball] then return end
            watched[ball] = true
            ball:GetAttributeChangedSignal("target"):Connect(function() parried = false end)
        end

        local lastQ = 0
        RunService.Heartbeat:Connect(function()
            spamBtn.Visible = S.ManualSpam
            if not S.ManualSpam and S.SpamOn then
                S.SpamOn = false
                spamBtn.Text = "SpamParry [OFF]"
            end

            if S.SpamOn then pcall(click) end

            local ball = getBall()
            local root = getRoot()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if ball then watchBall(ball) end

            -- Auto Parry
            if S.AutoParry and ball and root and ball:GetAttribute("target") == LocalPlayer.Name then
                if parried and tick() - lastParry >= 1 then parried = false end
                if not parried then
                    local spd = ballSpeed(ball)
                    if spd > 0 and (root.Position - ball.Position).Magnitude / spd <= S.Mult then
                        pcall(click)
                        parried = true
                        lastParry = tick()
                    end
                end
            end

            -- Follow Ball
            if S.FollowBall and ball and hum then
                pcall(function() hum:MoveTo(ball.Position) end)
            end

            -- Spam Ability
            if S.SpamAbility and tick() - lastQ >= 0.5 then
                lastQ = tick()
                pcall(function()
                    VirtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                    VirtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                end)
            end

            -- Visualizer
            if S.Visualizer and root then
                if not circle or not circle.Parent then
                    circle, circleMesh = makeCircle("Circle")
                    circleFollow, followMesh = makeCircle("CircleFollowBall")
                    circleFollow.Transparency = 0
                end
                if not speedGui or not speedGui.Parent then createSpeedGui() end
                circle.CFrame = root.CFrame
                if ball then
                    local spd = ballSpeed(ball)
                    local scale = spd / 500 * 3 * S.Mult
                    circleFollow.CFrame = CFrame.new(root.Position, ball.Position)
                    circleMesh.Scale = Vector3.new(scale, 0.05, scale)
                    followMesh.Scale = Vector3.new(scale, 0.05, scale)
                    if speedLabel then speedLabel.Text = tostring(math.round(spd * S.Mult)) end
                else
                    circleFollow.CFrame = root.CFrame
                end
            elseif not S.Visualizer and (circle or circleFollow or speedGui) then
                destroyVisualizer()
            end
        end)

        pcall(function() Window:Notify({ title = "Aethel Hub", content = "Blade Ball loaded.", duration = 4 }) end)
    end)
    if not bbOk then
        pcall(function() _print("[Aethel Hub] Blade Ball failed to load:", bbErr) end)
    end
elseif isMM2 then
    -- ========================================================
    -- BRANCH: MURDER MYSTERY 2
    -- ========================================================
    local mmOk, mmErr = pcall(function()
local Window = Airflow:CreateWindow({
    Name = "Aethel Hub",
    LoadingSubtitle = "Murder Mystery 2",
    Theme = "AethelDusk",
    ToggleUIKeybind = "RightControl",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AethelHub",
        FileName = "MM2",
    },
})

local Notify = function(props) pcall(function() Window:Notify(props) end) end

isWindowOpen = false
updateWindowOpenState = function()
    if Window and type(Window.IsOpen) == "function" then
        ok, val = pcall(function() return Window:IsOpen() end)
        if ok and type(val) == "boolean" then
            isWindowOpen = val
            return
        end
    end
    if Window and Window.Opened ~= nil then
        isWindowOpen = Window.Opened
        return
    end
    isWindowOpen = isWindowOpen or false
end

pcall(updateWindowOpenState)
function safeResolve(value)
    if not Localization or not Localization.Enabled then
        return value
    end
    
    if type(value) == "string" and value:sub(1, #Localization.Prefix) == Localization.Prefix then
        local key = value:sub(#Localization.Prefix + 1)
        local lang = Localization.Translations and Localization.Translations[Localization.DefaultLanguage]
        if lang and lang[key] then
            return lang[key]
        end
    end
    
    return value
end

function resolveWindowProperties(window)
    if not window then return end
    
    if window.Title and type(window.Title) == "string" then
        window.Title = safeResolve(window.Title)
    end
    if window.Author and type(window.Author) == "string" then
        window.Author = safeResolve(window.Author)
    end
end

resolveWindowProperties(Window)

print("Window Title:", Window.Title)
print("Window Author:", Window.Author)

Players = game:GetService("Players")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
VirtualUser = game:GetService("VirtualUser")
Lighting = game:GetService("Lighting")
ReplicatedStorage = game:GetService("ReplicatedStorage")
workspace = game:GetService("Workspace")
originalGameGravity = workspace.Gravity
TeleportService = game:GetService("TeleportService")
HttpService = game:GetService("HttpService")
MarketplaceService = game:GetService("MarketplaceService")
player = Players.LocalPlayer
playerGui = player:WaitForChild("PlayerGui")
placeId = game.PlaceId
jobId = game.JobId

featureStates = {
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 5,
    TPWALK = false,
    TpwalkValue = 1,
    JumpBoost = false,
    JumpPower = 5,
    AntiAFK = false,
    SpeedHack = false,
    SpeedValue = 16,
    Noclip = false,
    InnocentESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    MurderESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    HeroSheriffESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    InnocentHighlights = false,
    MurderHighlights = false,
    SheriffHeroHighlights = false
}

local function IsAlive(Player, currentRoles)
    for i, v in pairs(currentRoles) do
        if Player.Name == i then
            if not v.Killed and not v.Dead then
                return true
            else
                return false
            end
        end
    end
    return false
end

local function getOutlineColor(c)
    local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    if lum > 0.5 then
        return Color3.new(0,0,0)
    else
        return Color3.new(1,1,1)
    end
end

Tabs = {
    Main     = Window:CreateTab({ Name = "Main",     Icon = "layout-grid" }),
    Player   = Window:CreateTab({ Name = "Player",   Icon = "user" }),
    Combat   = Window:CreateTab({ Name = "Combat",   Icon = "swords" }),
    Visuals  = Window:CreateTab({ Name = "Visuals",  Icon = "camera" }),
    Esp      = Window:CreateTab({ Name = "Esp",      Icon = "eye" }),
    Teleport = Window:CreateTab({ Name = "Teleport", Icon = "navigation" }),
    Misc     = Window:CreateTab({ Name = "Misc",     Icon = "star" }),
    Utility  = Window:CreateTab({ Name = "Utility",  Icon = "wrench" }),
    Settings = Window:CreateTab({ Name = "Settings", Icon = "settings" }),
    Info     = Window:CreateTab({ Name = "Info",     Icon = "info" }),
}

Tabs.Main:CreateSection("Server Info")
Tabs.Main:CreateDivider()

placeName = "Unknown"
success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)
if success and productInfo then
    placeName = productInfo.Name
end

Tabs.Main:CreateParagraph({
    Title = "Game Mode",
    Content = placeName
})

Tabs.Main:CreateButton({
    Name = "Copy Server Link",
    Desc = "Copy the current server's join link",
    Icon = "link",
    Callback = function()
        serverLink = string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
        pcall(function()
            setclipboard(serverLink)
        end)
    end
})

numPlayers = #Players:GetPlayers()
maxPlayers = Players.MaxPlayers

playerCountParagraph = Tabs.Main:CreateParagraph({
    Title = "Current Players",
    Content = numPlayers .. " / " .. maxPlayers
})

RunService.Heartbeat:Connect(function()
    local modelCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if workspace:FindFirstChild(player.Name) then
            modelCount = modelCount + 1
        end
    end
    
    playerCountParagraph:Set(numPlayers .. " Online/ " .. maxPlayers .. "Max | Player Models Found: " .. modelCount .. "")
end)
ModelPlayerAntiBrokenServer = Tabs.Main:CreateParagraph({
    Title = "Player Model Server Status",
    Content = "Waiting..."
})

playerModelCheckConnection = RunService.Heartbeat:Connect(function()
    local playerCount = #Players:GetPlayers()
    local modelCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if workspace:FindFirstChild(player.Name) then
            modelCount = modelCount + 1
        end
    end
    
    if playerCount == modelCount then
        ModelPlayerAntiBrokenServer:Set("Player Model Is Correct Definitely Playable")
    else
        ModelPlayerAntiBrokenServer:Set("Unplayable Server Detected! Missing Player Model, Find a new server")
    end
end)
Tabs.Main:CreateParagraph({
    Title = "Server ID",
    Content = jobId
})

Tabs.Main:CreateParagraph({
    Title = "Place ID",
    Content = tostring(placeId)
})

Tabs.Main:CreateSection("Server Tools")
Tabs.Main:CreateDivider()

Tabs.Main:CreateButton({
    Name = "Rejoin",
    Desc = "Rejoin the current server",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, player)
    end
})

Tabs.Main:CreateButton({
    Name = "Server Hop",
    Desc = "Hop to a random server",
    Icon = "shuffle",
    Callback = function()
        AllIDs = {}
        foundAnything = ""
        actualHour = os.date("!*t").hour
        Deleted = false
        S_T = game:GetService("TeleportService")
        S_H = game:GetService("HttpService")

        File = pcall(function()
            AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            pcall(function()
                writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
            end)
        end

        function TPReturner(placeId)
            local Site;
            if foundAnything == "" then
                Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0;
            for i,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                            end
                        else
                            if tonumber(actualHour) ~= tonumber(Existing) then
                                local delFile = pcall(function()
                                    delfile("server-hop-temp.json")
                                    AllIDs = {}
                                    table.insert(AllIDs, actualHour)
                                end)
                            end
                        end
                        num = num + 1
                    end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                            wait()
                            S_T:TeleportToPlaceInstance(placeId, ID, game.Players.LocalPlayer)
                        end)
                        wait(4)
                    end
                end
            end
        end

        function Teleport(placeId)
            while wait() do
                pcall(function()
                    TPReturner(placeId)
                    if foundAnything ~= "" then
                        TPReturner(placeId)
                    end
                end)
            end
        end

        Teleport(game.PlaceId)
    end
})

Tabs.Main:CreateButton({
    Name = "Hop to Small Server",
    Desc = "Hop to the smallest available server",
    Icon = "minimize",
    Callback = function()
        request = request or (http and http.request) or (syn and syn.request)
        if not request then
            return
        end

        response = request({
            Url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET",
        })

        if response.StatusCode == 200 then
            serverData = HttpService:JSONDecode(response.Body)
            smallestServer = nil
            smallestPlayerCount = math.huge

            for _, server in pairs(serverData.data) do
                if server.id ~= jobId and server.playing < server.maxPlayers and server.playing < smallestPlayerCount then
                    smallestPlayerCount = server.playing
                    smallestServer = server
                end
            end

            if smallestServer then
                TeleportService:TeleportToPlaceInstance(placeId, smallestServer.id, player)
            end
        end
    end
})

Tabs.Main:CreateButton({
    Name = "Advanced Server Hop",
    Desc = "Finding a Server inside your game",
    Icon = "server",
    Callback = function()
        success, result = pcall(function()
            script = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Advanced%20Server%20Hop.lua"))()
        end)
    end
})

AutoServerHopToggle = Tabs.Main:CreateToggle({
    Name = "Auto Server Hop",
    Flag = "AutoServerHopToggle",
    Desc = "Note: If you use this for auto farm be sure enable auto load/save config",
    CurrentValue = false,
    Callback = function(state)
        if state then
            if AutoServerHopInterval < 20 then
                Notify({
                    title = "Auto Server Hop",
                    content = "Interval must be at least 20 seconds!",
                     duration = 3,
                })
                if AutoServerHopToggle and AutoServerHopToggle.Set then
                    AutoServerHopToggle:Set(false)
                end
                return
            end
            startAutoServerHop()
        else
            stopAutoServerHop()
        end
    end
})

AutoServerHopTypeDropdown = Tabs.Main:CreateDropdown({
    Name = "Server Hop Type",
    Flag = "AutoServerHopTypeDropdown",
    Desc = "Choose between small or random server hopping",
    Options = {"Random", "Small"},
    CurrentValue = "Random",
    Callback = function(value)
        AutoServerHopType = value
        if AutoServerHopEnabled then
            stopAutoServerHop()
            startAutoServerHop()
        end
    end
})

AutoServerHopIntervalInput = Tabs.Main:CreateInput({
    Name = "Hop Interval (seconds)",
    Flag = "AutoServerHopIntervalInput",
    Desc = "Minimum 20 seconds",
    Placeholder = "30",
    NumbersOnly = true,
    CurrentValue = "30",
    Callback = function(value)
        local num = tonumber(value)
        if num and num >= 20 then
            AutoServerHopInterval = num
            if AutoServerHopEnabled then
                stopAutoServerHop()
                startAutoServerHop()
            end
        else
            Notify({
                title = "Auto Server Hop",
                content = "Interval must be at least 20 seconds!",
                     duration = 3,
            })
            AutoServerHopIntervalInput:Set("30")
            AutoServerHopInterval = 30
        end
    end
})

Tabs.Player:CreateSection("Player")
Tabs.Player:CreateDivider()

character = nil
humanoid = nil
rootPart = nil

function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if featureStates.JumpBoost and humanoid then
        humanoid.JumpPower = featureStates.JumpPower
        humanoid.JumpHeight = featureStates.JumpPower
        setupJumpBoost()
    end
    if featureStates.SpeedHack and humanoid then
        humanoid.WalkSpeed = featureStates.SpeedValue
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

UserInputService.JumpRequest:connect(function()
    if featureStates.InfiniteJump then
        player.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
    end
end)

InfiniteJumpToggle = Tabs.Player:CreateToggle({
    Name = "Infinite Jump",
        Flag = "InfiniteJumpToggle",
    CurrentValue = featureStates.InfiniteJump,
    Callback = function(state)
        featureStates.InfiniteJump = state
    end
})

SpeedToggle = Tabs.Player:CreateToggle({
    Name = "Speed Hack",
        Flag = "SpeedToggle",
    CurrentValue = featureStates.SpeedHack,
    Callback = function(state)
        featureStates.SpeedHack = state
        if state and humanoid then
            humanoid.WalkSpeed = featureStates.SpeedValue
        elseif humanoid then
            humanoid.WalkSpeed = 16
        end
    end
})

SpeedSlider = Tabs.Player:CreateSlider({
    Name = "Speed Value",
        Flag = "SpeedSlider",
    Desc = "Adjust walk speed",
    Range = {16, 200}, Increment = 1, CurrentValue = featureStates.SpeedValue,
    Callback = function(value)
        featureStates.SpeedValue = value
        if featureStates.SpeedHack and humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

Noclip = nil
Clip = nil

function noclip()
    Clip = false
    local function Nocl()
        if Clip == false and player.Character ~= nil then
            for _,v in pairs(player.Character:GetDescendants()) do
                if v:IsA('BasePart') and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = RunService.Stepped:Connect(Nocl)
end

function clip()
    if Noclip then 
        Noclip:Disconnect() 
    end
    Clip = true
    if player.Character then
        for _,v in pairs(player.Character:GetDescendants()) do
            if v:IsA('BasePart') then
                v.CanCollide = true
            end
        end
    end
end

NoclipToggle = Tabs.Player:CreateToggle({
    Name = "Noclip",
        Flag = "NoclipToggle",
    CurrentValue = featureStates.Noclip,
    Callback = function(state)
        featureStates.Noclip = state
        if state then
            noclip()
        else
            clip()
        end
    end
})

flying = false
bodyVelocity = nil
bodyGyro = nil
flyConnection = nil

function startFlying()
    if not character or not humanoid or not rootPart then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    humanoid.PlatformStand = true
end

function stopFlying()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if humanoid then
        humanoid.PlatformStand = false
    end
end

function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    camera = workspace.CurrentCamera
    cameraCFrame = camera.CFrame
    direction = Vector3.new(0, 0, 0)
    moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        forwardVector = cameraCFrame.LookVector
        rightVector = cameraCFrame.RightVector
        forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (featureStates.FlySpeed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

FlyToggle = Tabs.Player:CreateToggle({
    Name = "Fly",
        Flag = "FlyToggle",
    CurrentValue = featureStates.Fly,
    Callback = function(state)
        featureStates.Fly = state
        if state then
            startFlying()
            flyConnection = RunService.Heartbeat:Connect(updateFly)
        else
            stopFlying()
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
        end
    end
})

FlySpeedSlider = Tabs.Player:CreateSlider({
    Name = "Fly Speed",
        Flag = "FlySpeedSlider",
    Range = {1, 200}, Increment = 1, CurrentValue = featureStates.FlySpeed,
    Desc = "Adjust fly speed",
    Callback = function(value)
        featureStates.FlySpeed = value
    end
})
local godModeEnabled = false
local godModeConnection = nil
local godModeMethod = "Health Math.huge"

local function applyHumanoidReplacement()
    local Char = player.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    
    local nHuman = Human:Clone()
    nHuman.Parent = Char
    player.Character = nil
    nHuman:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    nHuman.BreakJointsOnDeath = true
    nHuman.MaxHealth = math.huge
    nHuman.Health = math.huge
    Human:Destroy()
    player.Character = Char
    nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    local Script = Char:FindFirstChild("Animate")
    if Script then
        Script.Disabled = true
        wait()
        Script.Disabled = false
    end
end

local function applyHealthMathHuge()
    local Char = player.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    
    Human.MaxHealth = math.huge
    Human.Health = math.huge
    
    Human:GetPropertyChangedSignal("Health"):Connect(function()
        if godModeEnabled and Human.Health < Human.MaxHealth then
            Human.Health = Human.MaxHealth
        end
    end)
end

local function applyGodMode()
    if godModeMethod == "Humanoid Replacement (Very buggy)" then
        applyHumanoidReplacement()
    elseif godModeMethod == "Health Math.huge" then
        applyHealthMathHuge()
    end
end

local function startGodMode()
    if godModeConnection then return end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if godModeEnabled and player.Character then
            local Human = player.Character:FindFirstChildWhichIsA("Humanoid")
            if Human and Human.Health < math.huge then
                applyGodMode()
            end
        end
    end)
end

local function stopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

GodModeToggle = Tabs.Player:CreateToggle({
    Name = "God Mode",
        Flag = "GodModeToggle",
    Desc = "Become invincible",
    CurrentValue = false,
    Callback = function(state)
        godModeEnabled = state
        if state then
            applyGodMode()
            startGodMode()
        else
            stopGodMode()
        end
    end
})

GodModeMethodDropdown = Tabs.Player:CreateDropdown({
    Name = "God Mode Method",
        Flag = "GodModeMethodDropdown",
    Options = {"Health Math.huge", "Humanoid Replacement (Very buggy)"},
    CurrentValue = "Health Math.huge",
    MenuWidth = 400,
    Callback = function(value)
        godModeMethod = value
        if godModeEnabled then
            applyGodMode()
        end
    end
})
ToggleTpwalk = false
TpwalkConnection = nil

function Tpwalking()
    if ToggleTpwalk and character and humanoid and rootPart then
        moveDirection = humanoid.MoveDirection
        moveDistance = featureStates.TpwalkValue
        origin = rootPart.Position
        direction = moveDirection * moveDistance
        targetPosition = origin + direction
        raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastResult = workspace:Raycast(origin, direction, raycastParams)
        if raycastResult then
            hitPosition = raycastResult.Position
            distanceToHit = (hitPosition - origin).Magnitude
            if distanceToHit < math.abs(moveDistance) then
                targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
            end
        end
        rootPart.CFrame = CFrame.new(targetPosition) * rootPart.CFrame.Rotation
        rootPart.CanCollide = true
    end
end

function startTpwalk()
    ToggleTpwalk = true
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
    end
    TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
end

function stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
    if rootPart then
        rootPart.CanCollide = false
    end
end

TPWALKToggle = Tabs.Player:CreateToggle({
    Name = "TP WALK",
        Flag = "TPWALKToggle",
    CurrentValue = featureStates.TPWALK,
    Callback = function(state)
        featureStates.TPWALK = state
        if state then
            startTpwalk()
        else
            stopTpwalk()
        end
    end
})

TPWALKSlider = Tabs.Player:CreateSlider({
    Name = "TPWALK VALUE",
        Flag = "TPWALKSlider",
    Desc = "Adjust TPWALK speed",
    Range = {1, 200}, Increment = 1, CurrentValue = featureStates.TpwalkValue,
    Callback = function(value)
        featureStates.TpwalkValue = value
    end
})

jumpCount = 0
MAX_JUMPS = math.huge

function setupJumpBoost()
    if not character or not humanoid then return end
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)
    humanoid.Jumping:Connect(function(isJumping)
        if isJumping and featureStates.JumpBoost and jumpCount < MAX_JUMPS then
            jumpCount = jumpCount + 1
            humanoid.JumpHeight = featureStates.JumpPower
            if jumpCount > 1 then
                rootPart:ApplyImpulse(Vector3.new(0, featureStates.JumpPower * rootPart.Mass, 0))
            end
        end
    end)
end

function startJumpBoost()
    if humanoid then
        humanoid.JumpPower = featureStates.JumpPower
        humanoid.JumpHeight = featureStates.JumpPower
    end
    setupJumpBoost()
end

function stopJumpBoost()
    jumpCount = 0
    if humanoid then
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 50
    end
end

JumpBoostToggle = Tabs.Player:CreateToggle({
    Name = "Jump Height",
        Flag = "JumpBoostToggle",
    CurrentValue = featureStates.JumpBoost,
    Callback = function(state)
        featureStates.JumpBoost = state
        if state then
            startJumpBoost()
        else
            stopJumpBoost()
        end
    end
})

JumpBoostSlider = Tabs.Player:CreateSlider({
    Name = "Jump Power",
        Flag = "JumpBoostSlider",
    Desc = "Adjust jump height",
    Range = {1, 200}, Increment = 1, CurrentValue = featureStates.JumpPower,
    Callback = function(value)
        featureStates.JumpPower = value
        if featureStates.JumpBoost then
            if humanoid then
                humanoid.JumpPower = featureStates.JumpPower
                humanoid.JumpHeight = featureStates.JumpPower
            end
        end
    end
})

Tabs.Player:CreateButton({
    Name = "Walk on Walls (must reset to stop)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/randomstring0/Qwerty/refs/heads/main/qwerty21.lua"))()
    end
})
Tabs.Player:CreateToggle({
    Name = "Fake dead (lays)",
    Compact = true,
    CurrentValue = false,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if v then
            if hrp and hum then
                local animator = hum:FindFirstChild("Animator")
                if animator then
                    animator:Destroy()
                end

                hum:ChangeState(Enum.HumanoidStateType.Physics)
                hrp.Anchored = true
                hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
                hrp.CFrame = hrp.CFrame + Vector3.new(0, -2.5, 0)
            end
        else
            if hrp and hum then
                hrp.Anchored = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)

                if not hum:FindFirstChild("Animator") then
                    local newAnimator = Instance.new("Animator")
                    newAnimator.Parent = hum
                end
            end
        end
    end
})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

AimbotEnabled = false
ShowFOV = false
FOVThickness = 2
FOVColor = Color3.new(0, 1, 0)
LocalPlayer = Players.LocalPlayer
Cam = workspace.CurrentCamera

targetRoles = {}
aimPart = "Head"
smoothnessValue = 10
wallCheckEnabled = false
fovRadius = 100
lockFOVToCenter = true
AimbotCircle = nil
aimbotRenderConnection = nil
aimbotRunning = false

function getAimPart(character)
    if aimPart == "Head" then
        return character:FindFirstChild("Head")
    elseif aimPart == "Body" then
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif aimPart == "Legs" then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("Head")
end

function getPlayerRole(player)
    return "Unknown"
end

function isVisible(part)
    if not wallCheckEnabled then
        return true
    end
    
    character = LocalPlayer.Character
    if not character then return false end
    
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    origin = humanoidRootPart.Position
    target = part.Position
    direction = (target - origin).Unit
    ray = Ray.new(origin, direction * (target - origin).Magnitude)
    hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {character, part.Parent})
    
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

function lookAt(pos)
    currentCFrame = Cam.CFrame
    lookVector = (pos - currentCFrame.Position).Unit
    targetCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + lookVector)
    
    Cam.CFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothnessValue)
end

function getClosestEnemyInFOV()
    closestPlayer = nil
    closestDistance = math.huge
    
    if lockFOVToCenter then
        screenCenter = Cam.ViewportSize / 2
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                char = player.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    aimPartInstance = getAimPart(char)
                    if aimPartInstance then
                        playerRole = getPlayerRole(player)
                        shouldTarget = false
                        
                        if #targetRoles == 0 then
                            shouldTarget = true
                        else
                            for _, role in ipairs(targetRoles) do
                                if (role == "Murderer" and playerRole == "Murderer") or
                                   (role == "Sheriff" and playerRole == "Sheriff") or
                                   (role == "Hero" and playerRole == "Hero") or
                                   (role == "Innocent" and playerRole == "Innocent") or
                                   (role == "Unknown" and playerRole == "Unknown") then
                                    shouldTarget = true
                                    break
                                end
                            end
                        end
                        
                        if shouldTarget then
                            screenPos, visible = Cam:WorldToViewportPoint(aimPartInstance.Position)
                            distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

                            if visible and distance < fovRadius and distance < closestDistance and isVisible(aimPartInstance) then
                                closestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    else
        mousePos = UserInputService:GetMouseLocation()
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                char = player.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    aimPartInstance = getAimPart(char)
                    if aimPartInstance then
                        playerRole = getPlayerRole(player)
                        shouldTarget = false
                        
                        if #targetRoles == 0 then
                            shouldTarget = true
                        else
                            for _, role in ipairs(targetRoles) do
                                if (role == "Murderer" and playerRole == "Murderer") or
                                   (role == "Sheriff" and playerRole == "Sheriff") or
                                   (role == "Hero" and playerRole == "Hero") or
                                   (role == "Innocent" and playerRole == "Innocent") or
                                   (role == "Unknown" and playerRole == "Unknown") then
                                    shouldTarget = true
                                    break
                                end
                            end
                        end
                        
                        if shouldTarget then
                            screenPoint, onScreen = Cam:WorldToScreenPoint(aimPartInstance.Position)
                            if onScreen then
                                distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                                if distance < fovRadius and distance < closestDistance and isVisible(aimPartInstance) then
                                    closestDistance = distance
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

function createFOVCircle()
    if AimbotCircle then 
        AimbotCircle:Remove() 
        AimbotCircle = nil
    end
    
    circle = Drawing.new("Circle")
    circle.Visible = ShowFOV
    circle.Radius = fovRadius
    circle.Color = FOVColor
    circle.Thickness = FOVThickness
    circle.Filled = false
    
    if lockFOVToCenter then
        viewportSize = Cam.ViewportSize
        circle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        circle.Position = UserInputService:GetMouseLocation()
    end
    
    AimbotCircle = circle
    
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
    end
    
    aimbotRenderConnection = RunService.RenderStepped:Connect(function()
        if circle then
            circle.Radius = fovRadius
            circle.Visible = ShowFOV
            circle.Color = FOVColor
            circle.Thickness = FOVThickness
            
            if lockFOVToCenter then
                viewportSize = Cam.ViewportSize
                circle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
            else
                circle.Position = UserInputService:GetMouseLocation()
            end
        end
    end)
end

function updateDrawings()
    if AimbotCircle then
        AimbotCircle.Visible = ShowFOV
        AimbotCircle.Radius = fovRadius
        AimbotCircle.Color = FOVColor
        AimbotCircle.Thickness = FOVThickness
        
        if lockFOVToCenter then
            viewportSize = Cam.ViewportSize
            AimbotCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        else
            AimbotCircle.Position = UserInputService:GetMouseLocation()
        end
    end
end

function startAimbot()
    createFOVCircle()
    
    aimbotRunning = true
    
    while AimbotEnabled and aimbotRunning do
        RunService.RenderStepped:Wait()
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
            continue
        end
        
        closestPlayer = getClosestEnemyInFOV()
        if closestPlayer then
            char = closestPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                aimPartInstance = getAimPart(char)
                if aimPartInstance then
                    lookAt(aimPartInstance.Position)
                end
            end
        end
    end
end

function stopAimbot()
    aimbotRunning = false
    
    if AimbotCircle then
        AimbotCircle:Remove()
        AimbotCircle = nil
    end
    
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
        aimbotRenderConnection = nil
    end
end

function handleCharacterRespawn()
    if AimbotEnabled then
        task.wait(1)
        if AimbotCircle then
            AimbotCircle:Remove()
            AimbotCircle = nil
        end
        createFOVCircle()
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    handleCharacterRespawn()
end)

Tabs.Combat:CreateSection("Aimbot Settings")

AimbotToggle = Tabs.Combat:CreateToggle({
    Name = "Aimbot",
        Flag = "AimbotToggle",
    CurrentValue = false,
    Callback = function(state)
        AimbotEnabled = state
        if state then
            coroutine.wrap(startAimbot)()
        else
            stopAimbot()
        end
    end
})

AimPartDropdown = Tabs.Combat:CreateDropdown({
    Name = "Aim Part",
        Flag = "AimPartDropdown",
    Desc = "Select which part to aim at",
    Options = { "Head", "Body", "Legs" },
    CurrentValue = "Head",
    Callback = function(value)
        aimPart = value
    end
})
--[[ I'm done
TargetRoleDropdown = Tabs.Combat:CreateDropdown({
    Name = "Target Role",
        Flag = "TargetRoleDropdown",
    Desc = "Select which roles to target",
    Options = { "Murderer", "Sheriff", "Hero", "Innocent", "Unknown" },
    CurrentValue = {},
    Multi = true,
    AllowNone = true,
    Callback = function(values)
        targetRoles = values
    end
})
]]
SmoothnessSlider = Tabs.Combat:CreateSlider({
    Name = "Smoothness",
        Flag = "SmoothnessSlider",
    Desc = "Higher = smoother aim, Lower = snappier aim",
    Range = {1, 20}, Increment = 1, CurrentValue = 10,
    Callback = function(value)
        smoothnessValue = value
    end
})

WallCheckToggle = Tabs.Combat:CreateToggle({
    Name = "Wall Check",
        Flag = "WallCheckToggle",
    CurrentValue = false,
    Callback = function(state)
        wallCheckEnabled = state
    end
})

Tabs.Combat:CreateSection("FOV Settings")

ShowFOVToggle = Tabs.Combat:CreateToggle({
    Name = "Show FOV Circle",
        Flag = "ShowFOVToggle",
    CurrentValue = false,
    Callback = function(state)
        ShowFOV = state
        updateDrawings()
    end
})

LockFOVToggle = Tabs.Combat:CreateToggle({
    Name = "Lock FOV On Middle Screen",
        Flag = "LockFOVToggle",
    CurrentValue = true,
    Callback = function(state)
        lockFOVToCenter = state
        updateDrawings()
    end
})

FOVRadiusSlider = Tabs.Combat:CreateSlider({
    Name = "FOV Radius",
        Flag = "FOVRadiusSlider",
    Desc = "Size of the targeting area",
    Range = {10, 500}, Increment = 5, CurrentValue = 100,
    Callback = function(value)
        fovRadius = value
        updateDrawings()
    end
})

FOVColorPicker = Tabs.Combat:CreateColorPicker({
    Name = "FOV Color",
        Flag = "FOVColorPicker",
    Desc = "FOV Circle Color",
    CurrentValue = Color3.fromRGB(0, 255, 0),
    Locked = false,
    Callback = function(color)
        FOVColor = color
        updateDrawings()
    end
})

FOVThicknessSlider = Tabs.Combat:CreateSlider({
    Name = "FOV Thickness",
        Flag = "FOVThicknessSlider",
    Desc = "Thickness of the FOV circle",
    Range = {1, 10}, Increment = 1, CurrentValue = 2,
    Callback = function(value)
        FOVThickness = value
        updateDrawings()
    end
})
Tabs.Combat:CreateSection("Gun Combat")
Tabs.Combat:CreateDivider()
local sheriffButton = nil
local sheriffGui = nil
local sheriffButtonActive = false
local shotType = "Default"
local buttonSize = 60
local autoShootEnabled = false
local shootOffset = 0
local pingMultiplier = 0

local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    
    local originalBackground = frame.BackgroundColor3
    local originalTransparency = frame.BackgroundTransparency
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency - 0.1
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency
        end
    end)
end

local function GetMurderer()
    local success, roles = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if not success or not roles then
        return nil
    end
    
    for name, data in pairs(roles) do
        if data.Role == "Murderer" then
            return Players:FindFirstChild(name)
        end
    end
    return nil
end

local function IsMurdererVisible(murderer)
    if not murderer or not murderer.Character then return false end
    
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    
    local localHead = localChar:FindFirstChild("Head")
    local murdererHead = murderer.Character:FindFirstChild("Head")
    
    if not localHead or not murdererHead then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localChar, murderer.Character}
    
    local direction = (murdererHead.Position - localHead.Position)
    local raycastResult = workspace:Raycast(localHead.Position, direction, raycastParams)
    
    return raycastResult == nil
end

local function ShootMurderer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
        return false
    end
    
    local murderer = GetMurderer()
    if not murderer or not murderer.Character or not murderer.Character:FindFirstChild("Humanoid") or murderer.Character.Humanoid.Health <= 0 then
        return false
    end
    
    if not IsMurdererVisible(murderer) then
        return false
    end
    
    local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then
        return false
    end
    
    if gun and not LocalPlayer.Character:FindFirstChild("Gun") then
        gun.Parent = LocalPlayer.Character
    end
    
    gun = LocalPlayer.Character:FindFirstChild("Gun")
    if gun and gun:FindFirstChild("KnifeLocal") then
        local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            local targetPos = targetPart.Position
            local murdererHumanoid = murderer.Character:FindFirstChildOfClass("Humanoid")
            
            if shootOffset ~= 0 and murdererHumanoid then
                local moveDirection = murdererHumanoid.MoveDirection
                if moveDirection.Magnitude > 0 then
                    local offsetDirection = moveDirection.Unit
                    local finalOffset = shootOffset * pingMultiplier
                    targetPos = targetPos + (offsetDirection * finalOffset)
                end
            end
            
            local args = {[1] = 1, [2] = targetPos, [3] = "AH2"}
            gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
            return true
        end
    end
    return false
end

local function startAutoShoot()
    while autoShootEnabled do
        ShootMurderer()
        task.wait(0.1)
    end
end

local function createSheriffGui()
    if sheriffGui then
        sheriffGui:Destroy()
        sheriffGui = nil
    end
    
    sheriffGui = Instance.new("ScreenGui")
    sheriffGui.Name = "SheriffGui"
    sheriffGui.IgnoreGuiInset = true
    sheriffGui.ResetOnSpawn = false
    sheriffGui.Enabled = true
    sheriffGui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    frame.Position = UDim2.new(0.5, -30, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = sheriffGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "SHOT"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    sheriffButton = Instance.new("TextButton")
    sheriffButton.Name = "TriggerButton"
    sheriffButton.Text = "FIRE"
    sheriffButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    sheriffButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    sheriffButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    sheriffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sheriffButton.Font = Enum.Font.Roboto
    sheriffButton.TextSize = 14
    sheriffButton.TextXAlignment = Enum.TextXAlignment.Center
    sheriffButton.TextYAlignment = Enum.TextYAlignment.Center
    sheriffButton.TextScaled = true
    sheriffButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = sheriffButton

    sheriffButton.MouseButton1Click:Connect(function()
        ShootMurderer()
    end)
    
    sheriffButtonActive = true
end

local function removeSheriffGui()
    if sheriffGui then
        sheriffGui:Destroy()
        sheriffGui = nil
    end
    sheriffButton = nil
    sheriffButtonActive = false
end

Tabs.Combat:CreateToggle({
    Name = "Auto Shoot Murderer",
    CurrentValue = false,
    Callback = function(state)
        autoShootEnabled = state
        if state then
            task.spawn(startAutoShoot)
        end
    end
})

Tabs.Combat:CreateInput({
    Name = "Shoot Position Offset",
    Placeholder = "0",
    CurrentValue = "0",
    Callback = function(text)
        shootOffset = tonumber(text) or 0
    end
})

Tabs.Combat:CreateInput({
    Name = "Offset-to-Ping Multiplier",
    Placeholder = "0",
    CurrentValue = "0",
    Callback = function(text)
        pingMultiplier = tonumber(text) or 1
    end
})

Tabs.Combat:CreateButton({
    Name = "Shoot Murderer",
    Callback = function()
        ShootMurderer()
    end
})
Tabs.Combat:CreateKeybind({
    Name = "Shoot Murderer Keybind",
    CurrentValue = "E",
    Callback = function(key)
        local keyCode = Enum.KeyCode[key]
        if keyCode then
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == keyCode then
                    ShootMurderer()
                end
            end)
            
            return function()
                if connection then
                    connection:Disconnect()
                end
            end
        end
    end
})

Tabs.Combat:CreateButton({
    Name = "Toggle Shot Button",
    Callback = function()
        if sheriffButtonActive then
            removeSheriffGui()
        else
            createSheriffGui()
        end
    end
})

Tabs.Combat:CreateSlider({
    Name = "Button Size",
    Increment = 1,
    Range = {40, 100}, CurrentValue = 60,
    Callback = function(size)
        buttonSize = size
        if sheriffButtonActive then
            removeSheriffGui()
            createSheriffGui()
        end
    end
})
local murderTpEnabled = false
local murderTpConnection = nil
local tpOffset = Vector3.new(0, 15, 0)

local function parseOffsetInput(input)
    local x, y, z = 0, 15, 0
    
    if input and input ~= "" then
        local cleaned = input:gsub("%s+", " "):gsub(",", " "):gsub("^%s+", ""):gsub("%s+$", "")
        local parts = {}
        for part in cleaned:gmatch("[%-%d%.]+") do
            table.insert(parts, tonumber(part))
        end
        
        if #parts >= 1 then x = parts[1] or 0 end
        if #parts >= 2 then y = parts[2] or 15 end
        if #parts >= 3 then z = parts[3] or 0 end
    end
    
    return Vector3.new(x, y, z)
end

local function StartMurderTp()
    if murderTpConnection then return end
    
    murderTpConnection = RunService.Heartbeat:Connect(function()
        if not murderTpEnabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local murderer = GetMurderer()
        if not murderer or not murderer.Character then return end
        
        local murderRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
        if not murderRoot then return end
        
        rootPart.CFrame = murderRoot.CFrame + tpOffset
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end)
end

local function StopMurderTp()
    if murderTpConnection then
        murderTpConnection:Disconnect()
        murderTpConnection = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

Tabs.Combat:CreateInput({
    Name = "TP Offset (X Y Z)",
    Placeholder = "0 15 0",
    CurrentValue = "0 15 0",
    Callback = function(text)
        tpOffset = parseOffsetInput(text)
    end
})

Tabs.Combat:CreateToggle({
    Name = "Murder CFrame TP",
    CurrentValue = false,
    Callback = function(state)
        murderTpEnabled = state
        if state then
            StartMurderTp()
        else
            StopMurderTp()
        end
    end
})
local GunSystem = {
    AutoGrabEnabled = false,
    NotifyGun = false,
    GunDropCheckInterval = 1,
    ActiveGunDrops = {},
    Mode = "Grab only"
}

local notifiedGunPickups = {}
local notifiedGunSpawns = {}

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local originalPosition = humanoidRootPart.Position

local function ScanForGunDrops()
    GunSystem.ActiveGunDrops = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            table.insert(GunSystem.ActiveGunDrops, obj)
        end
    end
end

local function EquipGun()
    if (player.Character and player.Character:FindFirstChild("Gun")) then
        return true
    end
    local gun = player.Backpack:FindFirstChild("Gun")
    if gun then
        gun.Parent = player.Character
        task.wait(0.1)
        return player.Character:FindFirstChild("Gun") ~= nil
    end
    return false
end

local function GetMurderer()
    local roles = ReplicatedStorage:FindFirstChild("GetPlayerData"):InvokeServer()
    for playerName, data in pairs(roles) do
        if (data.Role == "Murderer") then
            return Players:FindFirstChild(playerName)
        end
    end
end

local function ShootMurderer()
    local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    local murderer = nil
    for name, data in pairs(roles) do
        if (data.Role == "Murderer") then
            murderer = Players:FindFirstChild(name)
            break
        end
    end
    if (not murderer or not murderer.Character) then
        Notify({title = "Gun System", content = "Murderer not found!", duration = 3})
        return false
    end
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if (targetRoot and localRoot) then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
        task.wait(0.1)
    end
    local gun = player.Character:FindFirstChild("Gun")
    if not gun then
        Notify({title = "Gun System", content = "Gun not equipped!", duration = 3})
        return false
    end
    local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then
        return false
    end
    local args = {[1] = 1, [2] = targetPart.Position, [3] = "AH2"}
    if (gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam")) then
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
        Notify({title = "Gun System", content = "Successfully shot the murderer!", duration = 3})
        return true
    end
    return false
end

local function safeTeleport(cframe)
    pcall(function()
        if character and humanoidRootPart then
            humanoidRootPart.CFrame = cframe
        end
    end)
end

local function hasKnife()
    return player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife"))
end

local function collectAllGunDrops()
    if hasKnife() then
        Notify({title = "Gun System", content = "You already have a knife!", duration = 3})
        return
    end
    
    local currentPosition = humanoidRootPart.Position
    ScanForGunDrops()
    
    if #GunSystem.ActiveGunDrops == 0 then
        Notify({title = "Gun System", content = "No guns available on the map", duration = 3})
        return
    end
    
    for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
        if gunDrop and gunDrop.Parent then
            safeTeleport(gunDrop.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.05)
            safeTeleport(CFrame.new(currentPosition))
            task.wait(0.05)
        end
    end
    
    Notify({title = "Gun System", content = "Successfully collected all guns!", duration = 3})
end

local function ManualGrab()
    if hasKnife() then
        Notify({title = "Gun System", content = "You already have a knife!", duration = 3})
        return false
    end
    
    if GunSystem.Mode == "Grab only" then
        collectAllGunDrops()
    elseif GunSystem.Mode == "Grab & shoot murderer" then
        ScanForGunDrops()
        if (#GunSystem.ActiveGunDrops == 0) then
            Notify({title = "Gun System", content = "No guns available on the map", duration = 3})
            return false
        end
        
        local nearestGun = nil
        local minDistance = math.huge
        local character = player.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            for _, drop in ipairs(GunSystem.ActiveGunDrops) do
                local distance = (humanoidRootPart.Position - drop.Position).Magnitude
                if (distance < minDistance) then
                    nearestGun = drop
                    minDistance = distance
                end
            end
        end
        
        if (nearestGun and player.Character) then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = nearestGun.CFrame
                task.wait(0.3)
                local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                    Notify({title = "Gun System", content = "Successfully grabbed the gun!", duration = 3})
                    
                    task.wait(0.5)
                    if EquipGun() then
                        ShootMurderer()
                    end
                    
                    return true
                end
            end
        end
        return false
    end
end

local function ImprovedGrabOnly()
    local isTeleporting = false
    local teleportDelay = 0.5

    local function teleportLoop()
        if isTeleporting then return end
        if hasKnife() then return end
        
        isTeleporting = true
        
        local currentPosition = humanoidRootPart.Position
        ScanForGunDrops()
        
        if #GunSystem.ActiveGunDrops == 0 then
            isTeleporting = false
            return
        end
        
        for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
            if gunDrop and gunDrop.Parent then
                safeTeleport(gunDrop.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.05)
                safeTeleport(CFrame.new(currentPosition))
                task.wait(0.05)
            end
        end
        
        isTeleporting = false
    end

    while GunSystem.AutoGrabEnabled and GunSystem.Mode == "Grab only" do
        if not hasKnife() then
            teleportLoop()
        end
        task.wait(teleportDelay)
    end
end

local function AutoGrabGun()
    while GunSystem.AutoGrabEnabled do
        if hasKnife() then
            task.wait(GunSystem.GunDropCheckInterval)
            continue
        end
        
        if GunSystem.Mode == "Grab only" then
            ImprovedGrabOnly()
        elseif GunSystem.Mode == "Grab & shoot murderer" then
            ScanForGunDrops()
            if ((#GunSystem.ActiveGunDrops > 0) and player.Character) then
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestGun = nil
                    local minDistance = math.huge
                    for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
                        local distance = (humanoidRootPart.Position - gunDrop.Position).Magnitude
                        if (distance < minDistance) then
                            nearestGun = gunDrop
                            minDistance = distance
                        end
                    end
                    if nearestGun then
                        humanoidRootPart.CFrame = nearestGun.CFrame
                        task.wait(0.3)
                        local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                            
                            task.wait(0.5)
                            if EquipGun() then
                                ShootMurderer()
                            end
                            
                            task.wait(1)
                        end
                    end
                end
            end
            task.wait(GunSystem.GunDropCheckInterval)
        end
    end
end

local function monitorGunEvents()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            otherPlayer.CharacterAdded:Connect(function(character)
                character.ChildAdded:Connect(function(child)
                    if child.Name == "Gun" and GunSystem.NotifyGun then
                        if not notifiedGunPickups[otherPlayer.Name] then
                            Notify({
                                title = "Gun System", 
                                content = otherPlayer.Name .. " took the gun!",
                     duration = 5,
                            })
                            notifiedGunPickups[otherPlayer.Name] = true
                        end
                    end
                end)
            end)
            
            if otherPlayer.Character then
                otherPlayer.Character.ChildAdded:Connect(function(child)
                    if child.Name == "Gun" and GunSystem.NotifyGun then
                        if not notifiedGunPickups[otherPlayer.Name] then
                            Notify({
                                title = "Gun System", 
                                content = otherPlayer.Name .. " took the gun!",
                     duration = 5,
                            })
                            notifiedGunPickups[otherPlayer.Name] = true
                        end
                    end
                end)
            end
        end
    end
    
    workspace.DescendantAdded:Connect(function(child)
        if child.Name == "GunDrop" and child:IsA("BasePart") and GunSystem.NotifyGun then
            if not notifiedGunSpawns[child] then
                Notify({
                    title = "Gun System", 
                    content = "A gun has spawned!",
                     duration = 5,
                })
                notifiedGunSpawns[child] = true
            end
        end
    end)
end

local function resetGunNotifications()
    workspace.DescendantAdded:Connect(function(child)
        if child.Name == "GunDrop" and child:IsA("BasePart") then
            for playerName, _ in pairs(notifiedGunPickups) do
                notifiedGunPickups[playerName] = nil
            end
            notifiedGunSpawns[child] = nil
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    originalPosition = humanoidRootPart.Position
end)

Tabs.Combat:CreateToggle({
    Name = "Auto Grab Gun",
    CurrentValue = false,
    Callback = function(state)
        GunSystem.AutoGrabEnabled = state
        if state then
            coroutine.wrap(AutoGrabGun)()
        end
    end
})

Tabs.Combat:CreateButton({
    Name = "Manual Grab Gun",
    Callback = function()
        ManualGrab()
    end
})

Tabs.Combat:CreateDropdown({
    Name = "Auto Grab Mode",
    Options = {"Grab only", "Grab & shoot murderer"},
    CurrentValue = "Grab only",
    Callback = function(value)
        GunSystem.Mode = value
    end
})

Tabs.Combat:CreateToggle({
    Name = "Notify Gun",
    CurrentValue = false,
    Callback = function(state)
        GunSystem.NotifyGun = state
    end
})
Tabs.Combat:CreateSection("Knife Combat")
Tabs.Combat:CreateDivider()

local killMode = "Kill Aura"
local killAuraRadius = 10
local autoKillEnabled = false
local showAuraCircle = false
local autoEquipKnife = false
local killConnection = nil
local auraConnection = nil
local anchoredPlayers = {}
local auraCircle = nil
local originalEquipState = false

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

local function equipKnife()
    if not player.Character:FindFirstChild("Knife") then
        if player.Backpack:FindFirstChild("Knife") then
            player.Character:FindFirstChild("Humanoid"):EquipTool(player.Backpack:FindFirstChild("Knife"))
            return true
        end
        return false
    end
    return true
end

local function updateAuraCircle()
    if auraCircle and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            auraCircle.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end

local function createAuraCircle()
    if auraCircle then
        auraCircle:Destroy()
        auraCircle = nil
    end
    
    if showAuraCircle and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            auraCircle = Instance.new("Part")
            auraCircle.Name = "AuraRange"
            auraCircle.Shape = Enum.PartType.Cylinder
            auraCircle.Material = Enum.Material.Neon
            auraCircle.BrickColor = BrickColor.new("Bright red")
            auraCircle.Transparency = 0.7
            auraCircle.Anchored = true
            auraCircle.CanCollide = false
            auraCircle.Size = Vector3.new(1, killAuraRadius * 2, killAuraRadius * 2)
            auraCircle.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
            auraCircle.Parent = workspace
            
            if auraConnection then
                auraConnection:Disconnect()
            end
            
            auraConnection = RunService.Heartbeat:Connect(function()
                updateAuraCircle()
            end)
        end
    else
        if auraConnection then
            auraConnection:Disconnect()
            auraConnection = nil
        end
        if auraCircle then
            auraCircle:Destroy()
            auraCircle = nil
        end
    end
end

local function unanchorPlayers()
    for _, targetPlayer in pairs(anchoredPlayers) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.Anchored = false
            targetPlayer.Character.HumanoidRootPart.CanCollide = true
        end
    end
    anchoredPlayers = {}
end

local function disablePlayerCollision(character)
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function killAura()
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local hasTargetInRange = false
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local distance = (targetRoot.Position - localRoot.Position).Magnitude
            
            if distance <= tonumber(killAuraRadius) then
                hasTargetInRange = true
                targetRoot.Anchored = true
                targetRoot.CanCollide = false
                anchoredPlayers[targetPlayer] = targetPlayer
                targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
                disablePlayerCollision(targetPlayer.Character)
            end
        end    
    end
    
    if autoEquipKnife and hasTargetInRange then
        equipKnife()
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 3 do
            knife.Stab:FireServer("Down")
        end
    end
end

local function killNearby()
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local hasTargetClose = false
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local distance = (targetRoot.Position - localRoot.Position).Magnitude
            
            if distance <= 5 then
                hasTargetClose = true
                break
            end
        end    
    end
    
    if autoEquipKnife and hasTargetClose then
        equipKnife()
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 5 do
            for j = 1, 3 do
                knife.Stab:FireServer("Down")
            end
            task.wait(0.1)
        end
    end
end

local function killAll()
    if autoEquipKnife then
        equipKnife()
    end
    
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            targetRoot.Anchored = true
            targetRoot.CanCollide = false
            anchoredPlayers[targetPlayer] = targetPlayer
            targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
            disablePlayerCollision(targetPlayer.Character)
        end    
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 3 do
            knife.Stab:FireServer("Down")
        end
    end
end

local function startAutoKill()
    if killConnection then return end
    
    killConnection = RunService.Heartbeat:Connect(function()
        if autoKillEnabled and findMurderer() == player then
            if killMode == "Kill Aura" then
                killAura()
            elseif killMode == "Kill Nearby" then
                killNearby()
            elseif killMode == "Kill All" then
            local backpack = player:WaitForChild("Backpack")
local knife = backpack:FindFirstChild("Knife")

if knife then
    knife.Parent = player.Character
end
                killAll()
            end
        end
    end)
end

local function stopAutoKill()
    if killConnection then
        killConnection:Disconnect()
        killConnection = nil
    end
    unanchorPlayers()
end

AutoEquipKnifeToggle = Tabs.Combat:CreateToggle({
    Name = "Auto Equip Knife",
        Flag = "AutoEquipKnifeToggle",
    CurrentValue = false,
    Callback = function(state)
        autoEquipKnife = state
        originalEquipState = state
    end
})

KillModeDropdown = Tabs.Combat:CreateDropdown({
    Name = "Kill Mode",
        Flag = "KillModeDropdown",
    Options = {"Kill Aura", "Kill Nearby", "Kill All"},
    CurrentValue = "Kill Aura",
    Callback = function(value)
        killMode = value
        unanchorPlayers()
    end
})

KillAuraSlider = Tabs.Combat:CreateSlider({
    Name = "Knife Kill Aura Rage",
        Flag = "KillAuraSlider",
    Desc = "Adjust kill aura radius",
    Range = {1, 200}, Increment = 1, CurrentValue = 10,
    Callback = function(value)
        killAuraRadius = tonumber(value)
        if auraCircle then
            auraCircle.Size = Vector3.new(1, killAuraRadius * 2, killAuraRadius * 2)
        end
    end
})

ShowAuraToggle = Tabs.Combat:CreateToggle({
    Name = "Show Aura Circle",
        Flag = "ShowAuraToggle",
    CurrentValue = false,
    Callback = function(state)
        showAuraCircle = state
        createAuraCircle()
    end
})

AutoKillToggle = Tabs.Combat:CreateToggle({
    Name = "Auto Kill",
        Flag = "AutoKillToggle",
    CurrentValue = false,
    Callback = function(state)
        autoKillEnabled = state
        if state then
            startAutoKill()
        else
            stopAutoKill()
        end
    end
})
Tabs.Combat:CreateButton({
    Name = "Kill All",
    Desc = "Teleport and kill all players",
    Icon = "target",
    Callback = function()
        if findMurderer() ~= player then return end
        
local backpack = player:WaitForChild("Backpack")
local knife = backpack:FindFirstChild("Knife")

if knife then
    knife.Parent = player.Character
end
        local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                targetRoot.Anchored = true
                targetRoot.CanCollide = false
                targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
                disablePlayerCollision(targetPlayer.Character)
            end    
        end
        
        local knife = player.Character:FindFirstChild("Knife")
        if (knife and knife:FindFirstChild("Stab")) then
            for i = 1, 3 do
                knife.Stab:FireServer("Down")
            end
        end
    end
})
task.spawn(function()
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    ScanForGunDrops()
    if GunSystem.AutoGrabEnabled then
        coroutine.wrap(AutoGrabGun)()
    end
    monitorGunEvents()
    resetGunNotifications()
end)
Tabs.Visuals:CreateSection("Visual")
    Tabs.Visuals:CreateDivider()
    local cameraStretchConnection
local function setupCameraStretch()
    cameraStretchConnection = nil
    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    CameraStretchToggle = Tabs.Visuals:CreateToggle({
        Name = "Camera Stretch",
        Flag = "CameraStretchToggle",
        CurrentValue = false,
        Callback = function(state)
            if state then
                if cameraStretchConnection then cameraStretchConnection:Disconnect() end
                cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    local Camera = workspace.CurrentCamera
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                end)
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
            end
        end
    })

    CameraStretchHorizontalInput = Tabs.Visuals:CreateInput({
        Name = "Camera Stretch Horizontal",
        Flag = "CameraStretchHorizontalInput",
        Placeholder = "0.80",
        Numeric = true,
        CurrentValue = tostring(stretchHorizontal),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchHorizontal = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })

    CameraStretchVerticalInput = Tabs.Visuals:CreateInput({
        Name = "Camera Stretch Vertical",
        Flag = "CameraStretchVerticalInput",
        Placeholder = "0.80",
        Numeric = true,
        CurrentValue = tostring(stretchVertical),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchVertical = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })
end
	    FullBrightToggle = Tabs.Visuals:CreateToggle({
    Name = "Full Bright",
        Flag = "FullBrightToggle",
    Desc = "Ya Like drinking Night Vision while mining in da cave and sceard of creeper blow you up dawg?",
    CurrentValue = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            local Lighting = game:GetService("Lighting")
            
            featureStates.originalBrightness = Lighting.Brightness
            featureStates.originalAmbient = Lighting.Ambient
            featureStates.originalOutdoorAmbient = Lighting.OutdoorAmbient
            featureStates.originalColorShiftBottom = Lighting.ColorShift_Bottom
            featureStates.originalColorShiftTop = Lighting.ColorShift_Top
            
            local function applyFullBright()
                if Lighting.Brightness ~= 1 then
                    Lighting.Brightness = 1
                end
                if Lighting.Ambient ~= Color3.new(1, 1, 1) then
                    Lighting.Ambient = Color3.new(1, 1, 1)
                end
                if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                end
                if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then
                    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
                end
                if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then
                    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
                end
            end
            
            applyFullBright()
            
            if featureStates.fullBrightConnection then
                featureStates.fullBrightConnection:Disconnect()
            end
            
            featureStates.fullBrightConnection = RunService.Heartbeat:Connect(function()
                if featureStates.FullBright then
                    applyFullBright()
                end
            end)
            
            featureStates.fullBrightCharConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if featureStates.FullBright then
                    applyFullBright()
                end
            end)
            
        else
            if featureStates.fullBrightConnection then
                featureStates.fullBrightConnection:Disconnect()
                featureStates.fullBrightConnection = nil
            end
            
            if featureStates.fullBrightCharConnection then
                featureStates.fullBrightCharConnection:Disconnect()
                featureStates.fullBrightCharConnection = nil
            end
            
            if featureStates.originalBrightness then
                local Lighting = game:GetService("Lighting")
                Lighting.Brightness = featureStates.originalBrightness
                Lighting.Ambient = featureStates.originalAmbient
                Lighting.OutdoorAmbient = featureStates.originalOutdoorAmbient
                Lighting.ColorShift_Bottom = featureStates.originalColorShiftBottom
                Lighting.ColorShift_Top = featureStates.originalColorShiftTop
            end
        end
    end
})
local FOVSlider = Tabs.Visuals:CreateSlider({
    Name = "Field of View",
        Flag = "FOVSlider",
    Range = {1, 120}, Increment = 1, CurrentValue = originalFOV,
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = tonumber(value)
    end
})
local roundTimerEnabled = false
local roundTimerGui = nil
local roundTimerLabel = nil
local roundTimerConnection = nil
local clearTweensConnection = nil
local loadingMapConnection = nil
local roleSelectConnection = nil
local victoryConnection = nil
local lastTimerText = ""
local freezeCheckTime = 0
local freezeThreshold = 3
local isWaitingForMapVote = false
local isLoadingMap = false
local roleDisplayTime = 0
local roleDisplayDuration = 5
local countdownStartTime = 0
local isInCountdown = false
local timeUpDisplayTime = 0
local timeUpDisplayDuration = 3
local victoryDisplayTime = 0
local victoryDisplayDuration = 5

local function createRoundTimerGui()
    if roundTimerGui then
        roundTimerGui:Destroy()
        roundTimerGui = nil
    end
    
    roundTimerGui = Instance.new("ScreenGui")
    roundTimerGui.Name = "RoundTimerGui"
    roundTimerGui.IgnoreGuiInset = true
    roundTimerGui.ResetOnSpawn = false
    roundTimerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    roundTimerGui.Parent = playerGui

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = roundTimerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 40)
    frame.Position = UDim2.new(0.5, -100, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = roundTimerGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = frame

    roundTimerLabel = Instance.new("TextLabel")
    roundTimerLabel.Size = UDim2.new(1, 0, 1, 0)
    roundTimerLabel.BackgroundTransparency = 1
    roundTimerLabel.Text = "Round Timer: --:--"
    roundTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    roundTimerLabel.Font = Enum.Font.RobotoMono
    roundTimerLabel.TextSize = 18
    roundTimerLabel.TextScaled = false
    roundTimerLabel.TextXAlignment = Enum.TextXAlignment.Center
    roundTimerLabel.TextYAlignment = Enum.TextYAlignment.Center
    roundTimerLabel.Parent = frame
end

local function checkRoleSelectorCountdown()
    local mainGUI = player.PlayerGui:FindFirstChild("MainGUI")
    if not mainGUI then return false end
    
    local gameFrame = mainGUI:FindFirstChild("Game")
    if not gameFrame then return false end
    
    local roleSelector = gameFrame:FindFirstChild("RoleSelector")
    if not roleSelector or not roleSelector.Visible then return false end
    
    local roleText = roleSelector:FindFirstChild("Role")
    if not roleText then return false end
    
    local text = roleText.Text
    local number = tonumber(text)
    
    if number then
        roundTimerLabel.Text = "Round start in " .. number
        countdownStartTime = tick()
        isInCountdown = true
        return true
    end
    
    return false
end

local function updateRoundTimer()
    if not roundTimerEnabled or not roundTimerLabel then return end
    
    if tick() - victoryDisplayTime < victoryDisplayDuration then
        return
    end
    
    if tick() - timeUpDisplayTime < timeUpDisplayDuration then
        return
    end
    
    if isInCountdown then
        if tick() - countdownStartTime >= 1 then
            isInCountdown = false
        else
            return
        end
    end
    
    if checkRoleSelectorCountdown() then
        return
    end
    
    if tick() - roleDisplayTime < roleDisplayDuration then
        return
    end
    
    if isLoadingMap then
        roundTimerLabel.Text = "Loading map..."
        return
    end
    
    if isWaitingForMapVote then
        roundTimerLabel.Text = "Waiting for map vote"
        return
    end
    
    local timerPart = workspace:FindFirstChild("RoundTimerPart")
    if not timerPart then
        roundTimerLabel.Text = "Round Timer: --:--"
        lastTimerText = ""
        freezeCheckTime = tick()
        return
    end
    
    local surfaceGui = timerPart:FindFirstChildOfClass("SurfaceGui")
    if not surfaceGui then
        roundTimerLabel.Text = "Round Timer: --:--"
        lastTimerText = ""
        freezeCheckTime = tick()
        return
    end
    
    local timerLabel = surfaceGui:FindFirstChild("Timer")
    if not timerLabel then
        roundTimerLabel.Text = "Round Timer: --:--"
        lastTimerText = ""
        freezeCheckTime = tick()
        return
    end
    
    local currentText = timerLabel.Text
    local displayText = "Round Timer: " .. currentText
    
    if currentText == "1s" or currentText == "0s" then
        roundTimerLabel.Text = "Time's up"
        timeUpDisplayTime = tick()
        return
    end
    
    if currentText == lastTimerText then
        if tick() - freezeCheckTime >= freezeThreshold then
            roundTimerLabel.Text = displayText
            return
        end
    else
        lastTimerText = currentText
        freezeCheckTime = tick()
    end
    
    roundTimerLabel.Text = displayText
end

local function setupClearTweensListener()
    if clearTweensConnection then
        clearTweensConnection:Disconnect()
        clearTweensConnection = nil
    end
    
    local ClientTweenEvents = ReplicatedStorage:WaitForChild("ClientTweenEvents")
    local ClearTweens = ClientTweenEvents:WaitForChild("ClearTweens")
    
    clearTweensConnection = ClearTweens.OnClientEvent:Connect(function(...)
        if roundTimerEnabled and roundTimerLabel then
            isWaitingForMapVote = true
            isLoadingMap = false
            lastTimerText = ""
            freezeCheckTime = tick()
            timeUpDisplayTime = 0
            victoryDisplayTime = 0
        end
    end)
end

local function setupLoadingMapListener()
    if loadingMapConnection then
        loadingMapConnection:Disconnect()
        loadingMapConnection = nil
    end
    
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local Gameplay = Remotes:WaitForChild("Gameplay")
    local LoadingMap = Gameplay:WaitForChild("LoadingMap")
    
    loadingMapConnection = LoadingMap.OnClientEvent:Connect(function(mapName)
        if roundTimerEnabled and roundTimerLabel then
            isLoadingMap = true
            isWaitingForMapVote = false
            lastTimerText = ""
            freezeCheckTime = tick()
            timeUpDisplayTime = 0
            victoryDisplayTime = 0
        end
    end)
end

local function setupRoleSelectListener()
    if roleSelectConnection then
        roleSelectConnection:Disconnect()
        roleSelectConnection = nil
    end
    
    local RoleSelect = ReplicatedStorage.Remotes.Gameplay.RoleSelect
    roleSelectConnection = RoleSelect.OnClientEvent:Connect(function(role, ...)
        if roundTimerEnabled and roundTimerLabel then
            local roleName = role or "Unknown"
            roundTimerLabel.Text = "Your role is " .. roleName
            roleDisplayTime = tick()
            isLoadingMap = false
            isWaitingForMapVote = false
            timeUpDisplayTime = 0
            victoryDisplayTime = 0
        end
    end)
end

local function setupVictoryListener()
    if victoryConnection then
        victoryConnection:Disconnect()
        victoryConnection = nil
    end
    
    local VictoryRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("VictoryScreen")
    
    victoryConnection = VictoryRemote.OnClientEvent:Connect(function(arg1, arg2, arg3, arg4, arg5)
        if roundTimerEnabled and roundTimerLabel then
            if arg2 == "MurdererLeft" then
                roundTimerLabel.Text = "Murder left"
            elseif arg2 == "MurdererWin" then
                roundTimerLabel.Text = "Murder Win"
            else
                roundTimerLabel.Text = arg2 .. " win"
            end
            victoryDisplayTime = tick()
            timeUpDisplayTime = 0
        end
    end)
end

local function startRoundTimer()
    if roundTimerConnection then return end
    
    createRoundTimerGui()
    setupClearTweensListener()
    setupLoadingMapListener()
    setupRoleSelectListener()
    setupVictoryListener()
    
    lastTimerText = ""
    freezeCheckTime = tick()
    isWaitingForMapVote = false
    isLoadingMap = false
    roleDisplayTime = 0
    countdownStartTime = 0
    isInCountdown = false
    timeUpDisplayTime = 0
    victoryDisplayTime = 0
    
    roundTimerConnection = RunService.Heartbeat:Connect(function()
        updateRoundTimer()
    end)
end

local function stopRoundTimer()
    if roundTimerConnection then
        roundTimerConnection:Disconnect()
        roundTimerConnection = nil
    end
    
    if clearTweensConnection then
        clearTweensConnection:Disconnect()
        clearTweensConnection = nil
    end
    
    if loadingMapConnection then
        loadingMapConnection:Disconnect()
        loadingMapConnection = nil
    end
    
    if roleSelectConnection then
        roleSelectConnection:Disconnect()
        roleSelectConnection = nil
    end
    
    if victoryConnection then
        victoryConnection:Disconnect()
        victoryConnection = nil
    end
    
    if roundTimerGui then
        roundTimerGui:Destroy()
        roundTimerGui = nil
        roundTimerLabel = nil
    end
    
    lastTimerText = ""
    freezeCheckTime = 0
    isWaitingForMapVote = false
    isLoadingMap = false
    roleDisplayTime = 0
    countdownStartTime = 0
    isInCountdown = false
    timeUpDisplayTime = 0
    victoryDisplayTime = 0
end

RoundTimerToggle = Tabs.Visuals:CreateToggle({
    Name = "Round Timer Display",
        Flag = "RoundTimerToggle",
    Desc = "Show round timer in top middle of screen",
    CurrentValue = false,
    Callback = function(state)
        roundTimerEnabled = state
        if state then
            startRoundTimer()
        else
            stopRoundTimer()
        end
    end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        stopRoundTimer()
    end
end)
setupCameraStretch()
innocentEspElements = {}
murderEspElements = {}
sheriffEspElements = {}
coinEspElements = {}
gunEspElements = {}

playerEspConnection = nil
roleUpdateConnection = nil
roleData = {}
lastRoleUpdate = 0
roleUpdating = false
HighlightsConnection = nil
coinEspConnection = nil
gunEspConnection = nil

local getPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

featureStates.CoinESP = featureStates.CoinESP or {
    names = false,
    boxes = false,
    tracers = false,
    distance = false,
    boxType = "3D"
}

featureStates.GunESP = featureStates.GunESP or {
    names = false,
    boxes = false,
    tracers = false,
    distance = false,
    boxType = "3D"
}

featureStates.CoinHighlights = featureStates.CoinHighlights or false
featureStates.GunHighlights = featureStates.GunHighlights or false

local lastCoinSearch = 0
local lastGunSearch = 0
local coinCache = {}
local gunCache = {}
local cachedPlayers = {}
local lastPlayerCacheUpdate = 0

function isAnyRoleESPActive()
    local roles = {"InnocentESP", "MurderESP", "HeroSheriffESP", "CoinESP", "GunESP"}
    for _, role in ipairs(roles) do
        local states = featureStates[role]
        if states and (states.names or states.boxes or states.tracers or states.distance) then
            return true
        end
    end
    return false
end

local function checkAnyHighlights()
    return featureStates.InnocentHighlights or featureStates.MurderHighlights or featureStates.SheriffHeroHighlights or featureStates.CoinHighlights or featureStates.GunHighlights
end

function isAnyRoleNeeded()
    return isAnyRoleESPActive() or checkAnyHighlights()
end

function startRoleUpdating()
    if roleUpdating then return end
    roleUpdating = true
    updateRoles()
    roleUpdateConnection = RunService.Heartbeat:Connect(function()
        updateRoles()
    end)
end

function stopRoleUpdating()
    if roleUpdateConnection then
        roleUpdateConnection:Disconnect()
        roleUpdateConnection = nil
    end
    roleUpdating = false
    roleData = {}
end

function manageRoleUpdating()
    if isAnyRoleNeeded() then
        startRoleUpdating()
    else
        stopRoleUpdating()
    end
end

function updateRoles()
    if not getPlayerDataRemote then return end
    if tick() - lastRoleUpdate < 2 then return end
    lastRoleUpdate = tick()
    local success, roles = pcall(function()
        return getPlayerDataRemote:InvokeServer()
    end)
    if success and roles then
        roleData = {}
        for key, v in pairs(roles) do
            if v then
                roleData[key] = v
            end
        end
        refreshHighlights()
    end
end

function managePlayerESPConnection()
    local active = isAnyRoleESPActive()
    if active then
        if not playerEspConnection then
            playerEspConnection = RunService.RenderStepped:Connect(updateRoleESP)
        end
    else
        if playerEspConnection then
            playerEspConnection:Disconnect()
            playerEspConnection = nil
        end
    end
    manageRoleUpdating()
end

function manageHighlightsConnection()
    if checkAnyHighlights() then
        startHighlights()
    else
        stopHighlights()
    end
end

function manageCoinESPConnection()
    local coinActive = featureStates.CoinESP.names or featureStates.CoinESP.boxes or featureStates.CoinESP.tracers or featureStates.CoinESP.distance
    if coinActive then
        if not coinEspConnection then
            coinEspConnection = RunService.RenderStepped:Connect(updateCoinESP)
        end
    else
        if coinEspConnection then
            coinEspConnection:Disconnect()
            coinEspConnection = nil
            cleanupCoinElements()
        end
    end
end

function manageGunESPConnection()
    local gunActive = featureStates.GunESP.names or featureStates.GunESP.boxes or featureStates.GunESP.tracers or featureStates.GunESP.distance
    if gunActive then
        if not gunEspConnection then
            gunEspConnection = RunService.RenderStepped:Connect(updateGunESP)
        end
    else
        if gunEspConnection then
            gunEspConnection:Disconnect()
            gunEspConnection = nil
            cleanupGunElements()
        end
    end
end

function cleanupAllRoleElements()
    local elementTables = {innocentEspElements, murderEspElements, sheriffEspElements, coinEspElements, gunEspElements}
    for _, elemTable in ipairs(elementTables) do
        for target, esp in pairs(elemTable) do
            cleanupDrawingTable(esp)
            elemTable[target] = nil
        end
    end
end

function cleanupCoinElements()
    for target, esp in pairs(coinEspElements) do
        cleanupDrawingTable(esp)
        coinEspElements[target] = nil
    end
end

function cleanupGunElements()
    for target, esp in pairs(gunEspElements) do
        cleanupDrawingTable(esp)
        gunEspElements[target] = nil
    end
end

function getDistanceFromPlayer(targetPosition)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return 0 end
    return (targetPosition - player.Character.HumanoidRootPart.Position).Magnitude
end

function cleanupDrawingTable(drawingTable)
    for _, drawing in pairs(drawingTable) do
        if type(drawing) == "table" then
            for _, line in ipairs(drawing) do
                pcall(line.Remove, line)
            end
        else
            pcall(drawing.Remove, drawing)
        end
    end
end

function createESPObject()
    return {
        box = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        boxLines = {}
    }
end

function setupESPObject(esp)
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.tracer.Thickness = 1
    esp.name.Size = 14
    esp.name.Center = true
    esp.name.Outline = true
    esp.distance.Size = 14
    esp.distance.Center = true
    esp.distance.Outline = true
end

function draw3DBox(esp, cf, pos, camera, boxColor, boxSize)
    if not cf or not camera then return end
    
    boxSize = boxSize or Vector3.new(4, 5, 3)
    local size = boxSize
    local offsets = {
        Vector3.new( size.X/2,  size.Y/2,  size.Z/2), Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new( size.X/2, -size.Y/2,  size.Z/2), Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2,  size.Z/2), Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2,  size.Z/2), Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
    }
    
    local screenPoints = {}
    local anyPointOnScreen = false

    for i, offset in ipairs(offsets) do
        local success, vec, onScreen = pcall(function()
            local worldPos = cf * CFrame.Angles(0, math.rad(90), 0) * offset
            return camera:WorldToViewportPoint(worldPos)
        end)
        if success then
            screenPoints[i] = {pos = Vector2.new(vec.X, vec.Y), depth = vec.Z, onScreen = onScreen}
            if onScreen and vec.Z > 0 then anyPointOnScreen = true end
        end
    end

    if not esp.boxLines or #esp.boxLines == 0 then
        esp.boxLines = {}
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.ZIndex = 2
            table.insert(esp.boxLines, line)
        end
    end

    local edges = {
        {1, 2}, {1, 3}, {1, 5}, {2, 4}, {2, 6},
        {3, 4}, {3, 7}, {5, 6}, {5, 7}, {4, 8}, {6, 8}, {7, 8}
    }

    local distance = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
        (player.Character.HumanoidRootPart.Position - pos).Magnitude) or 10
    local thickness = math.clamp(3 / (distance / 50), 1, 3)

    for i, edge in ipairs(edges) do
        local line = esp.boxLines[i]
        if line then
            local p1, p2 = screenPoints[edge[1]], screenPoints[edge[2]]
            line.Color = boxColor or Color3.fromRGB(255, 255, 255)
            line.Thickness = thickness
            line.Transparency = 1
            if anyPointOnScreen and p1 and p2 and p1.depth > 0 and p2.depth > 0 then
                line.From = p1.pos
                line.To = p2.pos
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end
end

function getPlayerRole(plr)
    local playerKey = plr.Name
    return roleData[playerKey] and roleData[playerKey].Role
end

function findCoinServerParts()
    if tick() - lastCoinSearch < 3 then
        return coinCache
    end
    
    lastCoinSearch = tick()
    coinCache = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "Coin_Server" then
            table.insert(coinCache, obj)
        end
    end
    
    return coinCache
end

function findDropGunParts()
    if tick() - lastGunSearch < 3 then
        return gunCache
    end
    
    lastGunSearch = tick()
    gunCache = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "DropGun" then
            table.insert(gunCache, obj)
        end
    end
    
    return gunCache
end

function getCachedPlayers()
    if tick() - lastPlayerCacheUpdate < 1 then
        return cachedPlayers
    end
    
    lastPlayerCacheUpdate = tick()
    cachedPlayers = Players:GetPlayers()
    return cachedPlayers
end

function updateCoinESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentCoinTargets = {}
    
    local coins = findCoinServerParts()
    
    for _, coinPart in ipairs(coins) do
        if coinPart and coinPart.Parent then
            currentCoinTargets[coinPart] = true
            
            if not coinEspElements[coinPart] then
                coinEspElements[coinPart] = createESPObject()
                setupESPObject(coinEspElements[coinPart])
            end
            
            local esp = coinEspElements[coinPart]
            local vector, onScreen = camera:WorldToViewportPoint(coinPart.Position)
            
            if onScreen then
                local coinColor = Color3.fromRGB(255, 215, 0)
                local states = featureStates.CoinESP
                
                local topY = camera:WorldToViewportPoint(coinPart.Position + Vector3.new(0, 2, 0)).Y
                local bottomY = camera:WorldToViewportPoint(coinPart.Position - Vector3.new(0, 2, 0)).Y
                local size = math.max(10, (bottomY - topY) / 2)
                
                if states.boxes then
                    if states.boxType == "2D" then
                        esp.box.Visible = true
                        esp.box.Size = Vector2.new(size * 2, size * 2)
                        esp.box.Position = Vector2.new(vector.X - size, vector.Y - size)
                        esp.box.Color = coinColor
                        for _, line in ipairs(esp.boxLines) do line.Visible = false end
                    else
                        esp.box.Visible = false
                        pcall(draw3DBox, esp, coinPart.CFrame, coinPart.Position, camera, coinColor, Vector3.new(3, 3, 3))
                    end
                else
                    esp.box.Visible = false
                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                end
                
                esp.tracer.Visible = states.tracers
                if states.tracers then
                    esp.tracer.From = screenBottomCenter
                    esp.tracer.To = Vector2.new(vector.X, vector.Y)
                    esp.tracer.Color = coinColor
                end
                
                esp.name.Visible = states.names
                if states.names then
                    esp.name.Text = "Coin"
                    esp.name.Position = Vector2.new(vector.X, vector.Y - size - 15)
                    esp.name.Color = coinColor
                end
                
                esp.distance.Visible = states.distance
                if states.distance then
                    local distance = getDistanceFromPlayer(coinPart.Position)
                    esp.distance.Text = string.format("%.1f", distance)
                    esp.distance.Position = Vector2.new(vector.X, vector.Y + size + 5)
                    esp.distance.Color = coinColor
                end
            else
                esp.box.Visible = false
                esp.tracer.Visible = false
                esp.name.Visible = false
                esp.distance.Visible = false
                for _, line in ipairs(esp.boxLines) do line.Visible = false end
            end
        end
    end
    
    for target, esp in pairs(coinEspElements) do
        if not currentCoinTargets[target] then
            cleanupDrawingTable(esp)
            coinEspElements[target] = nil
        end
    end
end

function updateGunESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentGunTargets = {}
    
    local guns = findDropGunParts()
    
    for _, gunPart in ipairs(guns) do
        if gunPart and gunPart.Parent then
            currentGunTargets[gunPart] = true
            
            if not gunEspElements[gunPart] then
                gunEspElements[gunPart] = createESPObject()
                setupESPObject(gunEspElements[gunPart])
            end
            
            local esp = gunEspElements[gunPart]
            local vector, onScreen = camera:WorldToViewportPoint(gunPart.Position)
            
            if onScreen then
                local gunColor = Color3.fromRGB(255, 0, 255)
                local states = featureStates.GunESP
                
                local topY = camera:WorldToViewportPoint(gunPart.Position + Vector3.new(0, 2, 0)).Y
                local bottomY = camera:WorldToViewportPoint(gunPart.Position - Vector3.new(0, 2, 0)).Y
                local size = math.max(10, (bottomY - topY) / 2)
                
                if states.boxes then
                    if states.boxType == "2D" then
                        esp.box.Visible = true
                        esp.box.Size = Vector2.new(size * 2, size * 2)
                        esp.box.Position = Vector2.new(vector.X - size, vector.Y - size)
                        esp.box.Color = gunColor
                        for _, line in ipairs(esp.boxLines) do line.Visible = false end
                    else
                        esp.box.Visible = false
                        pcall(draw3DBox, esp, gunPart.CFrame, gunPart.Position, camera, gunColor, Vector3.new(3, 3, 3))
                    end
                else
                    esp.box.Visible = false
                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                end
                
                esp.tracer.Visible = states.tracers
                if states.tracers then
                    esp.tracer.From = screenBottomCenter
                    esp.tracer.To = Vector2.new(vector.X, vector.Y)
                    esp.tracer.Color = gunColor
                end
                
                esp.name.Visible = states.names
                if states.names then
                    esp.name.Text = "Gun"
                    esp.name.Position = Vector2.new(vector.X, vector.Y - size - 15)
                    esp.name.Color = gunColor
                end
                
                esp.distance.Visible = states.distance
                if states.distance then
                    local distance = getDistanceFromPlayer(gunPart.Position)
                    esp.distance.Text = string.format("%.1f", distance)
                    esp.distance.Position = Vector2.new(vector.X, vector.Y + size + 5)
                    esp.distance.Color = gunColor
                end
            else
                esp.box.Visible = false
                esp.tracer.Visible = false
                esp.name.Visible = false
                esp.distance.Visible = false
                for _, line in ipairs(esp.boxLines) do line.Visible = false end
            end
        end
    end
    
    for target, esp in pairs(gunEspElements) do
        if not currentGunTargets[target] then
            cleanupDrawingTable(esp)
            gunEspElements[target] = nil
        end
    end
end

function updateRoleESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentInnocentTargets = {}
    local currentMurderTargets = {}
    local currentSheriffTargets = {}

    local players = getCachedPlayers()

    for _, otherPlayer in ipairs(players) do
        if otherPlayer ~= player then
            local model = otherPlayer.Character
            if model then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local humanoid = model:FindFirstChild("Humanoid")
                if hrp and humanoid then
                    local playerRole = getPlayerRole(otherPlayer)
                    local isDead = humanoid.Health <= 0
                    local espColor, states, elements, currentTargets
                    if isDead then
                        espColor = Color3.fromRGB(255, 255, 255)
                        states = featureStates.InnocentESP
                        elements = innocentEspElements
                        currentTargets = currentInnocentTargets
                    elseif playerRole == "Murderer" then
                        espColor = Color3.fromRGB(255, 0, 0)
                        states = featureStates.MurderESP
                        elements = murderEspElements
                        currentTargets = currentMurderTargets
                    elseif playerRole == "Sheriff" then
                        espColor = Color3.fromRGB(0, 0, 255)
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    elseif playerRole == "Hero" then
                        espColor = Color3.fromRGB(255, 255, 0)
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    else
                        if playerRole == "Innocent" then
                            espColor = Color3.fromRGB(0, 255, 0)
                        else
                            espColor = Color3.fromRGB(255, 255, 255)
                        end
                        states = featureStates.InnocentESP
                        elements = innocentEspElements
                        currentTargets = currentInnocentTargets
                    end
                    local anyActive = states.names or states.boxes or states.tracers or states.distance
                    if anyActive then
                        currentTargets[model] = true
                        if not elements[model] then
                            elements[model] = createESPObject()
                            setupESPObject(elements[model])
                        end
                        local esp = elements[model]
                        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local topY = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y
                            local bottomY = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y
                            local size = (bottomY - topY) / 2
                            local boxSize = humanoid and Vector3.new(2, humanoid.HipHeight + 5, 2) or Vector3.new(4, 5, 3)
                            if states.boxes then
                                if states.boxType == "2D" then
                                    esp.box.Visible = true
                                    esp.box.Size = Vector2.new(size * 2, size * 3)
                                    esp.box.Position = Vector2.new(vector.X - size, vector.Y - size * 1.5)
                                    esp.box.Color = espColor
                                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                                else
                                    esp.box.Visible = false
                                    pcall(draw3DBox, esp, hrp.CFrame, hrp.Position, camera, espColor, boxSize)
                                end
                            else
                                esp.box.Visible = false
                                for _, line in ipairs(esp.boxLines) do line.Visible = false end
                            end
                            esp.tracer.Visible = states.tracers
                            if states.tracers then
                                esp.tracer.From = screenBottomCenter
                                esp.tracer.To = Vector2.new(vector.X, vector.Y)
                                esp.tracer.Color = espColor
                            end
                            esp.name.Visible = states.names
                            if states.names then
                                esp.name.Text = otherPlayer.Name
                                esp.name.Position = Vector2.new(vector.X, vector.Y - size * 1.5 - 20)
                                esp.name.Color = espColor
                            end
                            esp.distance.Visible = states.distance
                            if states.distance then
                                local distance = getDistanceFromPlayer(hrp.Position)
                                esp.distance.Text = string.format("%.1f", distance)
                                esp.distance.Position = Vector2.new(vector.X, vector.Y + size * 1.5 + 5)
                                esp.distance.Color = espColor
                            end
                        else
                            esp.box.Visible = false
                            esp.tracer.Visible = false
                            esp.name.Visible = false
                            esp.distance.Visible = false
                            for _, line in ipairs(esp.boxLines) do line.Visible = false end
                        end
                    end
                end
            end
        end
    end

    for target, esp in pairs(innocentEspElements) do
        if not currentInnocentTargets[target] then
            cleanupDrawingTable(esp)
            innocentEspElements[target] = nil
        end
    end
    for target, esp in pairs(murderEspElements) do
        if not currentMurderTargets[target] then
            cleanupDrawingTable(esp)
            murderEspElements[target] = nil
        end
    end
    for target, esp in pairs(sheriffEspElements) do
        if not currentSheriffTargets[target] then
            cleanupDrawingTable(esp)
            sheriffEspElements[target] = nil
        end
    end
end

function startHighlights()
    if not HighlightsConnection then
        HighlightsConnection = RunService.Heartbeat:Connect(updateRoleHighlights)
    end
end

function stopHighlights()
    if HighlightsConnection then
        HighlightsConnection:Disconnect()
        HighlightsConnection = nil
        clearAllHighlights()
    end
end

function clearAllHighlights()
    for _, plr in pairs(getCachedPlayers()) do
        if plr.Character then
            local highlight = plr.Character:FindFirstChild("PlayerHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
    
    if featureStates.CoinHighlights or featureStates.GunHighlights then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and (obj.Name == "Coin_Server" or obj.Name == "DropGun") then
                local highlight = obj:FindFirstChild("ItemHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

function refreshHighlights()
    if not HighlightsConnection then return end
    clearAllHighlights()
end

function updateRoleHighlights()
    if not roleData then return end

    local sheriffName = nil
    for name, data in pairs(roleData) do
        if data.Role == "Sheriff" then
            sheriffName = name
            break
        end
    end
    local sheriffPlayer = sheriffName and Players:FindFirstChild(sheriffName)
    local isSheriffAlive = sheriffPlayer and IsAlive(sheriffPlayer, roleData)

    local players = getCachedPlayers()

    for _, plr in ipairs(players) do
        if plr ~= player and plr.Character then
            local model = plr.Character
            local highlight = model:FindFirstChild("PlayerHighlight")
            local data = roleData[plr.Name]
            local role = data and data.Role
            local isAlivePlayer = data and IsAlive(plr, roleData)
            local highlightEnabled = false
            if not role then
                highlightEnabled = featureStates.InnocentHighlights
            elseif role == "Murderer" then
                highlightEnabled = featureStates.MurderHighlights
            elseif role == "Sheriff" or role == "Hero" then
                highlightEnabled = featureStates.SheriffHeroHighlights
            else
                highlightEnabled = featureStates.InnocentHighlights
            end
            if highlightEnabled then
                local color
                if not data or not isAlivePlayer then
                    color = Color3.new(1,1,1)
                else
                    if role == "Murderer" then
                        color = Color3.fromRGB(225, 0, 0)
                    elseif role == "Sheriff" then
                        color = Color3.fromRGB(0, 0, 225)
                    elseif role == "Hero" and not isSheriffAlive then
                        color = Color3.fromRGB(255, 250, 0)
                    else
                        color = Color3.fromRGB(0, 225, 0)
                    end
                end
                local outlineColor = getOutlineColor(color)
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerHighlight"
                    highlight.Adornee = model
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = model
                end
                highlight.FillColor = color
                highlight.OutlineColor = outlineColor
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end

    if featureStates.CoinHighlights then
        local coins = findCoinServerParts()
        for _, coinPart in ipairs(coins) do
            if coinPart and coinPart.Parent then
                local highlight = coinPart:FindFirstChild("ItemHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ItemHighlight"
                    highlight.Adornee = coinPart
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = coinPart
                end
                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                highlight.OutlineColor = getOutlineColor(Color3.fromRGB(255, 215, 0))
            end
        end
    end

    if featureStates.GunHighlights then
        local guns = findDropGunParts()
        for _, gunPart in ipairs(guns) do
            if gunPart and gunPart.Parent then
                local highlight = gunPart:FindFirstChild("ItemHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ItemHighlight"
                    highlight.Adornee = gunPart
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = gunPart
                end
                highlight.FillColor = Color3.fromRGB(255, 0, 255)
                highlight.OutlineColor = getOutlineColor(Color3.fromRGB(255, 0, 255))
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        local highlight = plr.Character:FindFirstChild("PlayerHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end)

coinEspConnection = RunService.RenderStepped:Connect(updateCoinESP)
gunEspConnection = RunService.RenderStepped:Connect(updateGunESP)
local xRay = false
Tabs.Visuals:CreateToggle({
    Name = "X-ray Vision",
    Compact = true,
    Callback = function(state)
        xRay = state
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                part.LocalTransparencyModifier = state and 0.7 or 0
            end
        end
    end
})
Tabs.Visuals:CreateButton({
    Name = "Shit Render", 
    Callback = function()
        Lighting = game:GetService("Lighting")
        Terrain = workspace:FindFirstChildOfClass("Terrain")
        Players = game:GetService("Players")
        LocalPlayer = Players.LocalPlayer

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 1

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("Accessory") or part:IsA("Clothing") then
                        part:Destroy()
                    end
                end
            end
        end
    end
})
local function spawnWeapon(name)
    local DataBase, PlayerData = require(game:GetService("ReplicatedStorage").Database.Sync.Item),
                                  require(game:GetService("ReplicatedStorage").Modules.ProfileData)
    local newOwned = {}
    newOwned[name] = 1
    local PlayerWeapons = PlayerData.Weapons
    game:GetService("RunService"):BindToRenderStep("InventoryUpdate", 0, function()
        PlayerWeapons.Owned = newOwned
    end)
    game.Players.LocalPlayer.Character:BreakJoints()
end
Tabs.Visuals:CreateParagraph({
    Title = "VISUAL WARNING",
    Content = "ALL items are in fact visual and not real you do not get to keep any of the items after rejoining the game they are only for show and do not actually exist "
})

local WeaponOwnedRange = { min = 1, max = 100000 }

Tabs.Visuals:CreateSection("Weapon Visuals")

Tabs.Visuals:CreateSlider({
    Name = "Min",
    Range = {1, 100000}, CurrentValue = 1,
    Compact = true,
    Callback = function(value) WeaponOwnedRange.min = value end
})

Tabs.Visuals:CreateSlider({
    Name = "Max",
    Range = {1, 100000}, CurrentValue = 150,
    Compact = true,
    Callback = function(value) WeaponOwnedRange.max = value end
})

Tabs.Visuals:CreateButton({
    Name = "spawn random Godlys (if they don’t spawn reset ",
    Compact = true,
    Callback = function()
        local DataBase = require(game:GetService("ReplicatedStorage").Database.Sync.Item)
        local PlayerData = require(game:GetService("ReplicatedStorage").Modules.ProfileData)
        local newOwned = {}
        for i, v in pairs(DataBase) do
            newOwned[i] = math.random(WeaponOwnedRange.min, WeaponOwnedRange.max)
        end
        game:GetService("RunService"):BindToRenderStep("InventoryUpdate", 0, function()
            PlayerData.Weapons.Owned = newOwned
        end)
        Notify({ title = "Visuals Enabled", content = "Fake counts activated!", duration = 2})
    end
})

Tabs.Visuals:CreateSection("Item Spawner")

Tabs.Visuals:CreateInput({
    Name = "Weapon Name",
    Placeholder = "Enter weapon name..",
    Compact = true,
    Callback = function(inputText)
        if inputText and inputText ~= "" then
            spawnWeapon(inputText)
            Notify({ title = "Weapon Spawned", content = inputText.." added!", duration = 2})
        end
    end
})
Tabs.Visuals:CreateSection("weapon dupe ")

Tabs.Visuals:CreateSection("Duplication Options")

Tabs.Visuals:CreateInput({
    Name = "Duplication Multiplier",
    Placeholder = "Enter multiplier (e.g., 2, 3)",
    Compact = true,
    Callback = function(inputText)
        local multiplier = tonumber(inputText)
        if multiplier and multiplier > 0 then
            _G.DupeMultiplier = multiplier
            Notify({ title = "Multiplier Set", content = "Duplication multiplier set to x" .. multiplier, duration = 2})
        else
            Notify({ title = "Invalid Multiplier", content = "Please enter a valid multiplier (greater than 0).", duration = 2})
        end
    end
})

Tabs.Visuals:CreateInput({
    Name = "Specific Item to Duplicate",
    Placeholder = "Enter item name to dupe (e.g., Christmas Knife)",
    Compact = true,
    Callback = function(inputText)
        _G.DupeSpecificItem = inputText
        Notify({ title = "Item Set", content = "Specific item set to duplicate: " .. inputText, duration = 2})
    end
})

Tabs.Visuals:CreateButton({
    Name = "Duplicate Inventory",
    Compact = true,
    Callback = function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local UIPath

        if LocalPlayer.PlayerGui.MainGUI.Game:FindFirstChild("Inventory") ~= nil then
            UIPath = LocalPlayer.PlayerGui.MainGUI.Game.Inventory.Main
        else
            UIPath = LocalPlayer.PlayerGui.MainGUI.Lobby.Screens.Inventory.Main
        end

        local function VisualDupe()
            local multiplier = _G.DupeMultiplier or 2
            local specificItem = _G.DupeSpecificItem

            for _, item in pairs(UIPath.Weapons.Items.Container:GetChildren()) do
                for _, weapon in pairs(item.Container:GetChildren()) do
                    if weapon:IsA("Frame") then
                        local itemName = weapon.ItemName.Label.Text
                        if (not specificItem or itemName == specificItem) and itemName ~= "Default Knife" and itemName ~= "Default Gun" then
                            local amount = weapon.Container.Amount.Text
                            if amount == "" or amount == "None" then
                                weapon.Container.Amount.Text = "x" .. tostring(multiplier)
                            else
                                local num = tonumber(amount:match("x(%d+)"))
                                if num then
                                    weapon.Container.Amount.Text = "x" .. tostring(num * multiplier)
                                end
                            end
                        end
                    end
                end
            end

            for _, pet in pairs(UIPath.Pets.Items.Container.Current.Container:GetChildren()) do
                if pet:IsA("Frame") then
                    local amount = pet.Container.Amount.Text
                    if amount == "" or amount == "None" then
                        pet.Container.Amount.Text = "x" .. tostring(multiplier)
                    else
                        local num = tonumber(amount:match("x(%d+)"))
                        if num then
                            pet.Container.Amount.Text = "x" .. tostring(num * multiplier)
                        end
                    end
                end
            end
        end

        VisualDupe()

        Notify({ title = "Inventory Visual Duplication", content = "Your inventory has been visually duplicated!", duration = 2})
    end
})
Tabs.Esp:CreateSection("Innocent ESP")

InnocentNameESPToggle = Tabs.Esp:CreateToggle({
    Name = "Innocent Name ESP",
        Flag = "InnocentNameESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.InnocentESP.names = state
        managePlayerESPConnection()
    end
})

InnocentBoxESPToggle = Tabs.Esp:CreateToggle({
    Name = "Innocent Box ESP",
        Flag = "InnocentBoxESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.InnocentESP.boxes = state
        managePlayerESPConnection()
    end
})

InnocentBoxTypeDropdown = Tabs.Esp:CreateDropdown({
    Name = "Innocent Box Type",
        Flag = "InnocentBoxTypeDropdown",
    Options = {"2D", "3D"},
    CurrentValue = "2D",
    Callback = function(value)
        featureStates.InnocentESP.boxType = value
    end
})

InnocentTracerToggle = Tabs.Esp:CreateToggle({
    Name = "Innocent Tracer",
        Flag = "InnocentTracerToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.InnocentESP.tracers = state
        managePlayerESPConnection()
    end
})

InnocentDistanceESPToggle = Tabs.Esp:CreateToggle({
    Name = "Innocent Distance ESP",
        Flag = "InnocentDistanceESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.InnocentESP.distance = state
        managePlayerESPConnection()
    end
})

InnocentHighlightsToggle = Tabs.Esp:CreateToggle({
    Name = "Innocent Highlights",
        Flag = "InnocentHighlightsToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.InnocentHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})

Tabs.Esp:CreateSection("Murder ESP")

MurderNameESPToggle = Tabs.Esp:CreateToggle({
    Name = "Murder Name ESP",
        Flag = "MurderNameESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.MurderESP.names = state
        managePlayerESPConnection()
    end
})

MurderBoxESPToggle = Tabs.Esp:CreateToggle({
    Name = "Murder Box ESP",
        Flag = "MurderBoxESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.MurderESP.boxes = state
        managePlayerESPConnection()
    end
})

MurderBoxTypeDropdown = Tabs.Esp:CreateDropdown({
    Name = "Murder Box Type",
        Flag = "MurderBoxTypeDropdown",
    Options = {"2D", "3D"},
    CurrentValue = "2D",
    Callback = function(value)
        featureStates.MurderESP.boxType = value
    end
})

MurderTracerToggle = Tabs.Esp:CreateToggle({
    Name = "Murder Tracer",
        Flag = "MurderTracerToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.MurderESP.tracers = state
        managePlayerESPConnection()
    end
})

MurderDistanceESPToggle = Tabs.Esp:CreateToggle({
    Name = "Murder Distance ESP",
        Flag = "MurderDistanceESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.MurderESP.distance = state
        managePlayerESPConnection()
    end
})

MurderHighlightsToggle = Tabs.Esp:CreateToggle({
    Name = "Murder Highlights",
        Flag = "MurderHighlightsToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.MurderHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})

Tabs.Esp:CreateSection("Hero/Sheriff ESP")

HeroSheriffNameESPToggle = Tabs.Esp:CreateToggle({
    Name = "Hero/Sheriff Name ESP",
        Flag = "HeroSheriffNameESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.names = state
        managePlayerESPConnection()
    end
})

HeroSheriffBoxESPToggle = Tabs.Esp:CreateToggle({
    Name = "Hero/Sheriff Box ESP",
        Flag = "HeroSheriffBoxESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.boxes = state
        managePlayerESPConnection()
    end
})

HeroSheriffBoxTypeDropdown = Tabs.Esp:CreateDropdown({
    Name = "Hero/Sheriff Box Type",
        Flag = "HeroSheriffBoxTypeDropdown",
    Options = {"2D", "3D"},
    CurrentValue = "2D",
    Callback = function(value)
        featureStates.HeroSheriffESP.boxType = value
    end
})

HeroSheriffTracerToggle = Tabs.Esp:CreateToggle({
    Name = "Hero/Sheriff Tracer",
        Flag = "HeroSheriffTracerToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.tracers = state
        managePlayerESPConnection()
    end
})

HeroSheriffDistanceESPToggle = Tabs.Esp:CreateToggle({
    Name = "Hero/Sheriff Distance ESP",
        Flag = "HeroSheriffDistanceESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.distance = state
        managePlayerESPConnection()
    end
})

SheriffHeroHighlightsToggle = Tabs.Esp:CreateToggle({
    Name = "Sheriff/Hero Highlights",
        Flag = "SheriffHeroHighlightsToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.SheriffHeroHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})
Tabs.Esp:CreateSection("Gun ESP")

GunNameESPToggle = Tabs.Esp:CreateToggle({
    Name = "Gun ESP",
        Flag = "GunNameESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.GunESP.names = state
        manageGunESPConnection()
    end
})

GunBoxESPToggle = Tabs.Esp:CreateToggle({
    Name = "Gun Box ESP",
        Flag = "GunBoxESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.GunESP.boxes = state
        manageGunESPConnection()
    end
})

GunBoxTypeDropdown = Tabs.Esp:CreateDropdown({
    Name = "Gun Box Type",
        Flag = "GunBoxTypeDropdown",
    Options = {"2D", "3D"},
    CurrentValue = "3D",
    Callback = function(value)
        featureStates.GunESP.boxType = value
    end
})

GunTracerToggle = Tabs.Esp:CreateToggle({
    Name = "Gun Tracer",
        Flag = "GunTracerToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.GunESP.tracers = state
        manageGunESPConnection()
    end
})

GunDistanceESPToggle = Tabs.Esp:CreateToggle({
    Name = "Gun Distance ESP",
        Flag = "GunDistanceESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.GunESP.distance = state
        manageGunESPConnection()
    end
})

GunHighlightsToggle = Tabs.Esp:CreateToggle({
    Name = "Gun Highlights",
        Flag = "GunHighlightsToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.GunHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})
Tabs.Esp:CreateSection("Coin ESP")

CoinNameESPToggle = Tabs.Esp:CreateToggle({
    Name = "Coin ESP",
        Flag = "CoinNameESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CoinESP.names = state
        manageCoinESPConnection()
    end
})

CoinBoxESPToggle = Tabs.Esp:CreateToggle({
    Name = "Coin Box ESP",
        Flag = "CoinBoxESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CoinESP.boxes = state
        manageCoinESPConnection()
    end
})

CoinBoxTypeDropdown = Tabs.Esp:CreateDropdown({
    Name = "Coin Box Type",
        Flag = "CoinBoxTypeDropdown",
    Options = {"2D", "3D"},
    CurrentValue = "3D",
    Callback = function(value)
        featureStates.CoinESP.boxType = value
    end
})

CoinTracerToggle = Tabs.Esp:CreateToggle({
    Name = "Coin Tracer",
        Flag = "CoinTracerToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CoinESP.tracers = state
        manageCoinESPConnection()
    end
})

CoinDistanceESPToggle = Tabs.Esp:CreateToggle({
    Name = "Coin Distance ESP",
        Flag = "CoinDistanceESPToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CoinESP.distance = state
        manageCoinESPConnection()
    end
})

CoinHighlightsToggle = Tabs.Esp:CreateToggle({
    Name = "Coin Highlights",
        Flag = "CoinHighlightsToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CoinHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})

Tabs.Teleport:CreateSection("Teleport")
Tabs.Teleport:CreateDivider()

function GetPlayerList()
    local playerList = {"Select a player"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(playerList, plr.Name)
        end
    end
    return playerList
end

TeleportPlayerDropdown = Tabs.Teleport:CreateDropdown({
    Name = "Select Player",
        Flag = "TeleportPlayerDropdown",
    Values = GetPlayerList(),
    CurrentValue = "Select a player",
    Callback = function(value)
        selectedPlayerName = value
    end
})

function UpdatePlayerList()
    TeleportPlayerDropdown:Refresh(GetPlayerList(), "Select a player")
end

Tabs.Teleport:CreateButton({
    Name = "Teleport to Player",
    Desc = "Teleport to the selected player",
    Icon = "user",
    Callback = function()
        if selectedPlayerName and selectedPlayerName ~= "Select a player" then
            targetPlayer = Players:FindFirstChild(selectedPlayerName)
            
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Random Player",
    Desc = "Teleport to a random player in the server",
    Icon = "users",
    Callback = function()
        otherPlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(otherPlayers, plr)
            end
        end
        
        if #otherPlayers > 0 then
            randomPlayer = otherPlayers[math.random(1, #otherPlayers)]
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

function FindMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

function FindSheriff()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun")) then
            return plr
        end
    end
    return nil
end

function FindDroppedGun()
    return workspace:FindFirstChild("DropGun")
end

function TeleportToCoin()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local coinServer = workspace:FindFirstChild("Coin_Server")
    if not coinServer then
        return
    end

    local coins = {}
    for _, coin in ipairs(coinServer:GetChildren()) do
        if coin:IsA("BasePart") then
            table.insert(coins, coin)
        end
    end

    if #coins == 0 then
        return
    end

    local targetCoin = coins[math.random(1, #coins)]
    local targetPos = targetCoin.Position + Vector3.new(0, 5, 0)

    humanoidRootPart.CFrame = CFrame.new(targetPos)
end

function TeleportToMap()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local spawnParts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Spawn" then
            local isInLobby = false
            local parent = obj.Parent
            while parent ~= nil do
                if parent.Name == "Lobby" and parent.Parent == workspace then
                    isInLobby = true
                    break
                end
                parent = parent.Parent
            end
            
            if not isInLobby then
                table.insert(spawnParts, obj)
            end
        end
    end
    
    if #spawnParts == 0 then
        return
    end
    
    local randomIndex = math.random(1, #spawnParts)
    local randomSpawn = spawnParts[randomIndex]
    
    humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
end

function TeleportToLobby()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local lobby = workspace:FindFirstChild("Lobby")
    if not lobby then
        return
    end
    
    local spawns = lobby:FindFirstChild("Spawns")
    if not spawns then
        return
    end
    
    local spawnLocations = {}
    for _, obj in pairs(spawns:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawnLocations, obj)
        end
    end
    
    if #spawnLocations == 0 then
        return
    end
    
    local randomIndex = math.random(1, #spawnLocations)
    local randomSpawn = spawnLocations[randomIndex]
    
    humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
end
Tabs.Teleport:CreateButton({
    Name = "Teleport to Innocent",
    Desc = "Teleport to a random innocent player",
    Icon = "user",
    Callback = function()
        murderer = FindMurderer()
        sheriff = FindSheriff()
        
        innocents = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr ~= murderer and plr ~= sheriff and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                hasKnife = plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife"))
                hasGun = plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun"))
                if not hasKnife and not hasGun then
                    table.insert(innocents, plr)
                end
            end
        end
        
        if #innocents > 0 then
            randomInnocent = innocents[math.random(1, #innocents)]
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = randomInnocent.Character.HumanoidRootPart.CFrame
            end
        end
    end
})
Tabs.Teleport:CreateButton({
    Name = "Teleport to Murderer",
    Icon = "user-x",
    Callback = function()
        murderer = FindMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Sheriff",
    Icon = "user-check",
    Callback = function()
        sheriff = FindSheriff()
        if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Dropped Gun",
    Icon = "target",
    Callback = function()
        gun = FindDroppedGun()
        if gun then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(gun.Position)
            end
        end
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Coin",
    Icon = "dollar-sign",
    Callback = function()
        TeleportToCoin()
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Map",
    Icon = "map",
    Callback = function()
        TeleportToMap()
    end
})

Tabs.Teleport:CreateButton({
    Name = "Teleport to Lobby",
    Icon = "home",
    Callback = function()
        TeleportToLobby()
    end
})

Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
end)

Players.PlayerRemoving:Connect(function()
    UpdatePlayerList()
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
end)

Tabs.Misc:CreateSection("Misc")
Tabs.Misc:CreateDivider()

AntiAFKConnection = nil

startAntiAFK = function()
    AntiAFKConnection = player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

stopAntiAFK = function()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

AntiAFKToggle = Tabs.Misc:CreateToggle({
    Name = "Anti AFK",
        Flag = "AntiAFKToggle",
    CurrentValue = featureStates.AntiAFK,
    Callback = function(state)
        featureStates.AntiAFK = state
        if state then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})
Tabs.Misc:CreateSection("Auto Farm")
Tabs.Misc:CreateDivider()

local AutoFarm = {
    Enabled = false,
    Mode = "Teleport",
    TeleportDelay = 0,
    MoveSpeed = 50,
    Connection = nil,
    CoinCheckInterval = 0.5,
    CoinContainers = {
        "Factory",
        "Hospital3",
        "MilBase",
        "House2",
        "Workplace",
        "Mansion2",
        "BioLab",
        "Hotel",
        "Bank2",
        "PoliceStation",
        "ResearchFacility",
        "Lobby"
    }
}

local function findNearestCoin()
    local closestCoin = nil
    local shortestDistance = math.huge
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nil
    end
    for _, containerName in ipairs(AutoFarm.CoinContainers) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            local coinContainer =
                ((containerName == "Lobby") and container) or container:FindFirstChild("CoinContainer")
            if coinContainer then
                for _, coin in ipairs(coinContainer:GetChildren()) do
                    if coin:IsA("BasePart") then
                        local distance = (humanoidRootPart.Position - coin.Position).Magnitude
                        if (distance < shortestDistance) then
                            shortestDistance = distance
                            closestCoin = coin
                        end
                    end
                end
            end
        end
    end
    return closestCoin
end

local function teleportToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    humanoidRootPart.CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))
    task.wait(AutoFarm.TeleportDelay)
end

local function smoothMoveToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    local startTime = tick()
    local startPos = humanoidRootPart.Position
    local endPos = coin.Position + Vector3.new(0, 3, 0)
    local distance = (startPos - endPos).Magnitude
    local duration = distance / AutoFarm.MoveSpeed
    while ((tick() - startTime) < duration) and AutoFarm.Enabled do
        if (not coin or not coin.Parent) then
            break
        end
        local progress = math.min((tick() - startTime) / duration, 1)
        humanoidRootPart.CFrame = CFrame.new(startPos:Lerp(endPos, progress))
        task.wait()
    end
end

local function walkToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    humanoid.WalkSpeed = 16
    humanoid:MoveTo(coin.Position + Vector3.new(0, 0, 3))
    local startTime = tick()
    while AutoFarm.Enabled and (humanoid.MoveDirection.Magnitude > 0) and ((tick() - startTime) < 10) do
        task.wait(0.5)
    end
end

local function collectCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    firetouchinterest(humanoidRootPart, coin, 0)
    firetouchinterest(humanoidRootPart, coin, 1)
end

local function farmLoop()
    while AutoFarm.Enabled do
        local coin = findNearestCoin()
        if coin then
            if (AutoFarm.Mode == "Teleport") then
                teleportToCoin(coin)
            elseif (AutoFarm.Mode == "Smooth") then
                smoothMoveToCoin(coin)
            else
                walkToCoin(coin)
            end
            collectCoin(coin)
            task.wait(2)
        end
        task.wait(AutoFarm.CoinCheckInterval)
    end
end

Tabs.Misc:CreateToggle({
    Name = "Enable AutoFarm",
    CurrentValue = false,
    Callback = function(state)
        AutoFarm.Enabled = state
        if state then
            AutoFarm.Connection = task.spawn(farmLoop)
        else
            if AutoFarm.Connection then
                task.cancel(AutoFarm.Connection)
            end
        end
    end
})
Tabs.Misc:CreateDropdown({
    Name = "Movement Mode",
    Options = {"Teleport", "Smooth", "Walk"},
    CurrentValue = "Teleport",
    Callback = function(mode)
        AutoFarm.Mode = mode
    end
})

Tabs.Misc:CreateSlider({
    Name = "Teleport Delay (sec)",
    Range = {0, 1}, Increment = 0.1, CurrentValue = 0,
    Callback = function(value)
        AutoFarm.TeleportDelay = value
    end
})

Tabs.Misc:CreateSlider({
    Name = "Smooth Move Speed",
    Range = {20, 200}, CurrentValue = 50,
    Callback = function(value)
        AutoFarm.MoveSpeed = value
    end
})

Tabs.Misc:CreateSlider({
    Name = "Check Interval (sec)",
    Increment = 0.1,
    Range = {0.1, 2}, CurrentValue = 0.5,
    Callback = function(value)
        AutoFarm.CoinCheckInterval = value
    end
})
ExpFarm = false
ExpFarmConnection = nil

if not workspace:FindFirstChild("SecurityPart") then
    local SecurityPart = Instance.new("Part")
    SecurityPart.Name = "SecurityPart"
    SecurityPart.Size = Vector3.new(10, 1, 10)
    SecurityPart.Position = Vector3.new(50000, 50000, 50000)
    SecurityPart.Anchored = true
    SecurityPart.CanCollide = true
    SecurityPart.Parent = workspace
end

function startExpFarm()
    local securityPart = workspace:FindFirstChild("SecurityPart")
    if not securityPart then
        print("SecurityPart not found")
        return
    end
    
    ExpFarmConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if character and rootPart then
            rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

function stopExpFarm()
    if ExpFarmConnection then
        ExpFarmConnection:Disconnect()
        ExpFarmConnection = nil
    end
end

ExpFarmToggle = Tabs.Misc:CreateToggle({
    Name = "Exp Farm",
        Flag = "ExpFarmToggle",
    CurrentValue = false,
    Callback = function(state)
        ExpFarm = state
        if state then
            startExpFarm()
        else
            stopExpFarm()
        end
    end
})
local function getPlayerRole(playerName)
    local success, roles = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if success and roles then
        local playerData = roles[playerName]
        if playerData then
            return playerData.Role
        end
    end
    return nil
end

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

local function findSheriffOrHero()
    local success, roles = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if success and roles then
        for playerName, data in pairs(roles) do
            if data.Role == "Sheriff" or data.Role == "Hero" then
                return Players:FindFirstChild(playerName), data.Role
            end
        end
    end
    return nil, nil
end

Tabs.Misc:CreateSection("Role Revealer")
Tabs.Misc:CreateDivider()

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

local function findSheriff()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun")) then
            return plr
        end
    end
    return nil
end

local function findHero()
    local success, roles = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if success and roles then
        for playerName, data in pairs(roles) do
            if data.Role == "Hero" then
                return Players:FindFirstChild(playerName)
            end
        end
    end
    return nil
end

Tabs.Misc:CreateButton({
    Name = "Reveal Murderer",
    Desc = "Reveal murderer in chat",
    Icon = "user-x",
    Callback = function()
        local textchannels = game:GetService("TextChatService"):WaitForChild("TextChannels"):GetChildren()
        for _, textchannel in ipairs(textchannels) do
            if textchannel.Name == "RBXSystem" then continue end
            local murd = findMurderer()
            if murd then
                local message = string.format("%s Is Murderer | Script Used: Aethel Hub", murd.Name)
                textchannel:SendAsync(message)
            else
                local message = "No Murderer Found | Script Used: Aethel Hub"
                textchannel:SendAsync(message)
            end
        end
    end
})

Tabs.Misc:CreateButton({
    Name = "Reveal Sheriff/Hero",
    Desc = "Reveal sheriff or hero in chat",
    Icon = "user-check",
    Callback = function()
        local textchannels = game:GetService("TextChatService"):WaitForChild("TextChannels"):GetChildren()
        for _, textchannel in ipairs(textchannels) do
            if textchannel.Name == "RBXSystem" then continue end
            local sher = findSheriff()
            local hero = findHero()
            if sher then 
                local message = string.format("%s Is Sheriff | Script Used: Aethel Hub", sher.Name)
                textchannel:SendAsync(message)
            elseif hero then
                local message = string.format("%s Is Hero | Script Used: Aethel Hub", hero.Name)
                textchannel:SendAsync(message)
            else
                local message = "No Sheriff/Hero Found | Script Used: Aethel Hub"
                textchannel:SendAsync(message)
            end
        end
    end
})
Tabs.Misc:CreateButton({
    Name = "Trade Helper",
    Compact = true,
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/8LDyigix"))()
        Notify({ title = "Trade Helper", content = "Script loaded!", duration = 3})
    end
})

Tabs.Utility:CreateButton({
    Name = "Unlock all emote and toy",
    Desc = "The toy is useless so don't mind it if it's not working",
    Callback = function()
    -- MM2 All Emotes Unlocker (2025) Script
--[[ ((Don't use this if you hate overlapping bug
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayEmote = ReplicatedStorage.Remotes.Misc.PlayEmote
local ItemService = require(ReplicatedStorage.ClientServices.ItemService)
local function getAllEmotes()
    local emotes = {}
    local success, syncModule = pcall(require, ReplicatedStorage.Database.Sync)
    if success and syncModule then
         if syncModule.Emotes then
            for emoteName, _ in pairs(syncModule.Emotes) do
                table.insert(emotes, emoteName)
            end
        end
        if syncModule.Toys then
            for toyName, _ in pairs(syncModule.Toys) do
                table.insert(emotes, toyName)
            end
        end
    end
    local defaultEmotes = {"wave", "cheer", "laugh", "dance1", "dance2", "dance3"}
    for _, emote in ipairs(defaultEmotes) do
        table.insert(emotes, emote)
    end
    return emotes
end
local AllEmotes = getAllEmotes()
local function UnlockEmotes()
    local Cross = PlayerGui:FindFirstChild("CrossPlatform")
    if not Cross then return end
    local Emotes = Cross:FindFirstChild("Emotes")
    if not Emotes then return end
    local Controller = Emotes:FindFirstChild("EmoteController")
    local Window = Emotes:FindFirstChild("EmoteWindow")
    if not Controller or not Window then return end
    local GameEmotes = Window.EmoteContainer.EmotePages["Game Emotes"]
    local FrameTemplate = Controller.EmoteFrame
    local RowTemplate = Controller.RowFrame
    for _, v in pairs(GameEmotes:GetChildren()) do
        if v.Name:match("^Row") then
            v:Destroy()
        end
    end
    local row, slot = 1, 1
    for _, emote in ipairs(AllEmotes) do
        local info = ItemService:GetItemInfo(emote, "Emotes")
        if not info then
            -- Try getting as toy if not found as emote
            info = ItemService:GetItemInfo(emote, "Toys")
        end
        if info then
            if slot == 1 then
                local newRow = RowTemplate:Clone()
                newRow.Name = "Row"..row
                newRow.Parent = GameEmotes
                newRow.LayoutOrder = row
            end
            local frame = FrameTemplate:Clone()
            frame.Name = "Emote"..slot
            frame:SetAttribute("EmoteName", emote)
            frame.EmoteName.Text = info.Name or emote
            frame.EmoteIcon.Image = ItemService:GetItemImage(info)
            frame.Hotkey.KeyLabel.Text = slot
            frame.Hotkey.Visible = UserInputService.KeyboardEnabled
            frame.Parent = GameEmotes["Row"..row]
            frame.PlayButton.Activated:Connect(function()
                PlayEmote:Fire(emote)
            end)
            slot += 1
            if slot > 8 then
                slot = 1
                row += 1
            end
        end
    end
end
local function initialize()
    PlayerGui:WaitForChild("CrossPlatform", 10)
    task.wait(1)
    UnlockEmotes()
end
if PlayerGui:FindFirstChild("CrossPlatform") then
    UnlockEmotes()
else
    initialize()
end
ReplicatedStorage.Remotes.Inventory.InventoryDataChanged.Event:Connect(function(cat)
    if cat == "Emotes" or cat == "Toys" then
        task.wait(0.3)
        UnlockEmotes()
    end
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    UnlockEmotes()
end)
]]
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local PlayEmote = ReplicatedStorage.Remotes.Misc.PlayEmote
        local ItemService = require(ReplicatedStorage.ClientServices.ItemService)
        
        local function getAllEmotes()
            local emotes = {}
            local added = {}
            
            local success, syncModule = pcall(require, ReplicatedStorage.Database.Sync)
            if success and syncModule then
                if syncModule.Emotes then
                    for emoteName, _ in pairs(syncModule.Emotes) do
                        if not added[emoteName] then
                            table.insert(emotes, emoteName)
                            added[emoteName] = true
                        end
                    end
                end
                
                if syncModule.Toys then
                    for toyName, _ in pairs(syncModule.Toys) do
                        if not added[toyName] then
                            table.insert(emotes, toyName)
                            added[toyName] = true
                        end
                    end
                end
            end
            
            local defaultEmotes = {"wave", "cheer", "laugh", "dance1", "dance2", "dance3"}
            for _, emote in ipairs(defaultEmotes) do
                if not added[emote] then
                    table.insert(emotes, emote)
                    added[emote] = true
                end
            end
            
            return emotes
        end
        
        local AllEmotes = getAllEmotes()
        
        local function UnlockEmotes()
            local Cross = PlayerGui:FindFirstChild("CrossPlatform")
            if not Cross then return end
            
            local Emotes = Cross:FindFirstChild("Emotes")
            if not Emotes then return end
            
            local Controller = Emotes:FindFirstChild("EmoteController")
            local Window = Emotes:FindFirstChild("EmoteWindow")
            if not Controller or not Window then return end
            
            local GameEmotes = Window.EmoteContainer.EmotePages["Game Emotes"]
            local FrameTemplate = Controller.EmoteFrame
            local RowTemplate = Controller.RowFrame
            
            for _, v in pairs(GameEmotes:GetChildren()) do
                if v.Name:match("^Row") then
                    v:Destroy()
                end
            end
            
            GameEmotes.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#AllEmotes / 4) * 120)
            
            local row, slot = 1, 1
            local maxSlotsPerRow = 6
            
            for _, emote in ipairs(AllEmotes) do
                local info = ItemService:GetItemInfo(emote, "Emotes")
                if not info then
                    info = ItemService:GetItemInfo(emote, "Toys")
                end
                
                if info then
                    if slot == 1 then
                        local newRow = RowTemplate:Clone()
                        newRow.Name = "Row"..row
                        newRow.Parent = GameEmotes
                        newRow.LayoutOrder = row
                        newRow.Size = UDim2.new(1, 0, 0, 100)
                    end
                    
                    local frame = FrameTemplate:Clone()
                    frame.Name = "Emote"..slot
                    frame:SetAttribute("EmoteName", emote)
                    frame.EmoteName.Text = info.Name or emote
                    frame.EmoteIcon.Image = ItemService:GetItemImage(info)
                    frame.Hotkey.KeyLabel.Text = slot
                    frame.Hotkey.Visible = UserInputService.KeyboardEnabled
                    frame.Size = UDim2.new(1/maxSlotsPerRow, -5, 1, -5)
                    frame.Position = UDim2.new((slot-1)/maxSlotsPerRow, 0, 0, 0)
                    frame.Parent = GameEmotes["Row"..row]
                    frame.PlayButton.Activated:Connect(function()
                        PlayEmote:Fire(emote)
                    end)
                    
                    slot += 1
                    if slot > maxSlotsPerRow then
                        slot = 1
                        row += 1
                    end
                end
            end
            
            if slot > 1 and slot <= maxSlotsPerRow then
                local newRow = RowTemplate:Clone()
                newRow.Name = "Row"..row
                newRow.Parent = GameEmotes
                newRow.LayoutOrder = row
                newRow.Size = UDim2.new(1, 0, 0, 100)
            end
        end
        
        local function UnlockEmotesAdvanced()
            local Cross = PlayerGui:FindFirstChild("CrossPlatform")
            if not Cross then return end
            
            local Emotes = Cross:FindFirstChild("Emotes")
            if not Emotes then return end
            
            local Controller = Emotes:FindFirstChild("EmoteController")
            local Window = Emotes:FindFirstChild("EmoteWindow")
            if not Controller or not Window then return end
            
            local GameEmotes = Window.EmoteContainer.EmotePages["Game Emotes"]
            local FrameTemplate = Controller.EmoteFrame
            
            for _, v in pairs(GameEmotes:GetChildren()) do
                if v.Name:match("^Row") or v.Name:match("^Emote") then
                    v:Destroy()
                end
            end
            
            if not GameEmotes:IsA("ScrollingFrame") then
                local scrollingFrame = Instance.new("ScrollingFrame")
                scrollingFrame.Name = "EmoteScroller"
                scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
                scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
                scrollingFrame.BackgroundTransparency = 1
                scrollingFrame.BorderSizePixel = 0
                scrollingFrame.ScrollBarThickness = 8
                scrollingFrame.Parent = GameEmotes
                
                local uiGridLayout = Instance.new("UIGridLayout")
                uiGridLayout.CellSize = UDim2.new(0, 80, 0, 80)
                uiGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
                uiGridLayout.FillDirection = Enum.FillDirection.Horizontal
                uiGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
                uiGridLayout.Parent = scrollingFrame
                GameEmotes = scrollingFrame
            end
            
            for index, emote in ipairs(AllEmotes) do
                local info = ItemService:GetItemInfo(emote, "Emotes")
                if not info then
                    info = ItemService:GetItemInfo(emote, "Toys")
                end
                
                if info then
                    local frame = FrameTemplate:Clone()
                    frame.Name = "Emote"..index
                    frame:SetAttribute("EmoteName", emote)
                    frame.EmoteName.Text = info.Name or emote
                    frame.EmoteIcon.Image = ItemService:GetItemImage(info)
                    frame.Hotkey.KeyLabel.Text = index
                    frame.Hotkey.Visible = UserInputService.KeyboardEnabled
                    frame.Size = UDim2.new(0, 70, 0, 70)
                    frame.LayoutOrder = index
                    frame.Parent = GameEmotes
                    frame.PlayButton.Activated:Connect(function()
                        PlayEmote:Fire(emote)
                    end)
                end
            end
            
            local emotesCount = #AllEmotes
            local rows = math.ceil(emotesCount / 6)
            GameEmotes.CanvasSize = UDim2.new(0, 0, 0, rows * 85)
        end
        
        local function initialize()
            PlayerGui:WaitForChild("CrossPlatform", 10)
            task.wait(1)
            local success = pcall(UnlockEmotesAdvanced)
            if not success then
                UnlockEmotes()
            end
        end
        
        if PlayerGui:FindFirstChild("CrossPlatform") then
            local success = pcall(UnlockEmotesAdvanced)
            if not success then
                UnlockEmotes()
            end
        else
            initialize()
        end
        
        ReplicatedStorage.Remotes.Inventory.InventoryDataChanged.Event:Connect(function(cat)
            if cat == "Emotes" or cat == "Toys" then
                task.wait(0.3)
                local success = pcall(UnlockEmotesAdvanced)
                if not success then
                    UnlockEmotes()
                end
            end
        end)
        
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(2)
            local success = pcall(UnlockEmotesAdvanced)
            if not success then
                UnlockEmotes()
            end
        end)
    end
})
emoteInputValue = ""

Tabs.Utility:CreateInput({
    Name = "Emote Name",
    Placeholder = "Enter emote name",
    Callback = function(emoteName)
        emoteInputValue = emoteName
    end
})

Tabs.Utility:CreateButton({
    Name = "Play Emote By Name",
    Callback = function()
        if emoteInputValue and emoteInputValue ~= "" then
            game:GetService("ReplicatedStorage").Remotes.Misc.PlayEmote:Fire(emoteInputValue)
        end
    end
})
hiddenfling = false
movel = 0.1
flingPower = 1e35
flingCoroutine = nil

function fling()
    local chr = player.Character
    if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    while hiddenfling and chr and hrp and hrp.Parent do
        local vel = hrp.Velocity
        hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
        RunService.Stepped:Wait()
        hrp.Velocity = vel + Vector3.new(0, movel, 0)
        movel = -movel
        RunService.Heartbeat:Wait()
    end
end

function startFling()
    if flingCoroutine then
        coroutine.close(flingCoroutine)
        flingCoroutine = nil
    end
    flingCoroutine = coroutine.create(fling)
    coroutine.resume(flingCoroutine)
end

function stopFling()
    if flingCoroutine then
        coroutine.close(flingCoroutine)
        flingCoroutine = nil
    end
    
    local chr = player.Character
    if chr then
        local hrp = chr:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

TouchFlingToggle = Tabs.Utility:CreateToggle({
    Name = "Touch Fling",
        Flag = "TouchFlingToggle",
    CurrentValue = false,
    Callback = function(state)
        hiddenfling = state
        if state then
            startFling()
        else
            stopFling()
        end
    end
})

player.CharacterAdded:Connect(function(character)
    if hiddenfling then
        task.wait(1)
        startFling()
    else
        task.wait(0.5)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

Tabs.Utility:CreateInput({
    Name = "Fling Power",
    Placeholder = "Enter fling power (default: 1e35)",
    Callback = function(value)
        if value and value ~= "" then
            flingPower = tonumber(value) or 1e35
        end
    end
})
Tabs.Utility:CreateButton({
    Name = "Fling Tool",
    Icon = "rbxassetid://3836615692",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE/main/punch"))()
    end
})

flingActive = false
flingMode = 1
currentInput = ""
processedPlayers = {}
localPlayer = game.Players.LocalPlayer
roles = {}
Murder = nil
Sheriff = nil
Hero = nil

local function IsAlive(Player)
    for i, v in pairs(roles) do
        if Player.Name == i then
            if not v.Killed and not v.Dead then
                return true
            else
                return false
            end
        end
    end
    return false
end

function updateRoles()
    local success, result = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if success and result then
        roles = result
        Murder = nil
        Sheriff = nil
        Hero = nil
        
        for i, v in pairs(roles) do
            if v.Role == "Murderer" then
                Murder = i
            elseif v.Role == 'Sheriff' then
                Sheriff = i
            elseif v.Role == 'Hero' then
                Hero = i
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    updateRoles()
end)

function sortPlayersAlphabetically(players)
    table.sort(players, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return players
end

function getPlayers(input)
    local players = {}
    input = string.lower(input or "")
    
    if input == "all" then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(players, player)
            end
        end
        players = sortPlayersAlphabetically(players)
    elseif input == "nonfriends" then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                local success, isFriend = pcall(function()
                    return player:IsFriendsWith(localPlayer.UserId)
                end)
                if not (success and isFriend) then
                    table.insert(players, player)
                end
            end
        end
        players = sortPlayersAlphabetically(players)
    elseif input == "murder" then
        if Murder then
            local murdererPlayer = game.Players:FindFirstChild(Murder)
            if murdererPlayer and murdererPlayer ~= localPlayer and murdererPlayer.Character and IsAlive(murdererPlayer) then
                table.insert(players, murdererPlayer)
            end
        end
    elseif input == "sheriff" or input == "hero" then
        if Sheriff then
            local sheriffPlayer = game.Players:FindFirstChild(Sheriff)
            if sheriffPlayer and sheriffPlayer ~= localPlayer and sheriffPlayer.Character and IsAlive(sheriffPlayer) then
                table.insert(players, sheriffPlayer)
            end
        end
        if Hero then
            local heroPlayer = game.Players:FindFirstChild(Hero)
            if heroPlayer and heroPlayer ~= localPlayer and heroPlayer.Character and IsAlive(heroPlayer) then
                table.insert(players, heroPlayer)
            end
        end
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                local playerName = string.lower(player.Name)
                local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
                
                for _, term in ipairs(searchTerms) do
                    if string.find(playerName, term) or string.find(displayName, term) then
                        table.insert(players, player)
                        break
                    end
                end
            end
        end
    end
    
    return players
end

function SkidFling(TargetPlayer, duration)
    local startTime = tick()
    local Character = localPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= game.Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end
        
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

function shhhlol(TargetPlayer)
    local Character = localPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

        local function mmmm(comkid, Pos, Ang)
            RootPart.CFrame = CFrame.new(comkid.Position) * Pos * Ang
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end

        local function wtf(comkid)
            local TimeToWait = 0.134
            local Time = tick()
            
            local Att1 = Instance.new("Attachment", RootPart)
            local Att2 = Instance.new("Attachment", comkid)

            repeat
                if RootPart and THumanoid then
                    if comkid.Velocity.Magnitude < 30 then
                        mmmm(
                            comkid,
                            CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 5,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()

                        mmmm(
                            comkid,
                            CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()

                        mmmm(
                            comkid,
                            CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()
                    else
                        mmmm(comkid, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(0), 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until comkid.Velocity.Magnitude > 1000 or 
                  comkid.Parent ~= TargetPlayer.Character or
                  TargetPlayer.Parent ~= game.Players or
                  not TargetPlayer.Character == TCharacter or
                  Humanoid.Health <= 0 or
                  tick() > Time + TimeToWait or
                  not flingActive

            Att1:Destroy()
            Att2:Destroy()
        end

        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(-9e99, 9e99, -9e99)
        BV.MaxForce = Vector3.new(-9e9, 9e9, -9e9)

        local BodyGyro = Instance.new("BodyGyro")
        BodyGyro.CFrame = CFrame.new(RootPart.Position)
        BodyGyro.D = 9e8
        BodyGyro.MaxTorque = Vector3.new(-9e9, 9e9, -9e9)
        BodyGyro.P = -9e9

        local BodyPosition = Instance.new("BodyPosition")
        BodyPosition.Position = RootPart.Position
        BodyPosition.D = 9e8
        BodyPosition.MaxForce = Vector3.new(-9e9, 9e9, -9e9)
        BodyPosition.P = -9e9

        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                wtf(THead)
            else
                wtf(TRootPart)
            end
        elseif TRootPart and not THead then
            wtf(TRootPart)
        elseif not TRootPart and THead then
            wtf(THead)
        end

        BV:Destroy()
        BodyGyro:Destroy()
        BodyPosition:Destroy()
        
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetDescendants()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

function yeet(targetPlayer)
    local character = localPlayer.Character
    local targetCharacter = targetPlayer.Character

    if not character or not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end

    if character.HumanoidRootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = character.HumanoidRootPart.CFrame
    end

    local existingForce = character.HumanoidRootPart:FindFirstChild("YeetForce")
    if existingForce then
        existingForce:Destroy()
    end

    local Thrust = Instance.new('BodyThrust', character.HumanoidRootPart)
    Thrust.Force = Vector3.new(9999, 9999, 9999)
    Thrust.Name = "YeetForce"

    local previousDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0

    local startTime = tick()
    local duration = (currentInput == "all" or currentInput == "nonfriends") and 5 or math.huge

    local yeetConnection
    yeetConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") or not flingActive or tick() > startTime + duration then
            yeetConnection:Disconnect()
            Thrust:Destroy()
            workspace.FallenPartsDestroyHeight = previousDestroyHeight

            if character and character.HumanoidRootPart and getgenv().OldPos then
                character.HumanoidRootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                character.Humanoid:ChangeState("GettingUp")
                for _, x in pairs(character:GetDescendants()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            return
        end

        local targetHRP = targetCharacter.HumanoidRootPart
        local targetVelocity = targetHRP.Velocity
        local speed = targetVelocity.Magnitude
        local direction = targetVelocity.Unit

        local offsetPosition
        if speed > 0.1 then
            offsetPosition = targetHRP.Position + (direction * speed)
        else
            offsetPosition = targetHRP.Position + Vector3.new(0, 0, 0)
        end

        character.HumanoidRootPart.CFrame = CFrame.new(offsetPosition)

        Thrust.Location = targetHRP.Position
    end)

    return true
end

function flingPlayers()
    local players = {}
    for player, _ in pairs(processedPlayers) do
        if player and player.Character and player.Character.Parent ~= nil then
            table.insert(players, player)
        end
    end
    
    if currentInput == "all" or currentInput == "nonfriends" then
        players = sortPlayersAlphabetically(players)
    end
    
    for _, player in ipairs(players) do
        if not flingActive then break end
        
        if player and player.Character and player.Character.Parent ~= nil then
            local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
            
            if flingMode == 1 then
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
                if currentInput == "all" or currentInput == "nonfriends" then
                    task.wait(1.5)
                end
            end
        end
    end
    
    if flingActive then
        task.wait()
        flingPlayers()
    end
end

function addPlayerToProcessed(player)
    if not player or player == localPlayer then return end
    
    local matchesFilter = false
    local input = string.lower(currentInput)
    
    if input == "all" then
        matchesFilter = true
    elseif input == "nonfriends" then
        local success, isFriend = pcall(function()
            return player:IsFriendsWith(localPlayer.UserId)
        end)
        matchesFilter = not (success and isFriend)
    elseif input == "murder" then
        if Murder and player.Name == Murder then
            matchesFilter = IsAlive(player)
        end
    elseif input == "sheriff" or input == "hero" then
        if (Sheriff and player.Name == Sheriff) or (Hero and player.Name == Hero) then
            matchesFilter = IsAlive(player)
        end
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        
        local playerName = string.lower(player.Name)
        local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
        
        for _, term in ipairs(searchTerms) do
            if string.find(playerName, term) or string.find(displayName, term) then
                matchesFilter = true
                break
            end
        end
    end
    
    if matchesFilter then
        processedPlayers[player] = true
    end
end

flingInputValue = ""
FlingInput = Tabs.Utility:CreateInput({
    Name = "Fling Target",
        Flag = "FlingInput",
    Placeholder = "nickname, all, nonfriends, murder, sheriff",
    Callback = function(value)
        flingInputValue = value
        currentInput = string.lower(value)
    end
})

FlingModeDropdown = Tabs.Utility:CreateDropdown({
    Name = "Fling Mode",
        Flag = "FlingModeDropdown",
    Options = {"SkidFling", "Shhhlol", "Yeet"},
    CurrentValue = "SkidFling",
    Callback = function(value)
        if value == "SkidFling" then
            flingMode = 1
        elseif value == "Shhhlol" then
            flingMode = 2
        elseif value == "Yeet" then
            flingMode = 3
        end
    end
})

FlingToggle = Tabs.Utility:CreateToggle({
    Name = "Fling Players",
        Flag = "FlingToggle",
    CurrentValue = false,
    Callback = function(state)
        flingActive = state
        
        if flingActive then
            currentInput = string.lower(flingInputValue or "")
            local players = getPlayers(currentInput)
            
            if #players == 0 then
                Notify({
                    title = "Fling Target",
                    content = "Invalid Input: " .. currentInput,
                     duration = 3,
                })
                flingActive = false
                FlingToggle:Set(false)
                return
            end
            
            processedPlayers = {}
            for _, player in ipairs(players) do
                addPlayerToProcessed(player)
            end
            
            Notify({
                title = "Fling Target",
                content = "Flinging " .. #players .. " players",
                     duration = 3,
            })
            
            coroutine.wrap(flingPlayers)()
        else
            processedPlayers = {}
        end
    end
})

Tabs.Utility:CreateButton({
    Name = "Fling Murderer",
    Callback = function()
        if flingActive then
            Notify({
                title = "Fling Target",
                content = "Stop current fling first",
                     duration = 2,
            })
            return
        end
        
        currentInput = "murder"
        local players = getPlayers(currentInput)
        
        if #players == 0 then
            Notify({
                title = "Fling Target",
                content = "No alive murderer found",
                     duration = 3,
            })
            return
        end
        
        flingActive = true
        processedPlayers = {}
        for _, player in ipairs(players) do
            addPlayerToProcessed(player)
        end
        
        Notify({
            title = "Fling Target",
            content = "Flinging murderer: " .. players[1].Name .. " for 10 seconds",
                     duration = 3,
        })
        
        local stopTimer = 10
        local startTime = tick()
        
        coroutine.wrap(function()
            while flingActive and tick() - startTime < stopTimer do
                task.wait(1)
            end
            if flingActive then
                flingActive = false
                processedPlayers = {}
                FlingToggle:Set(false)
            end
        end)()
        
        coroutine.wrap(flingPlayers)()
    end
})

Tabs.Utility:CreateButton({
    Name = "Fling Sheriff/Hero",
    Callback = function()
        if flingActive then
            Notify({
                title = "Fling Target",
                content = "Stop current fling first",
                     duration = 2,
            })
            return
        end
        
        currentInput = "sheriff"
        local players = getPlayers(currentInput)
        
        if #players == 0 then
            Notify({
                title = "Fling Target",
                content = "No alive sheriff or hero found",
                     duration = 3,
            })
            return
        end
        
        flingActive = true
        processedPlayers = {}
        for _, player in ipairs(players) do
            addPlayerToProcessed(player)
        end
        
        local targetNames = ""
        for i, player in ipairs(players) do
            targetNames = targetNames .. player.Name
            if i < #players then
                targetNames = targetNames .. ", "
            end
        end
        
        Notify({
            title = "Fling Target",
            content = "Flinging: " .. targetNames .. " for 10 seconds",
                     duration = 3,
        })
        
        local stopTimer = 10
        local startTime = tick()
        
        coroutine.wrap(function()
            while flingActive and tick() - startTime < stopTimer do
                task.wait(1)
            end
            if flingActive then
                flingActive = false
                processedPlayers = {}
                FlingToggle:Set(false)
            end
        end)()
        
        coroutine.wrap(flingPlayers)()
    end
})
game.Players.PlayerAdded:Connect(function(player)
    if flingActive then
        addPlayerToProcessed(player)
        if player.Character then
            if flingMode == 1 then
                local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
            end
        else
            player.CharacterAdded:Connect(function()
                if flingActive then
                    addPlayerToProcessed(player)
                    if flingMode == 1 then
                        local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                        SkidFling(player, duration)
                    elseif flingMode == 2 then
                        shhhlol(player)
                    elseif flingMode == 3 then
                        yeet(player)
                    end
                end
            end)
        end
    end
end)

localPlayer.CharacterAdded:Connect(function()
    if flingActive then
        task.wait(1)
        coroutine.wrap(flingPlayers)()
    end
end)
antiVoidActive = false
originalDestroyHeight = workspace.FallenPartsDestroyHeight

function enableAntiVoid()
    if antiVoidActive then return end
    antiVoidActive = true
    originalDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = -math.huge
end

function disableAntiVoid()
    if not antiVoidActive then return end
    workspace.FallenPartsDestroyHeight = originalDestroyHeight
    antiVoidActive = false
end

Tabs.Utility:CreateToggle({
    Name = "Anti Void Damage",
    CurrentValue = false,
    Callback = function(state)
        if state then
            enableAntiVoid()
        else
            disableAntiVoid()
        end
    end
})
infinitePositionEnabled = false
savedPosition = nil
positionConnection = nil
positionTolerance = 0.1

function lockPosition()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if not savedPosition then
        savedPosition = hrp.CFrame
    end

    positionConnection = RunService.Heartbeat:Connect(function()
        if hrp and hrp.Parent and savedPosition then
            if (hrp.Position - savedPosition.Position).Magnitude > positionTolerance then
                hrp.CFrame = savedPosition
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

function unlockPosition()
    if positionConnection then
        positionConnection:Disconnect()
        positionConnection = nil
    end
    savedPosition = nil
end

InfinitePositionToggle = Tabs.Utility:CreateToggle({
    Name = "Infinite Position Lock",
        Flag = "InfinitePositionToggle",
    Desc = "Lock your position in place",
    CurrentValue = false,
    Callback = function(state)
        infinitePositionEnabled = state
        if state then
            lockPosition()
            player.CharacterAdded:Connect(function()
                if infinitePositionEnabled then
                    task.wait(0.1)
                    lockPosition()
                end
            end)
        else
            unlockPosition()
        end
    end
})
TimeChangerInput = Tabs.Utility:CreateInput({
    Name = "Set Time (HH:MM)",
        Flag = "TimeChangerInput",
    Placeholder = "12:00",
    Callback = function(value)
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        local h_str, m_str = value:match("(%d+):(%d+)")
        if h_str and m_str then
            local h = tonumber(h_str)
            local m = tonumber(m_str)
            
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
                local totalHours = h + (m / 60)
                game:GetService("Lighting").ClockTime = totalHours
             end
        end
    end
})
getgenv().lagSwitchEnabled = false
getgenv().lagDuration = 0.5
lagGui = nil
lagGuiButton = nil
lagInputConnection = nil
isLagActive = false
lagSystemLoaded = false

local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    
    local originalBackground = frame.BackgroundColor3
    local originalTransparency = frame.BackgroundTransparency
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency - 0.1
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency
        end
    end)
end

function loadLagSystem()
    if lagSystemLoaded then return end
    lagSystemLoaded = true
    
    if not lagInputConnection then
        lagInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.L and getgenv().lagSwitchEnabled and not isLagActive then
                isLagActive = true
                task.spawn(function()
                    local duration = getgenv().lagDuration or 0.5
                    local start = tick()
                    while tick() - start < duration do
                        local a = math.random(1, 1000000) * math.random(1, 1000000)
                        a = a / math.random(1, 10000)
                    end
                    isLagActive = false
                end)
            end
        end)
    end
end

function unloadLagSystem()
    if not lagSystemLoaded then return end
    lagSystemLoaded = false
    
    if lagInputConnection then
        lagInputConnection:Disconnect()
        lagInputConnection = nil
    end
    isLagActive = false
end

function checkLagState()
    local shouldLoad = getgenv().lagSwitchEnabled
    
    if shouldLoad and not lagSystemLoaded then
        loadLagSystem()
    elseif not shouldLoad and lagSystemLoaded then
        unloadLagSystem()
    end
end

function createLagGui(yOffset)
    local lagGuiOld = playerGui:FindFirstChild("LagSwitchGui")
    if lagGuiOld then lagGuiOld:Destroy() end
    
    lagGui = Instance.new("ScreenGui")
    lagGui.Name = "LagSwitchGui"
    lagGui.IgnoreGuiInset = true
    lagGui.ResetOnSpawn = false
    lagGui.Enabled = getgenv().lagSwitchEnabled
    lagGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = lagGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Lag"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    lagGuiButton = Instance.new("TextButton")
    lagGuiButton.Name = "TriggerButton"
    lagGuiButton.Text = "Trigger"
    lagGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    lagGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    lagGuiButton.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    lagGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lagGuiButton.Font = Enum.Font.Roboto
    lagGuiButton.TextSize = 14
    lagGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    lagGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    lagGuiButton.TextScaled = true
    lagGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = lagGuiButton

    lagGuiButton.MouseButton1Click:Connect(function()
        if not isLagActive then
            isLagActive = true
            task.spawn(function()
                local start = tick()
                while tick() - start < (getgenv().lagDuration or 0.5) do
                    local a = math.random(1, 1000000) * math.random(1, 1000000)
                    a = a / math.random(1, 10000)
                end
                isLagActive = false
            end)
        end
    end)
end

LagSwitchToggle = Tabs.Utility:CreateToggle({
    Name = "Lag Switch",
        Flag = "LagSwitchToggle",
    Icon = "zap",
    CurrentValue = false,
    Callback = function(state)
        getgenv().lagSwitchEnabled = state
        if state then
            if not lagGui then
                createLagGui(0)
            else
                lagGui.Enabled = true
            end
        else
            if lagGui then
                lagGui.Enabled = false
            end
        end
        checkLagState()
    end
})

LagDurationInput = Tabs.Utility:CreateInput({
    Name = "Lag Duration (seconds)",
        Flag = "LagDurationInput",
    Placeholder = "0.5",
    CurrentValue = tostring(getgenv().lagDuration),
    NumbersOnly = true,
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            getgenv().lagDuration = n
        end
    end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        unloadLagSystem()
        if lagGui then
            lagGui:Destroy()
        end
    end
end)

checkLagState()
GravityToggle = Tabs.Utility:CreateToggle({
    Name = "Custom Gravity",
        Flag = "GravityToggle",
    CurrentValue = false,
    Callback = function(state)
        featureStates.CustomGravity = state
        if state then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
    end
})

GravityInput = Tabs.Utility:CreateInput({
    Name = "Gravity Value",
        Flag = "GravityInput",
    Placeholder = tostring(originalGameGravity),
    CurrentValue = tostring(featureStates.GravityValue),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            featureStates.GravityValue = num
            if featureStates.CustomGravity then
                workspace.Gravity = num
            end
        end
    end
})
getgenv().gravityGuiVisible = false

GravityGUIToggle = Tabs.Utility:CreateToggle({
    Name = "Gravity toggle shortcuts",
        Flag = "GravityGUIToggle",
    Desc = "Toggle gui or keybind for quick enable gravity",
    Icon = "toggle-right",
    CurrentValue = false,
    Callback = function(state)
        getgenv().gravityGuiVisible = state
        local gravityGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GravityGui")
        if gravityGui then
            gravityGui.Enabled = state
        end
        if not state then
            Notify({
                title = "Gravity GUI",
                content = "GUI And keybind disabled.",
                     duration = 3,
            })
        else
            Notify({
                title = "Gravity toggle shortcuts",
                content = "GUI is enabled or Press J to toggle gravity.",
                     duration = 3,
            })
        end
    end
})
featureStates.NoRender = false
featureStates.NoRenderColor = Color3.fromRGB(0, 0, 0)

NoRenderToggle = Tabs.Utility:CreateToggle({
    Name = "No Render",
        Flag = "NoRenderToggle",
    Desc = "Disable 3D rendering for performance",
    CurrentValue = false,
    Callback = function(state)
        featureStates.NoRender = state
        game:GetService("RunService"):Set3dRenderingEnabled(not state)
        
        if state then
            local gui = Instance.new("ScreenGui")
            gui.Name = "NoRenderBackground"
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.ResetOnSpawn = false
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = featureStates.NoRenderColor
            frame.BorderSizePixel = 0
            frame.Parent = gui
            
            gui.Parent = player.PlayerGui
        else
            local gui = player.PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                gui:Destroy()
            end
        end
    end
})

NoRenderColorPicker = Tabs.Utility:CreateColorPicker({
    Name = "No Render Color",
        Flag = "NoRenderColorPicker",
    Desc = "Choose background color when No Render is enabled",
    CurrentValue = Color3.fromRGB(0, 0, 0),
    Transparency = 0,
    Callback = function(color)
        featureStates.NoRenderColor = color
        
        if featureStates.NoRender then
            local gui = player.PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                local frame = gui:FindFirstChildOfClass("Frame")
                if frame then
                    frame.BackgroundColor3 = color
                end
            end
        end
    end
})
featureStates.RemoveTextures = false

RemoveTexturesButton = Tabs.Utility:CreateButton({
    Name = "Remove Textures",
    Callback = function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
                if part:IsA("Part") then
                    part.Material = Enum.Material.SmoothPlastic
                end
                if part:FindFirstChildWhichIsA("Texture") then
                    local texture = part:FindFirstChildWhichIsA("Texture")
                    texture.Texture = "rbxassetid://0"
                end
                if part:FindFirstChildWhichIsA("Decal") then
                    local decal = part:FindFirstChildWhichIsA("Decal")
                    decal.Texture = "rbxassetid://0"
                end
            end
        end
    end
})
game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end
end)
LowQualityButton = Tabs.Utility:CreateButton({
    Name = "Low Quality",
    Desc = "Disable textures, effects, and optimize graphics",
    Callback = function()
        local ToDisable = {
            Textures = true,
            VisualEffects = true,
            Parts = true,
            Particles = true,
            Sky = true
        }

        local ToEnable = {
            FullBright = false
        }

        local Stuff = {}

        for _, v in next, game:GetDescendants() do
            if ToDisable.Parts then
                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Particles then
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                    v.Enabled = false
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.VisualEffects then
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Textures then
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Texture = ""
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Sky then
                if v:IsA("Sky") then
                    v.Parent = nil
                    table.insert(Stuff, 1, v)
                end
            end
        end

        if ToEnable.FullBright then
            local Lighting = game:GetService("Lighting")
            
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = math.huge
            Lighting.FogStart = math.huge
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 5
            Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Outlines = true
        end
    end
})

antiFlingEnabled = false
antiFlingConnection = nil

function setCanCollideOfModelDescendants(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = bval
        end
    end
end

function startAntiFling()
    if antiFlingConnection then return end
    
    antiFlingConnection = RunService.Stepped:Connect(function()
        if antiFlingEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character then
                    setCanCollideOfModelDescendants(player.Character, false)
                end
            end
        end
    end)
end

function stopAntiFling()
    if antiFlingConnection then
        antiFlingConnection:Disconnect()
        antiFlingConnection = nil
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            setCanCollideOfModelDescendants(player.Character, true)
        end
    end
end

AntiFlingToggle = Tabs.Utility:CreateToggle({
    Name = "Disable Player Collisions",
        Flag = "AntiFlingToggle",
    CurrentValue = false,
    Callback = function(state)
        antiFlingEnabled = state
        if state then
            startAntiFling()
        else
            stopAntiFling()
        end
    end
})
HitboxSettings = {
    Enabled = false,
    Size = 5,
    Color = Color3.new(1, 0, 0),
    Adornments = {}
}

function UpdateHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local chr = plr.Character
            local box = HitboxSettings.Adornments[plr]
            if chr and HitboxSettings.Enabled then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root then
                    if not box then
                        box = Instance.new("BoxHandleAdornment")
                        box.Adornee = root
                        box.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                        box.Color3 = HitboxSettings.Color
                        box.Transparency = 0.4
                        box.ZIndex = 10
                        box.Parent = root
                        HitboxSettings.Adornments[plr] = box
                    else
                        box.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                        box.Color3 = HitboxSettings.Color
                    end
                end
            elseif box then
                box:Destroy()
                HitboxSettings.Adornments[plr] = nil
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if HitboxSettings.Enabled then
        task.wait(1)
        UpdateHitboxes()
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if HitboxSettings.Adornments[plr] then
        HitboxSettings.Adornments[plr]:Destroy()
        HitboxSettings.Adornments[plr] = nil
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if HitboxSettings.Enabled then
            task.wait(0.5)
            UpdateHitboxes()
        end
    end)
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function()
            if HitboxSettings.Enabled then
                task.wait(0.5)
                UpdateHitboxes()
            end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if HitboxSettings.Enabled then
        UpdateHitboxes()
    end
end)

Tabs.Utility:Toggle(
    {
        Name = "Show Hitboxes",
        Callback = function(state)
            HitboxSettings.Enabled = state
            if state then
                UpdateHitboxes()
            else
                for _, box in pairs(HitboxSettings.Adornments) do
                    if box then
                        box:Destroy()
                    end
                end
                HitboxSettings.Adornments = {}
            end
        end
    }
)

Tabs.Utility:Slider(
    {
        Name = "Hitbox Size",
    Range = {1, 30}, CurrentValue = 5,
        Callback = function(val)
            HitboxSettings.Size = val
            UpdateHitboxes()
        end
    }
)

Tabs.Utility:ColorPicker(
    {
        Name = "Hitbox Color",
        CurrentValue = Color3.new(1, 0, 0),
        Callback = function(col)
            HitboxSettings.Color = col
            UpdateHitboxes()
        end
    }
)
if _G.a then
    local v1, v2, v3 = pairs(_G.a)
    while true do
        local v4
        v3, v4 = v1(v2, v3)
        if v3 == nil then
            break
        end
        v4:Disconnect()
    end
    _G.a = nil
end

repeat
    task.wait()
until game.Players.LocalPlayer

vu5 = game.Players.LocalPlayer
vu6 = nil
vu7 = nil
vu8 = nil
vu9 = false
vu10 = {}

function vu16()
    vu6 = vu5.Character or vu5.CharacterAdded:Wait()
    vu7 = vu6:WaitForChild("Humanoid")
    vu8 = vu6:WaitForChild("HumanoidRootPart")
    vu10 = {}
    v11 = vu6
    v12, v13, v14 = pairs(v11:GetDescendants())
    while true do
        v15 = nil
        v14, v15 = v12(v13, v14)
        if v14 == nil then
            break
        end
        if v15:IsA("BasePart") and v15.Transparency == 0 then
            vu10[#vu10 + 1] = v15
        end
    end
end

function vu30()
    invisibleGui = Instance.new("ScreenGui")
    invisibleGui.Name = "InvisibleGui"
    invisibleGui.IgnoreGuiInset = true
    invisibleGui.ResetOnSpawn = false
    invisibleGui.Enabled = false
    invisibleGui.Parent = game:GetService("CoreGui")

    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 120)
    frame.Position = UDim2.new(0.5, -30, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = invisibleGui

    corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    label = Instance.new("TextLabel")
    label.Text = "INVISIBLE"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    invisibleButton = Instance.new("TextButton")
    invisibleButton.Name = "InvisibleButton"
    invisibleButton.Text = "OFF"
    invisibleButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    invisibleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    invisibleButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    invisibleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    invisibleButton.Font = Enum.Font.Roboto
    invisibleButton.TextSize = 14
    invisibleButton.TextXAlignment = Enum.TextXAlignment.Center
    invisibleButton.TextYAlignment = Enum.TextYAlignment.Center
    invisibleButton.TextScaled = true
    invisibleButton.Parent = frame

    buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = invisibleButton

    invisibleButton.MouseButton1Click:Connect(function()
        vu9 = not vu9
        if vu9 then
            invisibleButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            invisibleButton.Text = "ON"
        else
            invisibleButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            invisibleButton.Text = "OFF"
        end
        
        v26, v27, v28 = pairs(vu10)
        while true do
            v29 = nil
            v28, v29 = v26(v27, v28)
            if v28 == nil then
                break
            end
            v29.Transparency = v29.Transparency == 0 and 0.5 or 0
        end
    end)
end

vu16()
vu30()

v31 = {
    nil,
    nil
}
v32 = vu5

v31[1] = vu5:GetMouse().KeyDown:Connect(function(p33)
    if p33 == "i" then
        vu9 = not vu9
        
        gui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
        if gui then
            button = gui:FindFirstChild("InvisibleButton", true)
            if button then
                if vu9 then
                    button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    button.Text = "ON"
                else
                    button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                    button.Text = "OFF"
                end
            end
        end
        
        v34, v35, v36 = pairs(vu10)
        while true do
            v37 = nil
            v36, v37 = v34(v35, v36)
            if v36 == nil then
                break
            end
            v37.Transparency = v37.Transparency == 0 and 0.5 or 0
        end
    end
end)

v31[2] = game:GetService("RunService").Heartbeat:Connect(function()
    if vu9 then
        v38 = vu8.CFrame
        v39 = vu7.CameraOffset
        v40 = v38 * CFrame.new(0, -200000, 0)
        v41 = vu7
        v42 = vu8
        v43 = v40:ToObjectSpace(CFrame.new(v38.Position)).Position
        v42.CFrame = v40
        v41.CameraOffset = v43
        game:GetService("RunService").RenderStepped:Wait()
        v44 = vu7
        vu8.CFrame = v38
        v44.CameraOffset = v39
    end
end)

vu5.CharacterAdded:Connect(function()
    vu9 = false
    vu16()
    
    gui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
    if gui then
        button = gui:FindFirstChild("InvisibleButton", true)
        if button then
            button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            button.Text = "OFF"
        end
    end
end)

_G.a = v31
invisibleGuiActive = false

InvisibleGuiToggle = Tabs.Utility:CreateToggle({
    Name = "Invisible GUI",
    Flag = "InvisibleGuiToggle",
    CurrentValue = false,
    Callback = function(state)
        if state then
            invisibleGuiActive = true
            
            local invisibleGui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
            if invisibleGui then
                invisibleGui.Enabled = true
            else
            end
        else
            invisibleGuiActive = false
            
            local invisibleGui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
            if invisibleGui then
                invisibleGui.Enabled = false
            end
        end
    end
})
Tabs.Utility:CreateSlider({
    Name = "Invisible GUI Scale",
    Desc = "Adjust GUI scale",
    Increment = 0.01,
    Range = {0.5, 2}, CurrentValue = 1,
    Callback = function(v)
        gui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
        if gui then
            if not gui:FindFirstChild("GuiScale") then
                local uIScale = Instance.new("UIScale")
                uIScale.Name = "GuiScale"
                uIScale.Parent = gui
            end
            gui:FindFirstChild("GuiScale").Scale = v
        end
    end
})
Tabs.Settings:CreateSection("Config Manager")
Tabs.Settings:CreateDivider()

-- Services
HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

AutoLoadConfig = "default"
AutoLoadEnabled = false
AutoSaveEnabled = false
ConfigListDropdown = nil
AutoSaveConnection = nil

function FileExists(path)
    if isfile then
        return pcall(readfile, path)
    end
    return false
end

function WriteFile(path, content)
    if writefile then
        return pcall(writefile, path, content)
    end
    return false
end

function ReadFile(path)
    if readfile then
        local success, content = pcall(readfile, path)
        if success then
            return content
        end
    end
    return ""
end

function loadAutoLoadSettings()
    local autoLoadFile = "AethelHub/AutoLoad/Game/Murder-Mystery-2(Normal-Mode)/AutoLoad.json"
    
    if FileExists(autoLoadFile) then
        local content = ReadFile(autoLoadFile)
        
        if content ~= "" then
            local success, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            
            if success and data then
                AutoLoadConfig = data.configName or "default"
                AutoLoadEnabled = data.enabled or false
                return true
            end
        end
    end
    
    AutoLoadConfig = "default"
    AutoLoadEnabled = false
    return false
end

function saveAutoLoadSettings()
    local autoLoadFile = "AethelHub/AutoLoad/Game/Murder-Mystery-2(Normal-Mode)/AutoLoad.json"
    
    local success = WriteFile(autoLoadFile, "")
    if not success then
        if makefolder then
            pcall(function() makefolder("AethelHub") end)
            pcall(function() makefolder("AethelHub/AutoLoad") end)
            pcall(function() makefolder("AethelHub/AutoLoad/Game") end)
            pcall(function() makefolder("AethelHub/AutoLoad/Game/Murder-Mystery-2(Normal-Mode)") end)
        end
    end
    
    local data = {
        enabled = AutoLoadEnabled,
        configName = AutoLoadConfig
    }
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        WriteFile(autoLoadFile, json)
    end
end

loadAutoLoadSettings()

ConfigNameInput = Tabs.Settings:CreateInput({
    Name = "Config Name",
        Flag = "ConfigNameInput",
    Flag = "ConfigNameInput",
    Desc = "Name for your config file",
    Icon = "file-cog",
    Placeholder = "default",
    CurrentValue = CurrentConfigName,
    Callback = function(value)
        if value ~= "" then
            CurrentConfigName = value
        end
    end
})

Tabs.Settings:CreateDivider()

AutoLoadToggle = Tabs.Settings:CreateToggle({
    Name = "Auto Load",
        Flag = "AutoLoadToggle",
    Flag = "AutoLoadToggle",
    Desc = "Automatically load this config when script starts",
    CurrentValue = AutoLoadEnabled,
    Callback = function(state)
        AutoLoadEnabled = state
        if state then
            AutoLoadConfig = CurrentConfigName
            Notify({
                title = "Auto-Load",
                content = "Config '" .. CurrentConfigName .. "' will load automatically on startup",
                     duration = 3,
            })
        end
        saveAutoLoadSettings()
    end
})

AutoSaveToggle = Tabs.Settings:CreateToggle({
    Name = "Auto Save",
        Flag = "AutoSaveToggle",
    Flag = "AutoSaveToggle",
    Desc = "Automatically save changes to config every second",
    CurrentValue = AutoSaveEnabled,
    Callback = function(state)
        AutoSaveEnabled = state
        
        -- Stop existing auto-save loop if it exists
        if AutoSaveConnection then
            AutoSaveConnection:Disconnect()
            AutoSaveConnection = nil
        end
        
        if state then
            Notify({
                title = "Auto-Save",
                content = "Config will save automatically every second",
                     duration = 2,
            })
            
            -- Start auto-save loop
            AutoSaveConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if AutoSaveEnabled and CurrentConfigName ~= "" then
                    task.spawn(function()
                                                Window:SaveConfig(CurrentConfigName)
                    end)
                end
                task.wait(1) -- Save every second
            end)
        else
            Notify({
                title = "Auto-Save",
                content = "Auto-save disabled",
                     duration = 2,
            })
        end
    end
})

Tabs.Settings:CreateDivider()

function refreshConfigList()
    local allConfigs = Window:ListConfigs() or {}
    
    -- Ensure "default" config exists
    if not table.find(allConfigs, "default") then
        -- Create default config if it doesn't exist
        Window:SaveConfig("default")
        table.insert(allConfigs, 1, "default")
    end
    
    table.sort(allConfigs, function(a, b)
        return a:lower() < b:lower()
    end)
    
    local defaultValue = table.find(allConfigs, CurrentConfigName) and CurrentConfigName or "default"
    
    if ConfigListDropdown and ConfigListDropdown.Refresh then
        ConfigListDropdown:Refresh(allConfigs, false)
    end
end

ConfigListDropdown = Tabs.Settings:CreateDropdown({
    Name = "Existing Configs",
        Flag = "ConfigListDropdown",
    
    Desc = "Select from saved configs",
    Options = {"default"},
    CurrentValue = "default",
    Callback = function(value)
        CurrentConfigName = value
        ConfigNameInput:Set(value)
        
        if AutoLoadEnabled then
            AutoLoadConfig = value
            saveAutoLoadSettings()
        end
        
        Notify({
            title = "Config Selected",
            content = "Config '" .. value .. "' selected",
                     duration = 2,
        })
    end
})

Tabs.Settings:CreateDivider()

SaveConfigButton = Tabs.Settings:CreateButton({
    Name = "Save Config",
    Desc = "Save current settings to config",
    Icon = "save",
    Callback = function()
        if CurrentConfigName == "" then
            Notify({
                title = "Error",
                content = "Please enter a config name",
                     duration = 3,
            })
            return
        end
        
                local success, _ = pcall(function() Window:SaveConfig(CurrentConfigName) end)
        if success then
            Notify({
                title = "Config Saved",
                content = "Config '" .. CurrentConfigName .. "' saved successfully",
                     duration = 3,
            })
            
            if AutoLoadEnabled then
                AutoLoadConfig = CurrentConfigName
                saveAutoLoadSettings()
            end
            
            task.wait(0.5)
            refreshConfigList()
        else
            Notify({
                title = "Error",
                content = "Failed to save config",
                     duration = 3,
            })
        end
    end
})

Tabs.Settings:CreateDivider()

LoadConfigButton = Tabs.Settings:CreateButton({
    Name = "Load Config",
    Desc = "Load settings from selected config",
    Icon = "folder-open",
    Callback = function()
        if CurrentConfigName == "" then
            Notify({
                title = "Error",
                content = "Please enter a config name",
                     duration = 3,
            })
            return
        end
        
        local success, _ = pcall(function() Window:LoadConfig(CurrentConfigName) end)
        if success then
            Notify({
                title = "Config Loaded",
                content = "Config '" .. CurrentConfigName .. "' loaded successfully",
                     duration = 3,
            })
            
            if AutoLoadEnabled then
                AutoLoadConfig = CurrentConfigName
                saveAutoLoadSettings()
            end
        else
            Notify({
                title = "Error",
                content = "Config '" .. CurrentConfigName .. "' not found or empty",
                     duration = 3,
            })
        end
    end
})

Tabs.Settings:CreateDivider()

DeleteConfigButton = Tabs.Settings:CreateButton({
    Name = "Delete Config",
    Desc = "Delete selected config",
    Icon = "trash-2",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        if CurrentConfigName == "default" then
            Notify({
                title = "Error",
                content = "Cannot delete default config",
                     duration = 3,
            })
            return
        end
        
        local success = Window:DeleteConfig(CurrentConfigName)
        if success then
            Notify({
                title = "Config Deleted",
                content = "Config '" .. CurrentConfigName .. "' deleted",
                     duration = 3,
            })
            
            CurrentConfigName = "default"
            ConfigNameInput:Set("default")
            
            if AutoLoadEnabled then
                AutoLoadConfig = "default"
                saveAutoLoadSettings()
            end
            
            task.wait(0.5)
            refreshConfigList()
        else
            Notify({
                title = "Error",
                content = "Failed to delete config or config doesn't exist",
                     duration = 3,
            })
        end
    end
})

Tabs.Settings:CreateDivider()

RefreshConfigButton = Tabs.Settings:CreateButton({
    Name = "Refresh Config List",
    Desc = "Update the list of available configs",
    Icon = "refresh-cw",
    Callback = function()
        refreshConfigList()
        Notify({
            title = "Config List Refreshed",
            content = "Config list updated",
                     duration = 2,
        })
    end
})

task.spawn(function()
    task.wait(0.5) 
    refreshConfigList()
    
    -- Automatically set "default" config in the input box
    ConfigNameInput:Set("default")
    
    if AutoLoadEnabled then
        CurrentConfigName = AutoLoadConfig
        ConfigNameInput:Set(CurrentConfigName)
        
        task.wait(1)
                local ok, _ = pcall(function() Window:LoadConfig(CurrentConfigName) end)
                if ok then
            Notify({
                title = "Auto-Loaded",
                content = "Config '" .. CurrentConfigName .. "' loaded automatically",
                     duration = 3,
            })
        end
    end
end)

-- Start auto-save loop if enabled on startup
if AutoSaveEnabled then
    task.spawn(function()
        task.wait(1)
        
        if AutoSaveEnabled then
            -- Start auto-save loop
            AutoSaveConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if AutoSaveEnabled and CurrentConfigName ~= "" then
                    task.spawn(function()
                                                Window:SaveConfig(CurrentConfigName)
                    end)
                end
                task.wait(1) -- Save every second
            end)
        end
    end)
end
Tabs.Settings:CreateSection("Keybinds")
        Tabs.Settings:CreateKeybind({
        Flag = "Keybind",
        Name = "Keybind",
        Desc = "Keybind to open ui",
        CurrentValue = "RightControl",
        Callback = function(RightControl)
            -- Keybind set in Airflow:CreateWindow
        end
    })
    Tabs.Settings:CreateKeybind({
    Name = "Invisible Toggle",
    Desc = "Keybind to toggle invisible mode",
    CurrentValue = "I",
    Callback = function(v)
        vu9 = not vu9
        
        gui = game:GetService("CoreGui"):FindFirstChild("InvisibleGui")
        if gui then
            button = gui:FindFirstChild("InvisibleButton", true)
            if button then
                if vu9 then
                    button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    button.Text = "ON"
                else
                    button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                    button.Text = "OFF"
                end
            end
        end
        
        v34, v35, v36 = pairs(vu10)
        while true do
            v37 = nil
            v36, v37 = v34(v35, v36)
            if v36 == nil then
                break
            end
            v37.Transparency = v37.Transparency == 0 and 0.5 or 0
        end
    end
})
    do
     InviteCode = "kA3V23ry7K"
     DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

     success = pcall(function()
        Response = game:GetService("HttpService"):JSONDecode(request({
            Url = DiscordAPI,
            Method = "GET"
        }).Body)
        return Response
    end)
    
    Tabs.Info:CreateSection("Discord")
    Tabs.Info:CreateButton({
        Name = "Copy Discord Link",
        Desc = "Copies https://discord.gg/kA3V23ry7K to clipboard",
        Callback = function()
            pcall(function() setclipboard("https://discord.gg/kA3V23ry7K") end)
            Notify({title = "Discord", content = "Link copied to clipboard!", duration = 3})
        end
    })

    if success and Response and Response.guild then
        Tabs.Info:CreateSection("Join My Discord Server")
         DiscordServerParagraph = Tabs.Info:CreateParagraph({
            Title = tostring(Response.guild.name),
        Flag = "DiscordServerParagraph",
            Content = tostring(Response.guild.description),
            -- Thumbnail = "https://cdn.discordapp.com/banners/1300692552005189632/35981388401406a4b7dffd6f447a64c4.png?size=512"
        })
    end
end
    end)
    if not mmOk then
        pcall(function() _print("[Aethel Hub] Murder Mystery 2 failed to load:", mmErr) end)
    end
else
    -- Unsupported place: copy its PlaceId so it can be added to a whitelist above.
    local info = "PlaceId: " .. tostring(game.PlaceId) .. " | UniverseId: " .. tostring(game.GameId)
    pcall(function() setclipboard(info) end)
    pcall(function() _print("[Aethel Hub] Unsupported place. Copied to clipboard:", info) end)
end
