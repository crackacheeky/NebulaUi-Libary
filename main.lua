--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    NebulaUI  —  Matcha/Comfort Style Replica
    Version: 2.0.0
    
    HOW TO LOAD:
        local UI = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/YOUR/REPO/main/NebulaUI.lua"
        ))()
    
    USAGE:
        local Window = UI:CreateWindow({
            Title    = "Matcha",
            Subtitle = "Comfort",
            User     = game.Players.LocalPlayer.Name,
        })
        
        local CombatTab = Window:AddTab("Combat")
        
        -- Get the two columns (left, right)
        local Left, Right = CombatTab:GetColumns()
        
        -- OR use sub-tabs within a tab:
        local AimSubTab = CombatTab:AddSubTab("Aimbot")
        local SilentSubTab = CombatTab:AddSubTab("Silent Aim")
        local subLeft, subRight = AimSubTab:GetColumns()
        
        local Group = subLeft:AddGroup("Settings")
        Group:AddCheckbox({ Name="Enabled", Flag="aim_on", Keybind="rmb" })
        Group:AddSlider({ Name="Distance", Min=0, Max=500, Default=250, Flag="aim_dist" })
        Group:AddDropdown({ Name="Hit Part", Items={"Head","Torso","HRP"}, Flag="aim_part" })
        Group:AddColorPicker({ Name="Color", Default=Color3.fromRGB(232,80,180), Flag="aim_col" })
        Group:AddButton({ Name="Reset", Callback=function() print("reset") end })
        
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ─── Theme (Matcha/Comfort palette) ───
local T = {
    BG           = Color3.fromRGB(22, 22, 26),
    Panel        = Color3.fromRGB(28, 28, 33),
    GroupBG      = Color3.fromRGB(32, 32, 38),
    TopBar       = Color3.fromRGB(17, 17, 21),
    TabBarBG     = Color3.fromRGB(22, 22, 26),
    TabActive    = Color3.fromRGB(36, 36, 44),
    Accent       = Color3.fromRGB(232, 80, 180),
    AccentDark   = Color3.fromRGB(160, 50, 130),
    SubActive    = Color3.fromRGB(232, 80, 180),
    SubInactive  = Color3.fromRGB(115, 115, 132),
    SliderBG     = Color3.fromRGB(48, 48, 58),
    SliderFill   = Color3.fromRGB(232, 80, 180),
    CheckBG      = Color3.fromRGB(40, 40, 50),
    CheckActive  = Color3.fromRGB(232, 80, 180),
    CheckBorder  = Color3.fromRGB(72, 72, 90),
    DropBG       = Color3.fromRGB(36, 36, 44),
    DropHover    = Color3.fromRGB(46, 46, 56),
    Border       = Color3.fromRGB(46, 46, 58),
    Text         = Color3.fromRGB(222, 222, 232),
    TextDim      = Color3.fromRGB(138, 138, 155),
    TextMuted    = Color3.fromRGB(80, 80, 96),
    KeybindBG    = Color3.fromRGB(40, 40, 52),
    Font         = Enum.Font.GothamMedium,
    FontBold     = Enum.Font.GothamBold,
    FontSemi     = Enum.Font.Gotham,
}

-- ─── Helpers ───
local function tw(obj, t, props, sty, dir)
    sty = sty or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, sty, dir), props):Play()
end

local function N(cls, props, children)
    local i = Instance.new(cls)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then
            i[k] = v
        end
    end
    for _, c in pairs(children or {}) do c.Parent = i end
    if props and props.Parent then i.Parent = props.Parent end
    return i
end

local function corner(r, p) return N("UICorner",{CornerRadius=UDim.new(0,r),Parent=p}) end
local function stroke(c, t, p) return N("UIStroke",{Color=c,Thickness=t,Parent=p}) end
local function pad(t,b,l,r,p) return N("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r),Parent=p}) end

local function drag(frame, handle)
    local dn, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dn,ds,sp = true, i.Position, frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dn and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dn=false end
    end)
end

local function HSVtoRGB(h,s,v)
    local r,g,b
    local i=math.floor(h*6); local f=h*6-i
    local p=v*(1-s); local q=v*(1-f*s); local t2=v*(1-(1-f)*s)
    i=i%6
    if i==0 then r,g,b=v,t2,p
    elseif i==1 then r,g,b=q,v,p
    elseif i==2 then r,g,b=p,v,t2
    elseif i==3 then r,g,b=p,q,v
    elseif i==4 then r,g,b=t2,p,v
    elseif i==5 then r,g,b=v,p,q end
    return Color3.new(r,g,b)
end

local function RGBtoHSV(r,g,b)
    r,g,b=r/255,g/255,b/255
    local mx,mn=math.max(r,g,b),math.min(r,g,b)
    local h,s,v=0,0,mx
    local d=mx-mn; s=mx==0 and 0 or d/mx
    if mx~=mn then
        if mx==r then h=(g-b)/d+(g<b and 6 or 0)
        elseif mx==g then h=(b-r)/d+2
        elseif mx==b then h=(r-g)/d+4 end
        h=h/6
    end
    return h,s,v
end

local function toHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end
local function fromHex(h)
    h=h:gsub("#","")
    if #h~=6 then return Color3.new(1,1,1) end
    return Color3.fromRGB(tonumber(h:sub(1,2),16)or 255, tonumber(h:sub(3,4),16)or 255, tonumber(h:sub(5,6),16)or 255)
end

-- ─── Config ───
local ConfigClass = {}
ConfigClass.__index = ConfigClass
function ConfigClass.new(name)
    return setmetatable({Name=name, Data={}}, ConfigClass)
end
function ConfigClass:Set(f,v) self.Data[f]=v end
function ConfigClass:Get(f) return self.Data[f] end
function ConfigClass:Register(f,d) if self.Data[f]==nil then self.Data[f]=d end end
function ConfigClass:Save(n)
    local ok,e=pcall(writefile, self.Name.."_"..n..".json", HttpService:JSONEncode(self.Data))
    return ok, ok and "Saved: "..n or tostring(e)
end
function ConfigClass:Load(n)
    local ok,d=pcall(readfile, self.Name.."_"..n..".json")
    if ok then for k,v in pairs(HttpService:JSONDecode(d)) do self.Data[k]=v end end
    return ok, ok and "Loaded: "..n or "File not found"
end

-- ════════════════════════════════════════════
--  Element builder (shared by columns)
-- ════════════════════════════════════════════
local function buildGroup(scrollFrame, libRef, name)
    local G = {}

    local gFrame = N("Frame",{
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.GroupBG, BorderSizePixel=0,
        Parent=scrollFrame,
    })
    corner(5, gFrame)

    -- header
    local hdr = N("Frame",{Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=gFrame})
    N("TextLabel",{
        Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-10,1,0),
        BackgroundTransparency=1, Text=name,
        TextColor3=T.TextDim, TextSize=11, Font=T.FontBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr,
    })
    -- thin top accent line
    N("Frame",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0,1),
        BackgroundColor3=T.Border, BorderSizePixel=0, Parent=hdr})

    local list = N("Frame",{
        Position=UDim2.new(0,0,0,26),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Parent=gFrame,
    })
    N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,0), Parent=list})
    N("UIPadding",{PaddingBottom=UDim.new(0,6), Parent=list})

    -- ─── Checkbox ───
    function G:AddCheckbox(opts)
        opts = opts or {}
        local label = opts.Name     or "Option"
        local def   = opts.Default  or false
        local flag  = opts.Flag
        local key   = opts.Keybind
        local cb    = opts.Callback or function() end
        if flag then libRef.Cfg:Register(flag, def) end
        local state = def

        local row = N("TextButton",{
            Size=UDim2.new(1,0,0,25), BackgroundTransparency=1,
            Text="", AutoButtonColor=false, Parent=list,
        })

        local box = N("Frame",{
            Position=UDim2.new(0,10,0.5,-6), Size=UDim2.new(0,12,0,12),
            BackgroundColor3=state and T.CheckActive or T.CheckBG,
            BorderSizePixel=0, Parent=row,
        })
        corner(2, box)
        stroke(T.CheckBorder, 1, box)

        local tick = N("TextLabel",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="✓", TextColor3=Color3.new(1,1,1), TextSize=9,
            Font=T.FontBold, Visible=state, Parent=box,
        })

        N("TextLabel",{
            Position=UDim2.new(0,28,0,0), Size=UDim2.new(1,-70,1,0),
            BackgroundTransparency=1, Text=label,
            TextColor3=T.Text, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })

        if key then
            local kb = N("TextLabel",{
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-8,0.5,0),
                Size=UDim2.new(0,28,0,15),
                BackgroundColor3=T.KeybindBG, BorderSizePixel=0,
                Text=key, TextColor3=T.TextDim, TextSize=10, Font=T.Font,
                TextXAlignment=Enum.TextXAlignment.Center, Parent=row,
            })
            corner(3, kb)
        end

        local function upd(anim)
            local ti = TweenInfo.new(anim and 0.13 or 0)
            TweenService:Create(box, ti, {BackgroundColor3=state and T.CheckActive or T.CheckBG}):Play()
            tick.Visible = state
        end

        row.MouseButton1Click:Connect(function()
            state = not state
            if flag then libRef.Cfg:Set(flag, state) end
            upd(true)
            task.spawn(cb, state)
        end)
        row.MouseEnter:Connect(function() tw(row,0.1,{BackgroundColor3=Color3.fromRGB(38,38,48)}) end)
        row.MouseLeave:Connect(function() tw(row,0.1,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)

        return {
            Set=function(_, v) state=v; if flag then libRef.Cfg:Set(flag,v) end; upd(true); task.spawn(cb,v) end,
            Get=function() return state end,
        }
    end

    -- ─── Slider ───
    function G:AddSlider(opts)
        opts = opts or {}
        local label = opts.Name     or "Value"
        local mn    = opts.Min      or 0
        local mx    = opts.Max      or 100
        local def   = opts.Default  or mn
        local dec   = opts.Decimals or 0
        local sfx   = opts.Suffix   or ""
        local flag  = opts.Flag
        local cb    = opts.Callback or function() end
        if flag then libRef.Cfg:Register(flag, def) end
        local val = math.clamp(def, mn, mx)

        local row = N("Frame",{Size=UDim2.new(1,0,0,38), BackgroundTransparency=1, Parent=list})

        N("TextLabel",{
            Position=UDim2.new(0,10,0,4), Size=UDim2.new(0.7,0,0,16),
            BackgroundTransparency=1, Text=label,
            TextColor3=T.Text, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })

        local fmt = dec>0 and ("%."..dec.."f") or "%d"
        local vlbl = N("TextLabel",{
            AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-8,0,4),
            Size=UDim2.new(0,40,0,16), BackgroundTransparency=1,
            Text=string.format(fmt,val)..sfx,
            TextColor3=T.TextDim, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=row,
        })

        local track = N("Frame",{
            Position=UDim2.new(0,10,0,26), Size=UDim2.new(1,-20,0,3),
            BackgroundColor3=T.SliderBG, BorderSizePixel=0, Parent=row,
        })
        corner(99, track)

        local fill = N("Frame",{
            Size=UDim2.new((val-mn)/(mx-mn),0,1,0),
            BackgroundColor3=T.SliderFill, BorderSizePixel=0, Parent=track,
        })
        corner(99, fill)

        local knob = N("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new((val-mn)/(mx-mn),0,0.5,0),
            Size=UDim2.new(0,9,0,9),
            BackgroundColor3=T.SliderFill, BorderSizePixel=0, ZIndex=2, Parent=track,
        })
        corner(99, knob)

        local function setV(sc)
            sc=math.clamp(sc,0,1)
            val=mn+(mx-mn)*sc
            local m=10^dec; val=math.floor(val*m+0.5)/m; val=math.clamp(val,mn,mx)
            vlbl.Text=string.format(fmt,val)..sfx
            TweenService:Create(fill, TweenInfo.new(0.04), {Size=UDim2.new(sc,0,1,0)}):Play()
            TweenService:Create(knob,TweenInfo.new(0.04), {Position=UDim2.new(sc,0,0.5,0)}):Play()
            if flag then libRef.Cfg:Set(flag,val) end
            task.spawn(cb,val)
        end

        local dn=false
        local hit=N("TextButton",{
            Position=UDim2.new(0,-2,0,-10), Size=UDim2.new(1,4,0,24),
            BackgroundTransparency=1, Text="", ZIndex=3, Parent=track,
        })
        hit.MouseButton1Down:Connect(function()
            dn=true; TweenService:Create(knob,TweenInfo.new(0.1),{Size=UDim2.new(0,11,0,11)}):Play()
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dn=false; TweenService:Create(knob,TweenInfo.new(0.1),{Size=UDim2.new(0,9,0,9)}):Play()
            end
        end)
        RunService.Heartbeat:Connect(function()
            if dn then
                local mx2=UserInputService:GetMouseLocation().X
                setV((mx2-track.AbsolutePosition.X)/track.AbsoluteSize.X)
            end
        end)

        return {
            Set=function(_,v) setV(math.clamp((v-mn)/(mx-mn),0,1)) end,
            Get=function() return val end,
        }
    end

    -- ─── Dropdown ───
    function G:AddDropdown(opts)
        opts = opts or {}
        local label = opts.Name     or "Select"
        local items = opts.Items    or {}
        local def   = opts.Default  or (items[1])
        local flag  = opts.Flag
        local cb    = opts.Callback or function() end
        if flag then libRef.Cfg:Register(flag, def) end
        local selected = def
        local open = false

        local wrap = N("Frame",{
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=list,
        })

        N("TextLabel",{
            Position=UDim2.new(0,10,0,2), Size=UDim2.new(1,-10,0,18),
            BackgroundTransparency=1, Text=label,
            TextColor3=T.Text, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap,
        })

        local dbox = N("TextButton",{
            Position=UDim2.new(0,8,0,22), Size=UDim2.new(1,-16,0,24),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Text="", AutoButtonColor=false, Parent=wrap,
        })
        corner(3, dbox); stroke(T.Border,1,dbox)

        local selLbl = N("TextLabel",{
            Position=UDim2.new(0,8,0,0), Size=UDim2.new(1,-26,1,0),
            BackgroundTransparency=1, Text=selected or "None",
            TextColor3=T.Text, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=dbox,
        })
        local arr = N("TextLabel",{
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-6,0.5,0),
            Size=UDim2.new(0,14,0,14), BackgroundTransparency=1,
            Text="▾", TextColor3=T.TextDim, TextSize=12, Font=T.FontBold, Parent=dbox,
        })

        local dlist = N("Frame",{
            Position=UDim2.new(0,8,0,48), Size=UDim2.new(1,-16,0,math.min(#items,5)*23+4),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Visible=false, ZIndex=20, ClipsDescendants=true, Parent=wrap,
        })
        corner(3,dlist); stroke(T.Border,1,dlist)
        N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=dlist})
        N("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,2),Parent=dlist})

        for _,item in ipairs(items) do
            local ib = N("TextButton",{
                Size=UDim2.new(1,0,0,23), BackgroundTransparency=1,
                Text=item, TextColor3=item==selected and T.Accent or T.Text,
                TextSize=11, Font=T.Font, AutoButtonColor=false, ZIndex=21, Parent=dlist,
            })
            N("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=ib})
            ib.TextXAlignment=Enum.TextXAlignment.Left
            ib.MouseEnter:Connect(function() TweenService:Create(ib,TweenInfo.new(0.1),{BackgroundColor3=T.DropHover}):Play() end)
            ib.MouseLeave:Connect(function() TweenService:Create(ib,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(0,0,0,0)}):Play() end)
            ib.MouseButton1Click:Connect(function()
                selected=item; selLbl.Text=item
                for _,ch in ipairs(dlist:GetChildren()) do
                    if ch:IsA("TextButton") then
                        TweenService:Create(ch,TweenInfo.new(0.12),{TextColor3=ch.Text==selected and T.Accent or T.Text}):Play()
                    end
                end
                open=false; dlist.Visible=false
                TweenService:Create(arr,TweenInfo.new(0.15),{Rotation=0}):Play()
                if flag then libRef.Cfg:Set(flag,selected) end
                task.spawn(cb,selected)
            end)
        end

        dbox.MouseButton1Click:Connect(function()
            open=not open; dlist.Visible=open
            TweenService:Create(arr,TweenInfo.new(0.2),{Rotation=open and 180 or 0}):Play()
        end)
        dbox.MouseEnter:Connect(function() TweenService:Create(dbox,TweenInfo.new(0.1),{BackgroundColor3=T.DropHover}):Play() end)
        dbox.MouseLeave:Connect(function() TweenService:Create(dbox,TweenInfo.new(0.1),{BackgroundColor3=T.DropBG}):Play() end)

        N("Frame",{Size=UDim2.new(1,0,0,6),BackgroundTransparency=1,Parent=wrap})

        return {
            Set=function(_,v)
                selected=v; selLbl.Text=v
                if flag then libRef.Cfg:Set(flag,v) end; task.spawn(cb,v)
            end,
            Get=function() return selected end,
        }
    end

    -- ─── Color Picker ───
    function G:AddColorPicker(opts)
        opts = opts or {}
        local label = opts.Name    or "Color"
        local def   = opts.Default or Color3.fromRGB(232,80,180)
        local flag  = opts.Flag
        local cb    = opts.Callback or function() end
        if flag then libRef.Cfg:Register(flag, {def.R,def.G,def.B}) end

        local cc = def
        local open = false
        local h,s,v = RGBtoHSV(def.R*255, def.G*255, def.B*255)

        local wrap = N("Frame",{
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Parent=list,
        })

        local row = N("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Parent=wrap})
        N("TextLabel",{
            Position=UDim2.new(0,10,0,0), Size=UDim2.new(1,-52,1,0),
            BackgroundTransparency=1, Text=label,
            TextColor3=T.Text, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })

        local swatch = N("TextButton",{
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
            Size=UDim2.new(0,38,0,14), BackgroundColor3=cc,
            BorderSizePixel=0, Text="", AutoButtonColor=false, Parent=row,
        })
        corner(3,swatch); stroke(T.Border,1,swatch)

        local panel = N("Frame",{
            Position=UDim2.new(0,8,0,28), Size=UDim2.new(1,-16,0,128),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Visible=false, ZIndex=15, Parent=wrap,
        })
        corner(4,panel); stroke(T.Border,1,panel)
        N("UIPadding",{PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),Parent=panel})

        -- SV canvas
        local svF = N("Frame",{
            Size=UDim2.new(1,0,0,76), BackgroundColor3=HSVtoRGB(h,1,1),
            BorderSizePixel=0, ClipsDescendants=true, ZIndex=16, Parent=panel,
        })
        corner(3,svF)
        local wf=N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=17,Parent=svF})
        N("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wf})
        local bf=N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=18,Parent=svF})
        N("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bf})

        local svK = N("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(s,0,1-v,0),
            Size=UDim2.new(0,8,0,8), BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0, ZIndex=20, Parent=svF,
        })
        corner(99,svK); stroke(Color3.new(0,0,0),1,svK)

        -- Hue bar
        local hBar = N("Frame",{
            Position=UDim2.new(0,0,0,82), Size=UDim2.new(1,0,0,7),
            BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, ZIndex=16, Parent=panel,
        })
        corner(99,hBar)
        N("UIGradient",{Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
        }),Parent=hBar})

        local hK = N("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(h,0,0.5,0),
            Size=UDim2.new(0,5,1,4), BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0, ZIndex=17, Parent=hBar,
        })
        corner(3,hK)

        -- Hex
        local hexRow = N("Frame",{
            Position=UDim2.new(0,0,0,95), Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1, ZIndex=16, Parent=panel,
        })
        N("TextLabel",{Size=UDim2.new(0,26,1,0),BackgroundTransparency=1,
            Text="HEX",TextColor3=T.TextMuted,TextSize=10,Font=T.FontBold,
            ZIndex=17,Parent=hexRow})
        local hexBox = N("TextBox",{
            Position=UDim2.new(0,30,0,2),Size=UDim2.new(1,-30,0,16),
            BackgroundColor3=T.CheckBG,BorderSizePixel=0,
            Text=toHex(cc),TextColor3=T.Text,TextSize=10,
            Font=Enum.Font.Code,PlaceholderText="#FFFFFF",
            ClearTextOnFocus=false,ZIndex=17,Parent=hexRow,
        })
        corner(3,hexBox)
        N("UIPadding",{PaddingLeft=UDim.new(0,5),Parent=hexBox})

        local function apply()
            cc = HSVtoRGB(h,s,v)
            swatch.BackgroundColor3 = cc
            svF.BackgroundColor3 = HSVtoRGB(h,1,1)
            svK.Position = UDim2.new(s,0,1-v,0)
            hK.Position  = UDim2.new(h,0,0.5,0)
            hexBox.Text  = toHex(cc)
            if flag then libRef.Cfg:Set(flag,{cc.R,cc.G,cc.B}) end
            task.spawn(cb,cc)
        end

        local svDn,hDn = false,false
        local svBtn = N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=21,Parent=svF})
        svBtn.MouseButton1Down:Connect(function() svDn=true end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDn=false;hDn=false end end)
        RunService.Heartbeat:Connect(function()
            if svDn then
                local m=UserInputService:GetMouseLocation()
                s=math.clamp((m.X-svF.AbsolutePosition.X)/svF.AbsoluteSize.X,0,1)
                v=1-math.clamp((m.Y-svF.AbsolutePosition.Y)/svF.AbsoluteSize.Y,0,1)
                apply()
            end
            if hDn then
                local m=UserInputService:GetMouseLocation()
                h=math.clamp((m.X-hBar.AbsolutePosition.X)/hBar.AbsoluteSize.X,0,1)
                apply()
            end
        end)

        local hBtn = N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=18,Parent=hBar})
        hBtn.MouseButton1Down:Connect(function() hDn=true end)

        hexBox.FocusLost:Connect(function()
            local ok,col = pcall(fromHex, hexBox.Text)
            if ok and col then
                h,s,v = RGBtoHSV(col.R*255,col.G*255,col.B*255); apply()
            end
        end)

        swatch.MouseButton1Click:Connect(function()
            open=not open; panel.Visible=open
        end)

        apply()
        N("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        return {
            Set=function(_,col) h,s,v=RGBtoHSV(col.R*255,col.G*255,col.B*255); apply() end,
            Get=function() return cc end,
        }
    end

    -- ─── Button ───
    function G:AddButton(opts)
        opts = opts or {}
        local label = opts.Name or "Button"
        local cb    = opts.Callback or function() end

        local btn = N("TextButton",{
            Size=UDim2.new(1,-16,0,22),
            BackgroundColor3=T.DropBG, BorderSizePixel=0,
            Text=label, TextColor3=T.Text, TextSize=11, Font=T.Font,
            AutoButtonColor=false, Parent=list,
        })
        N("UICorner",{CornerRadius=UDim.new(0,3),Parent=btn})
        stroke(T.Border,1,btn)
        N("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingTop=UDim.new(0,0),Parent=btn})
        btn.TextXAlignment=Enum.TextXAlignment.Left

        btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=T.DropHover}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=T.DropBG}):Play() end)
        btn.MouseButton1Click:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=T.AccentDark}):Play()
            task.delay(0.14,function() TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=T.DropBG}):Play() end)
            task.spawn(cb)
        end)
        N("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=list})
    end

    -- ─── Spacer ───
    function G:AddSpacer(h)
        N("Frame",{Size=UDim2.new(1,0,0,h or 5),BackgroundTransparency=1,Parent=list})
    end

    return G
end

-- ════════════════════════════════════════════
--  Column wrapper
-- ════════════════════════════════════════════
local function makeColWrapper(scrollF, libRef)
    local Col = {}
    function Col:AddGroup(name)
        return buildGroup(scrollF, libRef, name)
    end
    return Col
end

-- ════════════════════════════════════════════
--  LIBRARY  
-- ════════════════════════════════════════════
local Lib = {}
Lib.__index = Lib

function Lib.new(opts)
    opts = opts or {}
    local self  = setmetatable({}, Lib)
    self.Cfg    = ConfigClass.new(opts.Name or "NebulaUI")
    self.TKey   = opts.ToggleKey or Enum.KeyCode.RightShift
    self.Shown  = true
    self.Win    = {}

    self.Gui = N("ScreenGui",{
        Name="NebulaUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
    })
    pcall(function() self.Gui.Parent = CoreGui end)
    if not self.Gui.Parent then self.Gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Notification container
    self.NotifF = N("Frame",{
        Size=UDim2.new(0,290,1,0), Position=UDim2.new(1,-298,0,0),
        BackgroundTransparency=1, Parent=self.Gui,
    })
    N("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),Parent=self.NotifF})
    N("UIPadding",{PaddingBottom=UDim.new(0,14),Parent=self.NotifF})

    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.KeyCode==self.TKey then self:Toggle() end
    end)
    return self
end

function Lib:Toggle()
    self.Shown = not self.Shown
    for _,w in pairs(self.Win) do w.Root.Visible = self.Shown end
end

function Lib:GetFlag(f) return self.Cfg:Get(f) end
function Lib:SetFlag(f,v) self.Cfg:Set(f,v) end

function Lib:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notice"
    local body  = opts.Body  or ""
    local dur   = opts.Duration or 4
    local kind  = opts.Type or "Info"
    local ac    = {Info=T.Accent,Success=Color3.fromRGB(55,195,95),Warning=Color3.fromRGB(215,170,40),Error=Color3.fromRGB(215,55,55)}
    local col   = ac[kind] or T.Accent

    local f = N("Frame",{
        Size=UDim2.new(1,0,0,58), BackgroundColor3=T.Panel,
        BorderSizePixel=0, Parent=self.NotifF, ClipsDescendants=true,
    })
    corner(5,f); stroke(col,1,f)
    N("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=col,BorderSizePixel=0,Parent=f})
    N("TextLabel",{Position=UDim2.new(0,11,0,7),Size=UDim2.new(1,-13,0,17),
        BackgroundTransparency=1,Text=title,TextColor3=T.Text,TextSize=12,Font=T.FontBold,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    N("TextLabel",{Position=UDim2.new(0,11,0,24),Size=UDim2.new(1,-13,0,26),
        BackgroundTransparency=1,Text=body,TextColor3=T.TextDim,TextSize=11,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=f})
    local pb = N("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BackgroundColor3=col,BorderSizePixel=0,Parent=f})
    TweenService:Create(pb, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)}):Play()
    task.delay(dur, function()
        TweenService:Create(f, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.35); f:Destroy()
    end)
end

-- ════════════════════════════════════════════
--  CreateWindow
-- ════════════════════════════════════════════
function Lib:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "Script"
    local subtitle = opts.Subtitle or "stable"
    local user     = opts.User     or ""
    local size     = opts.Size     or UDim2.new(0,680,0,480)
    local pos      = opts.Position or UDim2.new(0.5,-340,0.5,-240)
    local libRef   = self

    local W = {Lib=self, Tabs={}, ActiveTab=nil}

    -- Root
    W.Root = N("Frame",{
        Name=title.."_Win", Size=size, Position=pos,
        BackgroundColor3=T.BG, BorderSizePixel=0,
        ClipsDescendants=false, Parent=self.Gui,
    })
    corner(7, W.Root)
    stroke(T.Border, 1, W.Root)

    -- Drop shadow
    N("ImageLabel",{
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,6),
        Size=UDim2.new(1,50,1,50),
        BackgroundTransparency=1,
        Image="rbxassetid://6014261993",
        ImageColor3=Color3.new(0,0,0),
        ImageTransparency=0.5,
        ScaleType=Enum.ScaleType.Slice,
        SliceCenter=Rect.new(49,49,450,450),
        ZIndex=-1, Parent=W.Root,
    })

    -- Clip frame for content (so shadow outside)
    local clipF = N("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ClipsDescendants=true, Parent=W.Root,
    })
    corner(7,clipF)

    -- Top bar
    local topBar = N("Frame",{
        Size=UDim2.new(1,0,0,30),
        BackgroundColor3=T.TopBar,
        BorderSizePixel=0, Parent=clipF,
    })

    -- Title  "Matcha › Comfort  stable"
    N("TextLabel",{
        Position=UDim2.new(0,12,0,0), Size=UDim2.new(0.8,0,1,0),
        BackgroundTransparency=1,
        Text=title.." › "..subtitle.."  ",
        TextColor3=T.TextDim, TextSize=12, Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar,
    })

    -- The "stable" badge in pink
    local stableW = #subtitle * 7
    local stableX = 12 + (#(title.." › ")+1)*7
    N("TextLabel",{
        Position=UDim2.new(0, stableX, 0,7),
        Size=UDim2.new(0,stableW+14,0,16),
        BackgroundColor3=Color3.fromRGB(50,28,42),
        BorderSizePixel=0,
        Text=subtitle, TextColor3=T.Accent, TextSize=10, Font=T.FontBold,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=2, Parent=topBar,
    }):FindFirstChildOfClass("UICorner") or corner(3, topBar:FindFirstChild("TextLabel",true) or topBar)

    -- Username
    if user ~= "" then
        N("TextLabel",{
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-40,0.5,0),
            Size=UDim2.new(0,120,0,20), BackgroundTransparency=1,
            Text=user, TextColor3=T.TextDim, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=topBar,
        })
    end

    -- Close button
    local closeBtn = N("TextButton",{
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.new(0,16,0,16), BackgroundColor3=Color3.fromRGB(195,50,50),
        BorderSizePixel=0, Text="", AutoButtonColor=false, Parent=topBar,
    })
    corner(99,closeBtn)
    closeBtn.MouseButton1Click:Connect(function() W.Root.Visible=false end)
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(235,65,65)}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(195,50,50)}):Play() end)

    drag(W.Root, topBar)

    -- Tab bar row
    local tabBarF = N("Frame",{
        Position=UDim2.new(0,0,0,30), Size=UDim2.new(1,0,0,34),
        BackgroundColor3=T.TabBarBG, BorderSizePixel=0, Parent=clipF,
    })
    N("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Border,BorderSizePixel=0,Parent=tabBarF})

    local tabBtnHolder = N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=tabBarF})
    N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=tabBtnHolder})
    N("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),Parent=tabBtnHolder})

    -- Content area
    local contentHolder = N("Frame",{
        Position=UDim2.new(0,0,0,64),
        Size=UDim2.new(1,0,1,-64),
        BackgroundTransparency=1, ClipsDescendants=true,
        Parent=clipF,
    })

    -- ════ AddTab ════
    function W:AddTab(name)
        local Tab = {Window=W, SubTabs={}, ActiveSubTab=nil}

        -- Tab button
        local btn = N("TextButton",{
            Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(0,0,0,0), BorderSizePixel=0,
            Text=name, TextColor3=T.TextDim, TextSize=12, Font=T.Font,
            AutoButtonColor=false, Parent=tabBtnHolder,
        })
        N("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),Parent=btn})

        -- Active indicator line at bottom
        local indicator = N("Frame",{
            AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(0,0,0,2), BackgroundColor3=T.Accent,
            BorderSizePixel=0, Parent=btn,
        })
        corner(99,indicator)

        -- Tab content
        local content = N("Frame",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Visible=false, Parent=contentHolder,
        })

        -- Sub-tab bar
        local subBarF = N("Frame",{
            Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, Parent=content,
        })
        N("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,18),Parent=subBarF})
        N("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),Parent=subBarF})

        -- Two column area
        local colArea = N("Frame",{
            Position=UDim2.new(0,0,0,28),
            Size=UDim2.new(1,0,1,-28),
            BackgroundTransparency=1, Parent=content,
        })

        -- Default columns (used when no sub-tabs)
        local defColL = N("ScrollingFrame",{
            Position=UDim2.new(0,8,0,6), Size=UDim2.new(0.5,-12,1,-12),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=2, ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=colArea,
        })
        N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=defColL})

        local defColR = N("ScrollingFrame",{
            Position=UDim2.new(0.5,4,0,6), Size=UDim2.new(0.5,-12,1,-12),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=2, ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=colArea,
        })
        N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=defColR})

        Tab.Content  = content
        Tab.SubBarF  = subBarF
        Tab.ColArea  = colArea
        Tab.Btn      = btn
        Tab.Indicator= indicator

        local function activate()
            for _,t in pairs(W.Tabs) do
                t.Content.Visible = false
                TweenService:Create(t.Btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(0,0,0,0),TextColor3=T.TextDim}):Play()
                TweenService:Create(t.Indicator,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,2)}):Play()
            end
            content.Visible = true
            TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=T.TabActive,TextColor3=T.Text}):Play()
            -- Animate indicator width
            task.spawn(function()
                task.wait()
                local tw2 = btn.AbsoluteSize.X
                TweenService:Create(indicator,TweenInfo.new(0.22),{Size=UDim2.new(0,tw2,0,2)}):Play()
            end)
            W.ActiveTab = Tab
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function() if W.ActiveTab~=Tab then TweenService:Create(btn,TweenInfo.new(0.1),{TextColor3=T.Text}):Play() end end)
        btn.MouseLeave:Connect(function() if W.ActiveTab~=Tab then TweenService:Create(btn,TweenInfo.new(0.1),{TextColor3=T.TextDim}):Play() end end)

        table.insert(W.Tabs, Tab)
        if #W.Tabs == 1 then activate() end

        -- GetColumns (default, no sub-tabs)
        function Tab:GetColumns()
            return makeColWrapper(defColL, libRef), makeColWrapper(defColR, libRef)
        end

        -- AddSubTab
        function Tab:AddSubTab(subName)
            local ST = {Tab=self}

            local sbtn = N("TextButton",{
                Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
                BackgroundTransparency=1, BorderSizePixel=0,
                Text=subName, TextColor3=T.SubInactive, TextSize=12, Font=T.Font,
                AutoButtonColor=false, Parent=subBarF,
            })
            local suline = N("Frame",{
                AnchorPoint=Vector2.new(0,1), Position=UDim2.new(0,0,1,0),
                Size=UDim2.new(0,0,0,1), BackgroundColor3=T.Accent,
                BorderSizePixel=0, Parent=sbtn,
            })

            -- Sub-tab columns
            local scL = N("ScrollingFrame",{
                Position=UDim2.new(0,8,0,6), Size=UDim2.new(0.5,-12,1,-12),
                BackgroundTransparency=1, BorderSizePixel=0,
                ScrollBarThickness=2, ScrollBarImageColor3=T.Accent,
                CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false, Parent=colArea,
            })
            N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=scL})

            local scR = N("ScrollingFrame",{
                Position=UDim2.new(0.5,4,0,6), Size=UDim2.new(0.5,-12,1,-12),
                BackgroundTransparency=1, BorderSizePixel=0,
                ScrollBarThickness=2, ScrollBarImageColor3=T.Accent,
                CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false, Parent=colArea,
            })
            N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=scR})

            ST.Btn  = sbtn
            ST.ULine= suline
            ST.ColL = scL
            ST.ColR = scR

            local function activateSub()
                -- hide default cols
                defColL.Visible = false; defColR.Visible = false
                for _,st in pairs(self.SubTabs) do
                    TweenService:Create(st.Btn,TweenInfo.new(0.13),{TextColor3=T.SubInactive}):Play()
                    TweenService:Create(st.ULine,TweenInfo.new(0.15),{Size=UDim2.new(0,0,0,1)}):Play()
                    st.ColL.Visible=false; st.ColR.Visible=false
                end
                TweenService:Create(sbtn,TweenInfo.new(0.13),{TextColor3=T.SubActive}):Play()
                task.spawn(function()
                    task.wait()
                    TweenService:Create(suline,TweenInfo.new(0.2),{Size=UDim2.new(0,sbtn.AbsoluteSize.X,0,1)}):Play()
                end)
                scL.Visible=true; scR.Visible=true
                self.ActiveSubTab=ST
            end

            sbtn.MouseButton1Click:Connect(activateSub)
            sbtn.MouseEnter:Connect(function() if self.ActiveSubTab~=ST then TweenService:Create(sbtn,TweenInfo.new(0.1),{TextColor3=T.Text}):Play() end end)
            sbtn.MouseLeave:Connect(function() if self.ActiveSubTab~=ST then TweenService:Create(sbtn,TweenInfo.new(0.1),{TextColor3=T.SubInactive}):Play() end end)

            table.insert(self.SubTabs, ST)
            if #self.SubTabs==1 then activateSub() end

            function ST:GetColumns()
                return makeColWrapper(scL, libRef), makeColWrapper(scR, libRef)
            end

            return ST
        end

        return Tab
    end

    table.insert(self.Win, W)
    return W
end

return Lib
