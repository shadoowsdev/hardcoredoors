-- НАСТРОЙКИ МЕХАНИКИ ТАЙМЕРА
local BASE_TIMER = 40           -- Обычное время на комнату
local BOSS_TIMER = 400          -- Время для 50 и 100 комнат (Фигура)
local DETECTION_RADIUS = 45     -- Радиус подсветки дверей

-- ФИКСИРОВАННАЯ БЕЗОПАСНАЯ СКОРОСТЬ
local SAFE_WALK_SPEED = 20

-- НАСТРОЙКИ ДЛЯ А-90
local A90_INTERVAL = 400        -- Интервал появления A-90 (каждые 400 секунд)
local REACTION_TIME = 0.5       -- Время на полную остановку игрока

-- Сервисы Roblox
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Глобальные переменные логики
local currentRoomNum = 0
local timeLeft = BASE_TIMER
local a90TimeLeft = A90_INTERVAL
local soundPlaying = false
local isStopActive = false  

-- Кэш для оптимизации дверей
local doorCache = {}

-- Функция полной очистки скрипта
local function cleanup()
    local oldGui = player.PlayerGui:FindFirstChild("DoorsXenoTimer")
    if oldGui then oldGui:Destroy() end
    local oldCc = Lighting:FindFirstChild("XenoColorCorrection")
    if oldCc then oldCc:Destroy() end
    
    -- Очистка кэшированных ESP подсветок при перезапуске
    for obj, highlight in pairs(doorCache) do
        if highlight and highlight.Parent then highlight:Destroy() end
    end
    doorCache = {}
end

cleanup()
-- СОЗДАНИЕ ИНТЕРФЕЙСА ТАЙМЕРА
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsXenoTimer"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 1. Стандартный красный таймер комнат (Сверху)
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

-- Текстовые уведомления паники (Череп 💀)
local noTimeLabel = Instance.new("TextLabel")
noTimeLabel.Size = UDim2.new(0, 600, 0, 200)
noTimeLabel.Position = UDim2.new(0.5, -300, 0.4, -100)
noTimeLabel.BackgroundTransparency = 1
noTimeLabel.Font = Enum.Font.GothamBold
noTimeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
noTimeLabel.Text = ""
noTimeLabel.Visible = false
noTimeLabel.Parent = screenGui

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
-- РЕГИСТРАЦИЯ АУДИО
local scarySound = Instance.new("Sound")
scarySound.SoundId = "rbxassetid://9043360237"; scarySound.Volume = 0; scarySound.Looped = true; scarySound.Parent = screenGui

local finalKillSound = Instance.new("Sound")
finalKillSound.SoundId = "rbxassetid://5351101493"; finalKillSound.Volume = 3; finalKillSound.Parent = screenGui

local alertSound = Instance.new("Sound")
alertSound.SoundId = "rbxassetid://6834168433"; alertSound.Volume = 2; alertSound.Parent = screenGui

local successSound = Instance.new("Sound")
successSound.SoundId = "rbxassetid://4400874312"; successSound.Volume = 1.5; successSound.Parent = screenGui

-- КОРРЕКЦИЯ ЦВЕТА
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "XenoColorCorrection"; colorCorrection.Parent = Lighting

-- СТАБИЛЬНЫЙ МИКРО-СПИДХАК (БЕЗ ТЕЛЕПОРТАЦИЙ НАЗАД)
RunService.Heartbeat:Connect(function()
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    
    if isStopActive or not char or not hum then 
        if hum then hum.WalkSpeed = 16 end
        return 
    end
    
    if hum.MoveDirection.Magnitude > 0 then
        hum.WalkSpeed = SAFE_WALK_SPEED
    else
        hum.WalkSpeed = 16
    end
end)
-- ВЫСОКООПТИМИЗИРОВАННАЯ СИСТЕМА ПОИСКА ДВЕРЕЙ И ПРОВЕРКИ ИСПРАВНОСТИ ESP
local function updateOptimizedDoorESP()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not root or not currentRooms then return end

    -- ОПТИМИЗАЦИЯ: Сканируем только текущие загруженные комнаты, а не весь Workspace
    for _, room in pairs(currentRooms:GetChildren()) do
        for _, obj in pairs(room:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and string.find(obj.Name, "Door") then
                local primaryPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)) or obj
                
                if primaryPart then
                    local distance = (root.Position - primaryPart.Position).Magnitude
                    
                    -- Если дверь рядом — вешаем или проверяем ESP
                    if distance <= DETECTION_RADIUS then
                        if not doorCache[obj] or not obj:FindFirstChild("XenoDoorHighlight") then
                            -- Старый битый Highlight удаляем
                            local oldHighlight = obj:FindFirstChild("XenoDoorHighlight")
                            if oldHighlight then oldHighlight:Destroy() end
                            
                            -- Создаем проверенный новый зеленый маркер
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "XenoDoorHighlight"
                            highlight.FillColor = Color3.fromRGB(0, 255, 0) -- СОЧНЫЙ ЗЕЛЕНЫЙ ЦВЕТ
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.FillTransparency = 0.25
                            highlight.OutlineTransparency = 0.1
                            highlight.Adornee = obj
                            highlight.Parent = obj
                            
                            doorCache[obj] = highlight -- Записываем в кэш оптимизации
                        end
                    else
                        -- Очистка кэша, если игрок ушел далеко
                        if doorCache[obj] then
                            if obj:FindFirstChild("XenoDoorHighlight") then obj.XenoDoorHighlight:Destroy() end
                            doorCache[obj] = nil
                        end
                    end
                end
            end
        end
    end

    -- ПРОВЕРКА ВАЛИДНОСТИ КЭША: чистим мусор и удаленные игрой двери
    for cachedObj, highlight in pairs(doorCache) do
        if not cachedObj or not cachedObj.Parent or not cachedObj:FindFirstChild("XenoDoorHighlight") then
            if highlight and highlight.Parent then highlight:Destroy() end
            doorCache[cachedObj] = nil
        end
    end
end

-- Моментальный глухой черный экран смерти при проигрыше
local function timeOverDeath()
    scarySound:Stop(); alertSound:Stop(); finalKillSound:Play() 
    colorCorrection.Brightness = -1
    noTimeLabel.Visible = false; stopLabel.Visible = false
    isStopActive = false
    
    local deathFrame = Instance.new("Frame")
    deathFrame.Size = UDim2.new(1, 0, 1, 0); deathFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    deathFrame.ZIndex = 999; deathFrame.Parent = screenGui
    
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
    
    task.wait(1.5)
    cleanup()
end

player.CharacterAdded:Connect(function() cleanup() end)
local function spawnA90Event()
    isStopActive = true
    stopLabel.Visible = true
    task.wait(REACTION_TIME)
    
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChild("Humanoid")
    if not root or not isStopActive then return end
    
    local startPosition = root.Position
    local duration = 4.0; local elapsed = 0
    
    if hum then hum.WalkSpeed = 0 end 
    
    while elapsed < duration and isStopActive do
        task.wait(0.05); elapsed = elapsed + 0.05
        stopLabel.Position = UDim2.new(0.5, math.random(-6, 6) - 300, 0.35, math.random(-6, 6))
        if root and (root.Position - startPosition).Magnitude > 0.4 then
            timeOverDeath(); return
        end
    end
    
    if isStopActive then
        isStopActive = false; stopLabel.Visible = false; timeLeft = timeLeft + 5 
        local oldColor = timerLabel.TextColor3; timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.5); timerLabel.TextColor3 = oldColor
    end
end

local function resetTimer(roomNum)
    if roomNum == 50 or roomNum == 100 then
        timeLeft = BOSS_TIMER; timerLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
    else
        timeLeft = BASE_TIMER; timerLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
    end
    noTimeLabel.Visible = false
    if soundPlaying then scarySound:Stop() soundPlaying = false end
end

local currentRoomsFolder = Workspace:WaitForChild("CurrentRooms")
currentRoomsFolder.ChildAdded:Connect(function(room)
    local roomNum = tonumber(room.Name)
    if roomNum and roomNum > currentRoomNum then
        currentRoomNum = roomNum; resetTimer(roomNum)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local currentRooms = Workspace:FindFirstChild("CurrentRooms")
        if currentRooms then
            for _, room in pairs(currentRooms:GetChildren()) do
                local roomNum = tonumber(room.Name)
                if roomNum and roomNum >= currentRoomNum then
                    local doorModel = room:FindFirstChild("Door")
                    if doorModel and (doorModel:FindFirstChild("ClientOpen") or not doorModel:FindFirstChild("Lock")) then
                        if roomNum > currentRoomNum then
                            currentRoomNum = roomNum; resetTimer(roomNum)
                        end
                    end
                end
            end
        end
    end
end)
-- Независимый поток синего таймера А-90 (Каждые 400 сек)
task.spawn(function()
    task.wait(5)
    while true do
        task.wait(1)
        if isStopActive then continue end
        a90TimeLeft = a90TimeLeft - 1; a90TimerLabel.Text = "A-90: " .. tostring(a90TimeLeft)
        if a90TimeLeft == 3 then alertSound:Play() end
        if a90TimeLeft <= 0 then a90TimeLeft = A90_INTERVAL; task.spawn(spawnA90Event) end
    end
end)

-- Автономный легкий поток для периодического обновления и проверки зеленого ESP дверей
task.spawn(function()
    while true do
        task.wait(0.8) -- Частота проверок кэша (0.8 секунды идеальны для высокого FPS)
        if not isStopActive and timeLeft > 0 then
            updateGlobalDoorESP()
        end
    end
end)

-- Главный цикл отсчета комнат и динамического масштабирования черепа 💀
task.spawn(function()
    while timeLeft > 0 do
        task.wait(0.05)
        local character = player.Character; local humanoid = character and character:FindFirstChild("Humanoid")
        
        if humanoid and humanoid.Health <= 0 then cleanup() break end
        if isStopActive then continue end
        
        -- Логика паники на последних 10 секундах (ЭКРАН БОЛЬШЕ НЕ ТЕМНЕЕТ)
        if timeLeft <= 10 then
            if not soundPlaying then scarySound:Play() soundPlaying = true end
            local intensity = (10 - timeLeft) / 10
            scarySound.Volume = math.clamp(intensity * 3, 0.3, 3) 
            timerLabel.Position = UDim2.new(0.5, math.random(-3, 3) - 100, 0.05, math.random(-3, 3))
            
            -- РАДИОПОМЕХИ И ЭФФЕКТ ДИНАМИЧЕСКОГО СЧЕТЧИКА ЧЕРЕПА НА ПОСЛЕДНИХ СЕКУНДАХ
            if timeLeft <= 3 then
                noTimeLabel.Visible = true
                noTimeLabel.Text = "💀"
                colorCorrection.Contrast = math.random(-1, 2)
                colorCorrection.Saturation = math.random(-2, 1)
                
                if timeLeft > 2 then
                    noTimeLabel.TextSize = 100 -- 3 секунда
                    noTimeLabel.Position = UDim2.new(0.5, math.random(-5, 5) - 300, 0.4, math.random(-5, 5) - 100)
                elseif timeLeft <= 2 and timeLeft > 1 then
                    noTimeLabel.TextSize = 250 -- 2 секунда
                    noTimeLabel.Position = UDim2.new(0.5, math.random(-15, 15) - 300, 0.4, math.random(-15, 15) - 100)
                elseif timeLeft <= 1 and timeLeft > 0 then
                    noTimeLabel.TextSize = 550 -- 1 секунда
                    noTimeLabel.Position = UDim2.new(0.5, math.random(-35, 35) - 300, 0.4, math.random(-35, 35) - 100)
                end
            else
                noTimeLabel.Visible = false
                colorCorrection.Contrast = 0
                colorCorrection.Saturation = 0
            end
        else
            if soundPlaying then scarySound:Stop() soundPlaying = false end
            noTimeLabel.Visible = false; colorCorrection.Contrast = 0; colorCorrection.Saturation = 0
            scarySound.Volume = 0; timerLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
        end
        timerLabel.Text = string.format("%d", math.ceil(timeLeft)); timeLeft = timeLeft - 0.05
    end
    if timeLeft <= 0 then timeOverDeath() end
end)
