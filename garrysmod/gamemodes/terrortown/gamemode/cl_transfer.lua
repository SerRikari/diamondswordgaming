local GetTranslation = LANG.GetTranslation
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

function CreateTransferMenu(parent)
   local dform = vgui.Create("DForm", parent)
   dform:SetName(GetTranslation("xfer_menutitle"))
   dform:StretchToParent(0,0,0,0)
   dform:SetAutoSize(false)

   if LocalPlayer():GetCredits() <= 0 then
      dform:Help(GetTranslation("xfer_no_credits"))
      return dform
   end
   
   local amount = 20
   local bw, bh = 100, 30
   
   if (panel.top_dark.r <= 100) or (panel.top_dark.g <= 100) or (panel.top_dark.b <= 100) then
      amount = 6
   end

   local dsubmit = vgui.Create("DButton", dform)
   dsubmit:SetSize(bw, bh)
   dsubmit:SetDisabled(true)
   dsubmit:SetFont("midnight_font_13")
   dsubmit:SetText(GetTranslation("xfer_send"))
   dsubmit:SetTextColor(midnight_ui.text_colour.white)
   dsubmit.Hover = 0
   dsubmit.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover-FrameTime()*3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover+FrameTime()*3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   
   local selected_uid = nil

   local dpick = vgui.Create("DComboBox", dform)
   dpick.OnSelect = function(s, idx, val, data)
      if data then
         selected_uid = data
         dsubmit:SetDisabled(false)
      end
   end

   dpick:SetWide(250)

   local r = LocalPlayer():GetRole()
   
   for _, p in pairs(player.GetAll()) do
      if IsValid(p) and p:IsActiveRole(r) and p != LocalPlayer() then
         dpick:AddChoice(p:Nick(), p:UniqueID())
      end
   end

   if dpick:GetOptionText(1) then dpick:ChooseOptionID(1) end

   dsubmit.DoClick = function(s)
      if selected_uid then
         RunConsoleCommand("ttt_transfer_credits", tostring(selected_uid) or "-1", "1")
      end
   end

   dsubmit.Think = function(s)
      if LocalPlayer():GetCredits() < 1 then
         s:SetDisabled(true)
      end
   end

   dform:AddItem(dpick)
   dform:AddItem(dsubmit)
   dform:Help(LANG.GetParamTranslation("xfer_help", {role = LocalPlayer():GetRoleString()}))

   return dform
end
