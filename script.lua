-- НАСТРОЙКИ МЕХАНИКИ ТАЙМЕРА (Спешка)
local BASE_TIMER = 40           -- Обычное время на комнату
local BOSS_TIMER = 400          -- Время для 50 и 100 комнат (Фигура)
local DETECTION_RADIUS = 35     -- Радиус подсветки двери
local WALK_SPEED = 18.5         -- Безопасная скорость (без телепортов назад)

-- НАСТРОЙКИ МОНСТРА №1 И №2 (A-90 и Спешка)
local A90_INTERVAL = 400        -- Интервал появления A-90 (каждые 400 секунд)
local REACTION_TIME = 0.5       -- Время на полную остановку игрока

-- НАСТРОЙКИ МОНСТРА №3 (Монстр взгляда: Вверх/Вниз)
local MONSTER_INTERVAL = 200    -- Интервал нападения (каждые 200 секунд)
local LOOK_TIME_LIMIT = 5       -- Время на выполнение задания (5 секунд)
local ANGLE_THRESHOLD = 0.85    -- Строгость взгляда (почти до упора)

-- НАСТРОЙКИ МОНСТРА №4 (Глитч)
local GLITCH_INTERVAL = 130     -- Интервал нападения (каждые 130 секунд)
local GLITCH_TIME_LIMIT = 4     -- Время на выполнение (4 секунды)

-- НАСТРОЙКИ МОНСТРА №5 (Тимоти - Паук-Паразит)
local TIMOTHY_INTERVAL = 90     -- Интервал нападения (каждые 90 секунд)
local TIMOTHY_TIME_LIMIT = 3    -- Время удержания мыши (3 секунды)

-- НАСТРОЙКИ МОНСТРА №6 (Хайд - Прятки)
local HIDE_INTERVAL = 270       -- Интервал нападения (каждые 270 секунд)
local HIDE_TIME_LIMIT = 4       -- Время непрерывного бега (4 секунды)

-- Сервисы Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Функция полной очистки скрипта
local function cleanup()
    local oldGui = player.PlayerGui:FindFirstChild("DoorsXenoTimer")
    if oldGui then oldGui:Destroy() end
    local oldCc = Lighting:FindFirstChild("XenoColorCorrection")
    if oldCc then oldCc:Destroy() end
end

cleanup()
-- СОЗДАНИЕ ИНТЕРФЕЙСА ТАЙМЕРА
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsXenoTimer"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 1. Таймер комнат (Сверху, Красный)
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 200, 0, 50)
timerLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextSize = 46
timerLabel.Font = Enum.Font.SpecialElite
timerLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
timerLabel.TextStrokeTransparency = 0.2
timerLabel.Text = tostring(BASE_TIMER)
timerLabel.Parent = screenGui

-- 2. Синий таймер А-90 (Внизу справа)
local a90TimerLabel = Instance.new("TextLabel")
a90TimerLabel.Size = UDim2.new(0, 200, 0, 50)
a90TimerLabel.Position = UDim2.new(1, -220, 1, -70)
a90TimerLabel.BackgroundTransparency = 1
a90TimerLabel.TextSize = 36
a90TimerLabel.Font = Enum.Font.SpecialElite
a90TimerLabel.TextColor3 = Color3.fromRGB(0, 120, 255)
a90TimerLabel.TextStrokeTransparency = 0.3
a90TimerLabel.Text = "A-90: " .. tostring(A90_INTERVAL)
a90TimerLabel.Parent = screenGui

-- Текст Спешки (NO TIME LEFT)
local noTimeLabel = Instance.new("TextLabel")
noTimeLabel.Size = UDim2.new(0, 400, 0, 50)
noTimeLabel.Position = UDim2.new(0.5, -200, 0.15, 0)
noTimeLabel.BackgroundTransparency = 1
noTimeLabel.TextSize = 54
noTimeLabel.Font = Enum.Font.GothamBold
noTimeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
noTimeLabel.Text = "NO TIME LEFT"
noTimeLabel.TextStrokeTransparency = 0.1
noTimeLabel.Visible = false
noTimeLabel.Parent = screenGui

-- Знак STOP от А-90
local stopLabel = Instance.new("TextLabel")
stopLabel.Size = UDim2.new(0, 600, 0, 150)
stopLabel.Position = UDim2.new(0.5, -300, 0.35, 0)
stopLabel.BackgroundTransparency = 1
stopLabel.TextSize = 130
stopLabel.Font = Enum.Font.GothamBold
stopLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
stopLabel.Text = "STOP"
stopLabel.Visible = false
stopLabel.Parent = screenGui

-- Окно Монстра взгляда, Глитча, Тимоти и Хайда (Единое защищенное окно уведомлений)
local challengeLabel = Instance.new("TextLabel")
challengeLabel.Size = UDim2.new(0, 700, 0, 100)
challengeLabel.Position = UDim2.new(0.5, -350, 0.25, 0)
challengeLabel.BackgroundTransparency = 1
challengeLabel.TextSize = 55
challengeLabel.Font = Enum.Font.SpecialElite
challengeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
challengeLabel.TextStrokeTransparency = 0.1
challengeLabel.Visible = false
challengeLabel.Parent = screenGui
-- РЕГИСТРАЦИЯ АУДИО
local scarySound = Instance.new("Sound")
scarySound.SoundId = "rbxassetid://9043360237" -- Ваш трек на 10 сек
scarySound.Volume = 0; scarySound.Looped = true; scarySound.Parent = screenGui

local finalKillSound = Instance.new("Sound")
finalKillSound.SoundId = "rbxassetid://5351101493"; finalKillSound.Volume = 3; finalKillSound.Parent = screenGui

local alertSound = Instance.new("Sound")
alertSound.SoundId = "rbxassetid://6834168433"; alertSound.Volume = 2; alertSound.Parent = screenGui

local lookSound = Instance.new("Sound")
lookSound.SoundId = "rbxassetid://9114223147"; lookSound.Volume = 2.5; lookSound.Parent = screenGui

local glitchSound = Instance.new("Sound")
glitchSound.SoundId = "rbxassetid://9069171032"; glitchSound.Volume = 3; glitchSound.Parent = screenGui

local timothySound = Instance.new("Sound")
timothySound.SoundId = "rbxassetid://9069609268"; timothySound.Volume = 2.5; timothySound.Parent = screenGui

local hideSound = Instance.new("Sound")
hideSound.SoundId = "rbxassetid://9071067271"; hideSound.Volume = 3; hideSound.Parent = screenGui

local successSound = Instance.new("Sound")
successSound.SoundId = "rbxassetid://4400874312"; successSound.Volume = 1.5; successSound.Parent = screenGui

-- ЦВЕТОКОРРЕКЦИЯ И ESP ДВЕРЕЙ
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "XenoColorCorrection"; colorCorrection.Parent = Lighting

local doorHighlight = Instance.new("Highlight")
doorHighlight.FillColor = Color3.fromRGB(255, 0, 0); doorHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
doorHighlight.FillTransparency = 0.3; doorHighlight.OutlineTransparency = 0.1

-- Флаги состояний
local currentRoomNum = 0
local timeLeft = BASE_TIMER
local a90TimeLeft = A90_INTERVAL
local soundPlaying = false
local activeChallenge = "None" -- Хранит имя текущего монстра для избежания наложений

player.CharacterAdded:Connect(function() cleanup() end)
local function getNextDoorsDoor()
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return nil end
    local targetRoom = nil
    local maxNum = -1
    for _, room in pairs(currentRooms:GetChildren()) do
        local num = tonumber(room.Name)
        if num and num > maxNum then maxNum = num; targetRoom = room end
    end
    if targetRoom then
        local doorModel = targetRoom:FindFirstChild("Door")
        if doorModel then
            return doorModel:FindFirstChild("Door") or doorModel:FindFirstChild("PrimaryPart") or doorModel:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    return nil
end

-- Мгновенный черный экран смерти без анимаций и черепов
local function timeOverDeath()
    scarySound:Stop(); alertSound:Stop(); lookSound:Stop(); glitchSound:Stop(); timothySound:Stop(); hideSound:Stop()
    finalKillSound:Play() 
    
    colorCorrection.Brightness = -1
    noTimeLabel.Visible = false; stopLabel.Visible = false; challengeLabel.Visible = false
    activeChallenge = "Dead"
    
    local deathFrame = Instance.new("Frame")
    deathFrame.Size = UDim2.new(1, 0, 1, 0); deathFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    deathFrame.ZIndex = 999; deathFrame.Parent = screenGui
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
    
    task.wait(1.5)
    cleanup()
end
-- ЛОГИКА АТАКИ СУЩНОСТИ А-90
local function spawnA90Event()
    activeChallenge = "A90"
    stopLabel.Visible = true
    task.wait(REACTION_TIME)
    
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or activeChallenge ~= "A90" then return end
    
    local startPosition = root.Position
    local duration = 4.0; local elapsed = 0
    
    while elapsed < duration and activeChallenge == "A90" do
        task.wait(0.05); elapsed = elapsed + 0.05
        stopLabel.Position = UDim2.new(0.5, math.random(-6, 6) - 300, 0.35, math.random(-6, 6))
        if root and (root.Position - startPosition).Magnitude > 0.4 then
            timeOverDeath(); return
        end
    end
    
    if activeChallenge == "A90" then
        activeChallenge = "None"; stopLabel.Visible = false; timeLeft = timeLeft + 5 
        local oldColor = timerLabel.TextColor3; timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.5); timerLabel.TextColor3 = oldColor
    end
end

-- Функция сброса верхнего красного таймера комнат
local function resetTimer(roomNum)
    if roomNum == 50 or roomNum == 100 then
        timeLeft = BOSS_TIMER; timerLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
    else
        timeLeft = BASE_TIMER; timerLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
    end
    noTimeLabel.Visible = false
    if soundPlaying then scarySound:Stop() soundPlaying = false end
end

-- Синглплеерный триггер загрузки новых комнат
local currentRoomsFolder = Workspace:WaitForChild("CurrentRooms")
currentRoomsFolder.ChildAdded:Connect(function(room)
    local roomNum = tonumber(room.Name)
    if roomNum and roomNum > currentRoomNum then
        currentRoomNum = roomNum; resetTimer(roomNum)
    end
end)
-- МИНИ-ИГРЫ МОНСТРОВ ВЗГЛЯДА, ГЛИТЧА, ТИМОТИ И ХАЙДА
local function runMonstersChallenges(monsterName)
    if not challengeLabel or not challengeLabel.Parent or activeChallenge ~= "None" then return end
    activeChallenge = monsterName
    challengeLabel.Visible = true
    
    local camera = Workspace.CurrentCamera
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    local success = false
    local elapsed = 0
    
    if monsterName == "Look" then
        local dirs = {"ВВЕРХ", "ВНИЗ"}; local chosen = dirs[math.random(1, #dirs)]
        challengeLabel.Text = "ПОСМОТРИ " .. chosen .. "!"; challengeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        challengeLabel.TextStrokeColor3 = Color3.fromRGB(150, 0, 0); lookSound:Play()
        
        while elapsed < LOOK_TIME_LIMIT and activeChallenge == "Look" do
            task.wait(0.05); elapsed = elapsed + 0.05
            local lookY = camera.CFrame.LookVector.Y
            if (chosen == "ВВЕРХ" and lookY >= ANGLE_THRESHOLD) or (chosen == "ВНИЗ" and lookY <= -ANGLE_THRESHOLD) then
                success = true; break
            end
            challengeLabel.Position = UDim2.new(0.5, math.random(-4, 4) - 350, 0.25, math.random(-4, 4))
        end
        
    elseif monsterName == "Glitch" then
        local acts = {"ВСТАНЬ НА КОРТОЧКИ!", "ОТКРОЙ ЧАТ ( НАЖМИ / )"}; local chosen = acts[math.random(1, #acts)]
        challengeLabel.Text = chosen; challengeLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        challengeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 150); glitchSound:Play()
        
        while elapsed < GLITCH_TIME_LIMIT and activeChallenge == "Glitch" do
            task.wait(0.05); elapsed = elapsed + 0.05
            colorCorrection.Contrast = math.random(-2, 2); colorCorrection.Saturation = math.random(-2, 2)
            challengeLabel.Position = UDim2.new(0.5, math.random(-12, 12) - 350, 0.25, math.random(-12, 12))
            
            if chosen == "ВСТАНЬ НА КОРТОЧКИ!" and humanoid and humanoid.WalkSpeed < 10 and humanoid.MoveDirection.Magnitude > 0 then
                success = true; break
            elseif chosen == "ОТКРОЙ ЧАТ ( НАЖМИ / )" and UserInputService:GetFocusedTextBox() then
                success = true; break
            end
        end
        colorCorrection.Contrast = 0; colorCorrection.Saturation = 0
        
    elseif monsterName == "Timothy" then
        challengeLabel.Text = "НЕ ДВИГАЙ КАМЕРУ!"; challengeLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
        challengeLabel.TextStrokeColor3 = Color3.fromRGB(50, 50, 50); timothySound:Play()
        local startLook = camera.CFrame.LookVector
        success = true
        
        while elapsed < TIMOTHY_TIME_LIMIT and activeChallenge == "Timothy" do
            task.wait(0.05); elapsed = elapsed + 0.05
            camera.FieldOfView = 70 + math.random(-5, 5) -- Тряска камеры
            challengeLabel.Position = UDim2.new(0.5, math.random(-5, 5) - 350, 0.25, math.random(-5, 5))
            if (camera.CFrame.LookVector - startLook).Magnitude > 0.05 then
                success = false; break
            end
        end
        camera.FieldOfView = 70
        
    elseif monsterName == "Hide" then
        challengeLabel.Text = "БЕГИ БЕЗ ОСТАНОВКИ!"; challengeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        challengeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); hideSound:Play()
        success = true
        
        while elapsed < HIDE_TIME_LIMIT and activeChallenge == "Hide" do
            task.wait(0.05); elapsed = elapsed + 0.05
            colorCorrection.TintColor = Color3.fromRGB(255, 150, 150) -- Экран краснеет
            challengeLabel.Position = UDim2.new(0.5, math.random(-6, 6) - 350, 0.25, math.random(-6, 6))
            if humanoid and humanoid.MoveDirection.Magnitude == 0 then
                success = false; break
            end
        end
        colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
    end
    
    challengeLabel.Visible = false
    if activeChallenge == monsterName then
        activeChallenge = "None"
        if success then successSound:Play(); timeLeft = timeLeft + 5 else timeOverDeath() end
    end
end

-- Независимые потоковые циклы спавна монстров №3, №4, №5, №6
task.spawn(function()
    task.wait(15)
    while true do task.wait(MONSTER_INTERVAL) if activeChallenge == "None" then task.spawn(runMonstersChallenges, "Look") end end
end)
task.spawn(function()
    task.wait(30)
    while true do task.wait(GLITCH_INTERVAL) if activeChallenge == "None" then task.spawn(runMonstersChallenges, "Glitch") end end
end)
task.spawn(function()
    task.wait(20)
    while true do task.wait(TIMOTHY_INTERVAL) if activeChallenge == "None" then task.spawn(runMonstersChallenges, "Timothy") end end
end)
task.spawn(function()
    task.wait(45)
    while true do task.wait(HIDE_INTERVAL) if activeChallenge == "None" then task.spawn(runMonstersChallenges, "Hide") end end
end)

-- Синий таймер А-90
task.spawn(function()
    task.wait(5)
    while true do
        task.wait(1)
        if activeChallenge == "A90" or activeChallenge == "Dead" then continue end
        a90TimeLeft = a90TimeLeft - 1; a90TimerLabel.Text = "A-90: " .. tostring(a90TimeLeft)
        if a90TimeLeft == 3 then alertSound:Play() end
        if a90TimeLeft <= 0 then a90TimeLeft = A90_INTERVAL; task.spawn(spawnA90Event) end
    end
end)

-- Главный цикл (SpeedHack, ESP двери, Верхний красный таймер комнат)
task.spawn(function()
    while timeLeft > 0 do
        task.wait(0.05)
        local character = player.Character; local humanoid = character and character:FindFirstChild("Humanoid"); local root = character and character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and humanoid.Health <= 0 then cleanup() break end
        if humanoid and humanoid.WalkSpeed ~= WALK_SPEED and activeChallenge ~= "Glitch" then humanoid.WalkSpeed = WALK_SPEED end
        
        if root then
            local targetPart = getNextDoorsDoor()
            if targetPart and (root.Position - targetPart.Position).Magnitude <= DETECTION_RADIUS then
                doorHighlight.Adornee = targetPart; doorHighlight.Parent = targetPart
            else doorHighlight.Parent = nil end
        end
        
        if activeChallenge ~= "None" then continue end
        
        if timeLeft <= 10 then
            if not soundPlaying then scarySound:Play() soundPlaying = true end
            local intensity = (10 - timeLeft) / 10
            if timeLeft <= 5 then
                noTimeLabel.Visible = true; noTimeLabel.Position = UDim2.new(0.5, math.random(-5, 5) - 200, 0.15, math.random(-5, 5))
            else noTimeLabel.Visible = false end
            colorCorrection.Brightness = -intensity * 0.9; colorCorrection.Contrast = intensity * 0.7; colorCorrection.Saturation = -intensity * 0.8
            scarySound.Volume = math.clamp(intensity * 3, 0.3, 3) 
            timerLabel.Position = UDim2.new(0.5, math.random(-3, 3) - 100, 0.05, math.random(-3, 3))
        else
            if soundPlaying then scarySound:Stop() soundPlaying = false end
            noTimeLabel.Visible = false; colorCorrection.Brightness = 0; colorCorrection.Contrast = 0; colorCorrection.Saturation = 0; scarySound.Volume = 0; timerLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
        end
        timerLabel.Text = string.format("%d", math.ceil(timeLeft)); timeLeft = timeLeft - 0.05
    end
    if timeLeft <= 0 and activeChallenge ~= "Dead" then timeOverDeath() end
end)
