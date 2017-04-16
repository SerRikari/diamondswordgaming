include("sb_row.lua")

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

local function BorderedRect(x, y, w, h, main, border, shade, bt, br, bb, bl, centered, shaded)
   if (centered) then offset = (w/2) bx = -1 else offset = 0 bx = (w-1) end
 
   surface.SetDrawColor(main)
   surface.DrawRect(x-offset, y, w, h)
   
   if (shaded) then 
      surface.SetDrawColor(shade)
      surface.DrawRect(x-offset, y, w, 1)
   end

   if (bt) or (br) or (bb) or (bl) then surface.SetDrawColor(border) end
   if (bt) then surface.DrawRect(x-offset, y-1, w, 1) end
   if (br) then surface.DrawRect(x+offset+bx+1, y-1, 1, h+3) end
   if (bb) then surface.DrawRect(x-offset, y+h, w, 2) end
   if (bl) then surface.DrawRect(x-offset-1, y-1, 1, h+3) end
end

local function CompareScore(pa, pb)
   if not ValidPanel(pa) then return false end
   if not ValidPanel(pb) then return true end

   local a = pa:GetPlayer()
   local b = pb:GetPlayer()

   if not IsValid(a) then return false end
   if not IsValid(b) then return true end

   if a:Frags() == b:Frags() then return a:Deaths() < b:Deaths() end

   return a:Frags() > b:Frags()
end

local PANEL = {}

function PANEL:Init()
   self.name = "Spoooky!"
   self.color = COLOR_WHITE
   self.rows = {}
   self.rowcount = 0
   self.rows_sorted = {}
   self.group = "spec"
end

function PANEL:SetGroupInfo(name, color, group)
   self.name = name
   self.color = color
   self.group = group
end

function PANEL:Paint()
   BorderedRect(0, 0, self:GetWide(), self:GetTall(), panel.main_dark, panel.border, panel.shade_light, false, false, false, false, false, false)

   surface.SetFont("treb_small")

   local txt = self.name .. " (" .. self.rowcount .. ")"
   local w, h = surface.GetTextSize(txt)
   
   BorderedRect(1, 1, w+23, 19, self.color, panel.border, panel.shade_lighter, true, true, true, true, false, true)

   surface.SetTextPos(11, 11-h/2)
   surface.SetTextColor(0, 0, 0, 200)
   surface.DrawText(txt)

   surface.SetTextPos(10, 10-h/2)
   surface.SetTextColor(255, 255, 255, 255)
   surface.DrawText(txt)

   local y = 24
   
   for i, row in ipairs(self.rows_sorted) do
      if (i % 2) != 0 then
         BorderedRect(1, y+1, self:GetWide()-2, row:GetTall()-3, panel.main_light, panel.border, panel.shade_light, true, true, true, true, false, false)
      else
         BorderedRect(1, y+1, self:GetWide()-2, row:GetTall()-3, panel.main_dark, panel.border, panel.shade_light, true, true, true, true, false, false)
      end

      y = y+row:GetTall()+1
   end
end

function PANEL:AddPlayerRow(ply)
   if ScoreGroup(ply) == self.group and not self.rows[ply] then
      local row = vgui.Create("TTTScorePlayerRow", self)
      
      row:SetPlayer(ply)
      self.rows[ply] = row
      self.rowcount = table.Count(self.rows)
      self:PerformLayout()
   end
end

function PANEL:HasPlayerRow(ply)
   return self.rows[ply] != nil
end

function PANEL:HasRows()
   return self.rowcount > 0
end

function PANEL:UpdateSortCache()
   self.rows_sorted = {}
   
   for k, v in pairs(self.rows) do
      table.insert(self.rows_sorted, v)
   end

   table.sort(self.rows_sorted, CompareScore)
end

function PANEL:UpdatePlayerData()
   local to_remove = {}
   for k, v in pairs(self.rows) do
      if ValidPanel(v) and IsValid(v:GetPlayer()) and ScoreGroup(v:GetPlayer()) == self.group then
         v:UpdatePlayerData()
      else
         table.insert(to_remove, k)
      end
   end

   if #to_remove == 0 then return end

   for k, ply in pairs(to_remove) do
      local pnl = self.rows[ply]
      
      if ValidPanel(pnl) then
         pnl:Remove()
      end
      
      self.rows[ply] = nil
   end
   
   self.rowcount = table.Count(self.rows)
   self:UpdateSortCache()
   self:InvalidateLayout()
end

function PANEL:PerformLayout()
   if self.rowcount < 1 then
      self:SetVisible(false)
      return
   end

   self:SetSize(self:GetWide(), 30+self.rowcount+self.rowcount*SB_ROW_HEIGHT)
   self:UpdateSortCache()

   local y = 24
   
   for k, v in ipairs(self.rows_sorted) do
      v:SetPos(0, y)
      v:SetSize(self:GetWide(), v:GetTall())

      y = y+v:GetTall()+1
   end

   self:SetSize(self:GetWide(), 30+(y-24))
end
vgui.Register("TTTScoreGroup", PANEL, "Panel")