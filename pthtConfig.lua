-- ================= CONFIG =================
seedId = 333
plantId = 5640
delayPlant = 25
delayHarvest = 80
countPtht = 1
magx = 27
magy = 109
countTree = 3300

magplantEmpty = false
mode = "ptht" -- "ptht" | "pt" | "ht"
sprayMode = "uws" -- "uws" or "dgs"
isRunning = false
done = 0
-- =========================================


-- ================= MAGPLANT =================
function getMagplant()
    sendPacket(2,
        "action|dialog_return\n"..
        "dialog_name|itemsucker_block\n"..
        "tilex|"..magx.."|\n"..
        "tiley|"..magy.."|\n"..
        "buttonClicked|getplantationdevice\n"
    )
end

-- ================= OVERLAY =================
function Ovlay(text)
    sendPacket(2,"action|input\n|text|"..text.."|\n")
end

-- ===============  VARIANT DETECT ===============

AddHook(function(var)
 if var.v1 == "OnTalkBubble" and (var.v3:find("The `2Magplant") or var.v3:find("There is no active")) then
		magplantEmpty = true
		return true
	end

if var.v1 == "OnDialogRequest" and var.v2:find("Ultra World Spray") then
return true
end
end, "OnVariant")

-- ================= PLACE / USE ITEM =================
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
    return below and below.fg == 7520
end
-- ================= PLANT =================
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

-- ================= UWS =================
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


-- ================= HARVEST =================
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
        Sleep(25) -- rowDelay versi ringan (tidak ubah config lain)
    end
end

-- ================ START PTHT =================
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

        -- ===== MODE PT / PTHT =====
        if mode == "pt" or mode == "ptht" then
            Ovlay("`9Starting Auto Plant...")
            Sleep(1500)
            plant()
            Sleep(1000)
            Ovlay("`4DONE PLANT!")
        end

        if not isRunning then break end

        -- ===== MODE PTHT USING UWS =====
        if mode == "ptht" and sprayMode == "uws" then
            Sleep(4500)
            if not isRunning then break end
            Uws()
        end

        if not isRunning then break end

        -- ===== MODE PTHT USING DGS =====
        if mode == "ptht" and sprayMode == "dgs" then
            Sleep(4500)
            if not isRunning then break end
            spray()
        end

        if not isRunning then break end

        -- ===== MODE HT / PTHT =====
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

-- ================= INFO MENU =================
function configMenu()
	local dialog = [[
set_border_color|255,215,0,255
set_bg_color|150,0,0,200
add_label_with_icon|big|`7PTHT Configuration|left|5956|
add_spacer|small|
add_smalltext|`7Hi ]]..getLocal().name..[[|
add_smalltext|`7Type /infoo to see your latest config|
add_smalltext|`7This Script is Made by `c@FaRu|
add_spacer|small|
add_label_with_icon|small|`7Default Config : |left||
add_label_with_icon|small|`7Mode : ]]..mode..[[|left|14922|
add_label_with_icon|small|`7Spray Mode : ]]..sprayMode..[[|left|5926|
add_label_with_icon|small|`7ID Plant : ]]..plantId..[[ - `9]]..growtopia.getItemName(plantId)..[[|left|]]..plantId..[[|
add_label_with_icon|small|`7ID Harvest : ]]..seedId..[[ - `9]]..growtopia.getItemName(seedId)..[[|left|]]..seedId..[[|
add_label_with_icon|small|`7Delay Plant : ]]..delayPlant..[[|left|3804|
add_label_with_icon|small|`7Delay Harvest : ]]..delayHarvest..[[|left|3804|
add_label_with_icon|small|`7Pos Mag : X: ]]..magx..[[ Y: ]]..magy..[[|left|5638|
add_label_with_icon|small|`7Minimal Tree : ]]..countTree..[[|left|854|
add_label_with_icon|small|`7Loop : ]]..countPtht..[[|left|15110|


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

-- ================= MAIN LOOP =================
Ovlay("`9Taking Magplant...")
    Sleep(1000)
    getMagplant()
	pt(math.floor(GetLocal().posX/32), math.floor(GetLocal().posY/32), 5926)

AddHook(function(type, str)

    -- ================= START =================
    if str:find("/start") then
		runThread(startPtht)
        return true
    end


    -- ================= STOP =================
    if str:find("/stop") then
        if not isRunning then
            Ovlay("`4Script not running!")
            return true
        end

        isRunning = false
        Ovlay("`4Stopping Script...")
        return true
    end


    -- ================= CONFIG =================
    if str:find("/config") then
        configMenu()
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

		sendNotification("`2Config Saved Successfully!")
		LogToConsole("`2PTHT Config Updated!")

		return true
	end
end, "onSendPacket")
