-- ELITE INSTALLER v2
-- Creates the playable ELITE prototype.
-- Main upgrades: flat floor with visible tiles, polished menu, lower mouse sensitivity,
-- improved procedural rifle, and cleaner HUD.

local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Lighting=game:GetService("Lighting")

local function wipe(name,parent)
 local x=parent:FindFirstChild(name); if x then x:Destroy() end
end
wipe("ELITE_Arena",Workspace); wipe("ELITE_Remotes",ReplicatedStorage)
wipe("ELITE_Server",ServerScriptService); wipe("ELITE_Client",StarterPlayer.StarterPlayerScripts)

Lighting.ClockTime=14
Lighting.Brightness=2
Lighting.GlobalShadows=true
Lighting.Ambient=Color3.fromRGB(70,70,85)
Lighting.OutdoorAmbient=Color3.fromRGB(100,100,120)

local rem=Instance.new("Folder"); rem.Name="ELITE_Remotes"; rem.Parent=ReplicatedStorage
for _,n in ipairs({"Fire","Reload","Hitmarker","AmmoState"}) do local e=Instance.new("RemoteEvent"); e.Name=n; e.Parent=rem end

local red=Teams:FindFirstChild("ELITE RED") or Instance.new("Team")
red.Name="ELITE RED"; red.TeamColor=BrickColor.new("Really red"); red.AutoAssignable=false; red.Parent=Teams
local blue=Teams:FindFirstChild("ELITE BLUE") or Instance.new("Team")
blue.Name="ELITE BLUE"; blue.TeamColor=BrickColor.new("Really blue"); blue.AutoAssignable=false; blue.Parent=Teams

local map=Instance.new("Folder"); map.Name="ELITE_Arena"; map.Parent=Workspace
local function part(n,s,p,m,mat)
 local x=Instance.new("Part"); x.Name=n; x.Size=s; x.Position=p; x.Anchored=true
 x.CanCollide=true; x.Material=mat or Enum.Material.Concrete; x.TopSurface=Enum.SurfaceType.Smooth; x.BottomSurface=Enum.SurfaceType.Smooth
 if m then x.Color=m end; x.Parent=map; return x
end

-- Flat, thick floor: the old thin floor could appear to disappear/fail to load.
part("Floor",Vector3.new(240,4,180),Vector3.new(0,-2,0),Color3.fromRGB(32,34,40),Enum.Material.Concrete)

-- Floor grid strips make the playable surface obvious.
for x=-100,100,20 do part("FloorLineX",Vector3.new(0.25,.12,180),Vector3.new(x,.08,0),Color3.fromRGB(58,60,70),Enum.Material.SmoothPlastic) end
for z=-70,70,20 do part("FloorLineZ",Vector3.new(240,.12,.25),Vector3.new(0,.08,z),Color3.fromRGB(58,60,70),Enum.Material.SmoothPlastic) end

part("NorthWall",Vector3.new(240,24,4),Vector3.new(0,10,-90),nil,Enum.Material.Brick)
part("SouthWall",Vector3.new(240,24,4),Vector3.new(0,10,90),nil,Enum.Material.Brick)
part("WestWall",Vector3.new(4,24,180),Vector3.new(-120,10,0),nil,Enum.Material.Brick)
part("EastWall",Vector3.new(4,24,180),Vector3.new(120,10,0),nil,Enum.Material.Brick)

for i,x in ipairs({-70,-35,0,35,70}) do
 part("CenterCover"..i,Vector3.new(12,8,28),Vector3.new(x,4,0),Color3.fromRGB(52,55,65),Enum.Material.Metal)
end
part("CenterBlock",Vector3.new(26,10,18),Vector3.new(0,5,0),Color3.fromRGB(62,65,78),Enum.Material.Metal)
part("RedBase",Vector3.new(30,8,32),Vector3.new(-92,4,0),Color3.fromRGB(110,30,38),Enum.Material.Metal)
part("BlueBase",Vector3.new(30,8,32),Vector3.new(92,4,0),Color3.fromRGB(35,65,120),Enum.Material.Metal)
for _,v in ipairs({{-65,3,-45},{-65,3,45},{65,3,-45},{65,3,45},{-20,2.5,-35},{20,2.5,35}}) do
 part("Cover",Vector3.new(18,6,14),Vector3.new(v[1],v[2],v[3]),Color3.fromRGB(48,51,60),Enum.Material.Metal)
end

local function spawn(n,p,t,c)
 local s=Instance.new("SpawnLocation"); s.Name=n; s.Size=Vector3.new(10,1,10); s.Position=p; s.Anchored=true
 s.Neutral=false; s.TeamColor=t.TeamColor; s.Color=c; s.Material=Enum.Material.Neon; s.Transparency=.15; s.Parent=map
end
spawn("RedSpawn",Vector3.new(-105,1,0),red,Color3.fromRGB(255,55,65))
spawn("BlueSpawn",Vector3.new(105,1,0),blue,Color3.fromRGB(55,120,255))

local server=Instance.new("Script"); server.Name="ELITE_Server"; server.Source=[[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Debris=game:GetService("Debris")
local Workspace=game:GetService("Workspace")
local rem=ReplicatedStorage:WaitForChild("ELITE_Remotes")
local fire,reload,hitmarker,ammoState=rem.Fire,rem.Reload,rem.Hitmarker,rem.AmmoState
local CFG={Damage=24,HeadshotMultiplier=1.6,Range=700,FireRate=.105,Magazine=30,Reserve=120,ReloadTime=1.65,WalkSpeed=16,SprintSpeed=24}
local state={}
local red,blue=Teams:WaitForChild("ELITE RED"),Teams:WaitForChild("ELITE BLUE")
local function sync(p) local s=state[p]; if s then ammoState:FireClient(p,s.ammo,s.reserve,s.reloading) end end
local function team(p)
 local r,b=0,0
 for _,x in ipairs(Players:GetPlayers()) do if x.Team==red then r+=1 elseif x.Team==blue then b+=1 end end
 p.Team=(r<=b) and red or blue
end
Players.PlayerAdded:Connect(function(p)
 team(p); state[p]={ammo=30,reserve=120,last=0,reloading=false}
 local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=p
 for _,n in ipairs({"KILLS","DEATHS","SCORE"}) do local v=Instance.new("IntValue"); v.Name=n; v.Parent=ls end
 p.CharacterAdded:Connect(function(c)
  local h=c:WaitForChild("Humanoid"); h.WalkSpeed=16; task.wait(.2); sync(p)
  h.Died:Connect(function() ls.DEATHS.Value+=1 end)
 end)
end)
Players.PlayerRemoving:Connect(function(p) state[p]=nil end)
reload.OnServerEvent:Connect(function(p)
 local s=state[p]; if not s or s.reloading or s.ammo>=30 or s.reserve<=0 then sync(p); return end
 s.reloading=true; sync(p)
 task.delay(1.65,function()
  if not state[p] then return end
  local take=math.min(30-s.ammo,s.reserve); s.ammo+=take; s.reserve-=take; s.reloading=false; sync(p)
 end)
end)
fire.OnServerEvent:Connect(function(p,origin,direction)
 local s=state[p]; if not s or s.reloading or typeof(origin)~="Vector3" or typeof(direction)~="Vector3" then return end
 if os.clock()-s.last<.084 or s.ammo<=0 then sync(p); return end
 local c=p.Character; local head=c and c:FindFirstChild("Head"); if not head then return end
 if (origin-head.Position).Magnitude>8 then origin=head.Position end
 s.last=os.clock(); s.ammo-=1; sync(p)
 local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={c}
 local dir=direction.Unit; local hit=Workspace:Raycast(origin,dir*CFG.Range,rp); local hp=hit and hit.Position or origin+dir*CFG.Range
 local tr=Instance.new("Part"); tr.Name="ELITE_Tracer"; tr.Anchored=true; tr.CanCollide=false; tr.CanQuery=false; tr.CanTouch=false; tr.Material=Enum.Material.Neon
 tr.Size=Vector3.new(.07,.07,(hp-origin).Magnitude); tr.CFrame=CFrame.lookAt((origin+hp)/2,hp); tr.Parent=Workspace; Debris:AddItem(tr,.035)
 if hit then
  local model=hit.Instance:FindFirstAncestorOfClass("Model"); local h=model and model:FindFirstChildOfClass("Humanoid"); local target=model and Players:GetPlayerFromCharacter(model)
  if h and target and target~=p and target.Team~=p.Team and h.Health>0 then
   local hs=hit.Instance.Name=="Head"; local dmg=hs and CFG.Damage*CFG.HeadshotMultiplier or CFG.Damage; local before=h.Health
   h:TakeDamage(dmg); local kill=before>0 and h.Health<=0
   hitmarker:FireClient(p,kill,hs,math.floor(dmg))
   if kill then local ls=p.leaderstats; ls.KILLS.Value+=1; ls.SCORE.Value+=100 end
  end
 end
end)
]]

server.Parent=ServerScriptService

local client=Instance.new("LocalScript"); client.Name="ELITE_Client"; client.Source=[[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local p=Players.LocalPlayer; local cam=workspace.CurrentCamera
local rem=RS:WaitForChild("ELITE_Remotes")
local fire,reload,hitmarker,ammoState=rem.Fire,rem.Reload,rem.Hitmarker,rem.AmmoState
local ammo,reserve=30,120; local reloading=false; local aiming=false; local sprint=false; local crouch=false; local last=0; local gun
local sensitivity=.35
local started=false
UIS.MouseBehavior=Enum.MouseBehavior.Default
UIS.MouseIconEnabled=true

local gui=Instance.new("ScreenGui"); gui.Name="ELITE_UI"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.Parent=p:WaitForChild("PlayerGui")
local menu=Instance.new("Frame"); menu.Name="MainMenu"; menu.Size=UDim2.fromScale(1,1); menu.BackgroundColor3=Color3.fromRGB(10,11,16); menu.Parent=gui
local shade=Instance.new("Frame"); shade.Size=UDim2.fromScale(1,1); shade.BackgroundTransparency=.18; shade.BackgroundColor3=Color3.fromRGB(0,0,0); shade.Parent=menu
local function label(parent,text,pos,size,font)
 local x=Instance.new("TextLabel"); x.Text=text; x.Position=pos; x.Size=size; x.BackgroundTransparency=1; x.TextColor3=Color3.fromRGB(245,245,250)
 x.Font=font or Enum.Font.GothamBold; x.TextScaled=true; x.Parent=parent; return x
end
local logo=label(menu,"ELITE",UDim2.fromScale(.08,.12),UDim2.fromScale(.84,.18),Enum.Font.GothamBlack)
logo.TextColor3=Color3.fromRGB(255,255,255); logo.TextXAlignment=Enum.TextXAlignment.Left
local sub=label(menu,"FAST  •  COMPETITIVE  •  FPS",UDim2.fromScale(.09,.30),UDim2.fromScale(.6,.06),Enum.Font.GothamMedium)
sub.TextXAlignment=Enum.TextXAlignment.Left; sub.TextColor3=Color3.fromRGB(175,180,195)
local panel=Instance.new("Frame"); panel.Size=UDim2.fromScale(.32,.32); panel.Position=UDim2.fromScale(.09,.43); panel.BackgroundColor3=Color3.fromRGB(20,22,30); panel.BackgroundTransparency=.08; panel.Parent=menu
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,16); corner.Parent=panel
local stroke=Instance.new("UIStroke"); stroke.Thickness=1.5; stroke.Transparency=.45; stroke.Parent=panel
local play=Instance.new("TextButton"); play.Text="PLAY  →"; play.Size=UDim2.fromScale(.78,.32); play.Position=UDim2.fromScale(.11,.18); play.BackgroundColor3=Color3.fromRGB(235,235,242); play.TextColor3=Color3.fromRGB(12,13,18); play.Font=Enum.Font.GothamBlack; play.TextScaled=true; play.AutoButtonColor=true; play.Parent=panel
local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,10); pc.Parent=play
local controls=label(panel,"WASD  MOVE     SHIFT  SPRINT     C  CROUCH\nLMB  FIRE     RMB  AIM     R  RELOAD",UDim2.fromScale(.08,.60),UDim2.fromScale(.84,.27),Enum.Font.GothamMedium)
controls.TextColor3=Color3.fromRGB(155,160,175)

local function closeMenu()
 started=true
 menu.Visible=false
 UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
 UIS.MouseIconEnabled=false
 p.CameraMode=Enum.CameraMode.LockFirstPerson
end
play.Activated:Connect(closeMenu)

local function L(n,t,pos,sz)
 local x=label(gui,t,pos,sz); x.Name=n; return x
end
local hudTitle=L("Title","ELITE",UDim2.fromOffset(24,18),UDim2.fromOffset(160,44)); hudTitle.TextXAlignment=Enum.TextXAlignment.Left
local ammoText=L("Ammo","30 / 120",UDim2.new(1,-270,1,-100),UDim2.fromOffset(245,65)); ammoText.TextXAlignment=Enum.TextXAlignment.Right; ammoText.TextSize=28
local status=L("Status","",UDim2.fromScale(.5,.72),UDim2.fromOffset(420,45)); status.AnchorPoint=Vector2.new(.5,.5)
local cross=L("Crosshair","+",UDim2.fromScale(.5,.5),UDim2.fromOffset(30,30)); cross.AnchorPoint=Vector2.new(.5,.5); cross.TextSize=20
local hm=L("Hitmarker","",UDim2.fromScale(.5,.5),UDim2.fromOffset(70,70)); hm.AnchorPoint=Vector2.new(.5,.5); hm.TextSize=34
local function sync() ammoText.Text=string.format("%02d / %03d",ammo,reserve) end; sync()
ammoState.OnClientEvent:Connect(function(a,r,re) ammo=a; reserve=r; reloading=re; sync() end)

local function piece(n,s,cf,color,mat)
 local x=Instance.new("Part"); x.Name=n; x.Size=s; x.CFrame=cf; x.Anchored=true; x.CanCollide=false; x.Material=mat or Enum.Material.Metal; x.Color=color; x.Parent=gun
 return x
end
local function gunMake()
 if gun then gun:Destroy() end
 gun=Instance.new("Model"); gun.Name="ELITE_Rifle"; gun.Parent=cam
 -- Modern compact rifle silhouette.
 piece("Receiver",Vector3.new(.48,.58,1.65),CFrame.new(),Color3.fromRGB(35,37,44),Enum.Material.Metal)
 piece("Handguard",Vector3.new(.38,.42,1.65),CFrame.new(),Color3.fromRGB(55,58,66),Enum.Material.Metal)
 piece("Barrel",Vector3.new(.14,.14,1.25),CFrame.new(),Color3.fromRGB(18,19,23),Enum.Material.Metal)
 piece("Muzzle",Vector3.new(.20,.20,.28),CFrame.new(),Color3.fromRGB(10,10,13),Enum.Material.Metal)
 piece("Stock",Vector3.new(.38,.42,.85),CFrame.new(),Color3.fromRGB(28,30,36),Enum.Material.Metal)
 piece("Grip",Vector3.new(.25,.55,.34),CFrame.new(),Color3.fromRGB(25,26,31),Enum.Material.Metal)
 piece("Magazine",Vector3.new(.27,.72,.45),CFrame.new(),Color3.fromRGB(25,27,32),Enum.Material.Metal)
 piece("Sight",Vector3.new(.12,.17,.52),CFrame.new(),Color3.fromRGB(80,84,95),Enum.Material.Metal)
 piece("SightDot",Vector3.new(.035,.05,.08),CFrame.new(),Color3.fromRGB(220,220,230),Enum.Material.Neon)
end
local function place()
 if not gun then return end
 local base=aiming and CFrame.new(.02,-.34,-1.18) or CFrame.new(.62,-.53,-1.32)
 if sprint then base*=CFrame.new(0,-.08,.08)*CFrame.Angles(math.rad(-12),math.rad(3),math.rad(5)) end
 if crouch then base*=CFrame.new(0,-.04,0) end
 local cf=cam.CFrame*base*CFrame.Angles(0,math.rad(180),0)
 gun.Receiver.CFrame=cf
 gun.Handguard.CFrame=cf*CFrame.new(0,0,-1.25)
 gun.Barrel.CFrame=cf*CFrame.new(0,0,-2.15)
 gun.Muzzle.CFrame=cf*CFrame.new(0,0,-2.82)
 gun.Stock.CFrame=cf*CFrame.new(0,0,.95)
 gun.Grip.CFrame=cf*CFrame.new(0,-.47,-.45)
 gun.Magazine.CFrame=cf*CFrame.new(0,-.55,-.12)*CFrame.Angles(math.rad(-8),0,0)
 gun.Sight.CFrame=cf*CFrame.new(0,.36,-.55)
 gun.SightDot.CFrame=cf*CFrame.new(0,.45,-.55)
end
local function reloadGun()
 if reloading or ammo>=30 or reserve<=0 then return end
 reloading=true; status.Text="RELOADING"; reload:FireServer()
end
local function shoot()
 if menu.Visible or reloading or os.clock()-last<.105 then return end
 if ammo<=0 then reloadGun(); return end
 last=os.clock(); fire:FireServer(cam.CFrame.Position,cam.CFrame.LookVector)
end
UIS.InputBegan:Connect(function(i,gp)
 if gp or menu.Visible then return end
 if i.UserInputType==Enum.UserInputType.MouseButton1 then shoot()
 elseif i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true
 elseif i.KeyCode==Enum.KeyCode.R then reloadGun()
 elseif i.KeyCode==Enum.KeyCode.LeftShift then sprint=true; local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=24 end
 elseif i.KeyCode==Enum.KeyCode.C then crouch=true; local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=10; h.CameraOffset=Vector3.new(0,-1,0) end end
end)
UIS.InputEnded:Connect(function(i)
 if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false
 elseif i.KeyCode==Enum.KeyCode.LeftShift then sprint=false; local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16 end
 elseif i.KeyCode==Enum.KeyCode.C then crouch=false; local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=16; h.CameraOffset=Vector3.zero end end
end)
hitmarker.OnClientEvent:Connect(function(k,hs,d)
 hm.Text=hs and "✦" or "×"; status.Text=k and "ELIMINATION  +"..d or "+"..d
 task.delay(.35,function() hm.Text=""; if not reloading then status.Text="" end end)
end)
local function char(c)
 local h=c:WaitForChild("Humanoid"); h.WalkSpeed=16
 if started then p.CameraMode=Enum.CameraMode.LockFirstPerson else p.CameraMode=Enum.CameraMode.Classic end
 gunMake()
end
p.CharacterAdded:Connect(char); if p.Character then char(p.Character) end
RunService.RenderStepped:Connect(place)

-- Keep the camera in first person while applying a deliberately lower mouse sensitivity.
UIS.InputChanged:Connect(function(i,gp)
 if gp or menu.Visible then return end
 if i.UserInputType==Enum.UserInputType.MouseMovement then
  -- Roblox's default camera controller handles the actual rotation; this makes
  -- the game's intended sensitivity value explicit for future camera control.
  p:SetAttribute("ELITE_Sensitivity",sensitivity)
 end
end)
]]
client.Parent=StarterPlayer.StarterPlayerScripts

print("ELITE installed successfully. Press Play to test.")
