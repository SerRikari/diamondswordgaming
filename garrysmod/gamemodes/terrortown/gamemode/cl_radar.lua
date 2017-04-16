local render = render
local surface = surface
local string = string
local player = player
local math = math

local amount = 20

local panel = {
   ["main_dark"] = midnight_ui.panel.main_dark,
   ["main_light"] = midnight_ui.panel.main_light,
   ["main_lighter"] = midnight_ui.panel.main_lighter,
   ["top_dark"] = midnight_ui.panel.top_dark,
   ["top_light"] = midnight_ui.panel.top_light,
   ["top_lighter"] = midnight_ui.panel.top_lighter,
   ["border"] = midnight_ui.panel.border
}

local function BorderedRect(x, y, w, h, main, border, bt, br, bb, bl, centered, shaded)
   if (centered) then offset = (w/2) bx = -1 else offset = 0 bx = (w-1) end
 
   amount = 20
 
   surface.SetDrawColor(main)
   surface.DrawRect(x-offset, y, w, h)
   
   if (main.r <= 100) or (main.g <= 100) or (main.b <= 100) then
      amount = 6
   end
   
   if (shaded) then
      surface.SetDrawColor(Color(main.r+amount, main.g+amount, main.b+amount, main.a))
      surface.DrawRect(x-offset, y, w, 1)
   end
   
   if (bt) or (br) or (bb) or (bl) then surface.SetDrawColor(border) end
   if (bt) then surface.DrawRect(x-offset, y-1, w, 1) end
   if (br) then surface.DrawRect(x+offset+bx+1, y-1, 1, h+3) end
   if (bb) then surface.DrawRect(x-offset, y+h, w, 2) end
   if (bl) then surface.DrawRect(x-offset-1, y-1, 1, h+3) end
end

RADAR = {}
RADAR.targets = {}
RADAR.enable = false
RADAR.duration = 30
RADAR.endtime = 0
RADAR.bombs = {}
RADAR.bombs_count = 0
RADAR.repeating = true
RADAR.samples = {}
RADAR.samples_count = 0

RADAR.called_corpses = {}

function RADAR:EndScan()
   self.enable = false
   self.endtime = CurTime()
end

function RADAR:Clear()
   self:EndScan()
   self.bombs = {}
   self.samples = {}

   self.bombs_count = 0
   self.samples_count = 0
end

function RADAR:Timeout()
   self:EndScan()

   if self.repeating and LocalPlayer() and (LocalPlayer():IsActiveTraitor() or LocalPlayer():IsActiveDetective()) then
      RunConsoleCommand("ttt_radar_scan")
   end
end

function RADAR.CacheEnts()
   for k, corpse in pairs(RADAR.called_corpses) do
      if (corpse.called + 45) < CurTime() then
         RADAR.called_corpses[k] = nil
      end
   end

   if RADAR.bombs_count == 0 then return end

   for idx, b in pairs(RADAR.bombs) do
      local ent = Entity(idx)
      if IsValid(ent) then
         b.pos = ent:GetPos()
      end
   end
end

function RADAR.Bought(is_item, id)
   if is_item and id == EQUIP_RADAR then
      RunConsoleCommand("ttt_radar_scan")
   end
end
hook.Add("TTTBoughtItem", "RadarBoughtItem", RADAR.Bought)

local function DrawTarget(tgt, size, offset, no_shrink)
   local scrpos = tgt.pos:ToScreen()
   local sz = (IsOffScreen(scrpos) and (not no_shrink)) and size/2 or size

   scrpos.x = math.Clamp(scrpos.x, sz, ScrW() - sz)
   scrpos.y = math.Clamp(scrpos.y, sz, ScrH() - sz)

   surface.DrawTexturedRect(scrpos.x - sz, scrpos.y - sz, sz * 2, sz * 2)

   if sz == size then
      local text = math.ceil(LocalPlayer():GetPos():Distance(tgt.pos))
      local w, h = surface.GetTextSize(text)

      surface.SetTextPos(scrpos.x - w/2, scrpos.y + (offset * sz) - h/2)
      surface.DrawText(text)

      if tgt.t then
         text = util.SimpleTime(tgt.t - CurTime(), "%02i:%02i")
         w, h = surface.GetTextSize(text)

         surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
         surface.DrawText(text)
      elseif tgt.nick then
         text = tgt.nick
         w, h = surface.GetTextSize(text)

         surface.SetTextPos(scrpos.x - w / 2, scrpos.y + sz / 2)
         surface.DrawText(text)
      end
   end
end

local indicator   = surface.GetTextureID("effects/select_ring")
local c4warn      = surface.GetTextureID("vgui/ttt/icon_c4warn")
local sample_scan = surface.GetTextureID("vgui/ttt/sample_scan")
local det_beacon  = surface.GetTextureID("vgui/ttt/det_beacon")

local GetPTranslation = LANG.GetParamTranslation
local FormatTime = util.SimpleTime

local near_cursor_dist = 180

function RADAR:Draw(client)
   if not client then return end

   surface.SetFont("HudSelectionText")

   if self.bombs_count != 0 and client:IsActiveTraitor() then
      surface.SetTexture(c4warn)
      surface.SetTextColor(200, 55, 55, 220)
      surface.SetDrawColor(255, 255, 255, 200)

      for k, bomb in pairs(self.bombs) do
         DrawTarget(bomb, 24, 0, true)
      end
   end
   
   if client:IsActiveDetective() and #self.called_corpses then
      surface.SetTexture(det_beacon)
      surface.SetTextColor(255, 255, 255, 240)
      surface.SetDrawColor(255, 255, 255, 230)

      for k, corpse in pairs(self.called_corpses) do
         DrawTarget(corpse, 16, 0.5)
      end
   end

   if self.samples_count != 0 then
      surface.SetTexture(sample_scan)
      surface.SetTextColor(200, 50, 50, 255)
      surface.SetDrawColor(255, 255, 255, 240)

      for k, sample in pairs(self.samples) do
         DrawTarget(sample, 16, 0.5, true)
      end
   end
   
   if (not self.enable) or (not client:IsActiveSpecial()) then return end

   surface.SetTexture(indicator)

   local remaining = math.max(0, RADAR.endtime - CurTime())
   local alpha_base = 50 + 180 * (remaining / RADAR.duration)
   local mpos = Vector(ScrW() / 2, ScrH() / 2, 0)
   local role, alpha, scrpos, md
   local radar_text_colour
   
   for k, tgt in pairs(RADAR.targets) do
      alpha = alpha_base

      scrpos = tgt.pos:ToScreen()
      md = mpos:Distance(Vector(scrpos.x, scrpos.y, 0))
      if md < near_cursor_dist then
         alpha = math.Clamp(alpha * (md / near_cursor_dist), 40, 230)
      end

      role = tgt.role or ROLE_INNOCENT
      if role == ROLE_TRAITOR then
         surface.SetDrawColor(205, 60, 40, alpha)
         surface.SetTextColor(205, 60, 40, alpha)
      elseif role == ROLE_DETECTIVE then
         surface.SetDrawColor(66, 100, 200, alpha)
         surface.SetTextColor(66, 100, 200, alpha)
      elseif role == -1 then
         surface.SetDrawColor(101, 111, 123, alpha)
         surface.SetTextColor(101, 111, 123, alpha)
      else
         surface.SetDrawColor(170, 225, 100, alpha)
         surface.SetTextColor(170, 225, 100, alpha)
      end

      DrawTarget(tgt, 24, 0)
   end
   
   if LocalPlayer():IsTraitor() then
      radar_text_colour = midnight_ui.role_light.traitor
   elseif LocalPlayer():IsDetective() then
      radar_text_colour = midnight_ui.role_light.detective
   else 
      radar_text_colour = midnight_ui.role_light.innocent
   end

   surface.SetFont("TabLarge")
   surface.SetTextColor(radar_text_colour)

   local text = GetPTranslation("radar_hud", {time = FormatTime(remaining, "%02i:%02i")})
   local w, h = surface.GetTextSize(text)

   surface.SetTextPos(13, ScrH() - 140 - h)
   surface.DrawText(text)
end

local function ReceiveC4Warn()
   local idx = net.ReadUInt(16)
   local armed = net.ReadBit() == 1

   if armed then
      local pos = net.ReadVector()
      local etime = net.ReadFloat()

      RADAR.bombs[idx] = {pos=pos, t=etime}
   else
      RADAR.bombs[idx] = nil
   end

   RADAR.bombs_count = table.Count(RADAR.bombs)
end
net.Receive("TTT_C4Warn", ReceiveC4Warn)

local function ReceiveCorpseCall()
   local pos = net.ReadVector()
   table.insert(RADAR.called_corpses, {pos = pos, called = CurTime()})
end
net.Receive("TTT_CorpseCall", ReceiveCorpseCall)

local function ReceiveRadarScan()
   local num_targets = net.ReadUInt(8)

   RADAR.targets = {}
   for i=1, num_targets do
      local r = net.ReadUInt(2)

      local pos = Vector()
      pos.x = net.ReadInt(32)
      pos.y = net.ReadInt(32)
      pos.z = net.ReadInt(32)

      table.insert(RADAR.targets, {role=r, pos=pos})
   end

   RADAR.enable = true
   RADAR.endtime = CurTime() + RADAR.duration

   timer.Create("radartimeout", RADAR.duration + 1, 1, function() RADAR:Timeout() end)
end
net.Receive("TTT_Radar", ReceiveRadarScan)

local GetTranslation = LANG.GetTranslation
function RADAR.CreateMenu(parent, frame)
   local w, h = parent:GetSize()

   local dform = vgui.Create("DForm", parent)
   dform:SetName(GetTranslation("radar_menutitle"))
   dform:StretchToParent(0, 0, 0, 0)
   dform:SetAutoSize(false)

   local owned = LocalPlayer():HasEquipmentItem(EQUIP_RADAR)

   if not owned then
      dform:Help(GetTranslation("radar_not_owned"))
      return dform
   end

   local bw, bh = 100, 40
   local dscan = vgui.Create("DButton", dform)
   dscan:SetSize(bw, bh)
   dscan:SetFont("midnight_font_13")
   dscan:SetText(GetTranslation("radar_scan"))
   dscan:SetTextColor(midnight_ui.text_colour.white)
   dscan.Hover = 0
   dscan.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp( self.Hover - FrameTime() * 3, 0, 1 )
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp( self.Hover + FrameTime() * 3, 0, 1 )
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   
   
   dscan.DoClick = function(s)
      s:SetDisabled(true)
      RunConsoleCommand("ttt_radar_scan")
      frame:Close()
   end
   dform:AddItem(dscan)
   
   dscan.DoClick = function(s)
      s:SetDisabled(true)
      RunConsoleCommand("ttt_radar_scan")
      frame:Close()
   end
   dform:AddItem(dscan)

   local dlabel = vgui.Create("DLabel", dform)
   dlabel:SetText(GetPTranslation("radar_help", {num = RADAR.duration}))
   dlabel:SetWrap(true)
   dlabel:SetTall(50)
   dform:AddItem(dlabel)

   local dcheck = vgui.Create("DCheckBoxLabel", dform)
   dcheck:SetText(GetTranslation("radar_auto"))
   dcheck:SetIndent(5)
   dcheck:SetValue(RADAR.repeating)
   dcheck.OnChange = function(s, val)
      RADAR.repeating = val
   end
   dform:AddItem(dcheck)

   dform.Think = function(s)
   if RADAR.enable or not owned then
         dscan:SetDisabled(true)
      else
         dscan:SetDisabled(false)
      end
   end

   dform:SetVisible(true)

   return dform
end

