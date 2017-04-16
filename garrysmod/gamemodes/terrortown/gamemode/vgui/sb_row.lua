include("sb_info.lua")

surface.CreateFont("midnight_font_13", {font = "Tahoma", weight = 800, size = 13, antialias = true})

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

local PS = midnight_sb.config.pointshop
local PS2 = midnight_sb.config.pointshop2
local titles_enabled = midnight_sb.config.titles_enabled

SB_ROW_HEIGHT = 26

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

local PANEL = {}

function PANEL:Init()
   self.info = nil
   self.open = false

   self.cols = {}
   self:AddColumn(GetTranslation("sb_ping"), function(ply) return ply:Ping() end)
   self:AddColumn(GetTranslation("sb_deaths"), function(ply) return ply:Deaths() end)
   self:AddColumn(GetTranslation("sb_score"), function(ply) return ply:Frags() end)

   if KARMA.IsEnabled() then
      self:AddColumn(GetTranslation("sb_karma"), function(ply) return math.Round(ply:GetBaseKarma()) end, 60)
   end
   
   if (titles_enabled) then
      self:AddColumn(midnight_sb.config.title_text, function(ply) return ply:GetNWString("midnight_tstr") end, 80)
   end
   
   if (PS) or (PS2) then
      if (PS) then
         self:AddColumn(midnight_sb.config.points_text, function(ply) return string.Comma(ply:PS_GetPoints()) or 0 end, 80)
      elseif (PS2) then
         self:AddColumn(midnight_sb.config.points_text, function(ply) return string.Comma(ply.PS2_Wallet.points) or 0 end, 80)
      end
   end
   
   hook.Call("TTTScoreboardColumns", nil, self)

   for _, c in ipairs(self.cols) do
      c:SetMouseInputEnabled(false)
   end

   self.tag = vgui.Create("DLabel", self)
   self.tag:SetText("")
   self.tag:SetMouseInputEnabled(false)

   self.sresult = vgui.Create("DImage", self)
   self.sresult:SetSize(16, 16)
   self.sresult:SetMouseInputEnabled(false)

   self.avatar = vgui.Create("AvatarImage", self)
   self.avatar:SetSize(SB_ROW_HEIGHT, SB_ROW_HEIGHT)
   self.avatar:SetMouseInputEnabled(false)

   self.nick = vgui.Create("DLabel", self)
   self.nick:SetMouseInputEnabled(false)

   self.voice = vgui.Create("DImageButton", self)
   self.voice:SetSize(16, 14)

   self:SetCursor("hand")
end

function PANEL:AddColumn(label, func, width)
   local lbl = vgui.Create("DLabel", self)
   
   lbl.GetPlayerText = func
   lbl.IsHeading = false
   lbl.Width = width or 50
   table.insert(self.cols, lbl)
   
   return lbl
end

local namecolor = {
   default = COLOR_WHITE,
   admin = Color(220, 180, 0, 255),
   dev = Color(100, 240, 105, 255)
}

function GM:TTTScoreboardColorForPlayer(ply)
   if not IsValid(ply) then return namecolor.default end
   
   if ply:SteamID() == "STEAM_0:0:1963640" then
      return namecolor.dev
   elseif ply:IsAdmin() and GetGlobalBool("ttt_highlight_admins", true) then
      return namecolor.admin
   end
   
   return namecolor.default
end

function PANEL:Paint()
   if not IsValid(self.Player) then return end

   local ply = self.Player

   if ply:IsTraitor() then
      surface.SetDrawColor(205, 60, 40, 15)
      surface.DrawRect(1, 1, self:GetWide()-2, SB_ROW_HEIGHT-3)
   elseif ply:IsDetective() then
      surface.SetDrawColor(66, 100, 200, 15)
      surface.DrawRect(1, 1, self:GetWide()-2, SB_ROW_HEIGHT-3)
   end
   
   local scr = sboard_panel.ply_frame.scroll.Enabled and 0 or 0
   
   surface.SetDrawColor(0, 0, 0, 40)
   
   if sboard_panel.cols then
      local cx = self:GetWide()-scr
      
      for k, v in ipairs(sboard_panel.cols) do
         cx = cx-v.Width
         if k == 5 then
            surface.DrawRect(cx-v.Width/2-35, 1, v.Width+30, self:GetTall()-3)
         elseif k % 2 == 1 then
            surface.DrawRect(cx-v.Width/2, 1, v.Width, self:GetTall()-3)
         end
      end
   end

   return true
end

function PANEL:SetPlayer(ply)
   self.Player = ply
   self.avatar:SetPlayer(ply)

   if not self.info then
      local g = ScoreGroup(ply)
      if g == GROUP_TERROR and ply != LocalPlayer() then
         self.info = vgui.Create("TTTScorePlayerInfoTags", self)
         self.info:SetPlayer(ply)
         self:InvalidateLayout()
      elseif g == GROUP_FOUND or g == GROUP_NOTFOUND then
         self.info = vgui.Create("TTTScorePlayerInfoSearch", self)
         self.info:SetPlayer(ply)
         self:InvalidateLayout()
      end
   else
      self.info:SetPlayer(ply)
      self:InvalidateLayout()
   end

   self.voice.DoClick = function()
      if IsValid(ply) and ply != LocalPlayer() then
         ply:SetMuted(not ply:IsMuted())
      end
   end

   self:UpdatePlayerData()
end

function PANEL:GetPlayer() return self.Player end

function PANEL:UpdatePlayerData()
   if not IsValid(self.Player) then return end

   local ply = self.Player
   local v = ply:GetNWVector("midnight_tclr")
   local colour
   
	if v and (v.x ~= 0 or v.y ~= 0 or v.z ~= 0) then
		colour = Color(v.x, v.y, v.z)
	end
   
   for i = 1, #self.cols do
      self.cols[i]:SetText(self.cols[i].GetPlayerText(ply, self.cols[i]))
   end
   
   if (titles_enabled) then
      self.cols[5]:SetTextColor(colour)
   end
   
   if (PS) or (PS2) then
      if (titles_enabled) then
         self.cols[6]:SetTextColor(colour)
      else
         self.cols[5]:SetTextColor(colour)
      end
   end

   self.nick:SetText(ply:Nick())
   self.nick:SizeToContents()
   
   if (midnight_sb.config.coloured_names) and (titles_enabled) then
      for k, group in pairs(midnight_sb.config.coloured_name_blacklist) do
         if ply:IsUserGroup(group) or ply:GetUserGroup() == group then
            self.nick:SetTextColor(COLOR_WHITE)
         else
            self.nick:SetTextColor(colour)
         end
      end
   else 
      self.nick:SetTextColor(COLOR_WHITE)
   end
      
   local ptag = ply.sb_tag
   if ScoreGroup(ply) != GROUP_TERROR then
      ptag = nil
   end

   self.tag:SetFont("midnight_font_13")
   self.tag:SetText(ptag and ptag.txt or "")
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
   self.tag:SetExpensiveShadow(1, Color(0, 0, 0, 190))
   self.sresult:SetVisible(ply.search_result != nil)

   if ply.search_result and (LocalPlayer():IsDetective() or (not ply.search_result.show)) then
      self.sresult:SetImageColor(Color(200, 200, 255))
   end

   self:LayoutColumns()

   if self.info then
      self.info:UpdatePlayerData()
   end

   if self.Player != LocalPlayer() then
      local muted = self.Player:IsMuted()
      self.voice:SetImage(muted and "midnight-icons/sound_mute.png" or "midnight-icons/sound.png")
   else
      self.voice:Hide()
   end
end

function PANEL:ApplySchemeSettings()
   local c = self.Player:GetNWVector("midnight_tclr")
   local colour
   
	if c and (c.x ~= 0 or c.y ~= 0 or c.z ~= 0) then
		colour = Color(c.x, c.y, c.z)
	end

   for i = 1, 4 do
      v = self.cols[i]
      k = i
      v:SetTextColor(COLOR_WHITE)
   end
   
   for k, v in pairs(self.cols) do
      v:SetFont("treb_small")
      v:SetExpensiveShadow(1, Color(0, 0, 0, 190))
   end
   
   if (titles_enabled) then
      self.cols[5]:SetFont("midnight_font_13")
   end
   
   if (PS) or (PS2) then
      if (titles_enabled) then
         self.cols[6]:SetFont("midnight_font_13")
      else
         self.cols[5]:SetFont("midnight_font_13")
      end
   end

   self.nick:SetFont("treb_small")
   
   if (midnight_sb.config.coloured_names) and (titles_enabled) then
      for k, group in pairs(midnight_sb.config.coloured_name_blacklist) do
         if self.Player:IsUserGroup(group) or self.Player:GetUserGroup() == group then
            self.nick:SetTextColor(COLOR_WHITE)
         else
            self.nick:SetTextColor(colour)
         end
      end
   else 
      self.nick:SetTextColor(COLOR_WHITE)
   end

   self.nick:SetExpensiveShadow(1, Color(0, 0, 0, 190))

   local ptag = self.Player and self.Player.sb_tag
   
   self.tag:SetTextColor(ptag and ptag.color or COLOR_WHITE)
   self.tag:SetFont("midnight_font_13")
   self.tag:SetExpensiveShadow(1, Color(0, 0, 0, 190))
   
   self.sresult:SetImage("icon16/magnifier.png")
   self.sresult:SetImageColor(Color(170, 170, 170, 150))
end

function PANEL:LayoutColumns()
   local cx = self:GetWide()

   for i = 1, 4 do
      self.cols[i]:SizeToContents()
      cx = cx-self.cols[i].Width
      self.cols[i]:SetPos(cx-self.cols[i]:GetWide()/2, (SB_ROW_HEIGHT-self.cols[i]:GetTall())/2)
   end
   
   if (titles_enabled) then
      local five = self.cols[5]
      
      five:SizeToContents()
      cx = cx-five.Width
      five:SetPos(cx-five:GetWide()/2-10, (SB_ROW_HEIGHT-five:GetTall())/2)
   end
      
   if (PS) or (PS2) then
      local six
      
      if (titles_enabled) then
         six = self.cols[6]
         six:SizeToContents()
         cx = cx-six.Width
         six:SetPos(cx-six:GetWide()+10, (SB_ROW_HEIGHT-six:GetTall())/2)
      else
         six = self.cols[5]
         six:SizeToContents()
         cx = cx-six.Width
         six:SetPos(cx-six:GetWide()/2-10, (SB_ROW_HEIGHT-six:GetTall())/2)
      end
   end

   self.tag:SizeToContents()
   cx = cx-115
   self.tag:SetPos(cx-self.tag:GetWide()+41+midnight_sb.config.tagpos, (SB_ROW_HEIGHT-self.tag:GetTall())/2)

   self.sresult:SetPos(cx+26+midnight_sb.config.tagpos, (SB_ROW_HEIGHT-16)/2)
end

function PANEL:PerformLayout()
   self.avatar:SetPos(0, 0)
   self.avatar:SetSize(SB_ROW_HEIGHT,SB_ROW_HEIGHT)

   local fw = sboard_panel.ply_frame:GetWide()
   self:SetWide(sboard_panel.ply_frame.scroll.Enabled and fw-16 or fw )

   if not self.open then
      self:SetSize(self:GetWide(), SB_ROW_HEIGHT)

      if self.info then self.info:SetVisible(false) end
   elseif self.info then
      self:SetSize(self:GetWide(), 100+SB_ROW_HEIGHT)
      self.info:SetVisible(true)
      self.info:SetPos(5, SB_ROW_HEIGHT+5)
      self.info:SetSize(self:GetWide(), 100)
      self.info:PerformLayout()
      self:SetSize(self:GetWide(), SB_ROW_HEIGHT + self.info:GetTall())
   end

   self.nick:SizeToContents()
   self.nick:SetPos(SB_ROW_HEIGHT+10, (SB_ROW_HEIGHT-self.nick:GetTall())/2)
   
   self:LayoutColumns()
   
   self.voice:SetVisible(not self.open)
   self.voice:SetSize(16, 14)
   self.voice:DockMargin(4, 6, 4, 4)
   self.voice:Dock(RIGHT)
end

function PANEL:DoClick(x, y)
   self:SetOpen(not self.open)
end

function PANEL:SetOpen(o)
   if self.open then
      surface.PlaySound("ui/buttonclickrelease.wav")
   else
      surface.PlaySound("ui/buttonclick.wav")
   end

   self.open = o
   
   self:PerformLayout()
   self:GetParent():PerformLayout()
   sboard_panel:PerformLayout()
end

function PANEL:DoRightClick()
   local menu = DermaMenu()
   menu.Player = self:GetPlayer()

   local close = hook.Call("TTTScoreboardMenu", nil, menu)
   if close then menu:Remove() return end

   menu:Open()
end
vgui.Register("TTTScorePlayerRow", PANEL, "Button")
