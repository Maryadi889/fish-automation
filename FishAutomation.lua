-- =====================================================
-- Fish Automation Core (LEGIT)
-- Auto Fishing + Auto Sell (Inventory) + Preset V1/V2/V3
-- =====================================================

-- ===== ANTI DOUBLE LOAD =====
if getgenv().FISH_AUTOMATION_LOADED then return end
getgenv().FISH_AUTOMATION_LOADED = true

print("[FishAutomation] SCRIPT START")

-- ================= USER CONFIG =================
local Mode = "V1" -- "V1" | "V2" | "V3"

local AutoFishing = {
    Enable = true
}

local AutoSellConfig = {
    Enable = true,
    Mode = "COUNT", -- "COUNT" | "TIME"
    SellCount = 50,
    SellMinute = 5,
    Cooldown = 10
}

-- ================= PRESET =================
local function ApplyPreset(mode)
    if mode == "V1" then
        return {
            FishingDelay = {1.2, 2.0},
            LoopDelay = 3.5,
            SellCooldown = 15,
            SellMinute = 5,
            SellCount = 50
        }
    elseif mode == "V2" then
        return {
            FishingDelay = {0.6, 1.1},
            LoopDelay = 2.2,
            SellCooldown = 10,
            SellMinute = 3,
            SellCount = 35
        }
    else -- V3
        return {
            FishingDelay = {0.2, 0.4},
            LoopDelay = 1.2,
            SellCooldown = 6,
            SellMinute = 1,
            SellCount = 20
        }
    end
end

local Active = ApplyPreset(Mode)
AutoSellConfig.SellMinute = Active.SellMinute
AutoSellConfig.SellCount  = Active.SellCount
AutoSellConfig.Cooldown   = Active.SellCooldown

-- ================= SERVICES =================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ================= HELPER =================
local function rand(min, max)
    return min + math.random() * (max - min)
end

-- ================= REMOTE EVENTS =================
-- ⚠️ GANTI NAMA EVENT INI SESUAI GAME (PALING SERING BEDA)
local CastEvent = ReplicatedStorage:FindFirstChild("CastFishing")
local ReelEvent = ReplicatedStorage:FindFirstChild("ReelFishing")
local SellEvent = ReplicatedStorage:FindFirstChild("Selling")

if not CastEvent then
    warn("[FishAutomation] CastFishing event TIDAK ditemukan")
end
if not ReelEvent then
    warn("[FishAutomation] ReelFishing event TIDAK ditemukan")
end
if not SellEvent then
    warn("[FishAutomation] Selling event TIDAK ditemukan")
end

-- ================= INVENTORY =================
local function GetFishCount()
    local inv = player:FindFirstChild("Inventory")
    local fish = inv and inv:FindFirstChild("Fish")
    return fish and #fish:GetChildren() or 0
end

-- ================= LOCK =================
local fishingLock = false
local sellingLock = false
local lastSell = 0

-- ================= AUTO FISHING =================
-- Urutan: lempar kail → tunggu → tarik
local function DoFishing()
    if not AutoFishing.Enable then return end
    if fishingLock or sellingLock then return end
    if not CastEvent or not ReelEvent then return end

    fishingLock = true

    -- Lempar kail
    CastEvent:FireServer()

    -- Tunggu ikan nyangkut
    task.wait(rand(Active.FishingDelay[1], Active.FishingDelay[2]))

    -- Tarik kail
    ReelEvent:FireServer()

    fishingLock = false
end

task.spawn(function()
    while task.wait(Active.LoopDelay) do
        DoFishing()
    end
end)

-- ================= AUTO SELL =================
local function ReadyByCount()
    return GetFishCount() >= AutoSellConfig.SellCount
end

local function ReadyByTime()
    return (tick() - lastSell) >= (AutoSellConfig.SellMinute * 60)
end

local function ExecuteSell()
    if not AutoSellConfig.Enable then return end
    if sellingLock then return end
    if not SellEvent then return end

    sellingLock = true

    if AutoSellConfig.Mode == "COUNT" then
        SellEvent:FireServer("SellByCount")
    else
        SellEvent:FireServer("SellByTime")
    end

    lastSell = tick()

    task.delay(AutoSellConfig.Cooldown, function()
        sellingLock = false
    end)
end

task.spawn(function()
    while task.wait(3) do
        if AutoSellConfig.Mode == "COUNT" and ReadyByCount() then
            ExecuteSell()
        elseif AutoSellConfig.Mode == "TIME" and ReadyByTime() then
            ExecuteSell()
        end
    end
end)

print("[FishAutomation] Loaded successfully")
