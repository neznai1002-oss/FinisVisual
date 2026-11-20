--[[
    Eta  -  визуальная копия меню (только интерфейс).
    Никаких реальных функций: переключатели и ползунки лишь двигаются.
    Ключ для входа: @FinisOkek   (регистр не важен)
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local ENV = (type(getgenv) == "function" and getgenv()) or _G

-- повторный запуск: убираем старую копию
if ENV.__EtaMenu and type(ENV.__EtaMenu.Destroy) == "function" then
    pcall(ENV.__EtaMenu.Destroy)
end

local Eta = { conns = {} }
ENV.__EtaMenu = Eta

local function bind(signal, fn)
    local c = signal:Connect(fn)
    Eta.conns[#Eta.conns + 1] = c
    return c
end

----------------------------------------------------------------------
-- ScreenGui
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "EtaMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)

do
    local parent
    if type(gethui) == "function" then
        local ok, r = pcall(gethui)
        if ok and r then parent = r end
    end
    if not parent then
        local ok, r = pcall(function() return game:GetService("CoreGui") end)
        if ok and r then parent = r end
    end
    if parent then pcall(function() gui.Parent = parent end) end
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

function Eta.Destroy()
    for _, c in ipairs(Eta.conns) do pcall(function() c:Disconnect() end) end
    Eta.conns = {}
    pcall(function() gui:Destroy() end)
    if ENV.__EtaMenu == Eta then ENV.__EtaMenu = nil end
end

----------------------------------------------------------------------
-- размеры (дизайн-единицы; потом масштабируются под экран)
----------------------------------------------------------------------
local WIN_W, WIN_H = 1020, 620
local SIDE_W, HEAD_H = 173, 80
local PAGE_W, PAGE_H = WIN_W - SIDE_W, WIN_H - HEAD_H
local CARD_W, CARD_H = 495, 442

local KEY = "@finisokek"

----------------------------------------------------------------------
-- короткие помощники
----------------------------------------------------------------------
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
    white  = rgb(255, 255, 255),
    txt    = rgb(246, 248, 255),
    txt2   = rgb(184, 186, 216),
    txt3   = rgb(141, 141, 177),
    txt4   = rgb(112, 113, 148),
    dark   = rgb(22, 20, 46),
    knob   = rgb(238, 240, 250),
    track  = rgb(39, 41, 62),
    off    = rgb(74, 76, 104),
    panel  = rgb(18, 17, 38),
    glass  = rgb(255, 255, 255),
    green  = rgb(96, 226, 160),
    red    = rgb(255, 106, 140),
}

local THEMES = {
    { name = "Жемчуг",  a = rgb(160, 172, 250), b = rgb(192, 156, 250) },
    { name = "Бирюза",  a = rgb(112, 228, 204), b = rgb(110, 186, 236) },
    { name = "Янтарь",  a = rgb(252, 208, 124), b = rgb(246, 168, 110) },
    { name = "Роза",    a = rgb(246, 150, 204), b = rgb(200, 140, 246) },
    { name = "Сапфир",  a = rgb(110, 172, 255), b = rgb(134, 130, 250) },
    { name = "Иней",    a = rgb(218, 224, 242), b = rgb(178, 190, 226) },
}
local theme = { a = THEMES[1].a, b = THEMES[1].b, index = 1 }

local Quint, Quad, Back, Sine, Cubic =
    Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back,
    Enum.EasingStyle.Sine, Enum.EasingStyle.Cubic
local Out, InOut, In = Enum.EasingDirection.Out, Enum.EasingDirection.InOut, Enum.EasingDirection.In

local Anim = { speed = 1, mode = 2 }   -- speed: множитель длительности

local function tw(o, dur, props, style, dir)
    local t = TweenService:Create(o, TweenInfo.new(math.max(0.01, dur * Anim.speed), style or Quint, dir or Out), props)
    t:Play()
    return t
end

-- Шрифты. Если вместо русских букв видны квадраты — замени на
-- Enum.Font.SourceSans / Enum.Font.SourceSansSemibold / Enum.Font.SourceSansBold
local FONT_R, FONT_M, FONT_B = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold

-- ===== языки =====
local LANG = { code = "ru", pick = 1 }
local TR = {}
local TREG = setmetatable({}, { __mode = "k" })
local function T(s)
    local e = TR[s]
    if e == nil or LANG.code == "ru" then return s end
    return e[LANG.code] or e.en or s
end
local LANG_BY_PICK = { false, "en", "ru", "tr", "ar", "fa", "zh", "ja" }
local function systemLang()
    local id = "en"
    pcall(function() id = string.lower(game:GetService("LocalizationService").RobloxLocaleId) end)
    local map = { ru = "ru", en = "en", tr = "tr", ar = "ar", fa = "fa", zh = "zh", ja = "ja" }
    return map[string.sub(id, 1, 2)] or "en"
end
local function setLangByPick(pick)
    LANG.pick = pick
    LANG.code = LANG_BY_PICK[pick] or systemLang()
end
setLangByPick(1)

-- то, что должно пережить пересборку страниц (выбор сегментов и чипов)
local Persist = { seg = {}, chip = {} }

local function animateValue(dur, a, b, fn)
    dur = math.max(0.02, dur * Anim.speed)
    local t0 = os.clock()
    local done = false
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if done then return end
        local k = math.min(1, (os.clock() - t0) / dur)
        local e = 1 - (1 - k) * (1 - k) * (1 - k)
        fn(a + (b - a) * e)
        if k >= 1 then
            done = true
            conn:Disconnect()
        end
    end)
    task.delay(dur + 0.05, function()
        if not done then
            done = true
            conn:Disconnect()
            fn(b)
        end
    end)
end

local function New(class, props, parent)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do o[k] = v end
    end
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
    local key = t.Text
    local tr = (key ~= "" and TR[key] ~= nil)
    if tr then t.Text = T(key) end
    local l = New("TextLabel", t, parent)
    if tr then TREG[l] = key end
    return l
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

local function PadAll(o, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingTop, p.PaddingRight, p.PaddingBottom = UDim.new(0, l), UDim.new(0, t), UDim.new(0, r), UDim.new(0, b)
    p.Parent = o
    return p
end

-- градиенты акцентного цвета (меняются вместе с темой)
local accentGrads, accentFns = {}, {}
local function accentGradient(o, rot)
    local g = Grad(o, theme.a, theme.b, rot or 0)
    accentGrads[#accentGrads + 1] = g
    return g
end
local function onTheme(fn) accentFns[#accentFns + 1] = fn end
local function applyTheme(i)
    local t = THEMES[i]
    theme.a, theme.b, theme.index = t.a, t.b, i
    for _, g in ipairs(accentGrads) do
        if g.Parent then g.Color = ColorSequence.new(theme.a, theme.b) end
    end
    for _, f in ipairs(accentFns) do pcall(f) end
end

-- видимый размер экрана
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
    local ok, r = pcall(function()
        return TextService:GetTextSize(text, size, font or FONT_M, V2(3000, 200))
    end)
    if ok and r then return r.X end
    return #text * size * 0.58
end

-- глобальное перетаскивание (одна пара подписок на всё)
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
-- общее состояние (то, что синхронизируется между страницами)
----------------------------------------------------------------------
local State = {
    -- быстрые переключатели
    esp = true, aim = true, silent = true, fastreload = true, autofarm = false,
    freecam = false, thirdperson = false, ownmodel = false, fpsunlock = false, island = true,
    -- функции
    nospread = true, norecoil = true, fastfire = false, firerate = 2.0,
    farmres = 1, farmother = 0, gotoit = true, farmrate = 0.2,
    autopickup = false, pickwhat = 1,
    targetfps = 144, lowgfx = false, res = 70, lod = 50, simple = false, grass = 30,
    noshadow = true, nofx = true,
    customfov = false, fov = 90, freecamspeed = 10, tpdist = 3, tpangle = 0,
    timeofday = true, hour = 12, clearview = false,
    -- визуал
    radar = true, radaranimals = true, islandalert = true, alertdist = 50, overlay = true,
    offline = true, box = true, skeleton = true, openparts = true, snaplines = true,
    health = true, nick = true, dist = true, weapon = true, armor = true, arrows = true,
    espdist = 500, vopacity = 95, vthick = 1.0, vglow = 0.3, darkoutline = true, teamcolor = true,
    hue = 348, sat = 58, bri = 100, worlddist = 400, hidelooted = true,
    -- аим
    aimfov = 60, smooth = 1.0, hitchance = 100, lock = false, lead = true,
    ignallies = true, ignbots = false, ignoffline = true, igncover = true, maxdist = 400,
    fovcircle = true, bonepoints = true, aimline = true, targetpanel = true,
    autoshoot = true, reaction = 0, autorate = 20, recoilctl = 100,
    -- модели
    blink = true, physics = true,
    -- настройки
    ballvisible = true, panelopacity = 88, uiscale = 1.0,
    particles = true, density = 60, trail = true, pressfx = true,
    lang = 1, swatch = 0,
}

local Binders = {}
local function bindState(key, fn, shell)
    Binders[key] = Binders[key] or {}
    table.insert(Binders[key], { fn = fn, shell = shell })
    fn(State[key], true)
end
local function setState(key, v)
    State[key] = v
    local list = Binders[key]
    if list then
        for _, b in ipairs(list) do b.fn(v, false) end
    end
end

local QUICK_KEYS = { "esp", "aim", "silent", "fastreload", "autofarm", "freecam", "thirdperson", "ownmodel", "fpsunlock", "island" }
local function countOn()
    local n = 0
    for _, k in ipairs(QUICK_KEYS) do if State[k] then n = n + 1 end end
    return n
end
-- Таблица переводов (ключ — русский текст). Порядок: en, tr, ar, fa, zh, ja.
-- Чего нет в языке — берётся английский вариант.
do
    local function L(ru, en, tr, ar, fa, zh, ja)
        TR[ru] = { en = en, tr = tr, ar = ar, fa = fa, zh = zh, ja = ja }
    end
    L("Жемчуг", "Pearl", "İnci", "لؤلؤ", "مروارید", "珍珠", "パール")
    L("Бирюза", "Turquoise", "Turkuaz", "فيروزي", "فیروزه‌ای", "青綠", "ターコイズ")
    L("Янтарь", "Amber", "Kehribar", "عنبر", "کهربا", "琥珀", "アンバー")
    L("Роза", "Rose", "Gül", "وردي", "رز", "玫瑰", "ローズ")
    L("Сапфир", "Sapphire", "Safir", "ياقوت أزرق", "یاقوت کبود", "藍寶石", "サファイア")
    L("Иней", "Frost", "Kırağı", "صقيع", "یخبندان", "霜白", "フロスト")
    L("Nyx 49 м", "Nyx 49 m")
    L("Raven 14 м", "Raven 14 m")
    L("Vex 32 м", "Vex 32 m")
    L("Ghost 78 м", "Ghost 78 m")
    L("Bot-07 20 м", "Bot-07 20 m")
    L("Rook 10 м", "Rook 10 m")
    L("Голова", "Head", "Kafa", "الرأس", "سر", "頭部", "頭")
    L("Силент", "Silent", "Sessiz", "صامت", "بی‌صدا", "靜默", "サイレント")
    L("Nyx  ·  49 м  ·  Голова", "Nyx  ·  49 m  ·  Head")
    L("Стрельба", "Shooting", "Ateş", "إطلاق النار", "شلیک", "射擊", "射撃")
    L("Выкл", "Off", "Kapalı", "إيقاف", "خاموش", "關", "オフ")
    L("Вкл", "On", "Açık", "تشغيل", "روشن", "開", "オン")
    L("Обзор", "Overview", "Genel", "نظرة عامة", "نمای کلی", "總覽", "概要")
    L("Игра вкратце и несколько переключателей под рукой", "The game at a glance and a few toggles at hand", "Oyuna kısa bakış ve elinizin altında birkaç anahtar", "نظرة سريعة على اللعبة ومفاتيح قليلة في متناول يدك", "نگاهی کوتاه به بازی و چند کلید در دسترس", "遊戲概覽與幾個常用開關", "ゲームの概要と手元のスイッチ")
    L("Eta готова", "Eta is ready", "Eta hazır", "Eta جاهزة", "Eta آماده است", "Eta 已就緒", "Eta 準備完了")
    L("ВХ, аимбот, АвтоФарм и твики для Oxide: Survival Island. Быстрые переключатели ниже и на быстром шаре поверх игры.", "ESP, aimbot, AutoFarm and tweaks for Oxide: Survival Island. Quick toggles below and on the quick ball over the game.")
    L("В игре", "In game", "Oyunda", "في اللعبة", "در بازی", "遊戲中", "ゲーム中")
    L("Нет конфига", "No config", "Yapılandırma yok", "لا يوجد إعداد", "بدون پیکربندی", "無設定", "設定なし")
    L("Ключ ···%s", "Key ···%s", "Anahtar ···%s", "المفتاح ···%s", "کلید ···%s", "金鑰 ···%s", "キー ···%s")
    L("Лицензия активна", "License active", "Lisans etkin", "الترخيص نشط", "مجوز فعال است", "授權有效", "ライセンス有効")
    L("Аптайм %s", "Uptime %s", "Çalışma süresi %s", "مدة التشغيل %s", "مدت فعالیت %s", "運行時間 %s", "稼働時間 %s")
    L("Статус", "Status", "Durum", "الحالة", "وضعیت", "狀態", "ステータス")
    L("В поле зрения", "In view", "Görüşte", "في مجال الرؤية", "در دید", "視野內", "視界内")
    L("Частота кадров", "Frame rate", "Kare hızı", "معدل الإطارات", "نرخ فریم", "幀率", "フレームレート")
    L("Включено", "Enabled", "Etkin", "مفعّل", "فعال", "已啟用", "有効")
    L("Быстрые переключатели", "Quick toggles", "Hızlı anahtarlar", "مفاتيح سريعة", "کلیدهای سریع", "快速開關", "クイックスイッチ")
    L("ВХ", "ESP", "ESP", "ESP", "ESP", "ESP", "ESP")
    L("Аимбот", "Aimbot", "Aimbot", "Aimbot", "Aimbot", "自瞄", "エイムボット")
    L("Силент-аим", "Silent aim", "Sessiz nişan", "تصويب صامت", "هدف‌گیری بی‌صدا", "靜默瞄準", "サイレントエイム")
    L("Быстрая перезарядка", "Fast reload", "Hızlı şarjör", "إعادة تحميل سريعة", "بارگذاری سریع", "快速換彈", "高速リロード")
    L("АвтоФарм", "AutoFarm", "OtoFarm", "فارم تلقائي", "فارم خودکار", "自動採集", "オートファーム")
    L("Свободная камера", "Free camera", "Serbest kamera", "كاميرا حرة", "دوربین آزاد", "自由視角", "フリーカメラ")
    L("Вид от 3-го лица", "Third person", "Üçüncü şahıs", "منظور الشخص الثالث", "دید سوم‌شخص", "第三人稱", "三人称視点")
    L("Своя модель", "Custom model", "Özel model", "نموذج مخصص", "مدل سفارشی", "自訂模型", "カスタムモデル")
    L("Снять лимит FPS", "Unlock FPS", "FPS sınırını kaldır", "إزالة حد FPS", "حذف محدودیت FPS", "解除 FPS 限制", "FPS制限解除")
    L("Островок статуса", "Status island", "Durum adası", "جزيرة الحالة", "جزیره وضعیت", "狀態島", "ステータスアイランド")
    L("Настроить", "Customize", "Özelleştir", "تخصيص", "سفارشی‌سازی", "自訂", "カスタマイズ")
    L("Режим настройки плиток", "Tile customization mode")
    L("Быстрый шар", "Quick ball", "Hızlı küre", "الكرة السريعة", "توپ سریع", "快捷球", "クイックボール")
    L("Стеклянный шар поверх игры с этими переключателями; перетащи его к любому краю", "A glass ball over the game with these toggles; drag it to any edge")
    L("Функции", "Functions", "İşlevler", "الوظائف", "قابلیت‌ها", "功能", "機能")
    L("Бой, камера и фарм", "Combat, camera and farming", "Dövüş, kamera ve farm", "القتال والكاميرا والفارم", "نبرد، دوربین و فارم", "戰鬥、視角與採集", "戦闘・カメラ・ファーム")
    L("Бой", "Combat", "Dövüş", "القتال", "نبرد", "戰鬥", "戦闘")
    L("Без разброса", "No spread")
    L("Каждый выстрел идёт туда, куда указывает перекрестие", "Every shot goes exactly where the crosshair points")
    L("Без отдачи", "No recoil")
    L("Камера не дёргается при стрельбе", "The camera does not shake when shooting")
    L("Перезарядка заканчивается почти мгновенно", "Reloading finishes almost instantly")
    L("Быстрая стрельба", "Rapid fire")
    L("Стрельба быстрее, чем позволяет оружие", "Shoots faster than the weapon allows")
    L("Скорострельность", "Fire rate")
    L("Находит выбранный ресурс, поворачивается к нему и добывает; держи нужный инструмент", "Finds the chosen resource, turns to it and harvests it; hold the right tool")
    L("Ресурс", "Resource")
    L("Дерево", "Wood")
    L("Металл", "Metal")
    L("Сера", "Sulfur")
    L("Камень", "Stone")
    L("Другое", "Other")
    L("Подбираемое", "Pickups")
    L("Поленница", "Woodpile")
    L("Идти к нему", "Walk to it")
    L("Идёт к ближайшему; выкл.: добывать только то, что в зоне досягаемости", "Walks to the nearest one; off: harvest only what is within reach")
    L("Добывать каждые", "Harvest every")
    L(" с", " s", " sn", " ث", " ث", " 秒", " 秒")
    L("Автоподбор", "Auto pickup", "Otomatik toplama", "التقاط تلقائي", "برداشت خودکار", "自動拾取", "オート拾得")
    L("Подбирает всё, что лежит в зоне подбора игры, пока ты идёшь мимо", "Picks up everything in the game's pickup range as you walk by")
    L("Что", "What")
    L("Всё", "All")
    L("Ресурсы", "Resources")
    L("Выброшенное", "Dropped items")
    L("Снять лимит кадров", "Remove frame limit")
    L("Убирает ограничение частоты кадров игры", "Removes the game's frame rate cap")
    L("Целевой FPS", "Target FPS")
    L("Облегчённая графика", "Light graphics")
    L("Рисует игру с меньшей нагрузкой; после выключения всё возвращается", "Renders the game with less load; everything returns when turned off")
    L("Разрешение", "Resolution")
    L("От разрешения экрана; не выше игрового", "Of the screen resolution; not above the game's")
    L("Детализация моделей", "Model detail")
    L("Ниже: здания, камни и деревья упрощаются ближе к вам", "Lower: buildings, rocks and trees get simplified closer to you")
    L("Простейшие модели", "Simplest models")
    L("Всё на самом низком уровне детализации, даже вблизи", "Everything at the lowest detail level, even up close")
    L("Трава", "Grass")
    L("Дальность прорисовки травы; 0 — без травы", "Grass draw distance; 0 means no grass")
    L("Без теней", "No shadows")
    L("Тени не отрисовываются", "Shadows are not rendered")
    L("Без экранных эффектов", "No screen effects")
    L("Постобработка, сглаживание и HDR выключены", "Post-processing, anti-aliasing and HDR are off")
    L("Камера", "Camera", "Kamera", "الكاميرا", "دوربین", "視角", "カメラ")
    L("Свой FOV", "Custom FOV")
    L("Угол обзора", "Field of view")
    L("Отсоединяет камеру и позволяет летать", "Detaches the camera and lets you fly")
    L("Скорость", "Speed")
    L(" м/с", " m/s", " m/sn", " م/ث", " م/ث", " 米/秒", " m/s")
    L("Вид на себя сзади; выстрелы по-прежнему вылетают из головы", "View of yourself from behind; shots still come out of the head")
    L("Дистанция", "Distance", "Mesafe", "المسافة", "فاصله", "距離", "距離")
    L(" м", " m", " m", " م", " م", " 米", " m")
    L("Угол", "Angle")
    L("Лицом ко мне", "Face me")
    L("Камера повёрнута к тебе лицом", "The camera now faces you")
    L("Рисует VRM-модель вместо тела: см. страницу Модели", "Draws a VRM model instead of the body: see the Models page")
    L("Время суток", "Time of day")
    L("Задаёт игровое время (день или ночь)", "Sets the in-game time (day or night)")
    L("Час", "Hour")
    L(" ч", " h", " sa", " س", " ساعت", " 時", " 時")
    L("Чистый обзор", "Clear view")
    L("Без тумана — ни в воздухе, ни под водой — и без инея и радиации на экране", "No fog, in the air or underwater, and no frost or radiation on screen")
    L("Полезно знать", "Good to know", "Bilmekte fayda var", "من المفيد معرفته", "خوب است بدانید", "小提示", "ヒント")
    L("АвтоФарм добывает тем, что у тебя в руках: топором деревья, киркой руду.", "AutoFarm harvests with what you hold: trees with an axe, ore with a pickaxe.")
    L("После выключения время суток и частота кадров возвращаются к игровым.", "When turned off, the time of day and frame rate return to the game's own.")
    L("База", "Base")
    L("Шкаф", "Cabinet")
    L("Дверь", "Door")
    L("Турель", "Turret")
    L("Хранилище", "Storage")
    L("Большое хранилище", "Large storage")
    L("Спальный мешок", "Sleeping bag")
    L("Печь", "Furnace")
    L("Верстак", "Workbench")
    L("Ружейная ловушка", "Shotgun trap")
    L("Переработчик", "Recycler")
    L("Животные", "Animals", "Hayvanlar", "الحيوانات", "حیوانات", "動物", "動物")
    L("Медведь", "Bear")
    L("Олень", "Deer")
    L("Кабан", "Boar")
    L("Кролик", "Rabbit")
    L("Курица", "Chicken")
    L("Крыса", "Rat")
    L("Тыква", "Pumpkin")
    L("Лёд", "Ice")
    L("Лут", "Loot", "Ganimet", "الغنائم", "غنیمت", "戰利品", "ルート")
    L("Рюкзак", "Backpack")
    L("Бочка", "Barrel")
    L("Ящик", "Crate")
    L("Ящик на авто", "Car crate")
    L("Аирдроп", "Airdrop")
    L("Ящик на шаре", "Balloon crate")
    L("Выброшенный предмет", "Dropped item")
    L("Транспорт", "Vehicles", "Araçlar", "المركبات", "وسایل نقلیه", "載具", "乗り物")
    L("Визуал", "Visuals", "Görsel", "المرئيات", "بصری", "視覺", "ビジュアル")
    L("ВХ для игроков, ботов и ресурсов мира", "ESP for players, bots and world resources", "Oyuncular, botlar ve dünya kaynakları için ESP", "ESP للاعبين والبوتات وموارد العالم", "ESP برای بازیکنان، ربات‌ها و منابع جهان", "針對玩家、機器人與世界資源的 ESP", "プレイヤー・ボット・資源のESP")
    L("Предпросмотр", "Preview", "Önizleme", "معاينة", "پیش‌نمایش", "預覽", "プレビュー")
    L("Демо-данные", "Demo data", "Demo veriler", "بيانات تجريبية", "داده‌های نمایشی", "示範資料", "デモデータ")
    L("Стили видимости", "Visibility styles", "Görünürlük stilleri", "أنماط الظهور", "سبک‌های دید", "可見樣式", "表示スタイル")
    L("Игроки на виду и за укрытием", "Players in the open and behind cover")
    L("Стиль для", "Style for")
    L("На виду", "In the open")
    L("За укрытием", "Behind cover")
    L("Цвет команды", "Team color")
    L("Выкл.: цвет ниже для всех команд", "Off: the color below applies to all teams")
    L("Непрозрачность", "Opacity")
    L("Толщина линий", "Line thickness")
    L("Свечение", "Glow")
    L("Линия", "Line")
    L("Сплошная", "Solid")
    L("Пунктирная", "Dashed")
    L("Точечная", "Dotted")
    L("Тёмная обводка", "Dark outline")
    L("Тёмная линия под каждым штрихом, чтобы её было видно на светлом фоне", "A dark line under every stroke so it stays visible on a light background")
    L("Сбросить стиль", "Reset style", "Stili sıfırla", "إعادة ضبط النمط", "بازنشانی سبک", "重設樣式", "スタイルをリセット")
    L("Стиль сброшен", "Style reset")
    L("Цвета команд", "Team colors", "Takım renkleri", "ألوان الفرق", "رنگ تیم‌ها", "隊伍顏色", "チームカラー")
    L("Команда", "Team")
    L("Союзники", "Allies", "Müttefikler", "الحلفاء", "هم‌تیمی‌ها", "盟友", "味方")
    L("Боты", "Bots", "Botlar", "البوتات", "ربات‌ها", "機器人", "ボット")
    L("Враги", "Enemies", "Düşmanlar", "الأعداء", "دشمنان", "敵人", "敵")
    L("Цвет", "Color")
    L("Оттенок", "Hue")
    L("Насыщенность", "Saturation")
    L("Яркость", "Brightness")
    L("Сбросить цвет", "Reset color", "Rengi sıfırla", "إعادة ضبط اللون", "بازنشانی رنگ", "重設顏色", "色をリセット")
    L("Цвет сброшен", "Color reset")
    L("Мир", "World", "Dünya", "العالم", "جهان", "世界", "ワールド")
    L("Категории", "Categories")
    L("Подписи", "Labels")
    L("Иконка", "Icon")
    L("Имя", "Name")
    L("Полный", "Full")
    L("Дальность", "Range")
    L("Скрывать обчищенные", "Hide looted")
    L("Не показывать вскрытые аирдропы и опустошённые ящики", "Don't show opened airdrops and emptied crates")
    L("Главный выключатель для игроков и мира", "Master switch for players and the world")
    L("Радар", "Radar")
    L("По направлению взгляда, в углу экрана", "Follows your view direction, in a screen corner")
    L("Животные и лут на радаре", "Animals and loot on radar")
    L("Ещё животные, лут и транспорт, не только люди", "Also animals, loot and vehicles, not just people")
    L("Кто рядом, вверху экрана; сообщает о новых врагах", "Who is nearby, at the top of the screen; warns about new enemies")
    L("Тревога островка", "Island alert")
    L("Краснеет и указывает на врага в пределах этой дистанции", "Turns red and points at an enemy within this distance")
    L("Дистанция тревоги", "Alert distance")
    L("Рисовать поверх игры", "Draw over the game")
    L("Живой ВХ поверх игры", "Live ESP drawn over the game")
    L("Игроки", "Players", "Oyuncular", "اللاعبون", "بازیکنان", "玩家", "プレイヤー")
    L("Показывать", "Show")
    L("Игроки не в сети", "Offline players")
    L("Тела вышедших из игры игроков, отмечены луной", "Bodies of players who left the game, marked with a moon")
    L("Бокс", "Box")
    L("Стиль бокса", "Box style")
    L("Углы", "Corners")
    L("Контур", "Outline")
    L("Стекло", "Glass")
    L("Скелет", "Skeleton")
    L("Открытые части", "Exposed parts")
    L("Подсвечивает части тела вне укрытия", "Highlights body parts outside cover")
    L("Снаплайны", "Snaplines")
    L("Начало снаплайнов", "Snapline origin")
    L("Сверху", "Top")
    L("Центр", "Center")
    L("Снизу", "Bottom")
    L("Полоска здоровья", "Health bar")
    L("Ники", "Nicknames")
    L("Оружие в руках", "Held weapon")
    L("Иконка и название оружия в руках у каждого игрока", "Icon and name of every player's held weapon")
    L("Броня", "Armor")
    L("Голова, грудь, ноги и стопы, цвет по материалу", "Head, chest, legs and feet, colored by material")
    L("Стрелки за экраном", "Off-screen arrows")
    L("Указывают на игроков вне поля зрения", "Point to players outside your view")
    L("Аим", "Aim", "Nişan", "التصويب", "هدف‌گیری", "瞄準", "エイム")
    L("Аимбот: цели, точки прицеливания и стрельба", "Aimbot: targets, aim points and shooting", "Aimbot: hedefler, nişan noktaları ve atış", "Aimbot: الأهداف ونقاط التصويب وإطلاق النار", "Aimbot: اهداف، نقاط هدف‌گیری و شلیک", "自瞄：目標、瞄準點與射擊", "エイムボット：ターゲット・照準点・射撃")
    L("Кости", "Bones", "Kemikler", "العظام", "استخوان‌ها", "骨骼", "ボーン")
    L("Шея", "Neck")
    L("Грудь", "Chest")
    L("Таз", "Pelvis")
    L("Руки", "Arms")
    L("Кисти", "Hands")
    L("Ноги", "Legs")
    L("Стопы", "Feet")
    L("Целиться в", "Aim at")
    L("Выбор", "Selection")
    L("Ближайшая", "Closest")
    L("Приоритет", "Priority")
    L("Ближайшая берёт отмеченную точку, ближайшую к перекрестию. Приоритет берёт первую отмеченную группу, начиная с головы, у которой есть точка внутри круга.", "Closest takes the marked point nearest to the crosshair. Priority takes the first marked group, starting from the head, that has a point inside the circle.")
    L("Отображение", "Display", "Görüntü", "العرض", "نمایش", "顯示", "表示")
    L("Круг FOV", "FOV circle")
    L("Точки костей", "Bone points")
    L("Каждая отмеченная точка на каждой допустимой цели", "Every marked point on every valid target")
    L("Линия прицела", "Aim line")
    L("Панель цели", "Target panel")
    L("Кто, как далеко, какая кость и что делает", "Who, how far, which bone and what they are doing")
    L("Выстрелы летят в цель; камера не двигается", "Shots fly to the target; the camera does not move")
    L("Активация", "Activation")
    L("Всегда", "Always")
    L("Целясь", "While aiming")
    L("Плавность", "Smoothing")
    L("Только ассист: насколько плавно поворачивается камера", "Assist only: how smoothly the camera turns")
    L("Шанс попадания", "Hit chance")
    L("Только силент: остальные выстрелы мажут намеренно", "Silent only: the remaining shots miss on purpose")
    L("Перекрестие", "Crosshair")
    L("Здоровье", "Health")
    L("Захват цели", "Target lock")
    L("Держится за цель, пока она не выйдет из круга", "Sticks to the target until it leaves the circle")
    L("Упреждение", "Lead")
    L("Упреждает движущиеся цели; падение снаряда учитывается всегда, для любого оружия", "Leads moving targets; projectile drop is always counted, for any weapon")
    L("Цели", "Targets", "Hedefler", "الأهداف", "اهداف", "目標", "ターゲット")
    L("Игнорировать союзников", "Ignore allies")
    L("Игнорировать ботов", "Ignore bots")
    L("Игнорировать игроков не в сети", "Ignore offline players")
    L("Пропускает тела вышедших из игры игроков", "Skips the bodies of players who left the game")
    L("Игнорировать за укрытием", "Ignore behind cover")
    L("Целится только в части тела в прямой видимости", "Aims only at body parts in direct line of sight")
    L("Макс. дистанция", "Max distance")
    L("Автострельба", "Auto shoot", "Otomatik atış", "إطلاق تلقائي", "شلیک خودکار", "自動射擊", "オート射撃")
    L("Стреляет, пока выстрел попадает в цель", "Shoots while the shot hits the target")
    L("Реакция", "Reaction")
    L("Ожидание после захвата цели перед первым выстрелом", "Wait after locking on before the first shot")
    L(" мс", " ms", " ms", " مللي ث", " میلی‌ثانیه", " 毫秒", " ms")
    L(" / с", " / s", " / sn", " / ث", " / ثانیه", " / 秒", " / 秒")
    L("Контроль отдачи", "Recoil control")
    L("Модели", "Models", "Modeller", "النماذج", "مدل‌ها", "模型", "モデル")
    L("VRM-модели для вида от третьего лица -- видишь только ты", "VRM models for third-person view -- only you can see them", "Üçüncü şahıs görünümü için VRM modelleri -- yalnızca sen görürsün", "نماذج VRM للمنظور الثالث -- أنت فقط ترى ذلك", "مدل‌های VRM برای دید سوم‌شخص -- فقط شما می‌بینید", "第三人稱 VRM 模型 -- 只有你看得到", "三人称視点用のVRMモデル -- あなただけに見えます")
    L("Надето", "Equipped", "Giyilen", "المُلبَس", "پوشیده", "已裝備", "装備中")
    L("Нет модели", "No model", "Model yok", "لا يوجد نموذج", "بدون مدل", "無模型", "モデルなし")
    L("Вид от 3-го лица рисует выбранную модель вместо тела", "Third-person view draws the chosen model instead of the body")
    L("Сначала выбери модель", "Choose a model first")
    L("Перезагрузить", "Reload", "Yeniden yükle", "إعادة التحميل", "بارگذاری مجدد", "重新載入", "再読み込み")
    L("Список моделей обновлён", "Model list refreshed")
    L("Предпросмотр поворачивает камеру к тебе лицом и вокруг тебя; коснись глазика, чтобы остановить.", "Preview turns the camera to face you and around you; tap the eye to stop.")
    L("Вид", "Look", "Görünüm", "المظهر", "ظاهر", "外觀", "見た目")
    L("Освещается так же, как всё остальное в игре", "Lit the same way as everything else in the game")
    L("Освещается сценой, матовый, с собственными цветами модели", "Lit by the scene, matte, with the model's own colors")
    L("Цвета модели как нарисованы, без освещения и теней", "Model colors as drawn, without lighting or shadows")
    L("Освещение", "Lighting")
    L("Игра", "Game")
    L("Свет", "Light")
    L("Плоский", "Flat")
    L("Выражение", "Expression")
    L("Спокойно", "Calm", "Sakin", "هادئ", "آرام", "平靜", "穏やか")
    L("Радость", "Joy")
    L("Злость", "Anger")
    L("Грусть", "Sadness")
    L("Веселье", "Fun")
    L("Вау", "Wow")
    L("Моргание", "Blinking")
    L("Время от времени, как у человека", "From time to time, like a human")
    L("Физика волос и ткани", "Hair and cloth physics")
    L("Волосы, юбка и ленты качаются так, как задано в модели", "Hair, skirt and ribbons sway as defined in the model")
    L("Импорт", "Import", "İçe aktar", "استيراد", "درون‌ریزی", "匯入", "インポート")
    L("Выбери файл .vrm", "Choose a .vrm file")
    L("Выберите «Импорт», чтобы выбрать файл .vrm, или скопируйте его в папку моделей Eta.", "Choose \"Import\" to pick a .vrm file, or copy it to the Eta models folder.")
    L("Обновить", "Refresh", "Yenile", "تحديث", "به‌روزرسانی", "重新整理", "更新")
    L("Библиотека (0)", "Library (0)")
    L("Моделей пока нет: импортируй или положи файлы .vrm в eta/model/", "No models yet: import or put .vrm files into eta/model/")
    L("Конфиги", "Configs", "Yapılandırmalar", "الإعدادات", "پیکربندی‌ها", "設定檔", "コンフィグ")
    L("Сохранение, переключение и обмен целыми наборами настроек", "Save, switch and share whole sets of settings", "Ayar setlerini kaydet, değiştir ve paylaş", "احفظ وبدّل وشارك مجموعات كاملة من الإعدادات", "ذخیره، تعویض و اشتراک کامل مجموعه تنظیمات", "儲存、切換與分享整組設定", "設定一式の保存・切替・共有")
    L("Несохранённая настройка", "Unsaved setup", "Kaydedilmemiş ayar", "إعداد غير محفوظ", "تنظیم ذخیره‌نشده", "未儲存的設定", "未保存の設定")
    L("Изменений от стандартных: 1  ·  ещё не в конфиге", "Changes from default: 1  ·  not in a config yet")
    L("Не сохранён", "Not saved", "Kaydedilmedi", "غير محفوظ", "ذخیره نشده", "未儲存", "未保存")
    L("Сохранить как новый", "Save as new", "Yeni olarak kaydet", "حفظ كجديد", "ذخیره به‌عنوان جدید", "另存為新", "新規保存")
    L("Откатить", "Revert", "Geri al", "تراجع", "بازگرداندن", "還原", "元に戻す")
    L("Изменения откатены", "Changes reverted")
    L("По умолчанию", "Defaults", "Varsayılan", "افتراضي", "پیش‌فرض", "預設", "初期値")
    L("Настройки по умолчанию", "Default settings restored")
    L("Библиотека", "Library", "Kitaplık", "المكتبة", "کتابخانه", "資料庫", "ライブラリ")
    L("Сохранено: %d", "Saved: %d")
    L("Пока нет сохранённых конфигов", "No saved configs yet")
    L("Загрузить", "Load", "Yükle", "تحميل", "بارگذاری", "載入", "読み込み")
    L("Сохранить", "Save", "Kaydet", "حفظ", "ذخیره", "儲存", "保存")
    L("Переименовать", "Rename", "Yeniden adlandır", "إعادة تسمية", "تغییر نام", "重新命名", "名前変更")
    L("Дублировать", "Duplicate", "Çoğalt", "تكرار", "تکثیر", "複製", "複製")
    L("Поделиться", "Share", "Paylaş", "مشاركة", "اشتراک", "分享", "共有")
    L("Авто", "Auto", "Otomatik", "تلقائي", "خودکار", "自動", "自動")
    L("Удалить", "Delete", "Sil", "حذف", "حذف", "刪除", "削除")
    L("Загружен \"%s\"", "Loaded \"%s\"", "\"%s\" yüklendi", "تم تحميل \"%s\"", "\"%s\" بارگذاری شد", "已載入「%s」", "「%s」を読み込みました")
    L("Конфиг загружен  ·  без изменений", "Config loaded  ·  no changes")
    L("Сохранён", "Saved", "Kaydedildi", "تم الحفظ", "ذخیره شد", "已儲存", "保存済み")
    L("Сохранён \"%s\"", "Saved \"%s\"", "\"%s\" kaydedildi", "تم حفظ \"%s\"", "\"%s\" ذخیره شد", "已儲存「%s」", "「%s」を保存しました")
    L("Введи новое имя в поле «Новый конфиг»", "Type the new name in the \"New config\" field")
    L("%s (копия)", "%s (copy)")
    L("только что  ·  изменений: 21", "just now  ·  changes: 21")
    L("только что  ·  изменений: 0", "just now  ·  changes: 0")
    L("2 ч назад  ·  изменений: 21", "2 h ago  ·  changes: 21")
    L("Дубликат создан", "Duplicate created")
    L("Код для обмена готов", "Share code is ready")
    L("Автозагрузка включена", "Auto-load enabled")
    L("Автозагрузка выключена", "Auto-load disabled")
    L("Удалён \"%s\"", "Deleted \"%s\"", "\"%s\" silindi", "تم حذف \"%s\"", "\"%s\" حذف شد", "已刪除「%s」", "「%s」を削除しました")
    L("Новый конфиг", "New config", "Yeni yapılandırma", "إعداد جديد", "پیکربندی جدید", "新設定檔", "新しいコンフィグ")
    L("Название (необязательно)", "Name (optional)", "Ad (isteğe bağlı)", "الاسم (اختياري)", "نام (اختیاری)", "名稱（選填）", "名前（任意）")
    L("Конфиг %d", "Config %d")
    L("Пустой %d", "Empty %d")
    L("Сохранено  ·  без изменений", "Saved  ·  no changes")
    L("Сохранить текущие", "Save current", "Mevcut olanı kaydet", "حفظ الحالي", "ذخیره فعلی", "儲存目前", "現在の設定を保存")
    L("Пустой", "Empty", "Boş", "فارغ", "خالی", "空白", "空")
    L("Создан \"%s\"", "Created \"%s\"")
    L("Конфиг хранит все настройки Функций, Визуала и Аима. Внешний вид меню остаётся твоим и не передаётся.", "A config stores all settings of Functions, Visuals and Aim. The menu's look stays yours and is not shared.")
    L("Вставь код для обмена", "Paste a share code")
    L("Вставлено", "Pasted", "Yapıştırıldı", "تم اللصق", "چسبانده شد", "已貼上", "貼り付けました")
    L("Буфер обмена пуст", "Clipboard is empty", "Pano boş", "الحافظة فارغة", "کلیپ‌بورد خالی است", "剪貼簿是空的", "クリップボードが空です")
    L("Настройки", "Settings", "Ayarlar", "الإعدادات", "تنظیمات", "設定", "設定")
    L("Внешний вид меню и конфиги", "Menu appearance and configs", "Menü görünümü ve yapılandırmalar", "مظهر القائمة والإعدادات", "ظاهر منو و پیکربندی‌ها", "選單外觀與設定檔", "メニューの見た目とコンフィグ")
    L("Внешний вид", "Appearance", "Görünüm", "المظهر", "ظاهر", "外觀", "外観")
    L("Тема", "Theme", "Tema", "السمة", "تم", "主題", "テーマ")
    L("Тема: %s", "Theme: %s")
    L("Непрозрачность панели", "Panel opacity", "Panel opaklığı", "عتامة اللوحة", "شفافیت پنل", "面板不透明度", "パネルの不透明度")
    L("Чем меньше, тем лучше видна игра за меню", "The lower it is, the better you see the game behind the menu")
    L("Масштаб интерфейса", "Interface scale", "Arayüz ölçeği", "مقياس الواجهة", "مقیاس رابط", "介面縮放", "UIスケール")
    L("Анимация", "Animation", "Animasyon", "الحركة", "انیمیشن", "動畫", "アニメーション")
    L("Обычно", "Normal", "Normal", "عادي", "عادی", "一般", "標準")
    L("Живо", "Lively", "Canlı", "نشِط", "پرجنب‌وجوش", "活潑", "ダイナミック")
    L("Язык", "Language", "Dil", "اللغة", "زبان", "語言", "言語")
    L("Система", "System", "Sistem", "النظام", "سیستم", "系統", "システム")
    L("Русский", "Русский")
    L("Скоро появятся новые языки", "More languages are coming soon")
    L("Частицы", "Particles", "Parçacıklar", "الجسيمات", "ذرات", "粒子", "パーティクル")
    L("Фоновые частицы", "Background particles", "Arka plan parçacıkları", "جسيمات الخلفية", "ذرات پس‌زمینه", "背景粒子", "背景パーティクル")
    L("Парящие частицы вокруг меню", "Floating particles around the menu")
    L("Плотность частиц", "Particle density", "Parçacık yoğunluğu", "كثافة الجسيمات", "تراکم ذرات", "粒子密度", "パーティクル密度")
    L("След от касаний", "Touch trail", "Dokunma izi", "أثر اللمس", "رد لمس", "觸控軌跡", "タッチの軌跡")
    L("Частицы там, где ты касаешься меню", "Particles where you touch the menu")
    L("Эффект нажатия", "Press effect", "Basma efekti", "تأثير الضغط", "جلوه فشردن", "按壓效果", "タップ効果")
    L("Частицы при нажатии на переключатель или кнопку", "Particles when you press a toggle or button")
    L("О программе", "About", "Hakkında", "حول", "درباره", "關於", "情報")
    L("ВХ, аимбот, АвтоФарм и твики для Oxide: Survival Island.", "ESP, aimbot, AutoFarm and tweaks for Oxide: Survival Island.")
    L("Подключено", "Connected", "Bağlandı", "متصل", "متصل", "已連線", "接続済み")
    L("Введи ключ, чтобы продолжить", "Enter your key to continue", "Devam etmek için anahtarı gir", "أدخل المفتاح للمتابعة", "برای ادامه کلید را وارد کنید", "輸入金鑰以繼續", "続けるにはキーを入力")
    L("Ваш ключ", "Your key", "Anahtarın", "مفتاحك", "کلید شما", "你的金鑰", "あなたのキー")
    L("Вставить", "Paste", "Yapıştır", "لصق", "چسباندن", "貼上", "貼り付け")
    L("Войти", "Sign in", "Giriş", "دخول", "ورود", "進入", "ログイン")
    L("Введи ключ", "Enter a key", "Anahtar gir", "أدخل المفتاح", "کلید را وارد کنید", "請輸入金鑰", "キーを入力")
    L("Неверный ключ", "Invalid key", "Geçersiz anahtar", "مفتاح غير صالح", "کلید نامعتبر", "金鑰無效", "無効なキー")
end

----------------------------------------------------------------------
-- иконки: рисуются из линий/кругов (сетка 24x24), без картинок
----------------------------------------------------------------------
local ICONS = {
    grid  = { {"r",3,3,7,7,2}, {"r",14,3,7,7,2}, {"r",14,14,7,7,2}, {"r",3,14,7,7,2} },
    bolt  = { {"p",true, 13,2, 3,14, 12,14, 11,22, 21,10, 12,10} },
    eye   = { {"p",true, 2,12, 5,8.5, 8.5,6.3, 12,5.5, 15.5,6.3, 19,8.5, 22,12, 19,15.5, 15.5,17.7, 12,18.5, 8.5,17.7, 5,15.5}, {"c",12,12,3} },
    cross = { {"c",12,12,9}, {"l",12,1.5,12,6}, {"l",12,18,12,22.5}, {"l",1.5,12,6,12}, {"l",18,12,22.5,12}, {"d",12,12,1} },
    cube  = { {"p",true, 12,2.5, 20.5,7.5, 20.5,16.5, 12,21.5, 3.5,16.5, 3.5,7.5}, {"p",false, 3.5,7.5, 12,12.5, 20.5,7.5}, {"l",12,12.5,12,21.5} },
    folder= { {"p",true, 3,5.5, 8.5,5.5, 10.5,8, 20,8, 21,9, 21,19, 20,20, 4,20, 3,19} },
    sliders = { {"l",3,6,6,6}, {"l",11,6,21,6}, {"c",8.5,6,2.4}, {"l",3,12,13,12}, {"l",18,12,21,12}, {"c",15.5,12,2.4}, {"l",3,18,7,18}, {"l",12,18,21,18}, {"c",9.5,18,2.4} },
    gauge = { {"p",false, 4,18, 2.8,13.5, 4.5,9, 8,5.8, 12.5,4.8, 17,5.8, 20.5,9, 21.2,13.5, 20,18}, {"l",12,15,16.5,9}, {"d",12,15,1.6} },
    pulse = { {"p",false, 2,12, 6,12, 9,4, 15,20, 18,12, 22,12} },
    layers= { {"p",true, 12,3, 21,8, 12,13, 3,8}, {"p",false, 3,12.5, 12,17.5, 21,12.5}, {"p",false, 3,16.8, 12,21.8, 21,16.8} },
    info  = { {"c",12,12,9.5}, {"l",12,16.5,12,11.5}, {"d",12,7.8,1} },
    clock = { {"c",12,12,9.5}, {"p",false, 12,6.5, 12,12, 16,14.2} },
    tree  = { {"p",true, 12,2.5, 16,7.5, 14.5,7.5, 18,12, 16.5,12, 20.5,17, 3.5,17, 7.5,12, 6,12, 9.5,7.5, 8,7.5}, {"l",12,17,12,21.5} },
    camera= { {"r",2,7,20,14,3}, {"c",12,14,3.6}, {"p",false, 8,7, 9.5,4, 14.5,4, 16,7} },
    arrow = { {"l",4,12,20,12}, {"p",false, 14,6, 20,12, 14,18} },
    wand  = { {"l",3.5,20.5,15,9}, {"l",18,2.5,18,7.5}, {"l",15.5,5,20.5,5}, {"d",21,12,1}, {"d",10.5,3.5,1} },
    shield= { {"p",true, 4,6, 11,3, 13,3, 20,6, 20,13, 17,18, 12,21.5, 7,18, 4,13} },
    target= { {"c",12,12,9.5}, {"c",12,12,5.5}, {"d",12,12,1.6} },
    download = { {"l",12,3,12,15}, {"p",false, 7,10.5, 12,15.5, 17,10.5}, {"p",false, 4,15, 4,20, 20,20, 20,15} },
    plus  = { {"l",5,12,19,12}, {"l",12,5,12,19} },
    x     = { {"l",6,6,18,18}, {"l",18,6,6,18} },
    check = { {"p",false, 5,12.5, 10,17.5, 19,7} },
    pencil= { {"p",true, 3.5,20.5, 4.5,15.5, 15.5,4.5, 19.5,8.5, 8.5,19.5}, {"l",13,7,17,11} },
    save  = { {"p",true, 4,4, 17,4, 20,7, 20,20, 4,20}, {"p",false, 8,4, 8,9, 15,9, 15,4}, {"p",false, 7,20, 7,14, 17,14, 17,20} },
    copy  = { {"r",8,8,13,13,2.5}, {"p",false, 16,8, 16,5.5, 14.5,4, 5.5,4, 4,5.5, 4,14.5, 5.5,16, 8,16} },
    share = { {"c",18,5.5,3}, {"c",6,12,3}, {"c",18,18.5,3}, {"l",8.6,13.5,15.4,17}, {"l",15.4,7,8.6,10.5} },
    star  = { {"p",true, 12,2.5, 14.8,8.8, 21.5,9.5, 16.5,14, 18,20.8, 12,17.3, 6,20.8, 7.5,14, 2.5,9.5, 9.2,8.8} },
    trash = { {"l",3.5,6,20.5,6}, {"p",false, 8.5,6, 8.5,3.5, 15.5,3.5, 15.5,6}, {"p",true, 5.5,6, 6.5,20.5, 17.5,20.5, 18.5,6}, {"l",10,10,10,16.5}, {"l",14,10,14,16.5} },
    undo  = { {"p",false, 3,4.5, 3,10, 8.5,10}, {"p",false, 3.8,10, 5,6.8, 8,4.5, 12,3.6, 16,4.6, 19.2,7.6, 20.4,11.6, 19.4,15.6, 16.4,18.8, 12.4,20.2, 8.4,19.4} },
    clipboard = { {"r",5.5,4,13,17.5,2.5}, {"r",9,2,6,4,1.5}, {"l",9,12,15,12}, {"l",9,16,13,16} },
    key   = { {"c",6.2,12,3.6}, {"l",9.8,12,21.5,12}, {"l",18,12,18,15.5}, {"l",21.5,12,21.5,14.8} },
    sparkle = { {"p",true, 12,2, 14,10, 22,12, 14,14, 12,22, 10,14, 2,12, 10,10} },
    backpack= { {"r",5,8,14,14,4.5}, {"p",false, 9,8, 9,5.2, 10.5,3.5, 13.5,3.5, 15,5.2, 15,8}, {"l",9,15,15,15} },
    robot = { {"r",4,8,16,12,3.5}, {"l",12,8,12,4.5}, {"d",12,3.6,1.2}, {"d",9,13.2,1.3}, {"d",15,13.2,1.3} },
    paw   = { {"d",6.5,10.5,2}, {"d",10,6.5,2}, {"d",14,6.5,2}, {"d",17.5,10.5,2}, {"d",12,16,4.4} },
    car   = { {"p",true, 3,13, 5.5,8, 8.5,6, 15.5,6, 18.5,8, 21,13, 21,17, 3,17}, {"d",7.5,17,2}, {"d",16.5,17,2} },
    parachute = { {"p",false, 3,11, 4.5,6.5, 8.5,3.6, 12,3, 15.5,3.6, 19.5,6.5, 21,11}, {"l",3,11,11,19.5}, {"l",21,11,13,19.5}, {"l",12,3.2,12,19}, {"r",10,19,4,3.2,1} },
    pin   = { {"c",12,9,6}, {"l",12,15,12,21} },
    door  = { {"r",6.5,3,11,18,2}, {"d",14.5,12,1.1} },
    cabinet = { {"r",6,3,12,18,1.6}, {"l",12,3,12,21}, {"d",10,12,0.9}, {"d",14,12,0.9} },
    turret= { {"p",false, 3,17, 5,12, 9,9, 15,9, 19,12, 21,17}, {"l",3,17,21,17}, {"l",12,9,12,5} },
    box   = { {"r",3,6,18,14,2}, {"l",3,11,21,11}, {"l",12,11,12,13.5} },
    bed   = { {"l",3,19,3,7}, {"p",false, 3,14, 21,14, 21,19}, {"r",5.5,9.5,5.5,4.5,1.6} },
    flame = { {"p",true, 12,3, 16,8, 18,12.5, 17,17, 12,21, 7,17, 6,12.5, 8,9.5, 10,11.5} },
    hammer= { {"l",5,19.5,13,11.5}, {"p",true, 9.5,6, 15,3.5, 20.5,9, 18,14.5, 13.5,12, 11,9.5} },
    recycle={ {"p",false, 4,12, 5,8, 8,5.2, 12,4.2, 16,5.2, 19,8}, {"p",false, 15.5,4.5, 19,8, 15.5,11}, {"p",false, 20,12, 19,16, 16,18.8, 12,19.8, 8,18.8, 5,16}, {"p",false, 8.5,19.5, 5,16, 8.5,13} },
    crystal={ {"p",true, 12,2, 18,8.5, 12,22, 6,8.5}, {"l",6,8.5,18,8.5} },
    rock  = { {"p",true, 3,17.5, 5.5,10.5, 11,7, 18,9, 21,17.5} },
    pumpkin={ {"c",12,13.2,7.2}, {"l",12,6,12,3} },
    leaf  = { {"p",true, 4,20, 5,12, 10,6, 18,3.5, 20.5,6, 19.5,14, 13,19}, {"l",4,20,12,12} },
    barrel= { {"r",6,3,12,18,4.5}, {"l",6,8.5,18,8.5}, {"l",6,15.5,18,15.5} },
    venn  = { {"c",9.5,9,5.2}, {"c",14.5,9,5.2}, {"c",12,14.8,5.2} },
    dot   = { {"d",12,12,3} },
    dotring = { {"d",12,12,3.4} },
    moon  = { {"p",true, 14,3, 9,5, 5,10, 5,15, 9,19.5, 14.5,21, 19,19, 15,17.5, 12.5,14, 12.5,9.5, 14,6} },
}

local function atanDeg(dy, dx) return math.deg(atan2(dy, dx)) end

local function mkLine(root, x1, y1, x2, y2, th, color)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local f = Frame(root, {
        Name = "p", AnchorPoint = V2(0.5, 0.5),
        Position = off((x1 + x2) / 2, (y1 + y2) / 2),
        Size = off(len + th * 0.35, th),
        Rotation = atanDeg(dy, dx),
        BackgroundColor3 = color,
    })
    Corner(f, "full")
    return f
end

local function mkCircle(root, cx, cy, r, th, color, filled)
    local f = Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = off(cx, cy), Size = off(r * 2, r * 2) })
    Corner(f, "full")
    if filled then
        f.Name = "p"
        f.BackgroundColor3 = color
    else
        f.Name = "o"
        f.BackgroundTransparency = 1
        Stroke(f, color, 0, th)
    end
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
    local k = size / 24
    local th = math.max(1, size / 13)
    for _, s in ipairs(spec) do
        local t = s[1]
        if t == "l" then
            mkLine(root, s[2] * k, s[3] * k, s[4] * k, s[5] * k, th, color)
        elseif t == "p" then
            local pts = {}
            for i = 3, #s - 1, 2 do pts[#pts + 1] = { s[i] * k, s[i + 1] * k } end
            for i = 1, #pts - 1 do
                mkLine(root, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], th, color)
            end
            if s[2] and #pts > 2 then
                mkLine(root, pts[#pts][1], pts[#pts][2], pts[1][1], pts[1][2], th, color)
            end
        elseif t == "c" then
            mkCircle(root, s[2] * k, s[3] * k, s[4] * k, th, color, false)
        elseif t == "d" then
            mkCircle(root, s[2] * k, s[3] * k, s[4] * k, th, color, true)
        elseif t == "r" then
            mkRRect(root, s[2] * k, s[3] * k, s[4] * k, s[5] * k, s[6] * k, th, color)
        end
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
        if d:IsA("UIStroke") then
            d.Transparency = 1 - a
        elseif d:IsA("Frame") and d.Name == "p" then
            d.BackgroundTransparency = 1 - a
        end
    end
end

----------------------------------------------------------------------
-- логотип η (орбита + искра)
----------------------------------------------------------------------
local sparks = {}

local function makeSpark(parent, s, color)
    local f = Frame(parent, { Name = "Spark", BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0.5), Size = off(s, s) })
    local a = Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(1, 0, 0, 1.5), BackgroundColor3 = color })
    Corner(a, "full")
    local b = Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = UDim2.new(0, 1.5, 1, 0), BackgroundColor3 = color })
    Corner(b, "full")
    local d = Frame(f, { AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(s * 0.3, s * 0.3), BackgroundColor3 = C.white })
    Corner(d, "full")
    return f
end

-- size: высота знака; возвращает корневой Frame (ширина size*1.5)
local function makeLogo(parent, size, ring, spark)
    local root = Frame(parent, { Name = "Logo", BackgroundTransparency = 1, Size = off(size * 1.5, size) })
    local k = size / 40
    local cx, cy = size * 0.75, size * 0.5
    local thin = math.max(1.2, size / 17)
    local thick = math.max(1.8, size / 10.5)
    local col = rgb(232, 222, 255)
    local A, B = size * 0.66, size * 0.17
    local phi = math.rad(-16)
    local rcy = cy + size * 0.07
    if ring then
        local N = 40
        local px, py
        local lt = math.max(1, size / 34)
        for i = 0, N do
            local t = (i / N) * math.pi * 2
            local ex, ey = A * math.cos(t), B * math.sin(t)
            local x = cx + ex * math.cos(phi) - ey * math.sin(phi)
            local y = rcy + ex * math.sin(phi) + ey * math.cos(phi)
            if px then
                local ln = mkLine(root, px, py, x, y, lt, rgb(206, 198, 255))
                ln.BackgroundTransparency = 0.45
            end
            px, py = x, y
        end
    end
    local ox, oy = cx - 20 * k, cy - 20 * k
    local function poly(pts, th)
        for i = 1, #pts - 2, 2 do
            mkLine(root, ox + pts[i] * k, oy + pts[i + 1] * k, ox + pts[i + 2] * k, oy + pts[i + 3] * k, th, col)
        end
    end
    poly({ 13.4, 10.2, 12.6, 16.6, 11.8, 22.6, 10.8, 28.8 }, thin)
    poly({ 12.4, 17, 14, 13.6, 16.8, 11.6, 20.2, 11.2, 23.4, 12.4, 25.6, 15.2, 26.5, 19, 26.4, 23.4, 25.6, 27.8, 24.4, 31.8, 23.2, 35.6, 21.8, 39 }, thick)
    if spark then
        local s = makeSpark(root, math.max(8, size * 0.3), C.white)
        s.Position = off(cx - A * 0.8, rcy + B * 0.5)
        sparks[#sparks + 1] = { f = s, s = math.max(8, size * 0.3), cx = cx, cy = rcy, a = A, b = B, phi = phi, th = math.random() * 6.28, sp = 0.55 }
    end
    return root
end

----------------------------------------------------------------------
-- общие хуки (заполняются позже, когда есть окно)
----------------------------------------------------------------------
local UI = {
    toast = function() end,
    pressFx = function() end,
    scrollLock = function() end,
}

local function measureH(text, size, font, w)
    local ok, r = pcall(function() return TextService:GetTextSize(text, size, font, V2(w, 4000)) end)
    if ok and r then return r.Y end
    local lines = math.ceil((utf8.len(text) or #text) * size * 0.58 / w)
    return lines * size * 1.25
end

local function fitDesc(text, maxW)
    text = T(text)
    for _, s in ipairs({ 12, 10, 9 }) do
        if measure(text, s, FONT_R) <= maxW then return s, 1 end
    end
    local hh = measureH(text, 9, FONT_R, maxW)
    return 9, math.max(2, math.floor(hh / 11 + 0.5))
end

local function addPress(btn, target, amount)
    local us = Instance.new("UIScale")
    us.Parent = target
    amount = amount or 0.96
    btn.InputBegan:Connect(function(input)
        if isPress(input) then tw(us, 0.1, { Scale = amount }, Quad, Out) end
    end)
    btn.InputEnded:Connect(function(input)
        if isPress(input) then tw(us, 0.25, { Scale = 1 }, Back, Out) end
    end)
    return us
end

----------------------------------------------------------------------
-- переключатель
----------------------------------------------------------------------
local function Toggle(parent, x, y, on, onClick)
    local W, H, K = 58, 32, 24
    local root = Frame(parent, {
        Name = "Toggle", Position = off(x, y), Size = off(W, H),
        BackgroundColor3 = C.off, BackgroundTransparency = 0.2,
    })
    Corner(root, "full")
    local stroke = Stroke(root, C.white, on and 0.55 or 0.9, 1)
    local fill = Frame(root, { Size = sc(1, 1), BackgroundColor3 = C.white, BackgroundTransparency = on and 0 or 1 })
    Corner(fill, "full")
    accentGradient(fill, 0)
    local knob = Frame(root, {
        AnchorPoint = V2(0, 0.5), Position = off(on and (W - K - 4) or 4, H / 2),
        Size = off(K, K), BackgroundColor3 = C.knob, ZIndex = 2,
    })
    Corner(knob, "full")
    local btn = Button(root, { ZIndex = 3 })
    local obj = { frame = root, on = on }
    function obj.set(v, instant)
        obj.on = v
        local goal = off(v and (W - K - 4) or 4, H / 2)
        if instant then
            knob.Position = goal
            fill.BackgroundTransparency = v and 0 or 1
            stroke.Transparency = v and 0.55 or 0.9
        else
            tw(knob, 0.3, { Position = goal }, Back, Out)
            tw(fill, 0.22, { BackgroundTransparency = v and 0 or 1 }, Quad, Out)
            tw(stroke, 0.22, { Transparency = v and 0.55 or 0.9 }, Quad, Out)
        end
    end
    btn.InputBegan:Connect(function(input)
        if isPress(input) then tw(knob, 0.12, { Size = off(K + 6, K) }, Quad, Out) end
    end)
    btn.InputEnded:Connect(function(input)
        if isPress(input) then tw(knob, 0.2, { Size = off(K, K) }, Quad, Out) end
    end)
    btn.Activated:Connect(function() if UI.scrolled then return end;
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    return obj
end

----------------------------------------------------------------------
-- ползунок
----------------------------------------------------------------------
local function Slider(parent, x, y, w, cfg)
    local R = 11
    local root = Frame(parent, { Name = "Slider", BackgroundTransparency = 1, Position = off(x, y), Size = off(w, 28) })
    local track = Frame(root, {
        AnchorPoint = V2(0, 0.5), Position = off(0, 14), Size = off(w, 6),
        BackgroundColor3 = C.track, BackgroundTransparency = 0.05,
    })
    Corner(track, "full")
    local fill = Frame(track, { Size = off(0, 6), BackgroundColor3 = C.white })
    Corner(fill, "full")
    accentGradient(fill, 0)
    local thumb = Frame(root, {
        AnchorPoint = V2(0.5, 0.5), Size = off(2 * R, 2 * R), Position = off(R, 14),
        BackgroundColor3 = C.knob, ZIndex = 3,
    })
    Corner(thumb, "full")
    Stroke(thumb, C.white, 0.55, 1)
    local hit = Button(root, { Size = off(w, 28), ZIndex = 4 })

    local value = cfg.value
    local function render(animate)
        local f = math.clamp((value - cfg.min) / (cfg.max - cfg.min), 0, 1)
        local cx = R + f * (w - 2 * R)
        if animate then
            tw(thumb, 0.12, { Position = off(cx, 14) }, Quad, Out)
            tw(fill, 0.12, { Size = off(cx, 6) }, Quad, Out)
        else
            thumb.Position = off(cx, 14)
            fill.Size = off(cx, 6)
        end
        if cfg.label then cfg.label.Text = cfg.fmt(value) end
    end
    render(false)

    local function setFromX(px)
        local aw = track.AbsoluteSize.X
        if aw <= 0 then return end
        local k = aw / w
        local f = (px - track.AbsolutePosition.X - R * k) / (aw - 2 * R * k)
        f = math.clamp(f, 0, 1)
        local v = cfg.min + f * (cfg.max - cfg.min)
        if cfg.step then v = math.floor(v / cfg.step + 0.5) * cfg.step end
        v = math.clamp(v, cfg.min, cfg.max)
        if v ~= value then
            value = v
            render(false)
            if cfg.onChange then cfg.onChange(v) end
        end
    end

    hit.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        UI.scrollLock(true)
        tw(thumb, 0.15, { Size = off(2 * R + 4, 2 * R + 4) }, Quad, Out)
        setFromX(input.Position.X)
        beginDrag(function(i) setFromX(i.Position.X) end, function()
            UI.scrollLock(false)
            tw(thumb, 0.2, { Size = off(2 * R, 2 * R) }, Quad, Out)
        end)
    end)

    local obj = { frame = root }
    function obj.set(v)
        value = v
        render(true)
    end
    return obj
end

----------------------------------------------------------------------
-- сегментированный переключатель
----------------------------------------------------------------------
local function Segmented(parent, x, y, w, options, selected, onSelect)
    local H, pad = 38, 4
    local n = #options
    local root = Frame(parent, {
        Name = "Segmented", Position = off(x, y), Size = off(w, H),
        BackgroundColor3 = C.panel, BackgroundTransparency = 0.55,
    })
    Corner(root, 13)
    Stroke(root, C.white, 0.9, 1)
    local segW = (w - pad * 2) / n
    local pill = Frame(root, {
        Name = "Pill", Size = off(segW, H - pad * 2), Position = off(pad, pad),
        BackgroundColor3 = C.white, Visible = selected ~= nil and selected > 0,
    })
    Corner(pill, 10)
    accentGradient(pill, 0)
    local labels = {}
    local obj = { frame = root, selected = selected, pill = pill }
    local function paint(i, instant)
        for k, l in ipairs(labels) do
            local goal = (k == i) and C.dark or rgb(176, 177, 206)
            if instant then l.TextColor3 = goal else tw(l, 0.2, { TextColor3 = goal }) end
        end
    end
    function obj.set(i, instant)
        obj.selected = i
        if i == nil or i < 1 then
            pill.Visible = false
            paint(0, true)
            return
        end
        local goal = off(pad + (i - 1) * segW, pad)
        if not pill.Visible then
            pill.Position = goal
            pill.Visible = true
        elseif instant then
            pill.Position = goal
        else
            tw(pill, 0.32, { Position = goal }, Quint, Out)
        end
        paint(i, instant)
    end
    for i, name in ipairs(options) do
        local b = Button(root, { Position = off(pad + (i - 1) * segW, pad), Size = off(segW, H - pad * 2), ZIndex = 2 })
        local l = Label(b, {
            Size = sc(1, 1), Text = name, TextSize = 14, Font = FONT_M,
            TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = rgb(176, 177, 206),
        })
        labels[i] = l
        b.Activated:Connect(function() if UI.scrolled then return end;
            UI.pressFx(b)
            obj.set(i, false)
            if onSelect then onSelect(i, name) end
        end)
    end
    obj.set(selected, true)
    return obj
end

----------------------------------------------------------------------
-- кнопки
----------------------------------------------------------------------
local function MakeButton(parent, x, y, w, h, text, iconName, style, onClick)
    local root = Frame(parent, { Name = "Btn", Position = off(x, y), Size = off(w, h), BackgroundColor3 = C.white })
    Corner(root, 14)
    local fg = C.txt
    if style == "primary" or style == "dim" then
        accentGradient(root, 0)
        fg = C.dark
        if style == "dim" then root.BackgroundTransparency = 0.5 end
    else
        root.BackgroundColor3 = rgb(72, 72, 104)
        root.BackgroundTransparency = 0.72
        Stroke(root, C.white, 0.88, 1)
    end
    local tsize = 15
    local font = FONT_B
    local twd = measure(T(text), tsize, font)
    local iw = iconName and 17 or 0
    local gap = iconName and 8 or 0
    local sx = (w - (iw + gap + twd)) / 2
    local ic = iconName and Icon(root, iconName, 17, fg, { Position = off(sx, (h - 17) / 2) }) or nil
    local lb = Label(root, {
        Position = off(sx + iw + gap, 0), Size = off(twd + 6, h), Text = text,
        TextSize = tsize, Font = font, TextColor3 = fg,
        TextTransparency = (style == "dim") and 0.35 or 0,
    })
    local btn = Button(root, { ZIndex = 3 })
    addPress(btn, root, 0.97)
    btn.Activated:Connect(function() if UI.scrolled then return end;
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    return root, lb, btn
end

local function Swatch(parent, x, y, d, c1, c2, selected, onClick, withCheck)
    local root = Frame(parent, { Name = "Swatch", Position = off(x, y), Size = off(d, d), BackgroundColor3 = C.white })
    Corner(root, "full")
    Grad(root, c1, c2, 90)
    local hi = Frame(root, {
        Position = off(d * 0.2, d * 0.12), Size = off(d * 0.38, d * 0.24),
        BackgroundColor3 = C.white, BackgroundTransparency = 0.55,
    })
    Corner(hi, "full")
    local ring = Frame(root, {
        AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(d + 9, d + 9), BackgroundTransparency = 1,
    })
    Corner(ring, "full")
    local rs = Stroke(ring, C.white, selected and 0.1 or 1, 2)
    local chk
    if withCheck then
        chk = Icon(root, "check", d * 0.5, C.dark, { Position = off(d * 0.25, d * 0.25), Visible = selected })
    end
    local btn = Button(root, { ZIndex = 3 })
    btn.Activated:Connect(function() if UI.scrolled then return end;
        UI.pressFx(root)
        if onClick then onClick() end
    end)
    local obj = {}
    function obj.set(v)
        tw(rs, 0.2, { Transparency = v and 0.1 or 1 })
        if chk then chk.Visible = v end
    end
    return obj
end

local function Chip(parent, spec)
    local h = spec.h or 30
    local size = 12
    local font = FONT_M
    local ck = (spec.group or "") .. "|" .. spec.text
    if Persist.chip[ck] ~= nil then spec.on = Persist.chip[ck] end
    local tw_ = measure(T(spec.text), size, font)
    local iw = spec.icon and 15 or 0
    local w = math.ceil(tw_ + 26 + iw + (spec.icon and 4 or 0))
    local color = spec.color or rgb(170, 160, 250)
    local root = Frame(parent, { Name = "Chip", Size = off(w, h), BackgroundColor3 = color, BackgroundTransparency = 0.85 })
    Corner(root, "full")
    local stroke = Stroke(root, color, 0.3, 1)
    local ic
    if spec.icon then
        ic = Icon(root, spec.icon, 14, color, { Position = off(10, (h - 14) / 2) })
    end
    local lb = Label(root, {
        Position = off(12 + iw + (spec.icon and 4 or 0) - (spec.icon and 0 or 0), 0), Size = off(tw_ + 4, h),
        Text = spec.text, TextSize = size, Font = font, TextColor3 = C.txt,
    })
    if not spec.icon then lb.Position = off(13, 0) end
    local btn = Button(root, { ZIndex = 3 })
    local obj = { root = root, w = w, on = spec.on }
    function obj.set(v, instant)
        obj.on = v
        Persist.chip[ck] = v
        local fillT = v and 0.8 or 0.94
        local strokeT = v and 0.2 or 0.86
        local fillC = v and color or C.white
        local strokeC = v and color or C.white
        local txtC = v and C.txt or rgb(170, 171, 198)
        local icC = v and color or rgb(150, 151, 180)
        if instant then
            root.BackgroundTransparency, root.BackgroundColor3 = fillT, fillC
            stroke.Transparency, stroke.Color = strokeT, strokeC
            lb.TextColor3 = txtC
        else
            tw(root, 0.2, { BackgroundTransparency = fillT, BackgroundColor3 = fillC })
            tw(stroke, 0.2, { Transparency = strokeT, Color = strokeC })
            tw(lb, 0.2, { TextColor3 = txtC })
        end
        if ic then setIconColor(ic, icC, instant) end
    end
    obj.set(spec.on, true)
    btn.Activated:Connect(function() if UI.scrolled then return end;
        UI.pressFx(root)
        obj.set(not obj.on, false)
        if spec.onClick then spec.onClick(obj.on) end
    end)
    return obj
end

----------------------------------------------------------------------
-- колонка: раскладка строк сверху вниз
----------------------------------------------------------------------
local Column = {}
Column.__index = Column

local function Box(parent, p, group)
    if group then return Group(parent, p) end
    return Frame(parent, p)
end

local function newColumn(parent, x, y0, w, rv, ci)
    local c = setmetatable({}, Column)
    c.w, c.y, c.rv, c.ci = w, y0, rv, ci or 1
    c.holder = Frame(parent, { Name = "Col", BackgroundTransparency = 1, Position = off(x, 0), Size = off(w, 10) })
    return c
end

function Column:done()
    self.holder.Size = off(self.w, self.y)
    return self.y
end

function Column:gap(h) self.y = self.y + h end

function Column:row(h, opts)
    opts = opts or {}
    local vis = self.rv ~= nil and self.y < PAGE_H + 20
    local r = Box(self.holder, { Name = "Row", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, h) }, opts.dep or vis)
    if vis then self.rv.add(r, self.ci) end
    if opts.sep ~= false then
        Frame(r, { Name = "sep", Position = off(0, h - 1), Size = off(self.w, 1), BackgroundTransparency = 0.93 })
    end
    if opts.dep then
        local inv = opts.inv
        bindState(opts.dep, function(v, instant)
            local en = v
            if inv then en = not v end
            local goal = en and 0 or 0.5
            r:SetAttribute("dimT", goal)
            if instant then r.GroupTransparency = goal else tw(r, 0.25, { GroupTransparency = goal }) end
        end)
    end
    self.y = self.y + h
    return r
end

function Column:header(title, icon, hint, topGap)
    self.y = self.y + (topGap or 0)
    local vis = self.rv ~= nil and self.y < PAGE_H + 20
    local r = Box(self.holder, { Name = "Header", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, 26) }, vis)
    if vis then self.rv.add(r, self.ci) end
    local badge = Frame(r, { Size = off(26, 26), BackgroundColor3 = rgb(140, 130, 235), BackgroundTransparency = 0.78 })
    Corner(badge, "full")
    Stroke(badge, C.white, 0.9, 1)
    local ic = Icon(badge, icon, 14, rgb(196, 188, 255), { Position = off(6, 6) })
    Label(r, { Position = off(36, 0), Size = off(self.w - 36, 26), Text = title, TextSize = 15 })
    local hl
    if hint then
        hl = Label(r, {
            AnchorPoint = V2(1, 0), Position = off(self.w, 0), Size = off(self.w * 0.62, 26),
            Text = hint, TextSize = 12, TextColor3 = C.txt3, TextXAlignment = Enum.TextXAlignment.Right,
        })
    end
    self.y = self.y + 26 + 13
    return r, hl
end

function Column:toggle(key, title, desc, opts)
    opts = opts or {}
    local maxW = self.w - 76
    local size, lines = 12, 1
    if desc then size, lines = fitDesc(desc, maxW) end
    local extra = (lines - 1) * 11
    local h = (desc and 68 or 45) + extra
    local r = self:row(h, opts)
    Label(r, { Position = off(0, 8), Size = off(self.w - 72, 22), Text = title, TextSize = 16 })
    if desc then
        Label(r, {
            Position = off(0, 31), Size = off(maxW, 18 + extra), Text = desc, TextSize = size,
            TextColor3 = C.txt3, Font = FONT_R, TextWrapped = lines > 1,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
    end
    local t = Toggle(r, self.w - 58, desc and 11 or 3, State[key], function() setState(key, not State[key]) end)
    bindState(key, function(v, instant) t.set(v, instant) end)
    return r, t
end

function Column:slider(key, title, desc, cfg, opts)
    local size, lines = 12, 1
    if desc then size, lines = fitDesc(desc, self.w) end
    local extra = (lines - 1) * 11
    local h = (desc and 87 or 72) + extra
    local r = self:row(h, opts)
    Label(r, { Position = off(0, 0), Size = off(self.w - 100, 22), Text = title, TextSize = 16 })
    local val = Label(r, {
        AnchorPoint = V2(1, 0), Position = off(self.w, 1), Size = off(100, 20),
        TextSize = 14, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Right,
    })
    if desc then
        Label(r, {
            Position = off(0, 21), Size = off(self.w, 18 + extra), Text = desc, TextSize = size,
            TextColor3 = C.txt3, Font = FONT_R, TextWrapped = lines > 1,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
    end
    cfg.label = val
    cfg.value = State[key]
    local userChange = cfg.onChange
    cfg.onChange = function(v)
        State[key] = v
        if userChange then userChange(v) end
    end
    local s = Slider(r, 0, (desc and 44 or 29) + extra, self.w, cfg)
    return r, s
end

function Column:segment(label, options, selected, onSelect, opts)
    local h = label and 77 or 52
    local r = self:row(h, opts)
    local sid = label or ""
    if Persist.seg[sid] then selected = Persist.seg[sid] end
    if label then Label(r, { Position = off(0, 0), Size = off(self.w, 22), Text = label, TextSize = 16 }) end
    local seg = Segmented(r, 0, label and 31 or 6, self.w, options, selected, function(i, name)
        Persist.seg[sid] = i
        if onSelect then onSelect(i, name) end
    end)
    return r, seg
end

function Column:button(text, icon, style, onClick, opts)
    opts = opts or {}
    local r = self:row(56, opts)
    local b, lb, btn = MakeButton(r, 0, 6, self.w, 44, text, icon, style, onClick)
    return r, b
end

function Column:note(text, size, color, gapAfter)
    size = size or 12
    text = T(text)
    local hh = measureH(text, size, FONT_R, self.w) + 4
    Label(self.holder, {
        Position = off(0, self.y), Size = off(self.w, hh), Text = text, TextSize = size,
        TextColor3 = color or C.txt2, Font = FONT_R, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
    self.y = self.y + hh + (gapAfter or 10)
end

function Column:chips(label, specs, opts)
    local vis = self.rv ~= nil and self.y < PAGE_H + 20
    local r = Box(self.holder, { Name = "Chips", BackgroundTransparency = 1, Position = off(0, self.y), Size = off(self.w, 10) }, vis)
    if vis then self.rv.add(r, self.ci) end
    local ly = 0
    if label then
        Label(r, { Position = off(0, 4), Size = off(self.w, 22), Text = label, TextSize = 16 })
        ly = 32
    else
        ly = 6
    end
    local cx, cy = 0, ly
    local lineH = (opts and opts.h or 30) + 8
    local list = {}
    for _, sp in ipairs(specs) do
        sp.h = sp.h or (opts and opts.h)
        sp.group = label or ""
        local chip = Chip(r, sp)
        if cx + chip.w > self.w and cx > 0 then
            cx = 0
            cy = cy + lineH
        end
        chip.root.Position = off(cx, cy)
        cx = cx + chip.w + 8
        list[#list + 1] = chip
    end
    local h = cy + (opts and opts.h or 30) + 12
    r.Size = off(self.w, h)
    if not (opts and opts.sep == false) then
        Frame(r, { Name = "sep", Position = off(0, h - 1), Size = off(self.w, 1), BackgroundTransparency = 0.93 })
    end
    self.y = self.y + h
    return r, list
end

local Builders, Input
do

----------------------------------------------------------------------
-- превью (демо-сцены) для Визуала и Аима
----------------------------------------------------------------------
local PREV_W, PREV_H = 357, 304

local function namePill(parent, x, y, text, color, size)
    size = size or 9
    local w = measure(T(text), size, FONT_M) + 22
    x = math.max(4, math.min(x, PREV_W - w - 4))
    local f = Frame(parent, { Position = off(x, y), Size = off(w, 15), BackgroundColor3 = rgb(14, 12, 28), BackgroundTransparency = 0.12 })
    Corner(f, "full")
    Stroke(f, color, 0.5, 1)
    local d = Frame(f, { Position = off(5, 5), Size = off(5, 5), BackgroundColor3 = color })
    Corner(d, "full")
    Label(f, { Position = off(13, 0), Size = off(w - 14, 15), Text = text, TextSize = size, TextColor3 = C.txt })
    return f
end

local function skeleton(parent, cx, top, h, color, dotsOnly)
    local th = 1.3
    local hr = h * 0.075
    local pts = {
        head = { cx, top + hr }, neck = { cx, top + hr * 2 }, shL = { cx - h * 0.14, top + h * 0.2 }, shR = { cx + h * 0.14, top + h * 0.2 },
        elL = { cx - h * 0.19, top + h * 0.38 }, elR = { cx + h * 0.19, top + h * 0.38 },
        haL = { cx - h * 0.12, top + h * 0.52 }, haR = { cx + h * 0.12, top + h * 0.52 },
        hip = { cx, top + h * 0.55 }, hpL = { cx - h * 0.08, top + h * 0.55 }, hpR = { cx + h * 0.08, top + h * 0.55 },
        knL = { cx - h * 0.1, top + h * 0.78 }, knR = { cx + h * 0.1, top + h * 0.78 },
        ftL = { cx - h * 0.09, top + h }, ftR = { cx + h * 0.09, top + h },
    }
    if dotsOnly then
        for _, p in pairs(pts) do mkCircle(parent, p[1], p[2], 1.9, 1, color, true) end
        return
    end
    local function ln(a, b) mkLine(parent, pts[a][1], pts[a][2], pts[b][1], pts[b][2], th, color) end
    mkCircle(parent, pts.head[1], pts.head[2], hr, th, color, false)
    ln("neck", "hip"); ln("shL", "shR"); ln("shL", "elL"); ln("elL", "haL"); ln("shR", "elR"); ln("elR", "haR")
    ln("hpL", "hpR"); ln("hpL", "knL"); ln("knL", "ftL"); ln("hpR", "knR"); ln("knR", "ftR")
end

local function previewBase(parent, x, y)
    local p = Frame(parent, { Name = "Preview", Position = off(x, y), Size = off(PREV_W, PREV_H), BackgroundColor3 = rgb(14, 12, 26), ClipsDescendants = true })
    Corner(p, 13)
    local sky = Frame(p, { Size = off(PREV_W, PREV_H * 0.42) })
    Grad(sky, rgb(24, 17, 46), rgb(104, 58, 112), 90)
    local hill = Frame(p, { AnchorPoint = V2(0.5, 0), Position = off(PREV_W * 0.5, PREV_H * 0.34), Size = off(PREV_W * 1.5, 120), BackgroundColor3 = rgb(36, 23, 55) })
    Corner(hill, "full")
    local ground = Frame(p, { Position = off(0, PREV_H * 0.43), Size = off(PREV_W, PREV_H * 0.57) })
    Grad(ground, rgb(26, 21, 46), rgb(10, 9, 20), 90)
    for _, fy in ipairs({ 0.5, 0.58, 0.69, 0.82, 0.95 }) do
        Frame(p, { Position = off(0, PREV_H * fy), Size = off(PREV_W, 1), BackgroundTransparency = 0.93 })
    end
    for _, tx in ipairs({ 112, 178, 282 }) do
        Icon(p, "tree", 15, rgb(44, 96, 70), { Position = off(tx, PREV_H * 0.33) })
    end
    local function blob(bx, by, bw, bh, col)
        local b = Frame(p, { Position = off(bx, by), Size = off(bw, bh), BackgroundColor3 = col })
        Corner(b, "full")
    end
    blob(92, 150, 36, 17, rgb(70, 70, 86)); blob(122, 196, 30, 15, rgb(190, 110, 44))
    blob(12, 270, 78, 26, rgb(86, 72, 40)); blob(70, 238, 22, 20, rgb(60, 60, 70))
    local function sil(sx, sy, sw, sh)
        local b = Frame(p, { Position = off(sx, sy), Size = off(sw, sh), BackgroundColor3 = rgb(56, 54, 70), BackgroundTransparency = 0.1 })
        Corner(b, 6)
    end
    sil(34, 210, 26, 70); sil(236, 190, 24, 74); sil(150, 178, 16, 40)
    return p
end

local function buildEspPreview(parent, x, y)
    local p = previewBase(parent, x, y)
    local pink, gold = rgb(255, 112, 170), rgb(255, 212, 90)
    -- радар
    local rad = Frame(p, { Position = off(12, 12), Size = off(60, 60), BackgroundColor3 = rgb(18, 16, 38), BackgroundTransparency = 0.25 })
    Corner(rad, "full")
    Stroke(rad, rgb(150, 130, 200), 0.45, 1)
    for _, d in ipairs({ { 40, 34 }, { 48, 30 }, { 42, 24 } }) do mkCircle(p, d[1], d[2], 2.4, 1, pink, true) end
    mkCircle(p, 42, 44, 3, 1, rgb(110, 220, 240), true)
    -- лучи (снаплайны)
    local bx, by = PREV_W / 2, PREV_H - 4
    local targets = {
        { 141, 196, pink }, { 172, 244, pink }, { 232, 188, pink }, { 262, 168, pink }, { 326, 188, gold }, { 335, 270, pink },
    }
    for _, t in ipairs(targets) do mkLine(p, bx, by, t[1], t[2], 1.2, t[3]).BackgroundTransparency = 0.45 end
    -- игроки
    local players = {
        { 141, 128, 66, pink, "Nyx 49 м", false, "Kriss Vector" },
        { 172, 142, 100, pink, "Raven 14 м", true, "Assault Rifle" },
        { 232, 124, 62, pink, "Vex 32 м", false, "Thompson" },
        { 262, 108, 56, pink, "Ghost 78 м", false, nil },
        { 326, 126, 62, gold, "Bot-07 20 м", false, "DVL" },
        { 335, 176, 98, pink, "Rook 10 м", true, "DVL" },
    }
    for _, pl in ipairs(players) do
        local cx, top, h, col = pl[1], pl[2], pl[3], pl[4]
        skeleton(p, cx, top, h, col, false)
        if pl[6] then
            local bxf = Frame(p, { Position = off(cx - h * 0.26, top - 2), Size = off(h * 0.52, h + 4), BackgroundColor3 = col, BackgroundTransparency = 0.88 })
            Stroke(bxf, col, 0.2, 1)
            local hb = Frame(p, { Position = off(cx + h * 0.3, top - 2), Size = off(3, h + 4), BackgroundColor3 = rgb(110, 230, 150) })
        end
        namePill(p, cx - 24, top - 22, pl[5], col)
        if pl[7] then Label(p, { Position = off(cx - 20, top + h + 4), Size = off(80, 12), Text = pl[7], TextSize = 7.5, TextColor3 = rgb(210, 210, 225), Font = FONT_R }) end
    end
    return p
end

local function buildAimPreview(parent, x, y)
    local p = previewBase(parent, x, y)
    local pink, gold = rgb(255, 112, 170), rgb(255, 212, 90)
    local ring = Frame(p, { AnchorPoint = V2(0.5, 0.5), Position = off(PREV_W / 2, PREV_H / 2 + 4), Size = off(450, 450), BackgroundTransparency = 1 })
    Corner(ring, "full")
    Stroke(ring, pink, 0.25, 2)
    skeleton(p, 198, 130, 74, pink, true)
    skeleton(p, 262, 150, 64, pink, true)
    skeleton(p, 120, 130, 40, gold, true)
    skeleton(p, 336, 128, 46, gold, true)
    mkCircle(p, 198, 130, 4, 1.2, C.white, false)
    Label(p, { Position = off(206, 122), Size = off(40, 10), Text = "Голова", TextSize = 7, TextColor3 = pink })
    local cx, cy = PREV_W / 2 - 4, 176
    mkLine(p, cx, cy, 198, 132, 1.3, C.white).BackgroundTransparency = 0.35
    mkLine(p, cx - 6, cy, cx + 6, cy, 1, C.white)
    mkLine(p, cx, cy - 6, cx, cy + 6, 1, C.white)
    -- HUD-плашка
    local hud = Frame(p, { AnchorPoint = V2(0.5, 1), Position = off(PREV_W / 2, PREV_H - 10), Size = off(250, 20), BackgroundColor3 = rgb(14, 12, 28), BackgroundTransparency = 0.12 })
    Corner(hud, "full")
    Stroke(hud, C.white, 0.85, 1)
    local c1 = Frame(hud, { Position = off(5, 3), Size = off(36, 14), BackgroundColor3 = rgb(70, 68, 100) })
    Corner(c1, "full")
    Label(c1, { Size = sc(1, 1), Text = "Силент", TextSize = 7.5, TextXAlignment = Enum.TextXAlignment.Center })
    mkCircle(hud, 52, 10, 2.4, 1, pink, true)
    Label(hud, { Position = off(58, 0), Size = off(120, 20), Text = "Nyx  ·  49 м  ·  Голова", TextSize = 8, Font = FONT_R })
    local bar = Frame(hud, { Position = off(176, 8), Size = off(24, 4), BackgroundColor3 = rgb(80, 80, 110) })
    Corner(bar, "full")
    local barf = Frame(bar, { Size = off(10, 4), BackgroundColor3 = rgb(110, 230, 150) })
    Corner(barf, "full")
    local fire = Frame(hud, { Position = off(205, 3), Size = off(40, 14), BackgroundColor3 = rgb(200, 50, 90) })
    Corner(fire, "full")
    Label(fire, { Size = sc(1, 1), Text = "Стрельба", TextSize = 7.5, TextXAlignment = Enum.TextXAlignment.Center })
    return p
end

----------------------------------------------------------------------
-- карточки обзора
----------------------------------------------------------------------
local function Sparkline(parent, x, y, w, h)
    local N = 22
    local bw = w / N
    local bars, tops = {}, {}
    local values = {}
    for i = 1, N do
        values[i] = 59
        local b = Frame(parent, { AnchorPoint = V2(0, 1), Position = off(x + (i - 1) * bw, y + h), Size = off(bw + 0.6, h * 0.9), BackgroundColor3 = rgb(150, 160, 240) })
        Grad(b, rgb(150, 160, 240), rgb(150, 160, 240), 90, 0.55, 1)
        local t = Frame(parent, { AnchorPoint = V2(0, 0.5), Position = off(x + (i - 1) * bw, y + h * 0.1), Size = off(bw + 0.6, 1.6), BackgroundColor3 = rgb(170, 200, 255) })
        bars[i], tops[i] = b, t
    end
    local dot = Frame(parent, { AnchorPoint = V2(0.5, 0.5), Position = off(x + w, y + h * 0.1), Size = off(7, 7), BackgroundColor3 = C.white })
    Corner(dot, "full")
    local halo = Frame(parent, { AnchorPoint = V2(0.5, 0.5), Position = off(x + w, y + h * 0.1), Size = off(15, 15), BackgroundColor3 = rgb(160, 200, 255), BackgroundTransparency = 0.7 })
    Corner(halo, "full")
    local obj = {}
    function obj.push(v)
        table.remove(values, 1)
        values[#values + 1] = v
        local maxv = 70
        for i = 1, N do
            local f = math.clamp(values[i] / maxv, 0.15, 1)
            local hh = h * 0.9 * f
            bars[i].Size = off(bw + 0.6, hh)
            tops[i].Position = off(x + (i - 1) * bw, y + h - hh)
        end
        local f = math.clamp(values[N] / maxv, 0.15, 1)
        local ty = y + h - h * 0.9 * f
        dot.Position = off(x + w, ty)
        halo.Position = off(x + w, ty)
    end
    obj.push(59)
    return obj
end

local function StatCard(parent, x, y, w, h, icon, title)
    local root = Frame(parent, { Name = "Stat", Position = off(x, y), Size = off(w, h), BackgroundTransparency = 0.94 })
    Corner(root, 16)
    Stroke(root, C.white, 0.9, 1)
    Icon(root, icon, 15, rgb(176, 166, 252), { Position = off(14, 14) })
    Label(root, { Position = off(36, 10), Size = off(w - 48, 22), Text = title, TextSize = 12.5, TextColor3 = C.txt2 })
    local val = Label(root, { Position = off(14, 50), Size = off(110, 34), Text = "", TextSize = 24, Font = FONT_B })
    return root, val
end

local function InfoChip(parent, x, y, text, dot)
    local w = measure(T(text), 12, FONT_M) + 36
    local f = Frame(parent, { Name = "InfoChip", Position = off(x, y), Size = off(w, 26), BackgroundTransparency = 0.93 })
    Corner(f, "full")
    Stroke(f, C.white, 0.88, 1)
    local d = Frame(f, { AnchorPoint = V2(0, 0.5), Position = off(11, 13), Size = off(8, 8), BackgroundColor3 = dot })
    Corner(d, "full")
    local lb = Label(f, { Position = off(25, 0), Size = off(w - 28, 26), Text = text, TextSize = 12, TextColor3 = rgb(212, 214, 234) })
    return f, lb, w
end

local function Tile(parent, x, y, w, h, key, title, icon)
    local root = Frame(parent, { Name = "Tile", Position = off(x, y), Size = off(w, h), BackgroundTransparency = 0.94 })
    Corner(root, 18)
    local stroke = Stroke(root, C.white, 0.88, 1)
    local fill = Frame(root, { Size = sc(1, 1), BackgroundTransparency = 1 })
    Corner(fill, 18)
    accentGradient(fill, 90)
    local ibg = Frame(root, { Position = off(14, 12), Size = off(34, 34), BackgroundTransparency = 0.9 })
    Corner(ibg, "full")
    local ic = Icon(ibg, icon, 17, rgb(172, 174, 206), { Position = off(8.5, 8.5) })
    local glow = Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = off(w - 18, 18), Size = off(20, 20), BackgroundTransparency = 1 })
    Corner(glow, "full")
    local dot = Frame(root, { AnchorPoint = V2(0.5, 0.5), Position = off(w - 18, 18), Size = off(10, 10), BackgroundColor3 = rgb(120, 122, 152), BackgroundTransparency = 0.35 })
    Corner(dot, "full")
    local size = 16
    while measure(T(title), size, FONT_B) > w - 28 and size > 11 do size = size - 1 end
    local ttl = Label(root, { Position = off(16, h - 52), Size = off(w - 20, 24), Text = title, TextSize = size, Font = FONT_B })
    local st = Label(root, { Position = off(16, h - 30), Size = off(w - 24, 18), Text = "Выкл", TextSize = 12, Font = FONT_R })
    local btn = Button(root, { ZIndex = 5 })
    addPress(btn, root, 0.96)
    local function paint(v, instant)
        local ft = v and 0 or 1
        local ttlC = v and C.dark or rgb(208, 210, 232)
        local stC = v and rgb(74, 66, 128) or C.txt4
        local ibgT = v and 0.62 or 0.9
        local glowT = v and 0.55 or 1
        local dotC = v and C.white or rgb(120, 122, 152)
        local dotT = v and 0 or 0.35
        st.Text = T(v and "Вкл" or "Выкл")
        local icC = v and rgb(40, 34, 92) or rgb(172, 174, 206)
        if instant then
            fill.BackgroundTransparency = ft; ttl.TextColor3 = ttlC; st.TextColor3 = stC
            ibg.BackgroundTransparency = ibgT; glow.BackgroundTransparency = glowT
            dot.BackgroundColor3 = dotC; dot.BackgroundTransparency = dotT
            stroke.Transparency = v and 1 or 0.88
        else
            tw(fill, 0.28, { BackgroundTransparency = ft }); tw(ttl, 0.2, { TextColor3 = ttlC }); tw(st, 0.2, { TextColor3 = stC })
            tw(ibg, 0.2, { BackgroundTransparency = ibgT }); tw(glow, 0.3, { BackgroundTransparency = glowT })
            tw(dot, 0.2, { BackgroundColor3 = dotC, BackgroundTransparency = dotT })
            tw(stroke, 0.2, { Transparency = v and 1 or 0.88 })
        end
        ibg.BackgroundColor3 = v and C.white or C.white
        setIconColor(ic, icC, instant)
    end
    bindState(key, paint)
    btn.Activated:Connect(function() if UI.scrolled then return end;
        UI.pressFx(root)
        setState(key, not State[key])
    end)
    return root
end

----------------------------------------------------------------------
-- поле ввода и карточка
----------------------------------------------------------------------
function Input(parent, x, y, w, h, icon, placeholder, size)
    local root = Frame(parent, {
        Name = "Input", Position = off(x, y), Size = off(w, h),
        BackgroundColor3 = rgb(16, 15, 34), BackgroundTransparency = 0.45,
    })
    Corner(root, 16)
    local stroke = Stroke(root, C.white, 0.9, 1)
    local ic = Icon(root, icon, 18, rgb(150, 150, 182), { Position = off(16, (h - 18) / 2) })
    local box = New("TextBox", {
        Name = "Box", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = off(48, 0), Size = off(w - 62, h),
        Font = FONT_M, TextSize = size or 16, TextColor3 = C.txt,
        PlaceholderText = T(placeholder), PlaceholderColor3 = rgb(112, 113, 144),
        Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
    }, root)
    box.Focused:Connect(function()
        tw(stroke, 0.2, { Transparency = 0.35, Color = theme.a })
        tw(root, 0.2, { BackgroundTransparency = 0.3 })
    end)
    box.FocusLost:Connect(function()
        tw(stroke, 0.2, { Transparency = 0.9, Color = C.white })
        tw(root, 0.2, { BackgroundTransparency = 0.45 })
    end)
    return root, box, stroke, ic
end

local function Card(parent, y, h, rv)
    local f = Box(parent, { Name = "Card", Position = off(21, y), Size = off(802, h), BackgroundColor3 = C.white, BackgroundTransparency = 0.955 }, rv ~= nil)
    if rv then rv.add(f, 1) end
    Corner(f, 20)
    Stroke(f, C.white, 0.9, 1)
    return f
end

Builders = {}
local COLW, LX, RX = 357, 40, 448

local function titleBlock(s, title, subtitle, rv)
    local t1 = Label(s, { Name = "Title", Position = off(21, 12), Size = off(430, 38), Text = title, TextSize = 28, Font = FONT_B, TextColor3 = rgb(236, 230, 255) })
    local t2 = Label(s, { Name = "Subtitle", Position = off(21, 50), Size = off(440, 22), Text = subtitle, TextSize = 13.5, TextColor3 = C.txt2 })
    if rv then
        rv.titles[#rv.titles + 1] = t1
        rv.titles[#rv.titles + 1] = t2
    end
end

local function fmtN(unit, dec)
    return function(v)
        if dec and dec > 0 then return string.format("%." .. dec .. "f", v) .. T(unit) end
        return string.format("%d", math.floor(v + 0.5)) .. T(unit)
    end
end

----------------------------------------------------------------------
-- ОБЗОР
----------------------------------------------------------------------
Builders.overview = function(page)
    local s = page.scroller
    local rv = page.rv
    titleBlock(s, "Обзор", "Игра вкратце и несколько переключателей под рукой", rv)

    local hero = Group(s, { Name = "Hero", Position = off(0, 84), Size = off(PAGE_W, 140) })
    rv.add(hero, 1)
    local logo = makeLogo(hero, 62, true, true)
    logo.Position = off(37, 47)
    Label(hero, { Position = off(168, 20), Size = off(500, 30), Text = "Eta готова", TextSize = 22, Font = FONT_B })
    Label(hero, {
        Position = off(168, 52), Size = off(640, 40), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        Text = "ВХ, аимбот, АвтоФарм и твики для Oxide: Survival Island. Быстрые переключатели ниже и на быстром шаре поверх игры.",
        TextSize = 12.5, TextColor3 = C.txt2,
    })
    local keyTail = string.sub(UI.keyText or "Okek", -4)
    local defs = {
        { "В игре", C.green }, { "Нет конфига", rgb(120, 122, 152) },
        { string.format(T("Ключ ···%s"), keyTail), rgb(110, 202, 240) }, { "Лицензия активна", C.green }, { string.format(T("Аптайм %s"), "00:00"), rgb(178, 140, 250) },
    }
    local cx = 168
    for i, d in ipairs(defs) do
        local _, lb, w = InfoChip(hero, cx, 97, d[1], d[2])
        cx = cx + w + 8
        if i == 5 then UI.uptimeLabel = lb end
    end

    local statusG = Group(s, { Name = "StatusGroup", Position = off(0, 232), Size = off(PAGE_W, 140) })
    rv.add(statusG, 1)
    local c = newColumn(statusG, 40, 0, 765)
    c:header("Статус", "pulse")
    local cw = (765 - 21) / 3
    local y = c.y + 2
    local _, v1 = StatCard(statusG, 40, y, cw, 95, "eye", "В поле зрения")
    v1.Text = "—"
    local card2, v2 = StatCard(statusG, 40 + cw + 10.5, y, cw, 95, "gauge", "Частота кадров")
    v2.Text = "59"
    UI.fpsLabel = v2
    UI.spark = Sparkline(card2, 84, 46, cw - 84 - 16, 38)
    local _, v3 = StatCard(statusG, 40 + (cw + 10.5) * 2, y, cw, 95, "layers", "Включено")
    local function updateCount() v3.Text = countOn() .. " / 10" end
    for _, k in ipairs(QUICK_KEYS) do bindState(k, function() updateCount() end) end

    local tilesG = Group(s, { Name = "TilesGroup", Position = off(0, 392), Size = off(PAGE_W, 520) })
    rv.add(tilesG, 1)
    local c2 = newColumn(tilesG, 40, 0, 765)
    c2:header("Быстрые переключатели", "layers")
    local ty = c2.y + 4
    local tiles = {
        { "esp", "ВХ", "eye" }, { "aim", "Аимбот", "cross" }, { "silent", "Силент-аим", "wand" }, { "fastreload", "Быстрая перезарядка", "clock" },
        { "autofarm", "АвтоФарм", "tree" }, { "freecam", "Свободная камера", "camera" }, { "thirdperson", "Вид от 3-го лица", "arrow" }, { "ownmodel", "Своя модель", "cube" },
        { "fpsunlock", "Снять лимит FPS", "pulse" }, { "island", "Островок статуса", "info" },
    }
    local tw_ = (765 - 3 * 14.5) / 4
    for i, t in ipairs(tiles) do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        Tile(tilesG, 40 + col * (tw_ + 14.5), ty + row * 111, tw_, 103, t[1], t[2], t[3])
    end
    local by = ty + 3 * 111 + 6
    MakeButton(tilesG, 40, by, 765, 46, "Настроить", "pencil", "ghost", function() UI.toast("Режим настройки плиток", "pencil") end)
    local c3 = newColumn(tilesG, 40, by + 60, 765)
    c3:toggle("ballvisible", "Быстрый шар", "Стеклянный шар поверх игры с этими переключателями; перетащи его к любому краю", { sep = false })
    tilesG.Size = off(PAGE_W, c3.y + 6)
    page.setHeight(392 + c3.y + 30)
end

----------------------------------------------------------------------
-- ФУНКЦИИ
----------------------------------------------------------------------
Builders.functions = function(page)
    local s = page.scroller
    titleBlock(s, "Функции", "Бой, камера и фарм", page.rv)
    local L = newColumn(s, LX, 99, COLW, page.rv, 1)
    local R = newColumn(s, RX, 37, COLW, page.rv, 2)

    L:header("Бой", "cross")
    L:toggle("nospread", "Без разброса", "Каждый выстрел идёт туда, куда указывает перекрестие")
    L:toggle("norecoil", "Без отдачи", "Камера не дёргается при стрельбе")
    L:toggle("fastreload", "Быстрая перезарядка", "Перезарядка заканчивается почти мгновенно")
    L:toggle("fastfire", "Быстрая стрельба", "Стрельба быстрее, чем позволяет оружие")
    L:slider("firerate", "Скорострельность", nil, { min = 1, max = 5, step = 0.5, fmt = function(v) return "×" .. string.format("%.1f", v) end }, { dep = "fastfire" })

    L:header("АвтоФарм", "tree", nil, 18)
    L:toggle("autofarm", "АвтоФарм", "Находит выбранный ресурс, поворачивается к нему и добывает; держи нужный инструмент")
    L:segment("Ресурс", { "Дерево", "Металл", "Сера", "Камень" }, 1, function(i) State.farmres = i end, { dep = "autofarm" })
    L:segment("Другое", { "Подбираемое", "Поленница" }, nil, function(i) State.farmother = i end, { dep = "autofarm" })
    L:toggle("gotoit", "Идти к нему", "Идёт к ближайшему; выкл.: добывать только то, что в зоне досягаемости", { dep = "autofarm" })
    L:slider("farmrate", "Добывать каждые", nil, { min = 0.2, max = 2, step = 0.1, fmt = fmtN(" с", 1) }, { dep = "autofarm" })

    L:header("Автоподбор", "backpack", nil, 18)
    L:toggle("autopickup", "Автоподбор", "Подбирает всё, что лежит в зоне подбора игры, пока ты идёшь мимо")
    L:segment("Что", { "Всё", "Ресурсы", "Выброшенное" }, 1, function(i) State.pickwhat = i end, { dep = "autopickup" })

    L:header("Частота кадров", "pulse", nil, 18)
    L:toggle("fpsunlock", "Снять лимит кадров", "Убирает ограничение частоты кадров игры")
    L:slider("targetfps", "Целевой FPS", nil, { min = 30, max = 144, step = 1, fmt = fmtN(" FPS") }, { dep = "fpsunlock" })
    L:toggle("lowgfx", "Облегчённая графика", "Рисует игру с меньшей нагрузкой; после выключения всё возвращается")
    L:slider("res", "Разрешение", "От разрешения экрана; не выше игрового", { min = 30, max = 100, step = 1, fmt = fmtN("%") }, { dep = "lowgfx" })
    L:slider("lod", "Детализация моделей", "Ниже: здания, камни и деревья упрощаются ближе к вам", { min = 25, max = 100, step = 1, fmt = fmtN("%") }, { dep = "lowgfx" })
    L:toggle("simple", "Простейшие модели", "Всё на самом низком уровне детализации, даже вблизи", { dep = "lowgfx" })
    L:slider("grass", "Трава", "Дальность прорисовки травы; 0 — без травы", { min = 0, max = 100, step = 1, fmt = fmtN("%") }, { dep = "lowgfx" })
    L:toggle("noshadow", "Без теней", "Тени не отрисовываются", { dep = "lowgfx" })
    L:toggle("nofx", "Без экранных эффектов", "Постобработка, сглаживание и HDR выключены", { dep = "lowgfx", sep = false })

    R:header("Камера", "eye")
    R:toggle("customfov", "Свой FOV")
    R:slider("fov", "Угол обзора", nil, { min = 60, max = 130, step = 1, fmt = fmtN("°") }, { dep = "customfov" })
    R:toggle("freecam", "Свободная камера", "Отсоединяет камеру и позволяет летать")
    R:slider("freecamspeed", "Скорость", nil, { min = 1, max = 50, step = 0.5, fmt = fmtN(" м/с", 1) }, { dep = "freecam" })
    R:toggle("thirdperson", "Вид от 3-го лица", "Вид на себя сзади; выстрелы по-прежнему вылетают из головы")
    R:slider("tpdist", "Дистанция", nil, { min = 1, max = 8, step = 0.5, fmt = fmtN(" м", 1) })
    R:slider("tpangle", "Угол", nil, { min = 0, max = 360, step = 1, fmt = fmtN("°") })
    R:button("Лицом ко мне", nil, "ghost", function() UI.toast("Камера повёрнута к тебе лицом", "eye") end)
    R:toggle("ownmodel", "Своя модель", "Рисует VRM-модель вместо тела: см. страницу Модели", { dep = "modelReady" })
    R:toggle("timeofday", "Время суток", "Задаёт игровое время (день или ночь)")
    R:slider("hour", "Час", nil, { min = 0, max = 24, step = 0.5, fmt = fmtN(" ч", 1) }, { dep = "timeofday" })
    R:toggle("clearview", "Чистый обзор", "Без тумана — ни в воздухе, ни под водой — и без инея и радиации на экране")
    R:header("Полезно знать", "info", nil, 16)
    R:note("АвтоФарм добывает тем, что у тебя в руках: топором деревья, киркой руду.", 12.5, C.txt2, 14)
    R:note("После выключения время суток и частота кадров возвращаются к игровым.", 12.5, C.txt2, 6)

    page.setHeight(math.max(L.y, R.y) + 28)
end

----------------------------------------------------------------------
-- ВИЗУАЛ
----------------------------------------------------------------------
local WORLD = {
    { name = "База", icon = "cabinet", color = rgb(118, 176, 236), items = {
        { "Шкаф", "cabinet" }, { "Дверь", "door" }, { "Турель", "turret" }, { "Хранилище", "box" }, { "Большое хранилище", "box" },
        { "Спальный мешок", "bed" }, { "Печь", "flame" }, { "Верстак", "hammer" }, { "Ружейная ловушка", "turret" }, { "Переработчик", "recycle" } } },
    { name = "Животные", icon = "paw", color = rgb(240, 144, 94), items = {
        { "Медведь", "paw" }, { "Олень", "paw" }, { "Кабан", "paw" }, { "Кролик", "paw" }, { "Курица", "paw" }, { "Крыса", "paw" } } },
    { name = "Ресурсы", icon = "crystal", items = {
        { "Сера", "crystal", rgb(236, 206, 76) }, { "Камень", "rock", rgb(176, 182, 198) }, { "Дерево", "tree", rgb(112, 214, 124) },
        { "Металл", "crystal", rgb(168, 184, 210) }, { "Тыква", "pumpkin", rgb(244, 150, 60) }, { "Подбираемое", "leaf", rgb(112, 218, 124) },
        { "Лёд", "crystal", rgb(126, 196, 236) }, { "Поленница", "tree", rgb(214, 152, 92) } } },
    { name = "Лут", icon = "box", items = {
        { "Рюкзак", "backpack", rgb(230, 194, 92) }, { "Бочка", "barrel", rgb(240, 104, 104) }, { "Ящик", "box", rgb(232, 194, 92) },
        { "Ящик на авто", "car", rgb(238, 204, 84) }, { "Аирдроп", "parachute", rgb(240, 112, 176) }, { "Ящик на шаре", "pin", rgb(240, 112, 176) },
        { "Выброшенный предмет", "cube", rgb(206, 196, 124) } } },
    { name = "Транспорт", icon = "car", color = rgb(164, 144, 244), items = { { "Транспорт", "car" } } },
}

Builders.visual = function(page)
    local s = page.scroller
    titleBlock(s, "Визуал", "ВХ для игроков, ботов и ресурсов мира", page.rv)
    local L = newColumn(s, LX, 99, COLW, page.rv, 1)
    local R = newColumn(s, RX, 37, COLW, page.rv, 2)

    L:header("Предпросмотр", "eye", "Демо-данные")
    local pgE = Group(L.holder, { Name = "PreviewG", Position = off(0, L.y), Size = off(PREV_W, PREV_H) })
    page.rv.add(pgE, 1)
    buildEspPreview(pgE, 0, 0)
    L.y = L.y + PREV_H + 18

    L:header("Стили видимости", "venn", "Игроки на виду и за укрытием")
    L:segment("Стиль для", { "На виду", "За укрытием" }, 2)
    L:toggle("teamcolor", "Цвет команды", "Выкл.: цвет ниже для всех команд")
    L:slider("vopacity", "Непрозрачность", nil, { min = 0, max = 100, step = 1, fmt = fmtN("%") })
    L:slider("vthick", "Толщина линий", nil, { min = 0.5, max = 3, step = 0.1, fmt = fmtN("x", 1) })
    L:slider("vglow", "Свечение", nil, { min = 0, max = 1.5, step = 0.1, fmt = fmtN("x", 1) })
    L:segment("Линия", { "Сплошная", "Пунктирная", "Точечная" }, 2)
    L:toggle("darkoutline", "Тёмная обводка", "Тёмная линия под каждым штрихом, чтобы её было видно на светлом фоне")
    L:button("Сбросить стиль", nil, "ghost", function() UI.toast("Стиль сброшен", "undo") end)

    L:header("Цвета команд", "venn", nil, 16)
    L:segment("Команда", { "Союзники", "Боты", "Враги" }, 3)
    do
        local r = L:row(78)
        Label(r, { Position = off(0, 4), Size = off(COLW, 22), Text = "Цвет", TextSize = 16 })
        local cols = {
            { rgb(236, 74, 92), rgb(196, 38, 62) }, { rgb(246, 156, 62), rgb(214, 108, 28) }, { rgb(246, 226, 76), rgb(206, 180, 30) },
            { rgb(104, 226, 90), rgb(52, 176, 52) }, { rgb(96, 226, 224), rgb(46, 176, 190) }, { rgb(86, 140, 240), rgb(44, 92, 200) },
            { rgb(178, 82, 232), rgb(132, 48, 190) }, { rgb(240, 240, 240), rgb(176, 176, 190) },
        }
        local step = (COLW - 26) / 7
        local sw = {}
        for i, cc in ipairs(cols) do
            sw[i] = Swatch(r, (i - 1) * step, 38, 26, cc[1], cc[2], State.swatch == i, function()
                State.swatch = i
                for j, o in ipairs(sw) do o.set(j == i) end
            end, false)
        end
    end
    L:slider("hue", "Оттенок", nil, { min = 0, max = 360, step = 1, fmt = fmtN("°") })
    L:slider("sat", "Насыщенность", nil, { min = 0, max = 100, step = 1, fmt = fmtN("%") })
    L:slider("bri", "Яркость", nil, { min = 0, max = 100, step = 1, fmt = fmtN("%") })
    L:button("Сбросить цвет", nil, "ghost", function() UI.toast("Цвет сброшен", "undo") end)

    L:header("Мир", "layers", nil, 16)
    local groupChips = {}
    local catSpecs = {}
    for _, g in ipairs(WORLD) do
        catSpecs[#catSpecs + 1] = {
            text = g.name, icon = g.icon, color = rgb(168, 170, 200), on = false,
            onClick = function()
                local list = groupChips[g.name]
                if not list then return end
                local any = false
                for _, ch in ipairs(list) do if ch.on then any = true end end
                for _, ch in ipairs(list) do ch.set(not any, false) end
                -- сама плашка категории остаётся "нейтральной"
            end,
        }
    end
    local _, catList = L:chips("Категории", catSpecs)
    for _, g in ipairs(WORLD) do
        local specs = {}
        for _, it in ipairs(g.items) do
            specs[#specs + 1] = { text = it[1], icon = it[2], color = it[3] or g.color, on = true }
        end
        local _, list = L:chips(g.name, specs)
        groupChips[g.name] = list
    end
    L:segment("Подписи", { "Иконка", "Имя", "Полный" }, 3)
    L:slider("worlddist", "Дальность", nil, { min = 50, max = 400, step = 10, fmt = fmtN(" м") })
    L:toggle("hidelooted", "Скрывать обчищенные", "Не показывать вскрытые аирдропы и опустошённые ящики", { sep = false })

    R:header("ВХ", "target")
    R:toggle("esp", "Включено", "Главный выключатель для игроков и мира")
    R:toggle("radar", "Радар", "По направлению взгляда, в углу экрана")
    R:toggle("radaranimals", "Животные и лут на радаре", "Ещё животные, лут и транспорт, не только люди")
    R:toggle("island", "Островок статуса", "Кто рядом, вверху экрана; сообщает о новых врагах")
    R:toggle("islandalert", "Тревога островка", "Краснеет и указывает на врага в пределах этой дистанции")
    R:slider("alertdist", "Дистанция тревоги", nil, { min = 10, max = 150, step = 5, fmt = fmtN(" м") })
    R:toggle("overlay", "Рисовать поверх игры", "Живой ВХ поверх игры")

    R:header("Игроки", "cross", nil, 16)
    R:chips("Показывать", {
        { text = "Союзники", icon = "shield", color = rgb(170, 174, 204), on = false },
        { text = "Боты", icon = "robot", color = rgb(246, 190, 84), on = true },
        { text = "Враги", icon = "cross", color = rgb(255, 100, 140), on = true },
    }, { h = 34 })
    R:toggle("offline", "Игроки не в сети", "Тела вышедших из игры игроков, отмечены луной")
    R:toggle("box", "Бокс")
    R:segment("Стиль бокса", { "Углы", "Контур", "Стекло" }, 3)
    R:toggle("skeleton", "Скелет")
    R:toggle("openparts", "Открытые части", "Подсвечивает части тела вне укрытия")
    R:toggle("snaplines", "Снаплайны")
    R:segment("Начало снаплайнов", { "Сверху", "Центр", "Снизу" }, 3)
    R:toggle("health", "Полоска здоровья")
    R:toggle("nick", "Ники")
    R:toggle("dist", "Дистанция")
    R:toggle("weapon", "Оружие в руках", "Иконка и название оружия в руках у каждого игрока")
    R:toggle("armor", "Броня", "Голова, грудь, ноги и стопы, цвет по материалу")
    R:toggle("arrows", "Стрелки за экраном", "Указывают на игроков вне поля зрения")
    R:slider("espdist", "Дальность", nil, { min = 50, max = 500, step = 10, fmt = fmtN(" м") }, { sep = false })

    page.setHeight(math.max(L.y, R.y) + 28)
end

----------------------------------------------------------------------
-- АИМ
----------------------------------------------------------------------
Builders.aim = function(page)
    local s = page.scroller
    titleBlock(s, "Аим", "Аимбот: цели, точки прицеливания и стрельба", page.rv)
    local L = newColumn(s, LX, 99, COLW, page.rv, 1)
    local R = newColumn(s, RX, 37, COLW, page.rv, 2)

    L:header("Предпросмотр", "target", "Демо-данные")
    local pgA = Group(L.holder, { Name = "PreviewG", Position = off(0, L.y), Size = off(PREV_W, PREV_H) })
    page.rv.add(pgA, 1)
    buildAimPreview(pgA, 0, 0)
    L.y = L.y + PREV_H + 18

    L:header("Кости", "cube")
    local bones = {}
    for _, n in ipairs({ "Голова", "Шея", "Грудь", "Таз", "Руки", "Кисти", "Ноги", "Стопы" }) do
        bones[#bones + 1] = { text = n, icon = "dotring", color = rgb(170, 162, 252), on = true }
    end
    L:chips("Целиться в", bones)
    L:segment("Выбор", { "Ближайшая", "Приоритет" }, 2)
    L:note("Ближайшая берёт отмеченную точку, ближайшую к перекрестию. Приоритет берёт первую отмеченную группу, начиная с головы, у которой есть точка внутри круга.", 12.5, C.txt2, 12)

    L:header("Отображение", "eye", nil, 8)
    L:toggle("fovcircle", "Круг FOV")
    L:toggle("bonepoints", "Точки костей", "Каждая отмеченная точка на каждой допустимой цели")
    L:toggle("aimline", "Линия прицела")
    L:toggle("targetpanel", "Панель цели", "Кто, как далеко, какая кость и что делает", { sep = false })

    R:header("Аим", "gauge")
    R:toggle("aim", "Включено")
    R:toggle("silent", "Силент-аим", "Выстрелы летят в цель; камера не двигается")
    R:segment("Активация", { "Всегда", "Стрельба", "Целясь" }, 1)
    R:slider("aimfov", "Угол обзора", nil, { min = 5, max = 60, step = 1, fmt = fmtN("°") })
    R:slider("smooth", "Плавность", "Только ассист: насколько плавно поворачивается камера", { min = 1, max = 10, step = 0.1, fmt = fmtN("", 1) }, { dep = "silent", inv = true })
    R:slider("hitchance", "Шанс попадания", "Только силент: остальные выстрелы мажут намеренно", { min = 0, max = 100, step = 1, fmt = fmtN("%") })
    R:segment("Приоритет", { "Перекрестие", "Дистанция", "Здоровье" }, 1)
    R:toggle("lock", "Захват цели", "Держится за цель, пока она не выйдет из круга")
    R:toggle("lead", "Упреждение", "Упреждает движущиеся цели; падение снаряда учитывается всегда, для любого оружия")

    R:header("Цели", "shield", nil, 16)
    R:toggle("ignallies", "Игнорировать союзников")
    R:toggle("ignbots", "Игнорировать ботов")
    R:toggle("ignoffline", "Игнорировать игроков не в сети", "Пропускает тела вышедших из игры игроков")
    R:toggle("igncover", "Игнорировать за укрытием", "Целится только в части тела в прямой видимости")
    R:slider("maxdist", "Макс. дистанция", nil, { min = 50, max = 400, step = 10, fmt = fmtN(" м") })

    R:header("Автострельба", "bolt", nil, 16)
    R:toggle("autoshoot", "Автострельба", "Стреляет, пока выстрел попадает в цель")
    R:slider("reaction", "Реакция", "Ожидание после захвата цели перед первым выстрелом", { min = 0, max = 500, step = 10, fmt = fmtN(" мс") })
    R:slider("autorate", "Скорострельность", nil, { min = 1, max = 20, step = 1, fmt = fmtN(" / с") })
    R:slider("recoilctl", "Контроль отдачи", nil, { min = 0, max = 100, step = 1, fmt = fmtN("%") }, { sep = false })

    page.setHeight(math.max(L.y, R.y) + 28)
end

----------------------------------------------------------------------
-- МОДЕЛИ
----------------------------------------------------------------------
Builders.models = function(page)
    local s = page.scroller
    titleBlock(s, "Модели", "VRM-модели для вида от третьего лица -- видишь только ты", page.rv)
    local y = 81

    -- Надето
    local card = Card(s, y, 10, page.rv)
    local c = newColumn(card, 18, 16, 766)
    c:header("Надето", "sparkle")
    local av = Frame(c.holder, { Position = off(0, c.y), Size = off(118, 118) })
    Corner(av, 14)
    Grad(av, rgb(122, 110, 192), rgb(168, 140, 216), 135)
    Label(av, { Size = sc(1, 1), Text = "?", TextSize = 44, Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Center })
    Label(c.holder, { Position = off(136, c.y + 6), Size = off(400, 28), Text = "Нет модели", TextSize = 20, Font = FONT_B })
    local sub = Label(c.holder, { Position = off(136, c.y + 92), Size = off(300, 18), Text = "Выкл", TextSize = 12, TextColor3 = C.txt4 })
    bindState("ownmodel", function(v) sub.Text = T(v and "Вкл" or "Выкл") end)
    c.y = c.y + 132
    c:toggle("ownmodel", "Своя модель", "Вид от 3-го лица рисует выбранную модель вместо тела")
    local r = c:row(56, { sep = false })
    MakeButton(r, 0, 6, 377, 44, "Предпросмотр", "eye", "dim", function() UI.toast("Сначала выбери модель", "info") end)
    MakeButton(r, 389, 6, 377, 44, "Перезагрузить", "undo", "ghost", function() UI.toast("Список моделей обновлён", "undo") end)
    c:note("Предпросмотр поворачивает камеру к тебе лицом и вокруг тебя; коснись глазика, чтобы остановить.", 12, C.txt2, 8)
    card.Size = off(802, c.y + 8)
    y = y + c.y + 8 + 16

    -- Вид
    card = Card(s, y, 10, page.rv)
    c = newColumn(card, 18, 16, 766)
    c:header("Вид", "wand")
    local lightHints = {
        "Освещается так же, как всё остальное в игре",
        "Освещается сценой, матовый, с собственными цветами модели",
        "Цвета модели как нарисованы, без освещения и теней",
    }
    local hintLabel
    local r1 = c:row(104, { sep = false })
    local selL = Persist.seg["Освещение"] or 2
    Label(r1, { Position = off(0, 4), Size = off(766, 22), Text = "Освещение", TextSize = 16 })
    Segmented(r1, 0, 32, 766, { "Игра", "Свет", "Плоский" }, selL, function(i)
        Persist.seg["Освещение"] = i
        hintLabel.Text = T(lightHints[i])
    end)
    hintLabel = Label(r1, { Position = off(0, 78), Size = off(766, 18), Text = lightHints[selL], TextSize = 12, TextColor3 = C.txt3, Font = FONT_R })
    c:segment("Выражение", { "Спокойно", "Радость", "Злость", "Грусть", "Веселье", "Вау" }, 1)
    c:toggle("blink", "Моргание", "Время от времени, как у человека")
    c:toggle("physics", "Физика волос и ткани", "Волосы, юбка и ленты качаются так, как задано в модели", { sep = false })
    card.Size = off(802, c.y + 8)
    y = y + c.y + 8 + 16

    -- Импорт
    card = Card(s, y, 10, page.rv)
    c = newColumn(card, 18, 16, 766)
    c:header("Импорт", "download")
    local ri = c:row(56, { sep = false })
    MakeButton(ri, 0, 6, 766, 44, "Импорт", "download", "primary", function() UI.toast("Выбери файл .vrm", "download") end)
    c:note("Выберите «Импорт», чтобы выбрать файл .vrm, или скопируйте его в папку моделей Eta.", 12, C.txt2, 8)
    local rr = c:row(56, { sep = false })
    MakeButton(rr, 0, 6, 766, 44, "Обновить", "undo", "ghost", function() UI.toast("Список моделей обновлён", "undo") end)
    card.Size = off(802, c.y + 8)
    y = y + c.y + 8 + 16

    -- Библиотека
    card = Card(s, y, 10, page.rv)
    c = newColumn(card, 18, 16, 766)
    c:header("Библиотека (0)", "cube")
    c:note("Моделей пока нет: импортируй или положи файлы .vrm в eta/model/", 12.5, C.txt2, 8)
    card.Size = off(802, c.y + 8)
    y = y + c.y + 8 + 16
    page.setHeight(y + 4)
end

----------------------------------------------------------------------
-- КОНФИГИ
----------------------------------------------------------------------
local function firstChar(str)
    local e = utf8.offset(str, 2)
    return string.upper(string.sub(str, 1, (e or (#str + 1)) - 1))
end

local CFG = {
    rows = { { name = "My setup", meta = "2 ч назад  ·  изменений: 21", star = false } },
    title = "Несохранённая настройка", meta = "Изменений от стандартных: 1  ·  ещё не в конфиге",
    state = "Не сохранён", green = false, counter = 1,
}

Builders.configs = function(page)
    local s = page.scroller
    titleBlock(s, "Конфиги", "Сохранение, переключение и обмен целыми наборами настроек", page.rv)
    local cards = {}
    local function relayout(animate)
        local y = 81
        for _, cd in ipairs(cards) do
            local sz, ps = off(802, cd.h), off(21, y)
            if animate then
                tw(cd.frame, 0.35, { Size = sz, Position = ps })
            else
                cd.frame.Size, cd.frame.Position = sz, ps
            end
            y = y + cd.h + 16
        end
        page.setHeight(y + 6)
    end
    local function addCard(h)
        local f = Card(s, 0, h, page.rv)
        local cd = { frame = f, h = h }
        cards[#cards + 1] = cd
        return cd
    end

    local function setStatus(title, meta, state, green)
        CFG.title, CFG.meta, CFG.state, CFG.green = title, meta, state, green
        UI.cfgTitle.Text = T(title)
        UI.cfgMeta.Text = T(meta)
        UI.cfgState.Text = T(state)
        tw(UI.cfgDot, 0.2, { BackgroundColor3 = green and C.green or rgb(120, 122, 152) })
    end

    -- 1. текущее состояние
    local top = addCard(184)
    do
        local f = top.frame
        local tile = Frame(f, { Position = off(18, 18), Size = off(64, 64) })
        Corner(tile, 18)
        accentGradient(tile, 135)
        Icon(tile, "plus", 24, C.dark, { Position = off(20, 20) })
        UI.cfgTitle = Label(f, { Position = off(98, 22), Size = off(480, 30), Text = CFG.title, TextSize = 22, Font = FONT_B, TextColor3 = rgb(232, 226, 255) })
        UI.cfgMeta = Label(f, { Position = off(98, 56), Size = off(480, 20), Text = CFG.meta, TextSize = 12.5, TextColor3 = C.txt3 })
        local pill = Frame(f, { AnchorPoint = V2(1, 0), Position = off(748, 24), Size = off(112, 27), BackgroundTransparency = 0.93 })
        Corner(pill, "full")
        Stroke(pill, C.white, 0.88, 1)
        UI.cfgDot = Frame(pill, { Position = off(11, 9.5), Size = off(8, 8), BackgroundColor3 = CFG.green and C.green or rgb(120, 122, 152) })
        Corner(UI.cfgDot, "full")
        UI.cfgState = Label(pill, { Position = off(25, 0), Size = off(84, 27), Text = CFG.state, TextSize = 12 })
        local bw = (766 - 21) / 3
        UI.cfgSaveNew = function() end
        MakeButton(f, 18, 108, bw, 46, "Сохранить как новый", "save", "primary", function() UI.cfgSaveNew() end)
        MakeButton(f, 18 + bw + 10.5, 108, bw, 46, "Откатить", "undo", "ghost", function() UI.toast("Изменения откатены", "undo") end)
        MakeButton(f, 18 + (bw + 10.5) * 2, 108, bw, 46, "По умолчанию", "x", "ghost", function() UI.toast("Настройки по умолчанию", "x") end)
    end

    -- 2. библиотека
    local lib = addCard(160)
    local rows = {}
    local listHolder, hintLbl, emptyLbl
    local layoutRows
    do
        local f = lib.frame
        local hdr = newColumn(f, 18, 16, 766)
        local _, hl = hdr:header("Библиотека", "folder", string.format(T("Сохранено: %d"), #CFG.rows))
        hintLbl = hl
        listHolder = Frame(f, { Name = "List", BackgroundTransparency = 1, Position = off(18, 52), Size = off(766, 10) })
        emptyLbl = Label(f, { Position = off(18, 56), Size = off(766, 24), Text = "Пока нет сохранённых конфигов", TextSize = 12.5, TextColor3 = C.txt3, Font = FONT_R })
    end

    layoutRows = function(animate)
        local y = 0
        for _, rw in ipairs(rows) do
            local ps, sz = off(0, y), off(766, rw.h)
            if animate then
                tw(rw.frame, 0.35, { Position = ps, Size = sz })
            else
                rw.frame.Position, rw.frame.Size = ps, sz
            end
            y = y + rw.h + 8
        end
        local total = (#rows > 0) and (y - 8) or 0
        listHolder.Size = off(766, total)
        emptyLbl.Visible = (#rows == 0)
        hintLbl.Text = string.format(T("Сохранено: %d"), #rows)
        lib.h = 52 + (#rows > 0 and total or 28) + 18
        relayout(animate)
    end

    local function removeRow(rw)
        for i, r in ipairs(rows) do if r == rw then table.remove(rows, i) break end end
        for i, e in ipairs(CFG.rows) do if e == rw.entry then table.remove(CFG.rows, i) break end end
        tw(rw.frame, 0.2, { BackgroundTransparency = 1 })
        task.delay(0.2, function() rw.frame:Destroy() end)
        layoutRows(true)
    end

    local addRowUI
    addRowUI = function(entry)
        local name = entry.name
        local rw = { entry = entry, expanded = false, h = 66 }
        local f = Frame(listHolder, { Name = "CfgRow", Size = off(766, 66), BackgroundTransparency = 0.96, ClipsDescendants = true })
        Corner(f, 16)
        local st = Stroke(f, C.white, 1, 1)
        rw.frame = f
        local av = Frame(f, { Position = off(12, 11), Size = off(44, 44) })
        Corner(av, 14)
        accentGradient(av, 135)
        Label(av, { Size = sc(1, 1), Text = firstChar(name), TextSize = 20, Font = FONT_B, TextColor3 = C.dark, TextXAlignment = Enum.TextXAlignment.Center })
        Label(f, { Position = off(70, 10), Size = off(500, 26), Text = name, TextSize = 17, Font = FONT_B })
        Label(f, { Position = off(70, 36), Size = off(500, 18), Text = entry.meta, TextSize = 12, TextColor3 = C.txt4 })
        local chev = Icon(f, "arrow", 14, rgb(150, 150, 182), { Position = off(738, 26), Rotation = 90 })
        local head = Button(f, { Size = off(766, 66), ZIndex = 2 })
        head.Activated:Connect(function() if UI.scrolled then return end;
            if UI.scrolled then return end
            rw.expanded = not rw.expanded
            rw.h = rw.expanded and 156 or 66
            tw(st, 0.25, { Transparency = rw.expanded and 0.86 or 1 })
            tw(f, 0.25, { BackgroundTransparency = rw.expanded and 0.93 or 0.96 })
            tw(chev, 0.3, { Rotation = rw.expanded and -90 or 90 }, Quint, Out)
            layoutRows(true)
        end)
        Frame(f, { Position = off(14, 66), Size = off(738, 1), BackgroundTransparency = 0.93 })
        local acts = {
            { "Загрузить", "check" }, { "Сохранить", "save" }, { "Переименовать", "pencil" }, { "Дублировать", "copy" },
            { "Поделиться", "share" }, { "Авто", "star" }, { "Удалить", "trash" },
        }
        local pitch = (766 - 28) / 7
        for i, a in ipairs(acts) do
            local cx = 14 + (i - 0.5) * pitch
            local circ = Frame(f, { AnchorPoint = V2(0.5, 0), Position = off(cx, 76), Size = off(43, 43), BackgroundTransparency = 0.92 })
            Corner(circ, "full")
            Stroke(circ, C.white, 0.82, 1)
            local icColor = rgb(214, 214, 238)
            if i == 1 then
                circ.BackgroundColor3 = theme.a
                circ.BackgroundTransparency = 0.45
                icColor = C.white
                onTheme(function() circ.BackgroundColor3 = theme.a end)
            elseif i == 7 then
                circ.BackgroundColor3 = rgb(255, 90, 130)
                circ.BackgroundTransparency = 0.68
                icColor = rgb(255, 150, 176)
            end
            local ic = Icon(circ, a[2], 18, entry.star and i == 6 and rgb(255, 214, 110) or icColor, { Position = off(12.5, 12.5) })
            Label(f, { AnchorPoint = V2(0.5, 0), Position = off(cx, 124), Size = off(pitch, 16), Text = a[1], TextSize = 10.5, TextColor3 = C.txt3, TextXAlignment = Enum.TextXAlignment.Center })
            local b = Button(f, { AnchorPoint = V2(0.5, 0), Position = off(cx, 72), Size = off(pitch, 66), ZIndex = 3 })
            addPress(b, circ, 0.9)
            b.Activated:Connect(function() if UI.scrolled then return end;
                if UI.scrolled then return end
                UI.pressFx(circ)
                if i == 1 then
                    UI.toast(string.format(T('Загружен "%s"'), name), "check")
                    setStatus(name, "Конфиг загружен  ·  без изменений", "Сохранён", true)
                elseif i == 2 then
                    UI.toast(string.format(T('Сохранён "%s"'), name), "save")
                elseif i == 3 then
                    UI.toast("Введи новое имя в поле «Новый конфиг»", "pencil")
                elseif i == 4 then
                    local e = { name = string.format(T("%s (копия)"), name), meta = "только что  ·  изменений: 21" }
                    table.insert(CFG.rows, e)
                    addRowUI(e)
                    layoutRows(true)
                    UI.toast("Дубликат создан", "copy")
                elseif i == 5 then
                    UI.toast("Код для обмена готов", "share")
                elseif i == 6 then
                    entry.star = not entry.star
                    setIconColor(ic, entry.star and rgb(255, 214, 110) or icColor, false)
                    UI.toast(entry.star and "Автозагрузка включена" or "Автозагрузка выключена", "star")
                else
                    UI.toast(string.format(T('Удалён "%s"'), name), "trash")
                    removeRow(rw)
                end
            end)
        end
        rows[#rows + 1] = rw
        return rw
    end

    -- 3. новый конфиг
    local newCard = addCard(220)
    local nameBox
    do
        local f = newCard.frame
        local c = newColumn(f, 18, 16, 766)
        c:header("Новый конфиг", "plus")
        local _, box = Input(f, 18, c.y, 766, 56, "pencil", "Название (необязательно)", 17)
        nameBox = box
        c.y = c.y + 56 + 18
        local bw = (766 - 12) / 2
        local function saveCurrent()
            local nm = trim(nameBox.Text)
            if nm == "" then
                CFG.counter = CFG.counter + 1
                nm = string.format(T("Конфиг %d"), CFG.counter)
            end
            nameBox.Text = ""
            local e = { name = nm, meta = "только что  ·  изменений: 21" }
            table.insert(CFG.rows, e)
            addRowUI(e)
            layoutRows(true)
            UI.toast(string.format(T('Сохранён "%s"'), nm), "save")
            setStatus(nm, "Сохранено  ·  без изменений", "Сохранён", true)
        end
        UI.cfgSaveNew = saveCurrent
        MakeButton(f, 18, c.y, bw, 48, "Сохранить текущие", "save", "primary", saveCurrent)
        MakeButton(f, 18 + bw + 12, c.y, bw, 48, "Пустой", "plus", "ghost", function()
            local nm = trim(nameBox.Text)
            if nm == "" then
                CFG.counter = CFG.counter + 1
                nm = string.format(T("Пустой %d"), CFG.counter)
            end
            nameBox.Text = ""
            local e = { name = nm, meta = "только что  ·  изменений: 0" }
            table.insert(CFG.rows, e)
            addRowUI(e)
            layoutRows(true)
            UI.toast(string.format(T('Создан "%s"'), nm), "plus")
        end)
        c.y = c.y + 48 + 16
        c:note("Конфиг хранит все настройки Функций, Визуала и Аима. Внешний вид меню остаётся твоим и не передаётся.", 12, C.txt2, 6)
        newCard.h = c.y + 10
    end

    -- 4. импорт
    local imp = addCard(130)
    do
        local f = imp.frame
        local c = newColumn(f, 18, 16, 766)
        c:header("Импорт", "download")
        local _, box = Input(f, 18, c.y, 700, 56, "share", "Вставь код для обмена", 17)
        local cb = Frame(f, { Position = off(18 + 714, c.y + 4), Size = off(48, 48), BackgroundTransparency = 0.6 })
        Corner(cb, "full")
        cb.BackgroundColor3 = theme.a
        onTheme(function() cb.BackgroundColor3 = theme.a end)
        Stroke(cb, C.white, 0.8, 1)
        Icon(cb, "clipboard", 20, rgb(226, 220, 255), { Position = off(14, 14) })
        local b = Button(cb, { ZIndex = 3 })
        addPress(b, cb, 0.92)
        b.Activated:Connect(function() if UI.scrolled then return end;
            if UI.scrolled then return end
            UI.pressFx(cb)
            local txt
            if type(getclipboard) == "function" then
                local ok, r = pcall(getclipboard)
                if ok then txt = r end
            end
            if txt and txt ~= "" then
                box.Text = txt
                UI.toast("Вставлено", "clipboard")
            else
                UI.toast("Буфер обмена пуст", "clipboard")
            end
        end)
        imp.h = c.y + 56 + 22
    end

    for _, e in ipairs(CFG.rows) do addRowUI(e) end
    layoutRows(false)
end

----------------------------------------------------------------------
-- НАСТРОЙКИ
----------------------------------------------------------------------
Builders.settings = function(page)
    local s = page.scroller
    titleBlock(s, "Настройки", "Внешний вид меню и конфиги", page.rv)
    local L = newColumn(s, LX, 99, COLW, page.rv, 1)
    local R = newColumn(s, RX, 37, COLW, page.rv, 2)

    L:header("Внешний вид", "venn")
    do
        local r = L:row(92)
        Label(r, { Position = off(0, 4), Size = off(200, 22), Text = "Тема", TextSize = 16 })
        local nameLbl = Label(r, { AnchorPoint = V2(1, 0), Position = off(COLW, 6), Size = off(160, 20), Text = THEMES[theme.index].name, TextSize = 13, TextColor3 = C.txt3, TextXAlignment = Enum.TextXAlignment.Right })
        local sw = {}
        for i, t in ipairs(THEMES) do
            sw[i] = Swatch(r, (i - 1) * 49 + 4, 40, 36, t.a, t.b, i == theme.index, function()
                for j, o in ipairs(sw) do o.set(j == i) end
                applyTheme(i)
                nameLbl.Text = T(THEMES[i].name)
                UI.toast(string.format(T("Тема: %s"), T(THEMES[i].name)), "sparkle")
            end, true)
        end
    end
    L:slider("panelopacity", "Непрозрачность панели", "Чем меньше, тем лучше видна игра за меню", { min = 40, max = 100, step = 1, fmt = fmtN("%"), onChange = function(v) UI.setOpacity(v) end })
    local _, scaleSlider = L:slider("uiscale", "Масштаб интерфейса", nil, { min = 0.6, max = 1.5, step = 0.05, fmt = fmtN("x", 2), onChange = function(v) UI.setUserScale(v, true) end })
    UI.scaleSliderObj = scaleSlider
    L:segment("Анимация", { "Спокойно", "Обычно", "Живо" }, 2, function(i)
        Anim.mode = i
        Anim.speed = (i == 1) and 1.5 or ((i == 3) and 0.75 or 1)
    end, { sep = false })

    R:header("Язык", "grid")
    do
        local r = R:row(204, { sep = false })
        Label(r, { Position = off(0, 4), Size = off(COLW, 22), Text = "Язык", TextSize = 16 })
        local langs = { { "Система", "English", "Русский" }, { "Türkçe", "العربية", "فارسی" }, { "繁體中文", "日本語", "???" } }
        local segs = {}
        local rowOf = math.floor((State.lang - 1) / 3) + 1
        local colOf = (State.lang - 1) % 3 + 1
        for i = 1, 3 do
            segs[i] = Segmented(r, 0, 32 + (i - 1) * 50, COLW, langs[i], (i == rowOf) and colOf or nil, function(idx)
                local pick = (i - 1) * 3 + idx
                if pick == 9 then
                    UI.toast("Скоро появятся новые языки", "sparkle")
                    for j = 1, 3 do segs[j].set(nil, false) end
                    local rr = math.floor((State.lang - 1) / 3) + 1
                    segs[rr].set((State.lang - 1) % 3 + 1, false)
                    return
                end
                for j = 1, 3 do
                    if j ~= i then segs[j].set(nil, false) end
                end
                State.lang = pick
                task.delay(0.18, function() UI.setLanguage(pick) end)
            end)
        end
    end
    R:header("Частицы", "sparkle", nil, 14)
    R:toggle("particles", "Фоновые частицы", "Парящие частицы вокруг меню")
    R:slider("density", "Плотность частиц", nil, { min = 20, max = 100, step = 1, fmt = fmtN("%"), onChange = function() UI.refreshParticles() end }, { dep = "particles" })
    R:toggle("trail", "След от касаний", "Частицы там, где ты касаешься меню")
    R:toggle("pressfx", "Эффект нажатия", "Частицы при нажатии на переключатель или кнопку")
    R:header("О программе", "info", nil, 14)
    do
        local r = R:row(86, { sep = false })
        makeLogo(r, 50, true, true).Position = off(0, 14)
        Label(r, { Position = off(100, 10), Size = off(250, 26), Text = "Eta", TextSize = 20, Font = FONT_B })
        Label(r, { Position = off(100, 38), Size = off(257, 40), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "ВХ, аимбот, АвтоФарм и твики для Oxide: Survival Island.", TextSize = 12.5, TextColor3 = C.txt2 })
    end
    page.setHeight(math.max(L.y, R.y) + 28)
end

end

local function BuildShell()
-- локальные копии коротких помощников (чтобы функция не захватывала слишком много внешних переменных)
local Quint, Quad, Back = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local Out, In, InOut = Enum.EasingDirection.Out, Enum.EasingDirection.In, Enum.EasingDirection.InOut
local V2 = Vector2.new
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local function off(x, y) return UDim2.fromOffset(x, y) end
local function sc(x, y) return UDim2.fromScale(x, y) end
local WIN_W, WIN_H, SIDE_W, HEAD_H, PAGE_W, PAGE_H, CARD_W, CARD_H = 1020, 620, 173, 80, 847, 540, 495, 442

----------------------------------------------------------------------
-- тосты (плашка сверху по центру)
----------------------------------------------------------------------
local toastHost = Frame(gui, { Name = "Toasts", BackgroundTransparency = 1, Size = sc(1, 1), ZIndex = 60 })
local curToast

function UI.toast(text, iconName)
    text = T(text)
    if curToast then pcall(function() curToast:Destroy() end) end
    local w = measure(text, 15, FONT_M) + 84
    local pill = Frame(toastHost, {
        Name = "Toast", AnchorPoint = V2(0.5, 0), Position = UDim2.new(0.5, 0, -0.14, 0),
        Size = off(w, 46), BackgroundColor3 = rgb(15, 14, 32), BackgroundTransparency = 0.1,
    })
    curToast = pill
    Corner(pill, "full")
    Stroke(pill, C.white, 0.86, 1)
    local us = Instance.new("UIScale")
    us.Scale = baseScale()
    us.Parent = pill
    local ic = Frame(pill, { Position = off(9, 9), Size = off(28, 28), BackgroundColor3 = rgb(150, 140, 235), BackgroundTransparency = 0.68 })
    Corner(ic, "full")
    Icon(ic, iconName or "check", 14, rgb(214, 206, 255), { Position = off(7, 7) })
    Label(pill, { Position = off(48, 0), Size = off(w - 60, 44), Text = text, TextSize = 15 })
    local bar = Frame(pill, { Position = off(48, 40), Size = off(w - 70, 2) })
    Corner(bar, "full")
    accentGradient(bar, 0)
    tw(pill, 0.5, { Position = UDim2.new(0.5, 0, 0.035, 0) }, Back, Out)
    TweenService:Create(bar, TweenInfo.new(1.7, Enum.EasingStyle.Linear), { Size = off(0, 2) }):Play()
    task.delay(1.85, function()
        if curToast == pill then
            tw(pill, 0.35, { Position = UDim2.new(0.5, 0, -0.14, 0) }, Quint, In)
            task.delay(0.4, function()
                pcall(function() pill:Destroy() end)
                if curToast == pill then curToast = nil end
            end)
        end
    end)
end

----------------------------------------------------------------------
-- масштаб
----------------------------------------------------------------------
local userScale = 1
local function curScale() return baseScale() * userScale end

local winOpen, cardOpen, authed = false, false, false

-- пока меню открыто, прячем верхнюю панель Roblox (чтобы она не лезла под окно)
local StarterGui = game:GetService("StarterGui")
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
do
    local prevDestroy = Eta.Destroy
    function Eta.Destroy()
        winOpen, cardOpen = false, false
        UI.syncTopbar()
        prevDestroy()
    end
end

----------------------------------------------------------------------
-- шар (orb)
----------------------------------------------------------------------
local ORB = 74
local orb = Frame(gui, {
    Name = "Orb", AnchorPoint = V2(0.5, 0.5), Position = UDim2.new(0.04, 0, 0.87, 0),
    Size = off(ORB, ORB), BackgroundColor3 = C.white, BackgroundTransparency = 0.1, ZIndex = 20,
})
Corner(orb, "full")
Grad(orb, rgb(88, 78, 152), rgb(30, 27, 60), 135)
Stroke(orb, rgb(190, 180, 255), 0.7, 1.5)
local orbScale = Instance.new("UIScale")
orbScale.Scale = 0.01
orbScale.Parent = orb
local arc = Frame(orb, { Name = "Arc", AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(ORB + 2, ORB + 2), BackgroundTransparency = 1 })
Corner(arc, "full")
local arcStroke = Stroke(arc, rgb(232, 224, 255), 0, 2.4)
local arcGrad = Instance.new("UIGradient")
arcGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.26, 0.55),
    NumberSequenceKeypoint.new(0.34, 1), NumberSequenceKeypoint.new(1, 1),
})
arcGrad.Parent = arcStroke
do
    local lg = makeLogo(orb, 32, false, false)
    lg.Position = off((ORB - 48) / 2, (ORB - 32) / 2)
end
local orbBtn = Button(orb, { ZIndex = 5 })

local orbBase = UDim2.new(0.04, 0, 0.87, 0)
local function orbPress(k) tw(orbScale, 0.12, { Scale = baseScale() * k }, Quad, Out) end

local function snapOrb()
    local scr = viewport()
    local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
    local cx = a.X + sz.X / 2
    local goalX = (cx < scr.X / 2) and (sz.X / 2 + 14) or (scr.X - sz.X / 2 - 14)
    local cy = math.clamp(a.Y + sz.Y / 2, sz.Y / 2 + 10, scr.Y - sz.Y / 2 - 10)
    tw(orb, 0.45, { Position = UDim2.fromScale(goalX / scr.X, cy / scr.Y) }, Back, Out)
end

orbBtn.InputBegan:Connect(function(input)
    if not isPress(input) then return end
    local startPos = input.Position
    local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
    local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
    local moved = false
    orbPress(0.9)
    beginDrag(function(i)
        local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
        if not moved and (math.abs(dx) + math.abs(dy)) > 8 then moved = true end
        if moved then
            local scr = viewport()
            orb.Position = UDim2.fromScale(
                math.clamp((startCenter.X + dx) / scr.X, 0.02, 0.98),
                math.clamp((startCenter.Y + dy) / scr.Y, 0.04, 0.96))
        end
    end, function()
        orbPress(1)
        if moved then snapOrb() else UI.orbTap() end
    end)
end)

function UI.updateOrb()
    orb.Visible = (State.ballvisible ~= false) or (not winOpen)
end

----------------------------------------------------------------------
-- главное окно
----------------------------------------------------------------------
local winBaseT = 0.13
local win = Frame(gui, {
    Name = "Window", AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(WIN_W, WIN_H),
    BackgroundColor3 = C.white, BackgroundTransparency = winBaseT, Visible = false,
    ClipsDescendants = true, Active = true, ZIndex = 12,
})
Corner(win, 28)
Grad(win, rgb(86, 82, 146), rgb(32, 28, 64), 120)
local winStroke = Stroke(win, C.white, 0.35, 1.5)
do
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.35, 0.62), NumberSequenceKeypoint.new(1, 0.82),
    })
    g.Parent = winStroke
end
local winScale = Instance.new("UIScale")
winScale.Scale = 1
winScale.Parent = win

local particleLayer = Frame(win, { Name = "Particles", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ClipsDescendants = true, ZIndex = 1 })
local body = Group(win, { Name = "Body", Size = off(WIN_W, WIN_H), ZIndex = 2 })
local fx = Frame(win, { Name = "Fx", BackgroundTransparency = 1, Size = off(WIN_W, WIN_H), ZIndex = 30 })

-- шапка
local header = Frame(body, { Name = "Header", BackgroundTransparency = 1, Size = off(WIN_W, HEAD_H) })
local headDrag = Button(header, { Name = "DragHandle", Size = off(WIN_W, HEAD_H) })
local hLogo = makeLogo(header, 40, true, true)
hLogo.Position = off(14, 19)
local hTitle = Label(header, { Position = off(83, 13), Size = off(200, 32), Text = "Eta", TextSize = 26, Font = FONT_B })
Grad(hTitle, rgb(255, 250, 255), rgb(212, 190, 255), 0)
Label(header, { Position = off(84, 46), Size = off(300, 14), Text = "OXIDE  ·  SURVIVAL ISLAND", TextSize = 9.5, TextColor3 = C.txt4 })
do
    local pill = Frame(header, { Position = off(WIN_W - 22 - 36 - 12 - 116, 26), Size = off(116, 28), BackgroundTransparency = 0.93 })
    Corner(pill, "full")
    Stroke(pill, C.white, 0.88, 1)
    local halo = Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(14, 14), BackgroundColor3 = C.green, BackgroundTransparency = 0.75 })
    Corner(halo, "full")
    local d = Frame(pill, { AnchorPoint = V2(0.5, 0.5), Position = off(18, 14), Size = off(8, 8), BackgroundColor3 = C.green })
    Corner(d, "full")
    Label(pill, { Position = off(31, 0), Size = off(82, 28), Text = "Подключено", TextSize = 12.5 })
    local x = Frame(header, { Position = off(WIN_W - 22 - 36, 22), Size = off(36, 36), BackgroundTransparency = 0.93 })
    Corner(x, "full")
    Stroke(x, C.white, 0.88, 1)
    Icon(x, "x", 14, rgb(214, 214, 238), { Position = off(11, 11) })
    local xb = Button(x, { ZIndex = 3 })
    addPress(xb, x, 0.9)
    xb.Activated:Connect(function() if UI.scrolled then return end; UI.closeWindow() end)
end
Frame(body, { Name = "HeadLine", Position = off(0, HEAD_H - 1), Size = off(WIN_W, 1), BackgroundTransparency = 0.92 })

-- боковое меню
local side = Frame(body, { Name = "Sidebar", BackgroundTransparency = 1, Position = off(0, HEAD_H), Size = off(SIDE_W, PAGE_H) })
Frame(body, { Name = "SideLine", Position = off(SIDE_W - 1, HEAD_H), Size = off(1, PAGE_H), BackgroundTransparency = 0.93 })
Label(side, { Position = off(20, PAGE_H - 36), Size = off(150, 14), Text = "ETA  ·  v2.9  ·  Eta29", TextSize = 9.5, TextColor3 = C.txt4 })

local NAV = {
    { "overview", "Обзор", "grid" }, { "functions", "Функции", "bolt" }, { "visual", "Визуал", "eye" }, { "aim", "Аим", "cross" },
    { "models", "Модели", "cube" }, { "configs", "Конфиги", "folder" }, { "settings", "Настройки", "sliders" },
}
local NAV_Y0, NAV_P = 13, 55.3
local selPill = Frame(side, { Name = "Sel", Position = off(8, NAV_Y0), Size = off(155, 50), BackgroundTransparency = 0.9, Visible = false })
Corner(selPill, 16)
Stroke(selPill, C.white, 0.82, 1)
local selBar = Frame(selPill, { Position = off(3, 16), Size = off(3, 18), BackgroundColor3 = theme.b })
Corner(selBar, "full")
onTheme(function() selBar.BackgroundColor3 = theme.b end)

local navItems = {}
for i, n in ipairs(NAV) do
    local y = NAV_Y0 + (i - 1) * NAV_P
    local ic = Icon(side, n[3], 18, rgb(160, 162, 196), { Position = off(30, y + 16) })
    local lb = Label(side, { Position = off(63, y), Size = off(100, 50), Text = n[2], TextSize = 16, TextColor3 = rgb(182, 183, 211) })
    local b = Button(side, { Position = off(8, y), Size = off(155, 50), ZIndex = 3 })
    navItems[n[1]] = { icon = ic, label = lb, y = y }
    b.Activated:Connect(function() if UI.scrolled then return end; UI.switchPage(n[1]) end)
end

-- страницы
local pageHost = Frame(body, { Name = "Pages", BackgroundTransparency = 1, Position = off(SIDE_W, HEAD_H), Size = off(PAGE_W, PAGE_H), ClipsDescendants = true })
local Pages, currentPage = {}, nil

local function getPage(name)
    local p = Pages[name]
    if p then return p end
    local grp = Group(pageHost, { Name = "Page_" .. name, Size = off(PAGE_W, PAGE_H), Visible = false })
    local scroller = New("ScrollingFrame", {
        Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = off(PAGE_W, PAGE_H),
        CanvasSize = off(0, PAGE_H), ScrollBarThickness = 3, ScrollBarImageColor3 = rgb(206, 196, 255),
        ScrollBarImageTransparency = 0.45, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = false,
    }, grp)
    local rv = { items = {}, titles = {} }
    rv.add = function(inst, col) rv.items[#rv.items + 1] = { inst = inst, col = col } end
    p = { name = name, group = grp, scroller = scroller, built = false, rv = rv }
    p.setHeight = function(h) scroller.CanvasSize = off(0, math.max(h, PAGE_H)) end
    Pages[name] = p
    return p
end

-- прокрутка страницы: свой порог движения (тап не двигает страницу), инерция, колесо мыши
local Scroll = { blocked = false, active = false, moved = false, startY = 0, baseY = 0, lastY = 0, lastT = 0, vel = 0, coast = 0 }

local function curScroller()
    local p = currentPage and Pages[currentPage]
    return p and p.scroller or nil
end

local function setScrollY(y)
    local s_ = curScroller()
    if not s_ then return 0 end
    local maxY = math.max(0, s_.CanvasSize.Y.Offset - PAGE_H)
    y = math.clamp(y, 0, maxY)
    s_.CanvasPosition = V2(0, y)
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
    if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
    if not (winOpen and currentPage) or Scroll.blocked or not insidePage(input.Position) then return end
    Scroll.active, Scroll.moved = true, false
    Scroll.startY, Scroll.lastY, Scroll.lastT = input.Position.Y, input.Position.Y, os.clock()
    Scroll.vel, Scroll.coast = 0, 0
    local s_ = curScroller()
    Scroll.baseY = s_ and s_.CanvasPosition.Y or 0
end)

bind(UserInputService.InputChanged, function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseWheel then
        local s_ = curScroller()
        if winOpen and s_ and not Scroll.blocked then
            Scroll.coast = 0
            setScrollY(s_.CanvasPosition.Y - input.Position.Z * 80)
        end
        return
    end
    if not Scroll.active then return end
    if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
    if Scroll.blocked then
        Scroll.active = false
        return
    end
    local k = math.max(0.05, winScale.Scale)
    if not Scroll.moved then
        if math.abs(input.Position.Y - Scroll.startY) < 10 * k then return end
        Scroll.moved = true
        UI.scrolled = true
        Scroll.startY = input.Position.Y
        local s_ = curScroller()
        Scroll.baseY = s_ and s_.CanvasPosition.Y or 0
        Scroll.lastY, Scroll.lastT = input.Position.Y, os.clock()
        return
    end
    local now = os.clock()
    setScrollY(Scroll.baseY - (input.Position.Y - Scroll.startY) / k)
    local dt = now - Scroll.lastT
    if dt > 0.001 then
        Scroll.vel = Scroll.vel * 0.6 + (-(input.Position.Y - Scroll.lastY) / k / dt) * 0.4
    end
    Scroll.lastY, Scroll.lastT = input.Position.Y, now
end)

bind(UserInputService.InputEnded, function(input)
    local t = input.UserInputType
    if (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) or not Scroll.active then return end
    Scroll.active = false
    if Scroll.moved then
        Scroll.coast = (os.clock() - Scroll.lastT > 0.08) and 0 or Scroll.vel
        task.delay(0.12, function() UI.scrolled = false end)
    else
        UI.scrolled = false
    end
end)

local function paintNav(name, instant)
    for key, it in pairs(navItems) do
        local on = (key == name)
        setIconColor(it.icon, on and rgb(206, 196, 255) or rgb(160, 162, 196), instant)
        if instant then
            it.label.TextColor3 = on and C.white or rgb(182, 183, 211)
        else
            tw(it.label, 0.2, { TextColor3 = on and C.white or rgb(182, 183, 211) })
        end
    end
    local it = navItems[name]
    if it then
        selPill.Visible = true
        if instant then selPill.Position = off(8, it.y) else tw(selPill, 0.35, { Position = off(8, it.y) }, Quint, Out) end
    end
end

-- плавное появление: заголовок, потом строки левой колонки сверху вниз, затем правой
function UI.revealPage(p, delay)
    local rv = p.rv
    if not rv then return end
    delay = delay or 0
    local list = {}
    for _, it in ipairs(rv.items) do
        local y = it.inst.Position.Y.Offset
        if y < PAGE_H + 20 then list[#list + 1] = { inst = it.inst, col = it.col, y = y, pos = it.inst.Position } end
    end
    table.sort(list, function(a, b)
        if a.col ~= b.col then return a.col < b.col end
        return a.y < b.y
    end)
    for _, t in ipairs(rv.titles) do
        t.TextTransparency = 1
        task.delay(delay * Anim.speed, function() tw(t, 0.25, { TextTransparency = 0 }, Quad, Out) end)
    end
    local idx = { 0, 0 }
    for _, it in ipairs(list) do
        local g, pos = it.inst, it.pos
        g.GroupTransparency = 0.97
        g.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + 6)
        local n = (it.col == 2) and 2 or 1
        idx[n] = idx[n] + 1
        local d = delay + ((it.col == 2) and 0.08 or 0.02) + idx[n] * 0.03
        task.delay(d * Anim.speed, function()
            if not g.Parent then return end
            tw(g, 0.28, { GroupTransparency = g:GetAttribute("dimT") or 0, Position = pos }, Quad, Out)
        end)
    end
end

function UI.switchPage(name, instant, revealDelay)
    if currentPage == name then return end
    local old = currentPage and Pages[currentPage]
    local oldName = currentPage
    currentPage = name
    Scroll.coast = 0
    local p = getPage(name)
    if not p.built then
        p.built = true
        local ok, err = pcall(Builders[name], p)
        if not ok then warn("[Eta] ошибка страницы " .. name .. ": " .. tostring(err)) end
    end
    paintNav(name, instant)
    p.scroller.CanvasPosition = V2(0, 0)
    p.group.Visible = true
    p.group.GroupTransparency = 0
    p.group.Position = off(0, 0)
    if old and old ~= p then
        if instant then
            old.group.Visible = false
        else
            tw(old.group, 0.1, { GroupTransparency = 1 }, Quad, Out)
            task.delay(0.12 * Anim.speed, function()
                if currentPage ~= oldName then old.group.Visible = false end
            end)
        end
    end
    UI.revealPage(p, revealDelay or (instant and 0.45 or 0.05))
end

-- смена языка: подписи оболочки обновляются на месте, страницы собираются заново
function UI.retranslate()
    for l, key in pairs(TREG) do
        if l.Parent then l.Text = T(key) end
    end
    if UI.onLang then UI.onLang() end
end

function UI.rebuildPages()
    local cur = currentPage
    for _, p in pairs(Pages) do p.group:Destroy() end
    Pages = {}
    currentPage = nil
    for k, list in pairs(Binders) do
        local keep = {}
        for _, b in ipairs(list) do
            if b.shell then keep[#keep + 1] = b end
        end
        Binders[k] = keep
    end
    for i = #sparks, 1, -1 do
        if not sparks[i].f.Parent then table.remove(sparks, i) end
    end
    UI.fpsLabel, UI.spark, UI.uptimeLabel, UI.scaleSliderObj = nil, nil, nil, nil
    if cur then UI.switchPage(cur, true, 0.02) end
end

function UI.setLanguage(pick)
    setLangByPick(pick)
    State.lang = pick
    UI.retranslate()
    UI.rebuildPages()
end

-- уголок для изменения масштаба
local grip = Button(body, { Name = "Grip", Position = off(WIN_W - 34, WIN_H - 34), Size = off(30, 30), ZIndex = 5 })
for r = 0, 2 do
    for c = 0, 2 - r do
        local d = Frame(grip, { Position = off(20 - c * 6, 20 - r * 6), Size = off(2.5, 2.5), BackgroundTransparency = 0.55 })
        Corner(d, "full")
    end
end

----------------------------------------------------------------------
-- частицы и эффекты нажатия
----------------------------------------------------------------------
local PN = 34
local P = {}
for i = 1, PN do
    local sz = 2 + math.random() * 2.4
    local f = Frame(particleLayer, { Size = off(sz, sz), BackgroundColor3 = rgb(212, 204, 255), BackgroundTransparency = 0.6 })
    Corner(f, "full")
    P[i] = { f = f, x = math.random(30, WIN_W - 30), y = math.random(30, WIN_H - 30), vy = 5 + math.random() * 13, vx = (math.random() - 0.5) * 8, ph = math.random() * 6.28 }
    f.Position = off(P[i].x, P[i].y)
end

function UI.refreshParticles()
    local n = math.floor(PN * State.density / 100 + 0.5)
    for i, p in ipairs(P) do p.f.Visible = State.particles and i <= n end
end
UI.refreshParticles()
bindState("particles", function() UI.refreshParticles() end, true)

local function guiToFx(pos)
    local a = fx.AbsolutePosition
    local k = math.max(0.05, winScale.Scale)
    return V2((pos.X - a.X) / k, (pos.Y - a.Y) / k)
end

local function burst(host, x, y, n, spread)
    for i = 1, n do
        local d = Frame(host, { AnchorPoint = V2(0.5, 0.5), Position = off(x, y), Size = off(5, 5), BackgroundColor3 = theme.a, BackgroundTransparency = 0.1 })
        Corner(d, "full")
        local ang = math.random() * 6.283
        local dist = spread * (0.5 + math.random() * 0.8)
        tw(d, 0.55, { Position = off(x + math.cos(ang) * dist, y + math.sin(ang) * dist), BackgroundTransparency = 1, Size = off(2, 2) }, Quint, Out)
        task.delay(0.6, function() d:Destroy() end)
    end
end

function UI.pressFx(obj)
    if not (State.pressfx and winOpen) then return end
    local a, sz = obj.AbsolutePosition, obj.AbsoluteSize
    local p = guiToFx(V2(a.X + sz.X / 2, a.Y + sz.Y / 2))
    burst(fx, p.X, p.Y, 6, 28)
end

local lastTrail = 0
bind(UserInputService.InputChanged, function(input)
    if not (winOpen and State.trail) then return end
    local touch = input.UserInputType == Enum.UserInputType.Touch
    local mouse = input.UserInputType == Enum.UserInputType.MouseMovement
        and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    if not (touch or mouse) then return end
    local now = os.clock()
    if now - lastTrail < 0.035 then return end
    lastTrail = now
    local inset = GuiService:GetGuiInset()
    local p = V2(input.Position.X, input.Position.Y + inset.Y)
    local a, sz = win.AbsolutePosition, win.AbsoluteSize
    if p.X < a.X or p.Y < a.Y or p.X > a.X + sz.X or p.Y > a.Y + sz.Y then return end
    local w = guiToFx(p)
    local d = Frame(fx, { AnchorPoint = V2(0.5, 0.5), Position = off(w.X, w.Y), Size = off(8, 8), BackgroundColor3 = theme.b, BackgroundTransparency = 0.3 })
    Corner(d, "full")
    tw(d, 0.45, { Size = off(2, 2), BackgroundTransparency = 1 }, Quad, Out)
    task.delay(0.5, function() d:Destroy() end)
end)

----------------------------------------------------------------------
-- настройки, влияющие на оболочку
----------------------------------------------------------------------
function UI.setOpacity(v)
    winBaseT = (1 - v / 100) * 0.9 + 0.025
    tw(win, 0.2, { BackgroundTransparency = winBaseT })
end

local cardFrame  -- ниже
local function applyScales()
    if winOpen then winScale.Scale = curScale() end
    if cardFrame and cardOpen then cardFrame.UIScale.Scale = curScale() end
    orbScale.Scale = baseScale()
end

function UI.setUserScale(v, fromSlider)
    userScale = v
    State.uiscale = v
    if not fromSlider and UI.scaleSliderObj then UI.scaleSliderObj.set(v) end
    applyScales()
end

-- перетаскивание окон
local function makeDraggable(target, handle, hooks)
    handle.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        local startPos = input.Position
        local a, sz = target.AbsolutePosition, target.AbsoluteSize
        local startCenter = V2(a.X + sz.X / 2, a.Y + sz.Y / 2)
        local moved = false
        beginDrag(function(i)
            local dx, dy = i.Position.X - startPos.X, i.Position.Y - startPos.Y
            if not moved and (math.abs(dx) + math.abs(dy)) > 6 then
                moved = true
                if hooks and hooks.moved then hooks.moved() end
            end
            if moved then
                local scr = viewport()
                local cx = math.clamp(startCenter.X + dx, sz.X * 0.25, scr.X - sz.X * 0.25)
                local cy = math.clamp(startCenter.Y + dy, math.min(sz.Y / 2, scr.Y / 2), scr.Y - 60)
                target.Position = UDim2.fromScale(cx / scr.X, cy / scr.Y)
            end
        end, function()
            if hooks and hooks.ended then hooks.ended(moved) end
        end)
    end)
end

local winHome = homeCenter()
makeDraggable(win, headDrag, {
    moved = function()
        tw(body, 0.2, { GroupTransparency = 0.45 })
        tw(win, 0.2, { BackgroundTransparency = math.min(1, winBaseT + 0.12) })
    end,
    ended = function(moved)
        if moved then
            winHome = win.Position
            tw(body, 0.3, { GroupTransparency = 0 })
            tw(win, 0.3, { BackgroundTransparency = winBaseT })
            winStroke.Transparency = 0
            tw(winStroke, 0.7, { Transparency = 0.35 })
        end
    end,
})

grip.InputBegan:Connect(function(input)
    if not isPress(input) then return end
    local startPos, startScale = input.Position, userScale
    UI.scrollLock(true)
    beginDrag(function(i)
        local d = ((i.Position.X - startPos.X) + (i.Position.Y - startPos.Y)) / 2
        local v = math.clamp(startScale + d / (WIN_W * curScale()), 0.6, 1.5)
        v = math.floor(v * 20 + 0.5) / 20
        UI.setUserScale(v, false)
    end, function() UI.scrollLock(false) end)
end)

----------------------------------------------------------------------
-- открыть / закрыть окно
----------------------------------------------------------------------
function UI.openWindow()
    if winOpen then return end
    winOpen = true
    local resuming = win.Visible
    win.Visible = true
    if not resuming then
        win.Size = off(WIN_W, WIN_H)
        winScale.Scale = curScale() * 0.12
        win.Position = orb.Position
        body.GroupTransparency = 0.97
    end
    tw(winScale, 0.4, { Scale = curScale() }, Back, Out)
    tw(win, 0.4, { Position = winHome }, Quint, Out)
    task.delay(0.02, function() tw(body, 0.22, { GroupTransparency = 0 }, Quad, Out) end)
    UI.updateOrb()
    UI.syncTopbar()
end

function UI.closeWindow()
    if not winOpen then return end
    winOpen = false
    winHome = win.Position
    tw(body, 0.12, { GroupTransparency = 1 }, Quad, Out)
    tw(winScale, 0.28, { Scale = curScale() * 0.12 }, Quint, In)
    tw(win, 0.28, { Position = orb.Position }, Quint, In)
    task.delay(0.3 * Anim.speed, function()
        if not winOpen then win.Visible = false end
    end)
    UI.updateOrb()
    UI.syncTopbar()
end
bindState("ballvisible", function() UI.updateOrb() end, true)

----------------------------------------------------------------------
-- карточка ввода ключа
----------------------------------------------------------------------
local spinners = {}

local card = Frame(gui, {
    Name = "KeyCard", AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(CARD_W, CARD_H),
    BackgroundColor3 = C.white, BackgroundTransparency = 0.1, Visible = false, Active = true, ZIndex = 10,
})
cardFrame = card
Corner(card, 34)
Grad(card, rgb(70, 66, 122), rgb(24, 22, 50), 120)
local cardStroke = Stroke(card, C.white, 0.35, 1.5)
do
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(0.4, 0.62), NumberSequenceKeypoint.new(1, 0.8),
    })
    g.Parent = cardStroke
end
local cardScale = Instance.new("UIScale")
cardScale.Scale = 1
cardScale.Parent = card
local cardDrag = Button(card, { Name = "DragHandle", ZIndex = 1 })
local cardBody = Group(card, { Name = "Body", Size = sc(1, 1), ZIndex = 2 })

local kLogo = makeLogo(cardBody, 78, true, true)
kLogo.Position = off((CARD_W - 117) / 2, 36)
local kTitle = Label(cardBody, { Position = off(0, 148), Size = off(CARD_W, 38), Text = "Eta", TextSize = 33, Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Center })
Grad(kTitle, rgb(255, 250, 255), rgb(214, 192, 255), 0)
Label(cardBody, { Position = off(0, 194), Size = off(CARD_W, 22), Text = "Введи ключ, чтобы продолжить", TextSize = 15, TextColor3 = C.txt2, TextXAlignment = Enum.TextXAlignment.Center })
local inRoot, keyBox, inStroke, inIcon = Input(card, 35, 232, 425, 58, "key", "Ваш ключ", 18)
inRoot.ZIndex = 3
local function setInputAlpha(a)
    inRoot.BackgroundTransparency = 1 - 0.55 * a
    inStroke.Transparency = 1 - 0.1 * a
    keyBox.TextTransparency = 1 - a
    keyBox.PlaceholderText = (a > 0.6) and T("Ваш ключ") or ""
    setIconAlpha(inIcon, a)
end
Label(cardBody, { Position = off(0, 396), Size = off(CARD_W, 16), Text = "ETA  ·  v2.9  ·  Eta29", TextSize = 9.5, TextColor3 = C.txt4, TextXAlignment = Enum.TextXAlignment.Center })

function UI.onLang()
    keyBox.PlaceholderText = T("Ваш ключ")
end

local function doPaste()
    local txt
    if type(getclipboard) == "function" then
        local ok, r = pcall(getclipboard)
        if ok and type(r) == "string" then txt = trim(r) end
    end
    if txt and txt ~= "" then
        keyBox.Text = txt
        tw(inStroke, 0.15, { Transparency = 0.2, Color = theme.a })
        task.delay(0.6, function() tw(inStroke, 0.3, { Transparency = 0.9, Color = C.white }) end)
        UI.toast("Вставлено", "clipboard")
        burst(inRoot, 396, 29, 9, 26)
    else
        UI.toast("Буфер обмена пуст", "clipboard")
    end
end

local pasteWrap = Group(cardBody, { Name = "PasteWrap", Position = off(35, 306), Size = off(141, 52) })
MakeButton(pasteWrap, 0, 0, 141, 52, "Вставить", "clipboard", "ghost", doPaste)

local login = Frame(cardBody, { Name = "Login", Position = off(188, 306), Size = off(272, 52), BackgroundColor3 = C.white })
Corner(login, 16)
accentGradient(login, 0)
local lc = Group(login, { Name = "Content", Size = sc(1, 1) })
do
    local lw = measure("Войти", 16, FONT_B)
    local lx = (272 - (lw + 10 + 16)) / 2
    Label(lc, { Position = off(lx, 0), Size = off(lw + 6, 52), Text = "Войти", TextSize = 16, Font = FONT_B, TextColor3 = C.dark })
    Icon(lc, "arrow", 16, C.dark, { Position = off(lx + lw + 12, 18) })
end
local spin = Frame(login, { Name = "Spinner", AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Size = off(24, 24), BackgroundTransparency = 1, Visible = false })
Corner(spin, "full")
local spinStroke = Stroke(spin, C.dark, 0, 2.6)
do
    local g = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.4),
        NumberSequenceKeypoint.new(0.68, 1), NumberSequenceKeypoint.new(1, 1),
    })
    g.Parent = spinStroke
    spinners[#spinners + 1] = g
end
local chk = Icon(login, "check", 26, C.dark, { Name = "Check", AnchorPoint = V2(0.5, 0.5), Position = sc(0.5, 0.5), Visible = false })
local chkScale = Instance.new("UIScale")
chkScale.Parent = chk
local loginBtn = Button(login, { ZIndex = 4 })
addPress(loginBtn, login, 0.97)

local cardHome = homeCenter()
local cardMoved = false
local busy = false

local function orbCenterPos()
    local scr = viewport()
    local a, sz = orb.AbsolutePosition, orb.AbsoluteSize
    return UDim2.fromScale((a.X + sz.X / 2) / scr.X, (a.Y + sz.Y / 2) / scr.Y)
end

local function openCard()
    if cardOpen then return end
    cardOpen = true
    UI.syncTopbar()
    card.Visible = true
    cardScale.Scale = curScale() * 0.18
    card.Position = orbCenterPos()
    card.BackgroundTransparency = 0.7
    if not cardMoved then cardHome = homeCenter() end
    cardBody.GroupTransparency = 0.97
    setInputAlpha(0)
    tw(cardScale, 0.6, { Scale = curScale() }, Back, Out)
    tw(card, 0.55, { Position = cardHome, BackgroundTransparency = 0.1 }, Quint, Out)
    task.delay(0.16, function()
        tw(cardBody, 0.4, { GroupTransparency = 0 }, Quad, Out)
        animateValue(0.4, 0, 1, setInputAlpha)
    end)
end

local function closeCard()
    if not cardOpen then return end
    cardOpen = false
    UI.syncTopbar()
    cardHome = card.Position
    tw(cardBody, 0.15, { GroupTransparency = 1 }, Quad, Out)
    animateValue(0.15, 1, 0, setInputAlpha)
    tw(cardScale, 0.4, { Scale = curScale() * 0.18 }, Quint, In)
    tw(card, 0.4, { Position = orbCenterPos(), BackgroundTransparency = 0.7 }, Quint, In)
    task.delay(0.42 * Anim.speed, function()
        if not cardOpen then card.Visible = false end
    end)
end

makeDraggable(card, cardDrag, {
    ended = function(moved) if moved then cardHome = card.Position; cardMoved = true end end,
})

local function shake()
    local p = card.Position
    local d = 0.008
    local seq = { d, -d, d * 0.6, -d * 0.6, 0 }
    for i, o in ipairs(seq) do
        task.delay((i - 1) * 0.06, function()
            tw(card, 0.06, { Position = UDim2.new(p.X.Scale + o, 0, p.Y.Scale, 0) }, Quad, InOut)
        end)
    end
end

local function ripple(delay)
    task.delay(delay, function()
        local ring = Frame(cardBody, {
            AnchorPoint = V2(0.5, 0.5), Position = off(35 + 425 / 2, 332), Size = off(56, 56), BackgroundTransparency = 1,
        })
        Corner(ring, "full")
        local rs = Stroke(ring, C.white, 0.35, 1.6)
        tw(ring, 0.9, { Size = off(236, 236) }, Quint, Out)
        tw(rs, 0.9, { Transparency = 1 }, Quad, Out)
        task.delay(1, function() ring:Destroy() end)
    end)
end

local function resetLogin()
    spin.Visible = false
    chk.Visible = false
    tw(login, 0.4, { Size = off(272, 52), Position = off(188, 306) }, Quint, Out)
    tw(pasteWrap, 0.3, { GroupTransparency = 0 }, Quad, Out)
    tw(lc, 0.3, { GroupTransparency = 0 }, Quad, Out)
end

local function flyShared(winCenter)
    local scr = viewport()
    local k = curScale()
    local function center(o)
        local a, s = o.AbsolutePosition, o.AbsoluteSize
        return V2(a.X + s.X / 2, a.Y + s.Y / 2)
    end
    local fromLogo, fromTitle = center(kLogo), center(kTitle)
    local topLeft = V2(winCenter.X - WIN_W * k / 2, winCenter.Y - WIN_H * k / 2)
    local toLogo = V2(topLeft.X + 44 * k, topLeft.Y + 39 * k)
    local toTitle = V2(topLeft.X + 107 * k, topLeft.Y + 29 * k)
    local host = Frame(gui, { Name = "Fly", BackgroundTransparency = 1, Size = sc(1, 1), ZIndex = 40 })
    local fl = Frame(host, { AnchorPoint = V2(0.5, 0.5), BackgroundTransparency = 1, Size = off(117, 78), Position = UDim2.fromScale(fromLogo.X / scr.X, fromLogo.Y / scr.Y) })
    local fls = Instance.new("UIScale")
    fls.Scale = k
    fls.Parent = fl
    makeLogo(fl, 78, true, false)
    local ft = Label(host, {
        AnchorPoint = V2(0.5, 0.5), Size = off(120, 40), Text = "Eta", TextSize = 33, Font = FONT_B,
        TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromScale(fromTitle.X / scr.X, fromTitle.Y / scr.Y),
    })
    Grad(ft, rgb(255, 250, 255), rgb(214, 192, 255), 0)
    local fts = Instance.new("UIScale")
    fts.Scale = k
    fts.Parent = ft
    kLogo.Visible = false
    kTitle.Visible = false
    tw(fl, 0.65, { Position = UDim2.fromScale(toLogo.X / scr.X, toLogo.Y / scr.Y) }, Quint, InOut)
    tw(fls, 0.65, { Scale = k * 0.51 }, Quint, InOut)
    tw(ft, 0.65, { Position = UDim2.fromScale(toTitle.X / scr.X, toTitle.Y / scr.Y) }, Quint, InOut)
    tw(fts, 0.65, { Scale = k * 0.79 }, Quint, InOut)
    task.delay(0.95, function() host:Destroy() end)
end

local function goMain()
    authed = true
    UI.keyText = trim(keyBox.Text)
    local scr = viewport()
    local k = curScale()
    local c = card.AbsolutePosition + card.AbsoluteSize / 2
    local hw, hh = WIN_W * k / 2, WIN_H * k / 2
    local px = math.clamp(c.X, hw, math.max(hw, scr.X - hw))
    local lo = math.max(hh, topInsetPx() + hh + 6)
    local py = math.clamp(c.Y, lo, math.max(lo, scr.Y - hh))
    winHome = UDim2.fromScale(px / scr.X, py / scr.Y)
    winOpen = true
    UI.syncTopbar()
    win.Visible = true
    winScale.Scale = k
    win.Size = off(CARD_W, CARD_H)
    win.Position = card.Position
    body.GroupTransparency = 0.97
    UI.updateOrb()
    UI.switchPage("overview", true)
    flyShared(V2(px, py))
    tw(win, 0.6, { Size = off(WIN_W, WIN_H), Position = winHome }, Quint, Out)
    tw(cardBody, 0.25, { GroupTransparency = 1 }, Quad, Out)
    animateValue(0.25, 1, 0, setInputAlpha)
    task.delay(0.3, function()
        card.Visible = false
        cardOpen = false
        busy = false
    end)
    task.delay(0.32, function() tw(body, 0.5, { GroupTransparency = 0 }, Quad, Out) end)
end

local function doLogin()
    if busy then return end
    local txt = trim(keyBox.Text)
    if txt == "" then
        UI.toast("Введи ключ", "key")
        shake()
        return
    end
    busy = true
    keyBox:ReleaseFocus()
    tw(pasteWrap, 0.25, { GroupTransparency = 1 }, Quad, Out)
    tw(lc, 0.2, { GroupTransparency = 1 }, Quad, Out)
    tw(login, 0.45, { Size = off(56, 52), Position = off(35 + (425 - 56) / 2, 306) }, Quint, Out)
    task.delay(0.3, function() if busy then spin.Visible = true end end)
    task.delay(1.15, function()
        if string.lower(txt) == KEY then
            spin.Visible = false
            chk.Visible = true
            chkScale.Scale = 0.2
            tw(chkScale, 0.4, { Scale = 1 }, Back, Out)
            ripple(0)
            ripple(0.22)
            task.delay(0.95, goMain)
        else
            resetLogin()
            tw(inStroke, 0.15, { Color = C.red, Transparency = 0.1 })
            task.delay(0.9, function() tw(inStroke, 0.3, { Color = C.white, Transparency = 0.9 }) end)
            shake()
            UI.toast("Неверный ключ", "x")
            busy = false
        end
    end)
end

loginBtn.Activated:Connect(doLogin)
keyBox.FocusLost:Connect(function(enter) if enter then doLogin() end end)

function UI.orbTap()
    if not authed then
        if busy then return end
        if cardOpen then closeCard() else openCard() end
    else
        if winOpen then UI.closeWindow() else UI.openWindow() end
    end
end

----------------------------------------------------------------------
-- главный цикл
----------------------------------------------------------------------
local t0 = os.clock()
local acc1, acc2, fpsEst = 0, 0, 60
bind(RunService.Heartbeat, function(dt)
    local now = os.clock()
    if dt > 0 then fpsEst = fpsEst * 0.9 + (1 / dt) * 0.1 end
    arcGrad.Rotation = (now * 240) % 360
    for _, g in ipairs(spinners) do g.Rotation = (now * 420) % 360 end
    for _, sp in ipairs(sparks) do
        if sp.f.Parent then
            sp.th = sp.th + dt * sp.sp
            local x, y = sp.a * math.cos(sp.th), sp.b * math.sin(sp.th)
            local cph, sph = math.cos(sp.phi), math.sin(sp.phi)
            sp.f.Position = off(sp.cx + x * cph - y * sph, sp.cy + x * sph + y * cph)
            local k = 0.65 + 0.35 * math.sin(now * 3.2 + sp.th * 2)
            sp.f.Size = off(sp.s * k, sp.s * k)
        end
    end
    if winOpen and State.particles then
        local n = math.floor(PN * State.density / 100 + 0.5)
        for i = 1, n do
            local p = P[i]
            p.y = p.y - p.vy * dt
            p.x = p.x + (p.vx + math.sin(now * 0.7 + p.ph) * 5) * dt
            if p.y < 24 then
                p.y = WIN_H - 24
                p.x = math.random(30, WIN_W - 30)
            end
            p.f.Position = off(p.x, p.y)
            p.f.BackgroundTransparency = 0.45 + 0.4 * (0.5 + 0.5 * math.sin(now * 1.4 + p.ph))
        end
    end
    if Scroll.coast ~= 0 then
        local s_ = curScroller()
        if s_ then
            local y = s_.CanvasPosition.Y + Scroll.coast * dt
            local ny = setScrollY(y)
            if ny ~= y then Scroll.coast = 0 end
            Scroll.coast = Scroll.coast * math.max(0, 1 - 5 * dt)
            if math.abs(Scroll.coast) < 12 then Scroll.coast = 0 end
        else
            Scroll.coast = 0
        end
    end
    if Scroll.blocked and not Drag.finish then Scroll.blocked = false end
    acc1 = acc1 + dt
    if acc1 >= 1 then
        acc1 = 0
        local lb = UI.uptimeLabel
        if lb and lb.Parent then
            local t = math.floor(now - t0)
            lb.Text = string.format(T("Аптайм %s"), string.format("%02d:%02d", math.floor(t / 60) % 100, t % 60))
        end
    end
    acc2 = acc2 + dt
    if acc2 >= 0.5 then
        acc2 = 0
        local f = math.floor(math.min(fpsEst, 999) + 0.5)
        if UI.fpsLabel and UI.fpsLabel.Parent then UI.fpsLabel.Text = tostring(f) end
        if UI.spark then UI.spark.push(f) end
    end
end)

----------------------------------------------------------------------
-- запуск
----------------------------------------------------------------------
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyScales)
UI.setOpacity(State.panelopacity)
UI.updateOrb()
orb.Position = orbBase
orbScale.Scale = 0.01
tw(orbScale, 0.8, { Scale = baseScale() }, Back, Out)

end
BuildShell()
