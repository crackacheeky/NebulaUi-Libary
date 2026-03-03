-- NebulaUI v2.1 | Matcha/Comfort Style
-- Fixed version: proper parenting, no ClipsDescendants on root, return fixed

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

local T = {
    BG          = Color3.fromRGB(20, 20, 24),
    GroupBG     = Color3.fromRGB(30, 30, 36),
    TopBar      = Color3.fromRGB(15, 15, 18),
    TabBar      = Color3.fromRGB(20, 20, 24),
    TabActive   = Color3.fromRGB(34, 34, 42),
    Accent      = Color3.fromRGB(232, 80, 180),
    AccentDark  = Color3.fromRGB(155, 45, 120),
    SubOn       = Color3.fromRGB(232, 80, 180),
    SubOff      = Color3.fromRGB(110, 110, 130),
    SliderBG    = Color3.fromRGB(45, 45, 55),
    SliderFill  = Color3.fromRGB(232, 80, 180),
    CheckBG     = Color3.fromRGB(38, 38, 48),
    CheckOn     = Color3.fromRGB(232, 80, 180),
    CheckBorder = Color3.fromRGB(68, 68, 86),
    DropBG      = Color3.fromRGB(34, 34, 42),
    DropHover   = Color3.fromRGB(44, 44, 54),
    Border      = Color3.fromRGB(44, 44, 56),
    Text        = Color3.fromRGB(220, 220, 230),
    TextDim     = Color3.fromRGB(130, 130, 148),
    TextMuted   = Color3.fromRGB(75, 75, 92),
    KbBG        = Color3.fromRGB(38, 38, 50),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
}

-- ─── Utility ───────────────────────────────────────────
local function Tween(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function Make(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then o[k] = v end
    end
    if props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(r, p)   Make("UICorner",  {CornerRadius=UDim.new(0,r), Parent=p}) end
local function Stroke(c,t,p)  Make("UIStroke",  {Color=c, Thickness=t, Parent=p}) end
local function Pad(a,b,c,d,p) Make("UIPadding", {PaddingTop=UDim.new(0,a),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,c),PaddingRight=UDim.new(0,d),Parent=p}) end
local function List(p,gap,dir)
    Make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,gap or 0),
        FillDirection=dir or Enum.FillDirection.Vertical,Parent=p})
end

local function Drag(frame, handle)
    local dn,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dn,ds,sp=true,i.Position,frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dn and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dn=false end
    end)
end

-- HSV helpers
local function HSV(h,s,v)
    if s==0 then return Color3.new(v,v,v) end
    local i=math.floor(h*6); local f=h*6-i
    local p,q,t2=v*(1-s),v*(1-f*s),v*(1-(1-f)*s)
    i=i%6
    if i==0 then return Color3.new(v,t2,p)
    elseif i==1 then return Color3.new(q,v,p)
    elseif i==2 then return Color3.new(p,v,t2)
    elseif i==3 then return Color3.new(p,q,v)
    elseif i==4 then return Color3.new(t2,p,v)
    else return Color3.new(v,p,q) end
end
local function toHSV(c)
    local r,g,b=c.R,c.G,c.B
    local mx,mn=math.max(r,g,b),math.min(r,g,b)
    local h,s,v=0,0,mx; local d=mx-mn
    s=mx==0 and 0 or d/mx
    if mx~=mn then
        if mx==r then h=(g-b)/d+(g<b and 6 or 0)
        elseif mx==g then h=(b-r)/d+2
        else h=(r-g)/d+4 end
        h=h/6
    end
    return h,s,v
end
local function Hex(c) return string.format("#%02X%02X%02X",c.R*255,c.G*255,c.B*255) end
local function fromHex(s)
    s=s:gsub("#","")
    if #s~=6 then return Color3.new(1,1,1) end
    return Color3.fromRGB(tonumber(s:sub(1,2),16)or 255,tonumber(s:sub(3,4),16)or 255,tonumber(s:sub(5,6),16)or 255)
end

-- ─── Config ────────────────────────────────────────────
local Cfg={}; Cfg.__index=Cfg
function Cfg.new(n) return setmetatable({n=n,d={}},Cfg) end
function Cfg:reg(f,v) if self.d[f]==nil then self.d[f]=v end end
function Cfg:set(f,v) self.d[f]=v end
function Cfg:get(f)   return self.d[f] end
function Cfg:save(n)
    local ok,e=pcall(writefile,self.n.."_"..n..".json",HttpService:JSONEncode(self.d))
    return ok, ok and "Saved: "..n or tostring(e)
end
function Cfg:load(n)
    local ok,d=pcall(readfile,self.n.."_"..n..".json")
    if ok then for k,v in pairs(HttpService:JSONDecode(d)) do self.d[k]=v end end
    return ok, ok and "Loaded: "..n or "File not found"
end

-- ═══════════════════════════════════════════════════════
--  GROUP BUILDER  (shared by columns)
-- ═══════════════════════════════════════════════════════
local function buildGroup(scroll, cfg, name)
    local G={}

    local frame=Make("Frame",{
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.GroupBG, BorderSizePixel=0, Parent=scroll,
    })
    Corner(5,frame)

    -- header
    Make("TextLabel",{
        Size=UDim2.new(1,0,0,24), BackgroundColor3=Color3.fromRGB(26,26,32),
        BorderSizePixel=0, Text=name, TextColor3=T.TextDim,
        TextSize=10, Font=T.FontBold, TextXAlignment=Enum.TextXAlignment.Left,
        Parent=frame,
    })
    Pad(0,0,10,0, frame:FindFirstChildOfClass("TextLabel"))
    Corner(5, frame:FindFirstChildOfClass("TextLabel"))

    local body=Make("Frame",{
        Position=UDim2.new(0,0,0,24),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Parent=frame,
    })
    List(body, 0)
    Pad(0,6,0,0,body)

    -- ── Checkbox ──────────────────────────────────────
    function G:AddCheckbox(o)
        local label=o.Name or "Option"; local def=o.Default or false
        local flag=o.Flag; local kb=o.Keybind; local cb=o.Callback or function()end
        if flag then cfg:reg(flag,def) end
        local state=def

        local row=Make("TextButton",{
            Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
            Text="", AutoButtonColor=false, Parent=body,
        })

        local box=Make("Frame",{
            Position=UDim2.new(0,8,0.5,-6), Size=UDim2.new(0,12,0,12),
            BackgroundColor3=state and T.CheckOn or T.CheckBG,
            BorderSizePixel=0, Parent=row,
        })
        Corner(2,box); Stroke(T.CheckBorder,1,box)

        local tick=Make("TextLabel",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="✓", TextColor3=Color3.new(1,1,1), TextSize=9,
            Font=T.FontBold, Visible=state, Parent=box,
        })

        Make("TextLabel",{
            Position=UDim2.new(0,26,0,0), Size=UDim2.new(1,-70,1,0),
            BackgroundTransparency=1, Text=label, TextColor3=T.Text,
            TextSize=11, Font=T.Font, TextXAlignment=Enum.TextXAlignment.Left,
            Parent=row,
        })

        if kb then
            local k=Make("TextLabel",{
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-6,0.5,0),
                Size=UDim2.new(0,26,0,14), BackgroundColor3=T.KbBG,
                BorderSizePixel=0, Text=kb, TextColor3=T.TextDim,
                TextSize=9, Font=T.Font, Parent=row,
            })
            Corner(3,k)
        end

        local function upd(anim)
            local ti=TweenInfo.new(anim and 0.13 or 0)
            TweenService:Create(box,ti,{BackgroundColor3=state and T.CheckOn or T.CheckBG}):Play()
            tick.Visible=state
        end

        row.MouseButton1Click:Connect(function()
            state=not state
            if flag then cfg:set(flag,state) end
            upd(true); task.spawn(cb,state)
        end)
        row.MouseEnter:Connect(function()  Tween(row,0.1,{BackgroundColor3=Color3.fromRGB(36,36,46)}) end)
        row.MouseLeave:Connect(function()  Tween(row,0.1,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)

        return {
            Set=function(_,v) state=v; if flag then cfg:set(flag,v)end; upd(true); task.spawn(cb,v) end,
            Get=function() return state end,
        }
    end

    -- ── Slider ────────────────────────────────────────
    function G:AddSlider(o)
        local label=o.Name or "Value"; local mn=o.Min or 0; local mx=o.Max or 100
        local def=o.Default or mn; local dec=o.Decimals or 0; local sfx=o.Suffix or ""
        local flag=o.Flag; local cb=o.Callback or function()end
        if flag then cfg:reg(flag,def) end
        local val=math.clamp(def,mn,mx)

        local row=Make("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,Parent=body})

        Make("TextLabel",{
            Position=UDim2.new(0,8,0,4), Size=UDim2.new(0.65,0,0,16),
            BackgroundTransparency=1, Text=label, TextColor3=T.Text,
            TextSize=11, Font=T.Font, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
        })

        local fmt=dec>0 and ("%."..dec.."f") or "%d"
        local vl=Make("TextLabel",{
            AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-8,0,4),
            Size=UDim2.new(0,44,0,16), BackgroundTransparency=1,
            Text=string.format(fmt,val)..sfx,
            TextColor3=T.TextDim, TextSize=11, Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=row,
        })

        local track=Make("Frame",{
            Position=UDim2.new(0,8,0,26), Size=UDim2.new(1,-16,0,3),
            BackgroundColor3=T.SliderBG, BorderSizePixel=0, Parent=row,
        })
        Corner(99,track)

        local fill=Make("Frame",{
            Size=UDim2.new((val-mn)/(mx-mn),0,1,0),
            BackgroundColor3=T.SliderFill, BorderSizePixel=0, Parent=track,
        })
        Corner(99,fill)

        local knob=Make("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new((val-mn)/(mx-mn),0,0.5,0),
            Size=UDim2.new(0,9,0,9), BackgroundColor3=T.SliderFill,
            BorderSizePixel=0, ZIndex=2, Parent=track,
        })
        Corner(99,knob)

        local function setV(sc)
            sc=math.clamp(sc,0,1)
            local m=10^dec
            val=math.floor((mn+(mx-mn)*sc)*m+0.5)/m
            val=math.clamp(val,mn,mx)
            vl.Text=string.format(fmt,val)..sfx
            TweenService:Create(fill, TweenInfo.new(0.04),{Size=UDim2.new(sc,0,1,0)}):Play()
            TweenService:Create(knob,TweenInfo.new(0.04),{Position=UDim2.new(sc,0,0.5,0)}):Play()
            if flag then cfg:set(flag,val) end
            task.spawn(cb,val)
        end

        local dn=false
        local hit=Make("TextButton",{
            Position=UDim2.new(0,-2,0,-10),Size=UDim2.new(1,4,0,24),
            BackgroundTransparency=1,Text="",ZIndex=3,Parent=track,
        })
        hit.MouseButton1Down:Connect(function()
            dn=true; TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,11,0,11)}):Play()
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dn=false; TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,9,0,9)}):Play()
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

    -- ── Dropdown ──────────────────────────────────────
    function G:AddDropdown(o)
        local label=o.Name or "Select"; local items=o.Items or {}
        local def=o.Default or items[1]; local flag=o.Flag; local cb=o.Callback or function()end
        if flag then cfg:reg(flag,def) end
        local sel=def; local open=false

        local wrap=Make("Frame",{
            Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,Parent=body,
        })

        Make("TextLabel",{
            Position=UDim2.new(0,8,0,2),Size=UDim2.new(1,-8,0,18),
            BackgroundTransparency=1,Text=label,TextColor3=T.Text,
            TextSize=11,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap,
        })

        local dbox=Make("TextButton",{
            Position=UDim2.new(0,6,0,22),Size=UDim2.new(1,-12,0,24),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,
            Text="",AutoButtonColor=false,Parent=wrap,
        })
        Corner(3,dbox); Stroke(T.Border,1,dbox)

        local slbl=Make("TextLabel",{
            Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-24,1,0),
            BackgroundTransparency=1,Text=sel or "None",
            TextColor3=T.Text,TextSize=11,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=dbox,
        })
        local arr=Make("TextLabel",{
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),
            Size=UDim2.new(0,14,0,14),BackgroundTransparency=1,
            Text="▾",TextColor3=T.TextDim,TextSize=12,Font=T.FontBold,Parent=dbox,
        })

        local ih=math.min(#items,6)*22+4
        local dlist=Make("Frame",{
            Position=UDim2.new(0,6,0,48),Size=UDim2.new(1,-12,0,ih),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,
            Visible=false,ZIndex=50,Parent=wrap,
        })
        Corner(3,dlist); Stroke(T.Border,1,dlist)
        List(dlist,0)
        Pad(2,2,0,0,dlist)

        for _,item in ipairs(items) do
            local ib=Make("TextButton",{
                Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
                Text=item,TextColor3=item==sel and T.Accent or T.Text,
                TextSize=11,Font=T.Font,AutoButtonColor=false,ZIndex=51,Parent=dlist,
            })
            ib.TextXAlignment=Enum.TextXAlignment.Left
            Pad(0,0,10,0,ib)
            ib.MouseEnter:Connect(function() Tween(ib,0.08,{BackgroundColor3=T.DropHover}) end)
            ib.MouseLeave:Connect(function() Tween(ib,0.08,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)
            ib.MouseButton1Click:Connect(function()
                sel=item; slbl.Text=item
                for _,ch in ipairs(dlist:GetChildren()) do
                    if ch:IsA("TextButton") then
                        Tween(ch,0.1,{TextColor3=ch.Text==sel and T.Accent or T.Text})
                    end
                end
                open=false; dlist.Visible=false
                Tween(arr,0.15,{Rotation=0})
                if flag then cfg:set(flag,sel) end
                task.spawn(cb,sel)
            end)
        end

        dbox.MouseButton1Click:Connect(function()
            open=not open; dlist.Visible=open
            Tween(arr,0.15,{Rotation=open and 180 or 0})
        end)
        dbox.MouseEnter:Connect(function() Tween(dbox,0.08,{BackgroundColor3=T.DropHover}) end)
        dbox.MouseLeave:Connect(function() Tween(dbox,0.08,{BackgroundColor3=T.DropBG}) end)

        Make("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        return {
            Set=function(_,v) sel=v; slbl.Text=v; if flag then cfg:set(flag,v)end; task.spawn(cb,v) end,
            Get=function() return sel end,
        }
    end

    -- ── Color Picker ──────────────────────────────────
    function G:AddColorPicker(o)
        local label=o.Name or "Color"; local def=o.Default or Color3.fromRGB(232,80,180)
        local flag=o.Flag; local cb=o.Callback or function()end
        if flag then cfg:reg(flag,{def.R,def.G,def.B}) end
        local cc=def; local open=false
        local h,s,v=toHSV(cc)

        local wrap=Make("Frame",{
            Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,Parent=body,
        })

        local row=Make("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Parent=wrap})
        Make("TextLabel",{
            Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-52,1,0),
            BackgroundTransparency=1,Text=label,TextColor3=T.Text,
            TextSize=11,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=row,
        })

        local sw=Make("TextButton",{
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
            Size=UDim2.new(0,36,0,14),BackgroundColor3=cc,
            BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=row,
        })
        Corner(3,sw); Stroke(T.Border,1,sw)

        local panel=Make("Frame",{
            Position=UDim2.new(0,6,0,28),Size=UDim2.new(1,-12,0,124),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,
            Visible=false,ZIndex=30,Parent=wrap,
        })
        Corner(4,panel); Stroke(T.Border,1,panel)
        Pad(6,6,6,6,panel)

        -- SV canvas
        local sv=Make("Frame",{
            Size=UDim2.new(1,0,0,72),BackgroundColor3=HSV(h,1,1),
            BorderSizePixel=0,ClipsDescendants=true,ZIndex=31,Parent=panel,
        })
        Corner(3,sv)
        local wf=Make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=32,Parent=sv})
        Make("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wf})
        local bf=Make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=33,Parent=sv})
        Make("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bf})
        local sk=Make("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(s,0,1-v,0),
            Size=UDim2.new(0,8,0,8),BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,ZIndex=35,Parent=sv,
        })
        Corner(99,sk); Stroke(Color3.new(0,0,0),1.5,sk)

        -- Hue bar
        local hb=Make("Frame",{
            Position=UDim2.new(0,0,0,78),Size=UDim2.new(1,0,0,7),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=31,Parent=panel,
        })
        Corner(99,hb)
        Make("UIGradient",{Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
        }),Parent=hb})
        local hk=Make("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(h,0,0.5,0),
            Size=UDim2.new(0,5,1,4),BackgroundColor3=Color3.new(1,1,1),
            BorderSizePixel=0,ZIndex=32,Parent=hb,
        })
        Corner(3,hk)

        -- Hex input
        local hexrow=Make("Frame",{
            Position=UDim2.new(0,0,0,91),Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1,ZIndex=31,Parent=panel,
        })
        Make("TextLabel",{Size=UDim2.new(0,24,1,0),BackgroundTransparency=1,
            Text="HEX",TextColor3=T.TextMuted,TextSize=10,Font=T.FontBold,ZIndex=32,Parent=hexrow})
        local hbox=Make("TextBox",{
            Position=UDim2.new(0,28,0,2),Size=UDim2.new(1,-28,0,16),
            BackgroundColor3=T.CheckBG,BorderSizePixel=0,
            Text=Hex(cc),TextColor3=T.Text,TextSize=10,Font=Enum.Font.Code,
            PlaceholderText="#FFFFFF",ClearTextOnFocus=false,ZIndex=32,Parent=hexrow,
        })
        Corner(3,hbox); Pad(0,0,5,0,hbox)

        local function apply()
            cc=HSV(h,s,v); sw.BackgroundColor3=cc
            sv.BackgroundColor3=HSV(h,1,1)
            sk.Position=UDim2.new(s,0,1-v,0)
            hk.Position=UDim2.new(h,0,0.5,0)
            hbox.Text=Hex(cc)
            if flag then cfg:set(flag,{cc.R,cc.G,cc.B}) end
            task.spawn(cb,cc)
        end

        local svDn,hDn=false,false
        local svbtn=Make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=36,Parent=sv})
        svbtn.MouseButton1Down:Connect(function() svDn=true end)
        local hbtn=Make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=33,Parent=hb})
        hbtn.MouseButton1Down:Connect(function() hDn=true end)

        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then svDn=false; hDn=false end
        end)
        RunService.Heartbeat:Connect(function()
            if svDn then
                local m=UserInputService:GetMouseLocation()
                s=math.clamp((m.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1)
                v=1-math.clamp((m.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1)
                apply()
            end
            if hDn then
                local m=UserInputService:GetMouseLocation()
                h=math.clamp((m.X-hb.AbsolutePosition.X)/hb.AbsoluteSize.X,0,1)
                apply()
            end
        end)
        hbox.FocusLost:Connect(function()
            local ok,c=pcall(fromHex,hbox.Text)
            if ok then h,s,v=toHSV(c); apply() end
        end)

        sw.MouseButton1Click:Connect(function() open=not open; panel.Visible=open end)
        apply()
        Make("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        return {
            Set=function(_,c) h,s,v=toHSV(c); apply() end,
            Get=function() return cc end,
        }
    end

    -- ── Button ────────────────────────────────────────
    function G:AddButton(o)
        local label=o.Name or "Button"; local cb=o.Callback or function()end

        local btn=Make("TextButton",{
            Size=UDim2.new(1,-12,0,22),BackgroundColor3=T.DropBG,
            BorderSizePixel=0,Text=label,TextColor3=T.Text,
            TextSize=11,Font=T.Font,AutoButtonColor=false,Parent=body,
        })
        btn.TextXAlignment=Enum.TextXAlignment.Left
        Corner(3,btn); Stroke(T.Border,1,btn)
        Pad(0,0,8,0,btn)

        btn.MouseEnter:Connect(function() Tween(btn,0.08,{BackgroundColor3=T.DropHover}) end)
        btn.MouseLeave:Connect(function() Tween(btn,0.08,{BackgroundColor3=T.DropBG}) end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn,0.06,{BackgroundColor3=T.AccentDark})
            task.delay(0.12,function() Tween(btn,0.1,{BackgroundColor3=T.DropBG}) end)
            task.spawn(cb)
        end)
        Make("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=body})
    end

    -- ── Spacer ────────────────────────────────────────
    function G:AddSpacer(h)
        Make("Frame",{Size=UDim2.new(1,0,0,h or 4),BackgroundTransparency=1,Parent=body})
    end

    return G
end

-- column wrapper
local function Col(scroll, cfg)
    local C={}
    function C:AddGroup(name) return buildGroup(scroll,cfg,name) end
    return C
end

-- ═══════════════════════════════════════════════════════
--  LIBRARY
-- ═══════════════════════════════════════════════════════
local NebulaUI={}; NebulaUI.__index=NebulaUI

function NebulaUI.new(opts)
    opts=opts or {}
    local self=setmetatable({},NebulaUI)
    self.Cfg=Cfg.new(opts.Name or "NebulaUI")
    self.TKey=opts.ToggleKey or Enum.KeyCode.RightShift
    self.Shown=true
    self.Windows={}

    -- Create ScreenGui
    local sg=Instance.new("ScreenGui")
    sg.Name="NebulaUI"
    sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=999
    sg.IgnoreGuiInset=true

    local ok=pcall(function() sg.Parent=CoreGui end)
    if not ok or not sg.Parent then
        sg.Parent=LP:WaitForChild("PlayerGui")
    end
    self.Gui=sg

    -- Notification frame
    self.NF=Make("Frame",{
        Size=UDim2.new(0,280,1,0),Position=UDim2.new(1,-288,0,0),
        BackgroundTransparency=1,Parent=sg,
    })
    Make("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6),Parent=self.NF})
    Pad(0,12,0,0,self.NF)

    UserInputService.InputBegan:Connect(function(i,gp)
        if not gp and i.KeyCode==self.TKey then self:Toggle() end
    end)
    return self
end

function NebulaUI:Toggle()
    self.Shown=not self.Shown
    for _,w in pairs(self.Windows) do w.Root.Visible=self.Shown end
end
function NebulaUI:GetFlag(f) return self.Cfg:get(f) end
function NebulaUI:SetFlag(f,v) self.Cfg:set(f,v) end

function NebulaUI:Notify(o)
    o=o or {}
    local title=o.Title or "Notice"; local body=o.Body or ""
    local dur=o.Duration or 4; local kind=o.Type or "Info"
    local ac={Info=T.Accent,Success=Color3.fromRGB(50,195,90),Warning=Color3.fromRGB(210,170,38),Error=Color3.fromRGB(210,52,52)}
    local col=ac[kind] or T.Accent

    local f=Make("Frame",{
        Size=UDim2.new(1,0,0,56),BackgroundColor3=Color3.fromRGB(26,26,32),
        BorderSizePixel=0,Parent=self.NF,ClipsDescendants=true,
    })
    Corner(5,f); Stroke(col,1,f)
    Make("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=col,BorderSizePixel=0,Parent=f})
    Make("TextLabel",{Position=UDim2.new(0,11,0,7),Size=UDim2.new(1,-13,0,16),
        BackgroundTransparency=1,Text=title,TextColor3=T.Text,TextSize=12,Font=T.FontBold,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    Make("TextLabel",{Position=UDim2.new(0,11,0,23),Size=UDim2.new(1,-13,0,26),
        BackgroundTransparency=1,Text=body,TextColor3=T.TextDim,TextSize=11,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=f})
    local pb=Make("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),
        BackgroundColor3=col,BorderSizePixel=0,Parent=f})
    TweenService:Create(pb,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2)}):Play()
    task.delay(dur,function()
        TweenService:Create(f,TweenInfo.new(0.28),{Size=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.3); f:Destroy()
    end)
end

-- ── CreateWindow ────────────────────────────────────────
function NebulaUI:CreateWindow(opts)
    opts=opts or {}
    local title=opts.Title or "Script"
    local subtitle=opts.Subtitle or "stable"
    local user=opts.User or ""
    local size=opts.Size or UDim2.new(0,680,0,480)
    local pos=opts.Position or UDim2.new(0.5,-340,0.5,-240)
    local cfg=self.Cfg

    local W={Lib=self,Tabs={},ActiveTab=nil}

    -- Root (NO ClipsDescendants so dropdowns show outside groups)
    W.Root=Make("Frame",{
        Name=title.."_Win",Size=size,Position=pos,
        BackgroundColor3=T.BG,BorderSizePixel=0,Parent=self.Gui,
    })
    Corner(7,W.Root)
    Stroke(T.Border,1,W.Root)

    -- Everything inside a clip frame
    local clip=Make("Frame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        ClipsDescendants=true,Parent=W.Root,
    })
    Corner(7,clip)

    -- Top bar
    local top=Make("Frame",{
        Size=UDim2.new(1,0,0,30),BackgroundColor3=T.TopBar,BorderSizePixel=0,Parent=clip,
    })

    -- Title left
    Make("TextLabel",{
        Position=UDim2.new(0,12,0,0),Size=UDim2.new(0.5,0,1,0),
        BackgroundTransparency=1,
        Text=title.."  ",
        TextColor3=T.TextDim,TextSize=12,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=top,
    })
    -- Subtitle badge (pink)
    Make("Frame",{
        Position=UDim2.new(0,12+(#title+2)*7,0,8),
        Size=UDim2.new(0,#subtitle*7+10,0,14),
        BackgroundColor3=Color3.fromRGB(55,22,44),BorderSizePixel=0,Parent=top,
    })
    do
        local sb=top:FindFirstChildOfClass("Frame")
        if sb then
            Corner(3,sb)
            Make("TextLabel",{
                Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                Text=subtitle,TextColor3=T.Accent,TextSize=10,Font=T.FontBold,Parent=sb,
            })
        end
    end
    -- User
    if user~="" then
        Make("TextLabel",{
            AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-36,0.5,0),
            Size=UDim2.new(0,120,0,20),BackgroundTransparency=1,
            Text=user,TextColor3=T.TextDim,TextSize=11,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right,Parent=top,
        })
    end
    -- Close
    local cb2=Make("TextButton",{
        AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.new(0,15,0,15),BackgroundColor3=Color3.fromRGB(190,48,48),
        BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=top,
    })
    Corner(99,cb2)
    cb2.MouseButton1Click:Connect(function() W.Root.Visible=false end)
    cb2.MouseEnter:Connect(function() Tween(cb2,0.1,{BackgroundColor3=Color3.fromRGB(230,60,60)}) end)
    cb2.MouseLeave:Connect(function() Tween(cb2,0.1,{BackgroundColor3=Color3.fromRGB(190,48,48)}) end)

    Drag(W.Root, top)

    -- Tab bar
    local tbar=Make("Frame",{
        Position=UDim2.new(0,0,0,30),Size=UDim2.new(1,0,0,32),
        BackgroundColor3=T.TabBar,BorderSizePixel=0,Parent=clip,
    })
    Make("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
        BackgroundColor3=T.Border,BorderSizePixel=0,Parent=tbar})
    local tbholder=Make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=tbar})
    List(tbholder,0,Enum.FillDirection.Horizontal)
    Pad(0,0,8,8,tbholder)

    -- Content
    local content=Make("Frame",{
        Position=UDim2.new(0,0,0,62),Size=UDim2.new(1,0,1,-62),
        BackgroundTransparency=1,Parent=clip,
    })

    -- ── AddTab ──────────────────────────────────────────
    function W:AddTab(name)
        local Tab={Window=W,SubTabs={},ActiveSubTab=nil}

        local btn=Make("TextButton",{
            Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(0,0,0,0),BorderSizePixel=0,
            Text=name,TextColor3=T.TextDim,TextSize=12,Font=T.Font,
            AutoButtonColor=false,Parent=tbholder,
        })
        Pad(0,0,12,12,btn)

        local ind=Make("Frame",{
            AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(0,0,0,2),BackgroundColor3=T.Accent,
            BorderSizePixel=0,Parent=btn,
        })
        Corner(99,ind)

        local tabContent=Make("Frame",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Visible=false,Parent=content,
        })

        -- Sub-bar
        local sbar=Make("Frame",{
            Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Parent=tabContent,
        })
        List(sbar,18,Enum.FillDirection.Horizontal)
        Pad(0,0,12,12,sbar)

        -- Col area
        local ca=Make("Frame",{
            Position=UDim2.new(0,0,0,26),Size=UDim2.new(1,0,1,-26),
            BackgroundTransparency=1,Parent=tabContent,
        })

        -- Default columns (no sub-tabs)
        local dcL=Make("ScrollingFrame",{
            Position=UDim2.new(0,6,0,4),Size=UDim2.new(0.5,-10,1,-8),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=ca,
        })
        List(dcL,4)
        local dcR=Make("ScrollingFrame",{
            Position=UDim2.new(0.5,4,0,4),Size=UDim2.new(0.5,-10,1,-8),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=ca,
        })
        List(dcR,4)

        Tab.Btn=btn; Tab.Ind=ind; Tab.Content=tabContent
        Tab.SBar=sbar; Tab.CA=ca; Tab.DCL=dcL; Tab.DCR=dcR

        local function activate()
            for _,t in pairs(W.Tabs) do
                t.Content.Visible=false
                Tween(t.Btn,0.15,{BackgroundColor3=Color3.fromRGB(0,0,0,0),TextColor3=T.TextDim})
                Tween(t.Ind,0.18,{Size=UDim2.new(0,0,0,2)})
            end
            tabContent.Visible=true
            Tween(btn,0.15,{BackgroundColor3=T.TabActive,TextColor3=T.Text})
            task.spawn(function()
                task.wait()
                Tween(ind,0.2,{Size=UDim2.new(0,btn.AbsoluteSize.X,0,2)})
            end)
            W.ActiveTab=Tab
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function() if W.ActiveTab~=Tab then Tween(btn,0.1,{TextColor3=T.Text})end end)
        btn.MouseLeave:Connect(function() if W.ActiveTab~=Tab then Tween(btn,0.1,{TextColor3=T.TextDim})end end)

        table.insert(W.Tabs,Tab)
        if #W.Tabs==1 then activate() end

        function Tab:GetColumns()
            return Col(dcL,cfg), Col(dcR,cfg)
        end

        function Tab:AddSubTab(subName)
            local ST={Tab=self}

            local sbtn=Make("TextButton",{
                Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                BackgroundTransparency=1,BorderSizePixel=0,
                Text=subName,TextColor3=T.SubOff,TextSize=11,Font=T.Font,
                AutoButtonColor=false,Parent=sbar,
            })
            local sul=Make("Frame",{
                AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
                Size=UDim2.new(0,0,0,1),BackgroundColor3=T.Accent,
                BorderSizePixel=0,Parent=sbtn,
            })

            local scL=Make("ScrollingFrame",{
                Position=UDim2.new(0,6,0,4),Size=UDim2.new(0.5,-10,1,-8),
                BackgroundTransparency=1,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false,Parent=ca,
            })
            List(scL,4)
            local scR=Make("ScrollingFrame",{
                Position=UDim2.new(0.5,4,0,4),Size=UDim2.new(0.5,-10,1,-8),
                BackgroundTransparency=1,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=T.Accent,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=false,Parent=ca,
            })
            List(scR,4)

            ST.Btn=sbtn; ST.UL=sul; ST.CL=scL; ST.CR=scR

            local function activateSub()
                dcL.Visible=false; dcR.Visible=false
                for _,st in pairs(self.SubTabs) do
                    Tween(st.Btn,0.12,{TextColor3=T.SubOff})
                    Tween(st.UL,0.15,{Size=UDim2.new(0,0,0,1)})
                    st.CL.Visible=false; st.CR.Visible=false
                end
                Tween(sbtn,0.12,{TextColor3=T.SubOn})
                task.spawn(function()
                    task.wait()
                    Tween(sul,0.18,{Size=UDim2.new(0,sbtn.AbsoluteSize.X,0,1)})
                end)
                scL.Visible=true; scR.Visible=true
                self.ActiveSubTab=ST
            end

            sbtn.MouseButton1Click:Connect(activateSub)
            sbtn.MouseEnter:Connect(function() if self.ActiveSubTab~=ST then Tween(sbtn,0.1,{TextColor3=T.Text})end end)
            sbtn.MouseLeave:Connect(function() if self.ActiveSubTab~=ST then Tween(sbtn,0.1,{TextColor3=T.SubOff})end end)
            table.insert(self.SubTabs,ST)
            if #self.SubTabs==1 then activateSub() end

            function ST:GetColumns()
                return Col(scL,cfg), Col(scR,cfg)
            end
            return ST
        end

        return Tab
    end

    table.insert(self.Windows,W)
    return W
end

return NebulaUI
