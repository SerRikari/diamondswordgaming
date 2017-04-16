AddCSLuaFile()

SWEP.Kind = WEAPON_NONE
SWEP.CanBuy = nil

if CLIENT then
   SWEP.EquipMenuData = nil
   SWEP.Icon = "vgui/ttt/icon_nades"
end

SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.IsSilent = false

if CLIENT then
   SWEP.DrawCrosshair = false
   SWEP.ViewModelFOV = 82
   SWEP.ViewModelFlip = true
   SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_base"

SWEP.Category = "TTT"
SWEP.Spawnable = false
SWEP.IsGrenade = false
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.Sound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Damage = 1
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.02
SWEP.Primary.Delay = 0.15
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipMax = -1
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipMax = -1
SWEP.HeadshotMultiplier = 2.7
SWEP.StoredAmmo = 0
SWEP.IsDropped = false
SWEP.DeploySpeed = 1.4
SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD
SWEP.fingerprints = {}

local surface = surface
local sparkle = CLIENT and CreateConVar("ttt_crazy_sparks", "0", FCVAR_ARCHIVE)
local shadow = Color(0, 0, 0, 185)

local role_light = {
   ["innocent"] = midnight_hud.role_light.innocent,
   ["traitor"] = midnight_hud.role_light.traitor,
   ["detective"] = midnight_hud.role_light.detective
}

local function DrawShadow(x, y, width, length)
   surface.SetDrawColor(shadow)
   surface.DrawRect(x-1, y-1, width+2, length+2) 
end

local function BorderedLine(x, y, width, length, gap, colour, direction)
   if (direction == 1) then 
      DrawShadow(x, y-length-gap, width, length) 
      surface.SetDrawColor(colour)
      surface.DrawRect(x, y-length-gap, width, length) 
   end
   
   if (direction == 2) then 
      DrawShadow(x+1+gap, y, length, width) 
      surface.SetDrawColor(colour)
      surface.DrawRect(x+1+gap, y, length, width) 
   end
   
   if (direction == 3) then 
      DrawShadow(x, y+1+gap, width, length) 
      surface.SetDrawColor(colour)
      surface.DrawRect(x, y+1+gap, width, length) 
   end
   
   if (direction == 4) then 
      DrawShadow(x-length-gap, y, length, width) 
      surface.SetDrawColor(colour)
      surface.DrawRect(x-length-gap, y, length, width) 
   end
end

if CLIENT then
   local sights_opacity = CreateConVar("ttt_ironsights_crosshair_opacity", "0.8", FCVAR_ARCHIVE)
   local crosshair_brightness = CreateConVar("ttt_crosshair_brightness", "1.0", FCVAR_ARCHIVE)
   local crosshair_size = CreateConVar("ttt_crosshair_size", "1.0", FCVAR_ARCHIVE)
   local disable_crosshair = CreateConVar("ttt_disable_crosshair", "0", FCVAR_ARCHIVE)
   local x, y = ScrW(), ScrH()

   function SWEP:DrawHUD()
      local client = LocalPlayer()
      if disable_crosshair:GetBool() or (not IsValid(client)) then return end

      local sights = (not self.NoSights) and self:GetIronsights()
      local scale = math.max(0.2, 2*self:GetPrimaryCone())
      local LastShootTime = self:LastShootTime()
      local alpha = sights and sights_opacity:GetFloat() or 1
      local bright = crosshair_brightness:GetFloat() or 1
      local colour
      
      scale = scale*(2-math.Clamp((CurTime()-LastShootTime)*5, 0.0, 1.0))

      local gap = 30*scale*(sights and 0.8 or 1)
      local length = gap+(15*crosshair_size:GetFloat())*scale
      
      if GetRoundState() == ROUND_PREP then
         colour = role_light.prep
      elseif client.IsTraitor and client:IsTraitor() then
         colour =  role_light.traitor
      elseif client.IsDetective and client:IsDetective() then
         colour = role_light.detective
      else
         colour = role_light.innocent
      end

      colour = Color(255*bright, 255*bright, 255*bright, 255*alpha)
      
      BorderedLine(x/2, y/2, 1, length, gap, colour, 1)
      BorderedLine(x/2, y/2, 1, length, gap, colour, 2)
      BorderedLine(x/2, y/2, 1, length, gap, colour, 3)
      BorderedLine(x/2, y/2, 1, length, gap, colour, 4)

      if self.HUDHelp then
         self:DrawHelp()
      end
   end

   local GetTranslation  = LANG.GetTranslation
   local GetPTranslation = LANG.GetParamTranslation
   local help_spec = {text = "", font = "TabLarge", xalign = TEXT_ALIGN_CENTER}
   
   function SWEP:DrawHelp()
      local data = self.HUDHelp

      local translate = data.translatable
      local primary = data.primary
      local secondary = data.secondary

      if translate then
         primary = primary and GetPTranslation(primary, data.translate_params)
         secondary = secondary and GetPTranslation(secondary, data.translate_params)
      end

      help_spec.pos  = {ScrW()/2.0, ScrH()-40}
      help_spec.text = secondary or primary
      draw.TextShadow(help_spec, 2)

      if secondary then
         help_spec.pos[2] = ScrH()-60
         help_spec.text = primary
         draw.TextShadow(help_spec, 2)
      end
   end

   local default_key_params = {
      primaryfire = Key("+attack", "LEFT MOUSE"),
      secondaryfire = Key("+attack2", "RIGHT MOUSE"),
      usekey = Key("+use", "USE")
   }

   function SWEP:AddHUDHelp(primary_text, secondary_text, translate, extra_params)
      extra_params = extra_params or {}

      self.HUDHelp = {
         primary = primary_text,
         secondary = secondary_text,
         translatable = translate,
         translate_params = table.Merge(extra_params, default_key_params)
      }
   end
end

function SWEP:PrimaryAttack(worldsnd)
   self:SetNextSecondaryFire(CurTime()+self.Primary.Delay)
   self:SetNextPrimaryFire(CurTime()+self.Primary.Delay)

   if not self:CanPrimaryAttack() then return end

   if not worldsnd then
      self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
   elseif SERVER then
      sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
   end

   self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self:GetPrimaryCone())
   self:TakePrimaryAmmo( 1 )

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

   owner:ViewPunch(Angle(math.Rand(-0.2,-0.1)*self.Primary.Recoil, math.Rand(-0.1,0.1)*self.Primary.Recoil, 0))
end

function SWEP:DryFire(setnext)
   if CLIENT and LocalPlayer() == self.Owner then
      self:EmitSound( "Weapon_Pistol.Empty" )
   end

   setnext(self, CurTime()+0.2)

   self:Reload()
end

function SWEP:CanPrimaryAttack()
   if not IsValid(self.Owner) then return end

   if self:Clip1() <= 0 then
      self:DryFire(self.SetNextPrimaryFire)
      return false
   end
   return true
end

function SWEP:CanSecondaryAttack()
   if not IsValid(self.Owner) then return end

   if self:Clip2() <= 0 then
      self:DryFire(self.SetNextSecondaryFire)
      return false
   end
   return true
end

local function Sparklies(attacker, tr, dmginfo)
   if tr.HitWorld and tr.MatType == MAT_METAL then
      local eff = EffectData()
      eff:SetOrigin(tr.HitPos)
      eff:SetNormal(tr.HitNormal)
      util.Effect("cball_bounce", eff)
   end
end

function SWEP:ShootBullet(dmg, recoil, numbul, cone)
   self:SendWeaponAnim(self.PrimaryAnim)

   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not IsFirstTimePredicted() then return end

   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone or 0.01

   local bullet = {}
   bullet.Num = numbul
   bullet.Src = self.Owner:GetShootPos()
   bullet.Dir = self.Owner:GetAimVector()
   bullet.Spread = Vector(cone, cone, 0)
   bullet.Tracer = 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = 10
   bullet.Damage = dmg
   
   if CLIENT and sparkle:GetBool() then
      bullet.Callback = Sparklies
   end

   self.Owner:FireBullets(bullet)

   if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

      recoil = sights and (recoil*0.6) or recoil

      local eyeang = self.Owner:EyeAngles()
      eyeang.pitch = eyeang.pitch-recoil
      self.Owner:SetEyeAngles(eyeang)
   end
end

function SWEP:GetPrimaryCone()
   local cone = self.Primary.Cone or 0.2

   return self:GetIronsights() and (cone*0.85) or cone
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
   return self.HeadshotMultiplier
end

function SWEP:IsEquipment()
   return WEPS.IsEquipment(self)
end

function SWEP:DrawWeaponSelection() end

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) then return end

   self:SetIronsights(not self:GetIronsights())
   self:SetNextSecondaryFire(CurTime()+0.3)
end

function SWEP:Deploy()
   self:SetIronsights(false)
   return true
end

function SWEP:Reload()
	if (self:Clip1() == self.Primary.ClipSize or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0) then return end
   self:DefaultReload(self.ReloadAnim)
   self:SetIronsights(false)
end

function SWEP:OnRestore()
   self.NextSecondaryAttack = 0
   self:SetIronsights(false)
end

function SWEP:Ammo1()
   return IsValid(self.Owner) and self.Owner:GetAmmoCount(self.Primary.Ammo) or false
end

function SWEP:PreDrop()
   if SERVER and IsValid(self.Owner) and self.Primary.Ammo != "none" then
      local ammo = self:Ammo1()

      for _, w in pairs(self.Owner:GetWeapons()) do
         if IsValid(w) and w != self and w:GetPrimaryAmmoType() == self:GetPrimaryAmmoType() then
            ammo = 0
         end
      end

      self.StoredAmmo = ammo

      if ammo > 0 then
         self.Owner:RemoveAmmo(ammo, self.Primary.Ammo)
      end
   end
end

function SWEP:DampenDrop()
   local phys = self:GetPhysicsObject()
   
   if IsValid(phys) then
      phys:SetVelocityInstantaneous(Vector(0, 0, -75)+phys:GetVelocity()*0.001)
      phys:AddAngleVelocity(phys:GetAngleVelocity()*-0.99)
   end
end

local SF_WEAPON_START_CONSTRAINED = 1

function SWEP:Equip(newowner)
   if SERVER then
      if self:IsOnFire() then
         self:Extinguish()
      end

      self.fingerprints = self.fingerprints or {}

      if not table.HasValue(self.fingerprints, newowner) then
         table.insert(self.fingerprints, newowner)
      end

      if self:HasSpawnFlags(SF_WEAPON_START_CONSTRAINED) then
         local flags = self:GetSpawnFlags()
         local newflags = bit.band(flags, bit.bnot(SF_WEAPON_START_CONSTRAINED))
         self:SetKeyValue("spawnflags", newflags)
      end
   end

   if SERVER and IsValid(newowner) and self.StoredAmmo > 0 and self.Primary.Ammo != "none" then
      local ammo = newowner:GetAmmoCount(self.Primary.Ammo)
      local given = math.min(self.StoredAmmo, self.Primary.ClipMax-ammo)

      newowner:GiveAmmo( given, self.Primary.Ammo)
      self.StoredAmmo = 0
   end
end

function SWEP:WasBought(buyer) end
function SWEP:GetIronsights() return false end
function SWEP:SetIronsights() end

function SWEP:SetupDataTables()
   self:NetworkVar("Bool", 3, "Ironsights")
end

function SWEP:Initialize()
   if CLIENT and self:Clip1() == -1 then
      self:SetClip1(self.Primary.DefaultClip)
   elseif SERVER then
      self.fingerprints = {}

      self:SetIronsights(false)
   end

   self:SetDeploySpeed(self.DeploySpeed)

   if self.SetWeaponHoldType then
      self:SetWeaponHoldType(self.HoldType or "pistol")
   end
end

function SWEP:Think() end

function SWEP:DyingShot()
   local fired = false
   if self:GetIronsights() then
      self:SetIronsights(false)

      if self:GetNextPrimaryFire() > CurTime() then
         return fired
      end

      if IsValid(self.Owner) then
         local punch = self.Primary.Recoil or 5
         local eyeang = self.Owner:EyeAngles()
         
         eyeang.pitch = eyeang.pitch - math.Rand(-punch, punch)
         eyeang.yaw = eyeang.yaw - math.Rand(-punch, punch)
         self.Owner:SetEyeAngles(eyeang)

         MsgN(self.Owner:Nick().." fired his DYING SHOT")

         self.Owner.dying_wep = self
         self:PrimaryAttack(true)
         fired = true
      end
   end

   return fired
end

local ttt_lowered = CreateConVar("ttt_ironsights_lowered", "1", FCVAR_ARCHIVE)
local LOWER_POS = Vector(0, 0, -2)
local IRONSIGHT_TIME = 0.25

function SWEP:GetViewModelPosition(pos, ang)
   if not self.IronSightsPos then return pos, ang end

   local bIron = self:GetIronsights()

   if bIron != self.bLastIron then
      self.bLastIron = bIron
      self.fIronTime = CurTime()

      if bIron then
         self.SwayScale = 0.3
         self.BobScale = 0.1
      else
         self.SwayScale = 1.0
         self.BobScale = 1.0
      end
   end

   local fIronTime = self.fIronTime or 0
   if (not bIron) and fIronTime < CurTime()-IRONSIGHT_TIME then
      return pos, ang
   end

   local mul = 1.0

   if fIronTime > CurTime()-IRONSIGHT_TIME then
      mul = math.Clamp((CurTime()-fIronTime)/IRONSIGHT_TIME, 0, 1)

      if not bIron then mul = 1-mul end
   end

   local offset = self.IronSightsPos+(ttt_lowered:GetBool() and LOWER_POS or vector_origin)

   if self.IronSightsAng then
      ang = ang*1
      ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x*mul)
      ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y*mul)
      ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z*mul)
   end

   pos = pos+offset.x*ang:Right()*mul
   pos = pos+offset.y*ang:Forward()*mul
   pos = pos+offset.z*ang:Up()*mul

   return pos, ang
end