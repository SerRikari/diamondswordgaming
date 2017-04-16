include("cl_awards.lua")

local table = table
local string = string
local vgui = vgui
local pairs = pairs
local surface = surface
local dst = draw.SimpleText

CLSCORE = {}
CLSCORE.Events = {}
CLSCORE.Scores = {}
CLSCORE.TraitorIDs = {}
CLSCORE.DetectiveIDs = {}
CLSCORE.Players = {}
CLSCORE.StartTime = 0
CLSCORE.Panel = nil

CLSCORE.EventDisplay = {}

local skull_icon = Material("HUD/killicons/default")
local amount = 20

local T = LANG.GetTranslation
local PT = LANG.GetParamTranslation

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

local role_dark = {
   ["innocent"] = midnight_ui.role_dark.innocent,
   ["traitor"] = midnight_ui.role_dark.traitor,
   ["detective"] = midnight_ui.role_dark.detective
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

function draw.SimpleAA(text, font, x, y, colour, align)
   dst(text, font, x+1, y+1, Color(0, 0, 0, math.min(colour.a, 120)), align)
   dst(text, font, x+2, y+2, Color(0, 0, 0, math.min(colour.a, 50)), align)
   dst(text, font, x, y, colour, align)
end

function CLSCORE:GetDisplay(key, event)
   local displayfns = self.EventDisplay[event.id]
   if not displayfns then return end
   local keyfn = displayfns[key]
   if not keyfn then return end

   return keyfn(event)
end

function CLSCORE:TextForEvent(e)
   return self:GetDisplay("text", e)
end

function CLSCORE:IconForEvent(e)
   return self:GetDisplay("icon", e)
end

function CLSCORE:TimeForEvent(e)
   local t = e.t - self.StartTime
   if t >= 0 then
      return util.SimpleTime(t, "%02i:%02i")
   else
      return "     "
   end
end

function CLSCORE.DeclareEventDisplay(event_id, event_fns)
   if not tonumber(event_id) then
      Error("Event ??? display: invalid event id\n")
   end
   if (not event_fns) or type(event_fns) != "table" then
      Error(Format("Event %d display: no display functions found.\n", event_id))
   end
   if not event_fns.text then
      Error(Format("Event %d display: no text display function found.\n", event_id))
   end
   if not event_fns.icon then
      Error(Format("Event %d display: no icon and tooltip display function found.\n", event_id))
   end

   CLSCORE.EventDisplay[event_id] = event_fns
end

function CLSCORE:FillDList(dlst)

   for k, e in pairs(self.Events) do

      local etxt = self:TextForEvent(e)
      local eicon, ttip = self:IconForEvent(e)
      local etime = self:TimeForEvent(e)

      if etxt then
         if eicon then
            local mat = eicon
            eicon = vgui.Create("DImage")
            eicon:SetMaterial(mat)
            eicon:SetTooltip(ttip)
            eicon:SetKeepAspect(true)
            eicon:SizeToContents()
         end


         dlst:AddLine(etime, eicon, "  " .. etxt)
      end
   end
end

function CLSCORE:BuildEventLogPanel(dpanel)
   local margin = 10

   local w, h = dpanel:GetSize()

   local dlist = vgui.Create("DListView", dpanel)
   dlist:SetPos(0, 0)
   dlist:SetSize(w, h - margin * 2)
   dlist:SetSortable(true)
   dlist:SetMultiSelect(false)
   dlist.Paint = function(self, w, h)
      surface.SetDrawColor(text_colour.white)
      surface.DrawRect(0, 0, w, h)
   end
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
   
   local timecol = dlist:AddColumn(T("col_time"))
   local iconcol = dlist:AddColumn("")
   local eventcol = dlist:AddColumn(T("col_event"))

   iconcol:SetFixedWidth(16)
   timecol:SetFixedWidth(40)
   eventcol:SetFixedWidth(600)

   iconcol.Header:SetDisabled(true)
   timecol.Header:SetDisabled(true)
   eventcol.Header:SetDisabled(true)
   
   iconcol.Header:SetTextColor(text_colour.white)
   iconcol.Header.Paint = function(self, w, h)
      BorderedRect(0, 0, w, h, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end
   
   timecol.Header:SetTextColor(text_colour.white)
   timecol.Header.Paint = function(self, w, h)
      BorderedRect(0, 0, w, h, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end
   eventcol.Header:SetTextColor(text_colour.white)
   eventcol.Header.Paint = function(self, w, h)
      BorderedRect(0, 0, w, h, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end 

   self:FillDList(dlist)
end

function CLSCORE:BuildScorePanel(dpanel)
   local margin = 10
   local w, h = dpanel:GetSize()

   local dlist = vgui.Create("DListView", dpanel)
   dlist:SetPos(0, 0)
   dlist:SetSize(w, h)
   dlist:SetSortable(true)
   dlist:SetMultiSelect(false)
   dlist:SetPaintBackground(false)
   dlist:SetDrawBackground(false)
   dlist.Paint = function(self, w, h)
      surface.SetDrawColor(text_colour.white)
      surface.DrawRect(0, 0, w, h)
   end
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
   
   local colnames = {"", "col_player", "col_role", "col_kills1", "col_kills2", "col_points", "col_team", "col_total"}
   for k, name in pairs(colnames) do
      if name == "" then
         local c = dlist:AddColumn("")
         c.Header:SetTextColor(text_colour.white)
         c.Header.Paint = function(self, w, h)
            BorderedRect(0, 0, w, h, panel.top_dark, panel.top_dark, true, true, true, true, false, true) 
         end
         c:SetFixedWidth(20)
      else
         local k = dlist:AddColumn(T(name))
         k.Header:SetTextColor(text_colour.white)
         k.Header.Paint = function(self, w, h)
            BorderedRect(0, 0, w, h, panel.top_dark, panel.top_dark, true, true, true, true, false, true) 
         end
         k:SetFixedWidth(91)
      end
   end

   local wintype = WIN_NONE
   for i=#self.Events, 1, -1 do
      local e = self.Events[i]
      if e.id == EVENT_FINISH then
         wintype = e.win
         break
      end
   end

   local scores = self.Scores
   local nicks = self.Players
   local bonus = ScoreTeamBonus(scores, wintype)

   for id, s in pairs(scores) do
      if id != -1 then
         local was_traitor = s.was_traitor
         local role = was_traitor and T("traitor") or (s.was_detective and T("detective") or "")

         local surv = ""
         if s.deaths > 0 then
            surv = vgui.Create("ColoredBox", dlist)
            surv:SetColor(Color(150, 50, 50))
            surv:SetBorder(false)
            surv:SetSize(18,18)

            local skull = vgui.Create("DImage", surv)
            skull:SetMaterial(skull_icon)
            skull:SetTooltip("Dead")
            skull:SetKeepAspect(true)
            skull:SetSize(18,18)
         end

         local points_own   = KillsToPoints(s, was_traitor)
         local points_team  = (was_traitor and bonus.traitors or bonus.innos)
         local points_total = points_own + points_team

         local l = dlist:AddLine(surv, nicks[id], role, s.innos, s.traitors, points_own, points_team, points_total)

         for k, col in pairs(l.Columns) do
            col:SetContentAlignment(5)
         end

         local surv_col = l.Columns[1]
         if surv_col then
            surv_col.Value = type(surv_col.Value) == "Panel" and "1" or "0"
         end
      end
   end

   dlist:SortByColumn(6)
end

function CLSCORE:AddAward(y, pw, award, dpanel)
   local nick = award.nick
   local text = award.text
   local title = string.upper(award.title)

   local titlelbl = vgui.Create("DLabel", dpanel)
   titlelbl:SetText(title)
   titlelbl:SetFont("TabLarge")
   titlelbl:SizeToContents()
   local tiw, tih = titlelbl:GetSize()

   local nicklbl = vgui.Create("DLabel", dpanel)
   nicklbl:SetText(nick)
   nicklbl:SetFont("DermaDefaultBold")
   nicklbl:SizeToContents()
   local nw, nh = nicklbl:GetSize()

   local txtlbl = vgui.Create("DLabel", dpanel)
   txtlbl:SetText(text)
   txtlbl:SetFont("DermaDefault")
   txtlbl:SizeToContents()
   local tw, th = txtlbl:GetSize()

   titlelbl:SetPos((pw - tiw) / 2, y)
   y = y + tih + 2

   local fw = nw + tw + 5
   local fx = ((pw - fw) / 2)
   nicklbl:SetPos(fx, y)
   txtlbl:SetPos(fx + nw + 5, y)

   y = y + nh

   return y
end

local function ValidAward(a)
   return a and a.nick and a.text and a.title and a.priority
end

local wintitle = {
   [WIN_TRAITOR] = {txt = "hilite_win_traitors", c = role_light.traitor},
   [WIN_INNOCENT] = {txt = "hilite_win_innocent", c = role_dark.innocent}
}

function CLSCORE:BuildHilitePanel(dpanel)
   local w, h = dpanel:GetSize()

   local title = wintitle[WIN_INNOCENT]
   local endtime = self.StartTime
   for i=#self.Events, 1, -1 do
      local e = self.Events[i]
      if e.id == EVENT_FINISH then
         endtime = e.t

         local wintype = e.win
         if wintype == WIN_TIMELIMIT then wintype = WIN_INNOCENT end

         title = wintitle[wintype]
         break
      end
   end

   local roundtime = endtime - self.StartTime

   local numply = table.Count(self.Players)
   local numtr = table.Count(self.TraitorIDs)

   local bg = vgui.Create("ColoredBox", dpanel)
   bg:SetColor(panel.main_light)
   bg:SetSize(w, h)
   bg:SetPos(0, 0)

   local winlbl = vgui.Create("DLabel", dpanel)
   winlbl:SetFont("midnight_font_68")
   winlbl:SetText("")
   winlbl:SetTextColor(text_colour.white)
   winlbl:SetSize(600, 68)
   local xwin = (w-winlbl:GetWide())/2
   local ywin = 30
   winlbl:SetPos(xwin, ywin)
   
   surface.SetFont("midnight_font_68")
   local tw, th = surface.GetTextSize(T(title.txt))

   bg.PaintOver = function()
      BorderedRect(xwin-15, ywin-5, winlbl:GetWide()+30, winlbl:GetTall()+10, title.c, panel.border, true, true, true, true, false, true) 
      draw.SimpleAA(T(title.txt), "midnight_font_68", winlbl:GetWide()+30/2-tw/2, ywin, text_colour.white, TEXT_ALIGN_CENTER)
   end

   local ysubwin = ywin + winlbl:GetTall()
   local partlbl = vgui.Create("DLabel", dpanel)

   local plytxt = PT(numtr == 1 and "hilite_players2" or "hilite_players1", {numplayers = numply, numtraitors = numtr})

   partlbl:SetText(plytxt)
   partlbl:SizeToContents()
   partlbl:SetPos(xwin, ysubwin + 8)

   local timelbl = vgui.Create("DLabel", dpanel)
   timelbl:SetText(PT("hilite_duration", {time= util.SimpleTime(roundtime, "%02i:%02i")}))
   timelbl:SizeToContents()
   timelbl:SetPos(xwin + winlbl:GetWide() - timelbl:GetWide(), ysubwin + 8)

   local wa = math.Round(w * 0.9)
   local ha = h - ysubwin - 40
   local xa = (w - wa) / 2
   local ya = h - ha

   local awardp = vgui.Create("DPanel", dpanel)
   awardp:SetSize(wa, ha)
   awardp:SetPos(xa, ya)
   awardp:SetPaintBackground(false)

   math.randomseed(self.StartTime + endtime)

   local award_choices = {}
   for k, afn in pairs(AWARDS) do
      local a = afn(self.Events, self.Scores, self.Players, self.TraitorIDs, self.DetectiveIDs)
      if ValidAward(a) then
         table.insert(award_choices, a)
      end
   end

   local num_choices = table.Count(award_choices)
   local max_awards = 5

   table.SortByMember(award_choices, "priority")

   for i=1,max_awards do
      local a = award_choices[i]
      if a then
         self:AddAward((i - 1) * 42, wa, a, awardp)
      end
   end
end

function CLSCORE:ShowPanel()
   local margin = 15

   local dpanel = vgui.Create("DFrame")
   local w, h = 700, 512
   dpanel:SetSize(w, h)
   dpanel:Center()
   dpanel:SetTitle(T("report_title"))
   dpanel:SetVisible(true)
   dpanel:ShowCloseButton(true)
   dpanel:SetMouseInputEnabled(true)
   dpanel:SetKeyboardInputEnabled(true)
   dpanel:SetDraggable(false)
   dpanel:ShowCloseButton(false)
   dpanel.OnKeyCodePressed = util.BasicKeyHandler
   dpanel.Paint = function(self,w,h)
      BorderedRect(1, 0, w-2, h-2, panel.main_dark, panel.border, true, true, true, true, false, false) 
   end
   
   dpanel:SetDeleteOnClose(false)
   self.Panel = dpanel
   
   local dlabel = vgui.Create("DLabel", dpanel)
   dlabel:SetSize(800, 33)
   dlabel:SetPos(0, 0)
   dlabel:SetFont("midnight_font_14")
   dlabel:SetText("   " .. T("report_title"))
   dlabel:SetTextColor(text_colour.white)
   dlabel.Paint = function(self, w, h)
      BorderedRect(1, 1, w, h-2, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end

   local dbut = vgui.Create("DButton", dpanel)
   local bw, bh = 120, 28
   dbut:SetSize(bw, bh)
   dbut:SetPos(w - bw - margin, h - bh - margin / 2)
   dbut:SetFont("midnight_font_13")
   dbut:SetText(T("close"))
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
   dbut.DoClick = function() dpanel:Close() end

   local dsave = vgui.Create("DButton", dpanel)
   dsave:SetSize(bw,bh)
   dsave:SetPos(margin, h - bh - margin/2)
   dsave:SetFont("midnight_font_13")
   dsave:SetText(T("report_save"))
   dsave:SetTextColor(text_colour.white)
   dsave:SetTooltip(T("report_save_tip"))
   dsave:SetConsoleCommand("ttt_save_events")
   dsave.Hover = 0
   dsave.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end

   local dtabsheet = vgui.Create("DPropertySheet", dpanel)
   dtabsheet:SetPos(margin, margin + 15 + 12)
   dtabsheet:SetSize(w - margin * 2, h - margin * 3 - bh - 18)
   dtabsheet.Paint = function(self,w,h)
      BorderedRect(1, 0, w-2, h-2, panel.main_light, panel.border, true, true, true, true, false, false) 
   end
   
   local padding = dtabsheet:GetPadding()

   local dtabhilite = vgui.Create("DPanel", dtabsheet)
   dtabhilite:SetPaintBackground(false)
   dtabhilite:StretchToParent(padding,padding,padding,padding)
   self:BuildHilitePanel(dtabhilite)

   dtabsheet:AddSheet(T("report_tab_hilite"), dtabhilite, "icon16/star.png", false, false, T("report_tab_hilite_tip"))

   local dtabevents = vgui.Create("DPanel", dtabsheet)
   dtabevents:StretchToParent(padding, padding, padding, padding)
   self:BuildEventLogPanel(dtabevents)

   dtabsheet:AddSheet(T("report_tab_events"), dtabevents, "icon16/application_view_detail.png", false, false, T("report_tab_events_tip"))

   local dtabscores = vgui.Create("DPanel", dtabsheet)
   dtabscores:SetPaintBackground(false)
   dtabscores:StretchToParent(padding, padding, padding, padding)
   self:BuildScorePanel(dtabscores)

   dtabsheet:AddSheet(T("report_tab_scores"), dtabscores, "icon16/user.png", false, false, T("report_tab_scores_tip"))
   
   for k, v in pairs(dtabsheet.Items) do
      if (!v.Tab) then continue end

        v.Tab.Paint = function(self,w,h)
         surface.SetDrawColor(panel.main_light)
          if v.Tab == dtabsheet:GetActiveTab() then
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
   
    dpanel.PaintOver = function()
      surface.SetDrawColor(panel.border)
      surface.DrawRect(15, 42, w - 31, 1)
      surface.DrawRect(15, 42, 1, h - 88)
      surface.DrawRect(w - 1, 0, 1, h)
      
      surface.SetDrawColor(shaded)
      surface.DrawRect(16, 43, w-32, 1)
    end
   
   dpanel:MakePopup()
   dpanel:SetKeyboardInputEnabled(false)
end

function CLSCORE:ClearPanel()

   if self.Panel then
      gui.SetMousePos(ScrW()/2, ScrH()/2)
      local pnl = self.Panel
      timer.Simple(0, function() pnl:Remove() end)
   end
end

function CLSCORE:SaveLog()
   if self.Events and #self.Events <= 0 then
      chat.AddText(COLOR_WHITE, T("report_save_error"))
      return
   end

   local logdir = "ttt/logs"
   if not file.IsDir(logdir, "DATA") then
      file.CreateDir(logdir)
   end

   local logname = logdir .. "/ttt_events_" .. os.time() .. ".txt"
   local log = "Trouble in Terrorist Town - Round Events Log\n".. string.rep("-", 50) .."\n"

   log = log .. string.format("%s | %-25s | %s\n", " TIME", "TYPE", "WHAT HAPPENED") .. string.rep("-", 50) .."\n"

   for _, e in pairs(self.Events) do
      local etxt = self:TextForEvent(e)
      local etime = self:TimeForEvent(e)
      local _, etype = self:IconForEvent(e)
      if etxt then
         log = log .. string.format("%s | %-25s | %s\n", etime, etype, etxt)
      end
   end

   file.Write(logname, log)

   chat.AddText(text_colour.white, "You've successfully saved the logs for this round.")
end

function CLSCORE:Reset()
   self.Events = {}
   self.TraitorIDs = {}
   self.DetectiveIDs = {}
   self.Scores = {}
   self.Players = {}
   self.RoundStarted = 0

   self:ClearPanel()
end

function CLSCORE:Init(events)
   local starttime = nil
   local traitors = nil
   local detectives = nil
   for k, e in pairs(events) do
      if e.id == EVENT_GAME and e.state == ROUND_ACTIVE then
         starttime = e.t
      elseif e.id == EVENT_SELECTED then
         traitors = e.traitor_ids
         detectives = e.detective_ids
      end

      if starttime and traitors then
         break
      end
   end

   local scores = {}
   local nicks = {}
   for k, e in pairs(events) do
      if e.id == EVENT_SPAWN then
         scores[e.uid] = ScoreInit()
         nicks[e.uid] = e.ni
      end
   end

   scores = ScoreEventLog(events, scores, traitors, detectives)

   self.Players = nicks
   self.Scores = scores
   self.TraitorIDs = traitors
   self.DetectiveIDs = detectives
   self.StartTime = starttime
   self.Events = events
end

function CLSCORE:ReportEvents(events)
   self:Reset()

   self:Init(events)
   self:ShowPanel()
end

function CLSCORE:Reopen()
   if self.Panel and self.Panel:IsValid() and not self.Panel:IsVisible() then
      self.Panel:SetVisible(true)
   end
end

local buff = ""
local function ReceiveReportStream(len)
   local cont = net.ReadBit() == 1

   buff = buff .. net.ReadString()

   if cont then
      return
   else
      local json_events = buff
      if not json_events then
         ErrorNoHalt("Round report decompression failed!\n")
      else
         local events = util.JSONToTable(json_events)

         if istable(events) then
            CLSCORE:ReportEvents(events)
         else
            ErrorNoHalt("Round report event decoding failed!\n")
         end
      end

      buff = ""
   end
end
net.Receive("TTT_ReportStream", ReceiveReportStream)

local function SaveLog(ply, cmd, args)
   CLSCORE:SaveLog()
end
concommand.Add("ttt_save_events", SaveLog)
