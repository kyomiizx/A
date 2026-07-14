-- ========================================
-- SCRIPT TP SYSTEM V4 (FIX MULTIPLE POINT)
-- UNTUK DELTA / ANY EXECUTOR
-- ========================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:FindFirstChild("HumanoidRootPart")

-- ========================================
-- 1. DATA POINT (PAKAI TABEL GLOBAL)
-- ========================================
local points = {}  -- <-- PASTIKAN INI TABEL, BUKAN NIL
local selectedPoint = nil
local guiCreated = false

-- ========================================
-- 2. FUNGSI CORE
-- ========================================

-- Set Point (Simpan lokasi)
local function setPoint(name)
    if not rootPart then 
        print("❌ Karakter tidak ditemukan!")
        return false 
    end
    if name == nil or name == "" then
        print("❌ Nama point tidak boleh kosong!")
        return false
    end
    
    local pos = rootPart.Position
    points[name] = pos  -- <-- SIMPAN KE TABEL
    
    print("✅ Point '" .. name .. "' tersimpan di: " .. tostring(pos))
    print("📌 Total point sekarang: " .. tableCount(points))
    
    -- PASTIKAN PANGGIL UPDATE LIST
    updateList()
    return true
end

-- Helper: hitung jumlah point
local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Teleport ke Point
local function tpToPoint(name)
    if not rootPart then 
        print("❌ Karakter tidak ditemukan!")
        return 
    end
    local pos = points[name]
    if pos then
        local success, err = pcall(function()
            rootPart.CFrame = CFrame.new(pos)
            rootPart.Position = pos
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end)
        if success then
            print("✅ Teleport ke '" .. name .. "' berhasil!")
            game.StarterGui:SetCore("SendNotification", {
                Title = "TP System",
                Text = "✅ Teleport ke '" .. name .. "'",
                Duration = 2,
            })
        else
            print("❌ Gagal teleport: " .. tostring(err))
        end
    else
        print("❌ Point '" .. name .. "' tidak ditemukan!")
        game.StarterGui:SetCore("SendNotification", {
            Title = "TP System",
            Text = "❌ Point tidak ditemukan!",
            Duration = 2,
        })
    end
end

-- Teleport ke Spawn
local function tpToSpawn()
    if not rootPart then return end
    local spawns = workspace:FindFirstChild("Spawns") or workspace:FindFirstChild("SpawnLocation")
    if spawns then
        local spawnParts = spawns:GetChildren()
        if #spawnParts > 0 then
            local spawn = spawnParts[1]
            if spawn then
                rootPart.CFrame = spawn.CFrame
                print("✅ Teleport ke Spawn")
            end
        end
    end
end

-- Hapus Point
local function removePoint(name)
    if points[name] then
        points[name] = nil
        print("✅ Point '" .. name .. "' dihapus")
        print("📌 Total point sekarang: " .. tableCount(points))
        updateList()
        if selectedPoint == name then
            selectedPoint = nil
        end
        return true
    else
        print("❌ Point '" .. name .. "' tidak ditemukan!")
        return false
    end
end

-- Hapus SEMUA Point
local function clearAllPoints()
    points = {}
    selectedPoint = nil
    updateList()
    print("✅ Semua point dihapus!")
end

-- ========================================
-- 3. UPDATE LIST POINT (REFERESH UI) - FIX
-- ========================================
function updateList()
    -- Cek GUI
    local gui = player.PlayerGui:FindFirstChild("TPGUI")
    if not gui then 
        print("⚠️ GUI belum dibuat, skip update list")
        return 
    end
    
    -- Cari ListFrame (cek di ScrollFrame dulu)
    local scrollFrame = gui:FindFirstChild("ScrollFrame")
    local listFrame = nil
    
    if scrollFrame then
        listFrame = scrollFrame:FindFirstChild("ListFrame")
    end
    
    -- Fallback: cari langsung di GUI
    if not listFrame then
        listFrame = gui:FindFirstChild("ListFrame")
    end
    
    if not listFrame then 
        print("⚠️ ListFrame tidak ditemukan! Buat ulang...")
        -- Buat ListFrame baru jika tidak ada
        if not scrollFrame then
            scrollFrame = Instance.new("ScrollingFrame")
            scrollFrame.Name = "ScrollFrame"
            scrollFrame.Size = UDim2.new(1, -10, 0, 230)
            scrollFrame.Position = UDim2.new(0, 5, 0, 150)
            scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
            scrollFrame.BackgroundTransparency = 0.3
            scrollFrame.BorderSizePixel = 0
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 100)
            scrollFrame.ScrollBarThickness = 5
            scrollFrame.Parent = gui
        end
        
        listFrame = Instance.new("Frame")
        listFrame.Name = "ListFrame"
        listFrame.Size = UDim2.new(1, 0, 0, 100)
        listFrame.BackgroundTransparency = 1
        listFrame.Parent = scrollFrame
    end
    
    -- Hapus semua tombol lama
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Hitung jumlah point
    local pointCount = tableCount(points)
    print("📌 Update list: " .. pointCount .. " point ditemukan")
    
    if pointCount == 0 then
        -- Tampilkan pesan kosong
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 30)
        emptyLabel.Position = UDim2.new(0, 0, 0, 5)
        emptyLabel.Text = "📭 Belum ada point"
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 14
        emptyLabel.Parent = listFrame
        
        -- Update CanvasSize
        if scrollFrame then
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 50)
        end
        return
    end
    
    -- Buat tombol untuk setiap point
    local yOffset = 5
    local sortedNames = {}
    for name, _ in pairs(points) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)  -- Urutkan alfabetis
    
    for _, name in ipairs(sortedNames) do
        local pos = points[name]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, yOffset)
        btn.Text = "📍 " .. name .. " (" .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. ")"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = (selectedPoint == name) and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 70)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.Parent = listFrame
        
        -- Efek hover
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = (selectedPoint == name) and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 70)
        end)
        
        -- Klik = pilih point
        btn.MouseButton1Click:Connect(function()
            selectedPoint = name
            -- Update semua tombol
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") and child.Text:match("📍") then
                    child.BackgroundColor3 = (child == btn) and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 70)
                end
            end
            print("📌 Point dipilih: " .. name)
            local inputBox = gui:FindFirstChild("InputBox")
            if inputBox then
                inputBox.Text = name
            end
            game.StarterGui:SetCore("SendNotification", {
                Title = "TP System",
                Text = "✅ Dipilih: " .. name,
                Duration = 1,
            })
        end)
        
        -- Klik kanan = langsung teleport
        btn.MouseButton2Click:Connect(function()
            tpToPoint(name)
        end)
        
        yOffset = yOffset + 32
    end
    
    -- Update ukuran list frame
    local newHeight = math.max(yOffset + 10, 50)
    listFrame.Size = UDim2.new(1, 0, 0, newHeight)
    
    -- Update CanvasSize ScrollingFrame
    if scrollFrame then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, newHeight + 20)
    end
    
    print("✅ List berhasil diupdate dengan " .. pointCount .. " point")
end

-- ========================================
-- 4. BUAT UI LENGKAP
-- ========================================
local function createUI()
    -- Hapus GUI lama jika ada
    local oldGUI = player.PlayerGui:FindFirstChild("TPGUI")
    if oldGUI then oldGUI:Destroy() end
    
    -- ScreenGui utama
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TPGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui
    
    -- Frame Utama
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -260)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 2, 1, 2)
    border.Position = UDim2.new(0, -1, 0, -1)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 1
    border.BorderColor3 = Color3.fromRGB(100, 100, 150)
    border.Parent = mainFrame
    
    -- ========================================
    -- DRAG SYSTEM
    -- ========================================
    local function makeDraggable(frame)
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    
    -- ========================================
    -- TITLE BAR + MINIMIZE + CLOSE
    -- ========================================
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    makeDraggable(titleBar)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Text = "🚀 TP SYSTEM V4"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 1, -6)
    minBtn.Position = UDim2.new(1, -70, 0, 3)
    minBtn.Text = "─"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minBtn.Font = Enum.Font.Gotham
    minBtn.TextSize = 20
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    minBtn.MouseButton1Click:Connect(function()
        local content = mainFrame:FindFirstChild("ContentFrame")
        if content then
            content.Visible = not content.Visible
        end
        if content and content.Visible then
            mainFrame.Size = UDim2.new(0, 350, 0, 520)
            minBtn.Text = "─"
        else
            mainFrame.Size = UDim2.new(0, 350, 0, 35)
            minBtn.Text = "□"
        end
    end)
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 1, -6)
    closeBtn.Position = UDim2.new(1, -35, 0, 3)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- ========================================
    -- CONTENT FRAME
    -- ========================================
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -10, 1, -45)
    contentFrame.Position = UDim2.new(0, 5, 0, 40)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- ========================================
    -- INPUT NAMA POINT
    -- ========================================
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(1, 0, 0, 35)
    inputBox.Position = UDim2.new(0, 0, 0, 0)
    inputBox.PlaceholderText = "📝 Masukkan nama point..."
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.BorderSizePixel = 0
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = contentFrame
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and inputBox.Text ~= "" then
            setPoint(inputBox.Text)
            inputBox.Text = ""
        end
    end)
    
    -- ========================================
    -- TOMBOL (BARIS 1)
    -- ========================================
    local btnRow1 = Instance.new("Frame")
    btnRow1.Size = UDim2.new(1, 0, 0, 38)
    btnRow1.Position = UDim2.new(0, 0, 0, 40)
    btnRow1.BackgroundTransparency = 1
    btnRow1.Parent = contentFrame
    
    -- Set
    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0.32, -5, 1, 0)
    setBtn.Position = UDim2.new(0, 0, 0, 0)
    setBtn.Text = "💾 Set"
    setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 14
    setBtn.BorderSizePixel = 0
    setBtn.Parent = btnRow1
    setBtn.MouseButton1Click:Connect(function()
        local name = inputBox.Text
        if name and name ~= "" then
            if setPoint(name) then
                inputBox.Text = ""
            end
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "TP System",
                Text = "⚠️ Masukkan nama point!",
                Duration = 2,
            })
        end
    end)
    
    -- Teleport
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.32, -5, 1, 0)
    tpBtn.Position = UDim2.new(0.34, 0, 0, 0)
    tpBtn.Text = "🌀 TP"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 14
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = btnRow1
    tpBtn.MouseButton1Click:Connect(function()
        local name = inputBox.Text
        if name and name ~= "" then
            tpToPoint(name)
        elseif selectedPoint then
            tpToPoint(selectedPoint)
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "TP System",
                Text = "⚠️ Pilih point dari list atau ketik nama!",
                Duration = 2,
            })
        end
    end)
    
    -- Spawn
    local spawnBtn = Instance.new("TextButton")
    spawnBtn.Size = UDim2.new(0.32, -5, 1, 0)
    spawnBtn.Position = UDim2.new(0.68, 0, 0, 0)
    spawnBtn.Text = "🏠 Spawn"
    spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
    spawnBtn.Font = Enum.Font.GothamBold
    spawnBtn.TextSize = 14
    spawnBtn.BorderSizePixel = 0
    spawnBtn.Parent = btnRow1
    spawnBtn.MouseButton1Click:Connect(function()
        tpToSpawn()
    end)
    
    -- ========================================
    -- TOMBOL (BARIS 2)
    -- ========================================
    local btnRow2 = Instance.new("Frame")
    btnRow2.Size = UDim2.new(1, 0, 0, 35)
    btnRow2.Position = UDim2.new(0, 0, 0, 83)
    btnRow2.BackgroundTransparency = 1
    btnRow2.Parent = contentFrame
    
    -- Hapus
    local removeBtn = Instance.new("TextButton")
    removeBtn.Size = UDim2.new(0.48, -5, 1, 0)
    removeBtn.Position = UDim2.new(0, 0, 0, 0)
    removeBtn.Text = "🗑️ Hapus"
    removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    removeBtn.Font = Enum.Font.GothamBold
    removeBtn.TextSize = 14
    removeBtn.BorderSizePixel = 0
    removeBtn.Parent = btnRow2
    removeBtn.MouseButton1Click:Connect(function()
        local name = inputBox.Text
        if name and name ~= "" and points[name] then
            removePoint(name)
            inputBox.Text = ""
        elseif selectedPoint then
            removePoint(selectedPoint)
            selectedPoint = nil
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "TP System",
                Text = "⚠️ Pilih point yang mau dihapus!",
                Duration = 2,
            })
        end
    end)
    
    -- Hapus Semua
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.48, -5, 1, 0)
    clearBtn.Position = UDim2.new(0.52, 0, 0, 0)
    clearBtn.Text = "🗑️ Hapus Semua"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 14
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = btnRow2
    clearBtn.MouseButton1Click:Connect(function()
        clearAllPoints()
        inputBox.Text = ""
        selectedPoint = nil
    end)
    
    -- ========================================
    -- LIST POINT (TAMPIL SEMUA POINT)
    -- ========================================
    local listLabel = Instance.new("TextLabel")
    listLabel.Size = UDim2.new(1, 0, 0, 22)
    listLabel.Position = UDim2.new(0, 0, 0, 125)
    listLabel.Text = "📋 DAFTAR POINT (klik pilih, klik kanan = TP)"
    listLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    listLabel.BackgroundTransparency = 1
    listLabel.Font = Enum.Font.Gotham
    listLabel.TextSize = 12
    listLabel.TextXAlignment = Enum.TextXAlignment.Left
    listLabel.Parent = contentFrame
    
    -- Scrolling Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, -10, 0, 230)
    scrollFrame.Position = UDim2.new(0, 5, 0, 150)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    scrollFrame.BackgroundTransparency = 0.3
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 100)
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.Parent = contentFrame
    
    -- List Frame
    local listFrame = Instance.new("Frame")
    listFrame.Name = "ListFrame"
    listFrame.Size = UDim2.new(1, 0, 0, 100)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = scrollFrame
    
    -- ========================================
    -- FOOTER
    -- ========================================
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -10, 0, 18)
    footer.Position = UDim2.new(0, 5, 1, -22)
    footer.Text = "🔑 F1=Set  F2=TP  F3=Toggle  Klik kanan list=TP"
    footer.TextColor3 = Color3.fromRGB(130, 130, 160)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 11
    footer.Parent = contentFrame
    
    -- ========================================
    -- SIMPAN REFERENSI
    -- ========================================
    screenGui.MainFrame = mainFrame
    screenGui.ListFrame = listFrame
    screenGui.ScrollFrame = scrollFrame
    screenGui.InputBox = inputBox
    
    guiCreated = true
    
    -- Update list setelah GUI dibuat
    updateList()
    
    print("✅ UI TP System V4 siap!")
end

-- ========================================
-- 5. JALANKAN UI (DENGAN DELAY)
-- ========================================
task.wait(0.5)
createUI()

-- ========================================
-- 6. KEYBIND
-- ========================================
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- F1 = Set Point
    if input.KeyCode == Enum.KeyCode.F1 then
        local name = "Point" .. os.time()
        setPoint(name)
        game.StarterGui:SetCore("SendNotification", {
            Title = "TP System",
            Text = "✅ Point '" .. name .. "' tersimpan!",
            Duration = 2,
        })
    end
    
    -- F2 = Teleport ke point terakhir
    if input.KeyCode == Enum.KeyCode.F2 then
        if selectedPoint then
            tpToPoint(selectedPoint)
        else
            local lastPoint = nil
            for name, _ in pairs(points) do
                lastPoint = name
            end
            if lastPoint then
                tpToPoint(lastPoint)
            else
                game.StarterGui:SetCore("SendNotification", {
                    Title = "TP System",
                    Text = "❌ Belum ada point!",
                    Duration = 2,
                })
            end
        end
    end
    
    -- F3 = Toggle GUI
    if input.KeyCode == Enum.KeyCode.F3 then
        local gui = player.PlayerGui:FindFirstChild("TPGUI")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end
end)

-- ========================================
-- 7. HANDLE KARAKTER RESPAWN
-- ========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:FindFirstChild("HumanoidRootPart")
    print("✅ Karakter respawn, TP System tetap aktif!")
    task.wait(0.5)
    updateList()
end)

-- ========================================
-- 8. NOTIFIKASI AWAL
-- ========================================
game.StarterGui:SetCore("SendNotification", {
    Title = "🚀 TP System V4 Aktif!",
    Text = "📌 F1=Set Point | F2=TP Point | F3=Toggle GUI",
    Duration = 4,
})

print("✅ TP System V4 siap digunakan!")
print("🔑 F1 = Set Point (otomatis)")
print("🔑 F2 = Teleport ke point terpilih")
print("🔑 F3 = Toggle GUI")
print("📌 Total point tersimpan: " .. tableCount(points))