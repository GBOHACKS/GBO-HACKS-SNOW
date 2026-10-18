-- GBO HACKS (snow) v3.7
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

local S={
    ESP=false,Box=false,BoxStyle="astro",Name=false,Distance=false,Health=false,Skeleton=false,ESPTraces=false,
    ESPTeamCheck=false,ESPWallCheck=false,
    Aimbot=false,AimTeamCheck=false,AimWallCheck=false,
    SilentAim=false,SilentTeamCheck=false,SilentWallCheck=false,SilentStrength=5.0,
    TriggerBot=false,TriggerLock=false,TriggerTeamCheck=false,TriggerWallCheck=false,TriggerWallBang=false,
    ShowAimFOV=false,ShowSilentFOV=false,ShowTriggerFOV=false,
    AimFOV=120,SilentFOV=100,TriggerFOV=80,MaxDist=500,
    ESPColor=C.accent,AimFOVColor=C.accent,SilentFOVColor=Color3.fromRGB(0,255,255),TriggerFOVColor=C.green,
    SpeedEnabled=false,MoveSpeed=DEF_SPEED,
    JumpEnabled=false,JumpPower=DEF_JUMP,JumpInf=false,FlySpeed=50,
    Noclip=false,Fly=false,Freecam=false,Rainbow=false,
    StreamMode=false,MouseFree=false,
    HitboxEnabled=false,HitboxMode="head",HitboxSize=3,HitboxTransparency=0,HitboxVisual="head",HitboxRainbow=false,
    SQSize=5,SQTransparency=0.7,SQColor=C.ice,SQRainbow=false,SQTeamCheck=false,
    SnowEnabled=true,
    Fullbright=false,AntiAFK=false,
    FakeLag=false,FakeLagAmount=200,Spin=false,SpinSpeed=50,
    Blacklist={},Whitelist={},
    AimKey=Enum.KeyCode.Q,SilentKey=Enum.KeyCode.E,TriggerKey=Enum.KeyCode.T,
    ToggleKey=Enum.KeyCode.RightShift,StreamKey=Enum.KeyCode.F1
}

local highlights={}
local drawingTraces={}
local drawingSkeletons={}
local sqOriginal={}
local freecam={enabled=false,pos=Vector3.new(0,10,0),yaw=0,pitch=0}
local originalCFrame,originalCameraType=nil,nil
local noclipState=false
local savedCharCollision={}
local savedLighting={}
local guiVisibleBeforeStream=true
local toggleSetters={}
local spinThread=nil
local fakeLagThread=nil
local afkConn=nil
local blListRefresh=nil
local wlListRefresh=nil
local lockTarget=nil
local wasFlying=false
local multiJumpLast=0

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
    if S.HitboxRainbow then head.Color=Color3.fromHSV((os.clock()*0.2)%1,1,1) end
    local oldMarker=head:FindFirstChild("HitboxMarker")
    if oldMarker then oldMarker:Destroy() end
    if S.HitboxVisual=="circle" then
        local marker=Instance.new("Part")
        marker.Name="HitboxMarker"; marker.Shape=Enum.PartType.Ball
        marker.Size=Vector3.new(v,v,v); marker.Transparency=0.7
        marker.Color=S.HitboxRainbow and Color3.fromHSV((os.clock()*0.2)%1,1,1) or Color3.fromRGB(255,80,80)
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
    root.Color=S.SQRainbow and Color3.fromHSV((os.clock()*0.2)%1,1,1) or (S.SQColor or C.ice)
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
        if S.HitboxMode=="head" then
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
make("TextLabel",{Size=UDim2.fromOffset(400,30),Position=UDim2.new(.5,-200,.5,-15),BackgroundTransparency=1,Text="v3.7  |  Loading...",TextColor3=C.textLight,Font=Enum.Font.GothamMedium,TextSize=16,ZIndex=2002},welcome)

task.delay(3,function()
    if welcome.Parent then
        local tw=T:Create(welcome,TweenInfo.new(0.5),{BackgroundTransparency=1})
        tw:Play(); tw.Completed:Wait(); welcome:Destroy()
    end
end)

local main=make("Frame",{Name="Main",Size=UDim2.fromOffset(980,620),Position=UDim2.new(.5,-490,.5,-310),BackgroundColor3=C.bg,BorderSizePixel=0,Visible=false},gui)
corner(main,12); stroke(main,C.ice,0.4,2)

-- Smoke aura
local auraHolder=make("Frame",{Name="AuraHolder",Position=UDim2.fromOffset(-60,-60),Size=UDim2.new(1,120,1,120),BackgroundTransparency=1,ClipsDescendants=false,ZIndex=0},main)
local smokePuffs={}
task.spawn(function()
    while auraHolder.Parent and gui.Parent do
        if main.Visible and #smokePuffs<18 then
            local w=math.random(120,220)
            local h=math.random(30,60)
            local puff=make("Frame",{Size=UDim2.fromOffset(w,h),Position=UDim2.fromOffset(math.random(-40,math.max(1,math.floor(auraHolder.AbsoluteSize.X)-80)),auraHolder.AbsoluteSize.Y-math.random(0,90)),BackgroundColor3=Color3.fromRGB(195,222,246),BackgroundTransparency=0.9,BorderSizePixel=0,ZIndex=0},auraHolder)
            corner(puff,math.floor(h/2))
            local grad=make("UIGradient",{Transparency=NumberSequence.new({
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
make("TextLabel",{Position=UDim2.fromOffset(20,0),Size=UDim2.fromOffset(500,56),BackgroundTransparency=1,Text="❄  GBO HACKS  (snow)  v3.7",TextColor3=C.textDark,TextSize=22,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},top)

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
        if math.abs(df.X)>5 or math.abs(df.Y)>5 then floatMoved=true end
        if floatMoved then
            floating.Position=UDim2.new(floatStartPos.X.Scale,floatStartPos.X.Offset+df.X,floatStartPos.Y.Scale,floatStartPos.Y.Offset+df.Y)
        end
    end
end)

floating.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        if floatDrag and not floatMoved then restorePanel() end
        floatDrag=false
    end
end)

local function applyMouseState()
    if S.StreamMode then U.MouseBehavior=Enum.MouseBehavior.LockCenter; U.MouseIconEnabled=false; return end
    if S.MouseFree then U.MouseBehavior=Enum.MouseBehavior.Default; U.MouseIconEnabled=true end
end

function minimizePanel() main.Visible=false; floating.Visible=true; applyMouseState() end
function restorePanel() main.Visible=true; floating.Visible=false; applyMouseState() end

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
    sim.Activated:Connect(function() dialog:Destroy(); gui:Destroy() end)
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

local sidebarScroll=make("ScrollingFrame",{Position=UDim2.fromOffset(12,68),Size=UDim2.new(0,200,1,-84),BackgroundColor3=C.panel,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.ice,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=10},main)
corner(sidebarScroll,10)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},sidebarScroll)
make("UIPadding",{PaddingTop=UDim.new(0,12),PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,12)},sidebarScroll)
local sidebar=sidebarScroll
local content=make("Frame",{Position=UDim2.fromOffset(224,68),Size=UDim2.new(1,-236,1,-84),BackgroundTransparency=1,ZIndex=10},main)

local pages={
    {"Home","⌂"},{"ESP","◉"},{"Aim","◎"},{"Silent Aim (RCL)","○"},
    {"Triggerbot","⌖"},{"Hitbox","▣"},{"Movement","↗"},{"Troll","♙"},
    {"Lists","☰"},{"Keybinds","⌨"},{"Credits","©"}
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
    if name=="Lists" then
        if blListRefresh then pcall(blListRefresh) end
        if wlListRefresh then pcall(wlListRefresh) end
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
        if expanded then
            descBox.Size=UDim2.new(1,-20,0,40)
            row.Size=UDim2.new(1,-5,0,(height or 44)+44)
        else
            descBox.Size=UDim2.new(1,-20,0,0)
            row.Size=UDim2.new(1,-5,0,height or 44)
        end
        return expanded
    end
    return row,descBox,toggleDesc
end

local function addArrow(parent,onToggle)
    local arrow=make("TextButton",{Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-26,0,4),BackgroundTransparency=1,Text="▼",TextColor3=C.accent,TextSize=12,Font=Enum.Font.SourceSansBold,TextScaled=true,AutoButtonColor=false,ZIndex=13},parent)
    local up=false
    arrow.Activated:Connect(function()
        up=not up
        arrow.Text=up and "▲" or "▼"
        onToggle(up)
    end)
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
    addArrow(row,function(up)
        toggleDesc()
    end)
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

local function textEntry(p,t,placeholder,callback,desc)
    local row,descBox,toggleDesc=buildRow(p,desc,70)
    make("TextLabel",{Position=UDim2.fromOffset(12,4),Size=UDim2.new(1,-40,0,22),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},row)
    local input=make("TextBox",{Position=UDim2.fromOffset(11,30),Size=UDim2.new(1,-42,0,30),BackgroundColor3=C.bg,Text="",PlaceholderText=placeholder or "Type here...",PlaceholderColor3=C.gray,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=12},row)
    corner(input,6); stroke(input)
    addArrow(row,function() toggleDesc() end)
    input.FocusLost:Connect(function(enter) if callback then pcall(callback,input.Text,enter) end end)
    return input
end

local function actionButton(p,t,callback,desc)
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t,TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function() pcall(callback) end)
    return b
end

local function redButton(p,t,callback,desc)
    local row=make("Frame",{Size=UDim2.new(1,-5,0,48),BackgroundColor3=Color3.fromRGB(230,80,100),BorderSizePixel=0,ZIndex=12,ClipsDescendants=true},frames[p])
    corner(row,8); stroke(row,Color3.fromRGB(255,120,140),1,0.2)
    local descBox=make("TextLabel",{Size=UDim2.new(1,-20,0,0),Position=UDim2.fromOffset(10,48),BackgroundTransparency=1,Text=desc or "",TextColor3=C.textLight,TextSize=11,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=12},row)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,48),BackgroundTransparency=1,Text=t,TextColor3=C.textLight,TextSize=13,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    local expanded=false
    local arrow=make("TextButton",{Size=UDim2.fromOffset(20,20),Position=UDim2.new(1,-26,0,14),BackgroundTransparency=1,Text="▼",TextColor3=C.textLight,TextSize=12,Font=Enum.Font.SourceSansBold,TextScaled=true,AutoButtonColor=false,ZIndex=13},row)
    arrow.Activated:Connect(function()
        expanded=not expanded
        arrow.Text=expanded and "▲" or "▼"
        if expanded then
            descBox.Size=UDim2.new(1,-20,0,40); row.Size=UDim2.new(1,-5,0,92)
        else
            descBox.Size=UDim2.new(1,-20,0,0); row.Size=UDim2.new(1,-5,0,48)
        end
    end)
    b.Activated:Connect(function() pcall(callback) end)
    return b
end

local palette={
    {"White",Color3.fromRGB(245,245,250)},{"Ice blue",Color3.fromRGB(130,210,255)},
    {"Red",Color3.fromRGB(255,100,110)},{"Green",Color3.fromRGB(100,255,160)},
    {"Purple",Color3.fromRGB(190,120,255)},{"Cyan",Color3.fromRGB(0,255,255)}
}
local function colorButton(p,t,settingName,desc)
    local index=1
    local row,descBox,toggleDesc=buildRow(p,desc,44)
    local b=make("TextButton",{Size=UDim2.new(1,-24,0,44),BackgroundTransparency=1,Text=t..": "..palette[1][1].."   ◉",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=true,ZIndex=13},row)
    addArrow(row,function() toggleDesc() end)
    b.Activated:Connect(function()
        index=index%#palette+1
        b.Text=t..": "..palette[index][1].."   ◉"
        b.TextColor3=palette[index][2]; S[settingName]=palette[index][2]
    end)
    return function() return palette[index][2] end
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

local function localLists(p)
    section(p,"Blacklist / Whitelist Local")
    local addBL=textEntry(p,"Add to Blacklist","Name",nil,"Adds a name to blacklist (only affects these targets).")
    actionButton(p,"+ BL",function() local n=addBL.Text; if n~="" and not table.find(S.Blacklist,n) then table.insert(S.Blacklist,1,n); notify("BL: "..n) end end)
    local addWL=textEntry(p,"Add to Whitelist","Name",nil,"Adds a name to whitelist (bypasses ESP/aim).")
    actionButton(p,"+ WL",function() local n=addWL.Text; if n~="" and not table.find(S.Whitelist,n) then table.insert(S.Whitelist,1,n); notify("WL: "..n) end end)
end

-- HOME
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
    if state then notify("Mouse unlocked! Configure the panel.") else notify("Mouse back to game control.") end
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

toggle("Home","Fullbright","Fullbright",false,function(state) setFullbright(state) end,"Brightens the entire map (daytime lighting).")
toggle("Home","Anti AFK","AntiAFK",false,function(state) setAntiAFK(state) end,"Prevents kick for inactivity.")

redButton("Home","🛑  DISABLE EVERYTHING",function()
    for _,rec in ipairs(toggleSetters) do pcall(function() rec.set(false,false) end) end
    S.ESP=false;S.Aimbot=false;S.SilentAim=false;S.TriggerBot=false
    S.Fly=false;S.Noclip=false;S.Freecam=false;S.Rainbow=false
    S.SpeedEnabled=false;S.JumpEnabled=false;S.HitboxEnabled=false
    S.FakeLag=false;S.Spin=false;S.JumpInf=false;S.MouseFree=false;S.Fullbright=false;S.AntiAFK=false
    S.Box=false;S.Name=false;S.Distance=false;S.Health=false;S.ESPTraces=false;S.Skeleton=false
    S.ShowAimFOV=false;S.ShowSilentFOV=false;S.ShowTriggerFOV=false
    S.HitboxRainbow=false;S.SQRainbow=false
    lockTarget=nil
    for _,data in pairs(highlights) do
        if data.box then data.box.Visible=false end
        if data.healthBar then data.healthBar.Visible=false end
        if data.billboard then data.billboard.Enabled=false end
        if data.highlight then data.highlight.Enabled=false end
    end
    for _,t in pairs(drawingTraces) do t.Visible=false end
    for _,t in pairs(drawingSkeletons) do t.Visible=false end
    clearAllHitbox(); clearAllSQ()
    setFullbright(false); setAntiAFK(false)
    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED;hum.JumpPower=DEF_JUMP;hum.PlatformStand=false end
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
            if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
        end
    end
    applyMouseState()
    notify("All options disabled")
end,"Turns off every option but keeps the panel open.")

actionButton("Home","↺  Restore Defaults",function()
    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED;hum.JumpPower=DEF_JUMP;hum.UseJumpPower=true;hum.PlatformStand=false end
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
            if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
        end
    end
    S.MoveSpeed=DEF_SPEED;S.JumpPower=DEF_JUMP;S.FlySpeed=50
    S.Fly=false;S.Noclip=false;S.SpeedEnabled=false;S.JumpEnabled=false;S.JumpInf=false;S.MouseFree=false
    clearAllHitbox(); clearAllSQ()
    setFullbright(false); setAntiAFK(false)
    applyMouseState()
    notify("Defaults restored")
end,"Returns the character to normal game behavior.")

section("Home","About the Panel:")
info("Home","GBO HACKS v3.7 (snow) — PvP panel. Creators: GBO (owner), CHACOIA, JUNIN, TOPENTA, PEDRO.")
local rejoin=make("TextButton",{Size=UDim2.new(1,-5,0,44),BackgroundColor3=C.item,Text="Rejoin",TextColor3=C.textDark,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=12},frames.Home)
corner(rejoin,8)
rejoin.Activated:Connect(function() pcall(function() TP:Teleport(game.PlaceId,LP) end) end)

-- ESP
section("ESP","Visual settings")
info("ESP","Box, skeleton, name, distance, health, traces and colors.")
toggle("ESP","ESP enabled","ESP",false,nil,"Master toggle for every ESP element.")
toggle("ESP","Name ESP","Name",false,nil,"Shows player names above their heads.")
toggle("ESP","Show distance","Distance",false,nil,"Shows distance in meters.")
toggle("ESP","Health ESP","Health",false,nil,"Draws a health bar next to the box.")
toggle("ESP","Box ESP","Box",false,nil,"Draws a box around each player.")
toggle("ESP","Skeleton ESP","Skeleton",false,nil,"Draws bones on each player.")
toggle("ESP","Traces ESP","ESPTraces",false,nil,"Lines from your character to each target.")
toggle("ESP","Team check","ESPTeamCheck",false,nil,"Ignores teammates.")
toggle("ESP","Wall check","ESPWallCheck",false,nil,"Only shows targets in line of sight.")
colorButton("ESP","ESP color","ESPColor","Pick the color used by all ESP elements.")
rainbowButton("ESP","Rainbow color","Rainbow",nil,"Cycles colors on every ESP element.")
slider("ESP","Max distance",50,2000,500,"MaxDist",nil,"Farthest distance ESP will render.")
localLists("ESP")

-- AIM
section("Aim","Aim settings")
info("Aim","Camera-based aimbot. Hold the key to lock on target head.")
toggle("Aim","Aim enabled","Aimbot",false,nil,"Locks your camera onto the target head.")
toggle("Aim","Team check","AimTeamCheck",false,nil,"Skips teammates.")
toggle("Aim","Wall check","AimWallCheck",false,nil,"Requires line of sight.")
toggle("Aim","Show FOV","ShowAimFOV",false,nil,"Draws the aim FOV circle on screen.")
slider("Aim","FOV size",20,500,120,"AimFOV",nil,"Radius of the aim FOV.")
colorButton("Aim","FOV color","AimFOVColor","Color of the aim circle.")
rainbowButton("Aim","Rainbow FOV","Rainbow",nil,"Cycles the FOV color.")
keyButton("Aim","Aim key","AimKey",Enum.KeyCode.Q,"Hold this key to aim.")
localLists("Aim")

-- SILENT AIM (RCL)
local rcl="Silent Aim (RCL)"
section(rcl,"Silent Aim (RCL) settings")
info(rcl,"RCL: snaps the mouse onto the target head without moving the camera. FOV follows the mouse.")
toggle(rcl,"Enabled","SilentAim",false,nil,"Moves the mouse onto target while you hold click.")
toggle(rcl,"Team check","SilentTeamCheck",false,nil,"Skips teammates.")
toggle(rcl,"Wall check","SilentWallCheck",false,nil,"Requires line of sight.")
toggle(rcl,"Show FOV","ShowSilentFOV",false,nil,"Draws the FOV circle around the mouse.")
slider(rcl,"FOV size",20,500,100,"SilentFOV",nil,"Radius of the silent FOV around the mouse.")
colorButton(rcl,"FOV color","SilentFOVColor","Color of the silent circle.")
rainbowButton(rcl,"Rainbow FOV","Rainbow",nil,"Cycles the FOV color.")
keyButton(rcl,"Silent key","SilentKey",Enum.KeyCode.E,"Hold this key to activate silent aim.")
localLists(rcl)

-- TRIGGER
section("Triggerbot","Triggerbot settings")
info("Triggerbot","Fires automatically when a target is in FOV. Uses real screen clicks (works in most games).")
toggle("Triggerbot","Enabled","TriggerBot",false,nil,"Fires when a target enters the FOV.")
toggle("Triggerbot","Silent lock","TriggerLock",false,nil,"Locks camera onto target while firing.")
toggle("Triggerbot","Wallbang","TriggerWallBang",false,nil,"Fires through walls.")
toggle("Triggerbot","Team check","TriggerTeamCheck",false,nil,"Skips teammates.")
toggle("Triggerbot","Wall check","TriggerWallCheck",false,nil,"Requires line of sight.")
toggle("Triggerbot","Show FOV","ShowTriggerFOV",false,nil,"Draws the trigger FOV circle.")
slider("Triggerbot","FOV size",10,400,80,"TriggerFOV",nil,"Radius of the trigger FOV.")
colorButton("Triggerbot","FOV color","TriggerFOVColor","Color of the trigger circle.")
rainbowButton("Triggerbot","Rainbow FOV","Rainbow",nil,"Cycles the FOV color.")
keyButton("Triggerbot","Trigger key","TriggerKey",Enum.KeyCode.T,"Hold to enable triggerbot.")
localLists("Triggerbot")

-- HITBOX
local hb="Hitbox"
section(hb,"Hitbox expander")
info(hb,"Expands the target head hitbox. Reapplies on respawn.")
toggle(hb,"Hitbox enabled","HitboxEnabled",false,function() refreshAllHitboxes() end,"Expands everyone's head hitbox.")
actionButton(hb,"Mode: Head (click to swap)",function()
    S.HitboxMode=S.HitboxMode=="head" and "square" or "head"
    notify("Mode: "..(S.HitboxMode=="square" and "Square" or "Head"))
    refreshAllHitboxes()
end,"Switch between head-only and universal square.")
slider(hb,"Hitbox size",1,100,3,"HitboxSize",function(v)
    S.SQSize=v; refreshAllHitboxes()
end,"Size of the hitbox in studs (up to 100).")
slider(hb,"Hitbox transparency",0,100,0,"HitboxTransparency",function(v)
    S.HitboxTransparency=v/100; S.SQTransparency=v/100; refreshAllHitboxes()
end,"How transparent the hitbox is (0 = solid).")
colorButton(hb,"Hitbox color","SQColor","Color of the square hitbox.")
rainbowButton(hb,"Rainbow hitbox","HitboxRainbow",function(v)
    S.SQRainbow=v; refreshAllHitboxes()
end,"Cycles the hitbox color.")
actionButton(hb,"Swap visual (head / circle)",function()
    S.HitboxVisual=S.HitboxVisual=="head" and "circle" or "head"
    refreshAllHitboxes()
    notify("Visual: "..(S.HitboxVisual=="circle" and "Circle" or "Head"))
end,"Toggle between a real head mesh and a circle ball.")
localLists(hb)

-- MOVEMENT
section("Movement","Movement")
info("Movement","Enable each option individually. Disables back to game defaults.")
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
end,"WASD to fly, Space up, LeftCtrl down.")
slider("Movement","Fly speed",1,200,50,"FlySpeed",nil,"How fast you fly.")
toggle("Movement","Speed","SpeedEnabled",false,function(state)
    if not state and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED end
    end
end,"Increases walk speed.")
slider("Movement","WalkSpeed",1,100,DEF_SPEED,"MoveSpeed",nil,"Walk speed value.")
toggle("Movement","Jump Power","JumpEnabled",false,function(state)
    if not state and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower=DEF_JUMP end
    end
end,"Changes jump height.")
slider("Movement","Jump Power value",1,300,DEF_JUMP,"JumpPower",nil,"Jump power value.")
toggle("Movement","Infinite Jumps","JumpInf",false,nil,"Press Space in mid-air to keep jumping.")
toggle("Movement","Noclip","Noclip",false,nil,"Walk through walls.")
actionButton("Movement","Restore Defaults",function()
    S.MoveSpeed=DEF_SPEED;S.JumpPower=DEF_JUMP;S.FlySpeed=50
    S.Fly=false;S.Noclip=false;S.SpeedEnabled=false;S.JumpEnabled=false;S.JumpInf=false
    if LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=DEF_SPEED;hum.JumpPower=DEF_JUMP;hum.PlatformStand=false end
        for part,state in pairs(savedCharCollision) do if part and part.Parent then part.CanCollide=state end end
        savedCharCollision={}; noclipState=false
        local root=LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("FlyBV") then root.FlyBV:Destroy() end
            if root:FindFirstChild("FlyBG") then root.FlyBG:Destroy() end
        end
    end
    notify("Movement restored"); showPage("Movement")
end,"Resets all movement options to defaults.")

-- TROLL
section("Troll","Tools")
info("Troll","Freecam, teleport, spectate, fake lag, spin.")
toggle("Troll","Freecam","Freecam",false,function(state)
    if state then
        originalCFrame=camera.CFrame; originalCameraType=camera.CameraType
        camera.CameraType=Enum.CameraType.Scriptable
        freecam.enabled=true; freecam.pos=camera.CFrame.Position; freecam.yaw=0; freecam.pitch=0
        if LP.Character then
            local hum=LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
        end
    else
        camera.CameraType=originalCameraType or Enum.CameraType.Custom
        if originalCFrame then camera.CFrame=originalCFrame end
        freecam.enabled=false
        if LP.Character then
            local hum=LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed=S.SpeedEnabled and S.MoveSpeed or DEF_SPEED; hum.JumpPower=S.JumpEnabled and S.JumpPower or DEF_JUMP end
        end
    end
end,"Detach the camera and fly around with WASD.")

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
end,"Freezes you in place briefly to look laggy.")
slider("Troll","Fake lag intensity (ms)",50,2000,200,"FakeLagAmount",nil,"How long each freeze lasts.")

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
end,"Makes your character spin.")
slider("Troll","Spin speed",10,500,50,"SpinSpeed",nil,"Degrees per frame.")

local tpInput=textEntry("Troll","TP Player (name)","Type the player name",nil,"Teleport to the typed player.")
actionButton("Troll","▶  Teleport to player",function()
    local target=fuzzyFind(tpInput.Text)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame=target.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3); notify("TP: "..target.Name) end
    else notify("Player not found") end
end,"Teleports behind the typed player.")

local specInput=textEntry("Troll","Spectate (name)","Type the player name",nil,"Free camera from the typed player's head.")
actionButton("Troll","▶  Spectate player",function()
    local target=fuzzyFind(specInput.Text)
    if target and target.Character then S.Spectate=true; S.SpectateTarget=target; notify("Spectating: "..target.Name)
    else notify("Player not found") end
end,"Follows the typed player's view.")
actionButton("Troll","Stop spectating",function() S.Spectate=false; S.SpectateTarget=nil; notify("Stopped") end,"Returns the camera to you.")

-- LISTS
section("Lists","Manage Blacklist / Whitelist")
info("Lists","Blacklist: aim/trigger/hitbox only target these. Whitelist: ESP/aim ignore these.")

local function addToList(listName,name)
    if not name or name=="" then return end
    local list=S[listName]
    if not table.find(list,name) then table.insert(list,1,name); notify(listName..": "..name) end
end

local function removeFromList(listName,name)
    local list=S[listName]
    local i=table.find(list,name)
    if i then table.remove(list,i); notify("Removed from "..listName..": "..name) end
end

local blAddInput=textEntry("Lists","Add to Blacklist","Player name",nil,"Only these players will be targeted.")
actionButton("Lists","+ Add to Blacklist",function() addToList("Blacklist",blAddInput.Text) end,"Adds the typed name.")
local wlAddInput=textEntry("Lists","Add to Whitelist","Player name",nil,"These players are ignored by ESP/aim.")
actionButton("Lists","+ Add to Whitelist",function() addToList("Whitelist",wlAddInput.Text) end,"Adds the typed name.")

local blRemoveInput=textEntry("Lists","Remove from Blacklist","Player name",nil,"Removes a name from blacklist.")
actionButton("Lists","- Remove from Blacklist",function() removeFromList("Blacklist",blRemoveInput.Text) end,"Removes the typed name.")
local wlRemoveInput=textEntry("Lists","Remove from Whitelist","Player name",nil,"Removes a name from whitelist.")
actionButton("Lists","- Remove from Whitelist",function() removeFromList("Whitelist",wlRemoveInput.Text) end,"Removes the typed name.")

actionButton("Lists","Clear Blacklist",function() S.Blacklist={}; notify("Blacklist cleared"); if blListRefresh then blListRefresh() end end,"Removes every name from blacklist.")
actionButton("Lists","Clear Whitelist",function() S.Whitelist={}; notify("Whitelist cleared"); if wlListRefresh then wlListRefresh() end end,"Removes every name from whitelist.")

section("Lists","Players in Blacklist")
local blContainer=make("Frame",{Size=UDim2.new(1,-5,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=12},frames["Lists"])
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},blContainer)

section("Lists","Players in Whitelist")
local wlContainer=make("Frame",{Size=UDim2.new(1,-5,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=12},frames["Lists"])
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},wlContainer)

local function makePlayerCard(container,playerName)
    local card=make("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=C.item,BorderSizePixel=0,ZIndex=12},container)
    corner(card,8); stroke(card)
    local thumb=make("ImageLabel",{Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(46,46),BackgroundColor3=C.bg,Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=12},card)
    corner(thumb,23)
    make("TextLabel",{Position=UDim2.fromOffset(60,8),Size=UDim2.new(1,-90,0,20),BackgroundTransparency=1,Text=playerName,TextColor3=C.textDark,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},card)
    make("TextLabel",{Position=UDim2.fromOffset(60,28),Size=UDim2.new(1,-90,0,18),BackgroundTransparency=1,Text="@"..playerName,TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12},card)
    task.spawn(function()
        local targetPlayer=P:FindFirstChild(playerName)
        if targetPlayer then
            local ok,url=pcall(function() return P:GetUserThumbnailAsync(targetPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
            if ok and thumb.Parent then thumb.Image=url end
        end
    end)
end

local function refreshList(container,list)
    for _,c in ipairs(container:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if #list==0 then return end
    for _,name in ipairs(list) do makePlayerCard(container,name) end
end

blListRefresh=function() refreshList(blContainer,S.Blacklist) end
wlListRefresh=function() refreshList(wlContainer,S.Whitelist) end

task.spawn(function()
    while gui.Parent do
        if frames["Lists"] and frames["Lists"].Visible then pcall(blListRefresh); pcall(wlListRefresh) end
        task.wait(1)
    end
end)

-- KEYBINDS
local kp="Keybinds"
section(kp,"Keybind manager")
info(kp,"Click Create bind, search a function and pick a key. Starts empty.")
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

make("TextLabel",{Size=UDim2.new(1,-5,0,24),BackgroundTransparency=1,Text="Pick an option, then press the key. Starts empty.",TextColor3=C.gray,TextSize=11,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=12},frames[kp])

-- CREDITS
section("Credits","Credits")
info("Credits","Thanks to everyone who contributed.")
for _,name in ipairs({"BY GBO HACKS (owner)","BY CHACOIA HACKS","BY JUNIN HACKS","BY TOPENTA HACKS","BY PEDRO HACKS"}) do
    local b=make("TextLabel",{Size=UDim2.new(1,-5,0,36),BackgroundColor3=C.item,Text="❄   "..name,TextColor3=C.textDark,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=12},frames.Credits)
    corner(b,7)
end

-- LOGIC
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
        for _,obj in pairs(highlights[p]) do if obj and obj.Parent then obj:Destroy() end end
        highlights[p]=nil
    end
    if drawingTraces[p] then pcall(function() drawingTraces[p]:Remove() end); drawingTraces[p]=nil end
    if drawingSkeletons[p] then
        for _,line in ipairs(drawingSkeletons[p]) do pcall(function() line:Remove() end) end
        drawingSkeletons[p]=nil
    end
end

local BONES={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"LowerTorso","HumanoidRootPart"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local RBONES={{"Head","Torso"},{"Torso","HumanoidRootPart"},{"Torso","Left Arm"},{"Left Arm","Left Leg"},{"Torso","Right Arm"},{"Right Arm","Right Leg"}}

local function createESPForPlayer(p)
    if not p.Character then return end
    local data={}
    data.box=make("Frame",{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,ZIndex=30,Visible=false},gui)
    data.boxStroke=stroke(data.box,S.ESPColor,1.5,0)
    data.healthBar=make("Frame",{Size=UDim2.fromOffset(4,0),BackgroundColor3=Color3.fromRGB(30,30,30),BackgroundTransparency=0.3,ZIndex=31,Visible=false},gui)
    data.healthFill=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.green,ZIndex=32},data.healthBar)
    data.highlight=make("Highlight",{FillColor=S.ESPColor,OutlineColor=S.ESPColor,FillTransparency=0.7,OutlineTransparency=0.3,Enabled=false},p.Character)
    local head=p.Character:FindFirstChild("Head")
    if head then
        data.billboard=make("BillboardGui",{Size=UDim2.fromOffset(200,40),StudsOffsetWorldSpace=Vector3.new(0,2.5,0),AlwaysOnTop=true,MaxDistance=S.MaxDist,Enabled=false},head)
        data.billboard.Adornee=head
        data.text=make("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",TextColor3=S.ESPColor,Font=Enum.Font.GothamBold,TextSize=11,TextStrokeTransparency=0.5,ZIndex=34},data.billboard)
    end
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
    end
    highlights[p]=data
end

local function updateTrace(p)
    if not drawingTraces[p] then return end
    local line=drawingTraces[p]
    if S.StreamMode or not S.ESP or not S.ESPTraces or not validPlayer(p) or not LP.Character then
        line.Visible=false; return
    end
    local myRoot=LP.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot=p.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then line.Visible=false; return end
    local myPos,myOn=camera:WorldToViewportPoint(myRoot.Position)
    local tPos,tOn=camera:WorldToViewportPoint(targetRoot.Position)
    if not myOn or not tOn then line.Visible=false; return end
    line.From=Vector2.new(myPos.X,myPos.Y); line.To=Vector2.new(tPos.X,tPos.Y)
    line.Color=S.ESPColor; line.Visible=true
end

local function updateSkeleton(p)
    local skel=drawingSkeletons[p]
    if not skel then return end
    if S.StreamMode or not S.ESP or not S.Skeleton or not validPlayer(p) then
        for _,l in ipairs(skel) do l.Visible=false end
        return
    end
    local char=p.Character
    local rig=char:FindFirstChild("Humanoid") and char.Humanoid.RigType==Enum.HumanoidRigType.R15
    local bones=rig and BONES or RBONES
    for i,b in ipairs(bones) do
        local a1=char:FindFirstChild(b[1])
        local a2=char:FindFirstChild(b[2])
        local line=skel[i]
        if a1 and a2 then
            local s1,o1=camera:WorldToViewportPoint(a1.Position)
            local s2,o2=camera:WorldToViewportPoint(a2.Position)
            if o1 and o2 then
                line.From=Vector2.new(s1.X,s1.Y); line.To=Vector2.new(s2.X,s2.Y)
                line.Color=S.ESPColor; line.Visible=true
            else line.Visible=false end
        else line.Visible=false end
    end
    for i=#bones+1,#skel do skel[i].Visible=false end
end

local function updateESP()
    local seen={}
    for _,p in ipairs(P:GetPlayers()) do
        if not inList(S.Whitelist,p.Name) then
            if validPlayer(p) and not isFriendly(p,S.ESPTeamCheck) then
                seen[p]=true
                if not highlights[p] then createESPForPlayer(p) end
                local data=highlights[p]
                if data then
                    local hum=p.Character:FindFirstChildOfClass("Humanoid")
                    local root=p.Character:FindFirstChild("HumanoidRootPart")
                    local head=p.Character:FindFirstChild("Head")
                    if hum and root and head then
                        local dist=(camera.CFrame.Position-root.Position).Magnitude
                        local skip=S.StreamMode or dist>S.MaxDist
                        if not skip and S.ESPWallCheck and hasWallBetween(head) then skip=true end
                        if skip then
                            data.box.Visible=false; data.healthBar.Visible=false
                            if data.billboard then data.billboard.Enabled=false end
                            if data.highlight then data.highlight.Enabled=false end
                            if drawingTraces[p] then drawingTraces[p].Visible=false end
                            if drawingSkeletons[p] then for _,l in ipairs(drawingSkeletons[p]) do l.Visible=false end end
                        elseif S.ESP then
                            data.highlight.Enabled=true
                            data.highlight.FillColor=S.ESPColor
                            data.highlight.OutlineColor=S.ESPColor
                            local headSP,headOn=camera:WorldToViewportPoint(head.Position)
                            local feetSP,feetOn=camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
                            if headOn and feetOn and headSP.Z>0 then
                                local height=math.abs(headSP.Y-feetSP.Y)*1.1
                                local width=height*0.55
                                if S.Box then
                                    data.box.Visible=true
                                    data.box.Size=UDim2.fromOffset(width,height)
                                    data.box.Position=UDim2.fromOffset(headSP.X-width/2,headSP.Y)
                                    data.boxStroke.Color=S.ESPColor
                                    data.boxStroke.Thickness=1.5
                                    data.boxStroke.Transparency=0
                                else data.box.Visible=false end
                                if S.Health then
                                    data.healthBar.Visible=true
                                    data.healthBar.Size=UDim2.fromOffset(4,height)
                                    data.healthBar.Position=UDim2.fromOffset(headSP.X-width/2-8,headSP.Y)
                                    local hp=math.clamp(hum.Health/hum.MaxHealth,0,1)
                                    data.healthFill.Size=UDim2.new(1,0,hp,0)
                                    data.healthFill.Position=UDim2.new(0,0,1-hp,0)
                                    data.healthFill.BackgroundColor3=Color3.fromHSV(hp*0.3,1,1)
                                else data.healthBar.Visible=false end
                            else
                                data.box.Visible=false; data.healthBar.Visible=false
                            end
                            if data.billboard then
                                if S.Name or S.Distance then
                                    data.billboard.Enabled=true
                                    local txt=""
                                    if S.Name then txt=p.Name end
                                    if S.Distance then
                                        if txt~="" then txt=txt.." | " end
                                        txt=txt..math.floor(dist).."m"
                                    end
                                    data.text.Text=txt; data.text.TextColor3=S.ESPColor
                                else data.billboard.Enabled=false end
                            end
                            updateTrace(p)
                            updateSkeleton(p)
                        else
                            data.box.Visible=false; data.healthBar.Visible=false
                            if data.billboard then data.billboard.Enabled=false end
                            data.highlight.Enabled=false
                            if drawingTraces[p] then drawingTraces[p].Visible=false end
                            if drawingSkeletons[p] then for _,l in ipairs(drawingSkeletons[p]) do l.Visible=false end end
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
        if p.Character then createESPForPlayer(p) end
        if S.HitboxEnabled then
            task.wait(0.4)
            if S.HitboxMode=="head" then applyHitboxToPlayer(p) else applySQ(p) end
        end
    end
    p.CharacterAdded:Connect(onChar)
    if p.Character then onChar() end
end

for _,p in ipairs(P:GetPlayers()) do bindPlayer(p) end
P.PlayerAdded:Connect(bindPlayer)
P.PlayerRemoving:Connect(function(p) resetSQ(p); removeHighlight(p) end)

local aimFovCircle=make("Frame",{Name="AimFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.AimFOV*2,S.AimFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(aimFovCircle,1000); local aimRingStroke=stroke(aimFovCircle,S.AimFOVColor,0.1); aimRingStroke.Thickness=2
local silentFovCircle=make("Frame",{Name="SilentFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.SilentFOV*2,S.SilentFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(silentFovCircle,1000); local silentRingStroke=stroke(silentFovCircle,S.SilentFOVColor,0.3); silentRingStroke.Thickness=2
local triggerFovCircle=make("Frame",{Name="TriggerFOV",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(S.TriggerFOV*2,S.TriggerFOV*2),BackgroundTransparency=1,Visible=false,ZIndex=20},gui)
corner(triggerFovCircle,1000); local triggerRingStroke=stroke(triggerFovCircle,S.TriggerFOVColor,0.3); triggerRingStroke.Thickness=2

local function getScreenCenter()
    local vp=camera.ViewportSize
    return Vector2.new(vp.X/2, vp.Y/2)
end

local function getMouseScreen()
    return U:GetMouseLocation()
end

local function getClosestPlayerFromOrigin(fovRadius,teamCheck,wallCheck,origin)
    local best,bestDist=nil,math.huge
    for _,p in ipairs(P:GetPlayers()) do
        if validPlayer(p) and not isFriendly(p,teamCheck) then
            local allowed=#S.Blacklist==0 or inList(S.Blacklist,p.Name)
            local blocked=inList(S.Whitelist,p.Name)
            if allowed and not blocked then
                local head=p.Character:FindFirstChild("Head")
                if head then
                    local ok=true
                    if wallCheck and hasWallBetween(head) then ok=false end
                    if ok then
                        local sp,on=camera:WorldToViewportPoint(head.Position)
                        if on then
                            local sd=(Vector2.new(sp.X,sp.Y)-origin).Magnitude
                            if sd<fovRadius then
                                local wd=(camera.CFrame.Position-head.Position).Magnitude
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
    if type(mousemoverel)=="function" then pcall(mousemoverel,dx,dy); return true end
    pcall(function() VIM:SendMouseMoveEvent(Vector2.new(dx,dy),false) end)
    return true
end

local function realScreenClick()
    local vp=camera.ViewportSize
    local cx=math.floor(vp.X/2 + math.random(-3,3))
    local cy=math.floor(vp.Y/2 + math.random(-3,3))
    pcall(function()
        VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
        task.wait(0.02)
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
        end
        for _,t in pairs(drawingTraces) do t.Visible=false end
        for _,sk in pairs(drawingSkeletons) do for _,l in ipairs(sk) do l.Visible=false end end
    else
        main.Visible=guiVisibleBeforeStream; statusBar.Visible=true
        for _,n in ipairs(notes:GetChildren()) do if n:IsA("TextLabel") then n.Visible=true end end
    end
end

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

U.InputChanged:Connect(function(input)
    if freecam.enabled and input.UserInputType==Enum.UserInputType.MouseMovement then
        local d=input.Delta
        freecam.yaw=freecam.yaw-d.X*0.005
        freecam.pitch=math.clamp(freecam.pitch-d.Y*0.005,-1.5,1.5)
    end
end)

R.RenderStepped:Connect(function(dt)
    if S.MouseFree and not S.StreamMode then
        if U.MouseBehavior ~= Enum.MouseBehavior.Default then
            U.MouseBehavior = Enum.MouseBehavior.Default
            U.MouseIconEnabled = true
        end
    end

    pcall(updateESP)

    if S.HitboxEnabled then
        for _,p in ipairs(P:GetPlayers()) do
            if p~=LP and p.Character then
                if S.HitboxMode=="square" then
                    if sqOriginal[p] then
                        local root=p.Character:FindFirstChild("HumanoidRootPart")
                        if root and math.abs(root.Size.X-(S.HitboxSize or 5))>0.01 then applySQ(p) end
                    end
                elseif S.HitboxRainbow then
                    local head=p.Character:FindFirstChild("Head")
                    if head then
                        local hue=(os.clock()*0.2)%1
                        head.Color=Color3.fromHSV(hue,1,1)
                        local marker=head:FindFirstChild("HitboxMarker")
                        if marker then marker.Color=Color3.fromHSV(hue,1,1) end
                    end
                end
            end
        end
        if S.HitboxMode=="square" and S.SQRainbow then
            for _,p in ipairs(P:GetPlayers()) do
                if sqOriginal[p] then
                    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if root then root.Color=Color3.fromHSV((os.clock()*0.2)%1,1,1) end
                end
            end
        end
    end

    local center=getScreenCenter()
    local mousePos=getMouseScreen()

    if freecam.enabled then
        local mv=Vector3.new()
        if U:IsKeyDown(Enum.KeyCode.W) then mv=mv+camera.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.S) then mv=mv-camera.CFrame.LookVector end
        if U:IsKeyDown(Enum.KeyCode.A) then mv=mv-camera.CFrame.RightVector end
        if U:IsKeyDown(Enum.KeyCode.D) then mv=mv+camera.CFrame.RightVector end
        if U:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
        if U:IsKeyDown(Enum.KeyCode.LeftShift) then mv=mv-Vector3.new(0,1,0) end
        if mv.Magnitude>0 then mv=mv.Unit*S.FlySpeed*dt; freecam.pos=freecam.pos+mv end
        camera.CFrame=CFrame.new(freecam.pos)*CFrame.Angles(0,freecam.yaw,0)*CFrame.Angles(0,freecam.pitch,0)
    end

    if S.Spectate and S.SpectateTarget and S.SpectateTarget.Character then
        local root=S.SpectateTarget.Character:FindFirstChild("HumanoidRootPart")
        local head=S.SpectateTarget.Character:FindFirstChild("Head")
        if root then
            local tp=head and head.Position or root.Position
            camera.CFrame=CFrame.new(tp+Vector3.new(0,2,5),tp)
        end
    end

    if S.Rainbow then
        local hue=(os.clock()*0.15)%1
        local color=Color3.fromHSV(hue,1,1)
        S.ESPColor=color; S.AimFOVColor=color
        S.SilentFOVColor=color; S.TriggerFOVColor=color
    end

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
        local target=getClosestPlayerFromOrigin(S.AimFOV,S.AimTeamCheck,S.AimWallCheck,center)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            camera.CFrame=CFrame.new(camera.CFrame.Position,target.Character.Head.Position)
        end
    end

    if S.SilentAim and U:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not main.Visible then
        if not lockTarget or not validPlayer(lockTarget) then
            lockTarget=getClosestPlayerFromOrigin(S.SilentFOV,S.SilentTeamCheck,S.SilentWallCheck,mousePos)
        end
        if lockTarget and lockTarget.Character then
            local head=lockTarget.Character:FindFirstChild("Head")
            if head then
                local sp,on=camera:WorldToViewportPoint(head.Position)
                if on then
                    local mp=U:GetMouseLocation()
                    silentAimMove(sp.X-mp.X,sp.Y-mp.Y)
                end
            end
        end
    else
        lockTarget=nil
    end

    if S.TriggerBot and not main.Visible then
        local target=getClosestPlayerFromOrigin(S.TriggerFOV,S.TriggerTeamCheck,false,center)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head=target.Character.Head
            local sp,on=camera:WorldToViewportPoint(head.Position)
            local sd=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            local canShoot=sd<S.TriggerFOV
            if S.TriggerWallBang then canShoot=true end
            if canShoot then
                if not S.TriggerWallBang and S.TriggerWallCheck and hasWallBetween(head) then
                    canShoot=false
                end
            end
            if canShoot then
                if S.TriggerLock then camera.CFrame=CFrame.new(camera.CFrame.Position,head.Position) end
                task.spawn(realScreenClick)
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
                if part:IsA("BasePart") and savedCharCollision[part]==nil then
                    savedCharCollision[part]=part.CanCollide
                end
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
                multiJumpLast=now
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
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
            bv.Name="FlyBV"
            bv.MaxForce=Vector3.new(9e9,9e9,9e9)
            bv.P=1250
            bv.Velocity=Vector3.new(0,0,0)
            bv.Parent=root
        end
        local bg=root:FindFirstChild("FlyBG")
        if not bg then
            bg=Instance.new("BodyGyro")
            bg.Name="FlyBG"
            bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
            bg.P=1e4
            bg.D=500
            bg.CFrame=camera.CFrame
            bg.Parent=root
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
notify("GBO HACKS (snow) v3.7 loaded ❄")
print("[GBO HACKS (snow) v3.7] loaded.")
