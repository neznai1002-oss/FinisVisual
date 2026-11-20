--[[
    Finis Visual v2.2 — 3D-интро "F" + 3D-Бекон + Самурайская шляпа + Шейдеры + Размер меню + Конфиги
    Чисто визуальное меню и оформление интерфейса.
    Ключ для входа: @FinisOkek (регистр не важен)
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local ENV = (type(getgenv) == "function" and getgenv()) or _G

-- удаляем старую копию при перезапуске
if ENV.__FinisVisual and type(ENV.__FinisVisual.Destroy) == "function" then
    pcall(ENV.__FinisVisual.Destroy)
end
if ENV.__EtaMenu and type(ENV.__EtaMenu.Destroy) == "function" then
    pcall(ENV.__EtaMenu.Destroy)
end

-- общая таблица состояния и модулей (исключает переполнение upvalues)
local F = {
    conns       = {},
    cleanups    = {},
    sparks      = {},
    searchItems = {},
    binders     = {},
    sliders     = {},
    segments    = {},
    palettes    = {},
    scrolled    = false,
    toast       = function() end,
    pressFx     = function() end,
    scrollLock  = function() end,
    orbTap      = function() end,
    applyScale  = function() end,
    applyOpac   = function() end,
    refreshPrev = function() end,
}
ENV.__FinisVisual = F
ENV.__FinisVisualMemCfg = ENV.__FinisVisualMemCfg or {}

function F.bind(signal, fn)
    local c = signal:Connect(fn)
    F.conns[#F.conns + 1] = c
    return c
end

function F.onCleanup(fn)
    F.cleanups[#F.cleanups + 1] = fn
end

----------------------------------------------------------------------
-- ScreenGui (CoreGui приоритетно для стабильного 3D ViewportFrame)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FinisVisualMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)

do
    local okCg, cg = pcall(function() return game:GetService("CoreGui") end)
    if okCg and cg then pcall(function() gui.Parent = cg end) end
    if not gui.Parent and type(gethui) == "function" then
        local okHui, hui = pcall(gethui)
        if okHui and hui then pcall(function() gui.Parent = hui end) end
    end
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
F.gui = gui

function F.Destroy()
    if F.saveAuto then pcall(F.saveAuto) end
    for _, fn in ipairs(F.cleanups) do pcall(fn) end
    F.cleanups = {}
    for _, c in ipairs(F.conns) do pcall(function() c:Disconnect() end) end
    F.conns = {}
    pcall(function() gui:Destroy() end)
    if ENV.__FinisVisual == F then ENV.__FinisVisual = nil end
end

----------------------------------------------------------------------
-- константы, цвета, хелперы
----------------------------------------------------------------------
local V2 = Vector2.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function off(x, y) return UDim2.fromOffset(x, y) end
local function sc(x, y) return UDim2.fromScale(x, y) end

F.V2, F.rgb, F.off, F.sc = V2, rgb, off, sc
F.WIN_W, F.WIN_H   = 1020, 620
F.SIDE_W, F.HEAD_H = 173, 80
F.PAGE_W, F.PAGE_H = 847, 540
F.CARD_W, F.CARD_H = 495, 442
F.KEY              = "@finisokek"
F.FONT_R, F.FONT_M, F.FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold

local C = {
    white = rgb(255, 255, 255),
    txt   = rgb(246, 248, 255),
    txt2  = rgb(184, 186, 216),
    txt3  = rgb(141, 141, 177),
    txt4  = rgb(112, 113, 148),
    dark  = rgb(22, 20, 46),
    knob  = rgb(238, 240, 250),
    track = rgb(39, 41, 62),
    off   = rgb(74, 76, 104),
    panel = rgb(18, 17, 38),
    green = rgb(96, 226, 160),
    red   = rgb(255, 106, 140),
    a     = rgb(160, 172, 250),
    b     = rgb(192, 156, 250),
}
F.C = C

local PALETTE = {
    rgb(160, 172, 250), -- жемчуг
    rgb(255, 92, 128),  -- розовый
    rgb(72, 198, 255),  -- голубой
    rgb(96, 232, 152),  -- мятный
    rgb(255, 210, 96),  -- золотой
    rgb(255, 134, 68),  -- оранжевый
    rgb(196, 116, 255), -- неон-фиолет
    rgb(245, 248, 255), -- белый
}
F.PALETTE = PALETTE

-- значения по умолчанию (шляпа выключена при старте!)
local DEFAULT_STATE = {
    -- оформление 3D-превью Бекона
    prevBox      = true,
    prevNick     = true,
    prevDist     = true,
    prevHealth   = true,
    chamsMode    = 1, -- 1=Обычный, 2=Glow, 3=Flat, 4=Glass
    chamsTrans   = 25,
    prevColorIdx = 2,

    -- косметическая самурайская шляпа (выключена при запуске!)
    hatEnabled   = false,
    hatRgb       = false,
    hatSize      = 1.25,
    hatHeight    = 0.55,
    hatTrans     = 15,
    hatMat       = 1,
    hatColorIdx  = 1,

    -- шейдеры (Lighting)
    shaderPreset = 1,
    shBloom      = false,
    shBloomInt   = 0.8,
    shSunRays    = false,
    shDof        = false,
    shSat        = 0.0,
    shContrast   = 0.0,
    shClock      = 14.0,
    shBright     = 2.0,
    shBlur       = 0,

    -- настройки самого меню и автосохранение
    menuScale    = 1.0,
    panelOpacity = 88,
    autoSave     = true,
}

local State = {}
for k, v in pairs(DEFAULT_STATE) do State[k] = v end
F.State = State

function F.getPrevColor() return PALETTE[State.prevColorIdx] or PALETTE[2] end
function F.getHatColor()  return PALETTE[State.hatColorIdx]  or PALETTE[1] end

function F.bindState(key, fn)
    F.binders[key] = F.binders[key] or {}
    table.insert(F.binders[key], fn)
    fn(State[key], true)
end

function F.setState(key, v, skipAutoSave)
    State[key] = v
    local list = F.binders[key]
    if list then
        for _, fn in ipairs(list) do pcall(fn, v, false) end
    end
    if not skipAutoSave and State.autoSave and F.scheduleAutoSave then
        F.scheduleAutoSave()
    end
end

function F.trim(s)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

function F.tw(o, dur, props, style, dir)
    local t = TweenService:Create(o, TweenInfo.new(math.max(0.01, dur), style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

function F.animateValue(dur, a, b, fn)
    dur = math.max(0.02, dur)
    local t0, done = os.clock(), false
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if done then return end
        local k = math.min(1, (os.clock() - t0) / dur)
        fn(a + (b - a) * (1 - (1 - k) ^ 3))
        if k >= 1 then done = true; conn:Disconnect() end
    end)
    task.delay(dur + 0.05, function()
        if not done then done = true; conn:Disconnect(); fn(b) end
    end)
end

function F.New(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end

function F.Frame(parent, p)
    local t = { BorderSizePixel = 0, BackgroundColor3 = C.white }
    if p then for k, v in pairs(p) do t[k] = v end end
    return F.New("Frame", t, parent)
end

function F.Group(parent, p)
    local t = { BorderSizePixel = 0, BackgroundTransparency = 1 }
    if p then for k, v in pairs(p) do t[k] = v end end
    return F.New("CanvasGroup", t, parent)
end

function F.Label(parent, p)
    local t = {
        BorderSizePixel = 0, BackgroundTransparency = 1, Font = F.FONT_M,
        TextSize = 14, TextColor3 = C.txt, Text = "",
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    }
    if p then for k, v in pairs(p) do t[k] = v end end
    t.TextSize = math.floor(t.TextSize + 0.5)
    return F.New("TextLabel", t, parent)
end

function F.Button(parent, p)
    local t = {
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        Size = sc(1, 1),
    }
    if p then for k, v in pairs(p) do t[k] = v end end
    return F.New("TextButton", t, parent)
end

function F.Corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r)
    c.Parent = o
    return c
end

function F.Stroke(o, color, tr, th)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or C.white
    s.Transparency = tr or 0.88
    s.Thickness = th or 1
    s.Parent = o
    return s
end

function F.Grad(o, c1, c2, rot, t1, t2)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    if t1 ~= nil then g.Transparency = NumberSequence.new(t1, t2 or t1) end
    g.Parent = o
    return g
end

function F.accent(o, rot) return F.Grad(o, C.a, C.b, rot or 0) end

function F.viewport()
    local v = gui.AbsoluteSize
    if v.X < 50 or v.Y < 50 then
        local cam = workspace.CurrentCamera
        if cam then v = cam.ViewportSize end
    end
    if v.X < 50 or v.Y < 50 then v = V2(1280, 720) end
    return v
end

function F.topInsetPx()
    local v = 0
    pcall(function() v = GuiService.TopbarInset.Max.Y end)
    if v <= 0 then pcall(function() v = GuiService:GetGuiInset().Y end) end
    return v
end

function F.homeCenter()
    local v = F.viewport()
    local inset = F.topInsetPx()
    return UDim2.fromScale(0.5, (inset + (v.Y - inset) / 2) / v.Y)
end

function F.baseScale()
    local v = F.viewport()
    local h = math.max(100, v.Y - F.topInsetPx())
    return math.max(0.3, math.min(h * 0.9 / F.WIN_H, v.X * 0.62 / F.WIN_W))
end

function F.measure(text, size, font)
    size = math.floor(size + 0.5)
    local ok, r = pcall(function() return TextService:GetTextSize(text, size, font or F.FONT_M, V2(3000, 200)) end)
    if ok and r then return r.X end
    return #text * size * 0.58
end

function F.measureH(text, size, font, w)
    local ok, r = pcall(function() return TextService:GetTextSize(text, size, font, V2(w, 4000)) end)
    if ok and r then return r.Y end
    return math.ceil((utf8.len(text) or #text) * size * 0.58 / w) * size * 1.25
end

-- единое перетаскивание
F.Drag = { move = nil, finish = nil }
function F.beginDrag(move, finish)
    if F.Drag.finish then pcall(F.Drag.finish) end
    F.Drag.move, F.Drag.finish = move, finish
end
F.bind(UserInputService.InputChanged, function(input)
    if F.Drag.move and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        F.Drag.move(input)
    end
end)
F.bind(UserInputService.InputEnded, function(input)
    if F.Drag.finish and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
        local fin = F.Drag.finish
        F.Drag.move, F.Drag.finish = nil, nil
        fin()
    end
end)

function F.isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

----------------------------------------------------------------------
-- СИСТЕМА КОНФИГОВ И АВТОСОХРАНЕНИЯ (ФАЙЛЫ + РЕЗЕРВ В ПАМЯТИ)
----------------------------------------------------------------------
do
    local CFG_DIR = "FinisVisualConfigs"
    local AUTO_FILE = CFG_DIR .. "/_autosave.json"
    local hasFS = (type(writefile) == "function" and type(readfile) == "function")

    local function ensureDir()
        if not hasFS then return end
        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
            end
        end)
    end

    local function sanitizeName(name)
        name = F.trim(tostring(name or ""))
        name = string.gsub(name, "[^%w%-%_%sА-Яа-яЁё]", "")
        return F.trim(name)
    end

    local function serializeState()
        local data = {}
        for k in pairs(DEFAULT_STATE) do
            data[k] = State[k]
        end
        return HttpService:JSONEncode(data)
    end

    local function decodeState(raw)
        local ok, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(tbl) == "table" then return tbl end
        return nil
    end

    function F.applyLoadedData(tbl)
        if type(tbl) ~= "table" then return end
        for k, defVal in pairs(DEFAULT_STATE) do
            if tbl[k] ~= nil and type(tbl[k]) == type(defVal) then
                State[k] = tbl[k]
            end
        end
        -- синхронизируем все UI элементы
        for k in pairs(DEFAULT_STATE) do
            F.setState(k, State[k], true)
            if F.sliders[k] then F.sliders[k].set(State[k]) end
            if F.palettes[k] then F.palettes[k].set(State[k]) end
            if F.segments[k] then F.segments[k].set(State[k], true) end
        end
        -- обновляем меню, 3D-превью и шейдеры
        F.applyScale(State.menuScale)
        F.applyOpac(State.panelOpacity)
        F.refreshPrev()
        if F.ApplySavedShaders then F.ApplySavedShaders() end
    end

    function F.saveConfig(name)
        name = sanitizeName(name)
        if name == "" then return false, "Введи название конфига" end
        local raw = serializeState()
        ENV.__FinisVisualMemCfg[name] = raw
        if hasFS then
            ensureDir()
            pcall(writefile, CFG_DIR .. "/" .. name .. ".json", raw)
        end
        return true, name
    end

    function F.loadConfig(name)
        local raw = ENV.__FinisVisualMemCfg[name]
        if hasFS and type(isfile) == "function" then
            local path = CFG_DIR .. "/" .. name .. ".json"
            local okEx, exists = pcall(isfile, path)
            if okEx and exists then
                local okR, content = pcall(readfile, path)
                if okR and type(content) == "string" then raw = content end
            end
        end
        if not raw then return false end
        local tbl = decodeState(raw)
        if not tbl then return false end
        F.applyLoadedData(tbl)
        if State.autoSave then F.saveAuto() end
        return true
    end

    function F.deleteConfig(name)
        ENV.__FinisVisualMemCfg[name] = nil
        if hasFS and type(delfile) == "function" then
            pcall(delfile, CFG_DIR .. "/" .. name .. ".json")
        end
    end

    function F.listConfigs()
        local map, out = {}, {}
        for name in pairs(ENV.__FinisVisualMemCfg) do
            if name ~= "_autosave" then map[name] = true end
        end
        if hasFS and type(listfiles) == "function" then
            ensureDir()
            local ok, files = pcall(listfiles, CFG_DIR)
            if ok and type(files) == "table" then
                for _, path in ipairs(files) do
                    local fname = string.match(path, "([^/\\]+)%.json$")
                    if fname and fname ~= "_autosave" then
                        map[fname] = true
                    end
                end
            end
        end
        for name in pairs(map) do out[#out + 1] = name end
        table.sort(out)
        return out
    end

    function F.saveAuto()
        if not State.autoSave then return end
        local raw = serializeState()
        ENV.__FinisVisualMemCfg["_autosave"] = raw
        if hasFS then
            ensureDir()
            pcall(writefile, AUTO_FILE, raw)
        end
    end

    function F.loadAuto()
        local raw = ENV.__FinisVisualMemCfg["_autosave"]
        if hasFS and type(isfile) == "function" then
            local okEx, exists = pcall(isfile, AUTO_FILE)
            if okEx and exists then
                local okR, content = pcall(readfile, AUTO_FILE)
                if okR and type(content) == "string" then raw = content end
            end
        end
        if not raw then return false end
        local tbl = decodeState(raw)
        if not tbl then return false end
        for k, defVal in pairs(DEFAULT_STATE) do
            if tbl[k] ~= nil and type(tbl[k]) == type(defVal) then
                State[k] = tbl[k]
            end
        end
        return true
    end

    local saveToken = 0
    function F.scheduleAutoSave()
        saveToken = saveToken + 1
        local tok = saveToken
        task.delay(0.35, function()
            if tok == saveToken then F.saveAuto() end
        end)
    end

    function F.resetAllToDefaults()
        local copy = {}
        for k, v in pairs(DEFAULT_STATE) do copy[k] = v end
        F.applyLoadedData(copy)
        if F.ResetShaders then F.ResetShaders() end
        F.saveAuto()
    end

    -- автосохранение при выходе игрока с сервера
    F.bind(Players.PlayerRemoving, function(plr)
        if plr == LocalPlayer then F.saveAuto() end
    end)

    -- загружаем прошлые настройки до построения UI
    F.loadAuto()
end

----------------------------------------------------------------------
-- векторные иконки + логотип F
----------------------------------------------------------------------
do
    local ICONS = {
        eye       = { {"p",true, 2,12, 5,8.5, 8.5,6.3, 12,5.5, 15.5,6.3, 19,8.5, 22,12, 19,15.5, 15.5,17.7, 12,18.5, 8.5,17.7, 5,15.5}, {"c",12,12,3} },
        folder    = { {"p",true, 3,5.5, 8.5,5.5, 10.5,8, 20,8, 21,9, 21,19, 20,20, 4,20, 3,19} },
        sliders   = { {"l",3,6,6,6}, {"l",11,6,21,6}, {"c",8.5,6,2.4}, {"l",3,12,13,12}, {"l",18,12,21,12}, {"c",15.5,12,2.4}, {"l",3,18,7,18}, {"l",12,18,21,18}, {"c",9.5,18,2.4} },
        save      = { {"p",true, 4,4, 17,4, 20,7, 20,20, 4,20}, {"p",false, 8,4, 8,9, 15,9, 15,4}, {"p",false, 7,20, 7,14, 17,14, 17,20} },
        trash     = { {"l",3.5,6,20.5,6}, {"p",false, 8.5,6, 8.5,3.5, 15.5,3.5, 15.5,6}, {"p",true, 5.5,6, 6.5,20.5, 17.5,20.5, 18.5,6}, {"l",10,10,10,16.5}, {"l",14,10,14,16.5} },
        pencil    = { {"p",true, 3.5,20.5, 4.5,15.5, 15.5,4.5, 19.5,8.5, 8.5,19.5}, {"l",13,7,17,11} },
        x         = { {"l",6,6,18,18}, {"l",18,6,6,18} },
        check     = { {"p",false, 5,12.5, 10,17.5, 19,7} },
        arrow     = { {"l",4,12,20,12}, {"p",false, 14,6, 20,12, 14,18} },
        key       = { {"c",6.2,12,3.6}, {"l",9.8,12,21.5,12}, {"l",18,12,18,15.5}, {"l",21.5,12,21.5,14.8} },
        clipboard = { {"r",5.5,4,13,17.5,2.5}, {"r",9,2,6,4,1.5}, {"l",9,12,15,12}, {"l",9,16,13,16} },
        sparkle   = { {"p",true, 12,2, 14,10, 22,12, 14,14, 12,22, 10,14, 2,12, 10,10} },
        search    = { {"c",10.5,10.5,6.5}, {"l",15.5,15.5,20.5,20.5} },
        undo      = { {"p",false, 3,4.5, 3,10, 8.5,10}, {"p",false, 3.8,10, 5,6.8, 8,4.5, 12,3.6, 16,4.6, 19.2,7.6, 20.4,11.6, 19.4,15.6, 16.4,18.8, 12.4,20.2, 8.4,19.4} },
        target    = { {"c",12,12,9.5}, {"c",12,12,5.5}, {"d",12,12,1.6} },
        hat       = { {"p",true, 12,5, 22,16, 2,16}, {"l",1,16.5,23,16.5} },
        sun       = { {"c",12,12,4.5}, {"l",12,2,12,5}, {"l",12,19,12,22}, {"l",2,12,5,12}, {"l",19,12,22,12}, {"l",5,5,7.2,7.2}, {"l",16.8,16.8,19,19}, {"l",19,5,16.8,7.2}, {"l",7.2,16.8,5,19} },
        dot       = { {"d",12,12,3} },
    }

    local function atan2(y, x) return math.atan2 and math.atan2(y, x) or math.atan(y, x) end

    local function mkLine(root, x1, y1, x2, y2, th, color)
        local dx, dy = x2 - x1, y2 - y1
        local f = F.Frame(root, {
            Name = "p", AnchorPoint = V2(0.5, 0.5),
            Position = off((x1 + x2) / 2, (y1 + y2) / 2),
            Size = off(math.sqrt(dx * dx + dy * dy) + th * 0.35, th),
            Rotation = math.deg(atan2(dy, dx)),
            BackgroundColor3 = color,
        })
        F.Corner(f, "full")
        return f
    end

    local function mkCircle(root, cx, cy, r, th, color, filled)
        local f = F.Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = off(cx, cy), Size = off(r * 2, r * 2) })
        F.Corner(f, "full")
        if filled then f.Name = "p"; f.BackgroundColor3 = color
        else f.Name = "o"; f.BackgroundTransparency = 1; F.Stroke(f, color, 0, th) end
        return f
    end

    local function mkRRect(root, x, y, w, h, rad, th, color)
        local f = F.Frame(root, { Name = "o", Position = off(x, y), Size = off(w, h), BackgroundTransparency = 1 })
        F.Corner(f, math.max(1, rad))
        F.Stroke(f, color, 0, th)
        return f
    end

    function F.Icon(parent, name, size, color, props)
        local spec = ICONS[name] or ICONS.dot
        local root = F.Frame(parent, { Name = "Icon", BackgroundTransparency = 1, Size = off(size, size) })
        if props then for k, v in pairs(props) do root[k] = v end end
        local k, th = size / 24, math.max(1, size / 13)
        for _, s in ipairs(spec) do
            local t = s[1]
            if t == "l" then mkLine(root, s[2]*k, s[3]*k, s[4]*k, s[5]*k, th, color)
            elseif t == "p" then
                local pts = {}
                for i = 3, #s - 1, 2 do pts[#pts + 1] = { s[i]*k, s[i + 1]*k } end
                for i = 1, #pts - 1 do mkLine(root, pts[i][1], pts[i][2], pts[i+1][1], pts[i+1][2], th, color) end
                if s[2] and #pts > 2 then mkLine(root, pts[#pts][1], pts[#pts][2], pts[1][1], pts[1][2], th, color) end
            elseif t == "c" then mkCircle(root, s[2]*k, s[3]*k, s[4]*k, th, color, false)
            elseif t == "d" then mkCircle(root, s[2]*k, s[3]*k, s[4]*k, th, color, true)
            elseif t == "r" then mkRRect(root, s[2]*k, s[3]*k, s[4]*k, s[5]*k, s[6]*k, th, color) end
        end
        return root
    end

    function F.setIconColor(root, color, instant)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("UIStroke") then
                if instant then d.Color = color else F.tw(d, 0.2, { Color = color }) end
            elseif d:IsA("Frame") and d.Name == "p" then
                if instant then d.BackgroundColor3 = color else F.tw(d, 0.2, { BackgroundColor3 = color }) end
            end
        end
    end

    function F.setIconAlpha(root, a)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("UIStroke") then d.Transparency = 1 - a
            elseif d:IsA("Frame") and d.Name == "p" then d.BackgroundTransparency = 1 - a end
        end
    end

    function F.makeLogoF(parent, size, ring, spark)
        local root = F.Frame(parent, { Name = "LogoF", BackgroundTransparency = 1, Size = off(size * 1.5, size) })
        local k = size / 40
        local cx, cy = size * 0.75, size * 0.5
        local thick, midTh = math.max(2.2, size / 9.2), math.max(1.8, size / 11.2)
        local col = rgb(232, 224, 255)
        local A, B, phi, rcy = size * 0.66, size * 0.17, math.rad(-16), cy + size * 0.07

        if ring then
            local px, py
            local lt = math.max(1, size / 34)
            for i = 0, 40 do
                local t = (i / 40) * math.pi * 2
                local ex, ey = A * math.cos(t), B * math.sin(t)
                local x = cx + ex * math.cos(phi) - ey * math.sin(phi)
                local y = rcy + ex * math.sin(phi) + ey * math.cos(phi)
                if px then mkLine(root, px, py, x, y, lt, rgb(206, 198, 255)).BackgroundTransparency = 0.45 end
                px, py = x, y
            end
        end

        local ox, oy = cx - 20 * k, cy - 20 * k
        mkLine(root, ox + 15.5*k, oy + 9.0*k,  ox + 12.2*k, oy + 32.5*k, thick, col)
        mkLine(root, ox + 15.5*k, oy + 9.0*k,  ox + 29.0*k, oy + 9.0*k,  thick, col)
        mkLine(root, ox + 14.0*k, oy + 20.5*k, ox + 25.0*k, oy + 20.5*k, midTh, col)

        if spark then
            local spSize = math.max(8, size * 0.3)
            local sf = F.Frame(root, { Name = "Spark", BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0.5), Size = off(spSize, spSize) })
            F.Corner(F.Frame(sf, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1.5), BackgroundColor3 = C.white }), "full")
            F.Corner(F.Frame(sf, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(0, 1.5, 1, 0), BackgroundColor3 = C.white }), "full")
            sf.Position = off(cx - A * 0.8, rcy + B * 0.5)
            F.sparks[#F.sparks + 1] = { f = sf, s = spSize, cx = cx, cy = rcy, a = A, b = B, phi = phi, th = math.random() * 6.28, sp = 0.55 }
        end
        return root
    end
end

----------------------------------------------------------------------
-- UI КОНСТРУКТОРЫ
----------------------------------------------------------------------
do
    local Quad, Back, Quint = Enum.EasingStyle.Quad, Enum.EasingStyle.Back, Enum.EasingStyle.Quint
    local Out = Enum.EasingDirection.Out

    function F.addPress(btn, target, amount)
        local us = F.New("UIScale", {}, target)
        amount = amount or 0.96
        btn.InputBegan:Connect(function(i) if F.isPress(i) then F.tw(us, 0.1, { Scale = amount }, Quad, Out) end end)
        btn.InputEnded:Connect(function(i) if F.isPress(i) then F.tw(us, 0.25, { Scale = 1 }, Back, Out) end end)
        return us
    end

    function F.Toggle(parent, x, y, on, onClick)
        local W, H, K = 58, 32, 24
        local root = F.Frame(parent, { Name = "Toggle", Position = off(x, y), Size = off(W, H), BackgroundColor3 = C.off, BackgroundTransparency = 0.2 })
        F.Corner(root, "full")
        local stroke = F.Stroke(root, C.white, on and 0.55 or 0.9, 1)
        local fill = F.Frame(root, { Size = sc(1, 1), BackgroundColor3 = C.white, BackgroundTransparency = on and 0 or 1 })
        F.Corner(fill, "full"); F.accent(fill, 0)
        local knob = F.Frame(root, { AnchorPoint = V2(0, 0.5), Position = off(on and (W-K-4) or 4, H/2), Size = off(K, K), BackgroundColor3 = C.knob, ZIndex = 2 })
        F.Corner(knob, "full")
        local btn = F.Button(root, { ZIndex = 3 })
        local obj = { frame = root, on = on }
        function obj.set(v, instant)
            obj.on = v
            local goal = off(v and (W-K-4) or 4, H/2)
            if instant then
                knob.Position = goal; fill.BackgroundTransparency = v and 0 or 1; stroke.Transparency = v and 0.55 or 0.9
            else
                F.tw(knob, 0.3, { Position = goal }, Back, Out)
                F.tw(fill, 0.22, { BackgroundTransparency = v and 0 or 1 }, Quad, Out)
                F.tw(stroke, 0.22, { Transparency = v and 0.55 or 0.9 }, Quad, Out)
            end
        end
        btn.InputBegan:Connect(function(i) if F.isPress(i) then F.tw(knob, 0.12, { Size = off(K+6, K) }, Quad, Out) end end)
        btn.InputEnded:Connect(function(i) if F.isPress(i) then F.tw(knob, 0.2, { Size = off(K, K) }, Quad, Out) end end)
        btn.Activated:Connect(function()
            if F.scrolled then return end
            F.pressFx(root)
            if onClick then onClick() end
        end)
        return obj
    end

    function F.Slider(parent, x, y, w, cfg)
        local R = 11
        local root = F.Frame(parent, { Name = "Slider", BackgroundTransparency = 1, Position = off(x, y), Size = off(w, 28) })
        local track = F.Frame(root, { AnchorPoint = V2(0, 0.5), Position = off(0, 14), Size = off(w, 6), BackgroundColor3 = C.track, BackgroundTransparency = 0.05 })
        F.Corner(track, "full")
        local fill = F.Frame(track, { Size = off(0, 6), BackgroundColor3 = C.white })
        F.Corner(fill, "full"); F.accent(fill, 0)
        local thumb = F.Frame(root, { AnchorPoint = V2(0.5, 0.5), Size = off(2*R, 2*R), Position = off(R, 14), BackgroundColor3 = C.knob, ZIndex = 3 })
        F.Corner(thumb, "full"); F.Stroke(thumb, C.white, 0.55, 1)
        local hit = F.Button(root, { Size = off(w, 28), ZIndex = 4 })

        local value = cfg.value
        local function render(animate)
            local f = math.clamp((value - cfg.min) / (cfg.max - cfg.min), 0, 1)
            local cx = R + f * (w - 2 * R)
            if animate then
                F.tw(thumb, 0.12, { Position = off(cx, 14) }, Quad, Out)
                F.tw(fill, 0.12, { Size = off(cx, 6) }, Quad, Out)
            else
                thumb.Position = off(cx, 14); fill.Size = off(cx, 6)
            end
            if cfg.label then cfg.label.Text = cfg.fmt(value) end
        end
        render(false)

        local function setFromX(px)
            local aw = track.AbsoluteSize.X
            if aw <= 0 then return end
            local k = aw / w
            local f = math.clamp((px - track.AbsolutePosition.X - R * k) / (aw - 2 * R * k), 0, 1)
            local v = cfg.min + f * (cfg.max - cfg.min)
            if cfg.step then v = math.floor(v / cfg.step + 0.5) * cfg.step end
            v = math.clamp(v, cfg.min, cfg.max)
            if v ~= value then
                value = v; render(false)
                if cfg.onChange then cfg.onChange(v) end
            end
        end

        hit.InputBegan:Connect(function(input)
            if not F.isPress(input) then return end
            F.scrollLock(true)
            F.tw(thumb, 0.15, { Size = off(2*R+4, 2*R+4) }, Quad, Out)
            setFromX(input.Position.X)
            F.beginDrag(function(i) setFromX(i.Position.X) end, function()
                F.scrollLock(false)
                F.tw(thumb, 0.2, { Size = off(2*R, 2*R) }, Quad, Out)
                if State.autoSave then F.scheduleAutoSave() end
            end)
        end)

        return { frame = root, set = function(v) value = v; render(true) end }
    end

    function F.Segmented(parent, x, y, w, options, selected, onSelect)
        local H, pad = 38, 4
        local n = #options
        local root = F.Frame(parent, { Name = "Segmented", Position = off(x, y), Size = off(w, H), BackgroundColor3 = C.panel, BackgroundTransparency = 0.55 })
        F.Corner(root, 13); F.Stroke(root, C.white, 0.9, 1)
        local segW = (w - pad * 2) / n
        local pill = F.Frame(root, { Name = "Pill", Size = off(segW, H - pad * 2), Position = off(pad, pad), BackgroundColor3 = C.white, Visible = (selected ~= nil and selected > 0) })
        F.Corner(pill, 10); F.accent(pill, 0)
        local labels = {}
        local obj = { frame = root, selected = selected }
        local function paint(idx, instant)
            for k, l in ipairs(labels) do
                local col = (k == idx) and C.dark or rgb(176, 177, 206)
                if instant then l.TextColor3 = col else F.tw(l, 0.2, { TextColor3 = col }) end
            end
        end
        function obj.set(i, instant)
            obj.selected = i
            if i == nil or i < 1 then pill.Visible = false; paint(0, true); return end
            local goal = off(pad + (i - 1) * segW, pad)
            if not pill.Visible then pill.Position = goal; pill.Visible = true
            elseif instant then pill.Position = goal
            else F.tw(pill, 0.3, { Position = goal }, Quint, Out) end
            paint(i, instant)
        end
        for i, name in ipairs(options) do
            local b = F.Button(root, { Position = off(pad + (i - 1) * segW, pad), Size = off(segW, H - pad * 2), ZIndex = 2 })
            labels[i] = F.Label(b, { Size = sc(1, 1), Text = name, TextSize = 12.5, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = rgb(176, 177, 206) })
            b.Activated:Connect(function()
                if F.scrolled then return end
                F.pressFx(b); obj.set(i, false)
                if onSelect then onSelect(i, name) end
                if State.autoSave then F.scheduleAutoSave() end
            end)
        end
        obj.set(selected, true)
        return obj
    end

    function F.MakeButton(parent, x, y, w, h, text, iconName, style, onClick)
        local root = F.Frame(parent, { Name = "Btn", Position = off(x, y), Size = off(w, h), BackgroundColor3 = C.white })
        F.Corner(root, 14)
        local fg = C.txt
        if style == "primary" then F.accent(root, 0); fg = C.dark
        elseif style == "danger" then root.BackgroundColor3 = rgb(210, 56, 86); root.BackgroundTransparency = 0.25; fg = C.white
        else root.BackgroundColor3 = rgb(72, 72, 104); root.BackgroundTransparency = 0.72; F.Stroke(root, C.white, 0.88, 1) end
        local twd = F.measure(text, 14.5, F.FONT_B)
        local iw, gap = iconName and 16 or 0, iconName and 7 or 0
        local sx = (w - (iw + gap + twd)) / 2
        if iconName then F.Icon(root, iconName, 16, fg, { Position = off(sx, (h - 16) / 2) }) end
        F.Label(root, { Position = off(sx + iw + gap, 0), Size = off(twd + 6, h), Text = text, TextSize = 14.5, Font = F.FONT_B, TextColor3 = fg })
        local btn = F.Button(root, { ZIndex = 3 })
        F.addPress(btn, root, 0.97)
        btn.Activated:Connect(function()
            if F.scrolled then return end
            F.pressFx(root)
            if onClick then onClick() end
        end)
        return root
    end

    function F.Swatch(parent, x, y, d, col, selected, onClick)
        local root = F.Frame(parent, { Name = "Swatch", Position = off(x, y), Size = off(d, d), BackgroundColor3 = col })
        F.Corner(root, "full")
        local ring = F.Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(d + 8, d + 8), BackgroundTransparency = 1 })
        F.Corner(ring, "full")
        local rs = F.Stroke(ring, C.white, selected and 0.1 or 1, 2)
        local btn = F.Button(root, { ZIndex = 3 })
        btn.Activated:Connect(function()
            if F.scrolled then return end
            F.pressFx(root)
            if onClick then onClick() end
            if State.autoSave then F.scheduleAutoSave() end
        end)
        return { set = function(v) F.tw(rs, 0.2, { Transparency = v and 0.1 or 1 }) end }
    end

    function F.Input(parent, x, y, w, h, icon, placeholder, size)
        local root = F.Frame(parent, { Name = "Input", Position = off(x, y), Size = off(w, h), BackgroundColor3 = rgb(16, 15, 34), BackgroundTransparency = 0.45 })
        F.Corner(root, 16)
        local stroke = F.Stroke(root, C.white, 0.9, 1)
        local ic = F.Icon(root, icon, 18, rgb(150, 150, 182), { Position = off(15, (h - 18) / 2) })
        local box = F.New("TextBox", {
            Name = "Box", BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = off(46, 0), Size = off(w - 58, h), Font = F.FONT_M, TextSize = size or 16,
            TextColor3 = C.txt, PlaceholderText = placeholder, PlaceholderColor3 = rgb(112, 113, 144),
            Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
        }, root)
        box.Focused:Connect(function() F.tw(stroke, 0.2, { Transparency = 0.35, Color = C.a }); F.tw(root, 0.2, { BackgroundTransparency = 0.3 }) end)
        box.FocusLost:Connect(function() F.tw(stroke, 0.2, { Transparency = 0.9, Color = C.white }); F.tw(root, 0.2, { BackgroundTransparency = 0.45 }) end)
        return root, box, stroke, ic
    end

    -- колонка-конструктор
    local Column = {}
    Column.__index = Column

    local function fitDesc(text, maxW)
        for _, s in ipairs({ 12, 10, 9 }) do
            if F.measure(text, s, F.FONT_R) <= maxW then return s, 1 end
        end
        return 9, math.max(2, math.floor(F.measureH(text, 9, F.FONT_R, maxW) / 11 + 0.5))
    end

    function F.newColumn(parent, x, y0, w)
        local c = setmetatable({}, Column)
        c.w, c.y = w, y0
        c.holder = F.Frame(parent, { Name = "Col", BackgroundTransparency = 1, Position = off(x, 0), Size = off(w, 10) })
        return c
    end

    function Column:row(h, opts)
        opts = opts or {}
        local r = F.Frame(self.holder, { Name = "Row", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, h) })
        if opts.sep ~= false then
            F.Frame(r, { Name = "sep", Position = off(0, h - 1), Size = off(self.w, 1), BackgroundTransparency = 0.93 })
        end
        self.y = self.y + h
        return r
    end

    function Column:header(title, icon, hint, topGap)
        self.y = self.y + (topGap or 0)
        local r = F.Frame(self.holder, { Name = "Header", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, 26) })
        local badge = F.Frame(r, { Size = off(26, 26), BackgroundColor3 = rgb(140, 130, 235), BackgroundTransparency = 0.78 })
        F.Corner(badge, "full"); F.Stroke(badge, C.white, 0.9, 1)
        F.Icon(badge, icon, 14, rgb(196, 188, 255), { Position = off(6, 6) })
        F.Label(r, { Position = off(36, 0), Size = off(self.w - 36, 26), Text = title, TextSize = 15 })
        if hint then
            F.Label(r, { AnchorPoint = V2(1, 0), Position = off(self.w, 0), Size = off(self.w * 0.55, 26), Text = hint, TextSize = 12, TextColor3 = C.txt3, TextXAlignment = Enum.TextXAlignment.Right })
        end
        self.y = self.y + 38
        return r
    end

    function Column:toggle(key, title, desc, onChange, opts)
        local maxW = self.w - 74
        local size, lines = 12, 1
        if desc then size, lines = fitDesc(desc, maxW) end
        local extra = (lines - 1) * 11
        local h = (desc and 64 or 44) + extra
        local r = self:row(h, opts)
        F.Label(r, { Position = off(0, 7), Size = off(self.w - 70, 22), Text = title, TextSize = 15.5 })
        if desc then
            F.Label(r, { Position = off(0, 29), Size = off(maxW, 18 + extra), Text = desc, TextSize = size, TextColor3 = C.txt3, Font = F.FONT_R, TextWrapped = lines > 1, TextYAlignment = Enum.TextYAlignment.Top })
        end
        local t = F.Toggle(r, self.w - 58, desc and 10 or 4, State[key], function()
            local nv = not State[key]
            F.setState(key, nv)
            if onChange then onChange(nv) end
        end)
        F.bindState(key, function(v, instant) t.set(v, instant) end)
        table.insert(F.searchItems, { row = r, text = string.lower(title .. " " .. (desc or "")) })
        return r, t
    end

    function Column:slider(key, title, desc, cfg, opts)
        local size, lines = 12, 1
        if desc then size, lines = fitDesc(desc, self.w) end
        local extra = (lines - 1) * 11
        local h = (desc and 82 or 68) + extra
        local r = self:row(h, opts)
        F.Label(r, { Position = off(0, 2), Size = off(self.w - 96, 20), Text = title, TextSize = 15 })
        local val = F.Label(r, { AnchorPoint = V2(1, 0), Position = off(self.w, 2), Size = off(96, 20), TextSize = 13.5, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Right })
        if desc then
            F.Label(r, { Position = off(0, 22), Size = off(self.w, 16 + extra), Text = desc, TextSize = size, TextColor3 = C.txt3, Font = F.FONT_R, TextWrapped = lines > 1, TextYAlignment = Enum.TextYAlignment.Top })
        end
        cfg.label = val; cfg.value = State[key]
        local userCb = cfg.onChange
        cfg.onChange = function(v) State[key] = v; if userCb then userCb(v) end end
        local s = F.Slider(r, 0, (desc and 42 or 28) + extra, self.w, cfg)
        F.sliders[key] = s
        table.insert(F.searchItems, { row = r, text = string.lower(title .. " " .. (desc or "")) })
        return r, s
    end

    function Column:segment(key, label, options, selected, onSelect, opts)
        local h = label and 74 or 50
        local r = self:row(h, opts)
        if label then F.Label(r, { Position = off(0, 2), Size = off(self.w, 20), Text = label, TextSize = 15 }) end
        local seg = F.Segmented(r, 0, label and 28 or 6, self.w, options, selected, onSelect)
        if key then F.segments[key] = seg end
        if label then table.insert(F.searchItems, { row = r, text = string.lower(label) }) end
        return r, seg
    end

    function Column:palette(key, label, selectedIdx, onPick, opts)
        local r = self:row(72, opts)
        F.Label(r, { Position = off(0, 4), Size = off(self.w, 20), Text = label, TextSize = 15 })
        local sw = {}
        local step = (self.w - 26) / (#PALETTE - 1)
        local function selectIdx(idx)
            for j, o in ipairs(sw) do o.set(j == idx) end
        end
        for i, col in ipairs(PALETTE) do
            sw[i] = F.Swatch(r, (i - 1) * step, 34, 26, col, i == selectedIdx, function()
                selectIdx(i)
                if onPick then onPick(i, col) end
            end)
        end
        if key then F.palettes[key] = { set = selectIdx } end
        table.insert(F.searchItems, { row = r, text = string.lower(label) })
        return r
    end

    function Column:button(text, icon, style, onClick, opts)
        local r = self:row(54, opts)
        F.MakeButton(r, 0, 5, self.w, 42, text, icon, style, onClick)
        table.insert(F.searchItems, { row = r, text = string.lower(text) })
        return r
    end
end

----------------------------------------------------------------------
-- МОДУЛЬ 1: КОСМЕТИЧЕСКАЯ САМУРАЙСКАЯ ШЛЯПА (КАСА)
----------------------------------------------------------------------
do
    local HAT_LAYERS = 13
    local HAT_MATS = { Enum.Material.Neon, Enum.Material.Glass, Enum.Material.SmoothPlastic, Enum.Material.ForceField }

    function F.CreateSamuraiHat(parent, name)
        local folder = F.New("Folder", { Name = name or "SamuraiHat" }, parent)
        local layers = {}
        for i = 1, HAT_LAYERS do
            layers[i] = F.New("Part", {
                Name = "Ring_" .. i, Shape = Enum.PartType.Cylinder,
                Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
                TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
                Material = Enum.Material.Neon, Size = Vector3.new(0.08, 2, 2), Transparency = 1,
            }, folder)
        end
        local tip = F.New("Part", {
            Name = "Tip", Shape = Enum.PartType.Ball,
            Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
            Material = Enum.Material.Neon, Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1,
        }, folder)
        return { folder = folder, layers = layers, tip = tip }
    end

    function F.UpdateSamuraiHat(hat, headCF, enabled, sizeScale, heightOff, transPct, col, matIdx, spinAngle)
        if not hat or not hat.folder or not hat.folder.Parent then return end
        if not enabled or not headCF then
            for _, p in ipairs(hat.layers) do p.Transparency = 1 end
            hat.tip.Transparency = 1
            return
        end

        local mat = HAT_MATS[matIdx] or Enum.Material.Neon
        local baseTrans = math.clamp(transPct / 100, 0, 0.96)
        local baseR = 2.55 * sizeScale
        local totalH = 0.92 * sizeScale
        local stepH = totalH / HAT_LAYERS
        local baseCF = headCF * CFrame.new(0, heightOff, 0) * CFrame.Angles(0, spinAngle or 0, 0)

        for i, p in ipairs(hat.layers) do
            local t = (i - 1) / (HAT_LAYERS - 1)
            local radius = math.max(0.14, baseR * ((1 - t) ^ 0.88))
            p.Size = Vector3.new(math.max(0.05, stepH * 1.35), radius * 2, radius * 2)
            p.CFrame = baseCF * CFrame.new(0, t * totalH, 0) * CFrame.Angles(0, 0, math.rad(90))
            p.Material = mat
            local shade = 0.72 + 0.28 * (1 - t)
            p.Color = Color3.new(col.R * shade, col.G * shade, col.B * shade)
            p.Transparency = (i == 1) and math.max(0, baseTrans - 0.12) or baseTrans
        end

        local tipSize = math.max(0.16, 0.24 * sizeScale)
        hat.tip.Size = Vector3.new(tipSize, tipSize, tipSize)
        hat.tip.CFrame = baseCF * CFrame.new(0, totalH + tipSize * 0.15, 0)
        hat.tip.Material = mat
        hat.tip.Color = col
        hat.tip.Transparency = baseTrans
    end

    local worldHatFolder = F.New("Folder", { Name = "FinisVisual_WorldHat" }, workspace)
    F.worldHat = F.CreateSamuraiHat(worldHatFolder, "LocalSamuraiHat")
    F.onCleanup(function() pcall(function() worldHatFolder:Destroy() end) end)
end

----------------------------------------------------------------------
-- МОДУЛЬ 2: ШЕЙДЕРЫ (LIGHTING + 8 ПРЕСЕТОВ)
----------------------------------------------------------------------
do
    local Orig = {
        ClockTime            = Lighting.ClockTime,
        Brightness           = Lighting.Brightness,
        Ambient              = Lighting.Ambient,
        OutdoorAmbient       = Lighting.OutdoorAmbient,
        ColorShift_Top       = Lighting.ColorShift_Top,
        ColorShift_Bottom    = Lighting.ColorShift_Bottom,
        GlobalShadows        = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
    DEFAULT_STATE.shClock  = math.floor(Orig.ClockTime * 2 + 0.5) / 2
    DEFAULT_STATE.shBright = math.clamp(math.floor(Orig.Brightness * 10 + 0.5) / 10, 0.5, 5)
    if State.shaderPreset == 1 then
        State.shClock  = DEFAULT_STATE.shClock
        State.shBright = DEFAULT_STATE.shBright
    end

    local ShaderFX = {}
    local function getFX(cls, name)
        if ShaderFX[name] and ShaderFX[name].Parent then return ShaderFX[name] end
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
        local obj = Instance.new(cls)
        obj.Name = name
        obj.Parent = Lighting
        ShaderFX[name] = obj
        return obj
    end

    F.SHADER_PRESETS = {
        { name = "Оригинал", reset = true },
        { name = "RTX Ультра", clock = 15.5, bright = 2.8, exposure = 0.18, ambient = rgb(92,98,114), outdoor = rgb(135,142,160), top = rgb(255,245,232), tint = rgb(255,250,244), bloom = true, bloomInt = 0.65, sun = true, dof = true, sat = 0.18, contrast = 0.18, blur = 0 },
        { name = "Киберпанк",  clock = 22.5, bright = 1.9, exposure = 0.25, ambient = rgb(95,50,145), outdoor = rgb(75,95,175),   top = rgb(220,90,255),  tint = rgb(225,200,255), bloom = true, bloomInt = 1.45, sun = false, dof = false, sat = 0.45, contrast = 0.28, blur = 0 },
        { name = "Закат",      clock = 17.8, bright = 2.6, exposure = 0.15, ambient = rgb(138,86,68), outdoor = rgb(186,118,86),  top = rgb(255,172,102), tint = rgb(255,224,194), bloom = true, bloomInt = 0.95, sun = true, dof = true, sat = 0.28, contrast = 0.15, blur = 0 },
        { name = "Аниме",      clock = 13.0, bright = 3.2, exposure = 0.22, ambient = rgb(140,152,178), outdoor = rgb(168,185,215), top = rgb(235,248,255), tint = rgb(248,252,255), bloom = true, bloomInt = 0.75, sun = true, dof = false, sat = 0.55, contrast = 0.12, blur = 0 },
        { name = "Нуар",       clock = 20.5, bright = 1.4, exposure = -0.1, ambient = rgb(52,56,68),  outdoor = rgb(72,78,92),    top = rgb(145,155,175), tint = rgb(210,220,238), bloom = false, bloomInt = 0.3, sun = false, dof = true, sat = -0.72, contrast = 0.35, blur = 0 },
        { name = "Зима",       clock = 10.5, bright = 2.5, exposure = 0.12, ambient = rgb(126,160,202), outdoor = rgb(156,192,232), top = rgb(208,236,255), tint = rgb(220,240,255), bloom = true, bloomInt = 0.85, sun = true, dof = false, sat = -0.08, contrast = 0.1, blur = 0 },
        { name = "Vaporwave",  clock = 18.4, bright = 2.3, exposure = 0.20, ambient = rgb(156,76,166), outdoor = rgb(98,176,212), top = rgb(255,128,214), tint = rgb(252,210,245), bloom = true, bloomInt = 1.25, sun = true, dof = false, sat = 0.42, contrast = 0.2, blur = 0 },
    }
    F.shaderSeg1, F.shaderSeg2 = nil, nil

    local function syncShaderSegs(idx)
        if F.shaderSeg1 and F.shaderSeg2 then
            if idx <= 4 then
                F.shaderSeg1.set(idx, true); F.shaderSeg2.set(nil, true)
            else
                F.shaderSeg1.set(nil, true); F.shaderSeg2.set(idx - 4, true)
            end
        end
    end

    function F.ResetShaders()
        for _, fxObj in pairs(ShaderFX) do pcall(function() fxObj:Destroy() end) end
        table.clear(ShaderFX)
        for prop, val in pairs(Orig) do pcall(function() Lighting[prop] = val end) end
    end

    function F.ApplyManualShaders(tintOverride)
        pcall(function()
            Lighting.ClockTime = State.shClock
            Lighting.Brightness = State.shBright
            Lighting.GlobalShadows = true
        end)
        local bloom = getFX("BloomEffect", "FinisVisual_Bloom")
        bloom.Enabled = State.shBloom; bloom.Intensity = State.shBloomInt; bloom.Size = 26; bloom.Threshold = 0.9

        local cc = getFX("ColorCorrectionEffect", "FinisVisual_CC")
        cc.Enabled = (State.shaderPreset ~= 1) or (State.shSat ~= 0) or (State.shContrast ~= 0)
        cc.Saturation = State.shSat; cc.Contrast = State.shContrast
        if tintOverride then cc.TintColor = tintOverride end

        local rays = getFX("SunRaysEffect", "FinisVisual_SunRays")
        rays.Enabled = State.shSunRays; rays.Intensity = 0.14; rays.Spread = 0.65

        local dof = getFX("DepthOfFieldEffect", "FinisVisual_DOF")
        dof.Enabled = State.shDof; dof.FocusDistance = 24; dof.InFocusRadius = 32; dof.NearIntensity = 0.12; dof.FarIntensity = 0.28

        local blur = getFX("BlurEffect", "FinisVisual_Blur")
        blur.Enabled = State.shBlur > 0; blur.Size = State.shBlur
    end

    function F.ApplyShaderPreset(idx)
        State.shaderPreset = idx
        syncShaderSegs(idx)
        local p = F.SHADER_PRESETS[idx]
        if not p or p.reset then
            F.ResetShaders()
            State.shSat = 0; State.shContrast = 0; State.shBlur = 0
            State.shClock = DEFAULT_STATE.shClock; State.shBright = DEFAULT_STATE.shBright
            F.setState("shBloom", false, true); F.setState("shSunRays", false, true); F.setState("shDof", false, true)
            for _, k in ipairs({ "shSat", "shContrast", "shClock", "shBright", "shBlur" }) do
                if F.sliders[k] then F.sliders[k].set(State[k]) end
            end
            if State.autoSave then F.scheduleAutoSave() end
            return
        end

        pcall(function()
            Lighting.Ambient = p.ambient; Lighting.OutdoorAmbient = p.outdoor
            Lighting.ColorShift_Top = p.top; Lighting.ExposureCompensation = p.exposure or 0
        end)
        State.shBloomInt = p.bloomInt; State.shSat = p.sat; State.shContrast = p.contrast
        State.shClock = p.clock; State.shBright = p.bright; State.shBlur = p.blur
        F.setState("shBloom", p.bloom, true); F.setState("shSunRays", p.sun, true); F.setState("shDof", p.dof, true)
        for _, k in ipairs({ "shBloomInt", "shSat", "shContrast", "shClock", "shBright", "shBlur" }) do
            if F.sliders[k] then F.sliders[k].set(State[k]) end
        end
        F.ApplyManualShaders(p.tint)
        if State.autoSave then F.scheduleAutoSave() end
    end

    function F.ApplySavedShaders()
        local idx = State.shaderPreset or 1
        syncShaderSegs(idx)
        local p = F.SHADER_PRESETS[idx]
        if not p or p.reset then
            F.ResetShaders()
            if State.shBloom or State.shSunRays or State.shDof or State.shSat ~= 0 or State.shContrast ~= 0 or State.shBlur > 0 then
                F.ApplyManualShaders()
            end
            return
        end
        pcall(function()
            Lighting.Ambient = p.ambient; Lighting.OutdoorAmbient = p.outdoor
            Lighting.ColorShift_Top = p.top; Lighting.ExposureCompensation = p.exposure or 0
        end)
        F.ApplyManualShaders(p.tint)
    end

    F.onCleanup(F.ResetShaders)
end

----------------------------------------------------------------------
-- МОДУЛЬ 3: 3D-ПРЕВЬЮ БЕКОНА (ЧАМСЫ НА ВСЁ ТЕЛО + ШЛЯПА КАСА)
----------------------------------------------------------------------
function F.BuildBaconPreview(parent, x, y, w, h, isWinOpenFn)
    local card = F.Frame(parent, {
        Name = "BaconPreviewCard", Position = off(x, y), Size = off(w, h),
        BackgroundColor3 = rgb(14, 13, 28), BackgroundTransparency = 0.2, ClipsDescendants = true,
    })
    F.Corner(card, 18); F.Stroke(card, C.white, 0.86, 1)

    local bgGrad = F.Frame(card, { Size = sc(1, 1), BackgroundTransparency = 0.65, ZIndex = 1 })
    F.Corner(bgGrad, 18); F.Grad(bgGrad, rgb(42, 36, 84), rgb(14, 13, 28), 90)

    local nameBadge = F.Frame(card, { Position = off(12, 12), Size = off(116, 26), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    F.Corner(nameBadge, "full"); F.Stroke(nameBadge, C.white, 0.85, 1)
    F.Corner(F.Frame(nameBadge, { Position = off(9, 9), Size = off(8, 8), BackgroundColor3 = C.a }), "full")
    F.Label(nameBadge, { Position = off(22, 0), Size = off(88, 26), Text = "Bacon 3D", TextSize = 12 })

    local autoSpin = true
    local spinBtn = F.Frame(card, { Position = off(w - 72, 12), Size = off(28, 28), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    F.Corner(spinBtn, "full"); F.Stroke(spinBtn, C.white, 0.85, 1)
    local spinIcon = F.Icon(spinBtn, "undo", 14, C.a, { Position = off(7, 7) })
    local spinHit = F.Button(spinBtn, { ZIndex = 5 }); F.addPress(spinHit, spinBtn, 0.9)

    local resetBtn = F.Frame(card, { Position = off(w - 38, 12), Size = off(28, 28), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    F.Corner(resetBtn, "full"); F.Stroke(resetBtn, C.white, 0.85, 1)
    F.Icon(resetBtn, "target", 14, C.txt2, { Position = off(7, 7) })
    local resetHit = F.Button(resetBtn, { ZIndex = 5 }); F.addPress(resetHit, resetBtn, 0.9)

    local vp = F.New("ViewportFrame", {
        Name = "BaconVP", Position = off(0, 34), Size = off(w, h - 56),
        BackgroundTransparency = 1, Ambient = rgb(212, 218, 230),
        LightColor = C.white, LightDirection = Vector3.new(-0.5, -1, 0.8),
        Active = true, ZIndex = 2,
    }, card)

    local espBox = F.Frame(vp, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.53), Size = off(122, 184), BackgroundTransparency = 1, ZIndex = 3 })
    F.Corner(espBox, 4)
    local espBoxStroke = F.Stroke(espBox, F.getPrevColor(), 0.1, 1.6)

    local espNick = F.Label(vp, {
        AnchorPoint = V2(0.5, 1), Position = UDim2.new(0.5, 0, 0.53, -96),
        Size = off(150, 16), Text = "Bacon Hair", TextSize = 11, Font = F.FONT_B,
        TextColor3 = C.white, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
    })
    local espDist = F.Label(vp, {
        AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, 0.53, 96),
        Size = off(100, 14), Text = "16 м", TextSize = 10, Font = F.FONT_M,
        TextColor3 = F.getPrevColor(), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
    })
    local hpBg = F.Frame(vp, { AnchorPoint = V2(1, 0.5), Position = UDim2.new(0.5, -66, 0.53, 0), Size = off(4, 184), BackgroundColor3 = rgb(14, 14, 24), BackgroundTransparency = 0.2, ZIndex = 4 })
    F.Corner(hpBg, "full")
    F.Corner(F.Frame(hpBg, { AnchorPoint = V2(0, 1), Position = sc(0, 1), Size = sc(1, 0.86), BackgroundColor3 = C.green }), "full")

    F.Label(card, { Position = off(0, h - 22), Size = off(w, 18), Text = "Потяни пальцем, чтобы крутить 3D-Бекона", TextSize = 11, TextColor3 = C.txt3, Font = F.FONT_R, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })

    local world = F.New("WorldModel", {}, vp)
    local cam = F.New("Camera", { FieldOfView = 38 }, vp)
    vp.CurrentCamera = cam

    local previewHat = F.CreateSamuraiHat(world, "PreviewSamuraiHat")
    local visuals = { model = nil, humanoid = nil, bodyColors = nil, headPart = nil, parts = {}, meshes = {}, decals = {}, clothes = {} }
    local camDist = 9.4

    local function RefreshPreview()
        local col = F.getPrevColor()
        espBox.Visible = State.prevBox; espBoxStroke.Color = col
        espNick.Visible = State.prevNick
        espDist.Visible = State.prevDist; espDist.TextColor3 = col
        hpBg.Visible = State.prevHealth

        local mode = State.chamsMode
        local chamsOn = (mode ~= 1)
        local mat = (mode == 2 and Enum.Material.Neon)
            or (mode == 3 and Enum.Material.SmoothPlastic)
            or Enum.Material.ForceField
        local chamsT = (mode == 4) and math.clamp(State.chamsTrans / 100, 0.2, 0.85) or (State.chamsTrans / 100 * 0.5)

        if visuals.humanoid then visuals.humanoid.Parent = chamsOn and nil or visuals.model end
        if visuals.bodyColors then visuals.bodyColors.Parent = chamsOn and nil or visuals.model end
        for _, cl in ipairs(visuals.clothes) do if cl.obj then cl.obj.Parent = chamsOn and nil or visuals.model end end
        for _, dc in ipairs(visuals.decals) do if dc.decal then dc.decal.Transparency = chamsOn and 1 or dc.origTrans end end
        for _, ms in ipairs(visuals.meshes) do
            if ms.mesh then
                pcall(function()
                    if ms.mesh:IsA("SpecialMesh") then ms.mesh.TextureId = chamsOn and "" or ms.origTex
                    elseif ms.mesh:IsA("MeshPart") then ms.mesh.TextureID = chamsOn and "" or ms.origTex end
                end)
            end
        end
        for _, info in ipairs(visuals.parts) do
            if info.part and info.part.Parent then
                if chamsOn then
                    info.part.Color = col; info.part.Material = mat; info.part.Transparency = chamsT
                else
                    info.part.Color = info.origColor; info.part.Material = info.origMat; info.part.Transparency = info.origTrans
                end
            end
        end
    end
    F.refreshPrev = RefreshPreview

    local function MountModel(model)
        for _, ch in ipairs(world:GetChildren()) do
            if ch ~= previewHat.folder then ch:Destroy() end
        end
        table.clear(visuals.parts); table.clear(visuals.meshes)
        table.clear(visuals.decals); table.clear(visuals.clothes)
        visuals.model = model
        visuals.humanoid = model:FindFirstChildOfClass("Humanoid")
        visuals.bodyColors = model:FindFirstChildOfClass("BodyColors")
        if visuals.humanoid then
            visuals.humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            visuals.humanoid.PlatformStand = true; visuals.humanoid.AutoRotate = false
        end

        model.Parent = world
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if hrp then hrp.Anchored = true; model.PrimaryPart = hrp; model:PivotTo(CFrame.new(0, 0, 0)) end

        RunService.Heartbeat:Wait()

        local bbCF, bbSize = model:GetBoundingBox()
        local shift = -bbCF.Position
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then obj.Anchored = true; obj.CFrame = obj.CFrame + shift end
        end

        visuals.headPart = model:FindFirstChild("Head")
        camDist = math.clamp(bbSize.Y * 1.65, 8.8, 11.4)

        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                if obj.Name == "HumanoidRootPart" then obj.Transparency = 1
                else table.insert(visuals.parts, { part = obj, origColor = obj.Color, origMat = obj.Material, origTrans = obj.Transparency }) end
                if obj:IsA("MeshPart") and obj.TextureID ~= "" then table.insert(visuals.meshes, { mesh = obj, origTex = obj.TextureID }) end
            elseif obj:IsA("SpecialMesh") and obj.TextureId ~= "" then table.insert(visuals.meshes, { mesh = obj, origTex = obj.TextureId })
            elseif obj:IsA("Decal") then table.insert(visuals.decals, { decal = obj, origTrans = obj.Transparency })
            elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then table.insert(visuals.clothes, { obj = obj }) end
        end
        RefreshPreview()
    end

    task.spawn(function()
        local skinGray = rgb(205, 206, 208)
        local okDesc, model = pcall(function()
            local desc = Instance.new("HumanoidDescription")
            desc.HairAccessory = "63690008"; desc.Shirt = 144076358; desc.Pants = 144076760; desc.Face = 144080495
            desc.HeadColor = skinGray; desc.TorsoColor = skinGray
            desc.LeftArmColor = skinGray; desc.RightArmColor = skinGray
            desc.LeftLegColor = skinGray; desc.RightLegColor = skinGray
            return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
        end)
        if okDesc and model then MountModel(model); return end

        local rig = F.New("Model", { Name = "BaconHairR6" })
        F.New("Humanoid", { RigType = Enum.HumanoidRigType.R6 }, rig)
        local function R6(name, sz, cf)
            return F.New("Part", {
                Name = name, Size = sz, CFrame = cf, Color = skinGray, Material = Enum.Material.SmoothPlastic,
                Anchored = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
            }, rig)
        end
        R6("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0)).Transparency = 1
        R6("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0))
        local head = R6("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0))
        F.New("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25) }, head)
        R6("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0))
        R6("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0))
        R6("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0))
        R6("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0))
        F.New("Decal", { Name = "face", Face = Enum.NormalId.Front, Texture = "rbxasset://textures/face.png" }, head)

        pcall(function()
            local objs = game:GetObjects("rbxassetid://63690008")
            local acc = objs and objs[1]
            if acc then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    handle.Anchored = true
                    local att = handle:FindFirstChildOfClass("Attachment")
                    handle.CFrame = att and (head.CFrame * CFrame.new(0, 0.6, 0) * att.CFrame:Inverse()) or (head.CFrame * CFrame.new(0, 0.3, 0))
                end
                acc.Parent = rig
            end
        end)
        pcall(function() local o = game:GetObjects("rbxassetid://144076358"); if o and o[1] then o[1].Parent = rig end end)
        pcall(function() local o = game:GetObjects("rbxassetid://144076760"); if o and o[1] then o[1].Parent = rig end end)
        MountModel(rig)
    end)

    local camYaw, camPitch, dragging3D = 18, 8, false
    spinHit.Activated:Connect(function()
        if F.scrolled then return end
        F.pressFx(spinBtn); autoSpin = not autoSpin
        F.setIconColor(spinIcon, autoSpin and C.a or C.txt3, false)
    end)
    resetHit.Activated:Connect(function()
        if F.scrolled then return end
        F.pressFx(resetBtn); camYaw, camPitch = 0, 8
    end)

    vp.InputBegan:Connect(function(input)
        if not F.isPress(input) then return end
        dragging3D = true; F.scrollLock(true)
        local lastPos = V2(input.Position.X, input.Position.Y)
        F.beginDrag(function(i)
            local cur = V2(i.Position.X, i.Position.Y)
            local d = cur - lastPos; lastPos = cur
            camYaw = camYaw - d.X * 0.9
            camPitch = math.clamp(camPitch + d.Y * 0.45, -28, 35)
        end, function() dragging3D = false; F.scrollLock(false) end)
    end)

    local spinHat = 0
    F.bind(RunService.RenderStepped, function(dt)
        spinHat = (spinHat + dt * 0.9) % (math.pi * 2)
        local hatCol = State.hatRgb and Color3.fromHSV((os.clock() * 0.25) % 1, 0.85, 1) or F.getHatColor()

        local char = LocalPlayer.Character
        local head = char and char:FindFirstChild("Head")
        F.UpdateSamuraiHat(F.worldHat, head and head.CFrame or nil, State.hatEnabled, State.hatSize, State.hatHeight, State.hatTrans, hatCol, State.hatMat, spinHat)

        if not isWinOpenFn() then return end

        if autoSpin and not dragging3D then camYaw = camYaw + dt * 24 end
        local rotCF = CFrame.Angles(0, math.rad(camYaw), 0) * CFrame.Angles(math.rad(-camPitch), 0, 0)
        cam.CFrame = CFrame.lookAt(rotCF * Vector3.new(0, 0.2, -camDist), Vector3.new(0, 0.2, 0))

        local prevHeadCF = visuals.headPart and visuals.headPart.CFrame or CFrame.new(0, 1.5, 0)
        F.UpdateSamuraiHat(previewHat, prevHeadCF, State.hatEnabled, State.hatSize, State.hatHeight, State.hatTrans, hatCol, State.hatMat, spinHat)
    end)

    return { refresh = RefreshPreview }
end

----------------------------------------------------------------------
-- ВКЛАДКА 1: ВИЗУАЛ (3D-БЕКОН + ШЛЯПА КАСА + ШЕЙДЕРЫ)
----------------------------------------------------------------------
function F.BuildVisualPage(page, isWinOpenFn)
    local s = page.scroller
    F.Label(s, { Position = off(26, 12), Size = off(420, 38), Text = "Визуал", TextSize = 28, Font = F.FONT_B, TextColor3 = rgb(236, 230, 255) })
    F.Label(s, { Position = off(26, 50), Size = off(520, 22), Text = "3D-превью Бекона, самурайская шляпа (Каса) и шейдеры", TextSize = 13.5, TextColor3 = C.txt2 })

    local LX, RX, COLW = 26, 422, 372
    local L = F.newColumn(s, LX, 90, COLW)
    local R = F.newColumn(s, RX, 90, COLW)

    -- ЛЕВАЯ КОЛОНКА: 3D Бекон + Чамсы + Шейдеры
    L:header("3D Предпросмотр", "eye", "Бекон + Каса")
    local preview = F.BuildBaconPreview(L.holder, 0, L.y, COLW, 306, isWinOpenFn)
    L.y = L.y + 314

    L:segment("chamsMode", "Стиль чамсов (на всё тело)", { "Обычный", "Glow", "Flat", "Glass" }, State.chamsMode, function(idx, name)
        State.chamsMode = idx
        preview.refresh()
        F.toast("Чамсы: " .. name, "sparkle")
    end)

    L:header("Шейдеры (Освещение)", "sun", "8 пресетов", 14)
    do
        local r1 = L:row(46, { sep = false })
        local pIdx = State.shaderPreset
        local seg1 = F.Segmented(r1, 0, 4, COLW, { "Оригинал", "RTX", "Кибер", "Закат" }, (pIdx <= 4) and pIdx or nil, function(i)
            F.ApplyShaderPreset(i)
            F.toast("Шейдер: " .. F.SHADER_PRESETS[i].name, "sun")
        end)
        local r2 = L:row(50)
        local seg2 = F.Segmented(r2, 0, 4, COLW, { "Аниме", "Нуар", "Зима", "Vapor" }, (pIdx > 4) and (pIdx - 4) or nil, function(i)
            F.ApplyShaderPreset(i + 4)
            F.toast("Шейдер: " .. F.SHADER_PRESETS[i + 4].name, "sun")
        end)
        F.shaderSeg1, F.shaderSeg2 = seg1, seg2
        table.insert(F.searchItems, { row = r1, text = "шейдеры оригинал rtx киберпанк закат" })
        table.insert(F.searchItems, { row = r2, text = "шейдеры аниме нуар зима vaporwave" })
    end

    L:toggle("shBloom", "Свечение (Bloom)", "Мягкое сияние ярких объектов", function() F.ApplyManualShaders() end)
    L:slider("shBloomInt", "Сила свечения", nil, { min = 0, max = 3, step = 0.05, fmt = function(v) return string.format("%.2f", v) end, onChange = function() F.ApplyManualShaders() end })
    L:toggle("shSunRays", "Лучи солнца (SunRays)", "Объёмные солнечные лучи", function() F.ApplyManualShaders() end)
    L:toggle("shDof", "Глубина резкости (DOF)", "Мягкое размытие дальнего фона", function() F.ApplyManualShaders() end)
    L:slider("shSat", "Насыщенность", nil, { min = -1, max = 1, step = 0.05, fmt = function(v) return string.format("%+.2f", v) end, onChange = function() F.ApplyManualShaders() end })
    L:slider("shContrast", "Контраст", nil, { min = -0.5, max = 0.8, step = 0.05, fmt = function(v) return string.format("%+.2f", v) end, onChange = function() F.ApplyManualShaders() end })
    L:slider("shClock", "Время суток", nil, { min = 0, max = 24, step = 0.5, fmt = function(v) return string.format("%.1f ч", v) end, onChange = function() F.ApplyManualShaders() end })
    L:slider("shBright", "Яркость мира", nil, { min = 0.5, max = 5, step = 0.1, fmt = function(v) return string.format("%.1f", v) end, onChange = function() F.ApplyManualShaders() end })
    L:slider("shBlur", "Размытие экрана", nil, { min = 0, max = 24, step = 1, fmt = function(v) return string.format("%d px", v) end, onChange = function() F.ApplyManualShaders() end })
    L:button("Сбросить шейдеры", "undo", "ghost", function()
        F.ApplyShaderPreset(1)
        F.toast("Шейдеры сброшены к оригиналу", "undo")
    end, { sep = false })

    -- ПРАВАЯ КОЛОНКА: Самурайская шляпа (Каса) + Визуал превью Бекона
    R:header("Самурайская шляпа (Каса)", "hat", "На голове + 3D")
    R:toggle("hatEnabled", "Включить шляпу", "Коническая самурайская шляпа (выкл. по умолчанию)")
    R:toggle("hatRgb", "Радуга (RGB)", "Плавный перелив всех цветов")
    R:slider("hatSize", "Размер шляпы", "Ширина полей и высота конуса", {
        min = 0.5, max = 3.0, step = 0.05, fmt = function(v) return string.format("%.2fx", v) end,
    })
    R:slider("hatHeight", "Высота над головой", nil, {
        min = -0.3, max = 2.0, step = 0.05, fmt = function(v) return string.format("%+.2f", v) end,
    })
    R:slider("hatTrans", "Прозрачность шляпы", nil, {
        min = 0, max = 95, step = 5, fmt = function(v) return string.format("%d%%", v) end,
    })
    R:segment("hatMat", "Материал шляпы", { "Neon", "Glass", "Flat", "Field" }, State.hatMat, function(i) State.hatMat = i end)
    R:palette("hatColorIdx", "Цвет шляпы", State.hatColorIdx, function(i) State.hatColorIdx = i end)

    R:header("Оформление 3D-превью", "target", "Только превью", 14)
    R:toggle("prevBox", "Рамка на превью", "2D рамка вокруг 3D-Бекона", function() preview.refresh() end)
    R:toggle("prevNick", "Ник на превью", "Подпись сверху модели", function() preview.refresh() end)
    R:toggle("prevDist", "Дистанция на превью", "Подпись снизу модели", function() preview.refresh() end)
    R:toggle("prevHealth", "Полоска HP на превью", "Индикатор здоровья сбоку", function() preview.refresh() end)
    R:slider("chamsTrans", "Прозрачность чамсов", nil, {
        min = 5, max = 95, step = 5, fmt = function(v) return string.format("%d%%", v) end,
        onChange = function() preview.refresh() end,
    })
    R:palette("prevColorIdx", "Цвет рамки и чамсов", State.prevColorIdx, function(i)
        State.prevColorIdx = i; preview.refresh()
    end, { sep = false })

    page.setHeight(math.max(L.y, R.y) + 32)
end

----------------------------------------------------------------------
-- ВКЛАДКА 2: МЕНЮ И КОНФИГИ (РАЗМЕР МЕНЮ + СОХРАНЕНИЕ)
----------------------------------------------------------------------
function F.BuildConfigPage(page)
    local s = page.scroller
    F.Label(s, { Position = off(26, 12), Size = off(460, 38), Text = "Меню и Конфиги", TextSize = 28, Font = F.FONT_B, TextColor3 = rgb(236, 230, 255) })
    F.Label(s, { Position = off(26, 50), Size = off(560, 22), Text = "Размер интерфейса, автосохранение при выходе и профили настроек", TextSize = 13.5, TextColor3 = C.txt2 })

    local LX, RX, COLW = 26, 422, 372
    local L = F.newColumn(s, LX, 90, COLW)
    local R = F.newColumn(s, RX, 90, COLW)

    -- ЛЕВАЯ КОЛОНКА: Размер меню и автосохранение
    L:header("Размер и вид меню", "sliders", "Под любой экран")

    local sizeVals = { 0.75, 1.0, 1.25 }
    local initPreset = (State.menuScale <= 0.85 and 1) or (State.menuScale >= 1.15 and 3) or 2
    L:segment(nil, "Быстрый размер", { "Маленькое", "Среднее", "Большое" }, initPreset, function(i)
        local v = sizeVals[i]
        State.menuScale = v
        if F.sliders.menuScale then F.sliders.menuScale.set(v) end
        F.applyScale(v)
        F.toast("Размер меню: " .. string.format("%.2fx", v), "sliders")
    end)

    L:slider("menuScale", "Масштаб меню (точнее)", "Уменьшай или увеличивай окно как удобно", {
        min = 0.55, max = 1.45, step = 0.05,
        fmt = function(v) return string.format("%.2fx", v) end,
        onChange = function(v) F.applyScale(v) end,
    })

    L:slider("panelOpacity", "Непрозрачность панели", "Чем меньше, тем лучше видно игру за меню", {
        min = 40, max = 100, step = 2,
        fmt = function(v) return string.format("%d%%", v) end,
        onChange = function(v) F.applyOpac(v) end,
    })

    L:header("Сохранение", "save", "Авто + сброс", 12)
    L:toggle("autoSave", "Автосохранение", "Сохраняет все настройки автоматически и при выходе", function(v)
        if v then F.saveAuto(); F.toast("Автосохранение включено", "save") end
    end)

    L:button("Сохранить сейчас", "save", "primary", function()
        F.saveAuto()
        F.toast("Текущие настройки сохранены", "save")
    end)

    L:button("Сбросить все настройки", "undo", "ghost", function()
        F.resetAllToDefaults()
        F.toast("Все настройки сброшены", "undo")
    end, { sep = false })

    -- ПРАВАЯ КОЛОНКА: Менеджер конфигов
    R:header("Создать конфиг", "folder", "JSON профили")
    local nameRow = R:row(58, { sep = false })
    local _, cfgNameBox = F.Input(nameRow, 0, 4, COLW, 46, "pencil", "Название конфига (например: my_cfg)", 14)

    local listContainer = F.Frame(R.holder, { Name = "CfgList", BackgroundTransparency = 1, Position = off(0, 0), Size = off(COLW, 10) })
    local rebuildList

    R:button("Сохранить как новый конфиг", "save", "primary", function()
        local ok, res = F.saveConfig(cfgNameBox.Text)
        if ok then
            cfgNameBox.Text = ""
            rebuildList()
            F.toast('Конфиг "' .. res .. '" сохранён', "save")
        else
            F.toast(res, "x")
        end
    end)

    R:header("Сохранённые конфиги", "folder", "Загрузка в 1 клик", 12)
    local listStartY = R.y
    listContainer.Position = off(0, listStartY)

    rebuildList = function()
        for _, ch in ipairs(listContainer:GetChildren()) do ch:Destroy() end
        local names = F.listConfigs()
        local y = 0
        if #names == 0 then
            F.Label(listContainer, { Position = off(0, 4), Size = off(COLW, 24), Text = "Пока нет сохранённых конфигов", TextSize = 13, TextColor3 = C.txt3, Font = F.FONT_R })
            y = 34
        else
            for _, cname in ipairs(names) do
                local item = F.Frame(listContainer, { Position = off(0, y), Size = off(COLW, 54), BackgroundColor3 = C.panel, BackgroundTransparency = 0.45 })
                F.Corner(item, 14); F.Stroke(item, C.white, 0.88, 1)

                F.Label(item, { Position = off(14, 0), Size = off(COLW - 188, 54), Text = cname, TextSize = 14.5, Font = F.FONT_B, ClipsDescendants = true })

                F.MakeButton(item, COLW - 168, 9, 78, 36, "Загр.", nil, "primary", function()
                    if F.loadConfig(cname) then
                        F.toast('Загружен "' .. cname .. '"', "check")
                    else
                        F.toast("Ошибка чтения конфига", "x")
                    end
                end)
                F.MakeButton(item, COLW - 84, 9, 36, 36, "", "save", "ghost", function()
                    F.saveConfig(cname)
                    F.toast('Обновлён "' .. cname .. '"', "save")
                end)
                F.MakeButton(item, COLW - 42, 9, 36, 36, "", "trash", "danger", function()
                    F.deleteConfig(cname)
                    rebuildList()
                    F.toast('Удалён "' .. cname .. '"', "trash")
                end)
                y = y + 62
            end
        end
        listContainer.Size = off(COLW, y)
        page.setHeight(math.max(L.y, listStartY + y) + 32)
    end

    rebuildList()
end

----------------------------------------------------------------------
-- 3D-ИНТРО БУКВЫ "F" (С ЗАЩИТОЙ ОТ СБОЕВ)
----------------------------------------------------------------------
function F.RunIntro3DF(orb, orbScale, getOrbTargetPos)
    local function ensureOrbVisible()
        if not orb.Visible then
            orb.Visible = true
            orbScale.Scale = F.baseScale() * 0.25
            F.tw(orbScale, 0.55, { Scale = F.baseScale() }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            F.toast("Finis Visual готов — нажми на шар F", "sparkle")
        end
    end

    task.delay(3.4, ensureOrbVisible)

    task.spawn(function()
        local ok = pcall(function()
            local DimOverlay = F.Frame(gui, { Name = "IntroDim", Size = sc(1, 1), BackgroundColor3 = rgb(6, 7, 16), BackgroundTransparency = 1, ZIndex = 48 })
            local IntroVP = F.New("ViewportFrame", {
                Name = "Intro3DF", Size = sc(1, 1), BackgroundTransparency = 1,
                Ambient = rgb(160, 168, 210), LightColor = C.white, LightDirection = Vector3.new(-1, -1, 1), ZIndex = 50,
            }, gui)

            local IntroWorld = F.New("WorldModel", {}, IntroVP)
            local IntroCam = F.New("Camera", { FieldOfView = 42, CFrame = CFrame.lookAt(Vector3.new(0, 0, -13.5), Vector3.zero) }, IntroVP)
            IntroVP.CurrentCamera = IntroCam

            local introBars = {}
            local function Create3DBar(w, h, targetCF, startCF)
                local rim  = F.New("Part", { Size = Vector3.new(w, h, 0.58), Color = rgb(225, 222, 255), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
                local face = F.New("Part", { Size = Vector3.new(w - 0.14, h - 0.14, 0.10), Color = rgb(118, 114, 178), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
                local back = F.New("Part", { Size = Vector3.new(w - 0.14, h - 0.14, 0.10), Color = rgb(118, 114, 178), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
                table.insert(introBars, { rim = rim, face = face, back = back, target = targetCF, start = startCF })
            end

            Create3DBar(0.88, 4.30, CFrame.new(1.15, 0.0, 0),  CFrame.new(5.8, -3.5, 4.0) * CFrame.Angles(1.2, -1.6, 0.8))
            Create3DBar(2.95, 0.88, CFrame.new(-0.35, 1.71, 0), CFrame.new(-5.5, 4.8, 3.0) * CFrame.Angles(-1.4, 1.3, -0.9))
            Create3DBar(2.35, 0.84, CFrame.new(-0.05, 0.08, 0), CFrame.new(-6.2, -2.8, -2.5) * CFrame.Angles(0.9, 1.8, 0.7))

            local function PlaceBar(bar, worldCF)
                bar.rim.CFrame  = worldCF
                bar.face.CFrame = worldCF * CFrame.new(0, 0, -0.26)
                bar.back.CFrame = worldCF * CFrame.new(0, 0, 0.26)
            end
            local function EaseOutBack(x) local c1 = 1.45; return 1 + (c1 + 1) * ((x - 1) ^ 3) + c1 * ((x - 1) ^ 2) end
            local function EaseInOutCubic(x) return x < 0.5 and 4 * x ^ 3 or 1 - ((-2 * x + 2) ^ 3) / 2 end
            local function ScreenToWorldPos(sx, sy, pxH, W, H)
                local halfTan = math.tan(math.rad(IntroCam.FieldOfView * 0.5))
                local dist = (4.3 * H) / (2 * math.max(pxH, 1) * halfTan)
                local halfH = dist * halfTan
                local halfW = halfH * (W / math.max(H, 1))
                local nx, ny = (sx / math.max(W, 1)) * 2 - 1, 1 - (sy / math.max(H, 1)) * 2
                local cf = IntroCam.CFrame
                return cf.Position + cf.LookVector * dist + cf.RightVector * (nx * halfW) + cf.UpVector * (ny * halfH)
            end

            RunService.RenderStepped:Wait()
            RunService.RenderStepped:Wait()
            F.tw(DimOverlay, 0.35, { BackgroundTransparency = 0.52 })

            local startClock = os.clock()
            local baseTilt = CFrame.Angles(0, 0, math.rad(-22))
            local faceBase, faceFlash = rgb(118, 114, 178), rgb(248, 246, 255)
            local dimCleared = false

            local introConn
            introConn = F.bind(RunService.RenderStepped, function()
                local elapsed = os.clock() - startClock

                if elapsed < 0.90 then
                    for i, bar in ipairs(introBars) do
                        local alpha = math.clamp((elapsed - (i - 1) * 0.10) / 0.65, 0, 1)
                        PlaceBar(bar, baseTilt * bar.start:Lerp(bar.target, EaseOutBack(alpha)))
                    end
                elseif elapsed < 1.90 then
                    local t = (elapsed - 0.90) / 1.0
                    local hoverCF = baseTilt * CFrame.Angles(math.sin(t * math.pi) * 0.08, math.sin(t * math.pi * 2) * 0.14, 0)
                    local sheen = 0
                    if elapsed > 1.12 and elapsed < 1.78 then
                        local p = (elapsed - 1.12) / 0.66
                        sheen = math.sin(p * math.pi)
                        IntroVP.LightDirection = Vector3.new(-2 + p * 4, -1.5 + p * 2.5, 1)
                    end
                    IntroVP.Ambient = rgb(160, 168, 210):Lerp(C.white, sheen * 0.9)
                    for _, bar in ipairs(introBars) do
                        PlaceBar(bar, hoverCF * bar.target)
                        bar.face.Color = faceBase:Lerp(faceFlash, sheen * 0.92)
                    end
                elseif elapsed < 2.65 then
                    local p = math.clamp((elapsed - 1.90) / 0.75, 0, 1)
                    local e = EaseInOutCubic(p)
                    if not dimCleared then dimCleared = true; F.tw(DimOverlay, 0.45, { BackgroundTransparency = 1 }) end

                    local scr = F.viewport()
                    local W, H = scr.X, scr.Y
                    local targetUDim, targetPxPos = getOrbTargetPos()
                    orb.Position = targetUDim

                    local halfTan = math.tan(math.rad(IntroCam.FieldOfView * 0.5))
                    local startPx = (4.3 * H) / (2 * 13.5 * halfTan)
                    local targetPx = 28 * F.baseScale()

                    local curX = (W * 0.5) + (targetPxPos.X - W * 0.5) * e
                    local curY = (H * 0.5) + (targetPxPos.Y - H * 0.5) * e - math.sin(p * math.pi) * (35 * F.baseScale())
                    local curPx = startPx + (targetPx - startPx) * e

                    local worldPos = ScreenToWorldPos(curX, curY, curPx, W, H)
                    local worldCF = CFrame.new(worldPos) * CFrame.Angles(0, math.sin(p * math.pi) * 1.1, math.rad(-22 + 6 * e))

                    local fade = math.clamp((p - 0.91) / 0.09, 0, 1)
                    for _, bar in ipairs(introBars) do
                        PlaceBar(bar, worldCF * bar.target)
                        bar.rim.Transparency = fade; bar.face.Transparency = fade; bar.back.Transparency = fade
                    end

                    if p >= 0.91 then ensureOrbVisible() end
                else
                    introConn:Disconnect()
                    ensureOrbVisible()
                    pcall(function() IntroVP:Destroy() end)
                    pcall(function() DimOverlay:Destroy() end)
                end
            end)
        end)
        if not ok then ensureOrbVisible() end
    end)
end

----------------------------------------------------------------------
-- ОБОЛОЧКА МЕНЮ (2 ВКЛАДКИ: ВИЗУАЛ + КОНФИГИ)
----------------------------------------------------------------------
local function BuildShell()
    local Quint, Quad, Back = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back
    local Out, In, InOut = Enum.EasingDirection.Out, Enum.EasingDirection.In, Enum.EasingDirection.InOut
    local WIN_W, WIN_H, SIDE_W, HEAD_H, PAGE_W, PAGE_H, CARD_W, CARD_H = 1020, 620, 173, 80, 847, 540, 495, 442

    -- тосты
    local toastHost = F.Frame(gui, { Name = "Toasts", BackgroundTransparency = 1, Size = sc(1, 1), ZIndex = 60 })
    local curToast
    function F.toast(text, iconName)
        if curToast then pcall(function() curToast:Destroy() end) end
        local w = F.measure(text, 15, F.FONT_M) + 84
        local pill = F.Frame(toastHost, {
            Name = "Toast", AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, -0.14, 0),
            Size = off(w, 46), BackgroundColor3 = rgb(15, 14, 32), BackgroundTransparency = 0.1,
        })
        curToast = pill
        F.Corner(pill, "full"); F.Stroke(pill, C.white, 0.86, 1)
        F.New("UIScale", { Scale = F.baseScale() }, pill)
        local ic = F.Frame(pill, { Position = off(9, 9), Size = off(28, 28), BackgroundColor3 = rgb(150, 140, 235), BackgroundTransparency = 0.68 })
        F.Corner(ic, "full"); F.Icon(ic, iconName or "check", 14, rgb(214, 206, 255), { Position = off(7, 7) })
        F.Label(pill, { Position = off(48, 0), Size = off(w - 60, 44), Text = text, TextSize = 15 })
        local bar = F.Frame(pill, { Position = off(48, 40), Size = off(w - 70, 2) })
        F.Corner(bar, "full"); F.accent(bar, 0)
        F.tw(pill, 0.5, { Position = UDim2.new(0.5, 0, 0.035, 0) }, Back, Out)
        TweenService:Create(bar, TweenInfo.new(1.7, Enum.EasingStyle.Linear), { Size = off(0, 2) }):Play()
        task.delay(1.85, function()
            if curToast == pill then
                F.tw(pill, 0.35, { Position = UDim2.new(0.5, 0, -0.14, 0) }, Quint, In)
                task.delay(0.4, function() pcall(function() pill:Destroy() end); if curToast == pill then curToast = nil end end)
            end
        end)
    end

    local function curScale() return F.baseScale() * State.menuScale end
    local winOpen, cardOpen, authed = false, false, false

    local topbarWas
    local function syncTopbar()
        local want = winOpen or cardOpen
        pcall(function()
            if want then
                if topbarWas == nil then topbarWas = StarterGui:GetCore("TopbarEnabled") end
                StarterGui:SetCore("TopbarEnabled", false)
            elseif topbarWas ~= nil then
                StarterGui:SetCore("TopbarEnabled", topbarWas)
                topbarWas = nil
            end
        end)
    end
    F.onCleanup(function() winOpen = false; cardOpen = false; syncTopbar() end)

    -- Шар Orb с логотипом F
    local ORB = 74
    local function getOrbTargetPos()
        local scr = F.viewport()
        local rad = (ORB * F.baseScale()) * 0.5
        local px = math.max(scr.X * 0.055, rad + 16)
        local py = math.min(scr.Y * 0.87, scr.Y - rad - 16)
        return UDim2.fromScale(px / scr.X, py / scr.Y), V2(px, py)
    end

    local orb = F.Frame(gui, {
        Name = "Orb", AnchorPoint = V2(0.5, 0.5), Position = getOrbTargetPos(),
        Size = off(ORB, ORB), BackgroundColor3 = C.white, BackgroundTransparency = 0.1, Visible = false, ZIndex = 20,
    })
    F.Corner(orb, "full"); F.Grad(orb, rgb(88, 78, 152), rgb(30, 27, 60), 135); F.Stroke(orb, rgb(190, 180, 255), 0.7, 1.5)
    local orbScale = F.New("UIScale", { Scale = 0.01 }, orb)
    local arc = F.Frame(orb, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(ORB + 2, ORB + 2), BackgroundTransparency = 1 })
    F.Corner(arc, "full")
    local arcGrad = F.New("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.26, 0.55), NumberSequenceKeypoint.new(0.34, 1), NumberSequenceKeypoint.new(1, 1) }),
    }, F.Stroke(arc, rgb(232, 224, 255), 0, 2.4))
    F.makeLogoF(orb, 32, false, false).Position = off((ORB - 48) / 2, (ORB - 32) / 2)
    local orbBtn = F.Button(orb, { ZIndex = 5 })

    local function snapOrb()
        local scr = F.viewport()
        local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
        local goalX = ((a.X + sz.X / 2) < scr.X / 2) and (sz.X / 2 + 14) or (scr.X - sz.X / 2 - 14)
        local cy = math.clamp(a.Y + sz.Y / 2, sz.Y / 2 + 10, scr.Y - sz.Y / 2 - 10)
        F.tw(orb, 0.45, { Position = UDim2.fromScale(goalX / scr.X, cy / scr.Y) }, Back, Out)
    end

    orbBtn.InputBegan:Connect(function(input)
        if not F.isPress(input) then return end
        local startPos = input.Position
        local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
        local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
        local moved = false
        F.tw(orbScale, 0.12, { Scale = F.baseScale() * 0.9 }, Quad, Out)
        F.beginDrag(function(i)
            local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
            if not moved and (math.abs(dx) + math.abs(dy)) > 8 then moved = true end
            if moved then
                local scr = F.viewport()
                orb.Position = UDim2.fromScale(math.clamp((startCenter.X + dx) / scr.X, 0.02, 0.98), math.clamp((startCenter.Y + dy) / scr.Y, 0.04, 0.96))
            end
        end, function()
            F.tw(orbScale, 0.12, { Scale = F.baseScale() }, Quad, Out)
            if moved then snapOrb() else F.orbTap() end
        end)
    end)

    -- Главное окно
    local winBaseT = (1 - State.panelOpacity / 100) * 0.9 + 0.025
    local win = F.Frame(gui, {
        Name = "Window", AnchorPoint = V2(0.5, 0.5), Position = F.homeCenter(), Size = off(WIN_W, WIN_H),
        BackgroundColor3 = C.white, BackgroundTransparency = winBaseT, Visible = false,
        ClipsDescendants = true, Active = true, ZIndex = 12,
    })
    F.Corner(win, 28); F.Grad(win, rgb(86, 82, 146), rgb(32, 28, 64), 120)
    local winStroke = F.Stroke(win, C.white, 0.35, 1.5)
    F.New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.35, 0.62), NumberSequenceKeypoint.new(1, 0.82) }) }, winStroke)
    local winScale = F.New("UIScale", { Scale = 1 }, win)

    local particleLayer = F.Frame(win, { Name = "Particles", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ClipsDescendants = true, ZIndex = 1 })
    local body = F.Frame(win, { Name = "Body", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ZIndex = 2 })
    local fx   = F.Frame(win, { Name = "Fx", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ZIndex = 30 })

    -- Шапка окна
    local header = F.Frame(body, { Name = "Header", BackgroundTransparency = 1, Size = off(WIN_W, HEAD_H) })
    local headDrag = F.Button(header, { Name = "DragHandle", Size = off(WIN_W, HEAD_H), ZIndex = 1 })
    local hLogo = F.makeLogoF(header, 40, true, true); hLogo.Position = off(14, 19); hLogo.ZIndex = 2
    local hTitle = F.Label(header, { Position = off(83, 13), Size = off(220, 32), Text = "Finis Visual", TextSize = 25, Font = F.FONT_B, ZIndex = 2 })
    F.Grad(hTitle, rgb(255, 250, 255), rgb(212, 190, 255), 0)
    F.Label(header, { Position = off(84, 46), Size = off(240, 14), Text = "FINIS VISUAL  ·  ROBLOX", TextSize = 9.5, TextColor3 = C.txt4, ZIndex = 2 })

    local searchWrap, searchBox = F.Input(header, 320, 21, 355, 38, "search", "Поиск...", 14)
    searchWrap.ZIndex = 3
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(F.trim(searchBox.Text))
        for _, item in ipairs(F.searchItems) do
            if item.row and item.row.Parent then
                item.row.Visible = (q == "" or string.find(item.text, q, 1, true) ~= nil)
            end
        end
    end)

    local closeBtn
    do
        local pill = F.Frame(header, { Position = off(WIN_W - 22 - 36 - 12 - 36 - 12 - 116, 26), Size = off(116, 28), BackgroundTransparency = 0.93, ZIndex = 3 })
        F.Corner(pill, "full"); F.Stroke(pill, C.white, 0.88, 1)
        F.Corner(F.Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(14, 14), BackgroundColor3 = C.green, BackgroundTransparency = 0.75 }), "full")
        F.Corner(F.Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(8, 8), BackgroundColor3 = C.green }), "full")
        F.Label(pill, { Position = off(31, 0), Size = off(82, 28), Text = "Подключено", TextSize = 12.5 })

        local avFrame = F.Frame(header, { Position = off(WIN_W - 22 - 36 - 12 - 36, 22), Size = off(36, 36), BackgroundColor3 = rgb(24, 22, 48), BackgroundTransparency = 0.2, ZIndex = 3 })
        F.Corner(avFrame, "full"); F.Stroke(avFrame, C.a, 0.4, 1.4)
        local avImg = F.New("ImageLabel", { Size = sc(1, 1), BackgroundTransparency = 1, Image = "", ZIndex = 4 }, avFrame)
        F.Corner(avImg, "full")
        task.spawn(function()
            local ok, thumb = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and thumb then avImg.Image = thumb end
        end)

        local x = F.Frame(header, { Position = off(WIN_W - 22 - 36, 22), Size = off(36, 36), BackgroundTransparency = 0.93, ZIndex = 3 })
        F.Corner(x, "full"); F.Stroke(x, C.white, 0.88, 1); F.Icon(x, "x", 14, rgb(214, 214, 238), { Position = off(11, 11) })
        closeBtn = F.Button(x, { ZIndex = 4 }); F.addPress(closeBtn, x, 0.9)
    end
    F.Frame(body, { Position = off(0, HEAD_H - 1), Size = off(WIN_W, 1), BackgroundTransparency = 0.92 })

    -- Боковая панель (2 вкладки: Визуал и Конфиги)
    local side = F.Frame(body, { Name = "Sidebar", BackgroundTransparency = 1, Position = off(0, HEAD_H), Size = off(SIDE_W, PAGE_H) })
    F.Frame(body, { Position = off(SIDE_W - 1, HEAD_H), Size = off(1, PAGE_H), BackgroundTransparency = 0.93 })
    F.Label(side, { Position = off(20, PAGE_H - 36), Size = off(150, 14), Text = "FINIS VISUAL  ·  v2.2", TextSize = 9.5, TextColor3 = C.txt4 })

    local NAV = {
        { id = "visual",  title = "Визуал",  icon = "eye" },
        { id = "configs", title = "Конфиги", icon = "folder" },
    }
    local selPill = F.Frame(side, { Position = off(8, 13), Size = off(155, 50), BackgroundTransparency = 0.9 })
    F.Corner(selPill, 16); F.Stroke(selPill, C.white, 0.82, 1)
    F.Corner(F.Frame(selPill, { Position = off(3, 16), Size = off(3, 18), BackgroundColor3 = C.b }), "full")

    local pageHost = F.Frame(body, { Name = "Pages", BackgroundTransparency = 1, Position = off(SIDE_W, HEAD_H), Size = off(PAGE_W, PAGE_H), ClipsDescendants = true })
    local Pages, navBtns, currentTab = {}, {}, "visual"

    local function createPage(id)
        local holder = F.Frame(pageHost, { Name = "Page_" .. id, BackgroundTransparency = 1, Size = off(PAGE_W, PAGE_H), Visible = (id == "visual") })
        local scroller = F.New("ScrollingFrame", {
            Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = off(PAGE_W, PAGE_H),
            CanvasSize = off(0, PAGE_H), ScrollBarThickness = 3, ScrollBarImageColor3 = rgb(206, 196, 255),
            ScrollBarImageTransparency = 0.45, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = false,
        }, holder)
        Pages[id] = { holder = holder, scroller = scroller, setHeight = function(h) scroller.CanvasSize = off(0, math.max(h, PAGE_H)) end }
        return Pages[id]
    end

    local Scroll = { blocked = false, active = false, moved = false, startY = 0, baseY = 0, lastY = 0, lastT = 0, vel = 0, coast = 0 }
    local function curScroller() return Pages[currentTab] and Pages[currentTab].scroller end
    local function setScrollY(y)
        local sc_ = curScroller()
        if not sc_ then return 0 end
        y = math.clamp(y, 0, math.max(0, sc_.CanvasSize.Y.Offset - PAGE_H))
        sc_.CanvasPosition = V2(0, y)
        return y
    end
    function F.scrollLock(locked) Scroll.blocked = locked end

    local function switchTab(id)
        if currentTab == id then return end
        currentTab = id; Scroll.coast = 0
        for tabId, pg in pairs(Pages) do pg.holder.Visible = (tabId == id) end
        for tabId, it in pairs(navBtns) do
            local on = (tabId == id)
            F.setIconColor(it.icon, on and rgb(206, 196, 255) or rgb(160, 162, 196), false)
            F.tw(it.label, 0.2, { TextColor3 = on and C.white or rgb(182, 183, 211) })
            if on then F.tw(selPill, 0.3, { Position = off(8, it.y) }, Quint, Out) end
        end
    end

    for i, item in ipairs(NAV) do
        local y = 13 + (i - 1) * 56
        local on = (item.id == "visual")
        local ic = F.Icon(side, item.icon, 18, on and rgb(206, 196, 255) or rgb(160, 162, 196), { Position = off(30, y + 16) })
        local lb = F.Label(side, { Position = off(63, y), Size = off(100, 50), Text = item.title, TextSize = 16, TextColor3 = on and C.white or rgb(182, 183, 211) })
        local b = F.Button(side, { Position = off(8, y), Size = off(155, 50), ZIndex = 3 })
        navBtns[item.id] = { icon = ic, label = lb, y = y }
        b.Activated:Connect(function() if not F.scrolled then switchTab(item.id) end end)
    end

    -- Инерционный скролл
    local function insidePage(pos)
        local a, s_ = pageHost.AbsolutePosition, pageHost.AbsoluteSize
        local inset = GuiService:GetGuiInset()
        local function hit(y) return pos.X >= a.X and pos.X <= a.X + s_.X and y >= a.Y and y <= a.Y + s_.Y end
        return hit(pos.Y) or hit(pos.Y + inset.Y)
    end

    F.bind(UserInputService.InputBegan, function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if not winOpen or Scroll.blocked or not insidePage(input.Position) then return end
        local sc_ = curScroller(); if not sc_ then return end
        Scroll.active, Scroll.moved = true, false
        Scroll.startY, Scroll.lastY, Scroll.lastT = input.Position.Y, input.Position.Y, os.clock()
        Scroll.vel, Scroll.coast, Scroll.baseY = 0, 0, sc_.CanvasPosition.Y
    end)

    F.bind(UserInputService.InputChanged, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseWheel then
            local sc_ = curScroller()
            if winOpen and sc_ and not Scroll.blocked then Scroll.coast = 0; setScrollY(sc_.CanvasPosition.Y - input.Position.Z * 80) end
            return
        end
        if not Scroll.active or (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement) then return end
        if Scroll.blocked then Scroll.active = false; return end
        local k = math.max(0.05, winScale.Scale)
        if not Scroll.moved then
            if math.abs(input.Position.Y - Scroll.startY) < 10 * k then return end
            Scroll.moved = true; F.scrolled = true
            local sc_ = curScroller()
            Scroll.startY, Scroll.baseY, Scroll.lastY, Scroll.lastT = input.Position.Y, sc_ and sc_.CanvasPosition.Y or 0, input.Position.Y, os.clock()
            return
        end
        local now = os.clock()
        setScrollY(Scroll.baseY - (input.Position.Y - Scroll.startY) / k)
        local dt = now - Scroll.lastT
        if dt > 0.001 then Scroll.vel = Scroll.vel * 0.6 + (-(input.Position.Y - Scroll.lastY) / k / dt) * 0.4 end
        Scroll.lastY, Scroll.lastT = input.Position.Y, now
    end)

    F.bind(UserInputService.InputEnded, function(input)
        local t = input.UserInputType
        if (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) or not Scroll.active then return end
        Scroll.active = false
        if Scroll.moved then
            Scroll.coast = (os.clock() - Scroll.lastT > 0.08) and 0 or Scroll.vel
            task.delay(0.12, function() F.scrolled = false end)
        else F.scrolled = false end
    end)

    -- Собираем обе вкладки
    table.clear(F.searchItems)
    F.BuildVisualPage(createPage("visual"), function() return winOpen end)
    F.BuildConfigPage(createPage("configs"))
    -- применяем сохранённые шейдеры после автозагрузки
    F.ApplySavedShaders()

    -- Уголок масштаба + частицы
    local grip = F.Button(body, { Position = off(WIN_W - 34, WIN_H - 34), Size = off(30, 30), ZIndex = 5 })
    for r = 0, 2 do for c = 0, 2 - r do F.Corner(F.Frame(grip, { Position = off(20 - c*6, 20 - r*6), Size = off(2.5, 2.5), BackgroundTransparency = 0.55 }), "full") end end

    local PN, P = 28, {}
    for i = 1, PN do
        local sz = 2 + math.random() * 2.4
        local f = F.Frame(particleLayer, { Size = off(sz, sz), BackgroundColor3 = rgb(212, 204, 255), BackgroundTransparency = 0.6 })
        F.Corner(f, "full")
        P[i] = { f = f, x = math.random(30, WIN_W-30), y = math.random(30, WIN_H-30), vy = 5 + math.random()*12, vx = (math.random()-0.5)*8, ph = math.random()*6.28 }
        f.Position = off(P[i].x, P[i].y)
    end

    local function burst(host, x, y, n, spread)
        for _ = 1, n do
            local d = F.Frame(host, { AnchorPoint = V2(0.5, 0.5), Position = off(x, y), Size = off(5, 5), BackgroundColor3 = C.a, BackgroundTransparency = 0.1 })
            F.Corner(d, "full")
            local ang, dist = math.random() * 6.283, spread * (0.5 + math.random() * 0.8)
            F.tw(d, 0.55, { Position = off(x + math.cos(ang)*dist, y + math.sin(ang)*dist), BackgroundTransparency = 1, Size = off(2, 2) }, Quint, Out)
            task.delay(0.6, function() d:Destroy() end)
        end
    end
    function F.pressFx(obj)
        if not winOpen then return end
        local a, sz, k = obj.AbsolutePosition, obj.AbsoluteSize, math.max(0.05, winScale.Scale)
        local fa = fx.AbsolutePosition
        burst(fx, (a.X + sz.X / 2 - fa.X) / k, (a.Y + sz.Y / 2 - fa.Y) / k, 6, 28)
    end

    local cardFrame
    local function applyScales()
        if winOpen then winScale.Scale = curScale() end
        if cardFrame and cardOpen then cardFrame.UIScale.Scale = curScale() end
        if orb.Visible then orbScale.Scale = F.baseScale() end
    end
    function F.applyScale(v)
        State.menuScale = math.clamp(v, 0.55, 1.45)
        applyScales()
    end
    function F.applyOpac(v)
        State.panelOpacity = math.clamp(v, 40, 100)
        winBaseT = (1 - State.panelOpacity / 100) * 0.9 + 0.025
        F.tw(win, 0.2, { BackgroundTransparency = winBaseT })
    end

    local function makeDraggable(target, handle, hooks)
        handle.InputBegan:Connect(function(input)
            if not F.isPress(input) then return end
            local startPos = input.Position
            local a, sz = target.AbsolutePosition, target.AbsoluteSize
            local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
            local moved = false
            F.beginDrag(function(i)
                local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
                if not moved and (math.abs(dx) + math.abs(dy)) > 6 then moved = true; if hooks and hooks.moved then hooks.moved() end end
                if moved then
                    local scr = F.viewport()
                    target.Position = UDim2.fromScale(
                        math.clamp(startCenter.X + dx, sz.X * 0.25, scr.X - sz.X * 0.25) / scr.X,
                        math.clamp(startCenter.Y + dy, math.min(sz.Y / 2, scr.Y / 2), scr.Y - 60) / scr.Y)
                end
            end, function() if hooks and hooks.ended then hooks.ended(moved) end end)
        end)
    end

    local winHome = F.homeCenter()
    makeDraggable(win, headDrag, {
        moved = function() F.tw(win, 0.2, { BackgroundTransparency = math.min(1, winBaseT + 0.14) }) end,
        ended = function(moved) if moved then winHome = win.Position; F.tw(win, 0.3, { BackgroundTransparency = winBaseT }) end end,
    })

    grip.InputBegan:Connect(function(input)
        if not F.isPress(input) then return end
        local startPos, startScale = input.Position, State.menuScale
        F.scrollLock(true)
        F.beginDrag(function(i)
            local d = ((i.Position.X - startPos.X) + (i.Position.Y - startPos.Y)) / 2
            local v = math.floor(math.clamp(startScale + d / (WIN_W * curScale()), 0.55, 1.45) * 20 + 0.5) / 20
            F.applyScale(v)
            if F.sliders.menuScale then F.sliders.menuScale.set(v) end
        end, function()
            F.scrollLock(false)
            if State.autoSave then F.scheduleAutoSave() end
        end)
    end)

    local function openWindow()
        if winOpen then return end
        winOpen = true; win.Visible = true
        win.Size = off(WIN_W, WIN_H); winScale.Scale = curScale() * 0.12; win.Position = orb.Position
        F.tw(winScale, 0.4, { Scale = curScale() }, Back, Out)
        F.tw(win, 0.4, { Position = winHome }, Quint, Out)
        syncTopbar()
    end
    local function closeWindow()
        if not winOpen then return end
        winOpen = false; winHome = win.Position
        F.tw(winScale, 0.28, { Scale = curScale() * 0.12 }, Quint, In)
        F.tw(win, 0.28, { Position = orb.Position }, Quint, In)
        task.delay(0.3, function() if not winOpen then win.Visible = false end end)
        syncTopbar()
    end
    closeBtn.Activated:Connect(function() if not F.scrolled then closeWindow() end end)

    -- Карточка ввода ключа (@FinisOkek)
    local spinners = {}
    local card = F.Frame(gui, {
        Name = "KeyCard", AnchorPoint = V2(0.5, 0.5), Position = F.homeCenter(), Size = off(CARD_W, CARD_H),
        BackgroundColor3 = C.white, BackgroundTransparency = 0.1, Visible = false, Active = true, ZIndex = 10,
    })
    cardFrame = card
    F.Corner(card, 34); F.Grad(card, rgb(70, 66, 122), rgb(24, 22, 50), 120)
    F.New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.4, 0.62), NumberSequenceKeypoint.new(1, 0.8) }) }, F.Stroke(card, C.white, 0.35, 1.5))
    local cardScale = F.New("UIScale", { Scale = 1 }, card)
    local cardDrag = F.Button(card, { ZIndex = 1 })
    local cardBody = F.Group(card, { Size = sc(1, 1), ZIndex = 2 })

    F.makeLogoF(cardBody, 78, true, true).Position = off((CARD_W - 117) / 2, 36)
    local kTitle = F.Label(cardBody, { Position = off(0, 148), Size = off(CARD_W, 38), Text = "Finis Visual", TextSize = 32, Font = F.FONT_B, TextXAlignment = Enum.TextXAlignment.Center })
    F.Grad(kTitle, rgb(255, 250, 255), rgb(214, 192, 255), 0)
    F.Label(cardBody, { Position = off(0, 194), Size = off(CARD_W, 22), Text = "Введи ключ, чтобы продолжить", TextSize = 15, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Center })
    local inRoot, keyBox, inStroke, inIcon = F.Input(card, 35, 232, 425, 58, "key", "Ваш ключ", 18)
    inRoot.ZIndex = 3
    local function setInputAlpha(a)
        inRoot.BackgroundTransparency = 1 - 0.55 * a; inStroke.Transparency = 1 - 0.1 * a
        keyBox.TextTransparency = 1 - a; keyBox.PlaceholderText = (a > 0.6) and "Ваш ключ" or ""
        F.setIconAlpha(inIcon, a)
    end
    F.Label(cardBody, { Position = off(0, 396), Size = off(CARD_W, 16), Text = "FINIS VISUAL  ·  v2.2", TextSize = 9.5, TextColor3 = C.txt4, TextXAlignment = Enum.TextXAlignment.Center })

    local pasteWrap = F.Group(cardBody, { Position = off(35, 306), Size = off(141, 52) })
    F.MakeButton(pasteWrap, 0, 0, 141, 52, "Вставить", "clipboard", "ghost", function()
        local txt
        if type(getclipboard) == "function" then local ok, r = pcall(getclipboard); if ok and type(r) == "string" then txt = F.trim(r) end end
        if txt and txt ~= "" then keyBox.Text = txt; F.toast("Вставлено", "clipboard"); burst(inRoot, 396, 29, 9, 26)
        else F.toast("Буфер обмена пуст", "clipboard") end
    end)

    local login = F.Frame(cardBody, { Position = off(188, 306), Size = off(272, 52), BackgroundColor3 = C.white })
    F.Corner(login, 16); F.accent(login, 0)
    local lc = F.Group(login, { Size = sc(1, 1) })
    do
        local lw = F.measure("Войти", 16, F.FONT_B)
        local lx = (272 - (lw + 26)) / 2
        F.Label(lc, { Position = off(lx, 0), Size = off(lw + 6, 52), Text = "Войти", TextSize = 16, Font = F.FONT_B, TextColor3 = C.dark })
        F.Icon(lc, "arrow", 16, C.dark, { Position = off(lx + lw + 12, 18) })
    end
    local spin = F.Frame(login, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(24, 24), BackgroundTransparency = 1, Visible = false })
    F.Corner(spin, "full")
    spinners[#spinners + 1] = F.New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(0.68, 1), NumberSequenceKeypoint.new(1, 1) }) }, F.Stroke(spin, C.dark, 0, 2.6))
    local chk = F.Icon(login, "check", 26, C.dark, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Visible = false })
    local chkScale = F.New("UIScale", {}, chk)
    local loginBtn = F.Button(login, { ZIndex = 4 }); F.addPress(loginBtn, login, 0.97)

    local cardHome, cardMoved, busy = F.homeCenter(), false, false
    local function orbCenterPos()
        local scr, a, sz = F.viewport(), orb.AbsolutePosition, orb.AbsoluteSize
        return UDim2.fromScale((a.X + sz.X / 2) / scr.X, (a.Y + sz.Y / 2) / scr.Y)
    end
    local function openCard()
        if cardOpen then return end
        cardOpen = true; syncTopbar(); card.Visible = true
        cardScale.Scale = curScale() * 0.18; card.Position = orbCenterPos(); card.BackgroundTransparency = 0.7
        if not cardMoved then cardHome = F.homeCenter() end
        cardBody.GroupTransparency = 0.97; setInputAlpha(0)
        F.tw(cardScale, 0.58, { Scale = curScale() }, Back, Out)
        F.tw(card, 0.52, { Position = cardHome, BackgroundTransparency = 0.1 }, Quint, Out)
        task.delay(0.15, function() F.tw(cardBody, 0.38, { GroupTransparency = 0 }, Quad, Out); F.animateValue(0.38, 0, 1, setInputAlpha) end)
    end
    local function closeCard()
        if not cardOpen then return end
        cardOpen = false; syncTopbar(); cardHome = card.Position
        F.tw(cardBody, 0.15, { GroupTransparency = 1 }, Quad, Out); F.animateValue(0.15, 1, 0, setInputAlpha)
        F.tw(cardScale, 0.38, { Scale = curScale() * 0.18 }, Quint, In)
        F.tw(card, 0.38, { Position = orbCenterPos(), BackgroundTransparency = 0.7 }, Quint, In)
        task.delay(0.4, function() if not cardOpen then card.Visible = false end end)
    end
    makeDraggable(card, cardDrag, { ended = function(m) if m then cardHome = card.Position; cardMoved = true end end })

    local function shake()
        local p = card.Position
        for i, o in ipairs({ 0.008, -0.008, 0.005, -0.005, 0 }) do
            task.delay((i - 1) * 0.06, function() F.tw(card, 0.06, { Position = UDim2.new(p.X.Scale + o, 0, p.Y.Scale, 0) }, Quad, InOut) end)
        end
    end

    local function goMain()
        authed = true
        local scr, k = F.viewport(), curScale()
        local c = card.AbsolutePosition + card.AbsoluteSize / 2
        local hw, hh = WIN_W * k / 2, WIN_H * k / 2
        local px = math.clamp(c.X, hw, math.max(hw, scr.X - hw))
        local lo = math.max(hh, F.topInsetPx() + hh + 6)
        local py = math.clamp(c.Y, lo, math.max(lo, scr.Y - hh))
        winHome = UDim2.fromScale(px / scr.X, py / scr.Y)
        winOpen = true; syncTopbar(); win.Visible = true
        winScale.Scale = k; win.Size = off(CARD_W, CARD_H); win.Position = card.Position
        F.tw(win, 0.56, { Size = off(WIN_W, WIN_H), Position = winHome }, Quint, Out)
        F.tw(cardBody, 0.24, { GroupTransparency = 1 }, Quad, Out); F.animateValue(0.24, 1, 0, setInputAlpha)
        task.delay(0.28, function() card.Visible = false; cardOpen = false; busy = false end)
    end

    local function doLogin()
        if busy then return end
        local txt = F.trim(keyBox.Text)
        if txt == "" then F.toast("Введи ключ", "key"); shake(); return end
        busy = true; keyBox:ReleaseFocus()
        F.tw(pasteWrap, 0.25, { GroupTransparency = 1 }, Quad, Out)
        F.tw(lc, 0.2, { GroupTransparency = 1 }, Quad, Out)
        F.tw(login, 0.45, { Size = off(56, 52), Position = off(35 + (425 - 56) / 2, 306) }, Quint, Out)
        task.delay(0.28, function() if busy then spin.Visible = true end end)
        task.delay(0.95, function()
            if string.lower(txt) == F.KEY then
                spin.Visible = false; chk.Visible = true; chkScale.Scale = 0.2
                F.tw(chkScale, 0.4, { Scale = 1 }, Back, Out)
                task.delay(0.7, goMain)
            else
                spin.Visible = false; chk.Visible = false
                F.tw(login, 0.4, { Size = off(272, 52), Position = off(188, 306) }, Quint, Out)
                F.tw(pasteWrap, 0.3, { GroupTransparency = 0 }, Quad, Out); F.tw(lc, 0.3, { GroupTransparency = 0 }, Quad, Out)
                F.tw(inStroke, 0.15, { Color = C.red, Transparency = 0.1 })
                task.delay(0.9, function() F.tw(inStroke, 0.3, { Color = C.white, Transparency = 0.9 }) end)
                shake(); F.toast("Неверный ключ", "x"); busy = false
            end
        end)
    end

    loginBtn.Activated:Connect(doLogin)
    keyBox.FocusLost:Connect(function(enter) if enter then doLogin() end end)

    function F.orbTap()
        if not authed then if not busy then if cardOpen then closeCard() else openCard() end end
        else if winOpen then closeWindow() else openWindow() end end
    end

    F.bind(UserInputService.InputBegan, function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightShift and orb.Visible then F.orbTap() end
    end)

    -- главный цикл (орбита, искры, частицы, инерция скролла)
    F.bind(RunService.Heartbeat, function(dt)
        local now = os.clock()
        arcGrad.Rotation = (now * 240) % 360
        for _, g in ipairs(spinners) do g.Rotation = (now * 420) % 360 end
        for _, sp in ipairs(F.sparks) do
            if sp.f.Parent then
                sp.th = sp.th + dt * sp.sp
                local x, y = sp.a * math.cos(sp.th), sp.b * math.sin(sp.th)
                local cph, sph = math.cos(sp.phi), math.sin(sp.phi)
                sp.f.Position = off(sp.cx + x*cph - y*sph, sp.cy + x*sph + y*cph)
                local k = 0.65 + 0.35 * math.sin(now * 3.2 + sp.th * 2)
                sp.f.Size = off(sp.s * k, sp.s * k)
            end
        end
        if winOpen then
            for i = 1, PN do
                local p = P[i]
                p.y = p.y - p.vy * dt
                p.x = p.x + (p.vx + math.sin(now * 0.7 + p.ph) * 5) * dt
                if p.y < 24 then p.y = WIN_H - 24; p.x = math.random(30, WIN_W - 30) end
                p.f.Position = off(p.x, p.y)
                p.f.BackgroundTransparency = 0.45 + 0.4 * (0.5 + 0.5 * math.sin(now * 1.4 + p.ph))
            end
        end
        if Scroll.coast ~= 0 then
            local sc_ = curScroller()
            if sc_ then
                local y = sc_.CanvasPosition.Y + Scroll.coast * dt
                if setScrollY(y) ~= y then Scroll.coast = 0 end
                Scroll.coast = Scroll.coast * math.max(0, 1 - 5 * dt)
                if math.abs(Scroll.coast) < 12 then Scroll.coast = 0 end
            else Scroll.coast = 0 end
        end
        if Scroll.blocked and not F.Drag.finish then Scroll.blocked = false end
    end)

    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyScales)
    F.RunIntro3DF(orb, orbScale, getOrbTargetPos)
end

BuildShell()
