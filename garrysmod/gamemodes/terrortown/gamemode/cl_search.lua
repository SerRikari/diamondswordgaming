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

local is_dmg = util.BitSet

local function DmgToText(d)
   if is_dmg(d, DMG_CRUSH) then
      return T("search_dmg_crush")
   elseif is_dmg(d, DMG_BULLET) then
      return T("search_dmg_bullet")
   elseif is_dmg(d, DMG_FALL) then
      return T("search_dmg_fall")
   elseif is_dmg(d, DMG_BLAST) then
      return T("search_dmg_boom")
   elseif is_dmg(d, DMG_CLUB) then
      return T("search_dmg_club")
   elseif is_dmg(d, DMG_DROWN) then
      return T("search_dmg_drown")
   elseif is_dmg(d, DMG_SLASH) then
      return T("search_dmg_stab")
   elseif is_dmg(d, DMG_BURN) or is_dmg(d, DMG_DIRECT) then
      return T("search_dmg_burn")
   elseif is_dmg(d, DMG_SONIC) then
      return T("search_dmg_tele")
   elseif is_dmg(d, DMG_VEHICLE) then
      return T("search_dmg_car")
   else
      return T("search_dmg_other")
   end
end

local function DmgToMat(d)
   if is_dmg(d, DMG_BULLET) then
      return "bullet"
   elseif is_dmg(d, DMG_CRUSH) then
      return "rock"
   elseif is_dmg(d, DMG_BLAST) then
      return "splode"
   elseif is_dmg(d, DMG_FALL) then
      return "fall"
   elseif is_dmg(d, DMG_BURN) or is_dmg(d, DMG_DIRECT) then
      return "fire"
   else
      return "skull"
   end
end

local function WeaponToIcon(d)
   local wep = util.WeaponForClass(d)
   return wep and wep.Icon or "vgui/ttt/icon_nades"
end

local TypeToMat = {
   nick="id",
   words="halp",
   eq_armor="armor",
   eq_radar="radar",
   eq_disg="disguise",
   role={[ROLE_TRAITOR]="traitor", [ROLE_DETECTIVE]="det", [ROLE_INNOCENT]="inno"},
   c4="code",
   dmg=DmgToMat,
   wep=WeaponToIcon,
   head="head",
   dtime="time",
   stime="wtester",
   lastid="lastid",
   kills="list"
};

local function IconForInfoType(t, data)
   local base = "vgui/ttt/icon_"
   local mat = TypeToMat[t]

   if type(mat) == "table" then
      mat = mat[data]
   elseif type(mat) == "function" then
      mat = mat(data)
   end

   if not mat then
      mat = TypeToMat["nick"]
   end

   if t != "wep" then
      return base .. mat
   else
      return mat
   end
end

function PreprocSearch(raw)
   local search = {}
   for t, d in pairs(raw) do
      search[t] = {img=nil, text="", p=10}

      if t == "nick" then
         search[t].text = PT("search_nick", {player = d})
         search[t].p = 1
         search[t].nick = d
      elseif t == "role" then
         if d == ROLE_TRAITOR then
            search[t].text = T("search_role_t")
         elseif d == ROLE_DETECTIVE then
            search[t].text = T("search_role_d")
         else
            search[t].text = T("search_role_i")
         end

         search[t].p = 2
      elseif t == "words" then
         if d != "" then
            local final = string.match(d, "[\\.\\!\\?]$") != nil

            search[t].text = PT("search_words", {lastwords = d .. (final and "" or "--.")})
         end
      elseif t == "eq_armor" then
         if d then
            search[t].text = T("search_armor")
            search[t].p = 17
         end
      elseif t == "eq_disg" then
         if d then
            search[t].text = T("search_disg")
            search[t].p = 18
         end
      elseif t == "eq_radar" then
         if d then
            search[t].text = T("search_radar")

            search[t].p = 19
         end
      elseif t == "c4" then
         if d > 0 then
            search[t].text= PT("search_c4", {num = d})
         end
      elseif t == "dmg" then
         search[t].text = DmgToText(d)
         search[t].p = 12
      elseif t == "wep" then
         local wep = util.WeaponForClass(d)
         local wname = wep and LANG.TryTranslation(wep.PrintName)

         if wname then
            search[t].text = PT("search_weapon", {weapon = wname})
         end
      elseif t == "head" then
         if d then
            search[t].text = T("search_head")
         end
         search[t].p = 15
      elseif t == "dtime" then
         if d != 0 then
            local ftime = util.SimpleTime(d, "%02i:%02i")
            search[t].text = PT("search_time", {time = ftime})

            search[t].text_icon = ftime

            search[t].p = 8
         end
      elseif t == "stime" then
         if d > 0 then
            local ftime = util.SimpleTime(d, "%02i:%02i")
            search[t].text = PT("search_dna", {time = ftime})

            search[t].text_icon = ftime
         end
      elseif t == "kills" then
         local num = table.Count(d)
         if num == 1 then
            local vic = Entity(d[1])
            local dc = d[1] == -1
            if dc or (IsValid(vic) and vic:IsPlayer()) then
               search[t].text = PT("search_kills1", {player = (dc and "<Disconnected>" or vic:Nick())})
            end
         elseif num > 1 then
            local txt = T("search_kills2") .. "\n"

            local nicks = {}
            for k, idx in pairs(d) do
               local vic = Entity(idx)
               local dc = idx == -1
               if dc or (IsValid(vic) and vic:IsPlayer()) then
                  table.insert(nicks, (dc and "<Disconnected>" or vic:Nick()))
               end
            end

            local last = #nicks
            txt = txt .. table.concat(nicks, "\n", 1, last)
            search[t].text = txt
         end

         search[t].p = 30
      elseif t == "lastid" then
         if d and d.idx != -1 then
            local ent = Entity(d.idx)
            if IsValid(ent) and ent:IsPlayer() then
               search[t].text = PT("search_eyes", {player = ent:Nick()})

               search[t].ply = ent
            end
         end
      else
         search[t] = nil
      end

      if search[t] and search[t].text == "" then
         search[t] = nil
      end

      if search[t] then
         search[t].img = IconForInfoType(t, d)
      end
   end

   return search
end

local function SearchInfoController(search, dactive, dtext)
   return function(s, pold, pnew)
      local t = pnew.info_type
      local data = search[t]
      if not data then
       ErrorNoHalt("Search: data not found", t, data,"\n")
       return
      end

      dtext:GetLabel():SetWrap(#data.text > 50)

      dtext:SetText(data.text)
      dactive:SetImage(data.img)
   end
end

local function ShowSearchScreen(search_raw)
   local client = LocalPlayer()
   if not IsValid(client) then return end

   local m = 8
   local bw, bh = 100, 28
   local w, h = 410, 267

   local rw, rh = (w - m*2), (h - 25 - m*2)
   local rx, ry = 0, 0

   local rows = 1
   local listw, listh = rw, (64 * rows + 6)
   local listx, listy = rx, ry

   ry = ry + listh + m*2
   rx = m

   local descw, desch = rw - m*2, 80
   local descx, descy = rx, ry

   ry = ry + desch + m

   local butx, buty = rx, ry

   local dframe = vgui.Create("DFrame")
   dframe:SetSize(w, h)
   dframe:Center()
   dframe:SetTitle(T("search_title") .. " - " .. search_raw.nick or "???")
   dframe:SetVisible(true)
   dframe:ShowCloseButton(false)
   dframe:SetDraggable(false)
   dframe:SetMouseInputEnabled(true)
   dframe:SetKeyboardInputEnabled(true)
   dframe:SetDeleteOnClose(true)
   dframe.Paint = function(self,w,h)
      BorderedRect(1, 0, w-2, h-2, panel.main_dark, panel.border, true, true, true, true, false, false) 
   end
   
   local dlabel = vgui.Create("DLabel", dframe)
   dlabel:SetSize(w, 33)
   dlabel:SetPos(0, 0)
   dlabel:SetFont("midnight_font_14")
   dlabel:SetText("    " .. T("search_title") .. " - " .. search_raw.nick or "???")
   dlabel:SetTextColor(text_colour.white)
   dlabel.Paint = function(self, w, h)
      BorderedRect(1, 1, w-2, h-2, panel.top_dark, panel.border, true, true, true, true, false, true) 
   end
   dframe.OnKeyCodePressed = util.BasicKeyHandler
   
   local dborder = vgui.Create("DPanel", dframe)
   dborder:SetSize(w - 5, h - 38)
   dborder:SetPos(0, 32) 
   dborder.Paint = function(self, w, h)
      BorderedRect(1, 1, w-2, h-3, panel.main_dark, panel.border, false, false, false, false, false, false) 
   end

   local dcont = vgui.Create("DPanel", dborder)
   dcont:SetPaintBackground(false)
   dcont:SetSize(rw, rh)
   dcont:SetPos(m, m)

   local dlist = vgui.Create("DPanelSelect", dcont)
   dlist:SetPos(listx, listy)
   dlist:SetSize(listw, listh)
   dlist:EnableHorizontal(true)
   dlist:SetSpacing(1)
   dlist:SetPadding(2)

   if dlist.VBar then
      dlist.VBar:Remove()
      dlist.VBar = nil
   end

   local dscroll = vgui.Create("DHorizontalScroller", dlist)
   dscroll:StretchToParent(3, 3, 3, 3)

   local ddesc = vgui.Create("ColoredBox", dcont)
   ddesc:SetColor(Color(50, 50, 50))
   ddesc:SetName(T("search_info"))
   ddesc:SetPos(descx, descy)
   ddesc:SetSize(descw, desch)
   ddesc.Paint = function(self, w, h)
      BorderedRect(1, 1, w-2, h-3, panel.main_light, panel.border, true, true, true, true, false, true) 
   end

   local dactive = vgui.Create("DImage", ddesc)
   dactive:SetImage("vgui/ttt/icon_id")
   dactive:SetPos(m, m)
   dactive:SetSize(64, 64)

   local dtext = vgui.Create("ScrollLabel", ddesc)
   dtext:SetSize(descw - 120, desch - m*2)
   dtext:MoveRightOf(dactive, m*2)
   dtext:AlignTop(m)
   dtext:SetText("...")

   local by = rh - bh - (m / 2) - 10

   local dident = vgui.Create("DButton", dcont)
   dident:SetPos(m, by)
   dident:SetSize(bw,bh)
   dident:SetFont("midnight_font_13")
   dident:SetText(T("search_confirm"))
   dident:SetTextColor(text_colour.white)
   dident.Hover = 0
   dident.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   
   local id = search_raw.eidx + search_raw.dtime
   dident.DoClick = function() RunConsoleCommand("ttt_confirm_death", search_raw.eidx, id) end
   dident:SetDisabled(client:IsSpec() or (not client:KeyDownLast(IN_WALK)))

   local dcall = vgui.Create("DButton", dcont)
   dcall:SetPos(m*2 + bw, by)
   dcall:SetSize(bw, bh)
   dcall:SetFont("midnight_font_13")
   dcall:SetText(T("search_call"))
   dcall:SetTextColor(text_colour.white)
   dcall.Hover = 0
   dcall.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   dcall.DoClick = function(s)
      client.called_corpses = client.called_corpses or {}
      table.insert(client.called_corpses, search_raw.eidx)
      s:SetDisabled(true)

      RunConsoleCommand("ttt_call_detective", search_raw.eidx)
   end

   dcall:SetDisabled(client:IsSpec() or table.HasValue(client.called_corpses or {}, search_raw.eidx))

   local dconfirm = vgui.Create("DButton", dcont)
   dconfirm:SetPos(rw - m - bw, by)
   dconfirm:SetSize(bw, bh)
   dconfirm:SetFont("midnight_font_13")
   dconfirm:SetText(T("close"))
   dconfirm:SetTextColor(text_colour.white)
   dconfirm.Hover = 0
   dconfirm.Paint = function(self, w, h)
      if self:IsHovered() then
         self.Hover = math.Clamp(self.Hover - FrameTime() * 3, 0, 1)
      elseif self:IsHovered() == false then
         self.Hover = math.Clamp(self.Hover + FrameTime() * 3, 0, 1)
      end  
      
      BorderedRect(1, 1, w-2, h-3, Color(panel.top_dark.r+30*self.Hover, panel.top_dark.g+30*self.Hover, panel.top_dark.b+30*self.Hover, 255), panel.border, true, true, true, true, false, true) 
   end
   dconfirm.DoClick = function() dframe:Close() end

   local search = PreprocSearch(search_raw)

   dlist.OnActivePanelChanged = SearchInfoController(search, dactive, dtext)

   local start_icon = nil
   for t, info in SortedPairsByMemberValue(search, "p") do
      local ic = nil

      if t == "nick" then
         local name = info.nick
         local avply = IsValid(search_raw.owner) and search_raw.owner or nil

         ic = vgui.Create("SimpleIconAvatar", dlist)
         ic:SetPlayer(avply)

         start_icon = ic
      elseif t == "lastid" then
         ic = vgui.Create("SimpleIconAvatar", dlist)
         ic:SetPlayer(info.ply)
         ic:SetAvatarSize(24)
      elseif info.text_icon then
         ic = vgui.Create("SimpleIconLabelled", dlist)
         ic:SetIconText(info.text_icon)
      else
         ic = vgui.Create("SimpleIcon", dlist)
      end

      ic:SetIconSize(64)
      ic:SetIcon(info.img)

      ic.info_type = t

      dlist:AddPanel(ic)
      dscroll:AddPanel(ic)
   end

   dlist:SelectPanel(start_icon)

   dframe:MakePopup()
end

local function StoreSearchResult(search)
   if search.owner then
      local ply = search.owner
      if (not ply.search_result) or ply.search_result.show then

         ply.search_result = search

         local rag = Entity(search.eidx)
         if IsValid(rag) then
            rag.search_result = search
         end
      end
   end
end

local function bitsRequired(num)
   local bits, max = 0, 1
   while max <= num do
      bits = bits + 1
      max = max + max
   end
   return bits
end

local search = {}
local function ReceiveRagdollSearch()
   search = {}

   search.eidx = net.ReadUInt(16)

   search.owner = Entity(net.ReadUInt(8))
   if not (IsValid(search.owner) and search.owner:IsPlayer() and (not search.owner:Alive())) then
      search.owner = nil
   end

   search.nick = net.ReadString()

   local eq = net.ReadUInt(16)

   search.eq_armor = util.BitSet(eq, EQUIP_ARMOR)
   search.eq_radar = util.BitSet(eq, EQUIP_RADAR)
   search.eq_disg = util.BitSet(eq, EQUIP_DISGUISE)

   search.role = net.ReadUInt(2)
   search.c4 = net.ReadInt(bitsRequired(C4_WIRE_COUNT) + 1)

   search.dmg = net.ReadUInt(30)
   search.wep = net.ReadString()
   search.head = net.ReadBit() == 1
   search.dtime = net.ReadInt(16)
   search.stime = net.ReadInt(16)

   local num_kills = net.ReadUInt(8)
   if num_kills > 0 then
      search.kills = {}
      for i=1,num_kills do
         table.insert(search.kills, net.ReadUInt(8))
      end
   else
      search.kills = nil
   end

   search.lastid = {idx=net.ReadUInt(8)}

   search.finder = net.ReadUInt(8)

   search.show = (LocalPlayer():EntIndex() == search.finder)

   local words = net.ReadString()
   search.words = (words ~= "") and words or nil

   if search.show then
      ShowSearchScreen(search)
   end

   StoreSearchResult(search)

   search = nil
end
net.Receive("TTT_RagdollSearch", ReceiveRagdollSearch)