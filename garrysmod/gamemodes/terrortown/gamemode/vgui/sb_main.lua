include("sb_team.lua")

surface.CreateFont("midnight_font_22", {font = "Tahoma", weight = 400, size = 22, antialias = true})
surface.CreateFont("midnight_font_14", {font = "Tahoma", weight = 1000, size = 14, antialias = true})
surface.CreateFont("midnight_font_13", {font = "Tahoma", weight = 800, size = 13, antialias = true})
surface.CreateFont("cool_small", {font = "coolvetica", size = 20, weight = 400, antialias = true})
surface.CreateFont("cool_large", {font = "coolvetica", size = 24, weight = 400, antialias = true})
surface.CreateFont("treb_small", {font = "Tahoma", size = 14, weight = 700, antialias = true})

local surface = surface
local draw = draw
local math = math
local string = string
local vgui = vgui

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

local y_logo_off = 72
local x_preview_off = 153
local amount = 20

local PS = midnight_sb.config.pointshop
local PS2 = midnight_sb.config.pointshop2
local titles_enabled = midnight_sb.config.titles_enabled

local logo_default = surface.GetTextureID("vgui/ttt/score_logo")
local logo_path = midnight_sb.config.logo_path
local source = midnight_sb.config.map_source
local map_gametracker = "http://image.www.gametracker.com/images/maps/160x120/garrysmod/"..string.lower(game.GetMap())..".jpg"
local map_webhost = midnight_sb.config.map_url..string.lower(game.GetMap())..".png"
local map_fastdl = Material("midnight-thumbs/"..string.lower(game.GetMap())..".png", "noclamp smooth")

local panel = {
   ["main_dark"] = midnight_sb.panel.main_dark,
   ["main_light"] = midnight_sb.panel.main_light,
   ["main_lighter"] = midnight_sb.panel.main_lighter,
   ["top_dark"] = midnight_sb.panel.top_dark,
   ["top_light"] = midnight_sb.panel.top_light,
   ["border"] = midnight_sb.panel.border,
   ["shade_dark"] = midnight_sb.panel.shade_dark,
   ["shade_light"] = midnight_sb.panel.shade_light,
   ["shade_lighter"] = midnight_sb.panel.shade_lighter
}

local text_colour = {
   ["dark"] = midnight_sb.text_colour.dark
}

local function BorderedRect(x, y, w, h, main, border, bt, br, bb, bl, centered, shaded)
   if (centered) then offset = (w/2) bx = -1 else offset = 0 bx = (w-1) end
 
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

local PANEL = {}
local max = math.max
local floor = math.floor

local function UntilMapChange()
   local rounds_left = max(0, GetGlobalInt("ttt_rounds_left", 6))
   local time_left = floor(max(0, ((GetGlobalInt("ttt_time_limit_minutes") or 60)*60) - CurTime()))

   local h = floor(time_left/3600)
   time_left = time_left - floor(h*3600)
   local m = floor(time_left/60)
   time_left = time_left - floor(m*60)
   local s = floor(time_left)

   return rounds_left, string.format("%02i:%02i:%02i", h, m, s)
end

GROUP_TERROR = 1
GROUP_NOTFOUND = 2
GROUP_FOUND = 3
GROUP_SPEC = 4
GROUP_COUNT = 4

function ScoreGroup(p)
   if not IsValid(p) then return -1 end

   if DetectiveMode() then
      if p:IsSpec() and (not p:Alive()) then
         if p:GetNWBool("body_found", false) then
            return GROUP_FOUND
         else
            local client = LocalPlayer()
            if client:IsSpec() or
               client:IsActiveTraitor() or
               ((GAMEMODE.round_state != ROUND_ACTIVE) and client:IsTerror()) then
               return GROUP_NOTFOUND
            else
               return GROUP_TERROR
            end
         end
      end
   end

   return p:IsTerror() and GROUP_TERROR or GROUP_SPEC
end

function PANEL:Init()
   if (source == "webhost" and midnight_sb.config.map_preview) then
      self.html = vgui.Create("html", self)
      self.html:SetVisible(true)
      self.html:OpenURL(map_webhost)
   end

   self.hostdesc = vgui.Create("DLabel", self)
   self.hostdesc:SetText(GetTranslation("sb_playing"))
   self.hostdesc:SetContentAlignment(9)

   self.hostname = vgui.Create("DLabel", self)
   self.hostname:SetText(GetHostName())
   self.hostname:SetContentAlignment(6)

   self.mapchange = vgui.Create("DLabel", self)
   self.mapchange:SetText("Map changes in 00 rounds or in 00:00:00")
   self.mapchange:SetContentAlignment(9)
   
   self.mapchange.Think = function(sf)
      local r, t = UntilMapChange()

      sf:SetText(GetPTranslation("sb_mapchange", {num = r, time = t}))
      sf:SizeToContents()
   end

   self.ply_frame = vgui.Create("TTTPlayerFrame", self)
   self.ply_groups = {}

   local t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
   t:SetGroupInfo(GetTranslation("terrorists"), Color(0, 200, 0, 100), GROUP_TERROR)
   self.ply_groups[GROUP_TERROR] = t

   t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
   t:SetGroupInfo(GetTranslation("spectators"), Color(200, 200, 0, 100), GROUP_SPEC)
   self.ply_groups[GROUP_SPEC] = t

   if DetectiveMode() then
      t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
      t:SetGroupInfo(GetTranslation("sb_mia"), Color(130, 190, 130, 100), GROUP_NOTFOUND)
      self.ply_groups[GROUP_NOTFOUND] = t

      t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
      t:SetGroupInfo(GetTranslation("sb_confirmed"), Color(130, 170, 10, 100), GROUP_FOUND)
      self.ply_groups[GROUP_FOUND] = t
   end

   self.cols = {}
   self:AddColumn(GetTranslation("sb_ping"))
   self:AddColumn(GetTranslation("sb_deaths"))
   self:AddColumn(GetTranslation("sb_score"))

   if KARMA.IsEnabled() then
      self:AddColumn(GetTranslation("sb_karma"), 60)
   end
   
   if (titles_enabled) then
      self:AddColumn(midnight_sb.config.title_text, function(ply) end, 80)
   end
   
   if (PS) or (PS2) then
      self:AddColumn(midnight_sb.config.points_text, function(ply) end, 80)
   end

   hook.Call("TTTScoreboardColumns", nil, self)

   self:UpdateScoreboard()
   self:StartUpdateTimer()
end

function PANEL:AddColumn(label, func, width)
   local lbl = vgui.Create("DLabel", self)
   
   lbl:SetText( label )
   lbl.IsHeading = true
   lbl.Width = width or 50
   table.insert(self.cols, lbl)
   
   return lbl
end

function PANEL:StartUpdateTimer()
   if not timer.Exists("TTTScoreboardUpdater") then
      timer.Create( "TTTScoreboardUpdater", 0.3, 0, function()
         local pnl = GAMEMODE:GetScoreboardPanel()
        
         if IsValid(pnl) then
            pnl:UpdateScoreboard()
         end
      end)
   end
end

function PANEL:Paint()
   BorderedRect(1, y_logo_off, self:GetWide()-2, self:GetTall()-y_logo_off-2, panel.main_light, panel.border, true, true, true, true, false, true)
   BorderedRect(1, y_logo_off+29, self:GetWide()-2, 32, panel.top_light, panel.border, true, false, true, false, false, true)
   if (midnight_sb.config.map_preview) then BorderedRect(self:GetWide()-145, y_logo_off+9, 136, 72, panel.main_dark, panel.border, true, true, true, true, false, true) end

   surface.SetDrawColor(255, 255, 255, 255)

   if (source == "fastdl" and midnight_sb.config.map_preview) then
      surface.SetMaterial(map_fastdl)
      surface.DrawTexturedRect(self:GetWide()-145, 81, 136, 72)
   end
   
   if (logo_custom) then
      surface.SetMaterial(midnight_sb.config.logo_path)
      surface.DrawTexturedRect(5 + midnight_sb.config.logo_offset_x, 0 + midnight_sb.config.logo_offset_y, 256 * midnight_sb.config.logo_scale, 256 * midnight_sb.config.logo_scale)
   else
      surface.SetTexture(logo_default)
      surface.DrawTexturedRect(5, 0, 256, 256)
   end
end

function PANEL:PerformLayout()
   local gy = 0
   
   if (midnight_sb.config.map_preview) then x_preview_off = 153 else x_preview_off = 10 end
   
   for i = 1, GROUP_COUNT do
      local group = self.ply_groups[i]
      if ValidPanel(group) then
         if group:HasRows() then
            group:SetVisible(true)
            group:SetPos(0, gy)
            group:SetSize(self.ply_frame:GetWide(), group:GetTall())
            group:InvalidateLayout()
            gy = gy + group:GetTall()+5
         else
            group:SetVisible(false)
         end
      end
   end

   self.ply_frame:GetCanvas():SetSize(self.ply_frame:GetCanvas():GetWide(), gy)

   local h = y_logo_off+110+self.ply_frame:GetCanvas():GetTall()
   local scrolling = h > ScrH()*0.95

   self.ply_frame:SetScroll(scrolling)
   h = math.Clamp(h, 110+y_logo_off, ScrH()*0.95)

   local w = math.max(ScrW()*0.6, 640)

   self:SetSize(w, h)
   self:SetPos((ScrW()-w)/2, math.min(72, (ScrH()-h)/4))

   self.ply_frame:SetPos(8, y_logo_off+109)
   self.ply_frame:SetSize(self:GetWide()-16, self:GetTall()-109-y_logo_off-5)

   self.hostdesc:SizeToContents()
   self.hostdesc:SetPos(w-self.hostdesc:GetWide()-x_preview_off, y_logo_off+11)

   local hw = w-180-8
   self.hostname:SetSize(hw, 32)
   self.hostname:SetPos(w-self.hostname:GetWide()-x_preview_off, y_logo_off+30)
   
   if (source == "webhost" and midnight_sb.config.map_preview) then
      self.html:SetPos(self:GetWide()-145, y_logo_off+9)
      self.html:SetSize(136, 72)
   end

   surface.SetFont("cool_large")
   
   local hname = self.hostname:GetValue()
   local tw, _ = surface.GetTextSize(hname)
   
   while tw > hw do
      hname = string.sub(hname, 1, -6) .. "..."
      tw, th = surface.GetTextSize(hname)
   end

   self.hostname:SetText(hname)
   self.mapchange:SizeToContents()
   self.mapchange:SetPos(w-self.mapchange:GetWide()-x_preview_off, y_logo_off+66)

   local cy = y_logo_off+90
   local cx = w-8-(scrolling and 16 or 0)
   
   for i = 1, 3 do
      self.cols[i]:SizeToContents()
      cx = cx-self.cols[i].Width
      self.cols[i]:SetPos(cx-self.cols[i]:GetWide()/2, cy)
   end
   
   local four = self.cols[4]
   
   four:SizeToContents()
   cx = cx-four.Width
   four:SetPos(cx-four:GetWide()/2-10, cy)
   
   if (titles_enabled) then
      local five = self.cols[5]
      
      five:SizeToContents()
      cx = cx-five.Width
      five:SetPos(cx-five:GetWide()/2-20, cy)
   end
   
   if (PS) or (PS2) then
      local six
      
      if (titles_enabled) then
         six = self.cols[6]
      else
         six = self.cols[5]
      end
      
      six:SizeToContents()
      cx = cx-six.Width
      six:SetPos(cx-six:GetWide(), cy)
   end
end

function PANEL:ApplySchemeSettings()
   self.hostdesc:SetFont("midnight_font_13")
   self.hostname:SetFont("midnight_font_22")
   self.mapchange:SetFont("midnight_font_13")

   self.hostdesc:SetTextColor(COLOR_WHITE)
   self.hostname:SetTextColor(text_colour.dark)
   self.mapchange:SetTextColor(COLOR_WHITE)
   
   self.hostdesc:SetExpensiveShadow(1, Color(0, 0, 0, 190))
   self.hostname:SetExpensiveShadow(1, Color(0, 0, 0, 65))
   self.mapchange:SetExpensiveShadow(1, Color(0, 0, 0, 190))

   for k, v in pairs(self.cols) do
      v:SetFont("treb_small")
      v:SetTextColor(COLOR_WHITE)
      v:SetExpensiveShadow(1, Color(0, 0, 0, 190))
   end
end

function PANEL:UpdateScoreboard(force)
   if not force and not self:IsVisible() then return end

   local layout = false

   for k, p in pairs(player.GetAll()) do
      if IsValid(p) then
         local group = ScoreGroup(p)
         if self.ply_groups[group] and not self.ply_groups[group]:HasPlayerRow(p) then
            self.ply_groups[group]:AddPlayerRow(p)
            layout = true
         end
      end
   end

   for k, group in pairs(self.ply_groups) do
      if ValidPanel(group) then
         group:SetVisible(group:HasRows())
         group:UpdatePlayerData()
      end
   end

   if layout then
      self:PerformLayout()
   else
      self:InvalidateLayout()
   end
end

vgui.Register("TTTScoreboard", PANEL, "Panel")

local PANEL = {}

function PANEL:Init()
   self.YOffset = 0
   self.pnlCanvas  = vgui.Create("Panel", self)
   self.scroll = vgui.Create("DVScrollBar", self)
end

function PANEL:GetCanvas() return self.pnlCanvas end

function PANEL:OnMouseWheeled(dlta)
   self.scroll:AddScroll(dlta*-2)
   self:InvalidateLayout()
end

function PANEL:SetScroll(st)
   self.scroll:SetEnabled(st)
end

function PANEL:PerformLayout()
   local was_on = self.scroll.Enabled
   
   self.pnlCanvas:SetVisible(self:IsVisible())
   self.scroll:SetPos(self:GetWide()+16, 0)
   self.scroll:SetSize(8, self:GetTall())
   self.scroll:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
   self.scroll:SetEnabled(was_on)
   self.YOffset = self.scroll:GetOffset()
   self.pnlCanvas:SetPos(0, self.YOffset)
   self.pnlCanvas:SetSize(self:GetWide()-(self.scroll.Enabled and 16 or 0), self.pnlCanvas:GetTall())
end

vgui.Register("TTTPlayerFrame", PANEL, "Panel")