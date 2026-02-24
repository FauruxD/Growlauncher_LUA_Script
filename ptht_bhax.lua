-- ================= CONFIG =================
seedId = 333
plantId = 5640
delayPlant = 25
delayHarvest = 80
count_ptht = 20
magx = 27
magy = 109
count_tree = 4000
platformId = 7520

magplantEmpty = false
mode = "ptht" -- "ptht" | "pt" | "ht"
sprayMode = "uws" -- "uws" or "dgs"
-- =========================================


-- ================= MAGPLANT =================
function getMagplant()
    SendPacket(2,
        "action|dialog_return\n"..
        "dialog_name|itemsucker_block\n"..
        "tilex|"..magx.."|\n"..
        "tiley|"..magy.."|\n"..
        "buttonClicked|getplantationdevice\n"
    )
end


-- ================= OVERLAY =================
function Ovlay(text)
    SendPacket(2,"action|input\n|text|"..text.."|\n")
end


-- ================= VARIANT DETECT =================
AddHook("OnVariant", "MagplantDetect", function(var)

    if var[0] == "OnTalkBubble" then
        local text = var[2] or ""
        if text:find("The `2Magplant") or text:find("There is no active") or text:find("The `2MAGPLANT") then
            magplantEmpty = true
            return true
        end
    end

    if var[0] == "OnDialogRequest" then
        if (var[1] or ""):find("Ultra World Spray") then
            return true
        end
    end

end)


-- ================= PLACE / USE ITEM =================
function pt(x, y, id)
    SendPacketRaw(false, {
        type = 3,
        value = id,
        px = x,
        py = y,
        x = x * 32,
        y = y * 32
    })
end


function bellow(x, y)
    local below = GetTile(x, y + 1)
    return below and below.fg == platformId
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
    for _, tile in pairs(GetTiles()) do
        if tile.fg == seedId and tile.extra then
            if tile.extra.progress < 1 then
                count = count + 1
            end
        end
    end
    return count
end


function Uws()
    local unready = CountUnreadyTree()
    Ovlay("Unready Tree: "..unready)

    if unready >= count_tree then
        Ovlay("`9Using UWS...")
        SendPacket(2,"action|dialog_return\ndialog_name|world_spray\n")
    else
        Ovlay("`4Skip UWS")
    end
end


function spray()
    Ovlay("`9Using Spray")
    for _, h in pairs(GetTiles()) do
        if h.fg == seedId and not h.readyharvest then
            Sleep(delayHarvest)
            SendPacketRaw(false,{
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
    SendPacketRaw(false,{
        type = 3,
        value = 18,
        px = x,
        py = y,
        x = x * 32,
        y = y * 32
    })
end


function isReady(tile)
    return tile 
        and tile.fg == seedId
        and tile.extra
        and tile.extra.progress
        and tile.extra.progress >= 1
end


function harvest()
    for x = 0, 100 do
        local rowMiss
        repeat
            rowMiss = 0
            for y = 0, 113 do
                local tile = GetTile(x, y)
                if isReady(tile) then
                    local tries = 0
                    repeat
                        SendPacketRaw(false,{
                            state = 32,
                            px = x,
                            py = y,
                            x = x * 32,
                            y = y * 32
                        })
                        hitTile(x, y)
                        Sleep(delayHarvest)
                        tile = GetTile(x, y) -- refresh real-time
                        tries = tries + 1
                    until not isReady(tile) or tries >= 3

                    if isReady(tile) then
                        rowMiss = rowMiss + 1
                    end
                end
            end
        until rowMiss == 0
        Sleep(25)
    end
end


-- ================= MAIN LOOP =================
local done = 0

Ovlay("`9Taking Magplant...")
Sleep(1000)
getMagplant()

local localPlayer = GetLocal()
if localPlayer then
    pt(math.floor(localPlayer.pos.x/32),
       math.floor(localPlayer.pos.y/32),
       5926)
end


for i = 1, count_ptht do

    if mode == "pt" or mode == "ptht" then
        Ovlay("`9Starting Auto Plant...")
        Sleep(1500)
        plant()
        Sleep(1500)
        Ovlay("`4DONE PLANT!")
    end

    if mode == "ptht" and sprayMode == "uws" then
        Sleep(5000)
        Uws()
    end

    if mode == "ptht" and sprayMode == "dgs" then
        Sleep(5000)
        spray()
    end

    if mode == "ht" or mode == "ptht" then
        Sleep(5000)
        Ovlay("`9Starting Auto Harvest")
        Sleep(500)
        harvest()
        Sleep(400)
        Ovlay("`4DONE HARVEST!")
    end

    done = done + 1
    Ovlay("`cTotal Done : "..done.." / "..count_ptht)
    LogToConsole("`cTotal Done : "..done.." / "..count_ptht)

    Sleep(2000)
    Ovlay("`9Loading Next Cycle")
    Sleep(3000)
end
