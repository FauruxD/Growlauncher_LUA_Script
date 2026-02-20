-- ================== CONFIG PNB ==================
local itemid = 5640
local delayPerBlock = 2
local delayAuto = 50
local xmag = 11
local ymag = 110
-- ================================================

-- ================== CONFIG PTHT =================
seedId = 333
plantId = 5640
delayPlant = 25
delayHarvest = 80
platformId = 7520
countPtht = 1
magx = 27
magy = 109
countTree = 3300

magplantEmpty = false
mode = "ptht" -- "ptht" | "pt" | "ht"
sprayMode = "uws" -- "uws" or "dgs"
isRunning = false
done = 0
-- ===============================================

-- ================ CONFIG EXCHANGE ===============
local isExchangeRunning = false
-- ================================================
-- ================== STATE ==================
local pnbEnabled = false
local paused = false
local localNetID = GetLocal().netID
-- ===========================================

-- ================== UTIL ==================
function ontext(txt)
    SendVariant({v1 = "OnTextOverlay", v2 = txt})
end

function talkBubble(text)
    local msg = "`1[FaRu] "..text
    SendVariant({
        v1 = "OnTalkBubble",
        v2 = getLocal().netID,
        v3 = msg
    })
end
-- ===========================================

-- ================== INIT PNB ==================
function initPNB()
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|itemsucker_block\n" ..
        "tilex|"..xmag.."|\n" ..
        "tiley|"..ymag.."|\n" ..
        "buttonClicked|getplantationdevice\n"
    )

    Sleep(400)

    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|cheats\n" ..
        "itemid|"..itemid.."\n" ..
        "slot|6\n" ..
        "checkbox_cheat_autofish|1\n" ..
        "checkbox_cheat_antibounce|1\n" ..
        "checkbox_cheat_speed|0\n" ..
        "checkbox_cheat_double_jump|1\n" ..
        "checkbox_cheat_jump|0\n" ..
        "checkbox_cheat_heat_resist|1\n" ..
        "checkbox_cheat_strong_punch|0\n" ..
        "checkbox_cheat_long_punch|1\n" ..
        "checkbox_cheat_long_build|0\n" ..
        "checkbox_cheat_autocollect|1\n" ..
        "checkbox_cheat_fastpull|0\n" ..
        "checkbox_cheat_fastdrop|0\n" ..
        "checkbox_cheat_fasttrash|0\n" ..
        "chat|\n"
    )

    EditToggle("Antilag", true)
    EditToggle("No Particle", true)
    EditToggle("Player", true)
end
-- =================================================

-- ================== BASIC PNB ==================
function place(x, y)
    SendPacketRaw(false, {
        type = 3,
        value = itemid,
        x = x * 32,
        y = y * 32,
        px = x,
        py = y
    })
end

function PlayerDetected()
    for _, p in pairs(getPlayerList()) do
        if p.netID ~= localNetID then
            return true
        end
    end
    return false
end
-- =================================================

-- ================== PNB THREAD ==================
runThread(function()
    while true do
        if not pnbEnabled then
            Sleep(200)
        else
            if PlayerDetected() then
                if not paused then
                    paused = true
                    LogToConsole("`4[PAUSE] Player detected, PNB paused")
                end
                Sleep(500)
            else
                if paused then
                    paused = false
                    LogToConsole("`2[RESUME] World empty, PNB resumed")
                    Sleep(1500)
                end

                Sleep(delayPerBlock)
                place(84,4)
                Sleep(delayPerBlock)
                place(85,4)
                Sleep(delayPerBlock)
                place(86,4)
                Sleep(delayPerBlock)
                place(87,4)
                Sleep(delayPerBlock)
                place(88,4)
                Sleep(delayPerBlock)
                place(89,4)

                Sleep(delayAuto)
            end
        end
    end
end)
-- =================================================

-- ================= PTHT FUNCTIONS =================
function getMagplant()
    sendPacket(2,
        "action|dialog_return\n"..
        "dialog_name|itemsucker_block\n"..
        "tilex|"..magx.."|\n"..
        "tiley|"..magy.."|\n"..
        "buttonClicked|getplantationdevice\n"
    )
end

function Ovlay(text)
    sendPacket(2,"action|input\n|text|"..text.."|\n")
end

function pt(x, y, id)
    local pkt = {}
    pkt.type = 3
    pkt.value = id
    pkt.px = x
    pkt.py = y
    pkt.x = x * 32
    pkt.y = y * 32
    SendPacketRaw(false, pkt)
end

function bellow(x, y)
    local below = GetTile(x, y +1)
    return below and below.fg == platformId
end

function plant()
    for _, t in pairs(GetTiles()) do
		if magplantEmpty then
			Ovlay("`4Plant Stopped (Magplant is Empty)")
			break
		end
		
        if t.fg == 0 and bellow(t.x, t.y) then
            pt(t.x, t.y, plantId)
            Sleep(delayPlant)
        end
    end
end

function CountUnreadyTree()
    local count = 0
    for x = 0, 100 do
        for y = 0, 113 do
            local tile = GetTile(x,y)
            if tile and tile.fg == seedId and not tile.readyharvest then
                count = count + 1
            end
        end
    end
    return count
end

function Uws()
    local unready = CountUnreadyTree()
    Ovlay("Unready Tree: "..unready)

    if unready >= countTree then
        Ovlay("`9Using Uws...")
        sendPacket(2,"action|dialog_return\ndialog_name|world_spray\n")
    else
        Ovlay("`4Skip UWS")
    end
end

function spray()
	Ovlay("`9Using Spray")
    for r, h in pairs(GetTiles()) do
        if h.fg == seedId and not h.readyharvest then
            Sleep(delayHarvest)
            SendPacketRaw(false, {
                type = 3,
                value = 1778,
                px = h.x,
                py = h.y,
                x = h.x * 32,
                y = h.y * 32
            })
        end
    end
Ovlay("`4Done Spray")
end

function hitTile(x, y)
    local pkt = {}
    pkt.type = 3
    pkt.value = 18
    pkt.px = x
    pkt.py = y
    pkt.x = x * 32
    pkt.y = y * 32
    SendPacketRaw(false, pkt)
end

function harvest()
    for x = 0, 100 do
        local rowMiss
        repeat
            rowMiss = 0
            for y = 0, 113 do
                local tile = GetTile(x, y)
                if tile and tile.fg == seedId and tile.readyharvest then
                    local tries = 0
                    repeat
						SendPacketRaw(false, {
                            state = 32,
                            px = x, py = y,
                            x = x * 32, y = y * 32
                        })
                        hitTile(x, y)
                        Sleep(delayHarvest)
                        tile = GetTile(x, y)
                        tries = tries + 1
                    until not (tile and tile.fg == seedId and tile.readyharvest)
                        or tries >= 2

                    if tile and tile.fg == seedId and tile.readyharvest then
                        rowMiss = rowMiss + 1
                    end
                end
            end
        until rowMiss == 0
        Sleep(25)
    end
end

function startPtht()
	if isRunning then
        Ovlay("`4Script already running!")
        return true
    end

    isRunning = true
    done = 0

    Ovlay("`2PTHT Script Started!")

    for i = 1, count_ptht do
        if not isRunning then break end

        if mode == "pt" or mode == "ptht" then
            Ovlay("`9Starting Auto Plant...")
            Sleep(1500)
            plant()
            Sleep(1000)
            Ovlay("`4DONE PLANT!")
        end

        if not isRunning then break end

        if mode == "ptht" and sprayMode == "uws" then
            Sleep(4500)
            if not isRunning then break end
            Uws()
        end

        if not isRunning then break end

        if mode == "ptht" and sprayMode == "dgs" then
            Sleep(4500)
            if not isRunning then break end
            spray()
        end

        if not isRunning then break end

        if mode == "ht" or mode == "ptht" then
            Sleep(5000)
            if not isRunning then break end

            Ovlay("`9Starting Auto Harvest")
            Sleep(500)
            harvest()
            Sleep(400)
            Ovlay("`4DONE HARVEST!")
        end

        done = done + 1
        Ovlay("`cTotal Done : "..done.." / "..count_ptht)

        Sleep(2000)
        Ovlay("`9Loading Next Cycle")
        Sleep(3000)
    end

    isRunning = false
    Ovlay("`4PTHT Script Finished!")
end
-- ===============================================

-- ================== DROP FUNCTIONS ==================
function drops(id, amount)
    SendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|drop_item\n" ..
        "itemID|"..id.."|\n" ..
        "count|"..amount.."\n"
    )
end

function clock(idNeed, idConvert, amount)
    for _, inv in pairs(GetInventory()) do
        if inv.id == idNeed and inv.amount < amount then
            SendPacketRaw(false, {type = 10, value = idConvert})
        end
    end
end
-- ====================================================

-- ================== EXCHANGE ==================
local function startExchangeEngine()
    AddHook(function(type, pkt)
        if type == 2 and pkt:find("dialog_name|exchange") then

            if isExchangeRunning then
                talkBubble("`4Exchange already running!")
                return true
            end

            talkBubble("`2Starting Exchange...")

            runThread(function()
                isExchangeRunning = true
                local counter = 0

                while isExchangeRunning do
                    SendPacket(2, pkt .. "\n")
                    counter = counter + 1
                    Sleep(300)
                end

                LogToConsole("`4Exchange Stopped! Total: " .. counter)
                talkBubble("`4Exchange Stopped! Total: " .. counter)
            end)

            return true
        end
    end, "OnSendPacket")
end
-- ==============================================

-- ================== UI : HELPER MENU ==================
function openHelperMenu()
    local status = pnbEnabled and "`2ENABLED" or "`4DISABLED"
    local dialog = [[
add_label_with_icon|big|`7Helper Menu|left|9472|
add_spacer|small|
add_label_with_icon|small|`0Hai! ]]..localPlayer().name..[[|right|14016|
add_label_with_icon|small|`0UserID : `3]]..GetLocal().userID..[[|left|12436|
add_label_with_icon|small|`0Current World `9]]..GetWorldName()..[[|left|3802|
add_label_with_icon|small|`0You're in Pos : `6[]]..(GetLocal().posX//32)..[[,]]..(GetLocal().posY//32)..[[]|left|12854|
add_spacer|small|
add_smalltext|PNB Status : ]]..status..[[|
add_spacer|small|
text_scaling_string|helperui|
add_button_with_icon|togglepnb|`7PNB Helper|staticGreyFrame|9472||
add_button_with_icon|featurescript|`7Feature Script|staticGreyFrame|9472||
add_button_with_icon|configpnb|`7PNB Config|staticGreyFrame|32||
add_button_with_icon|configPtht|`7PTHT Config|staticGreyFrame|32||
add_button_with_icon|exchange_go|`7Exchange Menu|staticGreyFrame|12826||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
end_dialog|helpermenu|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end

-- ================== UI : FEATURE SCRIPT ==================
function openFeatureScript()
    local dialog = [[
add_label_with_icon|big|`7Feature Script|left|9472|
add_spacer|small|
add_smalltext|`8Daftar command dan fungsi script:|

add_spacer|small|
add_label_with_icon|small|`cPNB Command|left|18|
add_smalltext|`9/startpnb      `7Start Auto PNB|
add_smalltext|`9/stoppnb      `7Stop Auto PNB|
add_smalltext|`9/configpnb      `7Stop Auto PNB|

add_spacer|small|
add_label_with_icon|small|`3PTHT Command|left|14922|
add_smalltext|`9/startptht        `7Start PT/HT|
add_smalltext|`9/stopptht      `7Stop PT/HT|
add_smalltext|`9/configptht        `7Open Config Menu|
add_smalltext|`9/infoo        `7Show Current Config|

add_spacer|small|
add_label_with_icon|small|`5ExchangeCommand|left|7188|
add_smalltext|`9/exchange      `7Open Exchange Menu|
add_smalltext|`9/startexc       `7Start Exchange Mode|
add_smalltext|`9/stopexc        `7Stop Exchange Loop|

add_spacer|small|
add_label_with_icon|small|`9World Lock|left|242|
add_smalltext|`9/w [amount]      `7Drop World Lock|
add_smalltext|`9/wx2 [amount]   `7Drop World Lock x2|
add_smalltext|`9/wx3 [amount]   `7Drop World Lock x3|
add_smalltext|`9/wall            `7Drop All World Lock|

add_spacer|small|
add_label_with_icon|small|`3Diamond Lock|left|1796|
add_smalltext|`3/d [amount]      `7Drop Diamond Lock|
add_smalltext|`3/dx2 [amount]   `7Drop Diamond Lock x2|
add_smalltext|`3/dx3 [amount]   `7Drop Diamond Lock x3|
add_smalltext|`3/dall            `7Drop All Diamond Lock|

add_spacer|small|
add_label_with_icon|small|`1Blue Gem Lock|left|7188|
add_smalltext|`1/b [amount]      `7Drop Blue Gem Lock|
add_smalltext|`1/bx2 [amount]   `7Drop Blue Gem Lock x2|
add_smalltext|`1/bx3 [amount]   `7Drop Blue Gem Lock x3|
add_smalltext|`1/ball            `7Drop All Blue Gem Lock|

add_spacer|small|
add_label_with_icon|small|`9Golden Gem Lock|left|8470|
add_smalltext|`9/g [amount]      `7Drop Golden Gem Lock|
add_smalltext|`9/gx2 [amount]   `7Drop Golden Gem Lock x2|
add_smalltext|`9/gx3 [amount]   `7Drop Golden Gem Lock x3|
add_smalltext|`9/gall            `7Drop All Golden Gem Lock|

add_spacer|small|
add_label_with_icon|small|`bThe Glorious Skull|left|13200|
add_smalltext|`b/t [amount]      `7Drop The Glorious Skull|
add_smalltext|`b/tx2 [amount]   `7Drop The Glorious Skull x2|
add_smalltext|`b/tx3 [amount]   `7Drop The Glorious Skull x3|
add_smalltext|`b/tall            `7Drop All The Glorious Skull|

add_spacer|small|
add_label_with_icon|small|`cThe Majestic Dragon|left|4428|
add_smalltext|`c/m [amount]      `7Drop The Majestic Dragon|
add_smalltext|`c/mx2 [amount]   `7Drop The Majestic Dragon x2|
add_smalltext|`c/mx3 [amount]   `7Drop The Majestic Dragon x3|
add_smalltext|`c/mall            `7Drop All The Majestic Dragon|

add_spacer|small|
add_label_with_icon|small|`wYin Yang Artifact|left|2950|
add_smalltext|`w/y [amount]      `7Drop Yin Yang Artifact|
add_smalltext|`w/yx2 [amount]   `7Drop Yin Yang Artifact x2|
add_smalltext|`w/yx3 [amount]   `7Drop Yin Yang Artifact x3|
add_smalltext|`w/yall            `7Drop All Yin Yang Artifact|

add_spacer|small|
add_label_with_icon|small|`#Bunny Valentine Artifact|left|5260|
add_smalltext|`#bv [amount]      `7Drop Bunny Valentine Artifact|
add_smalltext|`#bv2 [amount]   `7Drop Bunny Valentine Artifact x2|
add_smalltext|`#bv3 [amount]   `7Drop Bunny Valentine Artifact x3|
add_smalltext|`#bval            `7Drop All Bunny Valentine Artifact|

add_spacer|small|
add_label_with_icon|small|`8Chongqing Lion Artifact|left|7188|
add_smalltext|`8/c [amount]      `7Drop Chongqing Lion Artifact|
add_smalltext|`8/cx2 [amount]   `7Drop Chongqing Lion Artifact x2|
add_smalltext|`8/cx3 [amount]   `7Drop Chongqing Lion Artifact x3|
add_smalltext|`8/call            `7Drop All Chongqing Lion Artifact|

add_spacer|small|
add_smalltext|`8Contoh: `9/w 10 `7→ Drop 10 World Lock|
add_smalltext|`8`9/daw `7→ Drop All Lock|
end_dialog|featurescript|Close||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end

-- ================== UI : CONFIG PNB ==================
function openPNBConfig()
    local dialog = [[
set_border_color|0,215,230,255
set_bg_color|0,20,180,200
add_label_with_icon|big|`7PNB Configuration|left|9472|
add_spacer|small|
add_text_input|itemid|Item ID|]]..itemid..[[|5|
add_text_input|delaypb|Delay Per Block|]]..delayPerBlock..[[|5|
add_text_input|delayauto|Delay Auto|]]..delayAuto..[[|5|
add_text_input|xmag|Mag X|]]..xmag..[[|5|
add_text_input|ymag|Mag Y|]]..ymag..[[|5|
add_spacer|small|
add_button|savepnb|Save Config|
end_dialog|pnbconfig|Cancel||
]]
    SendVariant({v1="OnDialogRequest", v2=dialog})
end

-- ================== PTHT DIALOGS ==================
function configPtht()
	local dialog = [[
set_border_color|255,215,0,255
set_bg_color|150,0,0,200
add_label_with_icon|big|`7PTHT Configuration|left|5956|
add_spacer|small|
add_smalltext|`7Hi ]]..getLocal().name..[[|
add_smalltext|`7Type /infoo to see your latest config|
add_smalltext|`7This Script is Made by `c@FaRu|
add_spacer|small|
add_label_with_icon|small|`7Default Config : |||
add_label_with_icon|small|`7Mode : ptht|left|14922|
add_label_with_icon|small|`7Spray Mode : uws|left|5926|
add_label_with_icon|small|`7ID Plant : 5640 - `9]]..growtopia.getItemName(5640)..[[|left|5640|
add_label_with_icon|small|`7ID Harvest : 333 - `9]]..growtopia.getItemName(333)..[[|left|333|
add_label_with_icon|small|`7ID Platform : 7520 - `9]]..growtopia.getItemName(7520)..[[|left|7520|
add_label_with_icon|small|`7Delay Plant : 25|left|3804|
add_label_with_icon|small|`7Delay Harvest : 80|left|3804|
add_label_with_icon|small|`7Pos Mag : X: 27 Y: 109|left|5638|
add_label_with_icon|small|`7Minimal Tree for UWS : 3300|left|854|
add_label_with_icon|small|`7Loop : 20|left|15110|


add_spacer|small|
add_text_input|typeMode|`9Mode [pt/ht/ptht]||5|
add_text_input|sprayMode|`9Spray Mode [uws/dgs]||5|
add_text_input|plantId|`9ID Plant||5|
add_text_input|seedId|`9ID Harvest||5|
add_text_input|delayPlant|`9Delay Plant||5|
add_text_input|delayHarvest|`9Delay Harvest||5|
add_text_input|xmag|`9Pos Mag X||5|
add_text_input|ymag|`9Pos Mag Y||5|
add_text_input|countTree|`9Minimal Tree for UWS||5|
add_text_input|countPtht|`9Count Repeat||5|

add_spacer|small|
add_button|saveconfig|Save Config|
end_dialog|pthtconfig|Cancel||
]]

	SendVariant({v1="OnDialogRequest", v2=dialog})
end

function infoPtht()
    local dialog = [[
set_border_color|255,215,0,255
set_bg_color|150,0,0,200
add_label_with_icon|big|`7Config Info|left|5956|
add_spacer|small|
add_smalltext|`7Hi ]]..getLocal().name..[[|
add_smalltext|`7This is your latest config|
add_smalltext|`7This Script is Made by `c@FaRu|
add_spacer|small|
add_label_with_icon|small|`7Default Config : |||
add_label_with_icon|small|`7Mode : ]]..mode..[[|left|14922|
add_label_with_icon|small|`7Spray Mode : ]]..sprayMode..[[|left|5926|
add_label_with_icon|small|`7ID Plant : ]]..plantId..[[ - `9]]..growtopia.getItemName(plantId)..[[|left|]]..plantId..[[|
add_label_with_icon|small|`7ID Harvest : ]]..seedId..[[ - `9]]..growtopia.getItemName(seedId)..[[|left|]]..seedId..[[|
add_label_with_icon|small|`7ID Platform : ]]..platformId..[[ - `9]]..growtopia.getItemName(platformId)..[[|left|]]..platformId..[[|
add_label_with_icon|small|`7Delay Plant : ]]..delayPlant..[[|left|3804|
add_label_with_icon|small|`7Delay Harvest : ]]..delayHarvest..[[|left|3804|
add_label_with_icon|small|`7Pos Mag : X: ]]..magx..[[ Y: ]]..magy..[[|left|5638|
add_label_with_icon|small|`7Minimal Tree for UWS : ]]..countTree..[[|left|854|
add_label_with_icon|small|`7Loop Done : ]]..done..[[ / ]]..countPtht..[[|left|15110|
add_spacer|small|
add_button|closeinfo|Close|
]]

    SendVariant({v1="OnDialogRequest", v2=dialog})
end
-- ===============================================

-- ============ VARIANT HOOK =============
AddHook(function(var)
    if var.v1 == "OnDialogRequest" and var.v2:find("end_dialog|exchange") then
        SendVariant({
            v1 = "OnDialogRequest",
            v2 = "add_label_with_icon|big|`wSC BY FaRu``|left|5956|\nadd_spacer|small|\nadd_textbox|Just Press Button GET, and it Will Looping Exchange.|\nadd_textbox||\nadd_textbox||\nadd_spacer|small|\n" .. var.v2
        })
        return true
    end

    if var.v1 == "OnTalkBubble" and (var.v3:find("The `2Magplant") or var.v3:find("There is no active")) then
            magplantEmpty = true
            return true
        end

    if var.v1 == "OnDialogRequest" and var.v2:find("Ultra World Spray") then
        return true
    end
end, "onVariant")


-- ================== PACKET HOOK ==================
function hook(type, str)

    -- open helper
    if str:find("/helper") or str:find("selection|gems_bundle06") then
        openHelperMenu()
        return true
    end

    
    -- open feature script
    if str:find("buttonClicked|featurescript") then
        openFeatureScript()
        return true
    end
    
    
    -- pnb commands
    if str:find("buttonClicked|togglepnb") then
        pnbEnabled = not pnbEnabled
        paused = false
        if pnbEnabled then
            initPNB()
            ontext("`2PNB Enabled")
        else
            ontext("`4PNB Disabled")
        end
        openHelperMenu()
        return true
    end
    
    -- open config pnb
    if str:find("buttonClicked|configpnb") then
        openPNBConfig()
        return true
    end

    -- save config pnb
    if str:find("buttonClicked|savepnb") then
        itemid = tonumber(str:match("itemid|(%d+)")) or itemid
        delayPerBlock = tonumber(str:match("delaypb|(%d+)")) or delayPerBlock
        delayAuto = tonumber(str:match("delayauto|(%d+)")) or delayAuto
        xmag = tonumber(str:match("xmag|(%d+)")) or xmag
        ymag = tonumber(str:match("ymag|(%d+)")) or ymag
        ontext("`2PNB Config Saved")
        openHelperMenu()
        return true
    end
	
	if str:find("/startpnb") then 
		if not pnbEnabled then 
			pnbEnabled = true 
            paused = false 
            initPNB() 
            ontext("2PNB Started") 
        end 
		return true 
	end 
	
	if str:find("/stoppnb") then 
		pnbEnabled = false 
			ontext("4PNB Stopped") 
		return true 
	end
	
	if str:find("/configpnb") then
		openPNBConfig()
		return true
	end
	
    -- ptht commands
    if str:find("/startptht") then
        Ovlay("`9Taking Magplant...")
        Sleep(1000)
        getMagplant()
        pt(math.floor(GetLocal().posX/32), math.floor(GetLocal().posY/32), 5926)
		runThread(startPtht)
        return true
    end

    if str:find("/stopptht") then
        if not isRunning then
            Ovlay("`4Script not running!")
            return true
        end

        isRunning = false
        Ovlay("`4Stopping Script...")
        return true
    end

    if str:find("/configptht") then
        configPtht()
        return true
    end

	if str:find("buttonClicked|configPtht") then
        configPtht()
        return true
    end

    if str:find("/infoo") then
        infoPtht()
        return true
    end
	
	if str:find("buttonClicked|saveconfig") then
		mode = str:match("typeMode|([%w_]+)") or mode
		sprayMode = str:match("sprayMode|([%w_]+)") or sprayMode
		plantId = tonumber(str:match("plantId|(%d+)")) or plantId
		seedId = tonumber(str:match("seedId|(%d+)")) or seedId
		delayPlant = tonumber(str:match("delayPlant|(%d+)")) or delayPlant
		delayHarvest = tonumber(str:match("delayHarvest|(%d+)")) or delayHarvest
		magx = tonumber(str:match("xmag|(%d+)")) or magx
		magy = tonumber(str:match("ymag|(%d+)")) or magy
		countTree = tonumber(str:match("countTree|(%d+)")) or countTree
		count_ptht = tonumber(str:match("countPtht|(%d+)")) or count_ptht

		Ovlay("`2Config Saved Successfully!")
		LogToConsole("`2PTHT Config Updated!")
		return true
	end

    -- exchange commands
	if str:find("buttonClicked|exchange_go") then
        growtopia.sendChat("/exchange", true)
        return true
    end
    if str:find("/startexc") then
        startExchangeEngine()
        talkBubble("`2Exchange Mode Started! go /exchange and press `9GET")
        return true
    end

    if str:find("/stopexc") then
        if not isExchangeRunning then
            LogToConsole("`4Exchange is not running!")
            return true
        end

        isExchangeRunning = false
        LogToConsole("`4Stopping Exchange...")
        talkBubble("`4Stopping Exchange...")
        return true
    end

    -- ================= DROP COMMANDS =================
    if str:find("/w (%d+)") then
        local a = tonumber(str:match("/w (%d+)"))
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Lock!"); return true
    end
    if str:find("/wx2 (%d+)") then
        local a = tonumber(str:match("/wx2 (%d+)"))*2
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Locks!"); return true
    end
    if str:find("/wx3 (%d+)") then
        local a = tonumber(str:match("/wx3 (%d+)"))*3
        clock(242,1796,a); drops(242,a); talkBubble("`9Dropped `2"..a.." `9World Locks!"); return true
    end
    if str:find("/wall") then
        for _,i in pairs(GetInventory()) do if i.id==242 then drops(242,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9World Locks!") end end
        return true
    end

    if str:find("/d (%d+)") then
        local a = tonumber(str:match("/d (%d+)"))
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dx2 (%d+)") then
        local a = tonumber(str:match("/dx2 (%d+)"))*2
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dx3 (%d+)") then
        local a = tonumber(str:match("/dx3 (%d+)"))*3
        clock(1796,242,a); clock(1796,7188,a); drops(1796,a)
        talkBubble("`9Dropped `2"..a.." `9Diamond Lock!"); return true
    end
    if str:find("/dall") then
        for _,i in pairs(GetInventory()) do if i.id==1796 then drops(1796,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Diamond Locks!") end end
        return true
    end

    if str:find("/b (%d+)") then
        local a = tonumber(str:match("/b (%d+)"))
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/bx2 (%d+)") then
        local a = tonumber(str:match("/bx2 (%d+)"))*2
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/bx3 (%d+)") then
        local a = tonumber(str:match("/bx3 (%d+)"))*3
        drops(7188,a)
        talkBubble("`9Dropped `2"..a.." `9Blue Gem Lock!"); return true
    end
    if str:find("/ball") then
        for _,i in pairs(GetInventory()) do if i.id==7188 then drops(7188,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Blue Gem Locks!") end end
        return true
    end

    if str:find("/g (%d+)") then
        local a = tonumber(str:match("/g (%d+)"))
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gx2 (%d+)") then
        local a = tonumber(str:match("/gx2 (%d+)"))*2
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gx3 (%d+)") then
        local a = tonumber(str:match("/gx3 (%d+)"))*3
        drops(8470,a)
        talkBubble("`9Dropped `2"..a.." `9Golden Gem Lock!"); return true
    end
    if str:find("/gall") then
        for _,i in pairs(GetInventory()) do if i.id==8470 then drops(8470,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Golden Gem Lock!") end end
        return true
    end

    if str:find("/t (%d+)") then
        local a = tonumber(str:match("/t (%d+)"))
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tx2 (%d+)") then
        local a = tonumber(str:match("/tx2 (%d+)"))*2
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tx3 (%d+)") then
        local a = tonumber(str:match("/tx3 (%d+)"))*3
        drops(13200,a)
        talkBubble("`9Dropped `2"..a.." `9The Glorious Skull!"); return true
    end
    if str:find("/tall") then
        for _,i in pairs(GetInventory()) do if i.id==13200 then drops(13200,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9The Glorious Skull!") end end
        return true
    end

    if str:find("/m (%d+)") then
        local a = tonumber(str:match("/m (%d+)"))
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mx2 (%d+)") then
        local a = tonumber(str:match("/mx2 (%d+)"))*2
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mx3 (%d+)") then
        local a = tonumber(str:match("/mx3 (%d+)"))*3
        drops(4428,a)
        talkBubble("`9Dropped `2"..a.." `9The Majestic Dragon!"); return true
    end
    if str:find("/mall") then
        for _,i in pairs(GetInventory()) do if i.id==4428 then drops(4428,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9The Majestic Dragon!") end end
        return true
    end

    if str:find("/y (%d+)") then
        local a = tonumber(str:match("/y (%d+)"))
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yx2 (%d+)") then
        local a = tonumber(str:match("/yx2 (%d+)"))*2
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yx3 (%d+)") then
        local a = tonumber(str:match("/yx3 (%d+)"))*3
        drops(2950,a)
        talkBubble("`9Dropped `2"..a.." `9YinYang Universe Artifacts!"); return true
    end
    if str:find("/yall") then
        for _,i in pairs(GetInventory()) do if i.id==2950 then drops(2950,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9YinYang Universe Artifacts!") end end
        return true
    end

    if str:find("/bv (%d+)") then
        local a = tonumber(str:match("/bv (%d+)"))
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bv2 (%d+)") then
        local a = tonumber(str:match("/bv2 (%d+)"))*2
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bv3 (%d+)") then
        local a = tonumber(str:match("/bv3 (%d+)"))*3
        drops(5260,a)
        talkBubble("`9Dropped `2"..a.." `9Bunny Valentine Artifact!"); return true
    end
    if str:find("/bval") then
        for _,i in pairs(GetInventory()) do if i.id==5260 then 
            drops(5260,i.amount)
            talkBubble("`9Dropped `2"..i.amount.." `9Bunny Valentine Artifact!")
        end end
        return true
    end

    if str:find("/c (%d+)") then
        local a = tonumber(str:match("/c (%d+)"))
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/cx2 (%d+)") then
        local a = tonumber(str:match("/cx2 (%d+)"))*2
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/cx3 (%d+)") then
        local a = tonumber(str:match("/cx3 (%d+)"))*3
        drops(10410,a)
        talkBubble("`9Dropped `2"..a.." `9Chongqing Lion Artifact!"); return true
    end
    if str:find("/call") then
        for _,i in pairs(GetInventory()) do if i.id==10410 then drops(10410,i.amount) talkBubble("`9Dropped `2"..i.amount.." `9Chongqing Lion Artifact!") end end
        return true
    end
    -- =================================================

    lock = {242, 1796, 7188, 8470, 13200, 4428, 2950, 5260, 10410}
    if str:find("/daw") then
        for _,id in pairs(lock) do
            for _,i in pairs(GetInventory()) do
                if i.id==id then
                    drops(id,i.amount)
                    talkBubble("`9Dropped all Locks!")
                end
            end
        end
        return true
    end
    return false
end

AddHook(hook,"OnSendPacket")
-- =========================================================
talkBubble("`9Script Loaded! `9Type `2/helper `9to open the menu.")
LogToConsole("`3[FaRu] `2Loaded Successfully! Type `9/helper `2to open the menu.")

-- =========================================================



