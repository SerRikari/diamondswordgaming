local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

local surface = surface

CreateConVar("ttt_spectator_mode", "0", FCVAR_ARCHIVE)
CreateConVar("ttt_mute_team_check", "0")
CreateClientConVar("ttt_avoid_detective", "0", true, true)

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

HELPSCRN = {}

function HELPSCRN:Show()
   local margin = 15

   local dframe = vgui.Create("DFrame")
   local w, h = 630, 490
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(GetTranslation("help_title"))
   dframe:ShowCloseButton(false)
   dframe:SetDraggable(false)
   dframe.Paint = function(self,w,h)
      BorderedRect(1, 0, w-2, h-2, panel.main_dark, panel.border, true, true, true, true, false, false) 
   end
   
   local dlabel = vgui.Create("DLabel", dframe)
   dlabel:SetSize(630, 33)
   dlabel:SetPos(0, 0)
   dlabel:SetFont("midnight_font_14")
   dlabel:SetText("   " .. GetTranslation("help_title"))
   dlabel:SetTextColor(text_colour.white)
   dlabel.Paint = function(self, w, h)
      BorderedRect(1, 1, w-2, h-2, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end

   local bw, bh = 120, 28
   
   local dbut = vgui.Create("DButton", dframe)
   dbut:SetSize(bw, bh)
   dbut:SetPos(w - bw - margin, h - bh - margin/2)
   dbut:SetFont("midnight_font_13")
   dbut:SetText(GetTranslation("close"))
   dbut:SetTextColor(text_colour.white)
   dbut.Hover = 0
   dbut.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   dbut.DoClick = function() dframe:Close() end

   local dtabs = vgui.Create("DPropertySheet", dframe)
   dtabs:SetPos(margin, margin * 2 + 12)
   dtabs:SetSize(w - margin * 2, h - margin * 3 - bh - 17)
   dtabs:DockMargin(2, 2, 2, 2)
   dtabs.Paint = function(self,w,h)
      BorderedRect(1, 1, w-2, h-3, panel.main_light, panel.border, true, true, true, true, false, true) 
   end
   
   local padding = dtabs:GetPadding()

   padding = padding * 2

   local tutparent = vgui.Create("DPanel", dtabs)
   tutparent:SetPaintBackground(false)
   tutparent:StretchToParent(margin, 0, 0, 0)

   self:CreateTutorial(tutparent)

   dtabs:AddSheet(GetTranslation("help_tut"), tutparent, "icon16/book_open.png", false, false, GetTranslation("help_tut_tip"))

   local dsettings = vgui.Create("DPanelList", dtabs)
   dsettings:StretchToParent(0,0,padding,0)
   dsettings:EnableVerticalScrollbar(true)
   
   dsettings.VBar.Paint = function(self, w, h) end
   dsettings.VBar.btnUp.Paint = function(self, w, h)
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 
      
      draw.SimpleText("t", "Marlett", 7, h / 2, text_colour.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
   end
   
   dsettings.VBar.btnDown.Paint = function(self, w, h) 
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 
      
      draw.SimpleText("u", "Marlett", 7, h / 2, text_colour.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
   end

   dsettings.VBar.btnGrip.Paint = function(self, w, h)
      BorderedRect(0, 0, 16, h, panel.top_lighter, panel.border, false, false, false, false, false, false) 
   end
   
   dsettings:SetPadding(10)
   dsettings:SetSpacing(10)

   local dgui = vgui.Create("DForm", dsettings)
   dgui:SetName(GetTranslation("set_title_gui"))

   local cb = nil

   dgui:CheckBox(GetTranslation("set_tips"), "ttt_tips_enable")

   cb = dgui:NumSlider(GetTranslation("set_cross_brightness"), "ttt_crosshair_brightness", 0, 1, 1)
   if cb.Label then
      cb.Label:SetWrap(true)
   end

   cb = dgui:NumSlider(GetTranslation("set_cross_size"), "ttt_crosshair_size", 0.1, 3, 1)
   if cb.Label then
      cb.Label:SetWrap(true)
   end

   dgui:CheckBox(GetTranslation("set_cross_disable"), "ttt_disable_crosshair")

   dgui:CheckBox(GetTranslation("set_minimal_id"), "ttt_minimal_targetid")

   dgui:CheckBox(GetTranslation("set_healthlabel"), "ttt_health_label")

   cb = dgui:CheckBox(GetTranslation("set_lowsights"), "ttt_ironsights_lowered")
   cb:SetTooltip(GetTranslation("set_lowsights_tip"))

   cb = dgui:CheckBox(GetTranslation("set_fastsw"), "ttt_weaponswitcher_fast")
   cb:SetTooltip(GetTranslation("set_fastsw_tip"))

   cb = dgui:CheckBox(GetTranslation("set_wswitch"), "ttt_weaponswitcher_stay")
   cb:SetTooltip(GetTranslation("set_wswitch_tip"))

   cb = dgui:CheckBox(GetTranslation("set_cues"), "ttt_cl_soundcues")

   dsettings:AddItem(dgui)

   local dplay = vgui.Create("DForm", dsettings)
   dplay:SetName(GetTranslation("set_title_play"))

   cb = dplay:CheckBox(GetTranslation("set_avoid_det"), "ttt_avoid_detective")
   cb:SetTooltip(GetTranslation("set_avoid_det_tip"))

   cb = dplay:CheckBox(GetTranslation("set_specmode"), "ttt_spectator_mode")
   cb:SetTooltip(GetTranslation("set_specmode_tip"))

   local mute = dplay:CheckBox(GetTranslation("set_mute"), "ttt_mute_team_check")
   mute:SetValue(GetConVar("ttt_mute_team_check"):GetBool())
   mute:SetTooltip(GetTranslation("set_mute_tip"))

   dsettings:AddItem(dplay)

   local dlanguage = vgui.Create("DForm", dsettings)
   dlanguage:SetName(GetTranslation("set_title_lang"))

   local dlang = vgui.Create("DComboBox", dlanguage)
   dlang:SetConVar("ttt_language")

   dlang:AddChoice("Server default", "auto")
   for _, lang in pairs(LANG.GetLanguages()) do
      dlang:AddChoice(string.Capitalize(lang), lang)
   end

   dlang.OnSelect = function(idx, val, data)
      RunConsoleCommand("ttt_language", data)
  end
   dlang.Think = dlang.ConVarStringThink

   dlanguage:Help(GetTranslation("set_lang"))
   dlanguage:AddItem(dlang)

   dsettings:AddItem(dlanguage)

   dtabs:AddSheet(GetTranslation("help_settings"), dsettings, "icon16/wrench.png", false, false, GetTranslation("help_settings_tip"))

   for k, v in pairs(dtabs.Items) do
      if (!v.Tab) then continue end

      v.Tab.Paint = function(self,w,h)
      surface.SetDrawColor(panel.main_light)
         if v.Tab == dtabs:GetActiveTab() then
            surface.DrawRect(0, 0, w, h)
         else
            surface.DrawRect(0, 0, w, h)
         end
      end
   end
   
   hook.Call("TTTSettingsTabs", GAMEMODE, dtabs)
   
   local amount = 20
   
   if (panel.main_light.r <= 100) or (panel.main_light.g <= 100) or (panel.main_light.b <= 100) then
      amount = 6
   end
   
   local shaded = Color(panel.main_light.r+amount, panel.main_light.g+amount, panel.main_light.b+amount, panel.main_light.a)
   
   dframe.PaintOver = function()
      surface.SetDrawColor(panel.border)
      surface.DrawRect(15, 42, w - 42, 1)
      surface.DrawRect(15, 42, 1, h - 88)
      
      surface.SetDrawColor(shaded)
      surface.DrawRect(16, 43, w-42, 1)
   end

   dframe:MakePopup()
end

local function ShowTTTHelp(ply, cmd, args)
   HELPSCRN:Show()
end
concommand.Add("ttt_helpscreen", ShowTTTHelp)

local function SpectateCallback(cv, old, new)
   local num = tonumber(new)
   if num and (num == 0 or num == 1) then
      RunConsoleCommand("ttt_spectate", num)
   end
end
cvars.AddChangeCallback("ttt_spectator_mode", SpectateCallback)

local function MuteTeamCallback(cv, old, new)
   local num = tonumber(new)
   if num and (num == 0 or num == 1) then
      RunConsoleCommand("ttt_mute_team", num)
   end
end
cvars.AddChangeCallback("ttt_mute_team_check", MuteTeamCallback)

local imgpath = "vgui/ttt/help/tut0%d"
local tutorial_pages = 6

function HELPSCRN:CreateTutorial(parent)
   local w, h = parent:GetSize()
   local m = 5

   local bg = vgui.Create("ColoredBox", parent)
   bg:StretchToParent(0,0,0,0)
   bg:SetTall(330)
   bg:SetColor(COLOR_BLACK)

   local tut = vgui.Create("DImage", parent)
   tut:StretchToParent(0, 0, 0, 0)
   tut:SetVerticalScrollbarEnabled(false)
   tut:SetImage(Format(imgpath, 1))
   tut:SetWide(1024)
   tut:SetTall(512)
   tut.current = 1

   local bw, bh = 100, 30

   local bar = vgui.Create("TTTProgressBar", parent)
   bar:SetSize(384, bh)
   bar:MoveBelow(bg)
   bar:CenterHorizontal()
   bar:SetMin(1)
   bar:SetMax(tutorial_pages)
   bar:SetValue(1)
   bar:SetColor(panel.top_light)

   bar.UpdateText = function(s)
      s.Label:SetText(Format("%i / %i", s.m_iValue, s.m_iMax))
   end

   bar:UpdateText()

   local bnext = vgui.Create("DButton", parent)
   bnext:SetSize(bw, bh)
   bnext:SetText(GetTranslation("next"))
   bnext:CopyPos(bar)
   bnext:AlignRight(1)
   bnext:SetFont("midnight_font_13")
   bnext:SetTextColor(text_colour.white)
   bnext.Hover = 0
   bnext.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(0, 0, w, h, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, false, false, false, false, false, false) 
   end

   local bprev = vgui.Create("DButton", parent)
   bprev:SetSize(bw, bh)
   bprev:SetText(GetTranslation("prev"))
   bprev:CopyPos(bar)
   bprev:AlignLeft()
   bprev:SetFont("midnight_font_13")
   bprev:SetTextColor(text_colour.white)
   bprev.Hover = 0
   bprev.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(0, 0, w, h, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, false, false, false, false, false, false) 
   end

   bnext.DoClick = function()
      if tut.current < tutorial_pages then
         tut.current = tut.current + 1
         tut:SetImage(Format(imgpath, tut.current))
         bar:SetValue(tut.current)
      end
   end

   bprev.DoClick = function()
      if tut.current > 1 then
         tut.current = tut.current - 1
         tut:SetImage(Format(imgpath, tut.current))
         bar:SetValue(tut.current)
      end
   end
end
