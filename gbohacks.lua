-- GBO HACKS (snow) v3.8
-- Freecam removido, Disable All removido, Open Preview removido, traces funcional, aura reforçada/desliga, part pickers, hitbox mode dropdown, roster dropdown nos inputs, list player bulk-clear + auto-remove.

local P=game:GetService("Players")
local U=game:GetService("UserInputService")
local T=game:GetService("TweenService")
local R=game:GetService("RunService")
local TP=game:GetService("TeleportService")
local VU=game:GetService("VirtualUser")
local VIM=game:GetService("VirtualInputManager")
local L=game:GetService("Lighting")
local LP=P.LocalPlayer
local camera=workspace.CurrentCamera or workspace:WaitForChild("Camera")
local pg=LP:WaitForChild("PlayerGui")

pcall(function()
    local old=pg:FindFirstChild("GBOHacks")
    if old then old:Destroy() end
end)

local C={
    bg=Color3.fromRGB(235,245,255),panel=Color3.fromRGB(210,228,245),
    item=Color3.fromRGB(225,238,252),accent=Color3.fromRGB(60,140,220),
    border=Color3.fromRGB(150,180,215),green=Color3.fromRGB(80,200,120),
    red=Color3.fromRGB(220,80,100),textDark=Color3.fromRGB(20,40,80),
    textLight=Color3.fromRGB(245,250,255),ice=Color3.fromRGB(90,170,240),
    gray=Color3.fromRGB(90,120,160)
}
local DEF_SPEED=16
local DEF_JUMP=50

local AIM_PARTS={
    {"Head", {"Head"}},
    {"Chest", {"UpperTorso","Torso"}},
    {"Stomach", {"LowerTorso","Torso"}},
    {"Left Arm", {"LeftUpperArm","Left Arm"}},
    {"Right Arm", {"RightUpperArm","Right Arm"}},
    {"Left Leg", {"LeftUpperLeg","Left Leg"}},
    {"Right Leg", {"RightUpperLeg","Right Leg"}}
}
local AIM_PART_NAMES={}
for _,entry in ipairs(AIM_PARTS) do table.insert(AIM_PART_NAMES,entry[1]) end

local function resolveAimPart(char,partLabel)
    for _,entry in ipairs(AIM_PARTS) do
        if entry[1]==partLabel then
            for _,partName in ipairs(entry[2]) do
                local part=char:FindFirstChild(partName)
                if part then return part end
            end
        end
    end
    return char:FindFirstChild("Head")
end

local S={
    ESP=false,Box=false,Aura=false,Name=false,Distance=false,Health=false,Skeleton=false,ESPTraces=false,
    ESPTeamCheck=false,ESPWallCheck=false,ESPTransparency=50,
    Aimbot=false,AimTeamCheck=false,AimWallCheck=false,AimPart="Head",
    SilentAim=false,SilentTeamCheck=false,SilentWallCheck=false,SilentStrength=5.0,SilentPart="Head",
    TriggerBot=false,TriggerLock=false,TriggerTeamCheck=false,TriggerWallCheck=false,TriggerWallBang=false,TriggerPart="Head",
    ShowAimFOV=false,ShowSilentFOV=false,ShowTriggerFOV=false,
    AimFOV=120,SilentFOV=100,TriggerFOV=80,MaxDist=500,
    ESPColor=C.accent,AimFOVColor=C.accent,SilentFOVColor=Color3.fromRGB(0,255,255),
    TriggerFOVColor=C.green,HitboxColor=C.ice,SQColor=C.ice,
    RainbowESP=false,RainbowAimFOV=false,RainbowSilentFOV=false,RainbowTriggerFOV=false,
    RainbowHitbox=false,RainbowSQ=false,
    SpeedEnabled=false,MoveSpeed=DEF_SPEED,
    JumpEnabled=false,JumpPower=DEF_JUMP,JumpInf=false,FlySpeed=50,
    Noclip=false,Fly=false,
    StreamMode=false,MouseFree=false,
    HitboxEnabled=false,HitboxMode="Head",HitboxSize=3,HitboxTransparency=0,HitboxVisual="head",
    SQSize=5,SQTransparency=0.7,SQTeamCheck=false,
    SnowEnabled=true,Fullbright=false,AntiAFK=false,
    FakeLag=false,FakeLagAmount=200,Spin=false,SpinSpeed=50,
    Blacklist={},Whitelist={},
    AntiAim=false,AntiAimMode="Jitter",AntiAimYaw=0,
    NoFog=false,CustomFOV=false,CustomFOVValue=70,
    FPSBooster=false,
    Stretch=false,StretchSize=1.0,
    TSEnabled=false,TSMode="Distance",TSAction="Orbit",TSRadius=8,TSSpeed=2,TSName="",
    Spider=false,TPCursor=false,LaunchOnTouch=false,
    AimKey=Enum.KeyCode.Q,SilentKey=Enum.KeyCode.E,TriggerKey=Enum.KeyCode.T,
    ToggleKey=Enum.KeyCode.RightShift,StreamKey=Enum.KeyCode.F1,
    Spectate=false,SpectateTarget=nil
}

local highlights={}
local drawingTraces={}
local drawingSkeletons={}
local drawingHeadCircles={}
local sqOriginal={}
local originalFOV=camera.FieldOfView
local noclipState=false
local savedCharCollision={}
local savedLighting={}
local guiVisibleBeforeStream=true
local toggleSetters={}
local spinThread=nil
local fakeLagThread=nil
local afkConn=nil
local wasFlying=false
local multiJumpLast=0
local lockTarget=nil
local tsAngleAcc=0
local touchLaunchConn=nil

local function make(c,p,parent)
    local o=Instance.new(c)
    for k,v in pairs(p or {}) do pcall(function() o[k]=v end) end
    o.Parent=parent
    return o
end
local function corner(o,r) make("UICorner",{CornerRadius=UDim.new(0,r or 8)},o) end
local function stroke(o,col,n,t) return make("UIStroke",{Color=col or C.border,Thickness=n or 1,Transparency=t or .15},o) end

local function fuzzyFind(name)
    if not name or name=="" then return nil end
    local exact=P:FindFirstChild(name)
    if exact then return exact end
    local lower=string.lower(name)
    local best,bestScore=nil,math.huge
    for _,p in ipairs(P:GetPlayers()) do
        local pn=string.lower(p.Name)
        if string.find(pn,lower,1,true) or string.find(lower,pn,1,true) then
            local diff=math.abs(#pn-#lower)
            if diff<bestScore then bestScore=diff; best=p end
        end
    end
    return best
end

local function resetHeadForPlayer(p)
    if not p or p==LP or not p.Character then return end
    local head=p.Character:FindFirstChild("Head")
    if head then
        head.Size=Vector3.new(2,1,1); head.Transparency=0
        local marker=head:FindFirstChild("HitboxMarker")
        if marker then marker:Destroy() end
    end
end

local function applyHitboxToPlayer(p)
    if not p or p==LP or not p.Character then return end
    local head=p.Character:FindFirstChild("Head")
    if not head then return end
    local v=S.HitboxSize or 3
    head.Size=Vector3.new(v,v,v)
    head.Transparency=S.HitboxTransparency or 0
    if S.RainbowHitbox then head.Color=Color3.fromHSV((os.clock()*0.2)%1,1,1) else head.Color=S.HitboxColor end
    local oldMarker=head:FindFirstChild("HitboxMarker")
    if oldMarker then oldMarker:Destroy() end
    if S.HitboxVisual=="circle" then
        local marker=Instance.new("Part")
        marker.Name="HitboxMarker"; marker.Shape=Enum.PartType.Ball
        marker.Size=Vector3.new(v,v,v); marker.Transparency=0.7
        marker.Color=S.RainbowHitbox and Color3.fromHSV((os.clock()*0.2)%1,1,1) or S.HitboxColor
        marker.CanCollide=false; marker.Massless=true; marker.Anchored=false; marker.Parent=head
        local weld=Instance.new("WeldConstraint"); weld.Part0=head; weld.Part1=marker; weld.Parent=marker
    end
end

local function clearAllHitbox()
    for _,p in ipairs(P:GetPlayers()) do resetHeadForPlayer(p) end
end

local function isSQTarget(p)
    if not p or p==LP or not p.Character then return false end
    local hum=p.Character:FindFirstChildOfClass("Humanoid")
    local root=p.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health<=0 then return false end
    if S.SQTeamCheck and p.Team and LP.Team and p.Team==LP.Team then return false end
    return true
end

local function applySQ(p)
    if not isSQTarget(p) then return end
    local root=p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not sqOriginal[p] then
        sqOriginal[p]={Size=root.Size,Transparency=root.Transparency,Color=root.Color,Material=root.Material,CanCollide=root.CanCollide}
    end
    local s=S.SQSize or 5
    root.Size=Vector3.new(s,s,s)
    root.Transparency=S.SQTransparency or 0.7
    root.Color=S.RainbowSQ and Color3.fromHSV((os.clock()*0.2)%1,1,1) or (S.SQColor or C.ice)
    root.Material=Enum.Material.Neon
    root.CanCollide=false
end

local function resetSQ(p)
    if not p then return end
    local orig=sqOriginal[p]
    if not orig then return end
    sqOriginal[p]=nil
    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.Size=orig.Size; root.Transparency=orig.Transparency
    root.Color=orig.Color; root.Material=orig.Material; root.CanCollide=orig.CanCollide
end

local function clearAllSQ()
    for p in pairs(sqOriginal) do resetSQ(p) end
    sqOriginal={}
end

local function refreshAllHitboxes()
    if S.HitboxEnabled then
        if S.HitboxMode=="Head" then
            clearAllSQ()
            for _,p in ipairs(P:GetPlayers()) do applyHitboxToPlayer(p) end
        else
            clearAllHitbox()
            for _,p in ipairs(P:GetPlayers()) do applySQ(p) end
        end
    else
        clearAllHitbox(); clearAllSQ()
    end
end

local function setFullbright(on)
    S.Fullbright=on
    if on then
        savedLighting.Ambient=L.Ambient; savedLighting.Outdoor=L.OutdoorAmbient
        savedLighting.Brightness=L.Brightness; savedLighting.ClockTime=L.ClockTime
        savedLighting.FogEnd=L.FogEnd; savedLighting.GlobalShadows=L.GlobalShadows
        L.Ambient=Color3.fromRGB(255,255,255); L.OutdoorAmbient=Color3.fromRGB(255,255,255)
        L.Brightness=2; L.ClockTime=12; L.FogEnd=1e5; L.GlobalShadows=false
    elseif savedLighting.Ambient then
        L.Ambient=savedLighting.Ambient; L.OutdoorAmbient=savedLighting.Outdoor
        L.Brightness=savedLighting.Brightness; L.ClockTime=savedLighting.ClockTime
        L.FogEnd=savedLighting.FogEnd; L.GlobalShadows=savedLighting.GlobalShadows
    end
end

local function setAntiAFK(on)
    S.AntiAFK=on
    if on then
        if afkConn then afkConn:Disconnect(); afkConn=nil end
        afkConn=LP.Idled:Connect(function()
            pcall(function() VU:CaptureController(); VU:Button2Down(Vector2.new(0,0),camera.CFrame); task.wait(1); VU:Button2Up(Vector2.new(0,0),camera.CFrame) end)
        end)
    else
        if afkConn then afkConn:Disconnect(); afkConn=nil end
    end
end

local core=(gethui and gethui()) or (game:GetService("CoreGui")) or pg
local gui=make("ScreenGui",{Name="GBOHacks",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483647},core)
if syn and syn.protect_gui then syn.protect_gui(gui) end
if protect_gui then protect_gui(gui) end

local statusBar=make("Frame",{Name="StatusBar",Size=UDim2.fromOffset(400,28),Position=UDim2.new(1,-410,0,10),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=1000},gui)
corner(statusBar,8); stroke(statusBar,C.ice,1,0)
local statusLabel=make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="GBO HACKS | FPS: 60 | Ping: 0ms | --:--",TextColor3=C.textDark,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=1001},statusBar)

do
    local d,o,st=false,nil,nil
    statusBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;o=i.Position;st=statusBar.Position end
    end)
    U.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local df=i.Position-o
            statusBar.Position=UDim2.new(st.X.Scale,st.X.Offset+df.X,st.Y.Scale,st.Y.Offset+df.Y)
        end
    end)
    U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end
    end)
end

local frameCount=0
local lastFpsClock=os.clock()
local fps=60
task.spawn(function()
    while gui.Parent do
        local now=os.clock()
        frameCount=frameCount+1
        if now-lastFpsClock>=1 then fps=frameCount; frameCount=0; lastFpsClock=now end
        local ping=math.floor(LP:GetNetworkPing()*1000)
        local h=os.date("*t").hour; local m=os.date("*t").min
        local ampm="AM"; if h>=12 then ampm="PM" end
        local h12=h%12; if h12==0 then h12=12 end
        statusLabel.Text=string.format("GBO | FPS: %d | Ping: %dms | %02d:%02d %s",fps,ping,h12,m,ampm)
        task.wait(0.5)
    end
end)

local notes=make("Frame",{Name="Notifications",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.fromOffset(300,200),BackgroundTransparency=1},gui)
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,6)},notes)

local function notify(msg)
    pcall(function()
        if not gui.Parent or S.StreamMode then return end
        local n=make("TextLabel",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.panel,BackgroundTransparency=.05,Text=msg,TextColor3=C.textDark,TextSize=11,Font=Enum.Font.GothamBold,TextWrapped=true,LayoutOrder=os.clock()*1000,TextXAlignment=Enum.TextXAlignment.Center},notes)
        corner(n,8); local s=stroke(n,C.ice,1,0.3)
        task.delay(2.5,function()
            if not n.Parent then return end
            local tw=T:Create(n,TweenInfo.new(.3),{TextTransparency=1,BackgroundTransparency=1})
            T:Create(s,TweenInfo.new(.3),{Transparency=1}):Play()
            tw:Play(); tw.Completed:Wait(); if n.Parent then n:Destroy() end
        end)
    end)
end

local actions,names={},{} 
local function register(name,fn)
    actions[name]=fn
    if not table.find(names,name) then table.insert(names,name); table.sort(names) end
end

local welcome=make("Frame",{Name="Welcome",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0,ZIndex=2000},gui)
local wg=make("Frame",{Size=UDim2.fromScale(0.5,0.3),Position=UDim2.fromScale(0.25,0.35),BackgroundColor3=C.ice,BackgroundTransparency=0.85,ZIndex=2001},welcome)
corner(wg,20); stroke(wg,C.ice,0.5,2)
make("TextLabel",{Size=UDim2.fromOffset(700,60),Position=UDim2.new(.5,-350,.4,-30),BackgroundTransparency=1,Text="❄  GBO HACKS  (snow)",TextColor3=C.ice,Font=Enum.Font.GothamBlack,TextSize=40,ZIndex=2002},welcome)
make("TextLabel",{Size=UDim2.fromOffset(400,30),Position=UDim2.new(.5,-200,.5,-15),BackgroundTransparency=1,Text="v3.8  |  Loading...",TextColor3=C.textLight,Font=Enum.Font.GothamMedium,TextSize=16,ZIndex=2002},welcome)

task.delay(3,function()
    if welcome.Parent then
        local tw=T:Create(welcome,TweenInfo.new(0.5),{BackgroundTransparency=1})
        tw:Play(); tw.Completed:Wait(); welcome:Destroy()
    end
end)

local main=make("Frame",{Name="Main",Size=UDim2.fromOffset(980,620),Position=UDim2.new(.5,-490,.5,-310),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,ClipsDescendants=true},gui)
corner(main,12); stroke(main,C.ice,0.4,2)

local bgImage = make("ImageLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "rbxassetid://13550909835",
    ImageTransparency = 0.85,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 1
}, main)
corner(bgImage, 12)

local auraHolder=make("Frame",{Name="AuraHolder",Position=UDim2.fromOffset(-60,-60),Size=UDim2.new(1,120,1,120),BackgroundTransparency=1,ClipsDescendants=false,ZIndex=0},main)
local smokePuffs={}
task.spawn(function()
    while auraHolder.Parent and gui.Parent do
        if main.Visible and #smokePuffs<18 then
            local w=math.random(120,220)
            local h=math.random(30,60)
            local puff=make("Frame",{Size=UDim2.fromOffset(w,h),Position=UDim2.fromOffset(math.random(-40,math.max(1,math.floor(auraHolder.AbsoluteSize.X)-80)),auraHolder.AbsoluteSize.Y-math.random(0,90)),BackgroundColor3=Color3.fromRGB(195,222,246),BackgroundTransparency=0.9,BorderSizePixel=0,ZIndex=0},auraHolder)
            corner(puff,math.floor(h/2))
            make("UIGradient",{Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,1),
                NumberSequenceKeypoint.new(0.3,0.85),
                NumberSequenceKeypoint.new(0.7,0.85),
                NumberSequenceKeypoint.new(1,1)
            })},puff)
            puff.Rotation=math.random(-8,8)
            table.insert(smokePuffs,{obj=puff,life=0,maxLife=math.random(5,8),drift=(math.random(-15,15))/100,sway=math.random(-3,3)/10})
        end
        task.wait(0.5)
    end
end)
R.RenderStepped:Connect(function(dt)
    for i=#smokePuffs,1,-1 do
        local s=smokePuffs[i]
        if not s.obj.Parent then table.remove(smokePuffs,i) else
            s.life=s.life+dt
            local prog=s.life/s.maxLife
            s.obj.Position=s.obj.Position+UDim2.fromOffset(math.sin(s.life*1.1+s.sway)*1.2+s.drift*8,-14*dt)
            s.obj.Rotation=s.obj.Rotation+s.sway*6*dt
            local base=0.9+0.08*math.clamp(prog,0,1)
            s.obj.BackgroundTransparency=base
            if s.life>=s.maxLife then s.obj:Destroy(); table.remove(smokePuffs,i) end
        end
    end
end)

local top=make("Frame",{Name="Top",Size=UDim2.new(1,0,0,56),BackgroundColor3=C.panel,BorderSizePixel=0},main)
corner(top,12)
make("Frame",{Position=UDim2.new(0,0,1,-12),Size=UDim2.new(1,0,0,12),BackgroundColor3=C.panel,BorderSizePixel=0},top)
make("TextLabel",{Position=UDim2.fromOffset(20,0),Size=UDim2.fromOffset(500,56),BackgroundTransparency=1,Text="❄  GBO HACKS  (snow)  v3.8",TextColor3=C.textDark,TextSize=22,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},top)

local minimize=make("TextButton",{Position=UDim2.new(1,-95,0,13),Size=UDim2.fromOffset(36,30),BackgroundColor3=C.item,Text="—",TextColor3=C.textDark,TextSize=18,Font=Enum.Font.GothamBold},top)
corner(minimize,7)
local close=make("TextButton",{Position=UDim2.new(1,-51,0,13),Size=UDim2.fromOffset(36,30),BackgroundColor3=Color3.fromRGB(240,180,190),Text="×",TextColor3=C.textDark,TextSize=20,Font=Enum.Font.GothamBold},top)
corner(close,7)

task.delay(3,function() if not S.StreamMode then main.Visible=true end end)

do
    local d,o,st=false,nil,nil
    top.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;o=i.Position;st=main.Position end
    end)
    U.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local df=i.Position-o
            main.Position=UDim2.new(st.X.Scale,st.X.Offset+df.X,st.Y.Scale,st.Y.Offset+df.Y)
        end
    end)
    U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end
    end)
end

local floating=make("TextButton",{Name="FloatingLogo",Size=UDim2.fromOffset(54,54),Position=UDim2.new(0.5,-27,0,10),AnchorPoint=Vector2.new(0,0),BackgroundColor3=C.panel,Text="❄",TextColor3=C.ice,TextSize=28,Font=Enum.Font.GothamBold,Visible=false,AutoButtonColor=false,Active=true},gui)
corner(floating,16); stroke(floating,C.ice,2)

local floatDrag=false
local floatStartPos=nil
local floatStartMouse=nil
local floatMoved=false

floating.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        floatDrag=true; floatMoved=false
        floatStartPos=floating.Position; floatStartMouse=i.Position
    end
end)

U.InputChanged:Connect(function(i)
    if floatDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local df=i.Position-floatStartMouse
        if math.abs(df.X)>4 or math.abs(df.Y)>4 then floatMoved=true end
        floating.Position=UDim2.new(floatStartPos.X.Scale,floatStartPos.X.Offset+df.X,floatStartPos.Y.Scale,floatStartPos.Y.Offset+df.Y)
    end
end)

local function applyMouseState()
    if S.StreamMode then U.MouseBehavior=Enum.MouseBehavior.LockCenter; U.MouseIconEnabled=false; return end
    if S.MouseFree then U.MouseBehavior=Enum.MouseBehavior.Default; U.MouseIconEnabled=true end
end

-- ============================================================
-- AURA EMITTERS (used by ESP aura) — stronger
-- ============================================================
local function makeSSJAuraEmitters(parent)
    local list={}
    local core=Instance.new("ParticleEmitter")
    core.Texture="rbxassetid://243098098"
    core.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(0.3,Color3.fromRGB(255,255,180)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,220,0))})
    core.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6.5),NumberSequenceKeypoint.new(0.4,4.6),NumberSequenceKeypoint.new(1,0)})
    core.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.0),NumberSequenceKeypoint.new(0.6,0.25),NumberSequenceKeypoint.new(1,1)})
    core.Lifetime=NumberRange.new(0.7,1.2)
    core.Rate=420
    core.Speed=NumberRange.new(26,46)
    core.SpreadAngle=Vector2.new(45,45)
    core.LightEmission=1
    core.LightInfluence=0
    core.Acceleration=Vector3.new(0,26,0)
    core.Enabled=false
    core.Parent=parent
    table.insert(list,core)

    local spark=Instance.new("ParticleEmitter")
    spark.Texture="rbxassetid://6101261905"
    spark.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,100)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,180,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,120,0))})
    spark.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.6),NumberSequenceKeypoint.new(0.5,0.8),NumberSequenceKeypoint.new(1,0)})
    spark.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.2),NumberSequenceKeypoint.new(1,1)})
    spark.Lifetime=NumberRange.new(0.35,0.8)
    spark.Rate=280
    spark.Speed=NumberRange.new(36,72)
    spark.SpreadAngle=Vector2.new(180,180)
    spark.LightEmission=1
    spark.LightInfluence=0
    spark.Enabled=false
    spark.Parent=parent
    table.insert(list,spark)

    local glow=Instance.new("ParticleEmitter")
    glow.Texture="rbxassetid://243098098"
    glow.Color=ColorSequence.new(S.ESPColor)
    glow.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,16),NumberSequenceKeypoint.new(0.5,12),NumberSequenceKeypoint.new(1,0)})
    glow.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(0.5,0.5),NumberSequenceKeypoint.new(1,1)})
    glow.Lifetime=NumberRange.new(1.2,2.2)
    glow.Rate=90
    glow.Speed=NumberRange.new(4,11)
    glow.SpreadAngle=Vector2.new(50,50)
    glow.LightEmission=1
    glow.LightInfluence=0
    glow.Acceleration=Vector3.new(0,10,0)
    glow.Enabled=false
    glow.Parent=parent
    table.insert(list,glow)

    local side=Instance.new("ParticleEmitter")
    side.Texture="rbxassetid://243098098"
    side.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,200)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,150,0))})
    side.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6.5),NumberSequenceKeypoint.new(0.5,3.6),NumberSequenceKeypoint.new(1,0)})
    side.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.0),NumberSequenceKeypoint.new(0.7,0.3),NumberSequenceKeypoint.new(1,1)})
    side.Lifetime=NumberRange.new(0.5,1.1)
    side.Rate=220
    side.Speed=NumberRange.new(34,60)
    side.SpreadAngle=Vector2.new(180,180)
    side.LightEmission=1
    side.LightInfluence=0
    side.Enabled=false
    side.Parent=parent
    table.insert(list,side)

    local ember=Instance.new("ParticleEmitter")
    ember.Texture="rbxassetid://243098098"
    ember.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,240,180)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,200,80)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,120,0))})
    ember.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2.4),NumberSequenceKeypoint.new(0.5,1.4),NumberSequenceKeypoint.new(1,0)})
    ember.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.0),NumberSequenceKeypoint.new(0.6,0.3),NumberSequenceKeypoint.new(1,1)})
    ember.Lifetime=NumberRange.new(0.8,1.6)
    ember.Rate=160
    ember.Speed=NumberRange.new(9,18)
    ember.SpreadAngle=Vector2.new(180,180)
    ember.LightEmission=1
    ember.LightInfluence=0
    ember.Acceleration=Vector3.new(0,16,0)
    ember.Enabled=false
    ember.Parent=parent
    table.insert(list,ember)
    return list
end

function restorePanel()
    main.Visible=true
    floating.Visible=false
    applyMouseState()
end

function minimizePanel()
    main.Visible=false
    floating.Visible=true
    applyMouseState()
end

U.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        if floatDrag and not floatMoved then restorePanel() end
        floatDrag=false
    end
end)

minimize.Activated:Connect(minimizePanel)

close.Activated:Connect(function()
    if gui:FindFirstChild("ConfirmDialog") then return end
    local dialog=make("Frame",{Name="ConfirmDialog",Size=UDim2.fromOffset(320,160),Position=UDim2.new(.5,-160,.5,-80),BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=5000},gui)
    corner(dialog,12); stroke(dialog,C.ice,1,0)
    make("TextLabel",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,Text="Close the panel?",TextColor3=C.textDark,TextSize=15,Font=Enum.Font.GothamBold,TextWrapped=true,ZIndex=5001},dialog)
    local sim=make("TextButton",{Position=UDim2.fromOffset(20,90),Size=UDim2.fromOffset(130,44),BackgroundColor3=C.red,Text="YES",TextColor3=C.textLight,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=5001},dialog)
    corner(sim,8); stroke(sim,Color3.fromRGB(255,120,140),1,0.2)
    local nao=make("TextButton",{Position=UDim2.fromOffset(170,90),Size=UDim2.fromOffset(130,44),BackgroundColor3=C.accent,Text="NO",TextColor3=C.textLight,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=5001},dialog)
    corner(nao,8); stroke(nao,C.ice,1,0.2)
    sim.Activated:Connect(function()
        dialog:Destroy()
        if colorModal then colorModal:Destroy(); colorModal=nil end
        if plFrame then plFrame:Destroy() end
        gui:Destroy()
    end)
    nao.Activated:Connect(function() dialog:Destroy() end)
end)

for _,pos in ipairs({
    {UDim2.new(0,-6,0,-6)},{UDim2.new(1,-26,0,-6)},
    {UDim2.new(0,-6,1,-26)},{UDim2.new(1,-26,1,-26)}
}) do
    make("TextLabel",{Position=pos[1],Size=UDim2.fromOffset(32,32),BackgroundTransparency=1,Text="❄",TextColor3=C.ice,TextSize=26,Font=Enum.Font.GothamBold,ZIndex=15},main)
end

local snowHolder=make("Frame",{Name="SnowHolder",Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1,ClipsDescendants=true,ZIndex=999},main)
local snowflakes={}

task.spawn(function()
    while snowHolder.Parent and gui.Parent do
        if S.SnowEnabled and main.Visible and #snowflakes<40 then
            local flake=make("TextLabel",{Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(math.random(0,math.max(1,math.floor(snowHolder.AbsoluteSize.X)-16)),-16),BackgroundTransparency=1,Text="❄",TextColor3=Color3.fromRGB(200,230,255),TextSize=math.random(12,20),Font=Enum.Font.GothamBold,ZIndex=999},snowHolder)
            local spd=math.random(80,160)/100
            table.insert(snowflakes,{obj=flake,speed=spd})
        end
        task.wait(0.08)
    end
end)

R.RenderStepped:Connect(function(dt)
    if S.SnowEnabled and main.Visible then
        local h=snowHolder.AbsoluteSize.Y
        for i=#snowflakes,1,-1 do
            local f=snowflakes[i]
            if not f.obj.Parent then table.remove(snowflakes,i) else
                f.obj.Position=f.obj.Position+UDim2.fromOffset(math.sin(os.clock()*3+f.speed*10)*0.6,f.speed*100*dt)
                f.obj.TextTransparency=math.clamp(f.obj.Position.Y.Offset/math.max(h,1),0,1)
                if f.obj.Position.Y.Offset>h then f.obj:Destroy(); table.remove(snowflakes,i) end
            end
        end
    elseif not S.SnowEnabled then
        for i=#snowflakes,1,-1 do
            if snowflakes[i].obj.Parent then snowflakes[i].obj:Destroy() end
            table.remove(snowflakes,i)
        end
    end
end)

-- ============================================================
-- COLOR PICKER
-- ============================================================
local colorModal=nil
local function openColorPicker(title,initialColor,onChange)
    if colorModal then colorModal:Destroy() end
    colorModal=make("Frame",{Name="ColorPicker",Size=UDim2.fromOffset(420,320),Position=UDim2.new(.5,-210,.5,-160),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=9000},gui)
    corner(colorModal,14); stroke(colorModal,C.ice,1.2,0)
    local titleBar=make("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.ice,BorderSizePixel=0,ZIndex=9001},colorModal)
    corner(titleBar,14)
    make("Frame",{Position=UDim2.new(0,0,1,-14),Size=UDim2.new(1,0,0,14),BackgroundColor3=C.ice,BorderSizePixel=0,ZIndex=9001},titleBar)
    make("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text="❄ "..title,TextColor3=C.textLight,TextSize=15,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9002},titleBar)
    local xbtn=make("TextButton",{Position=UDim2.new(1,-40,0,6),Size=UDim2.fromOffset(30,24),BackgroundColor3=Color3.fromRGB(240,180,190),Text="×",TextColor3=C.textDark,TextSize=16,Font=Enum.Font.GothamBold,ZIndex=9002},titleBar)
    corner(xbtn,6)
    xbtn.Activated:Connect(function() if colorModal then colorModal:Destroy(); colorModal=nil end end)
    local d,o,st=false,nil,nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;o=i.Position;st=colorModal.Position end
    end)
    local dragMove=U.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local df=i.Position-o
            colorModal.Position=UDim2.new(st.X.Scale,st.X.Offset+df.X,st.Y.Scale,st.Y.Offset+df.Y)
        end
    end)
    local dragEnd=U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end
    end)
    local sv=make("Frame",{Position=UDim2.fromOffset(16,52),Size=UDim2.fromOffset(260,220),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9001},colorModal)
    corner(sv,8); stroke(sv,C.border,1,0.2)
    local baseColor=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromHSV(initialColor:ToHSV(),1,1),BorderSizePixel=0,ZIndex=9002},sv)
    corner(baseColor,8)
    local whiteOverlay=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9003},sv)
    corner(whiteOverlay,8)
    make("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=0},whiteOverlay)
    local blackOverlay=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=9004},sv)
    corner(blackOverlay,8)
    make("UIGradient",{Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Rotation=90},blackOverlay)
    local svKnob=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=2,BorderColor3=Color3.new(0,0,0),ZIndex=9005},sv)
    corner(svKnob,7)
    local hueBar=make("Frame",{Position=UDim2.fromOffset(292,52),Size=UDim2.fromOffset(20,220),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=9001},colorModal)
    corner(hueBar,6); stroke(hueBar,C.border,1,0.2)
    make("UIGradient",{Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))
    },Rotation=90},hueBar)
    local hueKnob=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.new(1,8,0,6),Position=UDim2.fromScale(.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=2,BorderColor3=Color3.new(0,0,0),ZIndex=9005},hueBar)
    corner(hueKnob,3)
    local preview=make("Frame",{Position=UDim2.fromOffset(328,52),Size=UDim2.fromOffset(74,60),BackgroundColor3=initialColor,BorderSizePixel=0,ZIndex=9001},colorModal)
    corner(preview,8); stroke(preview,C.border,1,0.1)
    local hexInput=make("TextBox",{Position=UDim2.fromOffset(328,120),Size=UDim2.fromOffset(74,24),BackgroundColor3=C.bg,Text="#------",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.Code,ZIndex=9001,ClearTextOnFocus=false},colorModal)
    corner(hexInput,6); stroke(hexInput,C.border,1,0.2)
    local h,s,v=initialColor:ToHSV()
    local updating=false
    local function refresh()
        updating=true
        local col=Color3.fromHSV(h,s,v)
        baseColor.BackgroundColor3=Color3.fromHSV(h,1,1)
        svKnob.Position=UDim2.new(1-s,0,v,0)
        hueKnob.Position=UDim2.new(.5,0,h,0)
        preview.BackgroundColor3=col
        local r,g,b=math.floor(col.R*255+0.5),math.floor(col.G*255+0.5),math.floor(col.B*255+0.5)
        hexInput.Text=string.format("#%02X%02X%02X",r,g,b)
        onChange(col)
        updating=false
    end
    local function updateFromSV(x,y)
        local sx=sv.AbsolutePosition.X; local sy=sv.AbsolutePosition.Y
        local sw=sv.AbsoluteSize.X; local sh=sv.AbsoluteSize.Y
        s=math.clamp(1-((x-sx)/sw),0,1); v=math.clamp((y-sy)/sh,0,1); refresh()
    end
    local function updateFromHue(y)
        local sy=hueBar.AbsolutePosition.Y; local sh=hueBar.AbsoluteSize.Y
        h=math.clamp((y-sy)/sh,0,1); refresh()
    end
    local svDrag,hueDrag=false,false
    sv.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svDrag=true; updateFromSV(i.Position.X,i.Position.Y) end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hueDrag=true; updateFromHue(i.Position.Y) end
    end)
    local moveConn=U.InputChanged:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
        if svDrag then updateFromSV(i.Position.X,i.Position.Y) end
        if hueDrag then updateFromHue(i.Position.Y) end
    end)
    local endConn=U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svDrag=false; hueDrag=false end
    end)
    hexInput.FocusLost:Connect(function()
        if updating then return end
        local txt=string.gsub(hexInput.Text,"#","")
        if #txt==6 then
            local ok=pcall(function()
                local r=tonumber(string.sub(txt,1,2),16) or 0
                local g=tonumber(string.sub(txt,3,4),16) or 0
                local b=tonumber(string.sub(txt,5,6),16) or 0
                local col=Color3.fromRGB(r,g,b); h,s,v=col:ToHSV(); refresh()
            end)
            if not ok then refresh() end
        else refresh() end
    end)
    colorModal.Destroying:Connect(function() moveConn:Disconnect(); endConn:Disconnect(); dragMove:Disconnect(); dragEnd:Disconnect() end)
    refresh()
end

-- ============================================================
-- UI BUILDER
-- ============================================================
local sidebarScroll=make("ScrollingFrame",{Position=UDim2.fromOffset(12,68),Size=UDim2.new(0,200,1,-84),BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.ice,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=10},main)
corner(sidebarScroll,10)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sidebarScroll)
make("UIPadding",{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,12)},sidebarScroll)
local sidebar=sidebarScroll
local content=make("Frame",{Position=UDim2.fromOffset(224,68),Size=UDim2.new(1,-236,1,-84),BackgroundTransparency=1,ZIndex=10},main)

local pages={
    {"Home","⌂"},{"ESP","◉"},{"Aim","◎"},{"Silent Aim (RCL)","○"},
    {"Triggerbot","⌖"},{"Hitbox","▣"},{"Others","✦"},{"Movement","↗"},{"Troll","♙"},
    {"List Player","☰"},{"Keybinds","⌨"},{"Credits","©"}
}
local frames={}
local nav={}
local savedKeys={}
local waiting=nil

local function showPage(name)
    for n,f in pairs(frames) do f.Visible=n==name end
    for n,b in pairs(nav) do
        local yes=n==name
        b.BackgroundColor3=yes and C.ice or C.item
        b.TextColor3=yes and C.textLight or C.textDark
    end
end

for i,e in ipairs(pages) do
    local name,symbol=e[1],e[2]
    local b=make("TextButton",{Name=name,LayoutOrder=i,Size=UDim2.new(1,0,0,42),BackgroundColor3=C.item,Text=symbol.."   "..name,TextColor3=C.textDark,TextSize=14,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=11},sidebar)
    corner(b,7)
    make("UIPadding",{PaddingLeft=UDim.new(0,10)},b)
    nav[name]=b
    b.Activated:Connect(function() showPage(name) end)
    local p=make("ScrollingFrame",{Name=name.."Page",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.ice,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ZIndex=11},content)
    make("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},p)
    make("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)},p)
    frames[name]=p
end

local function section(p,t) return make("TextLabel",{Size=UDim2.new(1,-5,0,32),BackgroundTransparency=1,Text=t,TextColor3=C.accent,TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},frames[p]) end
local function info(p,t) return make("TextLabel",{Size=UDim2.new(1,-5,0,44),BackgroundTransparency=1,Text=t,TextWrapped=true,TextColor3=C.gray,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},frames[p]) end

local function buildRow(parent,desc,height)
    local row=make("Frame",{Size=UDim2.new(1,-5,0,height or 44),BackgroundColor3=C.item,BorderSizePixel=0,ZIndex=12,ClipsDescendants=true},frames[parent])
    corner(row,8); stroke(row)
    local descBox=make("TextLabel",{Size=UDim2.new(1,-20,0,0),Position=UDim2.fromOffset(10,height or 44),BackgroundTransparency=1,Text=desc or "",TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=12},row)
    local expanded=false
    local function toggleDesc()
        expanded=not expanded
        if expanded then descBox.Size=UDim2.new(1,-20,0,40); row.Size=UDim2.new(1,-5,0,(height or 44)+44)
        else descBox.Size=UDim2.new(1,-20,0,0); row.Size=UDim2.new(1,-5,0,height or 44) end
        return expanded
    end
    return row,descBox,toggleDesc
end

local function addArrow(parent,onToggle)
    local arrow=make("TextButton",{Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-26,0,4),BackgroundTransparency=1,Text="▼",TextColor3=C.accent,TextSize=12,Font=Enum.Font.SourceSansBold,TextScaled=true,AutoButtonColor=false,ZIndex=13},parent)
    local up=false
    arrow.Activated:Connect(function() up=not up; arrow.Text=up and "▲" or "▼"; onToggle(up) end)
end

local function toggle(p,t,settingName,default,callback,desc)
    local value=default==true; S[settingName]=value
    local name=p.." / "..t
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local body=make("TextButton",{Size=UDim2.new(1,-26,0,44),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=13},row)
    make("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-160,1,0),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},body)
    local ind=make("TextLabel",{Position=UDim2.new(1,-88,.5,-11),Size=UDim2.fromOffset(46,22),BackgroundColor3=value and C.green or C.border,Text=value and "ON" or "OFF",TextColor3=C.textLight,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=13},row)
    corner(ind,10)
    addArrow(row,function() toggleDesc() end)
    local function set(v,notice)
        value=v; S[settingName]=v
        ind.Text=value and "ON" or "OFF"
        ind.BackgroundColor3=value and C.green or C.border
        if callback then pcall(callback,value) end
        if notice then notify(t..(value and " enabled" or " disabled")) end
    end
    body.Activated:Connect(function() set(not value,true) end)
    register(name,function() set(not value,true) end)
    table.insert(toggleSetters,{name=settingName,set=set})
    return function() return value end,set
end

local function slider(p,t,min,max,default,settingName,callback,desc)
    local value=math.clamp(default,min,max); S[settingName]=value
    local row,descBox,toggleDesc=buildRow(p,desc,66)
    make("TextLabel",{Position=UDim2.fromOffset(14,5),Size=UDim2.new(1,-100,0,24),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},row)
    local num=make("TextLabel",{Position=UDim2.new(1,-85,0,5),Size=UDim2.fromOffset(50,24),BackgroundTransparency=1,Text=tostring(value),TextColor3=C.accent,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12},row)
    local bar=make("Frame",{Position=UDim2.new(0,14,0,40),Size=UDim2.new(1,-50,0,8),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=12},row)
    corner(bar,5)
    local alpha=(value-min)/(max-min)
    local fill=make("Frame",{Size=UDim2.new(alpha,0,1,0),BackgroundColor3=C.ice,BorderSizePixel=0,ZIndex=12},bar)
    corner(fill,5)
    local knob=make("TextButton",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(alpha,0,.5,0),Size=UDim2.fromOffset(16,16),BackgroundColor3=C.textLight,Text="",AutoButtonColor=false,ZIndex=13},bar)
    corner(knob,7)
    addArrow(row,function() toggleDesc() end)
    local dragging=false
    local function setX(x)
        local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        value=math.floor(min+(max-min)*a+.5); S[settingName]=value
        fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,.5,0); num.Text=tostring(value)
        if callback then pcall(callback,value) end
    end
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; setX(i.Position.X) end end)
    local m=U.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setX(i.Position.X) end end)
    local e=U.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    row.Destroying:Connect(function() m:Disconnect(); e:Disconnect() end)
    return function() return value end
end

-- ============================================================
-- TEXT ENTRY with live player autocomplete
-- ============================================================
local activeDropdown=nil
local function hideActiveDropdown()
    if activeDropdown and activeDropdown.Parent then
        activeDropdown.Visible=false
        for _,c in ipairs(activeDropdown:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end
end

local function textEntry(p,t,placeholder,callback,desc)
    local row,descBox,toggleDesc=buildRow(p,desc,70)
    make("TextLabel",{Position=UDim2.fromOffset(12,4),Size=UDim2.new(1,-40,0,22),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},row)
    local input=make("TextBox",{Position=UDim2.fromOffset(11,30),Size=UDim2.new(1,-42,0,30),BackgroundColor3=C.bg,Text="",PlaceholderText=placeholder or "Type here...",PlaceholderColor3=C.gray,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=14},row)
    corner(input,6); stroke(input)

    local dropdown=make("Frame",{Name="AutoDrop",Size=UDim2.fromOffset(0,0),BackgroundColor3=C.panel,BorderSizePixel=0,Visible=false,ZIndex=9999,ClipsDescendants=true},gui)
    corner(dropdown,6); stroke(dropdown,C.ice,1,0.2)
    local dropScroll=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.ice,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},dropdown)
    make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},dropScroll)

    local function buildList()
        for _,c in ipairs(dropScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local q=string.lower(input.Text or "")
        local count=0
        for _,plr in ipairs(P:GetPlayers()) do
            if plr~=LP then
                local pn=string.lower(plr.Name)
                if q=="" or string.find(pn,q,1,true) then
                    local b=make("TextButton",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.item,BackgroundTransparency=0.2,Text=plr.Name,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=true,ZIndex=10000},dropScroll)
                    corner(b,4)
                    make("UIPadding",{PaddingLeft=UDim.new(0,8)},b)
                    b.Activated:Connect(function()
                        input.Text=plr.Name
                        if callback then pcall(callback,plr.Name,true) end
                        hideActiveDropdown()
                    end)
                    count=count+1
                end
            end
        end
        if count==0 then
            local b=make("TextButton",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.panel,Text="No players found",TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,AutoButtonColor=false,ZIndex=10000},dropScroll)
            corner(b,4)
        end
    end

    local function positionDropdown()
        local ap=input.AbsolutePosition
        local as_=input.AbsoluteSize
        local rows=0
        for _,c in ipairs(dropScroll:GetChildren()) do
            if c:IsA("TextButton") then rows=rows+1 end
        end
        local h=math.min(180,rows*28+8)
        dropdown.Position=UDim2.fromOffset(ap.X,ap.Y+as_.Y+2)
        dropdown.Size=UDim2.fromOffset(as_.X,h)
        dropScroll.CanvasSize=UDim2.new(0,0,0,rows*28+4)
    end

    input.Focused:Connect(function()
        hideActiveDropdown()
        activeDropdown=dropdown
        buildList()
        positionDropdown()
        dropdown.Visible=true
    end)
    input:GetPropertyChangedSignal("Text"):Connect(function()
        if activeDropdown==dropdown and dropdown.Visible then
            buildList()
            positionDropdown()
        end
    end)
    input.FocusLost:Connect(function(enter)
        task.delay(0.12,function()
            if activeDropdown==dropdown then hideActiveDropdown() end
            if callback then pcall(callback,input.Text,enter) end
        end)
    end)
    row.Destroying:Connect(function()
        if dropdown.Parent then dropdown:Destroy() end
    end)
    return input
end

-- ============================================================
-- DROPDOWN option picker (used by hitbox mode + aim parts)
-- ============================================================
local function optionPicker(p,t,settingName,options,callback,desc)
    local value=S[settingName] or options[1]
    S[settingName]=value
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t..": "..value,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    addArrow(row,function() toggleDesc() end)

    local dropdown=make("Frame",{Size=UDim2.fromOffset(240,0),BackgroundColor3=C.panel,BorderSizePixel=0,Visible=false,ZIndex=9999,ClipsDescendants=true},gui)
    corner(dropdown,6); stroke(dropdown,C.ice,1,0.2)
    local listFrame=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColorId=C.ice,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},dropdown)
    make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},listFrame)

    local function refreshList()
        for _,c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _,opt in ipairs(options) do
            local isSelected=opt==value
            local ob=make("TextButton",{Size=UDim2.new(1,0,0,26),BackgroundColor3=isSelected and C.ice or C.item,BackgroundTransparency=isSelected and 0 or 0.2,Text=opt,TextColor3=isSelected and C.textLight or C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=true,ZIndex=10000},listFrame)
            corner(ob,4)
            make("UIPadding",{PaddingLeft=UDim.new(0,8)},ob)
            ob.Activated:Connect(function()
                value=opt; S[settingName]=opt
                b.Text=t..": "..value
                dropdown.Visible=false
                if callback then pcall(callback,opt) end
            end)
        end
    end

    local function positionDropdown()
        local ap=b.AbsolutePosition
        local as_=b.AbsoluteSize
        local h=math.min(240,#options*28+8)
        dropdown.Position=UDim2.fromOffset(ap.X,ap.Y+as_.Y+2)
        dropdown.Size=UDim2.fromOffset(as_.X,h)
        listFrame.CanvasSize=UDim2.new(0,0,0,#options*28+4)
    end

    b.Activated:Connect(function()
        if dropdown.Visible then
            dropdown.Visible=false
            return
        end
        hideActiveDropdown()
        activeDropdown=dropdown
        refreshList()
        positionDropdown()
        dropdown.Visible=true
    end)

    row.Destroying:Connect(function()
        if dropdown.Parent then dropdown:Destroy() end
    end)
    return function() return value end
end

local function actionButton(p,t,callback,desc)
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function() pcall(callback) end)
    return b
end

local function colorButton(p,t,settingName,desc)
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text="",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    make("TextLabel",{Position=UDim2.fromOffset(14,0),Size=UDim2.new(1,-160,1,0),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},b)
    local swatch=make("Frame",{Position=UDim2.new(1,-80,.5,-12),Size=UDim2.fromOffset(64,24),BackgroundColor3=S[settingName],BorderSizePixel=0,ZIndex=13},b)
    corner(swatch,6); stroke(swatch,C.border,1,0.2)
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function()
        openColorPicker(t,S[settingName],function(col)
            S[settingName]=col
            swatch.BackgroundColor3=col
            if settingName=="ESPColor" then
                for _,data in pairs(highlights) do
                    if data.highlight then data.highlight.FillColor=col; data.highlight.OutlineColor=col end
                    if data.boxStroke then data.boxStroke.Color=col end
                    if data.box then data.box.BackgroundColor3=col end
                end
            end
        end)
    end)
    return function() return S[settingName] end
end

local function rainbowButton(p,t,settingName,callback,desc)
    local name=p.." / "..t
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t..": OFF",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    local enabled=false
    local function set(v,notice)
        enabled=v; b.Text=t..(v and ": ON" or ": OFF")
        if settingName then S[settingName]=v end
        if callback then pcall(callback,v) end
        if notice then notify(t..(v and " enabled" or " disabled")) end
    end
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function() set(not enabled,true) end)
    register(name,function() set(not enabled,true) end)
    table.insert(toggleSetters,{name="Rainbow_"..t,set=set})
    return function() return enabled end
end

local function keyButton(p,t,settingName,default,desc)
    local key=default; S[settingName]=key
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t..": ["..key.Name.."]",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function()
        if waiting then return end
        waiting={button=b,callback=function(k) key=k; S[settingName]=k; b.Text=t..": ["..k.Name.."]" end}
        b.Text=t..": [Press a key]"
    end)
    return function() return key end
end

-- PLAYER LIST
local plFrame=make("Frame",{Name="PlayerListPanel",Size=UDim2.fromOffset(800,540),Position=UDim2.new(0.5,-400,0.5,-270),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false,ZIndex=5000},gui)
corner(plFrame,12); stroke(plFrame,C.ice,0.4,2)
local plTop=make("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=5001},plFrame)
corner(plTop,12)
make("Frame",{Position=UDim2.new(0,0,1,-12),Size=UDim2.new(1,0,0,12),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=5001},plTop)
make("TextLabel",{Position=UDim2.fromOffset(20,0),Size=UDim2.new(1,-100,1,0),BackgroundTransparency=1,Text="❄  GBO HACKS  (List Player)",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=22,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5002},plTop)
local plClose=make("TextButton",{Position=UDim2.new(1,-51,0,13),Size=UDim2.fromOffset(36,30),BackgroundColor3=Color3.fromRGB(240,180,190),Text="×",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=20,BorderSizePixel=0,ZIndex=5002},plTop)
corner(plClose,7)
plClose.Activated:Connect(function() plFrame.Visible=false end)
do
    local d,o,st=false,nil,nil
    plTop.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;o=i.Position;st=plFrame.Position end
    end)
    U.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local df=i.Position-o; plFrame.Position=UDim2.new(st.X.Scale,st.X.Offset+df.X,st.Y.Scale,st.Y.Offset+df.Y)
        end
    end)
    U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end
    end)
end
local plSearch=make("TextBox",{Position=UDim2.fromOffset(20,70),Size=UDim2.new(0,350,0,35),BackgroundColor3=C.item,PlaceholderText="Search player name...",TextColor3=C.textDark,PlaceholderColor3=C.gray,Font=Enum.Font.Gotham,TextSize=14,ZIndex=5001,BorderSizePixel=0},plFrame)
corner(plSearch,8); stroke(plSearch)
local plList=make("ScrollingFrame",{Position=UDim2.fromOffset(20,115),Size=UDim2.new(0,350,1,-135),BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.ice,ZIndex=5001,ClipsDescendants=true},plFrame)
corner(plList,8)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},plList)
local rightPanel=make("Frame",{Position=UDim2.fromOffset(390,70),Size=UDim2.new(1,-410,1,-90),BackgroundColor3=C.item,ZIndex=5001,ClipsDescendants=true,BorderSizePixel=0},plFrame)
corner(rightPanel,8)
local selectedPlayerName=nil
local selectedPlayerLabel=make("TextLabel",{Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,0,30),BackgroundTransparency=1,Text="Select a player",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5002},rightPanel)
local blDisplay=make("ScrollingFrame",{Position=UDim2.fromOffset(10,270),Size=UDim2.new(0,150,0,170),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.ice,ZIndex=5002},rightPanel)
make("UIListLayout",{Padding=UDim.new(0,2)},blDisplay)
local wlDisplay=make("ScrollingFrame",{Position=UDim2.fromOffset(170,270),Size=UDim2.new(0,150,0,170),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.ice,ZIndex=5002},rightPanel)
make("UIListLayout",{Padding=UDim.new(0,2)},wlDisplay)
local function refreshListsDisplay()
    for _,c in ipairs(blDisplay:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    for _,name in ipairs(S.Blacklist) do
        make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="[BL] "..name,TextColor3=Color3.fromRGB(220,80,100),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5002},blDisplay)
    end
    for _,c in ipairs(wlDisplay:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    for _,name in ipairs(S.Whitelist) do
        make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="[WL] "..name,TextColor3=Color3.fromRGB(80,200,120),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5002},wlDisplay)
    end
end
local function createActionBtn(text,y,callback,color)
    local btn=make("TextButton",{Position=UDim2.fromOffset(10,y),Size=UDim2.new(1,-20,0,30),BackgroundColor3=color or C.bg,Text=text,TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=5002,BorderSizePixel=0},rightPanel)
    corner(btn,6); stroke(btn)
    btn.Activated:Connect(callback)
    return btn
end
createActionBtn("Add to Whitelist",50,function()
    if selectedPlayerName and not table.find(S.Whitelist,selectedPlayerName) then
        table.insert(S.Whitelist,selectedPlayerName); notify("Added WL: "..selectedPlayerName); refreshListsDisplay()
    end
end)
createActionBtn("Remove from Whitelist",90,function()
    if selectedPlayerName then
        local i=table.find(S.Whitelist,selectedPlayerName)
        if i then table.remove(S.Whitelist,i); notify("Removed WL: "..selectedPlayerName); refreshListsDisplay() end
    end
end)
createActionBtn("Add to Blacklist",140,function()
    if selectedPlayerName and not table.find(S.Blacklist,selectedPlayerName) then
        table.insert(S.Blacklist,selectedPlayerName); notify("Added BL: "..selectedPlayerName); refreshListsDisplay()
    end
end,Color3.fromRGB(255,150,150))
createActionBtn("Remove from Blacklist",180,function()
    if selectedPlayerName then
        local i=table.find(S.Blacklist,selectedPlayerName)
        if i then table.remove(S.Blacklist,i); notify("Removed BL: "..selectedPlayerName); refreshListsDisplay() end
    end
end)
createActionBtn("Clear Whitelist",225,function()
    S.Whitelist={}; notify("Whitelist cleared"); refreshListsDisplay()
end,Color3.fromRGB(255,220,150))
createActionBtn("Clear Blacklist",225+0,function() end)
-- place Clear Blacklist next to Clear Whitelist on second line
local cbBtn=make("TextButton",{Position=UDim2.fromOffset(10,225),Size=UDim2.new(0.5,-15,0,30),BackgroundColor3=Color3.fromRGB(255,150,150),Text="Clear Whitelist",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=5002,BorderSizePixel=0},rightPanel)
corner(cbBtn,6); stroke(cbBtn)
cbBtn.Text="Clear Blacklist"
-- simpler: rebuild two clear buttons cleanly
for _,c in ipairs(rightPanel:GetChildren()) do
    if c:IsA("TextButton") and (c.Text=="Clear Whitelist" or c.Text=="Clear Blacklist") then c:Destroy() end
end
local cwBtn=make("TextButton",{Position=UDim2.fromOffset(10,225),Size=UDim2.new(0.5,-15,0,30),BackgroundColor3=Color3.fromRGB(255,220,150),Text="Clear Whitelist",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=5002,BorderSizePixel=0},rightPanel)
corner(cwBtn,6); stroke(cwBtn)
cwBtn.Activated:Connect(function() S.Whitelist={}; notify("Whitelist cleared"); refreshListsDisplay() end)
local cbBtn2=make("TextButton",{Position=UDim2.new(0.5,5,0,225),Size=UDim2.new(0.5,-15,0,30),BackgroundColor3=Color3.fromRGB(255,150,150),Text="Clear Blacklist",TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=12,ZIndex=5002,BorderSizePixel=0},rightPanel)
corner(cbBtn2,6); stroke(cbBtn2)
cbBtn2.Activated:Connect(function() S.Blacklist={}; notify("Blacklist cleared"); refreshListsDisplay() end)
make("TextLabel",{Position=UDim2.fromOffset(10,260),Size=UDim2.new(1,-20,0,20),BackgroundTransparency=1,Text="Current Lists:",TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5002},rightPanel)
local function refreshPlayerList()
    for _,c in ipairs(plList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local query=string.lower(plSearch.Text)
    for _,p in ipairs(P:GetPlayers()) do
        if p~=LP and (query=="" or string.find(string.lower(p.Name),query,1,true)) then
            local row=make("TextButton",{Size=UDim2.new(1,-10,0,40),BackgroundColor3=C.bg,Text="",AutoButtonColor=false,ZIndex=5002,BorderSizePixel=0},plList)
            corner(row,6); stroke(row)
            local img=make("ImageLabel",{Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1,Image="rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=48&h=48",ZIndex=5003},row)
            corner(img,15)
            make("TextLabel",{Position=UDim2.fromOffset(45,0),Size=UDim2.new(1,-45,1,0),BackgroundTransparency=1,Text=p.Name,TextColor3=C.textDark,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5003},row)
            row.Activated:Connect(function() selectedPlayerName=p.Name; selectedPlayerLabel.Text="Selected: "..p.Name end)
        end
    end
end
plSearch:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)
plFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if plFrame.Visible then refreshPlayerList(); refreshListsDisplay() end
end)
-- auto-remove from lists when player leaves
P.PlayerRemoving:Connect(function(p)
    local changed=false
    for i=#S.Whitelist,1,-1 do
        if S.Whitelist[i]==p.Name then table.remove(S.Whitelist,i); changed=true end
    end
    for i=#S.Blacklist,1,-1 do
        if S.Blacklist[i]==p.Name then table.remove(S.Blacklist,i); changed=true end
    end
    if changed then pcall(refreshListsDisplay) end
end)

-- ============================================================
-- HOME
-- ============================================================
section("Home","Welcome to GBO HACKS")
info("Home","Icy interface + real features.")
local avatar=make("ImageLabel",{Size=UDim2.fromOffset(80,80),BackgroundColor3=C.item,Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=12},frames.Home)
corner(avatar,40)
task.spawn(function()
    local ok,url=pcall(function() return P:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
    if ok and avatar.Parent then avatar.Image=url end
end)
make("TextLabel",{Size=UDim2.new(1,-5,0,28),BackgroundTransparency=1,Text=LP.DisplayName.."  (@"..LP.Name..")",TextColor3=C.textDark,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},frames.Home)
keyButton("Home","Panel toggle key","ToggleKey",Enum.KeyCode.RightShift,"Keyboard shortcut that opens/closes the panel.")
keyButton("Home","Stream mode key","StreamKey",Enum.KeyCode.F1,"Hides the whole panel instantly — for recording.")
toggle("Home","Unlock Mouse","MouseFree",false,function(state)
    if state then notify("Mouse unlocked!") else notify("Mouse back to game control.") end
    applyMouseState()
end,"Frees the mouse cursor so you can drag and click the panel.")
toggle("Home","Snow effect","SnowEnabled",true,function(state)
    if not state then
        for i=#snowflakes,1,-1 do
            if snowflakes[i].obj.Parent then snowflakes[i].obj:Destroy() end
            table.remove(snowflakes,i)
        end
    end
end,"Falling snowflakes inside the panel.")
toggle("Home","Fullbright","Fullbright",false,function(state) setFullbright(state) end,"Brightens the entire map.")
toggle("Home","Anti AFK","AntiAFK",false,function(state) setAntiAFK(state) end,"Prevents kick for inactivity.")
actionButton("Home","↺  Restore Defaults",function()
    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED;hum.JumpPower=DEF_JUMP;hum.PlatformStand=false end
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
    end
    S.MoveSpeed=DEF_SPEED;S.JumpPower=DEF_JUMP;S.FlySpeed=50
    clearAllHitbox(); clearAllSQ(); setFullbright(false); setAntiAFK(false)
    camera.FieldOfView=originalFOV; applyMouseState(); notify("Defaults restored")
end,"Returns the character to normal game behavior.")
section("Home","About the Panel:")
info("Home","GBO HACKS v3.8 (snow) — PvP panel.")
local rejoin=make("TextButton",{Size=UDim2.new(1,-5,0,44),BackgroundColor3=C.item,Text="Rejoin",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=12},frames.Home)
corner(rejoin,8)
rejoin.Activated:Connect(function() pcall(function() TP:Teleport(game.PlaceId,LP) end) end)

-- ============================================================
-- ESP
-- ============================================================
section("ESP","Visual settings")
info("ESP","Box, skeleton, name, distance, health, traces e cores.")
toggle("ESP","ESP enabled","ESP",false,nil,"Master toggle para todos os elementos ESP.")
toggle("ESP","Name ESP","Name",false,nil,"Mostra nomes acima das cabeças.")
toggle("ESP","Show distance","Distance",false,nil,"Mostra distância abaixo do personagem.")
toggle("ESP","Health ESP","Health",false,nil,"Desenha barra de vida.")
toggle("ESP","Box ESP","Box",false,nil,"Desenha box ao redor dos jogadores.")
toggle("ESP","Aura ESP","Aura",false,nil,"Aura SSJ God — explosão de energia ao redor do inimigo.")
toggle("ESP","Skeleton ESP","Skeleton",false,nil,"Desenha ossos nos jogadores.")
toggle("ESP","Traces ESP","ESPTraces",false,nil,"Linhas do seu personagem até cada alvo.")
toggle("ESP","Team check","ESPTeamCheck",false,nil,"Ignora companheiros de equipe.")
toggle("ESP","Wall check (Color)","ESPWallCheck",false,nil,"Vermelho quando ocluído, verde quando visível.")
slider("ESP","ESP Transparency",0,100,50,"ESPTransparency",nil,"Transparência do fill da box (0 = sólido).")
colorButton("ESP","ESP color","ESPColor","Escolha a cor do ESP.")
rainbowButton("ESP","Rainbow ESP color","RainbowESP",nil,"Rainbow independente só para ESP.")
slider("ESP","Max distance",50,2000,500,"MaxDist",nil,"Distância máxima para renderizar o ESP.")

-- AIM
section("Aim","Aim settings")
info("Aim","Aimbot baseado na câmera. Segure a tecla para travar no alvo.")
toggle("Aim","Aim enabled","Aimbot",false,nil,"Trava a câmera na parte escolhida do alvo.")
toggle("Aim","Team check","AimTeamCheck",false,nil,"Pula companheiros.")
toggle("Aim","Wall check","AimWallCheck",false,nil,"Exige linha de visão.")
optionPicker("Aim","Aim part","AimPart",AIM_PART_NAMES,nil,"Onde grudar o tiro.")
toggle("Aim","Show FOV","ShowAimFOV",false,nil,"Desenha o círculo de FOV do aim.")
slider("Aim","FOV size",20,500,120,"AimFOV",nil,"Raio do FOV do aim.")
colorButton("Aim","FOV color","AimFOVColor","Cor do círculo de FOV do aim.")
rainbowButton("Aim","Rainbow Aim FOV","RainbowAimFOV",nil,"Rainbow independente para o FOV do aim.")
keyButton("Aim","Aim key","AimKey",Enum.KeyCode.Q,"Segure para ativar o aim.")

-- SILENT
local rcl="Silent Aim (RCL)"
section(rcl,"Silent Aim (RCL) settings")
info(rcl,"RCL só no mouse: trava o mouse na parte escolhida do alvo.")
toggle(rcl,"Enabled","SilentAim",false,nil,"Trava o mouse na parte escolhida enquanto MB1 pressionado.")
toggle(rcl,"Team check","SilentTeamCheck",false,nil,"Pula companheiros.")
toggle(rcl,"Wall check","SilentWallCheck",false,nil,"Exige linha de visão.")
optionPicker(rcl,"Silent part","SilentPart",AIM_PART_NAMES,nil,"Onde grudar o tiro do silent.")
toggle(rcl,"Show FOV","ShowSilentFOV",false,nil,"Desenha o círculo de FOV ao redor do mouse.")
slider(rcl,"FOV size",20,500,100,"SilentFOV",nil,"Raio do FOV silent ao redor do mouse.")
colorButton(rcl,"FOV color","SilentFOVColor","Cor do FOV silent.")
rainbowButton(rcl,"Rainbow Silent FOV","RainbowSilentFOV",nil,"Rainbow independente para o FOV silent.")
keyButton(rcl,"Silent key","SilentKey",Enum.KeyCode.E,"Segure para ativar o silent aim.")

-- TRIGGER
section("Triggerbot","Triggerbot settings")
info("Triggerbot","Atira automaticamente quando um alvo está no FOV.")
toggle("Triggerbot","Enabled","TriggerBot",false,nil,"Atira quando um alvo entra no FOV.")
toggle("Triggerbot","Silent lock","TriggerLock",false,nil,"Trava câmera no alvo enquanto atira.")
toggle("Triggerbot","Wallbang","TriggerWallBang",false,nil,"Atira através de paredes.")
toggle("Triggerbot","Team check","TriggerTeamCheck",false,nil,"Pula companheiros.")
toggle("Triggerbot","Wall check","TriggerWallCheck",false,nil,"Exige linha de visão.")
optionPicker("Triggerbot","Trigger part","TriggerPart",AIM_PART_NAMES,nil,"Parte do alvo usada pelo trigger.")
toggle("Triggerbot","Show FOV","ShowTriggerFOV",false,nil,"Desenha o círculo de FOV do trigger.")
slider("Triggerbot","FOV size",10,400,80,"TriggerFOV",nil,"Raio do FOV do trigger.")
colorButton("Triggerbot","FOV color","TriggerFOVColor","Cor do FOV do trigger.")
rainbowButton("Triggerbot","Rainbow Trigger FOV","RainbowTriggerFOV",nil,"Rainbow independente para o FOV do trigger.")
keyButton("Triggerbot","Trigger key","TriggerKey",Enum.KeyCode.T,"Segure para ativar o triggerbot.")

-- HITBOX
local hb="Hitbox"
section(hb,"Hitbox expander")
info(hb,"Expande a hitbox da cabeça. Reaplica ao respawnar.")
toggle(hb,"Hitbox enabled","HitboxEnabled",false,function() refreshAllHitboxes() end,"Expande a hitbox da cabeça de todos.")
optionPicker(hb,"Mode","HitboxMode",{"Head","Square"},function()
    refreshAllHitboxes()
    notify("Mode: "..S.HitboxMode)
end,"Cabeça ou hitbox quadrada.")
slider(hb,"Hitbox size",1,100,3,"HitboxSize",function(v)
    S.SQSize=v; refreshAllHitboxes()
end,"Tamanho da hitbox em studs.")
slider(hb,"Hitbox transparency",0,100,0,"HitboxTransparency",function(v)
    S.HitboxTransparency=v/100; S.SQTransparency=v/100; refreshAllHitboxes()
end,"Transparência da hitbox (0 = sólida).")
colorButton(hb,"Hitbox color","HitboxColor","Cor da hitbox da cabeça.")
rainbowButton(hb,"Rainbow head hitbox","RainbowHitbox",function(v) refreshAllHitboxes() end,"Cicla a cor da hitbox.")
colorButton(hb,"Square hitbox color","SQColor","Cor da hitbox quadrada.")
rainbowButton(hb,"Rainbow square hitbox","RainbowSQ",function(v) refreshAllHitboxes() end,"Cicla a cor da hitbox quadrada.")
actionButton(hb,"Swap visual (head / circle)",function()
    S.HitboxVisual=S.HitboxVisual=="head" and "circle" or "head"
    refreshAllHitboxes()
    notify("Visual: "..(S.HitboxVisual=="circle" and "Circle" or "Head"))
end,"Alterna entre malha de cabeça real e bola circular.")

-- OTHERS
local ot="Others"
section(ot,"Anti-Aim")
toggle(ot,"Anti-Aim enabled","AntiAim",false,nil,"Manipula sua direção de mira localmente.")
optionPicker(ot,"Mode","AntiAimMode",{"Jitter","Spin","Random"},nil,"Alterna entre Jitter, Spin e Random.")
section(ot,"World")
toggle(ot,"No Fog","NoFog",false,function(v)
    if v then L.FogEnd=1e5 else L.FogEnd=1000 end
end,"Remove névoa de distância.")
toggle(ot,"Custom FOV","CustomFOV",false,function(v)
    camera.FieldOfView=v and S.CustomFOVValue or originalFOV
end,"Sobrescreve o FieldOfView da câmera.")
slider(ot,"FOV value",40,120,70,"CustomFOVValue",function(v)
    if S.CustomFOV then camera.FieldOfView=v end
end,"Valor do FieldOfView.")
toggle(ot,"Stretched Screen","Stretch",false,function(v)
    if v then camera.FieldOfView=120/(S.StretchSize or 1.0)
    else camera.FieldOfView=S.CustomFOV and S.CustomFOVValue or originalFOV end
end,"Simula resolução esticada ajustando o FOV.")
slider(ot,"Stretch Amount",100,500,100,"StretchSize",function(v)
    S.StretchSize=v/100
    if S.Stretch then camera.FieldOfView=120/(v/100) end
end,"Intensidade do efeito de stretch.")
section(ot,"Performance")
toggle(ot,"FPS Booster","FPSBooster",false,function(v)
    pcall(function() settings().Rendering.QualityLevel=v and 1 or 10 end)
end,"Reduz qualidade gráfica para mais FPS.")
section(ot,"Target Strafe")
toggle(ot,"Target Strafe enabled","TSEnabled",false,nil,"Orbita o inimigo mais próximo em círculo.")
optionPicker(ot,"Mode","TSMode",{"Distance","Name"},nil,"Distance = mais próximo, Name = fuzzy find.")
optionPicker(ot,"Action","TSAction",{"Orbit","Click"},nil,"Orbit = círculo, Click = atirar no alvo.")
slider(ot,"Radius",2,20,8,"TSRadius",nil,"Distância de órbita em studs.")
slider(ot,"Orbit Speed x10",1,100,20,"TSSpeed",nil,"Velocidade de órbita.")
textEntry(ot,"Target Name (Name mode)","Type a name",function(text) S.TSName=text end,"Usado quando Mode = Name.")

-- MOVEMENT
section("Movement","Movement")
toggle("Movement","Fly","Fly",false,function(state)
    if not state and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
            if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
        end
        if hum then
            hum.PlatformStand=false; hum.Sit=false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            hum.WalkSpeed=S.SpeedEnabled and S.MoveSpeed or DEF_SPEED
            hum.JumpPower=S.JumpEnabled and S.JumpPower or DEF_JUMP
        end
    end
end,"WASD para voar, Space sobe, LeftCtrl desce.")
slider("Movement","Fly speed",1,200,50,"FlySpeed",nil,"Velocidade de voo.")
toggle("Movement","Speed","SpeedEnabled",false,function(state)
    if not state and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED end
    end
end,"Aumenta velocidade de caminhada.")
slider("Movement","WalkSpeed",1,100,DEF_SPEED,"MoveSpeed",nil,"Valor da velocidade.")
toggle("Movement","Jump Power","JumpEnabled",false,function(state)
    if not state and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower=DEF_JUMP end
    end
end,"Muda altura do pulo.")
slider("Movement","Jump Power value",1,300,DEF_JUMP,"JumpPower",nil,"Valor da força do pulo.")
toggle("Movement","Infinite Jumps","JumpInf",false,nil,"Pressione Space no ar para continuar pulando.")
toggle("Movement","Noclip","Noclip",false,nil,"Atravesse paredes.")
actionButton("Movement","Restore Defaults",function()
    S.MoveSpeed=DEF_SPEED;S.JumpPower=DEF_JUMP;S.FlySpeed=50
    S.Fly=false;S.Noclip=false;S.SpeedEnabled=false;S.JumpEnabled=false;S.JumpInf=false
    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED;hum.JumpPower=DEF_JUMP;hum.PlatformStand=false end
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
    end
    notify("Movement restored"); showPage("Movement")
end,"Reseta todas as opções de movimento.")

-- TROLL
section("Troll","Tools")
toggle("Troll","Fake lag","FakeLag",false,function(state)
    if state then
        if not fakeLagThread then
            fakeLagThread=task.spawn(function()
                while S.FakeLag do
                    local amount=S.FakeLagAmount or 200
                    local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if root then root.Anchored=true; task.wait(amount/1000); root.Anchored=false end
                    task.wait(0.05)
                end
                fakeLagThread=nil
            end)
        end
    else
        local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored=false end
    end
end,"Congela brevemente para parecer lagado.")
slider("Troll","Fake lag intensity (ms)",50,2000,200,"FakeLagAmount",nil,"Duração de cada congelamento.")
toggle("Troll","Spin","Spin",false,function(state)
    if state then
        if not spinThread then
            spinThread=task.spawn(function()
                while S.Spin do
                    local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local speed=S.SpinSpeed or 50
                        root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(speed),0)
                    end
                    task.wait()
                end
                spinThread=nil
            end)
        end
    else spinThread=nil end
end,"Faz o personagem girar.")
slider("Troll","Spin speed",10,500,50,"SpinSpeed",nil,"Graus por frame.")
local tpInput=textEntry("Troll","TP Player (name)","Type the player name",nil,"Teleporta para o jogador digitado.")
actionButton("Troll","▶  Teleport to player",function()
    local target=fuzzyFind(tpInput.Text)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=target.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3); notify("TP: "..target.Name) end
    else notify("Player not found") end
end,"Teleporta atrás do jogador digitado.")
local specInput=textEntry("Troll","Spectate (name)","Type the player name",nil,"Câmera livre a partir da cabeça do jogador.")
actionButton("Troll","▶  Spectate player",function()
    local target=fuzzyFind(specInput.Text)
    if target and target.Character then S.Spectate=true; S.SpectateTarget=target; notify("Spectating: "..target.Name)
    else notify("Player not found") end
end,"Segue a visão do jogador digitado.")
actionButton("Troll","Stop spectating",function() S.Spectate=false; S.SpectateTarget=nil; notify("Stopped") end,"Retorna a câmera para você.")
section("Troll","Extras")
toggle("Troll","Spider / Wall Climb","Spider",false,nil,"Segure Space perto de uma parede para escalar.")
toggle("Troll","TP to Cursor (click on screen)","TPCursor",false,nil,"Clique em qualquer lugar para se teleportar.")
toggle("Troll","Launch on Touch","LaunchOnTouch",false,function(v)
    if touchLaunchConn then touchLaunchConn:Disconnect(); touchLaunchConn=nil end
    if v and LP.Character then
        task.spawn(function()
            while S.LaunchOnTouch do
                if LP.Character then
                    for _,p in ipairs(P:GetPlayers()) do
                        if p~=LP and p.Character then
                            local root=p.Character:FindFirstChild("HumanoidRootPart")
                            local myRoot=LP.Character:FindFirstChild("HumanoidRootPart")
                            if root and myRoot and (root.Position-myRoot.Position).Magnitude<4 then
                                root.Velocity=Vector3.new(math.random(-250,250),math.random(150,250),math.random(-250,250))
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end,"Qualquer um que você tocar vai voar.")

-- PLAYERS
section("List Player","Player Management")
actionButton("List Player","Open List Player",function() plFrame.Visible=true end,"Abre o painel de lista de jogadores.")

-- KEYBINDS
local kp="Keybinds"
section(kp,"Keybind manager")
info(kp,"Clique em Create bind, busque uma função e pressione uma tecla.")
local search=make("TextBox",{Size=UDim2.new(1,-5,0,36),BackgroundColor3=C.item,Text="",PlaceholderText="Search keybinds...",PlaceholderColor3=C.gray,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=12},frames[kp])
corner(search,8); stroke(search)
local picker=make("Frame",{Name="OptionPicker",Size=UDim2.new(1,-5,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.panel,Visible=false,ZIndex=12},frames[kp])
corner(picker,8); stroke(picker)
make("UIPadding",{PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},picker)
make("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},picker)
local optionRows={}
local shortcutList=make("Frame",{Size=UDim2.new(1,-5,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=12},frames[kp])
make("UIListLayout",{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},shortcutList)
local function addShortcut(label,defaultKey,actionKey)
    local row=make("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.item,BorderSizePixel=0,ZIndex=12},shortcutList)
    corner(row,7)
    make("TextLabel",{Position=UDim2.fromOffset(9,0),Size=UDim2.new(.4,0,1,0),BackgroundTransparency=1,Text=label,TextColor3=C.textDark,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},row)
    local key=defaultKey
    local rebind=make("TextButton",{Position=UDim2.new(.42,0,0,5),Size=UDim2.new(.34,-3,0,28),BackgroundColor3=C.bg,Text=key.Name,TextColor3=C.accent,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=12},row)
    corner(rebind,5)
    local remove=make("TextButton",{Position=UDim2.new(1,-47,0,5),Size=UDim2.fromOffset(40,28),BackgroundColor3=Color3.fromRGB(240,180,190),Text="X",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=12},row)
    corner(remove,5)
    local rec={key=key,row=row,label=label,actionKey=actionKey or label}
    table.insert(savedKeys,rec)
    rebind.Activated:Connect(function()
        if waiting then return end
        waiting={button=rebind,callback=function(k) key=k; rec.key=k; rebind.Text=k.Name end}
        rebind.Text="Press..."
    end)
    remove.Activated:Connect(function()
        local i=table.find(savedKeys,rec)
        if i then table.remove(savedKeys,i) end
        row:Destroy()
    end)
    return rec
end
local create=make("TextButton",{Size=UDim2.new(1,-5,0,39),BackgroundColor3=C.item,Text="+  Create bind",TextColor3=C.accent,TextSize=13,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=12},frames[kp])
corner(create,8); stroke(create,C.ice,1)
local function refreshPicker()
    for _,r in ipairs(optionRows) do if r.Parent then r:Destroy() end end
    table.clear(optionRows)
    local query=string.lower(search.Text)
    for _,option in ipairs(names) do
        if query=="" or string.find(string.lower(option),query,1,true) then
            local b=make("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.item,Text=option,TextColor3=C.textDark,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=true,ZIndex=12},picker)
            corner(b,6)
            make("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,6)},b)
            table.insert(optionRows,b)
            b.Activated:Connect(function()
                if waiting then return end
                local selectedOption=option
                create.Text="Press a key..."
                waiting={button=create,callback=function(k)
                    addShortcut(selectedOption,k,selectedOption)
                    create.Text="+  Create bind"
                    picker.Visible=false; search.Text=""
                    notify("Bind created: "..selectedOption.." ["..k.Name.."]")
                end}
            end)
        end
    end
    if #optionRows==0 then
        table.insert(optionRows,make("TextLabel",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text="No options found.",TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,ZIndex=12},picker))
    end
end
create.Activated:Connect(function()
    picker.Visible=not picker.Visible
    if picker.Visible then refreshPicker(); search:CaptureFocus() else create.Text="+  Create bind" end
end)
search.Focused:Connect(function() picker.Visible=true; refreshPicker() end)
search:GetPropertyChangedSignal("Text"):Connect(function()
    if picker.Visible then refreshPicker() end
    local q=string.lower(search.Text)
    for _,r in ipairs(savedKeys) do
        if r.row and r.row.Parent then
            r.row.Visible=q=="" or string.find(string.lower(r.label),q,1,true)~=nil
        end
    end
end)
make("TextLabel",{Size=UDim2.new(1,-5,0,24),BackgroundTransparency=1,Text="Escolha uma opção, depois pressione a tecla. Começa vazio.",TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=12},frames[kp])

-- CREDITS
section("Credits","Credits")
info("Credits","Thanks to GBO.")
for _,name in ipairs({"BY GBO HACKS (owner)"}) do
    local b=make("TextLabel",{Size=UDim2.new(1,-5,0,36),BackgroundColor3=C.item,Text="❄   "..name,TextColor3=C.textDark,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=12},frames.Credits)
    corner(b,7)
end

-- ============================================================
-- LÓGICA ESP
-- ============================================================
local function validPlayer(p)
    if p==LP then return false end
    if not p.Character then return false end
    local hum=p.Character:FindFirstChildOfClass("Humanoid")
    local root=p.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    if hum.Health<=0 then return false end
    return true
end
local function isFriendly(p,c)
    if not c then return false end
    if not p.Team or not LP.Team then return false end
    return p.Team==LP.Team
end
local function hasWallBetween(t)
    if not LP.Character then return true end
    local pa=RaycastParams.new()
    pa.FilterType=Enum.RaycastFilterType.Exclude
    pa.FilterDescendantsInstances={LP.Character,t.Parent}
    return workspace:Raycast(camera.CFrame.Position,t.Position-camera.CFrame.Position,pa)~=nil
end
local function inList(list,name)
    for _,n in ipairs(list) do if n==name then return true end end
    return false
end
local function removeHighlight(p)
    if highlights[p] then
        for _,obj in pairs(highlights[p]) do
            if typeof(obj)=="Instance" and obj.Parent then pcall(function() obj:Destroy() end) end
        end
        highlights[p]=nil
    end
    if drawingTraces[p] then pcall(function() drawingTraces[p]:Remove() end); drawingTraces[p]=nil end
    if drawingSkeletons[p] then
        for _,line in ipairs(drawingSkeletons[p]) do pcall(function() line:Remove() end) end
        drawingSkeletons[p]=nil
    end
    if drawingHeadCircles[p] then pcall(function() drawingHeadCircles[p]:Remove() end); drawingHeadCircles[p]=nil end
end
local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"LowerTorso","HumanoidRootPart"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local RBONES={{"Head","Torso"},{"Torso","HumanoidRootPart"},{"Torso","Left Arm"},{"Left Arm","Left Leg"},{"Torso","Right Arm"},{"Right Arm","Right Leg"}}

local function createESPForPlayer(p)
    if not p.Character then return end
    local data={}
    data.box=make("Frame",{Size=UDim2.fromOffset(0,0),BackgroundTransparency=0.5,BackgroundColor3=S.ESPColor,ZIndex=30,Visible=false},gui)
    data.boxStroke=stroke(data.box,S.ESPColor,1.5,0)
    data.healthBar=make("Frame",{Size=UDim2.fromOffset(4,0),BackgroundColor3=Color3.fromRGB(30,30,30),BackgroundTransparency=0.3,ZIndex=31,Visible=false},gui)
    data.healthFill=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.green,ZIndex=32},data.healthBar)

    data.highlight=make("Highlight",{FillColor=S.ESPColor,OutlineColor=S.ESPColor,FillTransparency=0.7,OutlineTransparency=0.3,Enabled=false},p.Character)
    
    local root = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("UpperTorso")

    if root then
        data.auraList=makeSSJAuraEmitters(root)
    end

    local head=p.Character:FindFirstChild("Head")
    if head then
        data.billboard=make("BillboardGui",{Size=UDim2.fromOffset(200,40),StudsOffsetWorldSpace=Vector3.new(0,2.5,0),AlwaysOnTop=true,MaxDistance=S.MaxDist,Enabled=false},head)
        data.billboard.Adornee=head
        data.text=make("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",TextColor3=S.ESPColor,Font=Enum.Font.GothamBold,TextSize=11,TextStrokeTransparency=0.5,ZIndex=34},data.billboard)
    end

    pcall(function()
        if Drawing and Drawing.new then
            local line=Drawing.new("Line")
            line.Thickness=1.5; line.Color=S.ESPColor; line.Transparency=0.7; line.Visible=false
            drawingTraces[p]=line
            local skel={}
            local bones=p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.RigType==Enum.HumanoidRigType.R15 and BONES or RBONES
            for _=1,#bones do
                local l=Drawing.new("Line")
                l.Thickness=1.5; l.Color=S.ESPColor; l.Transparency=0.6; l.Visible=false
                table.insert(skel,l)
            end
            drawingSkeletons[p]=skel
            local circle=Drawing.new("Circle")
            circle.Thickness=1.5; circle.Color=S.ESPColor; circle.Transparency=0.6
            circle.Visible=false; circle.NumSides=20; circle.Filled=false
            drawingHeadCircles[p]=circle
        end
    end)
    highlights[p]=data
end

local function ensureDistLabel(data,p)
    if data.distanceGui then return end
    local root=p.Character and (p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso"))
    data.distanceGui=make("BillboardGui",{Size=UDim2.fromOffset(120,26),StudsOffsetWorldSpace=Vector3.new(0,-5.2,0),AlwaysOnTop=true,MaxDistance=S.MaxDist,Enabled=false},root)
    data.distanceGui.Adornee=root
    data.distanceText=make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",TextColor3=S.ESPColor,Font=Enum.Font.GothamBold,TextSize=12,TextStrokeTransparency=0.5},data.distanceGui)
end

local function updateTrace(p)
    if not drawingTraces[p] then return end
    local line=drawingTraces[p]
    if S.StreamMode or not S.ESP or not S.ESPTraces or not validPlayer(p) then line.Visible=false; return end
    if not LP.Character then line.Visible=false; return end
    local myRoot=LP.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot=p.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then line.Visible=false; return end
    local mySP,myOn=camera:WorldToViewportPoint(myRoot.Position)
    local tSP,tOn=camera:WorldToViewportPoint(targetRoot.Position)
    if not myOn or not tOn or tSP.Z<=0 then line.Visible=false; return end
    if mySP.Z<=0 then
        local vp=camera.ViewportSize
        line.From=Vector2.new(vp.X/2,vp.Y)
    else
        line.From=Vector2.new(mySP.X,mySP.Y)
    end
    local head=p.Character:FindFirstChild("Head")
    if S.ESPWallCheck and head and hasWallBetween(head) then
        line.Color=Color3.fromRGB(255,50,50)
    elseif S.ESPWallCheck then
        line.Color=Color3.fromRGB(50,255,50)
    else
        line.Color=S.ESPColor
    end
    line.To=Vector2.new(tSP.X,tSP.Y)
    line.Visible=true
end

local function updateSkeleton(p)
    local skel=drawingSkeletons[p]
    local circle=drawingHeadCircles[p]
    if not skel then return end
    if S.StreamMode or not S.ESP or not S.Skeleton or not validPlayer(p) then
        for _,l in ipairs(skel) do l.Visible=false end
        if circle then circle.Visible=false end
        return
    end
    local char=p.Character
    local rig=char:FindFirstChild("Humanoid") and char.Humanoid.RigType==Enum.HumanoidRigType.R15
    local bones=rig and BONES or RBONES
    local head=char:FindFirstChild("Head")
    local isOccluded=S.ESPWallCheck and head and hasWallBetween(head)
    local currentColor=S.ESPColor
    if S.ESPWallCheck then
        if isOccluded then currentColor=Color3.fromRGB(255,50,50) else currentColor=Color3.fromRGB(50,255,50) end
    end
    for i,b in ipairs(bones) do
        local a1=char:FindFirstChild(b[1]); local a2=char:FindFirstChild(b[2]); local line=skel[i]
        if a1 and a2 then
            local s1,o1=camera:WorldToViewportPoint(a1.Position)
            local s2,o2=camera:WorldToViewportPoint(a2.Position)
            if o1 and o2 and s1.Z>0 and s2.Z>0 then
                line.From=Vector2.new(s1.X,s1.Y); line.To=Vector2.new(s2.X,s2.Y)
                line.Color=currentColor; line.Visible=true
            else line.Visible=false end
        else line.Visible=false end
    end
    for i=#bones+1,#skel do skel[i].Visible=false end
    if circle and head then
        local headSP,headOn=camera:WorldToViewportPoint(head.Position)
        local topSP,topOn=camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
        if headOn and topOn and headSP.Z>0 then
            circle.Position=Vector2.new(headSP.X,headSP.Y)
            circle.Radius=math.max(math.abs(headSP.Y-topSP.Y)*1.2,5)
            circle.Color=currentColor; circle.Visible=true
        else circle.Visible=false end
    elseif circle then circle.Visible=false end
end

local function getCharacterScreenBox(char)
    local parts={}
    for _,desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name~="HumanoidRootPart" then table.insert(parts,desc) end
    end
    if #parts==0 then
        local ok,cf,sz=pcall(function() return char:GetBoundingBox() end)
        if not ok then return nil end
        local corners3={
            cf*CFrame.new(sz.X/2,sz.Y/2,sz.Z/2),cf*CFrame.new(-sz.X/2,sz.Y/2,sz.Z/2),
            cf*CFrame.new(sz.X/2,sz.Y/2,-sz.Z/2),cf*CFrame.new(-sz.X/2,sz.Y/2,-sz.Z/2),
            cf*CFrame.new(sz.X/2,-sz.Y/2,sz.Z/2),cf*CFrame.new(-sz.X/2,-sz.Y/2,sz.Z/2),
            cf*CFrame.new(sz.X/2,-sz.Y/2,-sz.Z/2),cf*CFrame.new(-sz.X/2,-sz.Y/2,-sz.Z/2),
        }
        local minX,maxX=math.huge,-math.huge; local minY,maxY=math.huge,-math.huge; local any=false
        for _,c in ipairs(corners3) do
            local sp,on=camera:WorldToViewportPoint(c.Position)
            if on and sp.Z>0 then
                any=true
                if sp.X<minX then minX=sp.X end; if sp.X>maxX then maxX=sp.X end
                if sp.Y<minY then minY=sp.Y end; if sp.Y>maxY then maxY=sp.Y end
            end
        end
        if not any then return nil end
        return minX,minY,maxX-minX,maxY-minY
    end
    local minX,maxX=math.huge,-math.huge; local minY,maxY=math.huge,-math.huge; local any=false
    for _,part in ipairs(parts) do
        local cf2=part.CFrame; local sz2=part.Size
        local hx,hy,hz=sz2.X/2,sz2.Y/2,sz2.Z/2
        local offsets={
            Vector3.new(hx,hy,hz),Vector3.new(-hx,hy,hz),
            Vector3.new(hx,hy,-hz),Vector3.new(-hx,hy,-hz),
            Vector3.new(hx,-hy,hz),Vector3.new(-hx,-hy,hz),
            Vector3.new(hx,-hy,-hz),Vector3.new(-hx,-hy,-hz),
        }
        for _,off in ipairs(offsets) do
            local worldPos=cf2*CFrame.new(off)
            local sp,on=camera:WorldToViewportPoint(worldPos.Position)
            if on and sp.Z>0 then
                any=true
                if sp.X<minX then minX=sp.X end; if sp.X>maxX then maxX=sp.X end
                if sp.Y<minY then minY=sp.Y end; if sp.Y>maxY then maxY=sp.Y end
            end
        end
    end
    if not any then return nil end
    return minX,minY,maxX-minX,maxY-minY
end

local function updateESP()
    local seen={}
    for _,p in ipairs(P:GetPlayers()) do
        if not inList(S.Whitelist,p.Name) then
            if validPlayer(p) and not isFriendly(p,S.ESPTeamCheck) then
                seen[p]=true
                if not highlights[p] then createESPForPlayer(p); ensureDistLabel(highlights[p],p) end
                local data=highlights[p]
                if data then
                    local hum=p.Character:FindFirstChildOfClass("Humanoid")
                    local root=p.Character:FindFirstChild("HumanoidRootPart")
                    local head=p.Character:FindFirstChild("Head")
                    if hum and root and head then
                        local dist=(camera.CFrame.Position-root.Position).Magnitude
                        local skip=S.StreamMode or dist>S.MaxDist
                        if skip then
                            data.box.Visible=false; data.healthBar.Visible=false
                            if data.billboard then data.billboard.Enabled=false end
                            if data.highlight then data.highlight.Enabled=false end
                            if data.auraList then for _,e in ipairs(data.auraList) do e.Enabled=false end end
                            if data.distanceGui then data.distanceGui.Enabled=false end
                            if drawingTraces[p] then drawingTraces[p].Visible=false end
                            if drawingSkeletons[p] then for _,l in ipairs(drawingSkeletons[p]) do l.Visible=false end end
                            if drawingHeadCircles[p] then drawingHeadCircles[p].Visible=false end
                        elseif S.ESP then
                            local isOccluded=S.ESPWallCheck and hasWallBetween(head)
                            local currentColor=S.ESPColor
                            if S.ESPWallCheck then
                                if isOccluded then currentColor=Color3.fromRGB(255,50,50)
                                else currentColor=Color3.fromRGB(50,255,50) end
                            end

                            if data.highlight then
                                data.highlight.Enabled=true
                                data.highlight.FillColor=currentColor
                                data.highlight.OutlineColor=currentColor
                                data.highlight.FillTransparency=S.ESPTransparency/100
                                data.highlight.OutlineTransparency=S.ESPTransparency/100
                            end

                            if data.auraList then
                                for _,e in ipairs(data.auraList) do
                                    if e:IsA("ParticleEmitter") then
                                        if e.Size and e.Size.Keypoints[1] and e.Size.Keypoints[1].Value>=10 then
                                            e.Color=ColorSequence.new(currentColor)
                                        end
                                        e.Enabled=S.Aura
                                    end
                                end
                            end

                            if S.Box then
                                local minX,minY,w,h2=getCharacterScreenBox(p.Character)
                                if minX then
                                    data.box.Visible=true
                                    data.box.Position=UDim2.fromOffset(minX,minY)
                                    data.box.Size=UDim2.fromOffset(w,h2)
                                    data.box.BackgroundColor3=currentColor
                                    data.box.BackgroundTransparency=math.clamp(S.ESPTransparency/100,0,0.95)
                                    data.boxStroke.Color=currentColor
                                    data.boxStroke.Thickness=1.8
                                    data.boxStroke.Transparency=0
                                else data.box.Visible=false end
                            else data.box.Visible=false end

                            if S.Health then
                                local minX2,minY2,w2,h3=getCharacterScreenBox(p.Character)
                                if minX2 then
                                    data.healthBar.Visible=true
                                    data.healthBar.Size=UDim2.fromOffset(4,h3)
                                    data.healthBar.Position=UDim2.fromOffset(minX2-8,minY2)
                                    local hp=math.clamp(hum.Health/hum.MaxHealth,0,1)
                                    data.healthFill.Size=UDim2.new(1,0,hp,0)
                                    data.healthFill.Position=UDim2.new(0,0,1-hp,0)
                                    data.healthFill.BackgroundColor3=Color3.fromHSV(hp*0.3,1,1)
                                else data.healthBar.Visible=false end
                            else data.healthBar.Visible=false end

                            if data.billboard then
                                if S.Name then
                                    data.billboard.Enabled=true; data.text.Text=p.Name; data.text.TextColor3=currentColor
                                else data.billboard.Enabled=false end
                            end

                            if data.distanceGui then
                                if S.Distance then
                                    data.distanceGui.Enabled=true
                                    data.distanceText.Text=math.floor(dist).."m"
                                    data.distanceText.TextColor3=currentColor
                                else data.distanceGui.Enabled=false end
                            end
                            updateTrace(p); updateSkeleton(p)
                        else
                            data.box.Visible=false; data.healthBar.Visible=false
                            if data.billboard then data.billboard.Enabled=false end
                            if data.highlight then data.highlight.Enabled=false end
                            if data.auraList then for _,e in ipairs(data.auraList) do e.Enabled=false end end
                            if data.distanceGui then data.distanceGui.Enabled=false end
                            if drawingTraces[p] then drawingTraces[p].Visible=false end
                            if drawingSkeletons[p] then for _,l in ipairs(drawingSkeletons[p]) do l.Visible=false end end
                            if drawingHeadCircles[p] then drawingHeadCircles[p].Visible=false end
                        end
                    end
                end
            end
        end
    end
    for p in pairs(highlights) do
        if not seen[p] or not validPlayer(p) then removeHighlight(p) end
    end
end

local function bindPlayer(p)
    if p==LP then return end
    local function onChar()
        task.wait(0.3)
        removeHighlight(p)
        if p.Character then createESPForPlayer(p); ensureDistLabel(highlights[p],p) end
        if S.HitboxEnabled then
            task.wait(0.4)
            if S.HitboxMode=="Head" then applyHitboxToPlayer(p) else applySQ(p) end
        end
    end
    p.CharacterAdded:Connect(onChar)
    if p.Character then onChar() end
end
for _,p in ipairs(P:GetPlayers()) do bindPlayer(p) end
P.PlayerAdded:Connect(bindPlayer)
P.PlayerRemoving:Connect(function(p) resetSQ(p); removeHighlight(p) end)

-- FOV circles
local aimFovCircle=make("Frame",{Name="AimFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.AimFOV*2,S.AimFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(aimFovCircle,1000); local aimRingStroke=stroke(aimFovCircle,S.AimFOVColor,0.1); aimRingStroke.Thickness=2
local silentFovCircle=make("Frame",{Name="SilentFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.SilentFOV*2,S.SilentFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(silentFovCircle,1000); local silentRingStroke=stroke(silentFovCircle,S.SilentFOVColor,0.3); silentRingStroke.Thickness=2
local triggerFovCircle=make("Frame",{Name="TriggerFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.TriggerFOV*2,S.TriggerFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(triggerFovCircle,1000); local triggerRingStroke=stroke(triggerFovCircle,S.TriggerFOVColor,0.3); triggerRingStroke.Thickness=2

local function getScreenCenter()
    local vp=camera.ViewportSize; return Vector2.new(vp.X/2,vp.Y/2)
end
local function getMouseScreen() return U:GetMouseLocation() end

local function getClosestPlayerFromOrigin(fovRadius,teamCheck,wallCheck,origin,partLabel)
    local best,bestDist=nil,math.huge
    for _,p in ipairs(P:GetPlayers()) do
        if validPlayer(p) and not isFriendly(p,teamCheck) then
            local allowed=#S.Blacklist==0 or inList(S.Blacklist,p.Name)
            local blocked=inList(S.Whitelist,p.Name)
            if allowed and not blocked then
                local part=resolveAimPart(p.Character,partLabel or "Head")
                if part then
                    local ok=true
                    if wallCheck and hasWallBetween(part) then ok=false end
                    if ok then
                        local sp,on=camera:WorldToViewportPoint(part.Position)
                        if on and sp.Z>0 then
                            local sd=(Vector2.new(sp.X,sp.Y)-origin).Magnitude
                            if sd<fovRadius then
                                local wd=(camera.CFrame.Position-part.Position).Magnitude
                                if wd<bestDist then bestDist=wd; best=p end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function silentAimMove(dx,dy)
    if type(mousemoverel)=="function" then pcall(mousemoverel,dx,dy); return end
    pcall(function() VIM:SendMouseMoveEvent(Vector2.new(dx,dy),false) end)
end

local silentLockTarget=nil
local silentLockLostFrames=0
local SILENT_REACQUIRE_FRAMES=3

local function updateSilentAim()
    if not S.SilentAim then silentLockTarget=nil; return end
    if main.Visible then silentLockTarget=nil; return end
    if not U:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        silentLockTarget=nil; silentLockLostFrames=0; return
    end
    local mousePos=getMouseScreen()
    if silentLockTarget then
        if not validPlayer(silentLockTarget) then silentLockTarget=nil
        else
            local part=resolveAimPart(silentLockTarget.Character,S.SilentPart)
            if not part then silentLockTarget=nil end
        end
    end
    if not silentLockTarget then
        silentLockLostFrames=silentLockLostFrames+1
        if silentLockLostFrames>=SILENT_REACQUIRE_FRAMES then
            silentLockLostFrames=0
            silentLockTarget=getClosestPlayerFromOrigin(S.SilentFOV,S.SilentTeamCheck,S.SilentWallCheck,mousePos,S.SilentPart)
        end
        if not silentLockTarget then return end
    end
    local part=silentLockTarget.Character and resolveAimPart(silentLockTarget.Character,S.SilentPart)
    if not part then silentLockTarget=nil; return end
    local sp,on=camera:WorldToViewportPoint(part.Position)
    if not on or sp.Z<=0 then silentLockTarget=nil; return end
    local dx=sp.X-mousePos.X; local dy=sp.Y-mousePos.Y
    local dist=math.sqrt(dx*dx+dy*dy)
    if dist<1 then return end
    silentAimMove(dx,dy)
end

local function realScreenClick()
    local vp=camera.ViewportSize
    local cx=math.floor(vp.X/2+math.random(-3,3)); local cy=math.floor(vp.Y/2+math.random(-3,3))
    pcall(function()
        VIM:SendMouseButtonEvent(cx,cy,0,true,game,0); task.wait(0.02)
        VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
    end)
end

local function applyStreamMode(on)
    S.StreamMode=on
    if on then
        guiVisibleBeforeStream=main.Visible
        main.Visible=false; floating.Visible=false; statusBar.Visible=false
        for _,n in ipairs(notes:GetChildren()) do if n:IsA("TextLabel") then n.Visible=false end end
        aimFovCircle.Visible=false; silentFovCircle.Visible=false; triggerFovCircle.Visible=false
        for _,data in pairs(highlights) do
            if data.box then data.box.Visible=false end
            if data.healthBar then data.healthBar.Visible=false end
            if data.billboard then data.billboard.Enabled=false end
            if data.highlight then data.highlight.Enabled=false end
            if data.auraList then for _,e in ipairs(data.auraList) do e.Enabled=false end end
            if data.distanceGui then data.distanceGui.Enabled=false end
        end
        for _,t in pairs(drawingTraces) do t.Visible=false end
        for _,sk in pairs(drawingSkeletons) do for _,l in ipairs(sk) do l.Visible=false end end
        for _,c in pairs(drawingHeadCircles) do c.Visible=false end
    else
        main.Visible=guiVisibleBeforeStream; statusBar.Visible=true
        for _,n in ipairs(notes:GetChildren()) do if n:IsA("TextLabel") then n.Visible=true end end
    end
end

U.InputBegan:Connect(function(input,processed)
    if input.UserInputType==Enum.UserInputType.MouseButton1 and S.TPCursor and not processed then
        if LP.Character then
            local mousePos=U:GetMouseLocation()
            local ray=camera:ViewportPointToRay(mousePos.X,mousePos.Y)
            local pa=RaycastParams.new()
            pa.FilterDescendantsInstances={LP.Character}; pa.FilterType=Enum.RaycastFilterType.Exclude
            local hit=workspace:Raycast(ray.Origin,ray.Direction*500,pa)
            if hit then
                local root=LP.Character:FindFirstChild("HumanoidRootPart")
                if root then root.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0)) end
            end
        end
    end
end)

U.InputBegan:Connect(function(input,processed)
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    if waiting then
        local pending=waiting; waiting=nil
        if pending.button and pending.button.Parent then pcall(pending.callback,input.KeyCode) end
        return
    end
    if input.KeyCode==S.StreamKey then applyStreamMode(not S.StreamMode); applyMouseState(); return end
    if processed or S.StreamMode then return end
    if input.KeyCode==S.ToggleKey then
        if main.Visible then minimizePanel() else restorePanel() end
        return
    end
    for _,rec in ipairs(savedKeys) do
        if rec.key==input.KeyCode then
            if rec.actionKey=="Painel" then
                if main.Visible then minimizePanel() else restorePanel() end
            elseif actions[rec.actionKey] then pcall(actions[rec.actionKey]) end
        end
    end
end)

R.RenderStepped:Connect(function(dt)
    if S.MouseFree and not S.StreamMode then
        if U.MouseBehavior~=Enum.MouseBehavior.Default then
            U.MouseBehavior=Enum.MouseBehavior.Default; U.MouseIconEnabled=true
        end
    end
    pcall(updateESP); pcall(updateSilentAim)

    if not S.Aura then
        for _,data in pairs(highlights) do
            if data.auraList then
                for _,e in ipairs(data.auraList) do
                    if e:IsA("ParticleEmitter") and e.Enabled then e.Enabled=false end
                end
            end
        end
    end

    if S.HitboxEnabled then
        for _,p in ipairs(P:GetPlayers()) do
            if p~=LP and p.Character then
                if S.HitboxMode=="Square" then
                    if sqOriginal[p] then
                        local root=p.Character:FindFirstChild("HumanoidRootPart")
                        if root and math.abs(root.Size.X-(S.HitboxSize or 5))>0.01 then applySQ(p) end
                    end
                elseif S.RainbowHitbox then
                    local head=p.Character:FindFirstChild("Head")
                    if head then
                        local hue=(os.clock()*0.2)%1; head.Color=Color3.fromHSV(hue,1,1)
                        local marker=head:FindFirstChild("HitboxMarker")
                        if marker then marker.Color=Color3.fromHSV(hue,1,1) end
                    end
                else
                    local head=p.Character:FindFirstChild("Head")
                    if head then head.Color=S.HitboxColor end
                end
            end
        end
        if S.HitboxMode=="Square" and S.RainbowSQ then
            for _,p in ipairs(P:GetPlayers()) do
                if sqOriginal[p] then
                    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if root then root.Color=Color3.fromHSV((os.clock()*0.2)%1,1,1) end
                end
            end
        end
    end

    local center=getScreenCenter(); local mousePos=getMouseScreen()

    if S.AntiAim and LP.Character then
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        local neck=LP.Character:FindFirstChild("Neck") or (LP.Character:FindFirstChild("UpperTorso") and LP.Character.UpperTorso:FindFirstChild("Neck"))
        if S.AntiAimMode=="Jitter" then
            if neck then
                local orig=LP.Character:FindFirstChild("AAOrigC0")
                if not orig then orig=Instance.new("CFrameValue",LP.Character); orig.Name="AAOrigC0"; orig.Value=neck.C0 end
                neck.C0=orig.Value*CFrame.Angles(0,math.rad(math.random(-45,45)),0)
            end
        elseif S.AntiAimMode=="Spin" then
            if root then root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(10),0) end
        elseif S.AntiAimMode=="Random" then
            if root then
                local rnd=Vector3.new(math.random(-25,25),math.random(-180,180),math.random(-25,25))
                root.CFrame=root.CFrame*CFrame.Angles(math.rad(rnd.X),math.rad(rnd.Y),math.rad(rnd.Z))
            end
        end
    end

    if S.TSEnabled and LP.Character and not main.Visible then
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local target=nil
            if S.TSMode=="Distance" then
                local best,bestDist=nil,math.huge
                for _,p in ipairs(P:GetPlayers()) do
                    if validPlayer(p) then
                        local tr=p.Character.HumanoidRootPart
                        local d=(root.Position-tr.Position).Magnitude
                        if d<bestDist then bestDist=d; best=p end
                    end
                end
                target=best
            elseif S.TSMode=="Name" then
                target=fuzzyFind(S.TSName); if target==LP then target=nil end
            end
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local tr=target.Character.HumanoidRootPart
                tsAngleAcc=tsAngleAcc+dt*(S.TSSpeed or 2)
                local rad=S.TSRadius or 8
                local offset=Vector3.new(math.cos(tsAngleAcc)*rad,0,math.sin(tsAngleAcc)*rad)
                root.CFrame=CFrame.new(tr.Position+offset)
                if S.TSAction=="Click" then
                    local headPart=target.Character:FindFirstChild("Head")
                    if headPart then
                        local sp,on=camera:WorldToViewportPoint(headPart.Position)
                        if on and sp.Z>0 then
                            local cx=math.floor(sp.X); local cy2=math.floor(sp.Y)
                            pcall(function()
                                VIM:SendMouseButtonEvent(cx,cy2,0,true,game,0); task.wait(0.03)
                                VIM:SendMouseButtonEvent(cx,cy2,0,false,game,0)
                            end)
                        end
                    end
                end
            end
        end
    end

    if S.Spider and LP.Character then
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if root and hum and U:IsKeyDown(Enum.KeyCode.Space) then
            local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
            for _,dir in ipairs(dirs) do
                local pa=RaycastParams.new()
                pa.FilterDescendantsInstances={LP.Character}; pa.FilterType=Enum.RaycastFilterType.Exclude
                local hit=workspace:Raycast(root.Position,dir*3,pa)
                if hit then root.Velocity=Vector3.new(root.Velocity.X,hum.JumpPower,root.Velocity.Z); break end
            end
        end
    end

    if S.Spectate and S.SpectateTarget and S.SpectateTarget.Character then
        local root2=S.SpectateTarget.Character:FindFirstChild("HumanoidRootPart")
        local head2=S.SpectateTarget.Character:FindFirstChild("Head")
        if root2 then
            local tp=head2 and head2.Position or root2.Position
            camera.CFrame=CFrame.new(tp+Vector3.new(0,2,5),tp)
        end
    end

    if S.RainbowESP then S.ESPColor=Color3.fromHSV((os.clock()*0.15)%1,1,1) end
    if S.RainbowAimFOV then S.AimFOVColor=Color3.fromHSV((os.clock()*0.15+0.25)%1,1,1) end
    if S.RainbowSilentFOV then S.SilentFOVColor=Color3.fromHSV((os.clock()*0.15+0.5)%1,1,1) end
    if S.RainbowTriggerFOV then S.TriggerFOVColor=Color3.fromHSV((os.clock()*0.15+0.75)%1,1,1) end

    if not S.StreamMode then
        aimFovCircle.Visible=S.ShowAimFOV
        if S.ShowAimFOV then
            aimFovCircle.Position=UDim2.fromOffset(center.X,center.Y)
            aimFovCircle.Size=UDim2.fromOffset(S.AimFOV*2,S.AimFOV*2)
            aimRingStroke.Color=S.AimFOVColor
        end
        silentFovCircle.Visible=S.ShowSilentFOV
        if S.ShowSilentFOV then
            silentFovCircle.Position=UDim2.fromOffset(mousePos.X,mousePos.Y)
            silentFovCircle.Size=UDim2.fromOffset(S.SilentFOV*2,S.SilentFOV*2)
            silentRingStroke.Color=S.SilentFOVColor
        end
        triggerFovCircle.Visible=S.ShowTriggerFOV
        if S.ShowTriggerFOV then
            triggerFovCircle.Position=UDim2.fromOffset(center.X,center.Y)
            triggerFovCircle.Size=UDim2.fromOffset(S.TriggerFOV*2,S.TriggerFOV*2)
            triggerRingStroke.Color=S.TriggerFOVColor
        end
    end

    if S.Aimbot and U:IsKeyDown(S.AimKey) and not main.Visible then
        local target=getClosestPlayerFromOrigin(S.AimFOV,S.AimTeamCheck,S.AimWallCheck,center,S.AimPart)
        if target and target.Character then
            local part=resolveAimPart(target.Character,S.AimPart)
            if part then camera.CFrame=CFrame.new(camera.CFrame.Position,part.Position) end
        end
    end

    if S.TriggerBot and not main.Visible then
        local target=getClosestPlayerFromOrigin(S.TriggerFOV,S.TriggerTeamCheck,false,center,S.TriggerPart)
        if target and target.Character then
            local part=resolveAimPart(target.Character,S.TriggerPart)
            if part then
                local sp,on=camera:WorldToViewportPoint(part.Position)
                local sd=(Vector2.new(sp.X,sp.Y)-center).Magnitude
                local canShoot=sd<S.TriggerFOV
                if S.TriggerWallBang then canShoot=true end
                if canShoot then
                    if not S.TriggerWallBang and S.TriggerWallCheck and hasWallBetween(part) then canShoot=false end
                end
                if canShoot then
                    if S.TriggerLock then camera.CFrame=CFrame.new(camera.CFrame.Position,part.Position) end
                    task.spawn(realScreenClick)
                end
            end
        end
    end

    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and not S.Fly then
            if S.SpeedEnabled then hum.WalkSpeed=S.MoveSpeed end
            if S.JumpEnabled then hum.UseJumpPower=true; hum.JumpPower=S.JumpPower end
        end
    end

    if S.Noclip and LP.Character then
        if not noclipState then
            savedCharCollision={}
            for _,part in pairs(LP.Character:GetDescendants()) do
                if part:IsA("BasePart") and savedCharCollision[part]==nil then savedCharCollision[part]=part.CanCollide end
            end
            noclipState=true
        end
        for _,part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                if savedCharCollision[part]==nil then savedCharCollision[part]=true end
                part.CanCollide=false
            end
        end
    elseif not S.Noclip and noclipState then
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
    end

    if S.JumpInf and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and U:IsKeyDown(Enum.KeyCode.Space) then
            local now=os.clock()
            if now-multiJumpLast>=0.25 then
                multiJumpLast=now; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end

    if S.Fly and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        wasFlying=true
        local root=LP.Character.HumanoidRootPart
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=true end
        local bv=root:FindFirstChild("FlyBV")
        if not bv then
            bv=Instance.new("BodyVelocity")
            bv.Name="FlyBV"; bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.P=1250
            bv.Velocity=Vector3.new(0,0,0); bv.Parent=root
        end
        local bg=root:FindFirstChild("FlyBG")
        if not bg then
            bg=Instance.new("BodyGyro")
            bg.Name="FlyBG"; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=1e4; bg.D=500
            bg.CFrame=camera.CFrame; bg.Parent=root
        end
        bg.CFrame=CFrame.new(root.Position,root.Position+camera.CFrame.LookVector)
        local move=Vector3.new()
        if U:IsKeyDown(Enum.KeyCode.W) then move=move+camera.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.S) then move=move-camera.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.A) then move=move-camera.CFrame.RightVector end
        if U:IsKeyDown(Enum.KeyCode.D) then move=move+camera.CFrame.RightVector end
        if U:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.new(0,1,0) end
        if U:IsKeyDown(Enum.KeyCode.LeftControl) then move=move-Vector3.new(0,1,0) end
        if move.Magnitude>0 then bv.Velocity=move.Unit*S.FlySpeed else bv.Velocity=Vector3.new(0,0,0) end
    elseif wasFlying then
        wasFlying=false
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local root=LP.Character.HumanoidRootPart
            local hum=LP.Character:FindFirstChildOfClass("Humanoid")
            if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
            if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
            if hum then
                hum.PlatformStand=false; hum.Sit=false
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                if hum.WalkSpeed<=0 then hum.WalkSpeed=S.SpeedEnabled and S.MoveSpeed or DEF_SPEED end
                if hum.JumpPower<=0 then hum.JumpPower=S.JumpEnabled and S.JumpPower or DEF_JUMP end
            end
        end
    end
end)

applyMouseState()
showPage("Home")
notify("GBO HACKS (snow) v3.8 loaded ❄")
print("[GBO HACKS (snow) v3.8] loaded.")
