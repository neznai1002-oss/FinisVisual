--[[
    Finis Visual — 3D Intro "F" + 3D Bacon (Full-Body Chams) + ESP + Samurai Hat + Shaders
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

local LocalPlayer = Players.LocalPlayer
local ENV = (type(getgenv) == "function" and getgenv()) or _G

-- повторный запуск: чисто удаляем старую копию
if ENV.__FinisVisual and type(ENV.__FinisVisual.Destroy) == "function" then
    pcall(ENV.__FinisVisual.Destroy)
end
if ENV.__EtaMenu and type(ENV.__EtaMenu.Destroy) == "function" then
    pcall(ENV.__EtaMenu.Destroy)
end

local App = { conns = {}, cleanups = {} }
ENV.__FinisVisual = App

local function bind(signal, fn)
    local c = signal:Connect(fn)
    App.conns[#App.conns + 1] = c
    return c
end

local function onCleanup(fn)
    App.cleanups[#App.cleanups + 1] = fn
end

----------------------------------------------------------------------
-- ScreenGui (CoreGui приоритетно, чтобы ViewportFrame 100% рендерился в Delta!)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FinisVisualMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)

do
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        pcall(function() gui.Parent = cg end)
    end
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

function App.Destroy()
    for _, fn in ipairs(App.cleanups) do pcall(fn) end
    App.cleanups = {}
    for _, c in ipairs(App.conns) do pcall(function() c:Disconnect() end) end
    App.conns = {}
    pcall(function() gui:Destroy() end)
    if ENV.__FinisVisual == App then ENV.__FinisVisual = nil end
end

----------------------------------------------------------------------
-- константы и помощники
----------------------------------------------------------------------
local WIN_W, WIN_H   = 1020, 620
local SIDE_W, HEAD_H = 173, 80
local PAGE_W, PAGE_H = WIN_W - SIDE_W, WIN_H - HEAD_H
local CARD_W, CARD_H = 495, 442
local KEY            = "@finisokek"

local V2 = Vector2.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function off(x, y) return UDim2.fromOffset(x, y) end
local function sc(x, y) return UDim2.fromScale(x, y) end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    return math.atan(y, x)
end

local function trim(s)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

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
}

local PALETTE = {
    rgb(160, 172, 250), -- жемчуг / фиолетовый
    rgb(255, 92, 128),  -- розовый / красный
    rgb(72, 198, 255),  -- голубой
    rgb(96, 232, 152),  -- мятный
    rgb(255, 210, 96),  -- золотой
    rgb(255, 134, 68),  -- оранжевый
    rgb(196, 116, 255), -- неон-фиолет
    rgb(245, 248, 255), -- белый
}

local theme = { a = rgb(160, 172, 250), b = rgb(192, 156, 250) }

local Quint, Quad, Back = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local Out, InOut, In = Enum.EasingDirection.Out, Enum.EasingDirection.InOut, Enum.EasingDirection.In
local FONT_R, FONT_M, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold

local function tw(o, dur, props, style, dir)
    local t = TweenService:Create(o, TweenInfo.new(math.max(0.01, dur), style or Quint, dir or Out), props)
    t:Play()
    return t
end

local function animateValue(dur, a, b, fn)
    dur = math.max(0.02, dur)
    local t0 = os.clock()
    local done = false
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if done then return end
        local k = math.min(1, (os.clock() - t0) / dur)
        local e = 1 - (1 - k) ^ 3
        fn(a + (b - a) * e)
        if k >= 1 then done = true; conn:Disconnect() end
    end)
    task.delay(dur + 0.05, function()
        if not done then done = true; conn:Disconnect(); fn(b) end
    end)
end

local function New(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end

local function Frame(parent, p)
    local t = { BorderSizePixel = 0, BackgroundColor3 = C.white }
    if p then for k, v in pairs(p) do t[k] = v end end
    return New("Frame", t, parent)
end

local function Group(parent, p)
    local t = { BorderSizePixel = 0, BackgroundTransparency = 1 }
    if p then for k, v in pairs(p) do t[k] = v end end
    return New("CanvasGroup", t, parent)
end

local function Label(parent, p)
    local t = {
        BorderSizePixel = 0, BackgroundTransparency = 1, Font = FONT_M,
        TextSize = 14, TextColor3 = C.txt, Text = "",
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    }
    if p then for k, v in pairs(p) do t[k] = v end end
    t.TextSize = math.floor(t.TextSize + 0.5)
    return New("TextLabel", t, parent)
end

local function Button(parent, p)
    local t = {
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
    }
    if p then for k, v in pairs(p) do t[k] = v end end
    return New("TextButton", t, parent)
end

local function Corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r)
    c.Parent = o
    return c
end

local function Stroke(o, color, tr, th)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or C.white
    s.Transparency = tr or 0.88
    s.Thickness = th or 1
    s.Parent = o
    return s
end

local function Grad(o, c1, c2, rot, t1, t2)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    if t1 ~= nil then g.Transparency = NumberSequence.new(t1, t2 or t1) end
    g.Parent = o
    return g
end

local function accentGradient(o, rot) return Grad(o, theme.a, theme.b, rot or 0) end

local function viewport()
    local v = gui.AbsoluteSize
    if v.X < 50 or v.Y < 50 then
        local cam = workspace.CurrentCamera
        if cam then v = cam.ViewportSize end
    end
    if v.X < 50 or v.Y < 50 then v = V2(1280, 720) end
    return v
end

local function topInsetPx()
    local v = 0
    pcall(function() v = GuiService.TopbarInset.Max.Y end)
    if v <= 0 then pcall(function() v = GuiService:GetGuiInset().Y end) end
    return v
end

local function homeCenter()
    local v = viewport()
    local inset = topInsetPx()
    return UDim2.fromScale(0.5, (inset + (v.Y - inset) / 2) / v.Y)
end

local function baseScale()
    local v = viewport()
    local h = math.max(100, v.Y - topInsetPx())
    return math.max(0.3, math.min(h * 0.9 / WIN_H, v.X * 0.62 / WIN_W))
end

local function measure(text, size, font)
    size = math.floor(size + 0.5)
    local ok, r = pcall(function() return TextService:GetTextSize(text, size, font or FONT_M, V2(3000, 200)) end)
    if ok and r then return r.X end
    return #text * size * 0.58
end

local function measureH(text, size, font, w)
    local ok, r = pcall(function() return TextService:GetTextSize(text, size, font, V2(w, 4000)) end)
    if ok and r then return r.Y end
    return math.ceil((utf8.len(text) or #text) * size * 0.58 / w) * size * 1.25
end

-- единое перетаскивание
local Drag = { move = nil, finish = nil }
local function beginDrag(move, finish)
    if Drag.finish then pcall(Drag.finish) end
    Drag.move, Drag.finish = move, finish
end
bind(UserInputService.InputChanged, function(input)
    if Drag.move and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        Drag.move(input)
    end
end)
bind(UserInputService.InputEnded, function(input)
    if Drag.finish and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
        local f = Drag.finish
        Drag.move, Drag.finish = nil, nil
        f()
    end
end)

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

----------------------------------------------------------------------
-- СОСТОЯНИЕ ВСЕХ ВИЗУАЛЬНЫХ ФУНКЦИЙ
----------------------------------------------------------------------
local State = {
    -- ESP и чамсы
    espEnabled   = false,
    espChams     = true,
    espBox       = true,
    espNick      = true,
    espDist      = true,
    espHealth    = true,
    chamsMode    = 1, -- 1=Обычный, 2=Glow, 3=Flat, 4=Glass
    chamsTrans   = 35,
    espColorIdx  = 2, -- розовый по умолчанию
    espColor     = PALETTE[2],

    -- Самурайская шляпа (Каса / China Hat)
    hatEnabled   = true,
    hatRgb       = false,
    hatSize      = 1.25,
    hatHeight    = 0.55,
    hatTrans     = 20,
    hatMat       = 1, -- 1=Neon, 2=Glass, 3=Flat, 4=ForceField
    hatColorIdx  = 1,
    hatColor     = PALETTE[1],

    -- Шейдеры (Lighting)
    shaderPreset = 1, -- 1=Оригинал ... 8=Vaporwave
    shBloom      = false,
    shBloomInt   = 0.8,
    shSunRays    = false,
    shDof        = false,
    shSat        = 0.0,
    shContrast   = 0.0,
    shClock      = 14.0,
    shBright     = 2.0,
    shBlur       = 0,

    -- Оболочка
    panelopacity = 88,
    particles    = true,
    density      = 60,
    trail        = true,
    pressfx      = true,
}

local Binders = {}
local function bindState(key, fn)
    Binders[key] = Binders[key] or {}
    table.insert(Binders[key], fn)
    fn(State[key], true)
end
local function setState(key, v)
    State[key] = v
    local list = Binders[key]
    if list then
        for _, fn in ipairs(list) do fn(v, false) end
    end
end

----------------------------------------------------------------------
-- ИКОНКИ И ЛОГОТИП F
----------------------------------------------------------------------
local ICONS = {
    eye      = { {"p",true, 2,12, 5,8.5, 8.5,6.3, 12,5.5, 15.5,6.3, 19,8.5, 22,12, 19,15.5, 15.5,17.7, 12,18.5, 8.5,17.7, 5,15.5}, {"c",12,12,3} },
    x        = { {"l",6,6,18,18}, {"l",18,6,6,18} },
    check    = { {"p",false, 5,12.5, 10,17.5, 19,7} },
    arrow    = { {"l",4,12,20,12}, {"p",false, 14,6, 20,12, 14,18} },
    key      = { {"c",6.2,12,3.6}, {"l",9.8,12,21.5,12}, {"l",18,12,18,15.5}, {"l",21.5,12,21.5,14.8} },
    clipboard= { {"r",5.5,4,13,17.5,2.5}, {"r",9,2,6,4,1.5}, {"l",9,12,15,12}, {"l",9,16,13,16} },
    sparkle  = { {"p",true, 12,2, 14,10, 22,12, 14,14, 12,22, 10,14, 2,12, 10,10} },
    search   = { {"c",10.5,10.5,6.5}, {"l",15.5,15.5,20.5,20.5} },
    undo     = { {"p",false, 3,4.5, 3,10, 8.5,10}, {"p",false, 3.8,10, 5,6.8, 8,4.5, 12,3.6, 16,4.6, 19.2,7.6, 20.4,11.6, 19.4,15.6, 16.4,18.8, 12.4,20.2, 8.4,19.4} },
    target   = { {"c",12,12,9.5}, {"c",12,12,5.5}, {"d",12,12,1.6} },
    bolt     = { {"p",true, 13,2, 3,14, 12,14, 11,22, 21,10, 12,10} },
    hat      = { {"p",true, 12,5, 22,16, 2,16}, {"l",1,16.5,23,16.5} },
    sun      = { {"c",12,12,4.5}, {"l",12,2,12,5}, {"l",12,19,12,22}, {"l",2,12,5,12}, {"l",19,12,22,12}, {"l",5,5,7.2,7.2}, {"l",16.8,16.8,19,19}, {"l",19,5,16.8,7.2}, {"l",7.2,16.8,5,19} },
    venn     = { {"c",9.5,9,5.2}, {"c",14.5,9,5.2}, {"c",12,14.8,5.2} },
    dot      = { {"d",12,12,3} },
}

local function mkLine(root, x1, y1, x2, y2, th, color)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local f = Frame(root, {
        Name = "p", AnchorPoint = V2(0.5, 0.5),
        Position = off((x1 + x2) / 2, (y1 + y2) / 2),
        Size = off(len + th * 0.35, th),
        Rotation = math.deg(atan2(dy, dx)),
        BackgroundColor3 = color,
    })
    Corner(f, "full")
    return f
end

local function mkCircle(root, cx, cy, r, th, color, filled)
    local f = Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = off(cx, cy), Size = off(r * 2, r * 2) })
    Corner(f, "full")
    if filled then f.Name = "p"; f.BackgroundColor3 = color
    else f.Name = "o"; f.BackgroundTransparency = 1; Stroke(f, color, 0, th) end
    return f
end

local function mkRRect(root, x, y, w, h, rad, th, color)
    local f = Frame(root, { Name = "o", Position = off(x, y), Size = off(w, h), BackgroundTransparency = 1 })
    Corner(f, math.max(1, rad))
    Stroke(f, color, 0, th)
    return f
end

local function Icon(parent, name, size, color, props)
    local spec = ICONS[name] or ICONS.dot
    local root = Frame(parent, { Name = "Icon", BackgroundTransparency = 1, Size = off(size, size) })
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

local function setIconColor(root, color, instant)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("UIStroke") then
            if instant then d.Color = color else tw(d, 0.2, { Color = color }) end
        elseif d:IsA("Frame") and d.Name == "p" then
            if instant then d.BackgroundColor3 = color else tw(d, 0.2, { BackgroundColor3 = color }) end
        end
    end
end

local function setIconAlpha(root, a)
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("UIStroke") then d.Transparency = 1 - a
        elseif d:IsA("Frame") and d.Name == "p" then d.BackgroundTransparency = 1 - a end
    end
end

local sparks = {}
local function makeSpark(parent, s, color)
    local f = Frame(parent, { Name = "Spark", BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0.5), Size = off(s, s) })
    Corner(Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1.5), BackgroundColor3 = color }), "full")
    Corner(Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(0, 1.5, 1, 0), BackgroundColor3 = color }), "full")
    Corner(Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(s*0.3, s*0.3), BackgroundColor3 = C.white }), "full")
    return f
end

local function makeLogoF(parent, size, ring, spark)
    local root = Frame(parent, { Name = "LogoF", BackgroundTransparency = 1, Size = off(size * 1.5, size) })
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
        local s = makeSpark(root, math.max(8, size * 0.3), C.white)
        s.Position = off(cx - A * 0.8, rcy + B * 0.5)
        sparks[#sparks + 1] = { f = s, s = math.max(8, size * 0.3), cx = cx, cy = rcy, a = A, b = B, phi = phi, th = math.random() * 6.28, sp = 0.55 }
    end
    return root
end

----------------------------------------------------------------------
-- МОДУЛЬ 1: САМУРАЙСКАЯ ШЛЯПА (КАСА / CHINA HAT) — ДЛЯ ИГРЫ И 3D-ПРЕВЬЮ
----------------------------------------------------------------------
local HAT_LAYERS = 13
local HAT_MATS = {
    Enum.Material.Neon,
    Enum.Material.Glass,
    Enum.Material.SmoothPlastic,
    Enum.Material.ForceField,
}

local function CreateSamuraiHat(parent, name)
    local folder = New("Folder", { Name = name or "SamuraiHat" }, parent)
    local layers = {}
    for i = 1, HAT_LAYERS do
        local p = New("Part", {
            Name = "Ring_" .. i,
            Shape = Enum.PartType.Cylinder,
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
            TopSurface = Enum.SurfaceType.Smooth,
            BottomSurface = Enum.SurfaceType.Smooth,
            Material = Enum.Material.Neon,
            Size = Vector3.new(0.08, 2, 2),
        }, folder)
        layers[i] = p
    end
    -- декоративная макушка-шпиль самурайской шляпы
    local tip = New("Part", {
        Name = "Tip",
        Shape = Enum.PartType.Ball,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
        Material = Enum.Material.Neon,
        Size = Vector3.new(0.2, 0.2, 0.2),
    }, folder)
    return { folder = folder, layers = layers, tip = tip }
end

local function UpdateSamuraiHat(hat, headCF, enabled, sizeScale, heightOff, transPct, col, matIdx, spinAngle)
    if not hat or not hat.folder or not hat.folder.Parent then return end
    local mat = HAT_MATS[matIdx] or Enum.Material.Neon
    local baseTrans = math.clamp(transPct / 100, 0, 0.96)
    local baseR = 2.55 * sizeScale
    local totalH = 0.92 * sizeScale
    local stepH = totalH / HAT_LAYERS

    if not enabled or not headCF then
        for _, p in ipairs(hat.layers) do p.Transparency = 1 end
        hat.tip.Transparency = 1
        return
    end

    local rotCF = CFrame.new(headCF.Position) * CFrame.Angles(0, spinAngle or 0, 0)
    -- переносим наклон головы, сохраняя шляпу сверху
    local baseCF = headCF * CFrame.new(0, heightOff, 0) * CFrame.Angles(0, spinAngle or 0, 0)
    local _ = rotCF

    for i, p in ipairs(hat.layers) do
        local t = (i - 1) / (HAT_LAYERS - 1) -- 0 = широкий край, 1 = вершина
        -- лёгкий вогнутый самурайский профиль (каса)
        local radius = math.max(0.14, baseR * ((1 - t) ^ 0.88))
        local y = t * totalH
        local thick = math.max(0.05, stepH * 1.35)
        -- в Roblox ось Cylinder идёт вдоль X, поэтому поворот на 90° по Z ставит диск горизонтально
        p.Size = Vector3.new(thick, radius * 2, radius * 2)
        p.CFrame = baseCF * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90))
        p.Material = mat
        -- лёгкий градиент яркости от ободка к макушке
        local shade = 0.72 + 0.28 * (1 - t)
        p.Color = Color3.new(col.R * shade, col.G * shade, col.B * shade)
        -- нижний ободок чуть плотнее, чтобы шляпа красиво читалась
        p.Transparency = (i == 1) and math.max(0, baseTrans - 0.12) or baseTrans
    end

    local tipSize = math.max(0.16, 0.24 * sizeScale)
    hat.tip.Size = Vector3.new(tipSize, tipSize, tipSize)
    hat.tip.CFrame = baseCF * CFrame.new(0, totalH + tipSize * 0.15, 0)
    hat.tip.Material = mat
    hat.tip.Color = col
    hat.tip.Transparency = baseTrans
end

-- Шляпа в реальном мире на LocalPlayer
local worldHatFolder = New("Folder", { Name = "FinisVisual_WorldHat" }, workspace)
local worldHat = CreateSamuraiHat(worldHatFolder, "LocalSamuraiHat")
onCleanup(function() pcall(function() worldHatFolder:Destroy() end) end)

----------------------------------------------------------------------
-- МОДУЛЬ 2: БАНАЛЬНЫЙ ESP НА ИГРОКОВ В ИГРЕ
----------------------------------------------------------------------
local espFolder = New("Folder", { Name = "FinisVisual_ESP" }, gui)
local espEntries = {} -- [player] = { hl, bb, box, nameLbl, distLbl, hpBg, hpFill, char }

local function RemovePlayerESP(plr)
    local e = espEntries[plr]
    if not e then return end
    if e.hl then pcall(function() e.hl:Destroy() end) end
    if e.bb then pcall(function() e.bb:Destroy() end) end
    espEntries[plr] = nil
end

local function EnsurePlayerESP(plr)
    if plr == LocalPlayer then return nil end
    local char = plr.Character
    if not char then RemovePlayerESP(plr); return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        RemovePlayerESP(plr)
        return nil
    end

    local e = espEntries[plr]
    if e and e.char == char and e.hl and e.hl.Parent and e.bb and e.bb.Parent then
        return e, char, hrp, hum
    end

    RemovePlayerESP(plr)

    local hl = New("Highlight", {
        Name = "HL_" .. plr.Name,
        Adornee = char,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor = State.espColor,
        OutlineColor = C.white,
        FillTransparency = State.chamsTrans / 100,
        OutlineTransparency = 0.1,
    }, espFolder)

    local bb = New("BillboardGui", {
        Name = "BB_" .. plr.Name,
        Adornee = hrp,
        AlwaysOnTop = true,
        Size = UDim2.fromScale(4.6, 5.8),
        StudsOffset = Vector3.new(0, 0.2, 0),
        LightInfluence = 0,
    }, espFolder)

    local box = Frame(bb, {
        AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = sc(0.88, 0.92),
        BackgroundTransparency = 1,
    })
    Corner(box, 3)
    local boxStroke = Stroke(box, State.espColor, 0.1, 1.5)

    local nameLbl = Label(bb, {
        AnchorPoint = V2(0.5, 1), Position = UDim2.new(0.5, 0, 0.03, -2),
        Size = UDim2.new(1.8, 0, 0, 16), Text = plr.DisplayName,
        TextSize = 11, Font = FONT_B, TextColor3 = C.white,
        TextStrokeTransparency = 0.35, TextXAlignment = Enum.TextXAlignment.Center,
    })

    local distLbl = Label(bb, {
        AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, 0.97, 2),
        Size = UDim2.new(1.5, 0, 0, 14), Text = "0 м",
        TextSize = 10, Font = FONT_M, TextColor3 = State.espColor,
        TextStrokeTransparency = 0.35, TextXAlignment = Enum.TextXAlignment.Center,
    })

    local hpBg = Frame(bb, {
        Position = UDim2.new(0.01, 0, 0.04, 0), Size = UDim2.new(0, 4, 0.92, 0),
        BackgroundColor3 = rgb(12, 12, 20), BackgroundTransparency = 0.25,
    })
    Corner(hpBg, "full")
    local hpFill = Frame(hpBg, {
        AnchorPoint = V2(0, 1), Position = sc(0, 1), Size = sc(1, 1),
        BackgroundColor3 = C.green,
    })
    Corner(hpFill, "full")

    e = {
        hl = hl, bb = bb, box = box, boxStroke = boxStroke,
        nameLbl = nameLbl, distLbl = distLbl, hpBg = hpBg, hpFill = hpFill, char = char,
    }
    espEntries[plr] = e
    return e, char, hrp, hum
end

local function UpdateAllESP()
    if not State.espEnabled then
        for plr in pairs(espEntries) do RemovePlayerESP(plr) end
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))
    local col = State.espColor
    local chamsT = math.clamp(State.chamsTrans / 100, 0.05, 0.95)
    local mode = State.chamsMode

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local e, _, hrp, hum = EnsurePlayerESP(plr)
            if e then
                e.hl.Enabled = State.espChams
                e.hl.FillColor = col
                e.hl.OutlineColor = (mode == 2) and C.white or col
                e.hl.FillTransparency = (mode == 4) and math.max(0.7, chamsT) or chamsT
                e.hl.OutlineTransparency = (mode == 3) and 1 or 0.1

                local any2D = State.espBox or State.espNick or State.espDist or State.espHealth
                e.bb.Enabled = any2D
                e.box.Visible = State.espBox
                e.boxStroke.Color = col
                e.nameLbl.Visible = State.espNick
                e.distLbl.Visible = State.espDist
                e.distLbl.TextColor3 = col
                if myRoot and hrp then
                    local d = math.floor((myRoot.Position - hrp.Position).Magnitude + 0.5)
                    e.distLbl.Text = d .. " м"
                end

                e.hpBg.Visible = State.espHealth
                local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                e.hpFill.Size = sc(1, hpRatio)
                e.hpFill.BackgroundColor3 = (hpRatio > 0.5) and C.green or ((hpRatio > 0.25) and rgb(255, 200, 70) or C.red)
            end
        end
    end
end

bind(Players.PlayerRemoving, RemovePlayerESP)
onCleanup(function()
    for plr in pairs(espEntries) do RemovePlayerESP(plr) end
    pcall(function() espFolder:Destroy() end)
end)

----------------------------------------------------------------------
-- МОДУЛЬ 3: ШЕЙДЕРЫ (LIGHTING + ПОСТ-ЭФФЕКТЫ С ВОЗВРАТОМ ОРИГИНАЛА)
----------------------------------------------------------------------
local OrigLighting = {
    ClockTime            = Lighting.ClockTime,
    Brightness           = Lighting.Brightness,
    Ambient              = Lighting.Ambient,
    OutdoorAmbient       = Lighting.OutdoorAmbient,
    ColorShift_Top       = Lighting.ColorShift_Top,
    ColorShift_Bottom    = Lighting.ColorShift_Bottom,
    FogEnd               = Lighting.FogEnd,
    FogColor             = Lighting.FogColor,
    GlobalShadows        = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation,
}

State.shClock  = math.floor(OrigLighting.ClockTime * 2 + 0.5) / 2
State.shBright = math.clamp(math.floor(OrigLighting.Brightness * 10 + 0.5) / 10, 0.5, 5)

local ShaderFX = {}
local function getFX(className, name)
    if ShaderFX[name] and ShaderFX[name].Parent then return ShaderFX[name] end
    local old = Lighting:FindFirstChild(name)
    if old then old:Destroy() end
    local obj = Instance.new(className)
    obj.Name = name
    obj.Parent = Lighting
    ShaderFX[name] = obj
    return obj
end

local SHADER_PRESETS = {
    { name = "Оригинал",  reset = true },
    {
        name = "RTX Ультра", clock = 15.5, bright = 2.8, exposure = 0.18,
        ambient = rgb(92, 98, 114), outdoor = rgb(135, 142, 160),
        top = rgb(255, 245, 232), tint = rgb(255, 250, 244),
        bloom = true, bloomInt = 0.65, sun = true, dof = true, sat = 0.18, contrast = 0.18, blur = 0,
    },
    {
        name = "Киберпанк", clock = 22.5, bright = 1.9, exposure = 0.25,
        ambient = rgb(95, 50, 145), outdoor = rgb(75, 95, 175),
        top = rgb(220, 90, 255), tint = rgb(225, 200, 255),
        bloom = true, bloomInt = 1.45, sun = false, dof = false, sat = 0.45, contrast = 0.28, blur = 0,
    },
    {
        name = "Закат", clock = 17.8, bright = 2.6, exposure = 0.15,
        ambient = rgb(138, 86, 68), outdoor = rgb(186, 118, 86),
        top = rgb(255, 172, 102), tint = rgb(255, 224, 194),
        bloom = true, bloomInt = 0.95, sun = true, dof = true, sat = 0.28, contrast = 0.15, blur = 0,
    },
    {
        name = "Аниме", clock = 13.0, bright = 3.2, exposure = 0.22,
        ambient = rgb(140, 152, 178), outdoor = rgb(168, 185, 215),
        top = rgb(235, 248, 255), tint = rgb(248, 252, 255),
        bloom = true, bloomInt = 0.75, sun = true, dof = false, sat = 0.55, contrast = 0.12, blur = 0,
    },
    {
        name = "Нуар", clock = 20.5, bright = 1.4, exposure = -0.1,
        ambient = rgb(52, 56, 68), outdoor = rgb(72, 78, 92),
        top = rgb(145, 155, 175), tint = rgb(210, 220, 238),
        bloom = false, bloomInt = 0.3, sun = false, dof = true, sat = -0.72, contrast = 0.35, blur = 0,
    },
    {
        name = "Зима", clock = 10.5, bright = 2.5, exposure = 0.12,
        ambient = rgb(126, 160, 202), outdoor = rgb(156, 192, 232),
        top = rgb(208, 236, 255), tint = rgb(220, 240, 255),
        bloom = true, bloomInt = 0.85, sun = true, dof = false, sat = -0.08, contrast = 0.1, blur = 0,
    },
    {
        name = "Vaporwave", clock = 18.4, bright = 2.3, exposure = 0.2,
        ambient = rgb(156, 76, 166), outdoor = rgb(98, 176, 212),
        top = rgb(255, 128, 214), tint = rgb(252, 210, 245),
        bloom = true, bloomInt = 1.25, sun = true, dof = false, sat = 0.42, contrast = 0.2, blur = 0,
    },
}

local function ResetShaders()
    for _, fxObj in pairs(ShaderFX) do pcall(function() fxObj:Destroy() end) end
    table.clear(ShaderFX)
    for prop, val in pairs(OrigLighting) do
        pcall(function() Lighting[prop] = val end)
    end
end

local function ApplyManualShaders(tintOverride)
    pcall(function()
        Lighting.ClockTime = State.shClock
        Lighting.Brightness = State.shBright
        Lighting.GlobalShadows = true
    end)

    local bloom = getFX("BloomEffect", "FinisVisual_Bloom")
    bloom.Enabled = State.shBloom
    bloom.Intensity = State.shBloomInt
    bloom.Size = 26
    bloom.Threshold = 0.9

    local cc = getFX("ColorCorrectionEffect", "FinisVisual_CC")
    cc.Enabled = (State.shaderPreset ~= 1) or (State.shSat ~= 0) or (State.shContrast ~= 0)
    cc.Saturation = State.shSat
    cc.Contrast = State.shContrast
    if tintOverride then cc.TintColor = tintOverride end

    local rays = getFX("SunRaysEffect", "FinisVisual_SunRays")
    rays.Enabled = State.shSunRays
    rays.Intensity = 0.14
    rays.Spread = 0.65

    local dof = getFX("DepthOfFieldEffect", "FinisVisual_DOF")
    dof.Enabled = State.shDof
    dof.FocusDistance = 24
    dof.InFocusRadius = 32
    dof.NearIntensity = 0.12
    dof.FarIntensity = 0.28

    local blur = getFX("BlurEffect", "FinisVisual_Blur")
    blur.Enabled = State.shBlur > 0
    blur.Size = State.shBlur
end

local ShaderSliders = {}
local function ApplyShaderPreset(idx)
    State.shaderPreset = idx
    local p = SHADER_PRESETS[idx]
    if not p or p.reset then
        ResetShaders()
        State.shBloom = false; State.shSunRays = false; State.shDof = false
        State.shSat = 0; State.shContrast = 0; State.shBlur = 0
        State.shClock = math.floor(OrigLighting.ClockTime * 2 + 0.5) / 2
        State.shBright = math.clamp(math.floor(OrigLighting.Brightness * 10 + 0.5) / 10, 0.5, 5)
        setState("shBloom", false); setState("shSunRays", false); setState("shDof", false)
        if ShaderSliders.sat then ShaderSliders.sat.set(0) end
        if ShaderSliders.contrast then ShaderSliders.contrast.set(0) end
        if ShaderSliders.clock then ShaderSliders.clock.set(State.shClock) end
        if ShaderSliders.bright then ShaderSliders.bright.set(State.shBright) end
        if ShaderSliders.blur then ShaderSliders.blur.set(0) end
        return
    end

    pcall(function()
        Lighting.Ambient = p.ambient
        Lighting.OutdoorAmbient = p.outdoor
        Lighting.ColorShift_Top = p.top
        Lighting.ExposureCompensation = p.exposure or 0
    end)

    State.shBloom = p.bloom; State.shBloomInt = p.bloomInt
    State.shSunRays = p.sun; State.shDof = p.dof
    State.shSat = p.sat; State.shContrast = p.contrast
    State.shClock = p.clock; State.shBright = p.bright; State.shBlur = p.blur

    setState("shBloom", p.bloom); setState("shSunRays", p.sun); setState("shDof", p.dof)
    if ShaderSliders.bloomInt then ShaderSliders.bloomInt.set(p.bloomInt) end
    if ShaderSliders.sat then ShaderSliders.sat.set(p.sat) end
    if ShaderSliders.contrast then ShaderSliders.contrast.set(p.contrast) end
    if ShaderSliders.clock then ShaderSliders.clock.set(p.clock) end
    if ShaderSliders.bright then ShaderSliders.bright.set(p.bright) end
    if ShaderSliders.blur then ShaderSliders.blur.set(p.blur) end

    ApplyManualShaders(p.tint)
end

onCleanup(ResetShaders)

----------------------------------------------------------------------
-- UI КОНСТРУКТОРЫ (ИЗ ТВОЕЙ ОБНОВЛЁННОЙ БАЗЫ)
----------------------------------------------------------------------
local UI = {
    toast = function() end,
    pressFx = function() end,
    scrollLock = function() end,
    scrolled = false,
    searchItems = {},
}

local function fitDesc(text, maxW)
    for _, s in ipairs({ 12, 10, 9 }) do
        if measure(text, s, FONT_R) <= maxW then return s, 1 end
    end
    return 9, math.max(2, math.floor(measureH(text, 9, FONT_R, maxW) / 11 + 0.5))
end

local function addPress(btn, target, amount)
    local us = New("UIScale", {}, target)
    amount = amount or 0.96
    btn.InputBegan:Connect(function(i) if isPress(i) then tw(us, 0.1, { Scale = amount }, Quad, Out) end end)
    btn.InputEnded:Connect(function(i) if isPress(i) then tw(us, 0.25, { Scale = 1 }, Back, Out) end end)
    return us
end

local function Toggle(parent, x, y, on, onClick)
    local W, H, K = 58, 32, 24
    local root = Frame(parent, { Name = "Toggle", Position = off(x, y), Size = off(W, H), BackgroundColor3 = C.off, BackgroundTransparency = 0.2 })
    Corner(root, "full")
    local stroke = Stroke(root, C.white, on and 0.55 or 0.9, 1)
    local fill = Frame(root, { Size = sc(1, 1), BackgroundColor3 = C.white, BackgroundTransparency = on and 0 or 1 })
    Corner(fill, "full"); accentGradient(fill, 0)
    local knob = Frame(root, { AnchorPoint = V2(0, 0.5), Position = off(on and (W-K-4) or 4, H/2), Size = off(K, K), BackgroundColor3 = C.knob, ZIndex = 2 })
    Corner(knob, "full")
    local btn = Button(root, { ZIndex = 3 })
    local obj = { frame = root, on = on }
    function obj.set(v, instant)
        obj.on = v
        local goal = off(v and (W-K-4) or 4, H/2)
        if instant then
            knob.Position = goal; fill.BackgroundTransparency = v and 0 or 1; stroke.Transparency = v and 0.55 or 0.9
        else
            tw(knob, 0.3, { Position = goal }, Back, Out)
            tw(fill, 0.22, { BackgroundTransparency = v and 0 or 1 }, Quad, Out)
            tw(stroke, 0.22, { Transparency = v and 0.55 or 0.9 }, Quad, Out)
        end
    end
    btn.InputBegan:Connect(function(i) if isPress(i) then tw(knob, 0.12, { Size = off(K+6, K) }, Quad, Out) end end)
    btn.InputEnded:Connect(function(i) if isPress(i) then tw(knob, 0.2, { Size = off(K, K) }, Quad, Out) end end)
    btn.Activated:Connect(function()
        if UI.scrolled then return end
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    return obj
end

local function Slider(parent, x, y, w, cfg)
    local R = 11
    local root = Frame(parent, { Name = "Slider", BackgroundTransparency = 1, Position = off(x, y), Size = off(w, 28) })
    local track = Frame(root, { AnchorPoint = V2(0, 0.5), Position = off(0, 14), Size = off(w, 6), BackgroundColor3 = C.track, BackgroundTransparency = 0.05 })
    Corner(track, "full")
    local fill = Frame(track, { Size = off(0, 6), BackgroundColor3 = C.white })
    Corner(fill, "full"); accentGradient(fill, 0)
    local thumb = Frame(root, { AnchorPoint = V2(0.5, 0.5), Size = off(2*R, 2*R), Position = off(R, 14), BackgroundColor3 = C.knob, ZIndex = 3 })
    Corner(thumb, "full"); Stroke(thumb, C.white, 0.55, 1)
    local hit = Button(root, { Size = off(w, 28), ZIndex = 4 })

    local value = cfg.value
    local function render(animate)
        local f = math.clamp((value - cfg.min) / (cfg.max - cfg.min), 0, 1)
        local cx = R + f * (w - 2 * R)
        if animate then
            tw(thumb, 0.12, { Position = off(cx, 14) }, Quad, Out)
            tw(fill, 0.12, { Size = off(cx, 6) }, Quad, Out)
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
        if not isPress(input) then return end
        UI.scrollLock(true)
        tw(thumb, 0.15, { Size = off(2*R+4, 2*R+4) }, Quad, Out)
        setFromX(input.Position.X)
        beginDrag(function(i) setFromX(i.Position.X) end, function()
            UI.scrollLock(false)
            tw(thumb, 0.2, { Size = off(2*R, 2*R) }, Quad, Out)
        end)
    end)

    return {
        frame = root,
        set = function(v) value = v; render(true) end,
    }
end

local function Segmented(parent, x, y, w, options, selected, onSelect)
    local H, pad = 38, 4
    local n = #options
    local root = Frame(parent, { Name = "Segmented", Position = off(x, y), Size = off(w, H), BackgroundColor3 = C.panel, BackgroundTransparency = 0.55 })
    Corner(root, 13); Stroke(root, C.white, 0.9, 1)
    local segW = (w - pad * 2) / n
    local pill = Frame(root, { Name = "Pill", Size = off(segW, H - pad * 2), Position = off(pad, pad), BackgroundColor3 = C.white })
    Corner(pill, 10); accentGradient(pill, 0)
    local labels = {}
    local obj = { frame = root, selected = selected }
    function obj.set(i, instant)
        obj.selected = i
        local goal = off(pad + (i - 1) * segW, pad)
        if instant then pill.Position = goal else tw(pill, 0.3, { Position = goal }, Quint, Out) end
        for k, l in ipairs(labels) do
            local col = (k == i) and C.dark or rgb(176, 177, 206)
            if instant then l.TextColor3 = col else tw(l, 0.2, { TextColor3 = col }) end
        end
    end
    for i, name in ipairs(options) do
        local b = Button(root, { Position = off(pad + (i - 1) * segW, pad), Size = off(segW, H - pad * 2), ZIndex = 2 })
        labels[i] = Label(b, { Size = sc(1, 1), Text = name, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = rgb(176, 177, 206) })
        b.Activated:Connect(function()
            if UI.scrolled then return end
            UI.pressFx(b); obj.set(i, false)
            if onSelect then onSelect(i, name) end
        end)
    end
    obj.set(selected, true)
    return obj
end

local function MakeButton(parent, x, y, w, h, text, iconName, style, onClick)
    local root = Frame(parent, { Name = "Btn", Position = off(x, y), Size = off(w, h), BackgroundColor3 = C.white })
    Corner(root, 14)
    local fg = C.txt
    if style == "primary" then accentGradient(root, 0); fg = C.dark
    else root.BackgroundColor3 = rgb(72, 72, 104); root.BackgroundTransparency = 0.72; Stroke(root, C.white, 0.88, 1) end
    local twd = measure(text, 15, FONT_B)
    local iw, gap = iconName and 17 or 0, iconName and 8 or 0
    local sx = (w - (iw + gap + twd)) / 2
    if iconName then Icon(root, iconName, 17, fg, { Position = off(sx, (h - 17) / 2) }) end
    Label(root, { Position = off(sx + iw + gap, 0), Size = off(twd + 6, h), Text = text, TextSize = 15, Font = FONT_B, TextColor3 = fg })
    local btn = Button(root, { ZIndex = 3 })
    addPress(btn, root, 0.97)
    btn.Activated:Connect(function()
        if UI.scrolled then return end
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    return root
end

local function Swatch(parent, x, y, d, col, selected, onClick)
    local root = Frame(parent, { Name = "Swatch", Position = off(x, y), Size = off(d, d), BackgroundColor3 = col })
    Corner(root, "full")
    local ring = Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(d + 8, d + 8), BackgroundTransparency = 1 })
    Corner(ring, "full")
    local rs = Stroke(ring, C.white, selected and 0.1 or 1, 2)
    local btn = Button(root, { ZIndex = 3 })
    btn.Activated:Connect(function()
        if UI.scrolled then return end
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    return { set = function(v) tw(rs, 0.2, { Transparency = v and 0.1 or 1 }) end }
end

local function Input(parent, x, y, w, h, icon, placeholder, size)
    local root = Frame(parent, { Name = "Input", Position = off(x, y), Size = off(w, h), BackgroundColor3 = rgb(16, 15, 34), BackgroundTransparency = 0.45 })
    Corner(root, 16)
    local stroke = Stroke(root, C.white, 0.9, 1)
    local ic = Icon(root, icon, 18, rgb(150, 150, 182), { Position = off(15, (h - 18) / 2) })
    local box = New("TextBox", {
        Name = "Box", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = off(46, 0), Size = off(w - 58, h), Font = FONT_M, TextSize = size or 16,
        TextColor3 = C.txt, PlaceholderText = placeholder, PlaceholderColor3 = rgb(112, 113, 144),
        Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
    }, root)
    box.Focused:Connect(function() tw(stroke, 0.2, { Transparency = 0.35, Color = theme.a }); tw(root, 0.2, { BackgroundTransparency = 0.3 }) end)
    box.FocusLost:Connect(function() tw(stroke, 0.2, { Transparency = 0.9, Color = C.white }); tw(root, 0.2, { BackgroundTransparency = 0.45 }) end)
    return root, box, stroke, ic
end

-- Колонка-конструктор
local Column = {}
Column.__index = Column

local function newColumn(parent, x, y0, w)
    local c = setmetatable({}, Column)
    c.w, c.y = w, y0
    c.holder = Frame(parent, { Name = "Col", BackgroundTransparency = 1, Position = off(x, 0), Size = off(w, 10) })
    return c
end

function Column:row(h, opts)
    opts = opts or {}
    local r = Frame(self.holder, { Name = "Row", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, h) })
    if opts.sep ~= false then
        Frame(r, { Name = "sep", Position = off(0, h - 1), Size = off(self.w, 1), BackgroundTransparency = 0.93 })
    end
    self.y = self.y + h
    return r
end

function Column:header(title, icon, hint, topGap)
    self.y = self.y + (topGap or 0)
    local r = Frame(self.holder, { Name = "Header", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, 26) })
    local badge = Frame(r, { Size = off(26, 26), BackgroundColor3 = rgb(140, 130, 235), BackgroundTransparency = 0.78 })
    Corner(badge, "full"); Stroke(badge, C.white, 0.9, 1)
    Icon(badge, icon, 14, rgb(196, 188, 255), { Position = off(6, 6) })
    Label(r, { Position = off(36, 0), Size = off(self.w - 36, 26), Text = title, TextSize = 15 })
    if hint then
        Label(r, { AnchorPoint = V2(1, 0), Position = off(self.w, 0), Size = off(self.w * 0.55, 26), Text = hint, TextSize = 12, TextColor3 = C.txt3, TextXAlignment = Enum.TextXAlignment.Right })
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
    Label(r, { Position = off(0, 7), Size = off(self.w - 70, 22), Text = title, TextSize = 15.5 })
    if desc then
        Label(r, { Position = off(0, 29), Size = off(maxW, 18 + extra), Text = desc, TextSize = size, TextColor3 = C.txt3, Font = FONT_R, TextWrapped = lines > 1, TextYAlignment = Enum.TextYAlignment.Top })
    end
    local t = Toggle(r, self.w - 58, desc and 10 or 4, State[key], function()
        local nv = not State[key]
        setState(key, nv)
        if onChange then onChange(nv) end
    end)
    bindState(key, function(v, instant) t.set(v, instant) end)
    table.insert(UI.searchItems, { row = r, text = string.lower(title .. " " .. (desc or "")) })
    return r, t
end

function Column:slider(key, title, desc, cfg, opts)
    local size, lines = 12, 1
    if desc then size, lines = fitDesc(desc, self.w) end
    local extra = (lines - 1) * 11
    local h = (desc and 82 or 68) + extra
    local r = self:row(h, opts)
    Label(r, { Position = off(0, 2), Size = off(self.w - 96, 20), Text = title, TextSize = 15 })
    local val = Label(r, { AnchorPoint = V2(1, 0), Position = off(self.w, 2), Size = off(96, 20), TextSize = 13.5, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Right })
    if desc then
        Label(r, { Position = off(0, 22), Size = off(self.w, 16 + extra), Text = desc, TextSize = size, TextColor3 = C.txt3, Font = FONT_R, TextWrapped = lines > 1, TextYAlignment = Enum.TextYAlignment.Top })
    end
    cfg.label = val; cfg.value = State[key]
    local userCb = cfg.onChange
    cfg.onChange = function(v) State[key] = v; if userCb then userCb(v) end end
    local s = Slider(r, 0, (desc and 42 or 28) + extra, self.w, cfg)
    table.insert(UI.searchItems, { row = r, text = string.lower(title .. " " .. (desc or "")) })
    return r, s
end

function Column:segment(label, options, selected, onSelect, opts)
    local h = label and 74 or 50
    local r = self:row(h, opts)
    if label then Label(r, { Position = off(0, 2), Size = off(self.w, 20), Text = label, TextSize = 15 }) end
    local seg = Segmented(r, 0, label and 28 or 6, self.w, options, selected, onSelect)
    if label then table.insert(UI.searchItems, { row = r, text = string.lower(label) }) end
    return r, seg
end

function Column:palette(label, selectedIdx, onPick, opts)
    local r = self:row(72, opts)
    Label(r, { Position = off(0, 4), Size = off(self.w, 20), Text = label, TextSize = 15 })
    local sw = {}
    local step = (self.w - 26) / (#PALETTE - 1)
    for i, col in ipairs(PALETTE) do
        sw[i] = Swatch(r, (i - 1) * step, 34, 26, col, i == selectedIdx, function()
            for j, o in ipairs(sw) do o.set(j == i) end
            if onPick then onPick(i, col) end
        end)
    end
    table.insert(UI.searchItems, { row = r, text = string.lower(label) })
    return r
end

function Column:button(text, icon, style, onClick, opts)
    local r = self:row(54, opts)
    MakeButton(r, 0, 5, self.w, 42, text, icon, style, onClick)
    table.insert(UI.searchItems, { row = r, text = string.lower(text) })
    return r
end

----------------------------------------------------------------------
-- 3D ПРЕВЬЮ БЕКОНА (ПОЛНЫЙ ФИКС ЧАМСОВ НА ВСЁ ТЕЛО + ШЛЯПА + ESP)
----------------------------------------------------------------------
local function BuildBaconPreview(parent, x, y, w, h, isWinOpenFn)
    local card = Frame(parent, {
        Name = "BaconPreviewCard", Position = off(x, y), Size = off(w, h),
        BackgroundColor3 = rgb(14, 13, 28), BackgroundTransparency = 0.2, ClipsDescendants = true,
    })
    Corner(card, 18); Stroke(card, C.white, 0.86, 1)

    local bgGrad = Frame(card, { Size = sc(1, 1), BackgroundTransparency = 0.65, ZIndex = 1 })
    Corner(bgGrad, 18); Grad(bgGrad, rgb(42, 36, 84), rgb(14, 13, 28), 90)

    local nameBadge = Frame(card, { Position = off(12, 12), Size = off(116, 26), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    Corner(nameBadge, "full"); Stroke(nameBadge, C.white, 0.85, 1)
    Corner(Frame(nameBadge, { Position = off(9, 9), Size = off(8, 8), BackgroundColor3 = theme.a }), "full")
    Label(nameBadge, { Position = off(22, 0), Size = off(88, 26), Text = "Bacon 3D", TextSize = 12 })

    local autoSpin = true
    local spinBtn = Frame(card, { Position = off(w - 72, 12), Size = off(28, 28), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    Corner(spinBtn, "full"); Stroke(spinBtn, C.white, 0.85, 1)
    local spinIcon = Icon(spinBtn, "undo", 14, theme.a, { Position = off(7, 7) })
    local spinHit = Button(spinBtn, { ZIndex = 5 })
    addPress(spinHit, spinBtn, 0.9)

    local resetBtn = Frame(card, { Position = off(w - 38, 12), Size = off(28, 28), BackgroundColor3 = rgb(20, 18, 42), BackgroundTransparency = 0.22, ZIndex = 4 })
    Corner(resetBtn, "full"); Stroke(resetBtn, C.white, 0.85, 1)
    Icon(resetBtn, "target", 14, C.txt2, { Position = off(7, 7) })
    local resetHit = Button(resetBtn, { ZIndex = 5 })
    addPress(resetHit, resetBtn, 0.9)

    local vp = New("ViewportFrame", {
        Name = "BaconVP", Position = off(0, 34), Size = off(w, h - 56),
        BackgroundTransparency = 1, Ambient = rgb(212, 218, 230),
        LightColor = C.white, LightDirection = Vector3.new(-0.5, -1, 0.8),
        Active = true, ZIndex = 2,
    }, card)

    -- 2D ESP-элементы поверх 3D-Бекона (живой отклик на тумблеры ESP!)
    local espBox = Frame(vp, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.53), Size = off(122, 184), BackgroundTransparency = 1, ZIndex = 3 })
    Corner(espBox, 4)
    local espBoxStroke = Stroke(espBox, State.espColor, 0.1, 1.6)

    local espNick = Label(vp, {
        AnchorPoint = V2(0.5, 1), Position = UDim2.new(0.5, 0, 0.53, -96),
        Size = off(150, 16), Text = "Bacon Hair", TextSize = 11, Font = FONT_B,
        TextColor3 = C.white, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
    })
    local espDist = Label(vp, {
        AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, 0.53, 96),
        Size = off(100, 14), Text = "16 м", TextSize = 10, Font = FONT_M,
        TextColor3 = State.espColor, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4,
    })
    local hpBg = Frame(vp, { AnchorPoint = V2(1, 0.5), Position = UDim2.new(0.5, -66, 0.53, 0), Size = off(4, 184), BackgroundColor3 = rgb(14, 14, 24), BackgroundTransparency = 0.2, ZIndex = 4 })
    Corner(hpBg, "full")
    local hpFill = Frame(hpBg, { AnchorPoint = V2(0, 1), Position = sc(0, 1), Size = sc(1, 0.86), BackgroundColor3 = C.green })
    Corner(hpFill, "full")

    Label(card, { Position = off(0, h - 22), Size = off(w, 18), Text = "Потяни пальцем, чтобы крутить 3D-Бекона", TextSize = 11, TextColor3 = C.txt3, Font = FONT_R, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })

    local world = New("WorldModel", {}, vp)
    local cam = New("Camera", { FieldOfView = 38 }, vp)
    vp.CurrentCamera = cam

    -- Самурайская шляпа на 3D-Беконе в превью
    local previewHat = CreateSamuraiHat(world, "PreviewSamuraiHat")

    local visuals = {
        model = nil, humanoid = nil, bodyColors = nil, headPart = nil,
        parts = {}, meshes = {}, decals = {}, clothes = {},
    }
    local camDist = 9.4

    -- КЛЮЧЕВОЙ ФИКС: при Chams снимаем Humanoid и BodyColors, чтобы светилось ВСЁ тело, а не только волосы!
    local function RefreshPreview()
        local col = State.espColor
        espBox.Visible = State.espBox
        espBoxStroke.Color = col
        espNick.Visible = State.espNick
        espDist.Visible = State.espDist
        espDist.TextColor3 = col
        hpBg.Visible = State.espHealth

        local mode = State.chamsMode
        local chamsOn = (mode ~= 1)
        local mat = (mode == 2 and Enum.Material.Neon)
            or (mode == 3 and Enum.Material.SmoothPlastic)
            or Enum.Material.ForceField
        local chamsT = (mode == 4) and math.clamp(State.chamsTrans / 100, 0.25, 0.85) or (State.chamsTrans / 100 * 0.45)

        if visuals.humanoid then
            visuals.humanoid.Parent = chamsOn and nil or visuals.model
        end
        if visuals.bodyColors then
            visuals.bodyColors.Parent = chamsOn and nil or visuals.model
        end
        for _, cl in ipairs(visuals.clothes) do
            if cl.obj then cl.obj.Parent = chamsOn and nil or visuals.model end
        end
        for _, dc in ipairs(visuals.decals) do
            if dc.decal then dc.decal.Transparency = chamsOn and 1 or dc.origTrans end
        end
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
                    info.part.Color = col
                    info.part.Material = mat
                    info.part.Transparency = chamsT
                else
                    info.part.Color = info.origColor
                    info.part.Material = info.origMat
                    info.part.Transparency = info.origTrans
                end
            end
        end
    end

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
            visuals.humanoid.PlatformStand = true
            visuals.humanoid.AutoRotate = false
        end

        model.Parent = world
        local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if hrp then
            hrp.Anchored = true
            model.PrimaryPart = hrp
            model:PivotTo(CFrame.new(0, 0, 0))
        end

        RunService.Heartbeat:Wait()

        -- Фиксируем все части на местах, чтобы снятие Humanoid при Chams не сдвигало конечности!
        local bbCF, bbSize = model:GetBoundingBox()
        local shift = -bbCF.Position
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CFrame = obj.CFrame + shift
            end
        end

        visuals.headPart = model:FindFirstChild("Head")
        camDist = math.clamp(bbSize.Y * 1.65, 8.8, 11.4)

        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                if obj.Name == "HumanoidRootPart" then
                    obj.Transparency = 1
                else
                    table.insert(visuals.parts, { part = obj, origColor = obj.Color, origMat = obj.Material, origTrans = obj.Transparency })
                end
                if obj:IsA("MeshPart") and obj.TextureID ~= "" then
                    table.insert(visuals.meshes, { mesh = obj, origTex = obj.TextureID })
                end
            elseif obj:IsA("SpecialMesh") and obj.TextureId ~= "" then
                table.insert(visuals.meshes, { mesh = obj, origTex = obj.TextureId })
            elseif obj:IsA("Decal") then
                table.insert(visuals.decals, { decal = obj, origTrans = obj.Transparency })
            elseif obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                table.insert(visuals.clothes, { obj = obj })
            end
        end

        RefreshPreview()
    end

    -- Загрузка настоящего 3D Бекона Roblox
    task.spawn(function()
        local skinGray = rgb(205, 206, 208)
        local okDesc, model = pcall(function()
            local desc = Instance.new("HumanoidDescription")
            desc.HairAccessory = "63690008"
            desc.Shirt = 144076358
            desc.Pants = 144076760
            desc.Face  = 144080495
            desc.HeadColor = skinGray; desc.TorsoColor = skinGray
            desc.LeftArmColor = skinGray; desc.RightArmColor = skinGray
            desc.LeftLegColor = skinGray; desc.RightLegColor = skinGray
            return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
        end)

        if okDesc and model then MountModel(model); return end

        -- Резервная сборка для Delta через game:GetObjects
        local rig = New("Model", { Name = "BaconHairR6" })
        New("Humanoid", { RigType = Enum.HumanoidRigType.R6 }, rig)
        local function R6(name, sz, cf)
            return New("Part", {
                Name = name, Size = sz, CFrame = cf, Color = skinGray,
                Material = Enum.Material.SmoothPlastic, Anchored = true,
                TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
            }, rig)
        end
        R6("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0)).Transparency = 1
        R6("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 0, 0))
        local head = R6("Head", Vector3.new(2, 1, 1), CFrame.new(0, 1.5, 0))
        New("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25) }, head)
        R6("Left Arm",  Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0))
        R6("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0))
        R6("Left Leg",  Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0))
        R6("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0))
        New("Decal", { Name = "face", Face = Enum.NormalId.Front, Texture = "rbxasset://textures/face.png" }, head)

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

    -- Вращение пальцем/мышью
    local camYaw, camPitch = 18, 8
    local dragging3D = false

    spinHit.Activated:Connect(function()
        if UI.scrolled then return end
        UI.pressFx(spinBtn)
        autoSpin = not autoSpin
        setIconColor(spinIcon, autoSpin and theme.a or C.txt3, false)
    end)
    resetHit.Activated:Connect(function()
        if UI.scrolled then return end
        UI.pressFx(resetBtn)
        camYaw, camPitch = 0, 8
    end)

    vp.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        dragging3D = true
        UI.scrollLock(true)
        local lastPos = V2(input.Position.X, input.Position.Y)
        beginDrag(function(i)
            local cur = V2(i.Position.X, i.Position.Y)
            local d = cur - lastPos; lastPos = cur
            camYaw = camYaw - d.X * 0.9
            camPitch = math.clamp(camPitch + d.Y * 0.45, -28, 35)
        end, function()
            dragging3D = false
            UI.scrollLock(false)
        end)
    end)

    local spinHat = 0
    bind(RunService.RenderStepped, function(dt)
        spinHat = (spinHat + dt * 0.9) % (math.pi * 2)
        local hatCol = State.hatRgb and Color3.fromHSV((os.clock() * 0.25) % 1, 0.85, 1) or State.hatColor

        -- Обновляем самурайскую шляпу в мире на LocalPlayer
        local char = LocalPlayer.Character
        local head = char and char:FindFirstChild("Head")
        UpdateSamuraiHat(worldHat, head and head.CFrame or nil, State.hatEnabled, State.hatSize, State.hatHeight, State.hatTrans, hatCol, State.hatMat, spinHat)

        if not isWinOpenFn() then return end

        -- Обновляем 3D-камеру Бекона и шляпу на нём
        if autoSpin and not dragging3D then camYaw = camYaw + dt * 24 end
        local rotCF = CFrame.Angles(0, math.rad(camYaw), 0) * CFrame.Angles(math.rad(-camPitch), 0, 0)
        cam.CFrame = CFrame.lookAt(rotCF * Vector3.new(0, 0.2, -camDist), Vector3.new(0, 0.2, 0))

        local prevHeadCF = visuals.headPart and visuals.headPart.CFrame or CFrame.new(0, 1.5, 0)
        UpdateSamuraiHat(previewHat, prevHeadCF, State.hatEnabled, State.hatSize, State.hatHeight, State.hatTrans, hatCol, State.hatMat, spinHat)
    end)

    return { refresh = RefreshPreview }
end

----------------------------------------------------------------------
-- ЕДИНСТВЕННАЯ ВКЛАДКА: ВИЗУАЛ (3D БЕКОН + ESP + САМУРАЙСКАЯ ШЛЯПА + ШЕЙДЕРЫ)
----------------------------------------------------------------------
local function BuildVisualPage(page, isWinOpenFn)
    table.clear(UI.searchItems)
    local s = page.scroller
    Label(s, { Position = off(26, 12), Size = off(420, 38), Text = "Визуал", TextSize = 28, Font = FONT_B, TextColor3 = rgb(236, 230, 255) })
    Label(s, { Position = off(26, 50), Size = off(520, 22), Text = "3D предпросмотр, ESP, самурайская шляпа и шейдеры", TextSize = 13.5, TextColor3 = C.txt2 })

    local LX, RX, COLW = 26, 422, 372
    local L = newColumn(s, LX, 90, COLW)
    local R = newColumn(s, RX, 90, COLW)

    -- ЛЕВАЯ КОЛОНКА: 3D Бекон + Чамсы + Шейдеры
    L:header("3D Предпросмотр", "eye", "Бекон + Каса")
    local preview = BuildBaconPreview(L.holder, 0, L.y, COLW, 306, isWinOpenFn)
    L.y = L.y + 314

    L:segment("Стиль чамсов (на всё тело)", { "Обычный", "Glow", "Flat", "Glass" }, State.chamsMode, function(idx, name)
        State.chamsMode = idx
        preview.refresh()
        UpdateAllESP()
        UI.toast("Чамсы: " .. name, "sparkle")
    end)

    -- ШЕЙДЕРЫ
    L:header("Шейдеры (Освещение)", "sun", "8 пресетов", 14)

    -- 2 ряда пресетов шейдеров (по 4 в ряд)
    do
        local row1Names = { "Оригинал", "RTX", "Кибер", "Закат" }
        local row2Names = { "Аниме", "Нуар", "Зима", "Vapor" }
        local seg1, seg2

        local r1 = L:row(46, { sep = false })
        seg1 = Segmented(r1, 0, 4, COLW, row1Names, 1, function(i)
            seg2.set(0, true)
            ApplyShaderPreset(i)
            UI.toast("Шейдер: " .. SHADER_PRESETS[i].name, "sun")
        end)

        local r2 = L:row(50)
        seg2 = Segmented(r2, 0, 4, COLW, row2Names, 1, function(i)
            seg1.set(0, true)
            ApplyShaderPreset(i + 4)
            UI.toast("Шейдер: " .. SHADER_PRESETS[i + 4].name, "sun")
        end)
        -- изначально выбран "Оригинал" (первый ряд), второй без подсветки
        seg2.frame.Pill.Visible = false
        for _, btn in ipairs(seg2.frame:GetChildren()) do
            if btn:IsA("TextButton") then
                local lbl = btn:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = rgb(176, 177, 206) end
            end
        end

        -- патчим set(0), чтобы скрывать пилюлю в неактивном ряду
        local origSet1, origSet2 = seg1.set, seg2.set
        seg1.set = function(i, inst)
            if i == 0 then seg1.frame.Pill.Visible = false else seg1.frame.Pill.Visible = true; origSet1(i, inst) end
        end
        seg2.set = function(i, inst)
            if i == 0 then seg2.frame.Pill.Visible = false else seg2.frame.Pill.Visible = true; origSet2(i, inst) end
        end
        table.insert(UI.searchItems, { row = r1, text = "шейдеры оригинал rtx киберпанк закат" })
        table.insert(UI.searchItems, { row = r2, text = "шейдеры аниме нуар зима vaporwave" })
    end

    L:toggle("shBloom", "Свечение (Bloom)", "Мягкое сияние ярких объектов", function() ApplyManualShaders() end)
    _, ShaderSliders.bloomInt = L:slider("shBloomInt", "Сила свечения", nil, { min = 0, max = 3, step = 0.05, fmt = function(v) return string.format("%.2f", v) end, onChange = function() ApplyManualShaders() end })
    L:toggle("shSunRays", "Лучи солнца (SunRays)", "Объёмные солнечные лучи", function() ApplyManualShaders() end)
    L:toggle("shDof", "Глубина резкости (DOF)", "Мягкое размытие дальнего фона", function() ApplyManualShaders() end)
    _, ShaderSliders.sat = L:slider("shSat", "Насыщенность", nil, { min = -1, max = 1, step = 0.05, fmt = function(v) return string.format("%+.2f", v) end, onChange = function() ApplyManualShaders() end })
    _, ShaderSliders.contrast = L:slider("shContrast", "Контраст", nil, { min = -0.5, max = 0.8, step = 0.05, fmt = function(v) return string.format("%+.2f", v) end, onChange = function() ApplyManualShaders() end })
    _, ShaderSliders.clock = L:slider("shClock", "Время суток", nil, { min = 0, max = 24, step = 0.5, fmt = function(v) return string.format("%.1f ч", v) end, onChange = function() ApplyManualShaders() end })
    _, ShaderSliders.bright = L:slider("shBright", "Яркость мира", nil, { min = 0.5, max = 5, step = 0.1, fmt = function(v) return string.format("%.1f", v) end, onChange = function() ApplyManualShaders() end })
    _, ShaderSliders.blur = L:slider("shBlur", "Размытие экрана", nil, { min = 0, max = 24, step = 1, fmt = function(v) return string.format("%d px", v) end, onChange = function() ApplyManualShaders() end })
    L:button("Сбросить шейдеры", "undo", "ghost", function()
        ApplyShaderPreset(1)
        UI.toast("Шейдеры сброшены к оригиналу", "undo")
    end, { sep = false })

    -- ПРАВАЯ КОЛОНКА: Банальный ESP + Самурайская шляпа (Каса / China Hat)
    R:header("Банальный ESP", "target", "Игроки + Превью")
    R:toggle("espEnabled", "ESP Включено", "Включает подсветку и метки на игроках", function() UpdateAllESP() end)
    R:toggle("espChams", "Чамсы (Highlight)", "Подсветка моделей сквозь стены", function() UpdateAllESP() end)
    R:toggle("espBox", "Бокс", "2D рамка вокруг игрока", function() preview.refresh(); UpdateAllESP() end)
    R:toggle("espNick", "Ники", "Имя игрока сверху", function() preview.refresh(); UpdateAllESP() end)
    R:toggle("espDist", "Дистанция", "Расстояние в метрах снизу", function() preview.refresh(); UpdateAllESP() end)
    R:toggle("espHealth", "Полоска HP", "Здоровье сбоку от рамки", function() preview.refresh(); UpdateAllESP() end)
    R:slider("chamsTrans", "Прозрачность чамсов", nil, {
        min = 5, max = 95, step = 5,
        fmt = function(v) return string.format("%d%%", v) end,
        onChange = function() preview.refresh(); UpdateAllESP() end,
    })
    R:palette("Цвет ESP и чамсов", State.espColorIdx, function(i, col)
        State.espColorIdx = i; State.espColor = col
        preview.refresh(); UpdateAllESP()
    end)

    -- САМУРАЙСКАЯ ШЛЯПА (КАСА / CHINA HAT)
    R:header("Самурайская шляпа (Каса)", "hat", "На голове + 3D", 14)
    R:toggle("hatEnabled", "Включить шляпу", "Коническая самурайская шляпа над головой")
    R:toggle("hatRgb", "Радуга (RGB)", "Плавный перелив всех цветов")
    R:slider("hatSize", "Размер шляпы", "Ширина полей и высота конуса", {
        min = 0.5, max = 3.0, step = 0.05,
        fmt = function(v) return string.format("%.2fx", v) end,
    })
    R:slider("hatHeight", "Высота над головой", nil, {
        min = -0.3, max = 2.0, step = 0.05,
        fmt = function(v) return string.format("%+.2f", v) end,
    })
    R:slider("hatTrans", "Прозрачность шляпы", nil, {
        min = 0, max = 95, step = 5,
        fmt = function(v) return string.format("%d%%", v) end,
    })
    R:segment("Материал шляпы", { "Neon", "Glass", "Flat", "Field" }, State.hatMat, function(i)
        State.hatMat = i
    end)
    R:palette("Цвет шляпы", State.hatColorIdx, function(i, col)
        State.hatColorIdx = i; State.hatColor = col
    end, { sep = false })

    page.setHeight(math.max(L.y, R.y) + 32)
end

----------------------------------------------------------------------
-- 3D-ИНТРО БУКВЫ "F" С ПЕРЕЛЁТОМ ТОЧНО В ШАР (ORB)
----------------------------------------------------------------------
local function RunIntro3DF(orb, orbScale, getOrbTargetPos)
    local DimOverlay = Frame(gui, { Name = "IntroDim", Size = sc(1, 1), BackgroundColor3 = rgb(6, 7, 16), BackgroundTransparency = 1, ZIndex = 48 })
    local IntroVP = New("ViewportFrame", {
        Name = "Intro3DF", Size = sc(1, 1), BackgroundTransparency = 1,
        Ambient = rgb(160, 168, 210), LightColor = C.white, LightDirection = Vector3.new(-1, -1, 1), ZIndex = 50,
    }, gui)

    local IntroWorld = New("WorldModel", {}, IntroVP)
    local IntroCam = New("Camera", { FieldOfView = 42, CFrame = CFrame.lookAt(Vector3.new(0, 0, -13.5), Vector3.zero) }, IntroVP)
    IntroVP.CurrentCamera = IntroCam

    local introBars = {}
    local function Create3DBar(w, h, targetCF, startCF)
        local rim  = New("Part", { Size = Vector3.new(w, h, 0.58), Color = rgb(225, 222, 255), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
        local face = New("Part", { Size = Vector3.new(w - 0.14, h - 0.14, 0.10), Color = rgb(118, 114, 178), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
        local back = New("Part", { Size = Vector3.new(w - 0.14, h - 0.14, 0.10), Color = rgb(118, 114, 178), Material = Enum.Material.SmoothPlastic, Anchored = true }, IntroWorld)
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

    task.spawn(function()
        -- ждём 2 кадра, чтобы экран гарантированно инициализировался
        RunService.RenderStepped:Wait()
        RunService.RenderStepped:Wait()
        tw(DimOverlay, 0.35, { BackgroundTransparency = 0.52 })

        local startClock = os.clock()
        local baseTilt = CFrame.Angles(0, 0, math.rad(-22))
        local faceBase, faceFlash = rgb(118, 114, 178), rgb(248, 246, 255)
        local dimCleared, landed = false, false

        local introConn
        introConn = bind(RunService.RenderStepped, function()
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

                if not dimCleared then
                    dimCleared = true
                    tw(DimOverlay, 0.45, { BackgroundTransparency = 1 })
                end

                local scr = viewport()
                local W, H = scr.X, scr.Y
                local targetUDim, targetPxPos = getOrbTargetPos()
                orb.Position = targetUDim

                local halfTan = math.tan(math.rad(IntroCam.FieldOfView * 0.5))
                local startPx = (4.3 * H) / (2 * 13.5 * halfTan)
                local targetPx = 28 * baseScale()

                local curX = (W * 0.5) + (targetPxPos.X - W * 0.5) * e
                local curY = (H * 0.5) + (targetPxPos.Y - H * 0.5) * e - math.sin(p * math.pi) * (35 * baseScale())
                local curPx = startPx + (targetPx - startPx) * e

                local worldPos = ScreenToWorldPos(curX, curY, curPx, W, H)
                local worldCF = CFrame.new(worldPos) * CFrame.Angles(0, math.sin(p * math.pi) * 1.1, math.rad(-22 + 6 * e))

                local fade = math.clamp((p - 0.91) / 0.09, 0, 1)
                for _, bar in ipairs(introBars) do
                    PlaceBar(bar, worldCF * bar.target)
                    bar.rim.Transparency = fade; bar.face.Transparency = fade; bar.back.Transparency = fade
                end

                if p >= 0.91 and not landed then
                    landed = true
                    orb.Visible = true
                    orbScale.Scale = baseScale() * 0.25
                    tw(orbScale, 0.55, { Scale = baseScale() }, Back, Out)
                    UI.toast("Finis Visual готов — нажми на шар F", "sparkle")
                end
            else
                introConn:Disconnect()
                if not landed then orb.Visible = true; tw(orbScale, 0.5, { Scale = baseScale() }, Back, Out) end
                IntroVP:Destroy(); DimOverlay:Destroy()
            end
        end)
    end)
end

----------------------------------------------------------------------
-- ОБОЛОЧКА МЕНЮ (FINIS VISUAL)
----------------------------------------------------------------------
local function BuildShell()
    local toastHost = Frame(gui, { Name = "Toasts", BackgroundTransparency = 1, Size = sc(1, 1), ZIndex = 60 })
    local curToast

    function UI.toast(text, iconName)
        if curToast then pcall(function() curToast:Destroy() end) end
        local w = measure(text, 15, FONT_M) + 84
        local pill = Frame(toastHost, {
            Name = "Toast", AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, -0.14, 0),
            Size = off(w, 46), BackgroundColor3 = rgb(15, 14, 32), BackgroundTransparency = 0.1,
        })
        curToast = pill
        Corner(pill, "full"); Stroke(pill, C.white, 0.86, 1)
        New("UIScale", { Scale = baseScale() }, pill)
        local ic = Frame(pill, { Position = off(9, 9), Size = off(28, 28), BackgroundColor3 = rgb(150, 140, 235), BackgroundTransparency = 0.68 })
        Corner(ic, "full"); Icon(ic, iconName or "check", 14, rgb(214, 206, 255), { Position = off(7, 7) })
        Label(pill, { Position = off(48, 0), Size = off(w - 60, 44), Text = text, TextSize = 15 })
        local bar = Frame(pill, { Position = off(48, 40), Size = off(w - 70, 2) })
        Corner(bar, "full"); accentGradient(bar, 0)
        tw(pill, 0.5, { Position = UDim2.new(0.5, 0, 0.035, 0) }, Back, Out)
        TweenService:Create(bar, TweenInfo.new(1.7, Enum.EasingStyle.Linear), { Size = off(0, 2) }):Play()
        task.delay(1.85, function()
            if curToast == pill then
                tw(pill, 0.35, { Position = UDim2.new(0.5, 0, -0.14, 0) }, Quint, In)
                task.delay(0.4, function() pcall(function() pill:Destroy() end); if curToast == pill then curToast = nil end end)
            end
        end)
    end

    local userScale = 1
    local function curScale() return baseScale() * userScale end
    local winOpen, cardOpen, authed = false, false, false

    local topbarWas
    function UI.syncTopbar()
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
    onCleanup(function() winOpen = false; cardOpen = false; UI.syncTopbar() end)

    -- Шар Orb с логотипом F
    local ORB = 74
    local function getOrbTargetPos()
        local scr = viewport()
        local rad = (ORB * baseScale()) * 0.5
        local px = math.max(scr.X * 0.055, rad + 16)
        local py = math.min(scr.Y * 0.87, scr.Y - rad - 16)
        return UDim2.fromScale(px / scr.X, py / scr.Y), V2(px, py)
    end

    local orb = Frame(gui, {
        Name = "Orb", AnchorPoint = V2(0.5, 0.5), Position = getOrbTargetPos(),
        Size = off(ORB, ORB), BackgroundColor3 = C.white, BackgroundTransparency = 0.1, Visible = false, ZIndex = 20,
    })
    Corner(orb, "full"); Grad(orb, rgb(88, 78, 152), rgb(30, 27, 60), 135); Stroke(orb, rgb(190, 180, 255), 0.7, 1.5)
    local orbScale = New("UIScale", { Scale = 0.01 }, orb)
    local arc = Frame(orb, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(ORB + 2, ORB + 2), BackgroundTransparency = 1 })
    Corner(arc, "full")
    local arcGrad = New("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.26, 0.55), NumberSequenceKeypoint.new(0.34, 1), NumberSequenceKeypoint.new(1, 1) }),
    }, Stroke(arc, rgb(232, 224, 255), 0, 2.4))
    makeLogoF(orb, 32, false, false).Position = off((ORB - 48) / 2, (ORB - 32) / 2)
    local orbBtn = Button(orb, { ZIndex = 5 })

    local function snapOrb()
        local scr = viewport()
        local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
        local goalX = ((a.X + sz.X / 2) < scr.X / 2) and (sz.X / 2 + 14) or (scr.X - sz.X / 2 - 14)
        local cy = math.clamp(a.Y + sz.Y / 2, sz.Y / 2 + 10, scr.Y - sz.Y / 2 - 10)
        tw(orb, 0.45, { Position = UDim2.fromScale(goalX / scr.X, cy / scr.Y) }, Back, Out)
    end

    orbBtn.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        local startPos = input.Position
        local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
        local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
        local moved = false
        tw(orbScale, 0.12, { Scale = baseScale() * 0.9 }, Quad, Out)
        beginDrag(function(i)
            local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
            if not moved and (math.abs(dx) + math.abs(dy)) > 8 then moved = true end
            if moved then
                local scr = viewport()
                orb.Position = UDim2.fromScale(math.clamp((startCenter.X + dx) / scr.X, 0.02, 0.98), math.clamp((startCenter.Y + dy) / scr.Y, 0.04, 0.96))
            end
        end, function()
            tw(orbScale, 0.12, { Scale = baseScale() }, Quad, Out)
            if moved then snapOrb() else UI.orbTap() end
        end)
    end)

    -- Главное окно
    local winBaseT = 0.13
    local win = Frame(gui, {
        Name = "Window", AnchorPoint = V2(0.5, 0.5), Position = homeCenter(), Size = off(WIN_W, WIN_H),
        BackgroundColor3 = C.white, BackgroundTransparency = winBaseT, Visible = false,
        ClipsDescendants = true, Active = true, ZIndex = 12,
    })
    Corner(win, 28); Grad(win, rgb(86, 82, 146), rgb(32, 28, 64), 120)
    local winStroke = Stroke(win, C.white, 0.35, 1.5)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.35, 0.62), NumberSequenceKeypoint.new(1, 0.82) }) }, winStroke)
    local winScale = New("UIScale", { Scale = 1 }, win)

    local particleLayer = Frame(win, { Name = "Particles", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ClipsDescendants = true, ZIndex = 1 })
    local body = Frame(win, { Name = "Body", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ZIndex = 2 })
    local fx   = Frame(win, { Name = "Fx", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ZIndex = 30 })

    -- Шапка окна
    local header = Frame(body, { Name = "Header", BackgroundTransparency = 1, Size = off(WIN_W, HEAD_H) })
    local headDrag = Button(header, { Name = "DragHandle", Size = off(WIN_W, HEAD_H), ZIndex = 1 })
    local hLogo = makeLogoF(header, 40, true, true); hLogo.Position = off(14, 19); hLogo.ZIndex = 2
    local hTitle = Label(header, { Position = off(83, 13), Size = off(220, 32), Text = "Finis Visual", TextSize = 25, Font = FONT_B, ZIndex = 2 })
    Grad(hTitle, rgb(255, 250, 255), rgb(212, 190, 255), 0)
    Label(header, { Position = off(84, 46), Size = off(240, 14), Text = "FINIS VISUAL  ·  ROBLOX", TextSize = 9.5, TextColor3 = C.txt4, ZIndex = 2 })

    local searchWrap, searchBox = Input(header, 320, 21, 355, 38, "search", "Поиск...", 14)
    searchWrap.ZIndex = 3
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(trim(searchBox.Text))
        for _, item in ipairs(UI.searchItems) do
            if item.row and item.row.Parent then
                item.row.Visible = (q == "" or string.find(item.text, q, 1, true) ~= nil)
            end
        end
    end)

    do
        local pill = Frame(header, { Position = off(WIN_W - 22 - 36 - 12 - 36 - 12 - 116, 26), Size = off(116, 28), BackgroundTransparency = 0.93, ZIndex = 3 })
        Corner(pill, "full"); Stroke(pill, C.white, 0.88, 1)
        Corner(Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(14, 14), BackgroundColor3 = C.green, BackgroundTransparency = 0.75 }), "full")
        Corner(Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(8, 8), BackgroundColor3 = C.green }), "full")
        Label(pill, { Position = off(31, 0), Size = off(82, 28), Text = "Подключено", TextSize = 12.5 })

        local avFrame = Frame(header, { Position = off(WIN_W - 22 - 36 - 12 - 36, 22), Size = off(36, 36), BackgroundColor3 = rgb(24, 22, 48), BackgroundTransparency = 0.2, ZIndex = 3 })
        Corner(avFrame, "full"); Stroke(avFrame, theme.a, 0.4, 1.4)
        local avImg = New("ImageLabel", { Size = sc(1, 1), BackgroundTransparency = 1, Image = "", ZIndex = 4 }, avFrame)
        Corner(avImg, "full")
        task.spawn(function()
            local ok, thumb = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
            if ok and thumb then avImg.Image = thumb end
        end)

        local x = Frame(header, { Position = off(WIN_W - 22 - 36, 22), Size = off(36, 36), BackgroundTransparency = 0.93, ZIndex = 3 })
        Corner(x, "full"); Stroke(x, C.white, 0.88, 1); Icon(x, "x", 14, rgb(214, 214, 238), { Position = off(11, 11) })
        local xb = Button(x, { ZIndex = 4 }); addPress(xb, x, 0.9)
        xb.Activated:Connect(function() if not UI.scrolled then UI.closeWindow() end end)
    end
    Frame(body, { Position = off(0, HEAD_H - 1), Size = off(WIN_W, 1), BackgroundTransparency = 0.92 })

    -- Боковая панель (только 1 вкладка: Визуал)
    local side = Frame(body, { Name = "Sidebar", BackgroundTransparency = 1, Position = off(0, HEAD_H), Size = off(SIDE_W, PAGE_H) })
    Frame(body, { Position = off(SIDE_W - 1, HEAD_H), Size = off(1, PAGE_H), BackgroundTransparency = 0.93 })
    Label(side, { Position = off(20, PAGE_H - 36), Size = off(150, 14), Text = "FINIS VISUAL  ·  v2.0", TextSize = 9.5, TextColor3 = C.txt4 })

    local selPill = Frame(side, { Position = off(8, 13), Size = off(155, 50), BackgroundTransparency = 0.9 })
    Corner(selPill, 16); Stroke(selPill, C.white, 0.82, 1)
    Corner(Frame(selPill, { Position = off(3, 16), Size = off(3, 18), BackgroundColor3 = theme.b }), "full")
    Icon(side, "eye", 18, rgb(206, 196, 255), { Position = off(30, 29) })
    Label(side, { Position = off(63, 13), Size = off(100, 50), Text = "Визуал", TextSize = 16, TextColor3 = C.white })

    -- Страница «Визуал» + твой инерционный скролл
    local pageHost = Frame(body, { Name = "Pages", BackgroundTransparency = 1, Position = off(SIDE_W, HEAD_H), Size = off(PAGE_W, PAGE_H), ClipsDescendants = true })
    local scroller = New("ScrollingFrame", {
        Name = "VisualScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = off(PAGE_W, PAGE_H),
        CanvasSize = off(0, PAGE_H), ScrollBarThickness = 3, ScrollBarImageColor3 = rgb(206, 196, 255),
        ScrollBarImageTransparency = 0.45, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = false,
    }, pageHost)
    local visualPage = { scroller = scroller, setHeight = function(h) scroller.CanvasSize = off(0, math.max(h, PAGE_H)) end }

    local Scroll = { blocked = false, active = false, moved = false, startY = 0, baseY = 0, lastY = 0, lastT = 0, vel = 0, coast = 0 }
    local function setScrollY(y)
        local maxY = math.max(0, scroller.CanvasSize.Y.Offset - PAGE_H)
        y = math.clamp(y, 0, maxY)
        scroller.CanvasPosition = V2(0, y)
        return y
    end
    function UI.scrollLock(locked) Scroll.blocked = locked end

    local function insidePage(pos)
        local a, s_ = pageHost.AbsolutePosition, pageHost.AbsoluteSize
        local inset = GuiService:GetGuiInset()
        local function hit(y) return pos.X >= a.X and pos.X <= a.X + s_.X and y >= a.Y and y <= a.Y + s_.Y end
        return hit(pos.Y) or hit(pos.Y + inset.Y)
    end

    bind(UserInputService.InputBegan, function(input)
        local t = input.UserInputType
        if (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) then return end
        if not winOpen or Scroll.blocked or not insidePage(input.Position) then return end
        Scroll.active, Scroll.moved = true, false
        Scroll.startY, Scroll.lastY, Scroll.lastT = input.Position.Y, input.Position.Y, os.clock()
        Scroll.vel, Scroll.coast, Scroll.baseY = 0, 0, scroller.CanvasPosition.Y
    end)

    bind(UserInputService.InputChanged, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseWheel then
            if winOpen and not Scroll.blocked then Scroll.coast = 0; setScrollY(scroller.CanvasPosition.Y - input.Position.Z * 80) end
            return
        end
        if not Scroll.active or (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement) then return end
        if Scroll.blocked then Scroll.active = false; return end
        local k = math.max(0.05, winScale.Scale)
        if not Scroll.moved then
            if math.abs(input.Position.Y - Scroll.startY) < 10 * k then return end
            Scroll.moved = true; UI.scrolled = true
            Scroll.startY, Scroll.baseY, Scroll.lastY, Scroll.lastT = input.Position.Y, scroller.CanvasPosition.Y, input.Position.Y, os.clock()
            return
        end
        local now = os.clock()
        setScrollY(Scroll.baseY - (input.Position.Y - Scroll.startY) / k)
        local dt = now - Scroll.lastT
        if dt > 0.001 then Scroll.vel = Scroll.vel * 0.6 + (-(input.Position.Y - Scroll.lastY) / k / dt) * 0.4 end
        Scroll.lastY, Scroll.lastT = input.Position.Y, now
    end)

    bind(UserInputService.InputEnded, function(input)
        local t = input.UserInputType
        if (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) or not Scroll.active then return end
        Scroll.active = false
        if Scroll.moved then
            Scroll.coast = (os.clock() - Scroll.lastT > 0.08) and 0 or Scroll.vel
            task.delay(0.12, function() UI.scrolled = false end)
        else UI.scrolled = false end
    end)

    -- Собираем вкладку «Визуал» сразу (Бекон начнёт грузиться заранее, пока идёт интро!)
    BuildVisualPage(visualPage, function() return winOpen end)

    -- Уголок масштаба + частицы
    local grip = Button(body, { Position = off(WIN_W - 34, WIN_H - 34), Size = off(30, 30), ZIndex = 5 })
    for r = 0, 2 do for c = 0, 2 - r do Corner(Frame(grip, { Position = off(20 - c*6, 20 - r*6), Size = off(2.5, 2.5), BackgroundTransparency = 0.55 }), "full") end end

    local PN, P = 28, {}
    for i = 1, PN do
        local sz = 2 + math.random() * 2.4
        local f = Frame(particleLayer, { Size = off(sz, sz), BackgroundColor3 = rgb(212, 204, 255), BackgroundTransparency = 0.6 })
        Corner(f, "full")
        P[i] = { f = f, x = math.random(30, WIN_W-30), y = math.random(30, WIN_H-30), vy = 5 + math.random()*12, vx = (math.random()-0.5)*8, ph = math.random()*6.28 }
        f.Position = off(P[i].x, P[i].y)
    end

    local function guiToFx(pos)
        local a, k = fx.AbsolutePosition, math.max(0.05, winScale.Scale)
        return V2((pos.X - a.X) / k, (pos.Y - a.Y) / k)
    end
    local function burst(host, x, y, n, spread)
        for _ = 1, n do
            local d = Frame(host, { AnchorPoint = V2(0.5, 0.5), Position = off(x, y), Size = off(5, 5), BackgroundColor3 = theme.a, BackgroundTransparency = 0.1 })
            Corner(d, "full")
            local ang, dist = math.random() * 6.283, spread * (0.5 + math.random() * 0.8)
            tw(d, 0.55, { Position = off(x + math.cos(ang)*dist, y + math.sin(ang)*dist), BackgroundTransparency = 1, Size = off(2, 2) }, Quint, Out)
            task.delay(0.6, function() d:Destroy() end)
        end
    end
    function UI.pressFx(obj)
        if not winOpen then return end
        local a, sz = obj.AbsolutePosition, obj.AbsoluteSize
        local p = guiToFx(V2(a.X + sz.X / 2, a.Y + sz.Y / 2))
        burst(fx, p.X, p.Y, 6, 28)
    end

    local cardFrame
    local function applyScales()
        if winOpen then winScale.Scale = curScale() end
        if cardFrame and cardOpen then cardFrame.UIScale.Scale = curScale() end
        if orb.Visible then orbScale.Scale = baseScale() end
    end

    local function makeDraggable(target, handle, hooks)
        handle.InputBegan:Connect(function(input)
            if not isPress(input) then return end
            local startPos = input.Position
            local a, sz = target.AbsolutePosition, target.AbsoluteSize
            local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
            local moved = false
            beginDrag(function(i)
                local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
                if not moved and (math.abs(dx) + math.abs(dy)) > 6 then moved = true; if hooks and hooks.moved then hooks.moved() end end
                if moved then
                    local scr = viewport()
                    target.Position = UDim2.fromScale(
                        math.clamp(startCenter.X + dx, sz.X * 0.25, scr.X - sz.X * 0.25) / scr.X,
                        math.clamp(startCenter.Y + dy, math.min(sz.Y / 2, scr.Y / 2), scr.Y - 60) / scr.Y)
                end
            end, function() if hooks and hooks.ended then hooks.ended(moved) end end)
        end)
    end

    local winHome = homeCenter()
    makeDraggable(win, headDrag, {
        moved = function() tw(win, 0.2, { BackgroundTransparency = math.min(1, winBaseT + 0.14) }) end,
        ended = function(moved) if moved then winHome = win.Position; tw(win, 0.3, { BackgroundTransparency = winBaseT }) end end,
    })

    grip.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        local startPos, startScale = input.Position, userScale
        UI.scrollLock(true)
        beginDrag(function(i)
            local d = ((i.Position.X - startPos.X) + (i.Position.Y - startPos.Y)) / 2
            userScale = math.floor(math.clamp(startScale + d / (WIN_W * curScale()), 0.6, 1.5) * 20 + 0.5) / 20
            applyScales()
        end, function() UI.scrollLock(false) end)
    end)

    function UI.openWindow()
        if winOpen then return end
        winOpen = true; win.Visible = true
        win.Size = off(WIN_W, WIN_H); winScale.Scale = curScale() * 0.12; win.Position = orb.Position
        tw(winScale, 0.4, { Scale = curScale() }, Back, Out)
        tw(win, 0.4, { Position = winHome }, Quint, Out)
        UI.syncTopbar()
    end
    function UI.closeWindow()
        if not winOpen then return end
        winOpen = false; winHome = win.Position
        tw(winScale, 0.28, { Scale = curScale() * 0.12 }, Quint, In)
        tw(win, 0.28, { Position = orb.Position }, Quint, In)
        task.delay(0.3, function() if not winOpen then win.Visible = false end end)
        UI.syncTopbar()
    end

    -- Карточка ввода ключа (@FinisOkek)
    local spinners = {}
    local card = Frame(gui, {
        Name = "KeyCard", AnchorPoint = V2(0.5, 0.5), Position = homeCenter(), Size = off(CARD_W, CARD_H),
        BackgroundColor3 = C.white, BackgroundTransparency = 0.1, Visible = false, Active = true, ZIndex = 10,
    })
    cardFrame = card
    Corner(card, 34); Grad(card, rgb(70, 66, 122), rgb(24, 22, 50), 120)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.4, 0.62), NumberSequenceKeypoint.new(1, 0.8) }) }, Stroke(card, C.white, 0.35, 1.5))
    local cardScale = New("UIScale", { Scale = 1 }, card)
    local cardDrag = Button(card, { ZIndex = 1 })
    local cardBody = Group(card, { Size = sc(1, 1), ZIndex = 2 })

    local kLogo = makeLogoF(cardBody, 78, true, true); kLogo.Position = off((CARD_W - 117) / 2, 36)
    local kTitle = Label(cardBody, { Position = off(0, 148), Size = off(CARD_W, 38), Text = "Finis Visual", TextSize = 32, Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Center })
    Grad(kTitle, rgb(255, 250, 255), rgb(214, 192, 255), 0)
    Label(cardBody, { Position = off(0, 194), Size = off(CARD_W, 22), Text = "Введи ключ, чтобы продолжить", TextSize = 15, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Center })
    local inRoot, keyBox, inStroke, inIcon = Input(card, 35, 232, 425, 58, "key", "Ваш ключ", 18)
    inRoot.ZIndex = 3
    local function setInputAlpha(a)
        inRoot.BackgroundTransparency = 1 - 0.55 * a; inStroke.Transparency = 1 - 0.1 * a
        keyBox.TextTransparency = 1 - a; keyBox.PlaceholderText = (a > 0.6) and "Ваш ключ" or ""
        setIconAlpha(inIcon, a)
    end
    Label(cardBody, { Position = off(0, 396), Size = off(CARD_W, 16), Text = "FINIS VISUAL  ·  v2.0", TextSize = 9.5, TextColor3 = C.txt4, TextXAlignment = Enum.TextXAlignment.Center })

    local pasteWrap = Group(cardBody, { Position = off(35, 306), Size = off(141, 52) })
    MakeButton(pasteWrap, 0, 0, 141, 52, "Вставить", "clipboard", "ghost", function()
        local txt
        if type(getclipboard) == "function" then local ok, r = pcall(getclipboard); if ok and type(r) == "string" then txt = trim(r) end end
        if txt and txt ~= "" then keyBox.Text = txt; UI.toast("Вставлено", "clipboard"); burst(inRoot, 396, 29, 9, 26)
        else UI.toast("Буфер обмена пуст", "clipboard") end
    end)

    local login = Frame(cardBody, { Position = off(188, 306), Size = off(272, 52), BackgroundColor3 = C.white })
    Corner(login, 16); accentGradient(login, 0)
    local lc = Group(login, { Size = sc(1, 1) })
    do
        local lw = measure("Войти", 16, FONT_B)
        local lx = (272 - (lw + 26)) / 2
        Label(lc, { Position = off(lx, 0), Size = off(lw + 6, 52), Text = "Войти", TextSize = 16, Font = FONT_B, TextColor3 = C.dark })
        Icon(lc, "arrow", 16, C.dark, { Position = off(lx + lw + 12, 18) })
    end
    local spin = Frame(login, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(24, 24), BackgroundTransparency = 1, Visible = false })
    Corner(spin, "full")
    spinners[#spinners + 1] = New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(0.68, 1), NumberSequenceKeypoint.new(1, 1) }) }, Stroke(spin, C.dark, 0, 2.6))
    local chk = Icon(login, "check", 26, C.dark, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Visible = false })
    local chkScale = New("UIScale", {}, chk)
    local loginBtn = Button(login, { ZIndex = 4 }); addPress(loginBtn, login, 0.97)

    local cardHome, cardMoved, busy = homeCenter(), false, false
    local function orbCenterPos()
        local scr, a, sz = viewport(), orb.AbsolutePosition, orb.AbsoluteSize
        return UDim2.fromScale((a.X + sz.X / 2) / scr.X, (a.Y + sz.Y / 2) / scr.Y)
    end
    local function openCard()
        if cardOpen then return end
        cardOpen = true; UI.syncTopbar(); card.Visible = true
        cardScale.Scale = curScale() * 0.18; card.Position = orbCenterPos(); card.BackgroundTransparency = 0.7
        if not cardMoved then cardHome = homeCenter() end
        cardBody.GroupTransparency = 0.97; setInputAlpha(0)
        tw(cardScale, 0.58, { Scale = curScale() }, Back, Out)
        tw(card, 0.52, { Position = cardHome, BackgroundTransparency = 0.1 }, Quint, Out)
        task.delay(0.15, function() tw(cardBody, 0.38, { GroupTransparency = 0 }, Quad, Out); animateValue(0.38, 0, 1, setInputAlpha) end)
    end
    local function closeCard()
        if not cardOpen then return end
        cardOpen = false; UI.syncTopbar(); cardHome = card.Position
        tw(cardBody, 0.15, { GroupTransparency = 1 }, Quad, Out); animateValue(0.15, 1, 0, setInputAlpha)
        tw(cardScale, 0.38, { Scale = curScale() * 0.18 }, Quint, In)
        tw(card, 0.38, { Position = orbCenterPos(), BackgroundTransparency = 0.7 }, Quint, In)
        task.delay(0.4, function() if not cardOpen then card.Visible = false end end)
    end
    makeDraggable(card, cardDrag, { ended = function(m) if m then cardHome = card.Position; cardMoved = true end end })

    local function shake()
        local p = card.Position
        for i, o in ipairs({ 0.008, -0.008, 0.005, -0.005, 0 }) do
            task.delay((i - 1) * 0.06, function() tw(card, 0.06, { Position = UDim2.new(p.X.Scale + o, 0, p.Y.Scale, 0) }, Quad, InOut) end)
        end
    end

    local function goMain()
        authed = true
        local scr, k = viewport(), curScale()
        local c = card.AbsolutePosition + card.AbsoluteSize / 2
        local hw, hh = WIN_W * k / 2, WIN_H * k / 2
        local px = math.clamp(c.X, hw, math.max(hw, scr.X - hw))
        local lo = math.max(hh, topInsetPx() + hh + 6)
        local py = math.clamp(c.Y, lo, math.max(lo, scr.Y - hh))
        winHome = UDim2.fromScale(px / scr.X, py / scr.Y)
        winOpen = true; UI.syncTopbar(); win.Visible = true
        winScale.Scale = k; win.Size = off(CARD_W, CARD_H); win.Position = card.Position
        tw(win, 0.56, { Size = off(WIN_W, WIN_H), Position = winHome }, Quint, Out)
        tw(cardBody, 0.24, { GroupTransparency = 1 }, Quad, Out); animateValue(0.24, 1, 0, setInputAlpha)
        task.delay(0.28, function() card.Visible = false; cardOpen = false; busy = false end)
    end

    local function doLogin()
        if busy then return end
        local txt = trim(keyBox.Text)
        if txt == "" then UI.toast("Введи ключ", "key"); shake(); return end
        busy = true; keyBox:ReleaseFocus()
        tw(pasteWrap, 0.25, { GroupTransparency = 1 }, Quad, Out)
        tw(lc, 0.2, { GroupTransparency = 1 }, Quad, Out)
        tw(login, 0.45, { Size = off(56, 52), Position = off(35 + (425 - 56) / 2, 306) }, Quint, Out)
        task.delay(0.28, function() if busy then spin.Visible = true end end)
        task.delay(1.0, function()
            if string.lower(txt) == KEY then
                spin.Visible = false; chk.Visible = true; chkScale.Scale = 0.2
                tw(chkScale, 0.4, { Scale = 1 }, Back, Out)
                task.delay(0.75, goMain)
            else
                spin.Visible = false; chk.Visible = false
                tw(login, 0.4, { Size = off(272, 52), Position = off(188, 306) }, Quint, Out)
                tw(pasteWrap, 0.3, { GroupTransparency = 0 }, Quad, Out); tw(lc, 0.3, { GroupTransparency = 0 }, Quad, Out)
                tw(inStroke, 0.15, { Color = C.red, Transparency = 0.1 })
                task.delay(0.9, function() tw(inStroke, 0.3, { Color = C.white, Transparency = 0.9 }) end)
                shake(); UI.toast("Неверный ключ", "x"); busy = false
            end
        end)
    end

    loginBtn.Activated:Connect(doLogin)
    keyBox.FocusLost:Connect(function(enter) if enter then doLogin() end end)

    function UI.orbTap()
        if not authed then if not busy then if cardOpen then closeCard() else openCard() end end
        else if winOpen then UI.closeWindow() else UI.openWindow() end end
    end

    bind(UserInputService.InputBegan, function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightShift and orb.Visible then UI.orbTap() end
    end)

    -- Главный цикл (орбита, искры, частицы, инерция скролла, обновление ESP)
    local espAcc = 0
    bind(RunService.Heartbeat, function(dt)
        local now = os.clock()
        arcGrad.Rotation = (now * 240) % 360
        for _, g in ipairs(spinners) do g.Rotation = (now * 420) % 360 end
        for _, sp in ipairs(sparks) do
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
            local y = scroller.CanvasPosition.Y + Scroll.coast * dt
            if setScrollY(y) ~= y then Scroll.coast = 0 end
            Scroll.coast = Scroll.coast * math.max(0, 1 - 5 * dt)
            if math.abs(Scroll.coast) < 12 then Scroll.coast = 0 end
        end
        if Scroll.blocked and not Drag.finish then Scroll.blocked = false end

        espAcc = espAcc + dt
        if espAcc >= 0.08 then
            espAcc = 0
            UpdateAllESP()
        end
    end)

    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyScales)
    RunIntro3DF(orb, orbScale, getOrbTargetPos)
end

BuildShell()
