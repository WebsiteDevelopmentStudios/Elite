-- ELITE INSTALLER
-- Paste this entire script into Roblox Studio's Command Bar and press Enter.
-- It creates the complete playable ELITE prototype in the current place.

local ServerScriptService=game:GetService("ServerScriptService")
local StarterPlayer=game:GetService("StarterPlayer")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")

local function wipe(name,parent)
 local x=parent:FindFirstChild(name); if x then x:Destroy() end
end
wipe("ELITE_Arena",Workspace)
wipe("ELITE_Remotes",ReplicatedStorage)
wipe("ELITE_Server",ServerScriptService)
wipe("ELITE_Client",StarterPlayer.StarterPlayerScripts)

local rem=Instance.new("Folder"); rem.Name="ELITE_Remotes"; rem.Parent=ReplicatedStorage
for _,n in ipairs({"Fire","Reload","Hitmarker","AmmoState"}) do local e=Instance.new("RemoteEvent"); e.Name=n; e.Parent=rem end

local red=Teams:FindFirstChild("ELITE RED") or Instance.new("Team"); red.Name="ELITE RED"; red.TeamColor=BrickColor.new("Really red"); red.AutoAssignable=false; red.Parent=Teams
local blue=Teams:FindFirstChild("ELITE BLUE") or Instance.new("Team"); blue.Name="ELITE BLUE"; blue.TeamColor=BrickColor.new("Really blue"); blue.AutoAssignable=false; blue.Parent=Teams

local map=Instance.new("Folder"); map.Name="ELITE_Arena"; map.Parent=Workspace
local function part(n,s,p,c,m)
 local x=Instance.new("Part"); x.Name=n; x.Size=s; x.Position=p; x.Anchored=true; x.CanCollide=c~=false; x.Material=m or Enum.Material.Concrete; x.Parent=map; return x
end
part("Floor",Vector3.new(240,2,180),Vector3.new(0,-1,0))
part("NorthWall",Vector3.new(240,24,4),Vector3.new(0,11,-90),true,Enum.Material.Brick)
part("SouthWall",Vector3.new(240,24,4),Vector3.new(0,11,90),true,Enum.Material.Brick)
part("WestWall",Vector3.new(4,24,180),Vector3.new(-120,11,0),true,Enum.Material.Brick)
part("EastWall",Vector3.new(4,24,180),Vector3.new(120,11,0),true,Enum.Material.Brick)
for i,x in ipairs({-70,-35,0,35,70}) do part("CenterCover"..i,Vector3.new(12,8,28),Vector3.new(x,4,0),true,Enum.Material.Metal) end
part("CenterBlock",Vector3.new(26,10,18),Vector3.new(0,5,0),true,Enum.Material.Metal)
part("RedBase",Vector3.new(30,8,32),Vector3.new(-92,4,0),true,Enum.Material.Metal)
part("BlueBase",Vector3.new(30,8,32),Vector3.new(92,4,0),true,Enum.Material.Metal)
for _,v in ipairs({{-65,3,-45},{-65,3,45},{65,3,-45},{65,3,45},{-20,2.5,-35},{20,2.5,35}}) do part("Cover",Vector3.new(18,6,14),Vector3.new(v[1],v[2],v[3]),true,Enum.Material.Metal) end

local function spawn(n,p,t)
 local s=Instance.new("SpawnLocation"); s.Name=n; s.Size=Vector3.new(8,1,8); s.Position=p; s.Anchored=true; s.Neutral=false; s.TeamColor=t.TeamColor; s.Parent=map
end
spawn("RedSpawn",Vector3.new(-105,1,0),red); spawn("BlueSpawn",Vector3.new(105,1,0),blue)

local server=Instance.new("Script"); server.Name="ELITE_Server"; server.Source=[[
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Debris=game:GetService("Debris")
local rem=ReplicatedStorage:WaitForChild("ELITE_Remotes")
local fire,reload,hitmarker,ammoState=rem.Fire,rem.Reload,rem.Hitmarker,rem.AmmoState
local CFG={Damage=24,HeadshotMultiplier=1.6,Range=700,FireRate=.105,Magazine=30,Reserve=120,ReloadTime=1.65,WalkSpeed=16,SprintSpeed=24}
local state={}
local red,blue=Teams:WaitForChild("ELITE RED"),Teams:WaitForChild("ELITE BLUE")
local function sync(p) local s=state[p]; if s then ammoState:FireClient(p,s.ammo,s.reserve,s.reloading) end end
local function team(p) local r,b=0,0; for _,x in ipairs(Players:GetPlayers()) do if x.Team==red then r+=1 elseif x.Team==blue then b+=1 end end; p.Team=(r<=b) and red or blue end
Players.PlayerAdded:Connect(function(p)
 team(p); state[p]={ammo=30,reserve=120,last=0,reloading=false}
 local ls=Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=p
 for _,n in ipairs({"KILLS","DEATHS","SCORE"}) do local v=Instance.new("IntValue"); v.Name=n; v.Parent=ls end
 p.CharacterAdded:Connect(function(c) local h=c:WaitForChild("Humanoid"); h.WalkSpeed=16; task.wait(.2); sync(p); h.Died:Connect(function() ls.DEATHS.Value+=1 end) end)
end)
Players.PlayerRemoving:Connect(function(p) state[p]=nil end)
reload.OnServerEvent:Connect(function(p)
 local s=state[p]; if not s or s.reloading or s.ammo>=30 or s.reserve<=0 then sync(p); return end
 s.reloading=true; sync(p)
 task.delay(1.65,function() if not state[p] then return end; local take=math.min(30-s.ammo,s.reserve); s.ammo+=take; s.reserve-=take; s.reloading=false; sync(p) end)
end)
fire.OnServerEvent:Connect(function(p,origin,direction)
 local s=state[p]; if not s or s.reloading or typeof(origin)~="Vector3" or typeof(direction)~="Vector3" then return end
 if os.clock()-s.last<.084 or s.ammo<=0 then sync(p); return end
 local c=p.Character; local head=c and c:FindFirstChild("Head"); if not head then return end
 if (origin-head.Position).Magnitude>8 then origin=head.Position end
 s.last=os.clock(); s.ammo-=1; sync(p)
 local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={c}
 local dir=direction.Unit; local hit=Workspace:Raycast(origin,dir*CFG.Range,rp); local hp=hit and hit.Position or origin+dir*CFG.Range
 local tr=Instance.new("Part"); tr.Name="ELITE_Tracer"; tr.Anchored=true; tr.CanCollide=false; tr.CanQuery=false; tr.CanTouch=false; tr.Material=Enum.Material.Neon; tr.Size=Vector3.new(.1,.1,(hp-origin).Magnitude); tr.CFrame=CFrame.lookAt((origin+hp)/2,hp); tr.Parent=Workspace; Debris:AddItem(tr,.05)
 if hit then
  local model=hit.Instance:FindFirstAncestorOfClass("Model"); local h=model and model:FindFirstChildOfClass("Humanoid"); local target=model and Players:GetPlayerFromCharacter(model)
  if h and target and target~=p and target.Team~=p.Team and h.Health>0 then
   local hs=hit.Instance.Name=="Head"; local dmg=hs and CFG.Damage*CFG.HeadshotMultiplier or CFG.Damage; local before=h.Health; h:TakeDamage(dmg); local kill=before>0 and h.Health<=0
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
local p=Players.LocalPlayer; local cam=workspace.CurrentCamera; local rem=RS:WaitForChild("ELITE_Remotes")
local fire,reload,hitmarker,ammoState=rem.Fire,rem.Reload,rem.Hitmarker,rem.AmmoState
local ammo,reserve=30,120; local reloading=false; local aiming=false; local sprint=false; local last=0; local gun
local gui=Instance.new("ScreenGui"); gui.Name="ELITE_HUD"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.Parent=p:WaitForChild("PlayerGui")
local function L(n,t,pos,sz) local x=Instance.new("TextLabel"); x.Name=n;x.Text=t;x.Position=pos;x.Size=sz;x.BackgroundTransparency=1;x.TextColor3=Color3.new(1,1,1);x.Font=Enum.Font.GothamBold;x.TextScaled=true;x.Parent=gui;return x end
local title=L("Title","ELITE",UDim2.fromOffset(24,18),UDim2.fromOffset(180,50));title.TextXAlignment=Enum.TextXAlignment.Left
local ammoText=L("Ammo","30 / 120",UDim2.new(1,-260,1,-100),UDim2.fromOffset(230,65));ammoText.TextXAlignment=Enum.TextXAlignment.Right
local status=L("Status","",UDim2.fromScale(.5,.72),UDim2.fromOffset(400,45));status.AnchorPoint=Vector2.new(.5,.5)
local cross=L("Crosshair","+",UDim2.fromScale(.5,.5),UDim2.fromOffset(30,30));cross.AnchorPoint=Vector2.new(.5,.5)
local hm=L("Hitmarker","",UDim2.fromScale(.5,.5),UDim2.fromOffset(70,70));hm.AnchorPoint=Vector2.new(.5,.5);hm.TextSize=34
local function sync() ammoText.Text=string.format("%02d / %03d",ammo,reserve) end;sync()
ammoState.OnClientEvent:Connect(function(a,r,re) ammo=a;reserve=r;reloading=re;sync() end)
local function gunMake()
 if gun then gun:Destroy() end;gun=Instance.new("Model");gun.Name="ELITE_Rifle"
 local function piece(n,s) local x=Instance.new("Part");x.Name=n;x.Size=s;x.Anchored=true;x.CanCollide=false;x.Material=Enum.Material.Metal;x.Parent=gun;return x end
 piece("Body",Vector3.new(.42,.5,2));piece("Barrel",Vector3.new(.16,.16,1.4));piece("Sight",Vector3.new(.12,.18,.45));gun.Parent=cam
end
local function place()
 if not gun then return end
 local base=aiming and CFrame.new(0,-.4,-1.05) or CFrame.new(.65,-.55,-1.35)
 if sprint then base*=CFrame.new(0,-.1,0)*CFrame.Angles(math.rad(-8),0,0) end
 local cf=cam.CFrame*base*CFrame.Angles(0,math.rad(180),0)
 gun.Body.CFrame=cf;gun.Barrel.CFrame=cf*CFrame.new(0,0,-1.65);gun.Sight.CFrame=cf*CFrame.new(0,.31,-.35)
end
local function reloadGun() if reloading or ammo>=30 or reserve<=0 then return end; reloading=true;status.Text="RELOADING";reload:FireServer() end
local function shoot() if reloading or os.clock()-last<.105 then return end;if ammo<=0 then reloadGun();return end;last=os.clock();fire:FireServer(cam.CFrame.Position,cam.CFrame.LookVector) end
UIS.InputBegan:Connect(function(i,gp) if gp then return end
 if i.UserInputType==Enum.UserInputType.MouseButton1 then shoot()
 elseif i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true
 elseif i.KeyCode==Enum.KeyCode.R then reloadGun()
 elseif i.KeyCode==Enum.KeyCode.LeftShift then sprint=true;local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h then h.WalkSpeed=24 end
 elseif i.KeyCode==Enum.KeyCode.C then local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h then h.WalkSpeed=10;h.CameraOffset=Vector3.new(0,-1,0) end end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false elseif i.KeyCode==Enum.KeyCode.LeftShift then sprint=false;local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h then h.WalkSpeed=16 end elseif i.KeyCode==Enum.KeyCode.C then local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h then h.WalkSpeed=16;h.CameraOffset=Vector3.zero end end end)
hitmarker.OnClientEvent:Connect(function(k,hs,d) hm.Text=hs and "✦" or "×";status.Text=k and "ELIMINATION +"..d or "+"..d;task.delay(.35,function()hm.Text="";if not reloading then status.Text="" end end) end)
local function char(c) local h=c:WaitForChild("Humanoid");h.WalkSpeed=16;p.CameraMode=Enum.CameraMode.LockFirstPerson;gunMake() end
p.CharacterAdded:Connect(char);if p.Character then char(p.Character) end;RunService.RenderStepped:Connect(place)
]]
client.Parent=StarterPlayer.StarterPlayerScripts

print("ELITE installed successfully. Press Play to test.")
