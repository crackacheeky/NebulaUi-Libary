local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

local HAS_WRITEFILE = type(writefile) == "function"
local HAS_READFILE  = type(readfile)  == "function"

-- ── Exact Matcha palette from screenshot ──────────────
local T = {
    WinBG       = Color3.fromRGB(24, 24, 28),      -- main window
    TopBar      = Color3.fromRGB(18, 18, 22),      -- very top strip
    TabBarBG    = Color3.fromRGB(24, 24, 28),      -- tab row bg
    ColBG       = Color3.fromRGB(30, 30, 35),      -- column background
    Accent      = Color3.fromRGB(235, 75, 175),    -- pink
    AccentDark  = Color3.fromRGB(160, 48, 120),
    TabActiveBG = Color3.fromRGB(38, 38, 45),      -- active top tab bg (rounded pill)
    TabActiveBdr= Color3.fromRGB(65, 65, 75),      -- active tab border
    SubActive   = Color3.fromRGB(235, 75, 175),    -- active sub-tab text
    SubInactive = Color3.fromRGB(105, 105, 125),   -- inactive sub-tab text
    SliderTrack = Color3.fromRGB(52, 52, 62),      -- slider bar bg
    SliderFill  = Color3.fromRGB(235, 75, 175),    -- slider filled portion
    CheckBG     = Color3.fromRGB(36, 36, 44),      -- unchecked box
    CheckActive = Color3.fromRGB(235, 75, 175),    -- checked box
    CheckBorder = Color3.fromRGB(60, 60, 74),
    DropBG      = Color3.fromRGB(34, 34, 41),
    DropHover   = Color3.fromRGB(42, 42, 52),
    DropBorder  = Color3.fromRGB(55, 55, 68),
    SectionLbl  = Color3.fromRGB(105, 105, 125),  -- section header like "Misc"
    ItemLabel   = Color3.fromRGB(215, 215, 225),  -- normal item text
    ValueLabel  = Color3.fromRGB(215, 215, 225),  -- right-side values "500"
    KbBG        = Color3.fromRGB(38, 38, 50),
    KbText      = Color3.fromRGB(100, 100, 120),
    Divider     = Color3.fromRGB(40, 40, 50),
    ScrollBar   = Color3.fromRGB(235, 75, 175),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontLight   = Enum.Font.Gotham,
}

-- ── Helpers ───────────────────────────────────────────
local function TW(obj, t, props)
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

local function Inst(cls, props)
    local o = Instance.new(cls)
    local par = nil
    for k, v in pairs(props or {}) do
        if k == "Parent" then par = v else pcall(function() o[k] = v end) end
    end
    if par then o.Parent = par end
    return o
end

local function Rnd(r, p)
    Inst("UICorner", {CornerRadius=UDim.new(0,r), Parent=p})
end
local function Brdr(c, t, p)
    Inst("UIStroke", {Color=c, Thickness=t, Parent=p, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function Padding(top, bot, left, right, p)
    Inst("UIPadding", {
        PaddingTop=UDim.new(0,top), PaddingBottom=UDim.new(0,bot),
        PaddingLeft=UDim.new(0,left), PaddingRight=UDim.new(0,right), Parent=p,
    })
end
local function VLayout(p, gap)
    Inst("UIListLayout", {
        SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=Enum.FillDirection.Vertical,
        Padding=UDim.new(0, gap or 0), Parent=p,
    })
end
local function HLayout(p, gap)
    Inst("UIListLayout", {
        SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=Enum.FillDirection.Horizontal,
        Padding=UDim.new(0, gap or 0), Parent=p,
    })
end

local function DragFrame(frame, handle)
    local down, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            down, ds, sp = true, i.Position, frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if down and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then down = false end
    end)
end

-- HSV helpers
local function HSVtoRGB(h,s,v)
    if s == 0 then return Color3.new(v,v,v) end
    local i = math.floor(h*6); local f = h*6-i
    local p,q,t2 = v*(1-s), v*(1-f*s), v*(1-(1-f)*s); i=i%6
    if i==0 then return Color3.new(v,t2,p) elseif i==1 then return Color3.new(q,v,p)
    elseif i==2 then return Color3.new(p,v,t2) elseif i==3 then return Color3.new(p,q,v)
    elseif i==4 then return Color3.new(t2,p,v) else return Color3.new(v,p,q) end
end
local function RGBtoHSV(c)
    local r,g,b=c.R,c.G,c.B; local mx,mn=math.max(r,g,b),math.min(r,g,b)
    local h,s,v=0,0,mx; local d=mx-mn; s=mx==0 and 0 or d/mx
    if mx~=mn then
        if mx==r then h=(g-b)/d+(g<b and 6 or 0)
        elseif mx==g then h=(b-r)/d+2 else h=(r-g)/d+4 end; h=h/6
    end
    return h,s,v
end
local function toHex(c) return string.format("#%02X%02X%02X",c.R*255,c.G*255,c.B*255) end
local function fromHex(s)
    s=s:gsub("#","")
    if #s~=6 then return Color3.new(1,1,1) end
    return Color3.fromRGB(tonumber(s:sub(1,2),16)or 255,tonumber(s:sub(3,4),16)or 255,tonumber(s:sub(5,6),16)or 255)
end

-- ── Config ────────────────────────────────────────────
local Cfg = {}; Cfg.__index = Cfg
function Cfg.new(name)
    return setmetatable({_name=name, _data={}}, Cfg)
end
function Cfg:reg(f,v) if self._data[f]==nil then self._data[f]=v end end
function Cfg:set(f,v) self._data[f]=v end
function Cfg:get(f)   return self._data[f] end
function Cfg:save(name)
    if not HAS_WRITEFILE then return false,"writefile not supported" end
    local ok,e = pcall(writefile, self._name.."_"..name..".json", HttpService:JSONEncode(self._data))
    return ok, ok and "Saved" or tostring(e)
end
function Cfg:load(name)
    if not HAS_READFILE then return false,"readfile not supported" end
    local ok,d = pcall(readfile, self._name.."_"..name..".json")
    if ok and d then
        local ok2,t = pcall(function() return HttpService:JSONDecode(d) end)
        if ok2 and t then for k,v in pairs(t) do self._data[k]=v end end
    end
    return ok, ok and "Loaded" or "File not found"
end

-- ══════════════════════════════════════════════════════
--  SECTION BUILDER  — no box, just flat items
-- ══════════════════════════════════════════════════════
local function BuildSection(parent, cfg, sectionName)
    local S = {}

    -- Section label (like "Misc", "Trigger Bot") — dim text, no box
    if sectionName and sectionName ~= "" then
        local lbl = Inst("TextLabel", {
            Size=UDim2.new(1,0,0,18),
            BackgroundTransparency=1,
            Text=sectionName,
            TextColor3=T.SectionLbl,
            TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,
            Parent=parent,
        })
        Padding(0,0,2,0, lbl)
    end

    -- ── Checkbox ──────────────────────────────────────
    -- Matches screenshot: small square, label right, keybind badge far right
    function S:AddCheckbox(o)
        o = o or {}
        local lbl   = o.Name or "Option"
        local def   = o.Default or false
        local flag  = o.Flag
        local kb    = o.Keybind
        local cb    = o.Callback or function() end
        if flag then cfg:reg(flag, def) end
        local state = def

        local row = Inst("TextButton", {
            Size=UDim2.new(1,0,0,22),
            BackgroundTransparency=1,
            Text="", AutoButtonColor=false,
            Parent=parent,
        })

        -- Square checkbox (exact match: 13x13, radius 2)
        local box = Inst("Frame", {
            Position=UDim2.new(0,2,0.5,-6),
            Size=UDim2.new(0,13,0,13),
            BackgroundColor3=state and T.CheckActive or T.CheckBG,
            BorderSizePixel=0, Parent=row,
        })
        Rnd(2, box)
        Brdr(T.CheckBorder, 1, box)

        local tick = Inst("TextLabel", {
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            Text="✓", TextColor3=Color3.new(1,1,1),
            TextSize=9, Font=T.FontBold,
            Visible=state, Parent=box,
        })

        -- Item label
        Inst("TextLabel", {
            Position=UDim2.new(0,22,0,0),
            Size=UDim2.new(1,-80,1,0),
            BackgroundTransparency=1,
            Text=lbl, TextColor3=T.ItemLabel,
            TextSize=12, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,
            Parent=row,
        })

        -- Keybind badge (like "rmb", "e", "q")
        if kb then
            local badge = Inst("TextLabel", {
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-2,0.5,0),
                Size=UDim2.new(0,30,0,16),
                BackgroundColor3=T.KbBG,
                BorderSizePixel=0,
                Text=kb, TextColor3=T.KbText,
                TextSize=10, Font=T.FontLight,
                Parent=row,
            })
            Rnd(3, badge)
        end

        local function updateBox(anim)
            TweenService:Create(box, TweenInfo.new(anim and 0.12 or 0), {BackgroundColor3=state and T.CheckActive or T.CheckBG}):Play()
            tick.Visible = state
        end

        row.MouseButton1Click:Connect(function()
            state = not state
            if flag then cfg:set(flag, state) end
            updateBox(true)
            task.spawn(cb, state)
        end)
        row.MouseEnter:Connect(function() TW(row,0.08,{BackgroundColor3=Color3.fromRGB(32,32,40)}) end)
        row.MouseLeave:Connect(function() TW(row,0.08,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)

        local obj = {}
        function obj:Set(v) state=v; if flag then cfg:set(flag,v) end; updateBox(true); task.spawn(cb,v) end
        function obj:Get() return state end
        return obj
    end

    -- ── Slider ────────────────────────────────────────
    -- Screenshot: "Distance    500" on one line, thin pink bar below
    function S:AddSlider(o)
        o = o or {}
        local lbl   = o.Name or "Value"
        local minV  = o.Min or 0
        local maxV  = o.Max or 100
        local def   = o.Default or minV
        local dec   = o.Decimals or 0
        local sfx   = o.Suffix or ""
        local flag  = o.Flag
        local cb    = o.Callback or function() end
        if flag then cfg:reg(flag, def) end
        local val   = math.clamp(def, minV, maxV)

        local wrap = Inst("Frame", {
            Size=UDim2.new(1,0,0,34),
            BackgroundTransparency=1,
            Parent=parent,
        })

        -- Label + value on same row
        Inst("TextLabel", {
            Position=UDim2.new(0,2,0,2),
            Size=UDim2.new(0.6,0,0,16),
            BackgroundTransparency=1,
            Text=lbl, TextColor3=T.ItemLabel,
            TextSize=12, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,
            Parent=wrap,
        })

        local fmt = dec>0 and ("%."..dec.."f") or "%d"
        local valLbl = Inst("TextLabel", {
            AnchorPoint=Vector2.new(1,0),
            Position=UDim2.new(1,-2,0,2),
            Size=UDim2.new(0,50,0,16),
            BackgroundTransparency=1,
            Text=string.format(fmt,val)..sfx,
            TextColor3=T.ValueLabel,
            TextSize=12, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right,
            Parent=wrap,
        })

        -- Track — 2px tall, full width (matching screenshot)
        local track = Inst("Frame", {
            Position=UDim2.new(0,2,0,22),
            Size=UDim2.new(1,-4,0,3),
            BackgroundColor3=T.SliderTrack,
            BorderSizePixel=0, Parent=wrap,
        })
        Rnd(99, track)

        local fill = Inst("Frame", {
            Size=UDim2.new((val-minV)/(maxV-minV),0,1,0),
            BackgroundColor3=T.SliderFill,
            BorderSizePixel=0, Parent=track,
        })
        Rnd(99, fill)

        -- Small circle knob
        local knob = Inst("Frame", {
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new((val-minV)/(maxV-minV),0,0.5,0),
            Size=UDim2.new(0,10,0,10),
            BackgroundColor3=T.SliderFill,
            BorderSizePixel=0, ZIndex=2, Parent=track,
        })
        Rnd(99, knob)

        local function setVal(sc)
            sc = math.clamp(sc,0,1)
            local m = 10^dec
            val = math.floor((minV+(maxV-minV)*sc)*m+0.5)/m
            val = math.clamp(val, minV, maxV)
            valLbl.Text = string.format(fmt,val)..sfx
            TweenService:Create(fill, TweenInfo.new(0.04),{Size=UDim2.new(sc,0,1,0)}):Play()
            TweenService:Create(knob,TweenInfo.new(0.04),{Position=UDim2.new(sc,0,0.5,0)}):Play()
            if flag then cfg:set(flag,val) end
            task.spawn(cb,val)
        end

        local dragging = false
        local hitbox = Inst("TextButton", {
            Position=UDim2.new(0,-2,0,-10),
            Size=UDim2.new(1,4,0,24),
            BackgroundTransparency=1, Text="", ZIndex=3, Parent=track,
        })
        hitbox.MouseButton1Down:Connect(function()
            dragging=true
            TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,12,0,12)}):Play()
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=false
                TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,10,0,10)}):Play()
            end
        end)
        RunService.Heartbeat:Connect(function()
            if dragging then
                local mx = UserInputService:GetMouseLocation().X
                local as = track.AbsoluteSize.X
                if as>0 then setVal((mx-track.AbsolutePosition.X)/as) end
            end
        end)

        local obj = {}
        function obj:Set(v) setVal(math.clamp((v-minV)/(maxV-minV),0,1)) end
        function obj:Get() return val end
        return obj
    end

    -- ── Dropdown ──────────────────────────────────────
    -- Screenshot: dark box, item name left, arrow right, opens below
    function S:AddDropdown(o)
        o = o or {}
        local lbl   = o.Name or "Select"
        local items = o.Items or {}
        local def   = o.Default or (items[1] or "")
        local flag  = o.Flag
        local cb    = o.Callback or function() end
        if flag then cfg:reg(flag, def) end
        local sel = def; local isOpen = false

        local wrap = Inst("Frame", {
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=parent,
        })
        -- Label above dropdown
        Inst("TextLabel", {
            Size=UDim2.new(1,0,0,18),
            BackgroundTransparency=1,
            Text=lbl, TextColor3=T.ItemLabel,
            TextSize=12, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
        })

        local dbox = Inst("TextButton", {
            Position=UDim2.new(0,0,0,20),
            Size=UDim2.new(1,0,0,28),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Text="", AutoButtonColor=false, Parent=wrap,
        })
        Rnd(4, dbox); Brdr(T.DropBorder, 1, dbox)

        local selLbl = Inst("TextLabel", {
            Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-30,1,0),
            BackgroundTransparency=1, Text=sel,
            TextColor3=T.ItemLabel, TextSize=12, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=dbox,
        })
        local arrow = Inst("TextLabel", {
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
            Size=UDim2.new(0,14,0,14), BackgroundTransparency=1,
            Text="▾", TextColor3=T.SubInactive, TextSize=14, Font=T.FontBold, Parent=dbox,
        })

        local listH = math.min(#items,6)*24+4
        local dlist = Inst("Frame", {
            Position=UDim2.new(0,0,0,50),
            Size=UDim2.new(1,0,0,listH),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Visible=false, ZIndex=60, Parent=wrap,
        })
        Rnd(4,dlist); Brdr(T.DropBorder,1,dlist)
        VLayout(dlist,0)
        Padding(2,2,0,0,dlist)

        for _, item in ipairs(items) do
            local ib = Inst("TextButton", {
                Size=UDim2.new(1,0,0,24),
                BackgroundTransparency=1,
                Text=item, TextColor3=item==sel and T.Accent or T.ItemLabel,
                TextSize=12, Font=T.Font,
                AutoButtonColor=false, ZIndex=61, Parent=dlist,
            })
            ib.TextXAlignment = Enum.TextXAlignment.Left
            Padding(0,0,10,0,ib)
            ib.MouseEnter:Connect(function() TW(ib,0.07,{BackgroundColor3=T.DropHover}) end)
            ib.MouseLeave:Connect(function() TW(ib,0.07,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)
            ib.MouseButton1Click:Connect(function()
                sel = item; selLbl.Text = item
                for _,ch in ipairs(dlist:GetChildren()) do
                    if ch:IsA("TextButton") then TW(ch,0.1,{TextColor3=ch.Text==sel and T.Accent or T.ItemLabel}) end
                end
                isOpen=false; dlist.Visible=false
                TW(arrow,0.15,{Rotation=0})
                if flag then cfg:set(flag,sel) end
                task.spawn(cb,sel)
            end)
        end

        dbox.MouseButton1Click:Connect(function()
            isOpen=not isOpen; dlist.Visible=isOpen
            TW(arrow,0.15,{Rotation=isOpen and 180 or 0})
        end)
        dbox.MouseEnter:Connect(function() TW(dbox,0.08,{BackgroundColor3=T.DropHover}) end)
        dbox.MouseLeave:Connect(function() TW(dbox,0.08,{BackgroundColor3=T.DropBG}) end)

        -- Spacer after
        Inst("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,Parent=wrap})

        local obj = {}
        function obj:Set(v) sel=v; selLbl.Text=v; if flag then cfg:set(flag,v) end; task.spawn(cb,v) end
        function obj:Get() return sel end
        return obj
    end

    -- ── ColorPicker ───────────────────────────────────
    function S:AddColorPicker(o)
        o = o or {}
        local lbl  = o.Name or "Color"
        local def  = o.Default or Color3.fromRGB(235,75,175)
        local flag = o.Flag
        local cb   = o.Callback or function() end
        if flag then cfg:reg(flag,{def.R,def.G,def.B}) end
        local cc = def; local isOpen=false; local h,s,v=RGBtoHSV(cc)

        local wrap = Inst("Frame",{
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=parent,
        })
        local row = Inst("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=wrap})
        Inst("TextLabel",{
            Position=UDim2.new(0,2,0,0),Size=UDim2.new(1,-52,1,0),
            BackgroundTransparency=1,Text=lbl,TextColor3=T.ItemLabel,
            TextSize=12,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=row,
        })
        local sw = Inst("TextButton",{
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-2,0.5,0),
            Size=UDim2.new(0,38,0,16),BackgroundColor3=cc,
            BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=row,
        })
        Rnd(3,sw); Brdr(T.DropBorder,1,sw)

        local panel = Inst("Frame",{
            Position=UDim2.new(0,0,0,26),Size=UDim2.new(1,0,0,128),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,
            Visible=false,ZIndex=40,Parent=wrap,
        })
        Rnd(5,panel); Brdr(T.DropBorder,1,panel)
        Padding(7,7,7,7,panel)

        -- SV Canvas
        local svc = Inst("Frame",{
            Size=UDim2.new(1,0,0,76),BackgroundColor3=HSVtoRGB(h,1,1),
            BorderSizePixel=0,ClipsDescendants=true,ZIndex=41,Parent=panel,
        })
        Rnd(4,svc)
        local wg=Inst("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=42,Parent=svc})
        Inst("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
        local bg2=Inst("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=43,Parent=svc})
        Inst("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bg2})
        local svk=Inst("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(s,0,1-v,0),
            Size=UDim2.new(0,9,0,9),BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,ZIndex=45,Parent=svc,
        })
        Rnd(99,svk); Brdr(Color3.new(0,0,0),1.5,svk)

        -- Hue bar
        local hbar = Inst("Frame",{
            Position=UDim2.new(0,0,0,82),Size=UDim2.new(1,0,0,8),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=41,Parent=panel,
        })
        Rnd(99,hbar)
        Inst("UIGradient",{Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33,Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83,Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
        }),Parent=hbar})
        local hk=Inst("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(h,0,0.5,0),
            Size=UDim2.new(0,6,1,4),BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,ZIndex=42,Parent=hbar,
        })
        Rnd(3,hk)

        -- Hex
        local hexrow=Inst("Frame",{Position=UDim2.new(0,0,0,97),Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,ZIndex=41,Parent=panel})
        Inst("TextLabel",{Size=UDim2.new(0,24,1,0),BackgroundTransparency=1,Text="HEX",TextColor3=T.SubInactive,TextSize=9,Font=T.FontBold,ZIndex=42,Parent=hexrow})
        local hbox=Inst("TextBox",{
            Position=UDim2.new(0,28,0,2),Size=UDim2.new(1,-28,0,16),
            BackgroundColor3=T.CheckBG,BorderSizePixel=0,
            Text=toHex(cc),TextColor3=T.ItemLabel,TextSize=10,Font=Enum.Font.Code,
            PlaceholderText="#FFFFFF",ClearTextOnFocus=false,ZIndex=42,Parent=hexrow,
        })
        Rnd(3,hbox); Padding(0,0,5,0,hbox)

        local function applyCol()
            cc=HSVtoRGB(h,s,v); sw.BackgroundColor3=cc
            svc.BackgroundColor3=HSVtoRGB(h,1,1)
            svk.Position=UDim2.new(s,0,1-v,0); hk.Position=UDim2.new(h,0,0.5,0)
            hbox.Text=toHex(cc)
            if flag then cfg:set(flag,{cc.R,cc.G,cc.B}) end
            task.spawn(cb,cc)
        end
        local svDn,hDn=false,false
        local svb=Inst("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=46,Parent=svc})
        local hb2=Inst("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=43,Parent=hbar})
        svb.MouseButton1Down:Connect(function() svDn=true end)
        hb2.MouseButton1Down:Connect(function() hDn=true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then svDn=false; hDn=false end
        end)
        RunService.Heartbeat:Connect(function()
            if svDn then
                local m=UserInputService:GetMouseLocation()
                local ap,sz=svc.AbsolutePosition,svc.AbsoluteSize
                if sz.X>0 and sz.Y>0 then s=math.clamp((m.X-ap.X)/sz.X,0,1); v=1-math.clamp((m.Y-ap.Y)/sz.Y,0,1); applyCol() end
            end
            if hDn then
                local m=UserInputService:GetMouseLocation()
                local ap,sz=hbar.AbsolutePosition,hbar.AbsoluteSize
                if sz.X>0 then h=math.clamp((m.X-ap.X)/sz.X,0,1); applyCol() end
            end
        end)
        hbox.FocusLost:Connect(function()
            local ok2,c2=pcall(fromHex,hbox.Text)
            if ok2 then h,s,v=RGBtoHSV(c2); applyCol() end
        end)
        sw.MouseButton1Click:Connect(function() isOpen=not isOpen; panel.Visible=isOpen end)
        applyCol()
        Inst("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        local obj={}
        function obj:Set(c2) h,s,v=RGBtoHSV(c2); applyCol() end
        function obj:Get() return cc end
        return obj
    end

    -- ── Button ────────────────────────────────────────
    function S:AddButton(o)
        o = o or {}
        local lbl = o.Name or "Button"
        local cb  = o.Callback or function() end
        local btn = Inst("TextButton",{
            Size=UDim2.new(1,0,0,26),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Text=lbl, TextColor3=T.ItemLabel,
            TextSize=12, Font=T.Font,
            AutoButtonColor=false, Parent=parent,
        })
        btn.TextXAlignment=Enum.TextXAlignment.Left
        Rnd(4,btn); Brdr(T.DropBorder,1,btn)
        Padding(0,0,10,0,btn)
        btn.MouseEnter:Connect(function() TW(btn,0.08,{BackgroundColor3=T.DropHover}) end)
        btn.MouseLeave:Connect(function() TW(btn,0.08,{BackgroundColor3=T.DropBG}) end)
        btn.MouseButton1Click:Connect(function()
            TW(btn,0.06,{BackgroundColor3=T.AccentDark})
            task.delay(0.1,function() TW(btn,0.1,{BackgroundColor3=T.DropBG}) end)
            task.spawn(cb)
        end)
        Inst("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=parent})
    end

    function S:AddSpacer(h)
        Inst("Frame",{Size=UDim2.new(1,0,0,h or 6),BackgroundTransparency=1,Parent=parent})
    end

    return S
end

-- Column wrapper
local function NewColumn(scrollFrame, cfg)
    local C = {}
    function C:AddSection(name)
        -- Optional thin divider before section (except first)
        return BuildSection(scrollFrame, cfg, name)
    end
    -- Backwards compat alias
    C.AddGroup = C.AddSection
    return C
end

-- ══════════════════════════════════════════════════════
--  NEBULA UI CLASS
-- ══════════════════════════════════════════════════════
local NebulaUI = {}
NebulaUI.__index = NebulaUI

function NebulaUI.new(opts)
    opts = opts or {}
    local inst = setmetatable({}, NebulaUI)
    inst.Windows   = {}
    inst.Cfg       = Cfg.new(opts.Name or "NebulaUI")
    inst.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    inst.Shown     = true

    local sg = Instance.new("ScreenGui")
    sg.Name="NebulaUI"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=999; sg.IgnoreGuiInset=true
    local ok = pcall(function() sg.Parent=CoreGui end)
    if not ok or not sg.Parent then sg.Parent=LP:WaitForChild("PlayerGui") end
    inst.Gui = sg

    -- Notification area (bottom-right)
    inst.NF = Inst("Frame",{
        Size=UDim2.new(0,290,0,400),
        AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-10,1,-10),
        BackgroundTransparency=1, Parent=sg,
    })
    local nfl=Inst("UIListLayout",{
        VerticalAlignment=Enum.VerticalAlignment.Bottom,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,6), Parent=inst.NF,
    })

    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.KeyCode==inst.ToggleKey then inst:Toggle() end
    end)

    -- Executor compat warning
    local missing={}
    if not HAS_WRITEFILE then table.insert(missing,"writefile") end
    if not HAS_READFILE  then table.insert(missing,"readfile") end
    if #missing>0 then
        task.delay(1.5,function()
            inst:Notify({Title="Executor Warning",Body="Not supported: "..table.concat(missing,", ")..". Config save/load disabled.",Type="Warning",Duration=7})
        end)
    end

    return inst
end

function NebulaUI:Toggle()
    self.Shown = not self.Shown
    for _,w in ipairs(self.Windows) do
        if w and w.Root then w.Root.Visible=self.Shown end
    end
end

function NebulaUI:GetFlag(f)    return self.Cfg:get(f) end
function NebulaUI:SetFlag(f,v)  self.Cfg:set(f,v) end

function NebulaUI:Notify(o)
    o = o or {}
    local title=o.Title or "Notice"; local body=o.Body or ""
    local dur=o.Duration or 4; local kind=o.Type or "Info"
    local pal={Info=T.Accent,Success=Color3.fromRGB(45,195,85),Warning=Color3.fromRGB(210,168,35),Error=Color3.fromRGB(208,50,50)}
    local col=pal[kind] or T.Accent
    local card=Inst("Frame",{
        Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(26,26,32),
        BorderSizePixel=0,ClipsDescendants=true,Parent=self.NF,
    })
    Rnd(5,card); Brdr(col,1,card)
    Inst("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=col,BorderSizePixel=0,Parent=card})
    Inst("TextLabel",{Position=UDim2.new(0,11,0,7),Size=UDim2.new(1,-14,0,16),
        BackgroundTransparency=1,Text=title,TextColor3=Color3.new(1,1,1),TextSize=12,Font=T.FontBold,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=card})
    Inst("TextLabel",{Position=UDim2.new(0,11,0,23),Size=UDim2.new(1,-14,0,28),
        BackgroundTransparency=1,Text=body,TextColor3=Color3.fromRGB(160,160,175),TextSize=11,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=card})
    local pb=Inst("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BackgroundColor3=col,BorderSizePixel=0,Parent=card})
    TweenService:Create(pb,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2)}):Play()
    task.delay(dur,function()
        TweenService:Create(card,TweenInfo.new(0.28),{Size=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.3); pcall(function() card:Destroy() end)
    end)
end

-- ── CreateWindow ──────────────────────────────────────
function NebulaUI:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "Script"
    local subtitle = opts.Subtitle or "stable"
    local user     = opts.User     or ""
    local winSize  = opts.Size     or UDim2.new(0,685,0,485)
    local winPos   = opts.Position or UDim2.new(0.5,-342,0.5,-242)
    local cfg      = self.Cfg

    local W={Lib=self,Tabs={},ActiveTab=nil}

    -- Root — no ClipsDescendants so dropdowns float above
    W.Root=Inst("Frame",{
        Name=title.."_Root", Size=winSize, Position=winPos,
        BackgroundColor3=T.WinBG, BorderSizePixel=0, Parent=self.Gui,
    })
    Rnd(7,W.Root)
    Brdr(Color3.fromRGB(50,50,62),1,W.Root)

    -- Inner clip (for corners on content)
    local clip=Inst("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ClipsDescendants=true, Parent=W.Root,
    })
    Rnd(7,clip)

    -- ─ Top bar (title row) ─────────────────────────
    local topBar=Inst("Frame",{
        Size=UDim2.new(1,0,0,32),
        BackgroundColor3=T.TopBar, BorderSizePixel=0, Parent=clip,
    })

    -- "Matcha › Comfort  [stable]"
    Inst("TextLabel",{
        Position=UDim2.new(0,12,0,0),Size=UDim2.new(0,100,1,0),
        BackgroundTransparency=1,
        Text=title.." › "..subtitle,
        TextColor3=Color3.fromRGB(130,130,148),TextSize=12,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=topBar,
    })
    -- "stable" pill badge
    local badgeW = math.max(#subtitle*7+14, 36)
    local badgeX = 12 + (# (title.." › "..subtitle)) * 7 + 6
    -- Simpler: just overlay "stable" in pink after the dim text
    local stableX = 12 + (#title + 3) * 7  -- approx pixel offset
    local stableBadge=Inst("Frame",{
        Position=UDim2.new(0,stableX,0,9),
        Size=UDim2.new(0,badgeW,0,14),
        BackgroundColor3=Color3.fromRGB(52,20,42),
        BorderSizePixel=0,Parent=topBar,
    })
    Rnd(3,stableBadge)
    Inst("TextLabel",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text=subtitle,TextColor3=T.Accent,TextSize=10,Font=T.FontBold,Parent=stableBadge,
    })

    -- Username top right
    if user~="" then
        Inst("TextLabel",{
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-32,0.5,0),
            Size=UDim2.new(0,140,0,20),BackgroundTransparency=1,
            Text=user,TextColor3=Color3.fromRGB(120,120,140),TextSize=11,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right,Parent=topBar,
        })
    end

    -- Close button (small red circle)
    local closeBtn=Inst("TextButton",{
        AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.new(0,14,0,14),BackgroundColor3=Color3.fromRGB(185,45,45),
        BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=topBar,
    })
    Rnd(99,closeBtn)
    closeBtn.MouseButton1Click:Connect(function() W.Root.Visible=false end)
    closeBtn.MouseEnter:Connect(function() TW(closeBtn,0.1,{BackgroundColor3=Color3.fromRGB(225,58,58)}) end)
    closeBtn.MouseLeave:Connect(function() TW(closeBtn,0.1,{BackgroundColor3=Color3.fromRGB(185,45,45)}) end)

    DragFrame(W.Root, topBar)

    -- ─ Tab bar row ─────────────────────────────────
    local tabRow=Inst("Frame",{
        Position=UDim2.new(0,0,0,32),Size=UDim2.new(1,0,0,34),
        BackgroundColor3=T.WinBG,BorderSizePixel=0,Parent=clip,
    })
    -- Bottom divider line
    Inst("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
        BackgroundColor3=T.Divider,BorderSizePixel=0,Parent=tabRow})

    local tabBtnContainer=Inst("Frame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=tabRow,
    })
    HLayout(tabBtnContainer,0)
    Padding(0,0,8,8,tabBtnContainer)

    -- ─ Content area ────────────────────────────────
    local contentHolder=Inst("Frame",{
        Position=UDim2.new(0,0,0,66),Size=UDim2.new(1,0,1,-66),
        BackgroundTransparency=1,Parent=clip,
    })

    -- ─ AddTab ──────────────────────────────────────
    function W:AddTab(tabName)
        local Tab={Window=W,SubTabs={},ActiveSubTab=nil}

        -- Tab button — active style is rounded pill with border (matches screenshot "Combat" tab)
        local tbtn=Inst("TextButton",{
            Size=UDim2.new(0,0,0,26),AutomaticSize=Enum.AutomaticSize.X,
            AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,0,0.5,0),
            BackgroundColor3=Color3.fromRGB(0,0,0,0),BorderSizePixel=0,
            Text=tabName,TextColor3=Color3.fromRGB(108,108,128),
            TextSize=12,Font=T.Font,AutoButtonColor=false,Parent=tabBtnContainer,
        })
        Padding(0,0,10,10,tbtn)
        Rnd(5,tbtn)
        local tbtnBorder=Inst("UIStroke",{
            Color=Color3.fromRGB(0,0,0,0),Thickness=1,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=tbtn,
        })

        local tabContent=Inst("Frame",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Visible=false,Parent=contentHolder,
        })

        -- Sub-tab bar inside tab content
        local subBarRow=Inst("Frame",{
            Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Parent=tabContent,
        })
        HLayout(subBarRow,22)
        Padding(0,0,14,14,subBarRow)
        -- Sub-bar bottom line
        Inst("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
            BackgroundColor3=T.Divider,BorderSizePixel=0,Parent=subBarRow})

        -- Two-column area (below sub bar)
        local colArea=Inst("Frame",{
            Position=UDim2.new(0,0,0,28),Size=UDim2.new(1,0,1,-28),
            BackgroundTransparency=1,Parent=tabContent,
        })

        -- Default cols (no sub-tabs)
        local defL=Inst("ScrollingFrame",{
            Position=UDim2.new(0,10,0,8),Size=UDim2.new(0.5,-14,1,-16),
            BackgroundColor3=T.ColBG,BorderSizePixel=0,
            ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=colArea,
        })
        Rnd(5,defL)
        VLayout(defL,2)
        Padding(10,10,10,10,defL)

        local defR=Inst("ScrollingFrame",{
            Position=UDim2.new(0.5,4,0,8),Size=UDim2.new(0.5,-14,1,-16),
            BackgroundColor3=T.ColBG,BorderSizePixel=0,
            ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=colArea,
        })
        Rnd(5,defR)
        VLayout(defR,2)
        Padding(10,10,10,10,defR)

        Tab.Btn=tbtn; Tab.BtnBdr=tbtnBorder; Tab.Content=tabContent
        Tab.SubBarRow=subBarRow; Tab.ColArea=colArea; Tab.DefL=defL; Tab.DefR=defR

        local function activateTab()
            for _,t in ipairs(W.Tabs) do
                t.Content.Visible=false
                TW(t.Btn,0.15,{BackgroundColor3=Color3.fromRGB(0,0,0,0),TextColor3=Color3.fromRGB(108,108,128)})
                TW(t.BtnBdr,0.15,{Color=Color3.fromRGB(0,0,0,0)})
            end
            tabContent.Visible=true
            TW(tbtn,0.15,{BackgroundColor3=T.TabActiveBG,TextColor3=Color3.fromRGB(220,220,230)})
            TW(tbtnBorder,0.15,{Color=T.TabActiveBdr})
            W.ActiveTab=Tab
        end

        tbtn.MouseButton1Click:Connect(activateTab)
        tbtn.MouseEnter:Connect(function()
            if W.ActiveTab~=Tab then TW(tbtn,0.1,{TextColor3=Color3.fromRGB(185,185,200)}) end
        end)
        tbtn.MouseLeave:Connect(function()
            if W.ActiveTab~=Tab then TW(tbtn,0.1,{TextColor3=Color3.fromRGB(108,108,128)}) end
        end)

        table.insert(W.Tabs,Tab)
        if #W.Tabs==1 then activateTab() end

        function Tab:GetColumns()
            return NewColumn(defL,cfg), NewColumn(defR,cfg)
        end
        Tab.GetColumns = Tab.GetColumns  -- alias

        -- AddSubTab
        function Tab:AddSubTab(subName)
            local ST={}; ST.Tab=self

            local sbtn=Inst("TextButton",{
                Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                BackgroundTransparency=1,BorderSizePixel=0,
                Text=subName,TextColor3=T.SubInactive,
                TextSize=12,Font=T.Font,AutoButtonColor=false,Parent=subBarRow,
            })
            -- Active underline
            local uline=Inst("Frame",{
                AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
                Size=UDim2.new(0,0,0,1),BackgroundColor3=T.Accent,
                BorderSizePixel=0,Parent=sbtn,
            })
            Rnd(99,uline)

            -- Sub-tab columns
            local scL=Inst("ScrollingFrame",{
                Position=UDim2.new(0,10,0,8),Size=UDim2.new(0.5,-14,1,-16),
                BackgroundColor3=T.ColBG,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false,Parent=colArea,
            })
            Rnd(5,scL); VLayout(scL,2); Padding(10,10,10,10,scL)

            local scR=Inst("ScrollingFrame",{
                Position=UDim2.new(0.5,4,0,8),Size=UDim2.new(0.5,-14,1,-16),
                BackgroundColor3=T.ColBG,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false,Parent=colArea,
            })
            Rnd(5,scR); VLayout(scR,2); Padding(10,10,10,10,scR)

            ST.Btn=sbtn; ST.ULine=uline; ST.CL=scL; ST.CR=scR

            local function activateSub()
                defL.Visible=false; defR.Visible=false
                for _,st in ipairs(self.SubTabs) do
                    TW(st.Btn,0.12,{TextColor3=T.SubInactive})
                    TW(st.ULine,0.15,{Size=UDim2.new(0,0,0,1)})
                    st.CL.Visible=false; st.CR.Visible=false
                end
                TW(sbtn,0.12,{TextColor3=T.SubActive})
                task.spawn(function()
                    task.wait()
                    TW(uline,0.18,{Size=UDim2.new(0,sbtn.AbsoluteSize.X,0,1)})
                end)
                scL.Visible=true; scR.Visible=true
                self.ActiveSubTab=ST
            end

            sbtn.MouseButton1Click:Connect(activateSub)
            sbtn.MouseEnter:Connect(function() if self.ActiveSubTab~=ST then TW(sbtn,0.1,{TextColor3=Color3.fromRGB(185,185,200)}) end end)
            sbtn.MouseLeave:Connect(function() if self.ActiveSubTab~=ST then TW(sbtn,0.1,{TextColor3=T.SubInactive}) end end)

            table.insert(self.SubTabs,ST)
            if #self.SubTabs==1 then activateSub() end

            function ST:GetColumns()
                return NewColumn(scL,cfg), NewColumn(scR,cfg)
            end
            return ST
        end

        return Tab
    end

    table.insert(self.Windows,W)
    return W
end

return NebulaUI
