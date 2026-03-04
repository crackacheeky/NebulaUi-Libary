local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

local HAS_WRITEFILE = type(writefile) == "function"
local HAS_READFILE  = type(readfile)  == "function"

local T = {
    WinBG        = Color3.fromRGB(20, 20, 24),
    TopBar       = Color3.fromRGB(14, 14, 18),
    TabBG        = Color3.fromRGB(20, 20, 24),
    ColBG        = Color3.fromRGB(27, 27, 33),
    Accent       = Color3.fromRGB(235, 75, 175),
    AccentDark   = Color3.fromRGB(150, 40, 115),
    SubActive    = Color3.fromRGB(235, 75, 175),
    SubInactive  = Color3.fromRGB(90, 90, 110),
    SliderTrack  = Color3.fromRGB(44, 44, 56),
    SliderFill   = Color3.fromRGB(235, 75, 175),
    CheckBG      = Color3.fromRGB(30, 30, 40),
    CheckOn      = Color3.fromRGB(235, 75, 175),
    CheckBorder  = Color3.fromRGB(52, 52, 67),
    DropBG       = Color3.fromRGB(28, 28, 36),
    DropHover    = Color3.fromRGB(36, 36, 46),
    DropBorder   = Color3.fromRGB(48, 48, 62),
    SectionLbl   = Color3.fromRGB(90, 90, 110),
    ItemLabel    = Color3.fromRGB(208, 208, 220),
    KbBG         = Color3.fromRGB(32, 32, 44),
    KbActive     = Color3.fromRGB(60, 20, 50),
    KbText       = Color3.fromRGB(85, 85, 108),
    KbTextActive = Color3.fromRGB(235, 75, 175),
    Divider      = Color3.fromRGB(34, 34, 44),
    ScrollBar    = Color3.fromRGB(235, 75, 175),
    BadgeBG      = Color3.fromRGB(46, 14, 36),
    Font         = Enum.Font.GothamMedium,
    FontBold     = Enum.Font.GothamBold,
    FontLight    = Enum.Font.Gotham,
}

local AccentObjs = {}
local function RegAccent(obj, prop)
    table.insert(AccentObjs, {o=obj, p=prop})
    pcall(function() obj[prop] = T.Accent end)
end
local function SetAccent(c)
    T.Accent=c; T.SubActive=c; T.SliderFill=c; T.CheckOn=c; T.ScrollBar=c
    T.KbTextActive=c; T.BadgeBG=Color3.fromRGB(math.floor(c.R*60),math.floor(c.G*20),math.floor(c.B*50))
    for _,e in ipairs(AccentObjs) do pcall(function() e.o[e.p]=c end) end
end

local function TW(o,t,p) pcall(function() TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end) end

local function New(cls, props)
    local o=Instance.new(cls); local par=nil
    for k,v in pairs(props or {}) do if k=="Parent" then par=v else pcall(function() o[k]=v end) end end
    if par then o.Parent=par end
    return o
end

local function Rnd(r,p)    New("UICorner",{CornerRadius=UDim.new(0,r),Parent=p}) end
local function Brdr(c,t,p) New("UIStroke",{Color=c,Thickness=t,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=p}) end
local function Pad(a,b,c,d,p) New("UIPadding",{PaddingTop=UDim.new(0,a),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,c),PaddingRight=UDim.new(0,d),Parent=p}) end
local function VList(p,g) New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,g or 0),Parent=p}) end
local function HList(p,g) New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,g or 0),Parent=p}) end

local function MkArrow(parent, rot)
    local holder = New("Frame",{
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-7,0.5,0),
        Size=UDim2.new(0,10,0,6), BackgroundTransparency=1, Parent=parent
    })
    
    local function MkLine(ax,ay,rot2,w,h)
        local f=New("Frame",{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.new(ax,0,ay,0),
            Size=UDim2.new(0,w,0,h),
            Rotation=rot2,
            BackgroundColor3=T.SubInactive,
            BorderSizePixel=0, Parent=holder
        })
        Rnd(1,f)
        return f
    end
    
    local l1 = MkLine(0.28, 0.5,  40, 2, 7)
    local l2 = MkLine(0.72, 0.5, -40, 2, 7)
    holder.Rotation = rot or 0
    return holder, l1, l2
end

local function Drag(frame, handle)
    local dn,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dn,ds,sp=true,i.Position,frame.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dn and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds; frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dn=false end
    end)
end

local function H2R(h,s,v)
    if s==0 then return Color3.new(v,v,v) end
    local i=math.floor(h*6); local f=h*6-i; local p,q,t2=v*(1-s),v*(1-f*s),v*(1-(1-f)*s); i=i%6
    if i==0 then return Color3.new(v,t2,p) elseif i==1 then return Color3.new(q,v,p)
    elseif i==2 then return Color3.new(p,v,t2) elseif i==3 then return Color3.new(p,q,v)
    elseif i==4 then return Color3.new(t2,p,v) else return Color3.new(v,p,q) end
end
local function R2H(c)
    local r,g,b=c.R,c.G,c.B; local mx,mn=math.max(r,g,b),math.min(r,g,b)
    local h,s,v=0,0,mx; local d=mx-mn; s=mx==0 and 0 or d/mx
    if mx~=mn then
        if mx==r then h=(g-b)/d+(g<b and 6 or 0) elseif mx==g then h=(b-r)/d+2 else h=(r-g)/d+4 end; h=h/6
    end
    return h,s,v
end
local function Hex(c) return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end
local function UnHex(s)
    s=s:gsub("#",""); if #s~=6 then return nil end
    return Color3.fromRGB(tonumber(s:sub(1,2),16)or 0,tonumber(s:sub(3,4),16)or 0,tonumber(s:sub(5,6),16)or 0)
end

local Cfg={}; Cfg.__index=Cfg
function Cfg.new(n)
    return setmetatable({_n=n, _d={}, _setters={}}, Cfg)
end

function Cfg:reg(flag, default, setter)
    if self._d[flag]==nil then self._d[flag]=default end
    if setter then self._setters[flag]=setter end
end
function Cfg:set(f,v) self._d[f]=v end
function Cfg:get(f)   return self._d[f] end
function Cfg:save(n)
    if not HAS_WRITEFILE then return false,"writefile not supported" end
    local ok,e=pcall(writefile,self._n.."_"..n..".json",HttpService:JSONEncode(self._d))
    return ok, ok and "Saved" or tostring(e)
end
function Cfg:load(n)
    if not HAS_READFILE then return false,"readfile not supported" end
    local ok,d=pcall(readfile,self._n.."_"..n..".json")
    if ok and d then
        local ok2,t=pcall(function() return HttpService:JSONDecode(d) end)
        if ok2 and t then
            for k,v in pairs(t) do self._d[k]=v end
            
            for flag,setter in pairs(self._setters) do
                if self._d[flag]~=nil then
                    task.spawn(function() pcall(setter, self._d[flag]) end)
                end
            end
        end
    end
    return ok, ok and "Loaded" or "File not found"
end

local function MkSection(parent, cfg, name)
    local S={}
    if name and name~="" then
        New("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=parent})
        New("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,
            Text=name,TextColor3=T.SectionLbl,TextSize=11,Font=T.FontBold,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=parent})
    end

    
    function S:AddCheckbox(o)
        o=o or {}
        local lbl   = o.Name     or "Option"
        local def   = o.Default  or false
        local flag  = o.Flag
        local kbDef = o.Keybind  
        local cb    = o.Callback or function() end
        local state = def

        
        local boundKey = nil
        if kbDef then
            pcall(function() boundKey = Enum.KeyCode[kbDef] end)
        end

        local row = New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=parent})
        local box = New("Frame",{Position=UDim2.new(0,0,0.5,-6),Size=UDim2.new(0,13,0,13),
            BackgroundColor3=state and T.CheckOn or T.CheckBG,BorderSizePixel=0,Parent=row})
        Rnd(2,box); Brdr(T.CheckBorder,1,box)
        local tick = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="✓",TextColor3=Color3.new(1,1,1),TextSize=9,Font=T.FontBold,Visible=state,Parent=box})
        New("TextLabel",{Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,
            Text=lbl,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=row})

        local kbBtn = nil
        local listening = false

        
        local function fmtKey(kc)
            if not kc then return "..." end
            local n = kc.Name
            
            local shorts = {RightShift="RShift",LeftShift="LShift",RightControl="RCtrl",LeftControl="LCtrl",
                RightAlt="RAlt",LeftAlt="LAlt",Return="Enter",BackSpace="Back"}
            return shorts[n] or (n:sub(1,6))
        end

        if kbDef ~= nil then
            
            local initTxt = boundKey and fmtKey(boundKey) or "..."
            kbBtn = New("TextButton",{
                AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,0,0.5,0),
                Size=UDim2.new(0,40,0,16),
                BackgroundColor3=T.KbBG, BorderSizePixel=0,
                Text=initTxt, TextColor3=T.KbText,
                TextSize=10, Font=T.FontLight,
                AutoButtonColor=false, Parent=row
            })
            Rnd(3,kbBtn)

            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                kbBtn.Text = "..."
                kbBtn.TextColor3 = T.KbTextActive
                TW(kbBtn, 0.1, {BackgroundColor3=T.KbActive})
                
                local conn; conn = UserInputService.InputBegan:Connect(function(inp, gp)
                    if gp then return end
                    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        listening = false
                        kbBtn.Text = boundKey and fmtKey(boundKey) or "none"
                        kbBtn.TextColor3 = T.KbText
                        TW(kbBtn, 0.1, {BackgroundColor3=T.KbBG})
                        conn:Disconnect()
                        return
                    end
                    boundKey = inp.KeyCode
                    listening = false
                    kbBtn.Text = fmtKey(boundKey)
                    kbBtn.TextColor3 = T.KbText
                    TW(kbBtn, 0.1, {BackgroundColor3=T.KbBG})
                    conn:Disconnect()
                end)
            end)
            kbBtn.MouseEnter:Connect(function() if not listening then TW(kbBtn,0.07,{BackgroundColor3=T.DropHover}) end end)
            kbBtn.MouseLeave:Connect(function() if not listening then TW(kbBtn,0.07,{BackgroundColor3=T.KbBG}) end end)
        end

        
        UserInputService.InputBegan:Connect(function(inp, gp)
            if gp or listening then return end
            if boundKey and inp.KeyCode == boundKey then
                state = not state
                if flag then cfg:set(flag, state) end
                local col = state and T.CheckOn or T.CheckBG
                TW(box, 0.12, {BackgroundColor3=col})
                tick.Visible = state
                task.spawn(cb, state)
            end
        end)

        local function upd(anim)
            local col = state and T.CheckOn or T.CheckBG
            if anim then TW(box,0.12,{BackgroundColor3=col}) else pcall(function() box.BackgroundColor3=col end) end
            tick.Visible = state
        end

        row.MouseButton1Click:Connect(function()
            state = not state
            if flag then cfg:set(flag,state) end
            upd(true); task.spawn(cb,state)
        end)
        row.MouseEnter:Connect(function() TW(row,0.07,{BackgroundColor3=Color3.fromRGB(28,28,38)}) end)
        row.MouseLeave:Connect(function() TW(row,0.07,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)

        local obj={}
        function obj:Set(v)
            state=v; if flag then cfg:set(flag,v) end; upd(true); task.spawn(cb,v)
        end
        function obj:Get() return state end

        
        if flag then
            cfg:reg(flag, def, function(v)
                
                local b = (v==true or v=="true")
                obj:Set(b)
            end)
        end

        return obj
    end

    
    function S:AddSlider(o)
        o=o or {}
        local lbl=o.Name or "Value"; local mn=o.Min or 0; local mx=o.Max or 100
        local def=o.Default or mn; local dec=o.Decimals or 0; local sfx=o.Suffix or ""
        local flag=o.Flag; local cb=o.Callback or function()end
        local val=math.clamp(def,mn,mx)

        local wrap=New("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,Parent=parent})
        New("TextLabel",{Position=UDim2.new(0,0,0,2),Size=UDim2.new(0.65,0,0,14),BackgroundTransparency=1,
            Text=lbl,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
        local fmt=dec>0 and ("%."..dec.."f") or "%d"
        local vl=New("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,2),Size=UDim2.new(0,52,0,14),
            BackgroundTransparency=1,Text=string.format(fmt,val)..sfx,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right,Parent=wrap})
        local track=New("Frame",{Position=UDim2.new(0,0,0,22),Size=UDim2.new(1,0,0,3),
            BackgroundColor3=T.SliderTrack,BorderSizePixel=0,Parent=wrap})
        Rnd(99,track)
        local fill=New("Frame",{Size=UDim2.new((val-mn)/(mx-mn),0,1,0),BackgroundColor3=T.SliderFill,BorderSizePixel=0,Parent=track})
        Rnd(99,fill); RegAccent(fill,"BackgroundColor3")
        local knob=New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((val-mn)/(mx-mn),0,0.5,0),
            Size=UDim2.new(0,10,0,10),BackgroundColor3=T.SliderFill,BorderSizePixel=0,ZIndex=2,Parent=track})
        Rnd(99,knob); RegAccent(knob,"BackgroundColor3")

        local function setV(sc)
            sc=math.clamp(sc,0,1); local m=10^dec
            val=math.floor((mn+(mx-mn)*sc)*m+.5)/m; val=math.clamp(val,mn,mx)
            vl.Text=string.format(fmt,val)..sfx
            TweenService:Create(fill,TweenInfo.new(0.04),{Size=UDim2.new(sc,0,1,0)}):Play()
            TweenService:Create(knob,TweenInfo.new(0.04),{Position=UDim2.new(sc,0,0.5,0)}):Play()
            if flag then cfg:set(flag,val) end; task.spawn(cb,val)
        end
        local dn=false
        local hit=New("TextButton",{Position=UDim2.new(0,-2,0,-10),Size=UDim2.new(1,4,0,24),
            BackgroundTransparency=1,Text="",ZIndex=3,Parent=track})
        hit.MouseButton1Down:Connect(function() dn=true; TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,12,0,12)}):Play() end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                dn=false; TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,10,0,10)}):Play()
            end
        end)
        RunService.Heartbeat:Connect(function()
            if dn then
                local x=UserInputService:GetMouseLocation().X; local as=track.AbsoluteSize.X
                if as>0 then setV((x-track.AbsolutePosition.X)/as) end
            end
        end)
        New("Frame",{Size=UDim2.new(1,0,0,2),BackgroundTransparency=1,Parent=parent})

        local obj={}
        function obj:Set(v)
            local n=tonumber(v); if not n then return end
            setV(math.clamp((n-mn)/(mx-mn),0,1))
        end
        function obj:Get() return val end
        if flag then cfg:reg(flag, def, function(v) obj:Set(v) end) end
        return obj
    end

    
    function S:AddDropdown(o)
        o=o or {}
        local lbl=o.Name or "Select"; local items=o.Items or {}
        local def=o.Default or (items[1] or ""); local flag=o.Flag; local cb=o.Callback or function()end
        local sel=def; local isOpen=false

        local wrap=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=parent})
        New("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text=lbl,TextColor3=T.ItemLabel,
            TextSize=12,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=wrap})
        local dbox=New("TextButton",{Position=UDim2.new(0,0,0,18),Size=UDim2.new(1,0,0,26),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=wrap})
        Rnd(4,dbox); Brdr(T.DropBorder,1,dbox)
        local slbl=New("TextLabel",{Position=UDim2.new(0,9,0,0),Size=UDim2.new(1,-28,1,0),
            BackgroundTransparency=1,Text=sel,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
            Parent=dbox})

        
        
        local arrHolder = New("Frame",{
            AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
            Size=UDim2.new(0,10,0,6),
            BackgroundTransparency=1, Parent=dbox
        })
        local function mkChevLine(ax, rot2)
            local f = New("Frame",{
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(ax,0,0.5,0),
                Size=UDim2.new(0,2,0,7),
                Rotation=rot2,
                BackgroundColor3=T.SubInactive,
                BorderSizePixel=0, Parent=arrHolder
            })
            Rnd(1,f); return f
        end
        mkChevLine(0.28,  40)  
        mkChevLine(0.72, -40)  
        
        local function setArrow(open)
            TW(arrHolder, 0.15, {Rotation = open and 180 or 0})
        end

        local dlist=New("Frame",{Position=UDim2.new(0,0,0,46),Size=UDim2.new(1,0,0,4),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,Visible=false,
            ZIndex=200,ClipsDescendants=false,Parent=wrap})
        Rnd(4,dlist); Brdr(T.DropBorder,1,dlist)
        local maxVis=6
        local listSF=New("ScrollingFrame",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
            CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ZIndex=201,Parent=dlist})
        VList(listSF,0); Pad(2,2,0,0,listSF)

        local function buildItems(list)
            for _,ch in ipairs(listSF:GetChildren()) do
                if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
            end
            local visH=math.min(#list,maxVis)*24+4
            dlist.Size=UDim2.new(1,0,0,visH)
            for _,item in ipairs(list) do
                local ib=New("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
                    Text=item,TextColor3=item==sel and T.Accent or T.ItemLabel,
                    TextSize=12,Font=T.Font,AutoButtonColor=false,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                    ZIndex=202,Parent=listSF})
                Pad(0,0,10,6,ib)
                ib.MouseEnter:Connect(function() TW(ib,0.07,{BackgroundColor3=T.DropHover}) end)
                ib.MouseLeave:Connect(function() TW(ib,0.07,{BackgroundColor3=Color3.fromRGB(0,0,0,0)}) end)
                ib.MouseButton1Click:Connect(function()
                    sel=item; slbl.Text=item
                    for _,ch2 in ipairs(listSF:GetChildren()) do
                        if ch2:IsA("TextButton") then
                            TW(ch2,0.1,{TextColor3=ch2.Text==sel and T.Accent or T.ItemLabel})
                        end
                    end
                    isOpen=false; dlist.Visible=false; setArrow(false)
                    if flag then cfg:set(flag,sel) end; task.spawn(cb,sel)
                end)
            end
        end
        buildItems(items)

        dbox.MouseButton1Click:Connect(function()
            isOpen=not isOpen; dlist.Visible=isOpen; setArrow(isOpen)
        end)
        dbox.MouseEnter:Connect(function() TW(dbox,0.07,{BackgroundColor3=T.DropHover}) end)
        dbox.MouseLeave:Connect(function() TW(dbox,0.07,{BackgroundColor3=T.DropBG}) end)
        New("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        local obj={}
        function obj:Set(v)
            sel=v; slbl.Text=v; if flag then cfg:set(flag,v) end; task.spawn(cb,v)
        end
        function obj:Get() return sel end
        function obj:Rebuild(newItems)
            items=newItems
            if not sel or not table.find(items,sel) then sel=items[1] or "" end
            slbl.Text=sel
            if flag then cfg:set(flag,sel) end
            buildItems(items)
        end
        if flag then
            cfg:reg(flag, def, function(v)
                
                local s = tostring(v)
                if table.find(items, s) then obj:Set(s) end
            end)
        end
        return obj
    end

    
    function S:AddColorPicker(o)
        o=o or {}
        local lbl=o.Name or "Color"; local def=o.Default or Color3.fromRGB(235,75,175)
        local flag=o.Flag; local cb=o.Callback or function()end
        local cc=def; local isOpen=false; local h,s,v=R2H(cc)

        local wrap=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Parent=parent})
        local row=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Parent=wrap})
        New("TextLabel",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,
            Text=lbl,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
        local sw=New("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),
            Size=UDim2.new(0,40,0,16),BackgroundColor3=cc,BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=row})
        Rnd(3,sw); Brdr(T.DropBorder,1,sw)

        local panel=New("Frame",{Position=UDim2.new(0,0,0,26),Size=UDim2.new(1,0,0,130),
            BackgroundColor3=T.DropBG,BorderSizePixel=0,Visible=false,ZIndex=40,Parent=wrap})
        Rnd(5,panel); Brdr(T.DropBorder,1,panel); Pad(7,7,7,7,panel)

        local svc=New("Frame",{Size=UDim2.new(1,0,0,78),BackgroundColor3=H2R(h,1,1),BorderSizePixel=0,ClipsDescendants=true,ZIndex=41,Parent=panel})
        Rnd(4,svc)
        local wg=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=42,Parent=svc})
        New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Parent=wg})
        local bg2=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=43,Parent=svc})
        New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=90,Parent=bg2})
        local svk=New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(s,0,1-v,0),
            Size=UDim2.new(0,9,0,9),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=45,Parent=svc})
        Rnd(99,svk); Brdr(Color3.new(0,0,0),1.5,svk)

        local hbar=New("Frame",{Position=UDim2.new(0,0,0,84),Size=UDim2.new(1,0,0,8),
            BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=41,Parent=panel})
        Rnd(99,hbar)
        New("UIGradient",{Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(0.83,Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
        }),Parent=hbar})
        local hk=New("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(h,0,0.5,0),
            Size=UDim2.new(0,6,1,4),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=42,Parent=hbar})
        Rnd(3,hk)

        local hexrow=New("Frame",{Position=UDim2.new(0,0,0,99),Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,ZIndex=41,Parent=panel})
        New("TextLabel",{Size=UDim2.new(0,26,1,0),BackgroundTransparency=1,Text="HEX",TextColor3=T.SubInactive,TextSize=9,Font=T.FontBold,ZIndex=42,Parent=hexrow})
        local hbox=New("TextBox",{Position=UDim2.new(0,30,0,1),Size=UDim2.new(1,-30,0,16),
            BackgroundColor3=T.CheckBG,BorderSizePixel=0,Text=Hex(cc),TextColor3=T.ItemLabel,
            TextSize=10,Font=Enum.Font.Code,PlaceholderText="#FFFFFF",ClearTextOnFocus=false,ZIndex=42,Parent=hexrow})
        Rnd(3,hbox); Pad(0,0,5,0,hbox)

        local function applyCol()
            cc=H2R(h,s,v); sw.BackgroundColor3=cc; svc.BackgroundColor3=H2R(h,1,1)
            svk.Position=UDim2.new(s,0,1-v,0); hk.Position=UDim2.new(h,0,0.5,0); hbox.Text=Hex(cc)
            if flag then cfg:set(flag,{cc.R,cc.G,cc.B}) end; task.spawn(cb,cc)
        end
        local svDn,hDn=false,false
        local svb=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=46,Parent=svc})
        local hb2=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=43,Parent=hbar})
        svb.MouseButton1Down:Connect(function() svDn=true end)
        hb2.MouseButton1Down:Connect(function() hDn=true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then svDn=false; hDn=false end
        end)
        RunService.Heartbeat:Connect(function()
            if svDn then local m=UserInputService:GetMouseLocation(); local ap,sz=svc.AbsolutePosition,svc.AbsoluteSize
                if sz.X>0 and sz.Y>0 then s=math.clamp((m.X-ap.X)/sz.X,0,1); v=1-math.clamp((m.Y-ap.Y)/sz.Y,0,1); applyCol() end end
            if hDn then local m=UserInputService:GetMouseLocation(); local ap,sz=hbar.AbsolutePosition,hbar.AbsoluteSize
                if sz.X>0 then h=math.clamp((m.X-ap.X)/sz.X,0,1); applyCol() end end
        end)
        hbox.FocusLost:Connect(function() local c2=UnHex(hbox.Text); if c2 then h,s,v=R2H(c2); applyCol() end end)
        sw.MouseButton1Click:Connect(function() isOpen=not isOpen; panel.Visible=isOpen end)
        applyCol()
        New("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=wrap})

        local obj={}
        function obj:Set(c2)
            if type(c2)=="table" then c2=Color3.new(c2[1],c2[2],c2[3]) end
            h,s,v=R2H(c2); applyCol()
        end
        function obj:Get() return cc end
        if flag then cfg:reg(flag, {def.R,def.G,def.B}, function(val)
            if type(val)=="table" then obj:Set(val) end
        end) end
        return obj
    end

    
    function S:AddButton(o)
        o=o or {}
        local lbl=o.Name or "Button"; local cb=o.Callback or function()end
        local btn=New("TextButton",{Size=UDim2.new(1,0,0,26),BackgroundColor3=T.DropBG,BorderSizePixel=0,
            Text=lbl,TextColor3=T.ItemLabel,TextSize=12,Font=T.Font,AutoButtonColor=false,Parent=parent})
        btn.TextXAlignment=Enum.TextXAlignment.Left
        Rnd(4,btn); Brdr(T.DropBorder,1,btn); Pad(0,0,9,0,btn)
        btn.MouseEnter:Connect(function() TW(btn,0.07,{BackgroundColor3=T.DropHover}) end)
        btn.MouseLeave:Connect(function() TW(btn,0.07,{BackgroundColor3=T.DropBG}) end)
        btn.MouseButton1Click:Connect(function()
            TW(btn,0.06,{BackgroundColor3=T.AccentDark})
            task.delay(0.1,function() TW(btn,0.1,{BackgroundColor3=T.DropBG}) end)
            task.spawn(cb)
        end)
        New("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=parent})
    end

    function S:AddSpacer(h) New("Frame",{Size=UDim2.new(1,0,0,h or 6),BackgroundTransparency=1,Parent=parent}) end
    return S
end

local function NewCol(scroll, cfg)
    local C={}
    function C:AddSection(n) return MkSection(scroll,cfg,n) end
    C.AddGroup=C.AddSection
    return C
end

local Lib={}; Lib.__index=Lib

function Lib.new(opts)
    opts=opts or {}
    local inst=setmetatable({},Lib)
    inst.Windows={}
    inst.Cfg=Cfg.new(opts.Name or "NebulaUI")
    inst._toggleKey={ key=opts.ToggleKey or Enum.KeyCode.RightShift }
    inst.Shown=true
    inst.SetAccent=SetAccent

    local sg=Instance.new("ScreenGui")
    sg.Name="NebulaUI"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder=999; sg.IgnoreGuiInset=true
    local ok=pcall(function() sg.Parent=CoreGui end)
    if not ok or not sg.Parent then sg.Parent=LP:WaitForChild("PlayerGui") end
    inst.Gui=sg; inst._sg=sg

    inst.NF=New("Frame",{Size=UDim2.new(0,295,0,500),AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-10,1,-10),BackgroundTransparency=1,Parent=sg})
    New("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,6),Parent=inst.NF})

    UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == inst._toggleKey.key then inst:Toggle() end
    end)

    local miss={}
    if not HAS_WRITEFILE then table.insert(miss,"writefile") end
    if not HAS_READFILE  then table.insert(miss,"readfile") end
    if #miss>0 then task.delay(1.5,function()
        inst:Notify({Title="Executor Warning",Body="Missing: "..table.concat(miss,", ")..". Config disabled.",Type="Warning",Duration=6})
    end) end

    return inst
end

function Lib:Toggle()
    local anyVisible = false
    for _,w in ipairs(self.Windows) do
        if w and w.Root and w.Root.Visible then anyVisible = true; break end
    end
    self.Shown = not anyVisible
    for _,w in ipairs(self.Windows) do if w and w.Root then w.Root.Visible=self.Shown end end
end

function Lib:Show()
    self.Shown = true
    for _,w in ipairs(self.Windows) do if w and w.Root then w.Root.Visible=true end end
end

function Lib:Hide()
    self.Shown = false
    for _,w in ipairs(self.Windows) do if w and w.Root then w.Root.Visible=false end end
end
function Lib:Unload() pcall(function() self._sg:Destroy() end) end
function Lib:SetToggleKey(k) self._toggleKey.key=k end
function Lib:GetFlag(f) return self.Cfg:get(f) end
function Lib:SetFlag(f,v) self.Cfg:set(f,v) end

function Lib:Notify(o)
    o=o or {}
    local title=o.Title or "Notice"; local body=o.Body or ""; local dur=o.Duration or 4; local kind=o.Type or "Info"
    local pal={Info=T.Accent,Success=Color3.fromRGB(45,195,85),Warning=Color3.fromRGB(210,168,35),Error=Color3.fromRGB(208,50,50)}
    local col=pal[kind] or T.Accent
    local card=New("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(20,20,26),
        BorderSizePixel=0,ClipsDescendants=true,Parent=self.NF})
    Rnd(5,card); Brdr(col,1,card)
    New("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=col,BorderSizePixel=0,Parent=card})
    New("TextLabel",{Position=UDim2.new(0,11,0,7),Size=UDim2.new(1,-14,0,16),BackgroundTransparency=1,
        Text=title,TextColor3=Color3.new(1,1,1),TextSize=12,Font=T.FontBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=card})
    New("TextLabel",{Position=UDim2.new(0,11,0,24),Size=UDim2.new(1,-14,0,26),BackgroundTransparency=1,
        Text=body,TextColor3=Color3.fromRGB(148,148,168),TextSize=11,Font=T.Font,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=card})
    local pb=New("Frame",{Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),BackgroundColor3=col,BorderSizePixel=0,Parent=card})
    TweenService:Create(pb,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2)}):Play()
    task.delay(dur,function()
        TweenService:Create(card,TweenInfo.new(0.28),{Size=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.3); pcall(function() card:Destroy() end)
    end)
end

function Lib:CreateWindow(opts)
    opts=opts or {}
    local title    = opts.Title    or "Script"
    local subtitle = opts.Subtitle or "stable"
    local user     = opts.User     or ""
    local winSize  = opts.Size     or UDim2.new(0,700,0,490)
    local winPos   = opts.Position or UDim2.new(0.5,-350,0.5,-245)
    local cfg      = self.Cfg

    local W={Lib=self,Tabs={},ActiveTab=nil}
    W.Root=New("Frame",{Name=title.."_Root",Size=winSize,Position=winPos,
        BackgroundColor3=T.WinBG,BorderSizePixel=0,Parent=self.Gui})
    Rnd(8,W.Root); Brdr(Color3.fromRGB(44,44,56),1,W.Root)

    local clip=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ClipsDescendants=true,Parent=W.Root})
    Rnd(8,clip)

    
    local topBar=New("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=T.TopBar,BorderSizePixel=0,Parent=clip})
    local titlePx = math.clamp(#title * 8, 30, 160)
    New("TextLabel",{Position=UDim2.new(0,12,0,0),Size=UDim2.new(0,titlePx,1,0),
        BackgroundTransparency=1,Text=title,TextColor3=Color3.fromRGB(112,112,132),
        TextSize=12,Font=T.FontBold,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,Parent=topBar})
    New("TextLabel",{Position=UDim2.new(0,12+titlePx+5,0,0),Size=UDim2.new(0,12,1,0),
        BackgroundTransparency=1,Text="›",TextColor3=Color3.fromRGB(50,50,65),TextSize=11,Font=T.Font,Parent=topBar})
    local badgeX=12+titlePx+5+14; local badgeW=math.max(#subtitle*7+14,36)
    local badge=New("Frame",{Position=UDim2.new(0,badgeX,0.5,-8),Size=UDim2.new(0,badgeW,0,16),
        BackgroundColor3=T.BadgeBG,BorderSizePixel=0,Parent=topBar})
    Rnd(4,badge)
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=subtitle,
        TextColor3=T.Accent,TextSize=10,Font=T.FontBold,Parent=badge})
    if user~="" then
        New("TextLabel",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-28,0.5,0),
            Size=UDim2.new(0,160,0,20),BackgroundTransparency=1,
            Text=user,TextColor3=Color3.fromRGB(95,95,115),TextSize=11,Font=T.Font,
            TextXAlignment=Enum.TextXAlignment.Right,Parent=topBar})
    end
    local closeBtn=New("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.new(0,14,0,14),BackgroundColor3=Color3.fromRGB(172,38,38),
        BorderSizePixel=0,Text="",AutoButtonColor=false,Parent=topBar})
    Rnd(99,closeBtn)
    closeBtn.MouseButton1Click:Connect(function() W.Root.Visible=false end)
    closeBtn.MouseEnter:Connect(function() TW(closeBtn,0.1,{BackgroundColor3=Color3.fromRGB(218,50,50)}) end)
    closeBtn.MouseLeave:Connect(function() TW(closeBtn,0.1,{BackgroundColor3=Color3.fromRGB(172,38,38)}) end)
    Drag(W.Root,topBar)

    
    local tabRow=New("Frame",{Position=UDim2.new(0,0,0,32),Size=UDim2.new(1,0,0,32),
        BackgroundColor3=T.TabBG,BorderSizePixel=0,Parent=clip})
    New("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
        Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Divider,BorderSizePixel=0,Parent=tabRow})
    local tabHolder=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=tabRow})
    HList(tabHolder,0); Pad(0,0,10,10,tabHolder)

    local contentHolder=New("Frame",{Position=UDim2.new(0,0,0,64),Size=UDim2.new(1,0,1,-64),
        BackgroundTransparency=1,Parent=clip})

    function W:AddTab(tabName)
        local Tab={Window=W,SubTabs={},ActiveSubTab=nil}
        local tbtn=New("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundTransparency=1,BorderSizePixel=0,Text=tabName,TextColor3=T.SubInactive,
            TextSize=12,Font=T.Font,AutoButtonColor=false,Parent=tabHolder})
        Pad(0,0,13,13,tbtn)
        local indLine=New("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),
            Size=UDim2.new(0,0,0,2),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=tbtn})
        Rnd(99,indLine); RegAccent(indLine,"BackgroundColor3")

        local tabContent=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=contentHolder})
        local subBarRow=New("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Parent=tabContent})
        HList(subBarRow,20); Pad(0,0,14,14,subBarRow)
        New("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),
            Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Divider,BorderSizePixel=0,Parent=subBarRow})
        local colArea=New("Frame",{Position=UDim2.new(0,0,0,28),Size=UDim2.new(1,0,1,-28),BackgroundTransparency=1,Parent=tabContent})
        local mkScroll=function(pos,sz)
            local sf=New("ScrollingFrame",{Position=pos,Size=sz,BackgroundColor3=T.ColBG,BorderSizePixel=0,
                ScrollBarThickness=2,ScrollBarImageColor3=T.ScrollBar,
                CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=colArea})
            Rnd(5,sf); VList(sf,1); Pad(10,10,10,10,sf); RegAccent(sf,"ScrollBarImageColor3")
            return sf
        end
        local defL=mkScroll(UDim2.new(0,8,0,8),UDim2.new(0.5,-12,1,-16))
        local defR=mkScroll(UDim2.new(0.5,4,0,8),UDim2.new(0.5,-12,1,-16))
        Tab.Btn=tbtn; Tab.Ind=indLine; Tab.Content=tabContent
        Tab.SubBarRow=subBarRow; Tab.ColArea=colArea; Tab.DefL=defL; Tab.DefR=defR

        local function activateTab()
            for _,t in ipairs(W.Tabs) do
                t.Content.Visible=false
                TW(t.Btn,0.14,{TextColor3=T.SubInactive})
                TW(t.Ind,0.15,{Size=UDim2.new(0,0,0,2)})
            end
            tabContent.Visible=true
            TW(tbtn,0.14,{TextColor3=T.ItemLabel})
            task.defer(function()
                local w=tbtn.AbsoluteSize.X
                TW(indLine,0.2,{Size=UDim2.new(0,w>0 and w or 60,0,2)})
            end)
            W.ActiveTab=Tab
        end

        tbtn.MouseButton1Click:Connect(activateTab)
        tbtn.MouseEnter:Connect(function() if W.ActiveTab~=Tab then TW(tbtn,0.1,{TextColor3=T.ItemLabel}) end end)
        tbtn.MouseLeave:Connect(function() if W.ActiveTab~=Tab then TW(tbtn,0.1,{TextColor3=T.SubInactive}) end end)
        table.insert(W.Tabs,Tab)
        if #W.Tabs==1 then task.delay(0.05,activateTab) end

        function Tab:GetColumns() return NewCol(defL,cfg),NewCol(defR,cfg) end

        function Tab:AddSubTab(subName)
            local ST={}; ST.Tab=self
            local sbtn=New("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                BackgroundTransparency=1,BorderSizePixel=0,Text=subName,TextColor3=T.SubInactive,
                TextSize=12,Font=T.Font,AutoButtonColor=false,Parent=subBarRow})
            local uline=New("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),
                Size=UDim2.new(0,0,0,1),BackgroundColor3=T.Accent,BorderSizePixel=0,Parent=sbtn})
            Rnd(99,uline); RegAccent(uline,"BackgroundColor3")
            local scL=mkScroll(UDim2.new(0,8,0,8),UDim2.new(0.5,-12,1,-16)); scL.Visible=false
            local scR=mkScroll(UDim2.new(0.5,4,0,8),UDim2.new(0.5,-12,1,-16)); scR.Visible=false
            ST.Btn=sbtn; ST.ULine=uline; ST.CL=scL; ST.CR=scR

            local function activateSub()
                defL.Visible=false; defR.Visible=false
                for _,st in ipairs(self.SubTabs) do
                    TW(st.Btn,0.12,{TextColor3=T.SubInactive})
                    TW(st.ULine,0.15,{Size=UDim2.new(0,0,0,1)})
                    st.CL.Visible=false; st.CR.Visible=false
                end
                TW(sbtn,0.12,{TextColor3=T.SubActive})
                task.defer(function()
                    local w=sbtn.AbsoluteSize.X
                    TW(uline,0.17,{Size=UDim2.new(0,w>0 and w or 40,0,1)})
                end)
                scL.Visible=true; scR.Visible=true; self.ActiveSubTab=ST
            end
            sbtn.MouseButton1Click:Connect(activateSub)
            sbtn.MouseEnter:Connect(function() if self.ActiveSubTab~=ST then TW(sbtn,0.1,{TextColor3=T.ItemLabel}) end end)
            sbtn.MouseLeave:Connect(function() if self.ActiveSubTab~=ST then TW(sbtn,0.1,{TextColor3=T.SubInactive}) end end)
            table.insert(self.SubTabs,ST)
            if #self.SubTabs==1 then task.delay(0.05,activateSub) end

            function ST:GetColumns() return NewCol(scL,cfg),NewCol(scR,cfg) end
            return ST
        end

        return Tab
    end

    table.insert(self.Windows,W)
    return W
end


function Lib:CreateKeySystem(opts)
    opts = opts or {}

    local keyType     = opts.KeyType    or "static"
    local validKey    = opts.Key        or "NEBULA-FREE"
    local keyUrl      = opts.KeyUrl     or ""
    local getKeyUrl   = opts.GetKeyUrl  or "https://example.com/getkey"
    local title       = opts.Title      or "Key System"
    local subtitle    = opts.Subtitle   or "verification required"
    local onSuccess   = opts.OnSuccess  or function() end
    local savedFile   = (opts.SaveName  or "NebulaKey") .. ".txt"

    local lib = self

    local function doSuccess()
        lib:Show()
        task.spawn(onSuccess)
    end

    local function checkKey(entered)
        local trimmed = entered:match("^%s*(.-)%s*$")
        if keyType == "url" then
            local ok, body = pcall(game.HttpGet, game, keyUrl)
            if ok and body then
                local fetched = body:match("^%s*(.-)%s*$")
                return trimmed == fetched, fetched
            end
            return false, nil
        else
            return trimmed == validKey, validKey
        end
    end

    lib:Hide()

    if HAS_READFILE then
        local ok, saved = pcall(readfile, savedFile)
        if ok and saved then
            local trimmed = saved:match("^%s*(.-)%s*$")
            local valid
            if keyType == "url" then
                local ok2, body = pcall(game.HttpGet, game, keyUrl)
                if ok2 and body then valid = trimmed == body:match("^%s*(.-)%s*$") end
            else
                valid = trimmed == validKey
            end
            if valid then
                task.defer(doSuccess)
                return
            end
        end
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "NebulaKeySystem"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 1000
    sg.IgnoreGuiInset = true
    local ok2 = pcall(function() sg.Parent = CoreGui end)
    if not ok2 or not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

    local overlay = New("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = Color3.fromRGB(8,8,10),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = sg,
    })

    local card = New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position    = UDim2.new(0.5,0,0.5,0),
        Size        = UDim2.new(0,380,0,260),
        BackgroundColor3 = T.WinBG,
        BorderSizePixel  = 0,
        Parent = sg,
    })
    Rnd(10, card)
    Brdr(Color3.fromRGB(44,44,56), 1, card)

    local topBar = New("Frame", {
        Size = UDim2.new(1,0,0,34),
        BackgroundColor3 = T.TopBar,
        BorderSizePixel  = 0,
        Parent = card,
    })
    Rnd(10, topBar)
    New("Frame", {
        Position = UDim2.new(0,0,0.5,0),
        Size     = UDim2.new(1,0,0.5,0),
        BackgroundColor3 = T.TopBar,
        BorderSizePixel  = 0,
        Parent = topBar,
    })

    local titlePx = math.clamp(#title * 8, 30, 200)
    New("TextLabel", {
        Position = UDim2.new(0,12,0,0), Size = UDim2.new(0,titlePx,1,0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Color3.fromRGB(112,112,132), TextSize = 12, Font = T.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = topBar,
    })
    New("TextLabel", {
        Position = UDim2.new(0,12+titlePx+4,0,0), Size = UDim2.new(0,10,1,0),
        BackgroundTransparency = 1, Text = "›",
        TextColor3 = Color3.fromRGB(50,50,65), TextSize = 11, Font = T.Font, Parent = topBar,
    })
    local bw = math.max(#subtitle*7+14, 40)
    local badge = New("Frame", {
        Position = UDim2.new(0,12+titlePx+18,0.5,-8), Size = UDim2.new(0,bw,0,16),
        BackgroundColor3 = T.BadgeBG, BorderSizePixel = 0, Parent = topBar,
    })
    Rnd(4, badge)
    New("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = subtitle,
        TextColor3 = T.Accent, TextSize = 10, Font = T.FontBold, Parent = badge,
    })

    local body = New("Frame", {
        Position = UDim2.new(0,0,0,34), Size = UDim2.new(1,0,1,-34),
        BackgroundTransparency = 1, Parent = card,
    })

    New("TextLabel", {
        Position = UDim2.new(0,22,0,16), Size = UDim2.new(1,-44,0,14),
        BackgroundTransparency = 1,
        Text = "Enter your key below to continue",
        TextColor3 = Color3.fromRGB(90,90,110), TextSize = 11, Font = T.Font,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = body,
    })

    local inputBg = New("Frame", {
        Position = UDim2.new(0,18,0,38), Size = UDim2.new(1,-36,0,32),
        BackgroundColor3 = T.DropBG, BorderSizePixel = 0, Parent = body,
    })
    Rnd(6, inputBg)
    Brdr(T.DropBorder, 1, inputBg)
    local inputBox = New("TextBox", {
        Position = UDim2.new(0,10,0,0), Size = UDim2.new(1,-20,1,0),
        BackgroundTransparency = 1,
        PlaceholderText = "Paste key here...",
        PlaceholderColor3 = Color3.fromRGB(60,60,78),
        Text = "", TextColor3 = T.ItemLabel,
        TextSize = 13, Font = T.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = inputBg,
    })

    local statusLbl = New("TextLabel", {
        Position = UDim2.new(0,18,0,80), Size = UDim2.new(1,-36,0,14),
        BackgroundTransparency = 1, Text = "",
        TextColor3 = Color3.fromRGB(90,90,110), TextSize = 11, Font = T.Font,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = body,
    })

    local function mkBtn(xOff, w, label, accent)
        local bg = New("TextButton", {
            Position = UDim2.new(0, xOff, 0, 106),
            Size     = UDim2.new(0, w, 0, 32),
            BackgroundColor3 = accent and T.Accent or T.DropBG,
            BorderSizePixel  = 0, Text = label,
            TextColor3 = accent and Color3.new(1,1,1) or T.ItemLabel,
            TextSize = 12, Font = T.FontBold,
            AutoButtonColor = false, Parent = body,
        })
        Rnd(6, bg)
        Brdr(accent and T.AccentDark or T.DropBorder, 1, bg)
        bg.MouseEnter:Connect(function()
            TW(bg, 0.08, {BackgroundColor3 = accent and T.AccentDark or T.DropHover})
        end)
        bg.MouseLeave:Connect(function()
            TW(bg, 0.08, {BackgroundColor3 = accent and T.Accent or T.DropBG})
        end)
        return bg
    end

    local btnW = 156
    local checkBtn  = mkBtn(18,          btnW, "Check Key",  true)
    local getKeyBtn = mkBtn(18+btnW+10,  btnW, "Get Key",    false)

    New("TextLabel", {
        Position = UDim2.new(0,18,0,152), Size = UDim2.new(1,-36,0,38),
        BackgroundTransparency = 1,
        Text = "Click 'Get Key' to open the key page, copy your key,\nthen paste it above and press 'Check Key'.",
        TextColor3 = Color3.fromRGB(58,58,74), TextSize = 10, Font = T.Font,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = body,
    })

    local checking = false
    checkBtn.MouseButton1Click:Connect(function()
        if checking then return end
        checking = true
        local entered = inputBox.Text
        statusLbl.Text = keyType == "url" and "Fetching key..." or "Checking..."
        statusLbl.TextColor3 = Color3.fromRGB(90,90,110)
        task.spawn(function()
            local valid, _ = checkKey(entered)
            if valid then
                if HAS_WRITEFILE then pcall(writefile, savedFile, entered:match("^%s*(.-)%s*$")) end
                statusLbl.Text = "Key accepted!"
                statusLbl.TextColor3 = Color3.fromRGB(45,195,85)
                TW(inputBg, 0.15, {BackgroundColor3 = Color3.fromRGB(18,38,22)})
                task.delay(0.6, function()
                    TW(card, 0.3, {Size = UDim2.new(0,380,0,0), Position = UDim2.new(0.5,0,0.5,0)})
                    TW(overlay, 0.3, {BackgroundTransparency = 1})
                    task.wait(0.35)
                    pcall(function() sg:Destroy() end)
                    doSuccess()
                end)
            else
                statusLbl.Text = "Invalid key. Try again."
                statusLbl.TextColor3 = Color3.fromRGB(208,50,50)
                TW(inputBg, 0.1, {BackgroundColor3 = Color3.fromRGB(38,12,12)})
                task.delay(0.5, function()
                    TW(inputBg, 0.2, {BackgroundColor3 = T.DropBG})
                end)
                checking = false
            end
        end)
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        local copied = false
        pcall(function()
            if setclipboard then setclipboard(getKeyUrl)
            elseif toclipboard then toclipboard(getKeyUrl) end
            copied = true
        end)
        statusLbl.Text = copied and "Link copied to clipboard!" or ("Open: " .. getKeyUrl)
        statusLbl.TextColor3 = copied and T.Accent or Color3.fromRGB(210,168,35)
    end)

    card.Position = UDim2.new(0.5,0,0.4,0)
    TW(card, 0.35, {Position = UDim2.new(0.5,0,0.5,0)})
end

return Lib
