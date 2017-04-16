local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local Equipment = nil

local panel = {
   ["main_dark"] = midnight_ui.panel.main_dark,
   ["main_light"] = midnight_ui.panel.main_light,
   ["main_lighter"] = midnight_ui.panel.main_lighter,
   ["top_dark"] = midnight_ui.panel.top_dark,
   ["top_light"] = midnight_ui.panel.top_light,
   ["top_lighter"] = midnight_ui.panel.top_lighter,
   ["border"] = midnight_ui.panel.border
}

local text_colour = {
   ["dark"] = midnight_ui.text_colour.dark,
   ["light"] = midnight_ui.text_colour.light,
   ["lighter"] = midnight_ui.text_colour.lighter,
   ["lightest"] = midnight_ui.text_colour.lightest,
   ["white"] = midnight_ui.text_colour.white
}

local role_light = {
   ["innocent"] = midnight_ui.role_light.innocent,
   ["traitor"] = midnight_ui.role_light.traitor,
   ["detective"] = midnight_ui.role_light.detective
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

function GetEquipmentForRole(role)
   if not Equipment then
      local tbl = table.Copy(EquipmentItems)

      for k, v in pairs(weapons.GetList()) do
         if v and v.CanBuy then
            local data = v.EquipMenuData or {}
            local base = {
               id       = WEPS.GetClass(v),
               name     = v.PrintName or "Unnamed",
               limited  = v.LimitedStock,
               kind     = v.Kind or WEAPON_NONE,
               slot     = (v.Slot or 0)+1,
               material = v.Icon or "vgui/ttt/icon_id",
               type     = "Type not specified",
               model    = "models/weapons/w_bugbait.mdl",
               desc     = "No description specified."
            }

            if data.modelicon then
               base.material = nil
            end

            table.Merge(base, data)

            for _, r in pairs(v.CanBuy) do
               table.insert(tbl[r], base)
            end
         end
      end

      for r, is in pairs(tbl) do
         for _, i in pairs(is) do
            if i and i.id then
               i.custom = not table.HasValue(DefaultEquipment[r], i.id)
            end
         end
      end

      Equipment = tbl
   end

   return Equipment and Equipment[role] or {}
end

local function ItemIsWeapon(item) return not tonumber(item.id) end
local function CanCarryWeapon(item) return LocalPlayer():CanCarryType(item.kind) end

local color_bad = role_light.traitor
local color_good = role_light.innocent

local function PreqLabels(parent, x, y)
   local tbl = {}

   tbl.credits = vgui.Create("DLabel", parent)
   tbl.credits:SetToolTip(GetTranslation("equip_help_cost"))
   tbl.credits:SetPos(x, y)
   tbl.credits.Check = function(s, sel)
      local credits = LocalPlayer():GetCredits()
      return credits > 0, GetPTranslation("equip_cost", {num = credits})
   end

   tbl.owned = vgui.Create("DLabel", parent)
   tbl.owned:SetToolTip(GetTranslation("equip_help_carry"))
   tbl.owned:CopyPos(tbl.credits)
   tbl.owned:MoveBelow(tbl.credits, y)
   tbl.owned.Check = function(s, sel)
      if ItemIsWeapon(sel) and (not CanCarryWeapon(sel)) then
         return false, GetPTranslation("equip_carry_slot", {slot = sel.slot})
      elseif (not ItemIsWeapon(sel)) and LocalPlayer():HasEquipmentItem(sel.id) then
         return false, GetTranslation("equip_carry_own")
      else
         return true, GetTranslation("equip_carry")
      end
   end

   tbl.bought = vgui.Create("DLabel", parent)
   tbl.bought:SetToolTip(GetTranslation("equip_help_stock"))
   tbl.bought:CopyPos(tbl.owned)
   tbl.bought:MoveBelow(tbl.owned, y)
   tbl.bought.Check = function(s, sel)
      if sel.limited and LocalPlayer():HasBought(tostring(sel.id)) then
         return false, GetTranslation("equip_stock_deny")
      else
         return true, GetTranslation("equip_stock_ok")
      end
   end

   for k, pnl in pairs(tbl) do
      pnl:SetFont("TabLarge")
   end

   return function(selected)
   local allow = true
   for k, pnl in pairs(tbl) do
      local result, text = pnl:Check(selected)
      pnl:SetTextColor(result and color_good or color_bad)
      pnl:SetText(text)
      pnl:SizeToContents()

      allow = allow and result
      end
   return allow
   end
end

local PANEL = {}
local function DrawSelectedEquipment(pnl)
   local w, h = pnl:GetWide(), pnl:GetTall()
   local material = Material("vgui/spawnmenu/hover")
   
   surface.SetDrawColor(panel.top_dark)
   surface.SetMaterial(material)
   pnl:DrawTexturedRect()
end

function PANEL:SelectPanel(pnl)
   self.BaseClass.SelectPanel(self, pnl)
   if pnl then
      pnl.PaintOver = DrawSelectedEquipment
   end
end
vgui.Register("EquipSelect", PANEL, "DPanelSelect")

local SafeTranslate = LANG.TryTranslation
local color_darkened = Color(255, 255, 255, 80)

local color_slot = {
   [ROLE_TRAITOR] = role_light.traitor,
   [ROLE_DETECTIVE] = role_light.detective
}

local eqframe = nil

local function TraitorMenuPopup()
   local ply = LocalPlayer()
   
   if not IsValid(ply) or not ply:IsActiveSpecial() then
      return
   end

   if eqframe and ValidPanel(eqframe) then eqframe:Close() end

   local credits = ply:GetCredits()
   local can_order = credits > 0
   local w, h = 520, 365
   
   local dframe = vgui.Create("DFrame")
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(GetTranslation("equip_title"))
   dframe:SetVisible(true)
   dframe:ShowCloseButton(false)
   dframe:SetDraggable(false)
   dframe:SetMouseInputEnabled(true)
   dframe:SetDeleteOnClose(true)
   dframe.Paint = function(self,w,h)
      BorderedRect(1, 0, w-2, h-2, panel.main_light, panel.border, true, true, true, true, false, false) 
   end
   
   local dlabel = vgui.Create("DLabel", dframe)
   dlabel:SetSize(519, 32)
   dlabel:SetPos(0, 0)
   dlabel:SetFont("midnight_font_14")
   dlabel:SetText("    " .. GetTranslation("equip_title"))
   dlabel:SetTextColor(text_colour.white)
   dlabel.Paint = function(self, w, h)
      BorderedRect(1, 1, w-1, h-2, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end
   
   local m = 5
   local dsheet = vgui.Create("DPropertySheet", dframe)
   local oldfunc = dsheet.SetActiveTab
   
   dsheet.SetActiveTab = function(self, new)
      if self.m_pActiveTab != new and self.OnTabChanged then
         self:OnTabChanged(self.m_pActiveTab, new)
      end
      oldfunc(self, new)
   end

   dsheet:SetPos(0, 0)
   dsheet:StretchToParent(m, m + 31, m, m+1)
   dsheet.Paint = function(s, w, h)
      BorderedRect(1, 1, w-2, h-3, panel.main_dark, panel.border, true, true, true, true, false, true) 
   end
   
   local padding = dsheet:GetPadding()
   
   local dequip = vgui.Create("DPanel", dsheet)
   dequip:SetPaintBackground(false)
   dequip:StretchToParent(padding, padding, padding, padding)

   local owned_ids = {}
   
   for _, wep in pairs(ply:GetWeapons()) do
      if IsValid(wep) and wep:IsEquipment() then
         table.insert(owned_ids, wep:GetClass())
      end
   end

   if #owned_ids == 0 then
      owned_ids = nil
   end

   local dlist = vgui.Create("EquipSelect", dequip)
   dlist:SetPos(0, 0)
   dlist:SetSize(219, h - 90)
   dlist:EnableVerticalScrollbar(true)
   dlist:EnableHorizontal(true)
   dlist.VBar.Paint = function(self, w, h) end
   dlist.VBar.btnUp.Paint = function(self, w, h)
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 

      draw.SimpleText("t", "Marlett", 7, h / 2, text_colour.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
   end
   
   dlist.VBar.btnDown.Paint = function(self, w, h) 
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 

      draw.SimpleText("u", "Marlett", 7, h / 2, text_colour.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
   end

   dlist.VBar.btnGrip.Paint = function(self, w, h)
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 
   end
   dlist:SetPadding(4)

   local items = GetEquipmentForRole(ply:GetRole())
   local to_select = nil
   
   for k, item in pairs(items) do
      local ic = nil

      if item.material then
         if item.custom then
            ic = vgui.Create("LayeredIcon", dlist)

            local marker = vgui.Create("DImage")
            marker.PerformLayout = function(s)
               s:AlignBottom(2)
               s:AlignRight(2)
               s:SetSize(16, 16)
            end
            marker:SetTooltip(GetTranslation("equip_custom"))

            ic:AddLayer(marker)

            ic:EnableMousePassthrough(marker)
         elseif not ItemIsWeapon(item) then
            ic = vgui.Create("SimpleIcon", dlist)
         else
            ic = vgui.Create("LayeredIcon", dlist)
         end
         
         ic:SetIconSize(64)
         ic:SetIcon(item.material)
      elseif item.model then
         ic = vgui.Create("SpawnIcon", dlist)
         ic:SetModel(item.model)
      else
         ErrorNoHalt("Equipment item does not have model or material specified: " .. tostring(item) .. "\n")
      end

      ic.item = item

      local tip = SafeTranslate(item.name) .. " (" .. SafeTranslate(item.type) .. ")"
      ic:SetTooltip(tip)

      if ((not can_order) or
          table.HasValue(owned_ids, item.id) or
          (tonumber(item.id) and ply:HasEquipmentItem(tonumber(item.id))) or
          (ItemIsWeapon(item) and (not CanCarryWeapon(item))) or
          (item.limited and ply:HasBought(tostring(item.id)))) then

         ic:SetIconColor(color_darkened)
      end

      dlist:AddPanel(ic)
   end

   local dlistw = 224
   local bw, bh = 100, 25
   local dih = h - bh - m * 5
   local diw = w - dlistw - m*6 - 2
   
   local dinfobg = vgui.Create("DPanel", dequip)
   dinfobg:SetPaintBackground(false)
   dinfobg:SetSize(diw, dih)
   dinfobg:SetPos(dlistw + m, 0)

   local dinfo = vgui.Create("ColoredBox", dinfobg)
   dinfo:SetColor(Color(90, 255, 95))
   dinfo:SetPos(0, 0)
   dinfo:StretchToParent(0, 0, 0, dih - 135)
   dinfo.Paint = function(s, w, h)
      BorderedRect(1, 1, w-2, h-3, panel.main_light, panel.border, true, true, true, true, false, true) 
   end

   local dfields = {}
   
   for _, k in pairs({"name", "type", "desc"}) do
      dfields[k] = vgui.Create("DLabel", dinfo)
      dfields[k]:SetTooltip(GetTranslation("equip_spec_" .. k))
      dfields[k]:SetPos(m*3, m*2)
   end

   dfields.name:SetFont("TabLarge")
   dfields.type:SetFont("DermaDefault")
   dfields.type:MoveBelow(dfields.name)
   dfields.desc:SetFont("DermaDefaultBold")
   dfields.desc:SetContentAlignment(7)
   dfields.desc:MoveBelow(dfields.type, 1)

   local iw, ih = dinfo:GetSize()

   local dhelp = vgui.Create("ColoredBox", dinfobg)
   dhelp:SetColor(Color(90, 90, 95))
   dhelp:SetSize(diw, dih - 219)
   dhelp:MoveBelow(dinfo, m)
   dhelp.Paint = function(s, w, h)
      BorderedRect(1, 1, w-2, h-3, panel.main_light, panel.border, true, true, true, true, false, true) 
   end
   
   local update_preqs = PreqLabels(dhelp, m*3, m*2)

   dhelp:SizeToContents()

   local dconfirm = vgui.Create("DButton", dinfobg)
   dconfirm:SetPos(0, dih - bh * 2 - 13)
   dconfirm:SetSize(bw + 20, bh+3)
   dconfirm:SetDisabled(true)
   dconfirm:SetFont("midnight_font_13")
   dconfirm:SetText(GetTranslation("equip_confirm"))
   dconfirm:SetTextColor(text_colour.white)
   dconfirm.Hover = 0
   dconfirm.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover-FrameTime()*3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover+FrameTime()*3, 0, 1)
      end  

      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end

   dsheet:AddSheet(GetTranslation("equip_tabtitle"), dequip, "icon16/bomb.png", false, false, "Traitor equipment menu")
   
   if ply:HasEquipmentItem(EQUIP_RADAR) then
      local dradar = RADAR.CreateMenu(dsheet, dframe)
      dsheet:AddSheet(GetTranslation("radar_name"), dradar, "icon16/magnifier.png", false,false, "Radar control")
   end

   if ply:HasEquipmentItem(EQUIP_DISGUISE) then
      local ddisguise = DISGUISE.CreateMenu(dsheet)
      dsheet:AddSheet(GetTranslation("disg_name"), ddisguise, "icon16/user.png", false,false, "Disguise control")
   end

   if IsValid(ply.radio) or ply:HasWeapon("weapon_ttt_radio") then
      local dradio = TRADIO.CreateMenu(dsheet)
      dsheet:AddSheet(GetTranslation("radio_name"), dradio, "icon16/transmit.png", false,false, "Radio control")
   end

   if credits > 0 then
      local dtransfer = CreateTransferMenu(dsheet)
      dsheet:AddSheet(GetTranslation("xfer_name"), dtransfer, "icon16/group_gear.png", false,false, "Transfer credits")
   end

   dlist.OnActivePanelChanged = function(self, _, new)
      for k,v in pairs(new.item) do
         if dfields[k] then
           dfields[k]:SetText(SafeTranslate(v))
           dfields[k]:SizeToContents()
         end
      end

      dfields.desc:SetTall(70)
      can_order = update_preqs(new.item)
      dconfirm:SetDisabled(not can_order)
   end

   dlist:SelectPanel(to_select or dlist:GetItems()[1])
   
   dconfirm.DoClick = function()
      local pnl = dlist.SelectedPanel
      if not pnl or not pnl.item then return end
      local choice = pnl.item
      RunConsoleCommand("ttt_order_equipment", choice.id)
      dframe:Close()
   end

   dsheet.OnTabChanged = function(s, old, new)
      if not IsValid(new) then return end
      if new:GetPanel() == dequip then
         can_order = update_preqs(dlist.SelectedPanel.item)
         dconfirm:SetDisabled(not can_order)
      end
   end

   local dcancel = vgui.Create("DButton", dframe)
   dcancel:SetPos(w - 13 - bw, h - bh - 20)
   dcancel:SetSize(bw, bh+3)
   dcancel:SetDisabled(false)
   dcancel:SetFont("midnight_font_13")
   dcancel:SetText(GetTranslation("close"))
   dcancel:SetTextColor(text_colour.white)
   dcancel.Hover = 0
   dcancel.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover-FrameTime()*3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover+FrameTime()*3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   dcancel.DoClick = function() dframe:Close() end
   
   for k, v in pairs(dsheet.Items) do
      if (!v.Tab) then continue end

      v.Tab.Paint = function(self,w,h)
      surface.SetDrawColor(panel.main_dark)
         if v.Tab == dsheet:GetActiveTab() then
            surface.DrawRect(0, 0, w, h)
         else
            surface.DrawRect(0, 0, w, h)
         end
      end
   end
   
   local amount = 20
   
   if (panel.main_light.r <= 100) or (panel.main_light.g <= 100) or (panel.main_light.b <= 100) then
      amount = 6
   end
   
   local shaded = Color(panel.main_light.r+amount, panel.main_light.g+amount, panel.main_light.b+amount, panel.main_light.a)
    
   dframe.PaintOver = function()
      surface.SetDrawColor(panel.border)
      surface.DrawRect(5, 36, 508, 1)
      surface.DrawRect(5, 36, 1, 28)
      surface.DrawRect(w-1, 0, 1, 33)
      
      surface.SetDrawColor(shaded)
      surface.DrawRect(6, 37, 507, 1)
   end

   dframe:MakePopup()
   dframe:SetKeyboardInputEnabled(false)

   eqframe = dframe
end
concommand.Add("ttt_cl_traitorpopup", TraitorMenuPopup)

local function ForceCloseTraitorMenu(ply, cmd, args)
   if ValidPanel(eqframe) then
      eqframe:Close()
   end
end
concommand.Add("ttt_cl_traitorpopup_close", ForceCloseTraitorMenu)

function GM:OnContextMenuOpen()
   local r = GetRoundState()
   if r == ROUND_ACTIVE and not (LocalPlayer():GetTraitor() or LocalPlayer():GetDetective()) then
      return
   elseif r == ROUND_POST or r == ROUND_PREP then
      CLSCORE:Reopen()
      return
   end
   
   RunConsoleCommand("ttt_cl_traitorpopup")
end

local function ReceiveEquipment()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.equipment_items = net.ReadUInt(16)
end
net.Receive("TTT_Equipment", ReceiveEquipment)

local function ReceiveCredits()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.equipment_credits = net.ReadUInt(8)
end
net.Receive("TTT_Credits", ReceiveCredits)

local r = 0
local function ReceiveBought()
   local ply = LocalPlayer()
   if not IsValid(ply) then return end

   ply.bought = {}
   local num = net.ReadUInt(8)
   for i=1,num do
      local s = net.ReadString()
      if s != "" then
         table.insert(ply.bought, s)
      end
   end

   if num != #ply.bought and r < 10 then
      RunConsoleCommand("ttt_resend_bought")
      r = r + 1
   else
      r = 0
   end
end
net.Receive("TTT_Bought", ReceiveBought)

local function ReceiveBoughtItem()
   local is_item = net.ReadBit() == 1
   local id = is_item and net.ReadUInt(16) or net.ReadString()

   hook.Run("TTTBoughtItem", is_item, id)
end
net.Receive("TTT_BoughtItem", ReceiveBoughtItem)